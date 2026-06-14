# Created by Kangy w/ OpenCode AI Assistance
# Version: 0.2.0-20260614

"""
Wallpaper Flare scraper — searches and downloads full-resolution wallpapers.
Full-res images found by visiting /download/ page and extracting img#show_img src.

Usage:
    python3 main.py --list --json [--keyword "nature"] [--page 1]
    python3 main.py --slug "..." --output /path/to/dir --json
"""

import sys
import json
import os
import re
from urllib.parse import urljoin

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print(json.dumps({"error": "install: pip install requests beautifulsoup4"}))
    sys.exit(1)

BASE = "https://www.wallpaperflare.com/"
HEADERS = {"User-Agent": "caelestia-niri-shell/1.0"}


def search_wallpapers(keyword="", page=1, resolution=None):
    if keyword:
        url = urljoin(BASE, f"/search?wallpaper={requests.utils.quote(keyword)}")
        if page > 1:
            url += f"&page={page}"
    else:
        url = urljoin(BASE, f"/")
        if page > 1:
            url = urljoin(BASE, f"/index.php?c=main&m=portal_loadmore&page={page}")

    resp = requests.get(url, headers=HEADERS, timeout=30)
    resp.raise_for_status()

    soup = BeautifulSoup(resp.text, "html.parser")
    results = []

    for li in soup.find_all("li", itemprop="associatedMedia"):
        link = li.find("a", itemprop="url")
        if not link:
            continue

        href = link.get("href", "")
        slug = href.rstrip("/").split("/")[-1] if href else ""

        img_tag = li.find("img", itemprop="contentUrl")
        if img_tag:
            thumb = img_tag.get("data-src", "") or img_tag.get("src", "")
        else:
            thumb = ""

        fig = li.find("figcaption", itemprop="caption description")
        title = fig.get_text(strip=True) if fig else ""

        res_span = li.find("span", class_="res")
        res = res_span.get_text(strip=True) if res_span else ""

        if slug and thumb:
            results.append({"slug": slug, "url_thumb": thumb, "resolution": res, "title": title})

    return results


def download_wallpaper(slug, output_dir, resolution=None):
    os.makedirs(output_dir, exist_ok=True)

    download_page = urljoin(BASE, f"/{slug}/download/")
    resp = requests.get(download_page, headers=HEADERS, timeout=30)
    resp.raise_for_status()

    soup = BeautifulSoup(resp.text, "html.parser")
    img = soup.find("img", id="show_img")
    if not img or not img.get("src"):
        raise RuntimeError("Could not find full image on download page")

    img_url = img["src"]

    ext = ".jpg"
    if img_url.endswith(".png"):
        ext = ".png"
    elif img_url.endswith(".webp"):
        ext = ".webp"

    filename = f"{slug}{ext}"
    filepath = os.path.join(output_dir, filename)

    img_resp = requests.get(img_url, headers=HEADERS, timeout=120, stream=True)
    img_resp.raise_for_status()

    with open(filepath, "wb") as f:
        for chunk in img_resp.iter_content(8192):
            f.write(chunk)

    return filepath


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(1)

    keyword = ""
    page = 1
    resolution = None
    slug = None
    output_dir = None
    json_out = False
    list_mode = False

    i = 0
    while i < len(args):
        a = args[i]
        if a == "--keyword" and i + 1 < len(args):
            i += 1
            keyword = args[i]
        elif a == "--page" and i + 1 < len(args):
            i += 1
            page = int(args[i])
        elif a == "--resolution" and i + 1 < len(args):
            i += 1
            resolution = args[i]
        elif a == "--slug" and i + 1 < len(args):
            i += 1
            slug = args[i]
        elif a == "--output" and i + 1 < len(args):
            i += 1
            output_dir = args[i]
        elif a == "--json":
            json_out = True
        elif a == "--list":
            list_mode = True
        i += 1

    if slug and output_dir:
        try:
            path = download_wallpaper(slug, output_dir, resolution)
            if json_out:
                print(json.dumps({"status": "success", "path": path}))
        except Exception as e:
            if json_out:
                print(json.dumps({"status": "error", "message": str(e)}))
            else:
                print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

    elif list_mode:
        try:
            results = search_wallpapers(keyword, page, resolution)
            if json_out:
                print(json.dumps(results))
            else:
                for r in results:
                    print(f"{r.get('slug')} | {r.get('resolution', '?')} | {r.get('title', '')}")
        except Exception as e:
            if json_out:
                print(json.dumps([]))
            else:
                print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
