import asyncio
import os
import uuid
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, AnyHttpUrl
import yt_dlp

ROOT = Path(os.getenv("DOWNLOAD_ROOT", "/tmp/ytmusic-downloads")); ROOT.mkdir(parents=True, exist_ok=True)
app = FastAPI(title="YT Music Library Download API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
app.mount("/files", StaticFiles(directory=ROOT), name="files")
jobs = {}

class DownloadRequest(BaseModel): url: AnyHttpUrl

@app.post("/api/download")
async def create_download(payload: DownloadRequest):
    job_id = uuid.uuid4().hex
    jobs[job_id] = {"id": job_id, "title": "جاري التحضير", "status": "queued", "progress": 0, "fileURL": None, "error": None}
    asyncio.create_task(run_download(job_id, str(payload.url)))
    return jobs[job_id]

@app.get("/api/download/{job_id}")
async def get_download(job_id: str):
    if job_id not in jobs: raise HTTPException(404, "job not found")
    return jobs[job_id]

async def run_download(job_id: str, url: str):
    folder = ROOT / job_id; folder.mkdir()
    def hook(data):
        if data.get("status") == "downloading":
            raw = data.get("_percent_str", "0").replace("%", "").strip()
            try: jobs[job_id]["progress"] = float(raw) / 100
            except ValueError: pass
            jobs[job_id]["title"] = data.get("info_dict", {}).get("title", "جاري التنزيل")
            jobs[job_id]["status"] = "downloading"
    try:
        options = {"format": "bestaudio/best", "outtmpl": str(folder / "%(title)s.%(ext)s"), "noplaylist": False, "quiet": True, "ignoreerrors": True, "progress_hooks": [hook], "postprocessors": [{"key": "FFmpegExtractAudio", "preferredcodec": "mp3", "preferredquality": "0"}]}
        jobs[job_id]["status"] = "downloading"
        await asyncio.to_thread(lambda: yt_dlp.YoutubeDL(options).download([url]))
        files = list(folder.glob("*.mp3"))
        if not files: raise RuntimeError("لم يتم العثور على ملف صوتي")
        jobs[job_id].update(status="completed", progress=1, fileURL=f"/files/{job_id}/{files[0].name}")
    except Exception as exc:
        jobs[job_id].update(status="error", error=str(exc))
