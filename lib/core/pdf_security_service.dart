import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfSecurityService {
  static void applySecurityAndWatermark({
    required PdfDocument document,
    String? userPassword,
    String? ownerPassword,
    String? watermarkText,
  }) {
    // 1. Password Protection & Encryption
    if (userPassword != null && userPassword.trim().isNotEmpty) {
      document.security.userPassword = userPassword.trim();
      if (ownerPassword != null && ownerPassword.trim().isNotEmpty) {
        document.security.ownerPassword = ownerPassword.trim();
      }
    }

    // 2. Watermarking
    if (watermarkText != null && watermarkText.trim().isNotEmpty) {
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 36);
      final PdfBrush brush = PdfSolidBrush(PdfColor(150, 150, 150));

      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final size = page.getClientSize();

        page.graphics.save();
        page.graphics.setTransparency(0.25);
        
        // Draw diagonal watermark text
        page.graphics.drawString(
          watermarkText.trim(),
          font,
          brush: brush,
          bounds: Rect.fromLTWH(40, size.height / 2 - 30, size.width - 80, 60),
        );
        page.graphics.restore();
      }
    }
  }
}
