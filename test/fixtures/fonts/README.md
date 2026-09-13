# Offline visual-test fonts

These are the exact normal-weight Inter and Lora font files referenced by the existing google_fonts 6.2.1 dependency (weights 400, 500, 600, 700). Filenames are their SHA-256 hashes. Source: `https://fonts.gstatic.com/s/a/<hash>.ttf`; each is validated by google_fonts' existing length/hash checks when loaded through the test HTTP client. Inter and Lora OFL license files accompany them.

Used only by `test/integrity/pass2_ui_test.dart` to test the actual reader and V2 layouts without live font requests or Flutter's Ahem placeholder font. No application fonts, assets, or dependencies are changed. Optional `SQ_CAPTURE=1` saves inspection images to the system temporary directory; the normal test run does not export images.
