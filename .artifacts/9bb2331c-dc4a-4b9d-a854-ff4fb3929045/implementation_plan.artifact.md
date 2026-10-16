# Implementation Plan - PDF Builder Flutter App

Build a robust, production-ready Flutter application for PDF manipulation on Android and iOS.

## User Review Required

> [!IMPORTANT]
> **PDF Translation Complexity**: Preserving the exact layout of a PDF while translating text is technically challenging. The implementation will focus on extracting text, translating it, and generating a new PDF with similar formatting.
> [!NOTE]
> **Syncfusion License**: I propose using `syncfusion_flutter_pdf` for advanced features like merging and splitting. This is free under their Community License (for individuals and small companies), but please verify if this fits your business model.

## Proposed Changes

### Project Foundation
Set up the core architecture and essential dependencies.

#### [MODIFY] [pubspec.yaml](file:///D:/projects/pdf_builder/pubspec.yaml)
Add dependencies:
- `flutter_riverpod`: State management.
- `go_router`: Navigation.
- `pdf`, `printing`: PDF creation and printing.
- `syncfusion_flutter_pdf`: Advanced PDF manipulation (Merge/Split).
- `image_picker`, `image_cropper`: Image selection and editing.
- `file_picker`: Document selection.
- `path_provider`, `share_plus`: File system access and sharing.
- `google_mlkit_document_scanner`: For the Scan feature.
- `signature`: For the Sign feature.
- `google_fonts`, `flutter_animate`: UI enhancement.

#### [NEW] Directory Structure
```text
lib/
├── core/           # Constants, themes, utilities
├── features/       # Feature-based modules
│   ├── home/       # Dashboard/Navigation
│   ├── img_to_pdf/ # Image to PDF logic & UI
│   ├── pdf_to_img/ # PDF to Image logic & UI
│   ├── merge_split/# Merge/Split logic & UI
│   ├── scan_sign/  # Scan & Signature logic & UI
│   └── translator/ # PDF Translation logic & UI
├── shared/         # Reusable widgets
└── main.dart       # Entry point & ProviderScope
```

---

### Core Features Implementation

#### 1. Home Dashboard
A modern Material 3 grid/list of features with smooth animations.

#### 2. Image to PDF
- Multi-image picker from gallery.
- Grid view with reordering capability.
- Integration with `image_cropper` for per-image editing.
- Generation using the `pdf` package.

#### 3. PDF to Image
- Render PDF pages using `printing` or `pdfx`.
- Save pages as JPG/PNG to the gallery or app documents.

#### 4. Merge & Split
- File picker to select multiple PDFs (Merge) or one PDF (Split).
- List view of selected files/pages.
- Logic powered by `syncfusion_flutter_pdf`.

#### 5. Scan & Sign
- Document scanner UI using `google_mlkit_document_scanner`.
- Signature pad using the `signature` package.
- Overlaying signature onto PDF using `syncfusion_flutter_pdf`.

#### 6. PDF Translator
- Text extraction from PDF.
- Translation integration (Basic implementation using a placeholder or public API).
- Reconstruction of PDF with translated text.

---

### Platform Configuration
- **Android**: Configure `AndroidManifest.xml` for camera, storage (scoped), and Internet permissions.
- **iOS**: Configure `Info.plist` for `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and `NSDocumentsFolderUsageDescription`.

## Verification Plan

### Automated Tests
- Unit tests for PDF generation and manipulation logic.
- Widget tests for the home dashboard and file list components.

### Manual Verification
- Testing the full flow of "Image -> PDF -> Save -> Share" on an Android emulator/device.
- Verifying document scanning and signature placement.
- Checking responsiveness on different screen sizes (Phone vs Tablet).
