# ✅ Google Cloud Storage Updates (GCS)

## 1. `gcs.service.ts` (Modified) 🛠️

Added several new methods to the Google Cloud Storage service:

### ✨ New Methods

- **`generateSignedUploadUrl()`** 🔐  
  Generates signed upload URLs for client-side uploads with:
  - 🗂️ Tenant / appointment folder isolation  
  - ⏳ Configurable expiry (default: **30 minutes**)  
  - 📏 File size limit enforcement (**500MB max**) via `x-goog-content-length-range` header  
  - 📦 Returns:
    - `uploadUrl`
    - `filePath`
    - `expiresAt` timestamp  

- **`getFileMetadata()`** 📄  
  Retrieves normalized file metadata including:
  - 📦 Size  
  - 🧾 Content type  
  - 🗓️ Creation & update dates  
  - 🔑 MD5 hash  

- **`deleteFilesOlderThan()`** 🧹  
  Deletes files older than a specified number of days for retention compliance.

- **`deleteTenantFilesOlderThan()`** 🏢🧹  
  Deletes old files for a **specific tenant** using prefix filtering.

- **`listAppointmentFiles()`** 📂  
  Lists all files in a specific appointment folder **with metadata**.

- **`countTenantFiles()`** 🔢  
  Counts total files stored for a tenant.

- **`getTenantStorageSize()`** 💾  
  Calculates total storage usage (in bytes) for a tenant.

### 🧩 Helpers & Types

- **`buildFileMetadata()` (private)** 🧰  
  Helper to normalize raw GCS metadata into the `FileMetadata` interface.

- Added **import/export** for:
  - `SignedUploadUrlResult`
  - `FileMetadata`  
  from the new types file ✅


---

## 2. `gcs.types.ts` (New File) 📌✨

Created a dedicated types file defining:

- **`SignedUploadUrlResult`** 🔐  
  Contains:
  - `uploadUrl`
  - `filePath`
  - `expiresAt`

- **`FileMetadata`** 📄  
  Contains:
  - `name`
  - `size`
  - `contentType`
  - `created`
  - `updated`
  - `md5Hash`
  - `exists`

---

## 3. `gcs.service.spec.ts` (New File) 🧪✅

Added unit tests covering the new service methods:

- **`generateSignedUploadUrl()`** 🔐🧪  
  Tests:
  - Correct action type  
  - File path generation  
  - Size limit enforcement  

- **`getFileMetadata()`** 📄🧪  
  Tests metadata retrieval and transformation.

- **`deleteFilesOlderThan()`** 🧹🧪  
  Tests deletion logic based on file age.

- **`deleteTenantFilesOlderThan()`** 🏢🧹🧪  
  Tests tenant-prefixed deletion.

- **`listAppointmentFiles()`** 📂🧪  
  Tests listing appointment folder files with metadata.
