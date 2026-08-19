#!/usr/bin/env python3
"""Resolve cover art for the active MPRIS track into a content-addressed cache.

Usage: coverart.py <cache_dir> <request_json>   (request also accepted on stdin)
    in : {"artUrl","trackUrl","title","artist","album","embedded","online"}
    out: {"ok": bool, "path": str, "source": str}

Resolution order: artUrl -> embedded tag -> sidecar file -> online lookup.
"""

import base64
import hashlib
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

TIMEOUT = 8
MAX_BYTES = 8 * 1024 * 1024
CACHE_MAX = 300
UA = "flokshell"

SIDECAR_STEMS = ("cover", "folder", "front", "album", "albumart", "artwork")
SIDECAR_EXTS = (".jpg", ".jpeg", ".png", ".webp")


def sniff(data):
    """Image extension from magic bytes, or None if this isn't an image."""
    if data[:3] == b"\xff\xd8\xff":
        return ".jpg"
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return ".png"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return ".webp"
    if data[:6] in (b"GIF87a", b"GIF89a"):
        return ".gif"
    return None


def store(cache_dir, data):
    # Content-addressed: Qt caches pixmaps by URL, so a reused path shows stale art.
    if not data:
        return None
    ext = sniff(data)
    if not ext:
        return None
    path = os.path.join(cache_dir, hashlib.sha256(data).hexdigest() + ext)
    if not os.path.exists(path):
        tmp = path + ".part"
        with open(tmp, "wb") as handle:
            handle.write(data)
        os.replace(tmp, path)
    return path


def read_file(path):
    try:
        if os.path.getsize(path) > MAX_BYTES:
            return None
        with open(path, "rb") as handle:
            return handle.read()
    except OSError:
        return None


def read_http(url):
    try:
        request = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
            return response.read(MAX_BYTES)
    except (urllib.error.URLError, OSError, ValueError):
        return None


def url_to_path(url):
    return urllib.parse.unquote(urllib.parse.urlparse(url).path)


def from_art_url(url):
    if not url:
        return None
    if url.startswith("data:"):
        head, _, payload = url.partition(",")
        try:
            if ";base64" in head:
                return base64.b64decode(payload)
            return urllib.parse.unquote_to_bytes(payload)
        except (ValueError, base64.binascii.Error):
            return None
    if url.startswith("file://"):
        return read_file(url_to_path(url))
    if url.startswith(("http://", "https://")):
        return read_http(url)
    if url.startswith("/"):
        return read_file(url)
    return None


def from_embedded(track_url):
    """Attached picture out of a local media file."""
    if not track_url or not track_url.startswith("file://"):
        return None
    path = url_to_path(track_url)
    if not os.path.isfile(path):
        return None

    # Copy first, re-encode only for covers image2 won't pass through.
    for codec in (["-c", "copy"], ["-c:v", "mjpeg"]):
        try:
            result = subprocess.run(
                ["ffmpeg", "-nostdin", "-loglevel", "error", "-i", path,
                 "-map", "0:v:0", "-frames:v", "1", "-f", "image2"]
                + codec + ["pipe:1"],
                capture_output=True, timeout=15,
            )
        except (OSError, subprocess.TimeoutExpired):
            return None
        if result.stdout and sniff(result.stdout):
            return result.stdout
    return None


def from_sidecar(track_url):
    """cover.jpg / folder.png / … sitting next to the track."""
    if not track_url or not track_url.startswith("file://"):
        return None
    directory = os.path.dirname(url_to_path(track_url))
    try:
        entries = sorted(os.listdir(directory))
    except OSError:
        return None
    for entry in entries:
        stem, ext = os.path.splitext(entry.lower())
        if stem in SIDECAR_STEMS and ext in SIDECAR_EXTS:
            data = read_file(os.path.join(directory, entry))
            if data and sniff(data):
                return data
    return None


def query_json(url):
    try:
        request = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
            return json.loads(response.read(MAX_BYTES))
    except (urllib.error.URLError, OSError, ValueError):
        return None


def from_online(artist, album, title):
    # No artist means a browser tab title, which matches arbitrary garbage.
    if not artist:
        return None
    term = "{} {}".format(artist, album or title).strip()
    if not term:
        return None
    quoted = urllib.parse.quote(term)

    payload = query_json("https://api.deezer.com/search?limit=1&q=" + quoted)
    if payload:
        for entry in payload.get("data") or []:
            art = (entry.get("album") or {}).get("cover_xl")
            if art:
                return read_http(art)

    payload = query_json(
        "https://itunes.apple.com/search?entity=album&limit=1&term=" + quoted
    )
    if payload:
        for entry in payload.get("results") or []:
            art = entry.get("artworkUrl100")
            if art:
                return read_http(art.replace("100x100", "600x600"))
    return None


def prune(cache_dir):
    try:
        entries = [os.path.join(cache_dir, e) for e in os.listdir(cache_dir)]
    except OSError:
        return
    files = [e for e in entries if os.path.isfile(e)]
    if len(files) <= CACHE_MAX:
        return
    files.sort(key=lambda p: os.path.getmtime(p))
    for path in files[:len(files) - CACHE_MAX]:
        try:
            os.remove(path)
        except OSError:
            pass


def main():
    if len(sys.argv) < 2:
        json.dump({"ok": False, "path": "", "source": "none"}, sys.stdout)
        return 1

    cache_dir = sys.argv[1]
    try:
        request = json.loads(sys.argv[2]) if len(sys.argv) > 2 else json.load(sys.stdin)
    except ValueError:
        request = {}

    os.makedirs(cache_dir, exist_ok=True)

    art_url = request.get("artUrl") or ""
    track_url = request.get("trackUrl") or ""
    title = request.get("title") or ""
    artist = request.get("artist") or ""
    album = request.get("album") or ""

    steps = [("artUrl", lambda: from_art_url(art_url))]
    if request.get("embedded", True):
        steps.append(("embedded", lambda: from_embedded(track_url)))
        steps.append(("sidecar", lambda: from_sidecar(track_url)))
    if request.get("online", False):
        steps.append(("online", lambda: from_online(artist, album, title)))

    for source, resolve in steps:
        path = store(cache_dir, resolve())
        if path:
            prune(cache_dir)
            json.dump({"ok": True, "path": path, "source": source}, sys.stdout)
            return 0

    json.dump({"ok": False, "path": "", "source": "none"}, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
