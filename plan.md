# خطة YT Music Library

## النطاق المؤكد

تطبيق SwiftUI عربي خفيف، وظيفة التنزيل هي الوظيفة الأساسية، مع تشغيل وتنظيم الملفات الناتجة. التنزيل يتم عبر Backend Python يستخدم yt-dlp وffmpeg، لأن iOS لا يشغّل أدوات Python/ffmpeg الخارجية بشكل موثوق داخل التطبيق. التطبيق لا يحتوي أي تنزيل تلقائي دون إدخال رابط، ويجب استخدامه للمحتوى المسموح بتنزيله.

## التصميم

- **Design Movement:** Neo-night audio utility.
- **Core Principles:** سريع، واضح، لمسي، قليل التشتيت.
- **Color Philosophy:** بنفسجي ليلي مع لمسات زرقاء ليوحي بالصوت والطاقة دون ازدحام.
- **Layout Paradigm:** رأس بسيط، قائمة مسارات ممتدة، وشريط تشغيل ثابت في الأسفل.
- **Signature Elements:** waveform، بطاقات زجاجية داكنة، زر تنزيل دائري واضح.
- **Interaction Philosophy:** كل إجراء رئيسي متاح بلمسة واحدة مع حالات تقدم واضحة.
- **Animation:** انتقالات قصيرة في التصفية وظهور شريط التشغيل.
- **Typography:** النظام العربي الافتراضي مع أوزان واضحة.
- **Brand Essence:** مكتبتك الصوتية الخاصة من الرابط إلى الاستماع.

## البنية

- `YTMusicLibrary/App`: تطبيق SwiftUI، مشغل AVAudioPlayer، المكتبة، واجهة التنزيل.
- `server`: FastAPI + yt-dlp + ffmpeg، وظائف التنزيل والتحويل وتقديم الملف.
- `.github/workflows/ios.yml`: بناء IPA عبر macOS runner.
