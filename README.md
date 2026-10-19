# YT Music Library — SwiftUI

تطبيق iOS أصلي لإدارة مكتبة صوتية عربية خفيفة، مع تنزيل الصوت من الروابط عبر Backend خاص مبني على `yt-dlp` و`ffmpeg`، ثم تشغيل الملفات محلياً وتنظيمها.

## المزايا

- إدخال رابط فيديو أو قائمة وبدء التنزيل.
- متابعة حالة التقدم وتحويل الصوت إلى MP3.
- استيراد ملفات الصوت من تطبيق Files.
- تشغيل محلي، بحث، مفضلة، حذف، وتصدير M3U.
- واجهة عربية RTL وحفظ المكتبة داخل الجهاز.

استخدم التنزيل فقط للمحتوى الذي تملكه أو لديك إذن واضح بتنزيله. لا أستطيع ضمان حقوق المحتوى الذي تدخله أنت.

## Backend

```bash
cd server
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000
```

عدّل `baseURL` في `DownloadService.swift` إلى عنوان الخادم المنشور قبل بناء IPA. لا تضع مفاتيح أو أسراراً داخل التطبيق.

## IPA عبر GitHub Actions

الـ workflow في `.github/workflows/ios.yml` يبني التطبيق على `macos-latest` عند كل push وينتج IPA غير موقّع كـ Artifact. للتثبيت على جهاز حقيقي، أضف شهادة Apple وملف provisioning profile كـ GitHub Secrets ثم فعّل التوقيع في workflow.
