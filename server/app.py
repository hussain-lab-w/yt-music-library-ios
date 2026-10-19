import asyncio
import os
import re
import uuid
from pathlib import Path
from urllib.parse import quote

import yt_dlp
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import AnyHttpUrl, BaseModel

ROOT = Path(os.getenv("DOWNLOAD_ROOT", "/tmp/ytmusic-downloads"))
ROOT.mkdir(parents=True, exist_ok=True)
app = FastAPI(title="Audio Library Download API", version="2.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["GET", "POST"], allow_headers=["*"])
app.mount("/files", StaticFiles(directory=str(ROOT)), name="files")
jobs: dict[str, dict] = {}

class DownloadRequest(BaseModel):
    url: AnyHttpUrl

@app.get("/health")
async def health():
    return {"ok": True, "service": "audio-library", "yt_dlp": yt_dlp.version.__version__}

@app.post("/api/download")
async def create_download(payload: DownloadRequest):
    job_id = uuid.uuid4().hex
    jobs[job_id] = {"id": job_id, "title": "Preparing…", "status": "queued", "progress": 0.0, "files": [], "error": None}
    asyncio.create_task(run_download(job_id, str(payload.url)))
    return jobs[job_id]

@app.get("/api/download/{job_id}")
async def get_download(job_id: str):
    job = jobs.get(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Download job not found")
    return job

def safe_name(value: str) -> str:
    value = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", value).strip(" .")
    return (value or "audio")[:150]

async def run_download(job_id: str, url: str):
    folder = ROOT / job_id
    folder.mkdir(parents=True, exist_ok=True)

    def hook(data: dict):
        info = data.get("info_dict") or {}
        title = info.get("title") or "Downloading audio"
        jobs[job_id]["title"] = title
        if data.get("status") == "downloading":
            raw = str(data.get("_percent_str", "0")).replace("%", "").strip()
            try:
                jobs[job_id]["progress"] = max(0.0, min(0.95, float(raw) / 100))
            except ValueError:
                pass
            jobs[job_id]["status"] = "downloading"
        elif data.get("status") == "finished":
            jobs[job_id]["status"] = "converting"

    try:
        jobs[job_id]["status"] = "downloading"
        options = {
            "format": "bestaudio/best",
            "outtmpl": str(folder / "%(playlist_index&{} - |)s%(title)s.%(ext)s"),
            "noplaylist": False,
            "quiet": True,
            "no_warnings": True,
            "ignoreerrors": True,
            "continuedl": True,
            "retries": 5,
            "fragment_retries": 5,
            "windowsfilenames": True,
            "restrictfilenames": False,
            "progress_hooks": [hook],
            "postprocessors": [{"key": "FFmpegExtractAudio", "preferredcodec": "mp3", "preferredquality": "0"}],
        }
        await asyncio.to_thread(lambda: yt_dlp.YoutubeDL(options).download([url]))
        files = sorted(p for p in folder.glob("*.mp3") if p.is_file())
        if not files:
            raise RuntimeError("No audio was produced. Check the URL, server logs, and ffmpeg installation.")
        result_files = []
        for path in files:
            title = path.stem
            result_files.append({"id": path.name, "title": title, "url": f"files/{job_id}/{quote(path.name)}"})
        jobs[job_id].update(status="completed", progress=1.0, title=result_files[0]["title"], files=result_files)
    except Exception as exc:
        jobs[job_id].update(status="error", error=str(exc), progress=0.0)
