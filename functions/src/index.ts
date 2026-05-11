import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { initializeApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

if (getApps().length === 0) {
  initializeApp();
}

const OCI_REGION = defineSecret("OCI_REGION");
const OCI_NAMESPACE = defineSecret("OCI_NAMESPACE");
const OCI_BUCKET_NAME = defineSecret("OCI_BUCKET_NAME");
const OCI_ACCESS_KEY = defineSecret("OCI_ACCESS_KEY");
const OCI_SECRET_KEY = defineSecret("OCI_SECRET_KEY");

const AUDD_API_TOKEN = defineSecret("AUDD_API_TOKEN");

const ALLOWED_CONTENT_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
]);
const ALLOWED_EXTENSIONS = /^[a-z0-9]{1,5}$/;
const PRESIGN_EXPIRES_SECONDS = 60 * 5;

interface UploadUrlRequest {
  contentType?: string;
  extension?: string;
}

interface UploadUrlResponse {
  uploadUrl: string;
  publicUrl: string;
  objectName: string;
  expiresIn: number;
}

export const getPlaylistCoverUploadUrl = onCall<UploadUrlRequest, Promise<UploadUrlResponse>>(
  {
    region: "us-central1",
    secrets: [
      OCI_REGION,
      OCI_NAMESPACE,
      OCI_BUCKET_NAME,
      OCI_ACCESS_KEY,
      OCI_SECRET_KEY,
    ],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const { contentType, extension } = request.data ?? {};

    if (!contentType || !ALLOWED_CONTENT_TYPES.has(contentType)) {
      throw new HttpsError(
        "invalid-argument",
        `contentType inválido. Permitidos: ${[...ALLOWED_CONTENT_TYPES].join(", ")}`,
      );
    }
    if (!extension || !ALLOWED_EXTENSIONS.test(extension)) {
      throw new HttpsError("invalid-argument", "Extensión inválida.");
    }

    const region = OCI_REGION.value();
    const namespace = OCI_NAMESPACE.value();
    const bucket = OCI_BUCKET_NAME.value();
    const accessKey = OCI_ACCESS_KEY.value();
    const secretKey = OCI_SECRET_KEY.value();

    const objectName = `covers/${request.auth.uid}/${Date.now()}.${extension}`;

    const s3 = new S3Client({
      region,
      endpoint: `https://${namespace}.compat.objectstorage.${region}.oraclecloud.com`,
      credentials: { accessKeyId: accessKey, secretAccessKey: secretKey },
      forcePathStyle: false,
    });

    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: objectName,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(s3, command, {
      expiresIn: PRESIGN_EXPIRES_SECONDS,
    });

    const publicUrl = `https://objectstorage.${region}.oraclecloud.com/n/${namespace}/b/${bucket}/o/${encodeURIComponent(objectName)}`;

    return {
      uploadUrl,
      publicUrl,
      objectName,
      expiresIn: PRESIGN_EXPIRES_SECONDS,
    };
  },
);

const ALLOWED_AUDIO_TYPES = new Set([
  "audio/mp4",
  "audio/aac",
  "audio/m4a",
]);
const MAX_AUDIO_BYTES = 2 * 1024 * 1024;

// `recognizeAudio` es onRequest (HTTP) — no callable — porque la stack
// callable del SDK cliente terminaba devolviendo `unauthenticated` por
// interferencia con App Check aunque la función no lo exija. Aquí
// verificamos el Firebase ID token manualmente desde el header
// `Authorization: Bearer <token>`, lo que nos da control total y
// elimina cualquier dependencia de App Check.
export const recognizeAudio = onRequest(
  {
    region: "us-central1",
    secrets: [AUDD_API_TOKEN],
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    const authHeader = req.get("authorization") ?? req.get("Authorization") ?? "";
    const match = authHeader.match(/^Bearer (.+)$/i);
    if (!match) {
      res.status(401).json({ error: "Falta el token de autenticación." });
      return;
    }
    try {
      await getAuth().verifyIdToken(match[1]);
    } catch (e) {
      res.status(401).json({ error: "Token inválido o expirado." });
      return;
    }

    const body = (req.body ?? {}) as {
      audioBase64?: unknown;
      contentType?: unknown;
    };
    const audioBase64 = body.audioBase64;
    const contentType = body.contentType;

    if (typeof audioBase64 !== "string" || audioBase64.length === 0) {
      res.status(400).json({ error: "audioBase64 requerido." });
      return;
    }
    if (typeof contentType !== "string" || !ALLOWED_AUDIO_TYPES.has(contentType)) {
      res.status(400).json({
        error: `contentType inválido. Permitidos: ${[...ALLOWED_AUDIO_TYPES].join(", ")}`,
      });
      return;
    }

    let audioBytes: Buffer;
    try {
      audioBytes = Buffer.from(audioBase64, "base64");
    } catch (e) {
      res.status(400).json({ error: "audioBase64 mal codificado." });
      return;
    }
    if (audioBytes.length === 0 || audioBytes.length > MAX_AUDIO_BYTES) {
      res.status(400).json({
        error: `Tamaño de audio inválido (${audioBytes.length} bytes).`,
      });
      return;
    }

    // AudD exige multipart/form-data con un campo `file`; el parámetro
    // `audio_data` documentado no se aplica en este endpoint público.
    // Para construir el Blob sin chocar con `Buffer<ArrayBufferLike>`
    // (TS rechaza SharedArrayBuffer como BlobPart) copiamos los bytes a
    // un ArrayBuffer puro — el cuerpo es de ~80–150 KB, la copia es trivial.
    const audioArrayBuffer = new ArrayBuffer(audioBytes.byteLength);
    new Uint8Array(audioArrayBuffer).set(audioBytes);
    const audioBlob = new Blob([audioArrayBuffer], { type: contentType });

    const form = new FormData();
    form.append("api_token", AUDD_API_TOKEN.value());
    form.append("return", "spotify,apple_music,deezer");
    form.append("file", audioBlob, "audio.m4a");

    let response: Response;
    try {
      response = await fetch("https://api.audd.io/", {
        method: "POST",
        body: form,
      });
    } catch (e) {
      res.status(502).json({ error: "No se pudo contactar al servicio de reconocimiento." });
      return;
    }

    if (!response.ok) {
      res.status(502).json({ error: `AudD respondió con HTTP ${response.status}.` });
      return;
    }

    const payload = (await response.json()) as {
      status?: string;
      result?: unknown;
      error?: { error_message?: string };
    };

    if (payload.status !== "success") {
      const msg = payload.error?.error_message ?? "Respuesta inválida de AudD.";
      res.status(502).json({ error: msg });
      return;
    }

    res.status(200).json({
      status: "success",
      result: payload.result ?? null,
    });
  },
);
