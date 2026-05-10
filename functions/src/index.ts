import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const OCI_REGION = defineSecret("OCI_REGION");
const OCI_NAMESPACE = defineSecret("OCI_NAMESPACE");
const OCI_BUCKET_NAME = defineSecret("OCI_BUCKET_NAME");
const OCI_ACCESS_KEY = defineSecret("OCI_ACCESS_KEY");
const OCI_SECRET_KEY = defineSecret("OCI_SECRET_KEY");

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
