# HSound Cloud Functions

Backend para firmar URLs de subida (presigned PUT) hacia OCI Object Storage.
Mantiene las credenciales OCI fuera del cliente Flutter.

## Función expuesta

`getPlaylistCoverUploadUrl` (HTTPS callable, requiere usuario autenticado).

**Request:**
```json
{ "contentType": "image/jpeg", "extension": "jpg" }
```

**Response:**
```json
{
  "uploadUrl": "https://...presigned PUT url...",
  "publicUrl": "https://objectstorage.<region>.oraclecloud.com/...",
  "objectName": "covers/<uid>/<ts>.jpg",
  "expiresIn": 300
}
```

El cliente hace `PUT uploadUrl` con los bytes del archivo y header
`Content-Type` igual al solicitado, luego usa `publicUrl` como portada.

## Setup

```bash
cd functions
npm install
```

## Configurar secretos (una sola vez por proyecto Firebase)

```bash
firebase functions:secrets:set OCI_REGION
firebase functions:secrets:set OCI_NAMESPACE
firebase functions:secrets:set OCI_BUCKET_NAME
firebase functions:secrets:set OCI_ACCESS_KEY
firebase functions:secrets:set OCI_SECRET_KEY
```

> **IMPORTANTE:** Antes de configurar los secretos, **rota** las credenciales
> OCI en la consola de Oracle Cloud. Las anteriores estuvieron expuestas en
> builds del cliente y deben considerarse comprometidas.

## Deploy

```bash
npm run build
firebase deploy --only functions
```

## Local (emulador)

```bash
npm run serve
```
