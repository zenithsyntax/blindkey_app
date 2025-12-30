# Google Play Store - MANAGE_EXTERNAL_STORAGE Permission Declaration

## All files access - Describe one feature (UNDER 500 CHARACTERS)

**Feature:** Secure File Decryption and Export to Downloads Folder

BlindKey encrypts and stores sensitive files. When users decrypt files, the app saves them directly to the Downloads folder (/storage/emulated/0/Download/BlindKey/). This requires direct file system access to write to the system Downloads directory, which Storage Access Framework cannot access on Android 11+. The app creates a "BlindKey" subfolder in Downloads, preserving original filenames so users can easily locate decrypted files through file managers.

**Character count: 398**

---

## Usage - Why does your app need to use the all files access permission?

**Select:** ✅ Core functionality

**Explanation:**
The all files access permission is essential for the app's core functionality of securely exporting decrypted files. Users encrypt files for security, and the ability to decrypt and save them to an accessible location (Downloads folder) is a fundamental feature of the application. Without this permission, users would be unable to retrieve their decrypted files, rendering the core purpose of the vault application non-functional.

---

## Technical reason - Why can't you use more privacy-friendly alternatives? (UNDER 500 CHARACTERS)

**Technical Explanation:**

SAF doesn't provide direct path access to Downloads directory. It requires manual folder selection per file, breaking batch export. The app must restore original filenames from encrypted metadata and save to predictable Downloads location, which SAF cannot guarantee. MediaStore only supports media files, not documents/PDFs/archives users encrypt.

**Character count: 287**

---

## Video Instructions

**Link:** https://www.youtube.com/shorts/tSOaSqfs4uA

**Note:** The video should demonstrate:
1. User opening an encrypted file in the app
2. Selecting "Save" or "Export" option
3. Permission dialog appearing (if not already granted)
4. File being decrypted and saved to Downloads/BlindKey folder
5. User accessing the file from Downloads folder using a file manager

---

---

## Photo and Video Permissions

### READ_MEDIA_IMAGES (UNDER 250 CHARACTERS)

**Description:**

Users frequently select photos to encrypt in vaults. App needs direct image file access for encryption processing, which photo picker cannot provide. Core functionality requires frequent media access.

**Character count: 149**

---

### READ_MEDIA_VIDEO (UNDER 250 CHARACTERS)

**Description:**

Users frequently select videos to encrypt in vaults. App needs direct video file access for encryption processing, which photo picker cannot provide. Core functionality requires frequent media access.

**Character count: 149**

---

## Summary

- **Feature:** Secure file decryption and export to Downloads folder
- **Usage Type:** Core functionality
- **Technical Reason:** Direct path access to Downloads folder required; SAF/MediaStore cannot provide seamless, batch file export with original filenames to system directories
- **Video:** https://www.youtube.com/shorts/tSOaSqfs4uA
- **READ_MEDIA_IMAGES:** Frequent access needed for encrypting photos (core functionality)
- **READ_MEDIA_VIDEO:** Frequent access needed for encrypting videos (core functionality)

