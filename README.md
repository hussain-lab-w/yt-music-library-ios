# YT Music Library — SwiftUI

A modern English SwiftUI audio library with a real download pipeline. The iOS app accepts a video or playlist URL, asks a separate Python Backend to download and convert the audio with `yt-dlp` and `ffmpeg`, then saves the resulting MP3 files locally for offline playback.

## Why the old build failed

`127.0.0.1` inside an iPhone points to the iPhone itself, not your computer. The app now has a **Backend Settings** screen and refuses to start until it can reach `/health`. Use a deployed **HTTPS** Backend URL, for example `https://your-service.example.com`.

## Backend setup

```bash
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000
```

For local network testing, expose the server through a reachable HTTPS tunnel or deploy it to a server with a public HTTPS URL. Then open the app, tap Download → Settings, and paste that URL. The Backend must expose `/health`, `/api/download`, and `/api/download/{id}`.

The app supports playlists and downloads every MP3 returned by the Backend. Use downloads only for content you own or are authorized to save.

## GitHub Actions

`.github/workflows/ios.yml` builds an unsigned IPA on `macos-latest`. A real iPhone installation requires Apple signing credentials and a provisioning profile. The app bundle metadata is configured for iOS and the Xcode project includes the settings and download files.
