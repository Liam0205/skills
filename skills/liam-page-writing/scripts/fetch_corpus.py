#!/usr/bin/env python3
"""把站点的全部文章抓成 Markdown 语料，供写作蒸馏使用。

只用于抓取自己拥有或已获授权的站点。默认按 sitemap 里的日期目录识别文章，
可用 --before / --after 限定年份。

依赖: beautifulsoup4 lxml

用法:
    python3 fetch_corpus.py --site https://liam.page --before 2026 --out ./samples
"""
import argparse
import json
import os
import re
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

from bs4 import BeautifulSoup

DROP_SEL = [
    ".post-footer", ".post-nav", ".post-copyright", ".post-widgets",
    ".post-header", ".headerlink", "script", "style", ".reward-container",
    ".post-tags", ".post-meta",
]


def code_text(fig):
    lang = ""
    m = re.search(r"highlight (\S+)", " ".join(fig.get("class") or []))
    if m:
        lang = m.group(1)
    for g in fig.select("td.gutter, .gutter"):
        g.decompose()
    td = fig.select_one("td.code") or fig.select_one("pre") or fig
    lines = [ln.get_text() for ln in td.select("span.line")]
    if not lines:
        return lang, td.get_text()
    return lang, "\n".join(lines)


def to_md(node):
    for fig in node.select("figure.highlight, .highlight"):
        lang, code = code_text(fig)
        fig.replace_with("\n```%s\n%s\n```\n" % (lang, code))
    for pre in node.find_all("pre"):
        pre.replace_with("\n```\n%s\n```\n" % pre.get_text())
    for tag, mark in [("h1", "#"), ("h2", "##"), ("h3", "###"), ("h4", "####"),
                      ("h5", "#####"), ("h6", "######")]:
        for h in node.find_all(tag):
            h.replace_with("\n%s %s\n" % (mark, h.get_text().strip()))
    for st in node.find_all("strong"):
        st.replace_with("**%s**" % st.get_text())
    for em in node.find_all("em"):
        em.replace_with("*%s*" % em.get_text())
    for a in node.find_all("a"):
        txt, href = a.get_text().strip(), a.get("href", "")
        a.replace_with("[%s](%s)" % (txt, href) if href else txt)
    for img in node.find_all("img"):
        src = img.get("src") or img.get("data-src") or ""
        img.replace_with("\n![%s](%s)\n" % (img.get("alt") or "", src))
    for li in node.find_all("li"):
        li.replace_with("\n- %s" % li.get_text().strip())
    for p in node.find_all(["p", "div", "blockquote", "tr", "figure", "figcaption"]):
        p.replace_with("\n%s\n" % p.get_text().strip())
    for br in node.find_all("br"):
        br.replace_with("\n")
    txt = node.get_text()
    txt = re.sub(r"\n{3,}", "\n\n", txt)
    txt = re.sub(r"[ \t]+\n", "\n", txt)
    return txt.strip()


def fetch(url, raw_dir):
    for attempt in range(3):
        try:
            req = urllib.request.Request(
                url, headers={"User-Agent": "Mozilla/5.0 (compatible; corpus-fetch)"})
            html = urllib.request.urlopen(req, timeout=40).read().decode("utf-8", "replace")
            soup = BeautifulSoup(html, "lxml")
            art = soup.select_one("article")
            if not art:
                return {"url": url, "error": "no <article> (可能是重定向页)"}
            title_el = art.select_one(".post-title") or soup.title
            title = title_el.get_text().strip() if title_el else ""
            dm = re.search(r"/(\d{4})/(\d{2})/(\d{2})/", url)
            if not dm:
                return {"url": url, "error": "URL 里没有日期"}
            date = "-".join(dm.groups())

            cats, tags = [], []
            meta_box = art.select_one(".post-meta")
            if meta_box:
                mt = meta_box.get_text(" ", strip=True)
                m = re.search(r"分类于\s*(.+?)(?:本文字数|阅读时长|阅读次数|$)", mt)
                if m:
                    cats = [c.strip() for c in re.split(r"[,/]", m.group(1)) if c.strip()]
            tb = art.select_one(".post-tags")
            if tb:
                tags = [t.strip().lstrip("#").strip()
                        for t in tb.get_text("\n", strip=True).split("\n") if t.strip()]

            body = art.select_one(".post-body") or art
            for sel in DROP_SEL:
                for n in body.select(sel):
                    n.decompose()
            md = to_md(body)

            slug = re.sub(r"[/\\]", "-", url.rstrip("/").split("/")[-1][:80])
            fname = "%s %s.md" % (date, slug)
            head = "---\ntitle: %s\nurl: %s\ndate: %s\ncategories: %s\ntags: %s\n---\n\n" % (
                json.dumps(title, ensure_ascii=False), url, date,
                json.dumps(cats, ensure_ascii=False), json.dumps(tags, ensure_ascii=False))
            with open(os.path.join(raw_dir, fname), "w", encoding="utf-8") as f:
                f.write(head + md)
            return {
                "file": fname, "url": url, "date": date, "title": title,
                "categories": cats, "tags": tags, "chars": len(md),
                "images": len(re.findall(r"!\[", md)),
                "code_blocks": md.count("```") // 2,
                "code_chars": sum(len(x) for x in re.findall(r"```.*?\n(.*?)```", md, re.S)),
            }
        except Exception as e:  # noqa: BLE001
            if attempt == 2:
                return {"url": url, "error": str(e)}
            time.sleep(1.5 * (attempt + 1))
    return {"url": url, "error": "unreachable"}


def main():
    ap = argparse.ArgumentParser(description="抓取站点文章为 Markdown 语料")
    ap.add_argument("--site", required=True, help="站点根地址，如 https://liam.page")
    ap.add_argument("--out", default="./samples", help="输出目录")
    ap.add_argument("--before", type=int, help="只抓这一年之前的文章")
    ap.add_argument("--after", type=int, help="只抓这一年及之后的文章")
    ap.add_argument("--workers", type=int, default=6)
    args = ap.parse_args()

    art_dir = os.path.join(args.out, "full")
    os.makedirs(art_dir, exist_ok=True)
    os.makedirs(args.out, exist_ok=True)

    sm_url = args.site.rstrip("/") + "/sitemap.xml"
    req = urllib.request.Request(sm_url, headers={"User-Agent": "Mozilla/5.0"})
    xml = urllib.request.urlopen(req, timeout=30).read().decode("utf-8", "replace")
    urls = re.findall(r"<loc>(.*?)</loc>", xml)
    articles = [u for u in urls if re.search(r"/\d{4}/\d{2}/\d{2}/", u)]
    if args.before:
        articles = [u for u in articles
                    if int(re.search(r"/(\d{4})/", u).group(1)) < args.before]
    if args.after:
        articles = [u for u in articles
                    if int(re.search(r"/(\d{4})/", u).group(1)) >= args.after]
    articles = sorted(set(articles))
    print("待抓取 %d 篇" % len(articles))

    rows = []
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(fetch, u, art_dir) for u in articles]
        done = 0
        for f in as_completed(futs):
            r = f.result()
            done += 1
            if r:
                rows.append(r)
            if done % 100 == 0:
                print("  %d/%d" % (done, len(articles)), flush=True)

    ok = [r for r in rows if "error" not in r]
    bad = [r for r in rows if "error" in r]
    with open(os.path.join(args.out, "index.json"), "w", encoding="utf-8") as f:
        json.dump(ok, f, ensure_ascii=False, indent=1)
    print("成功 %d 篇，失败 %d 篇，共 %d 汉字"
          % (len(ok), len(bad), sum(r["chars"] for r in ok)))
    for r in bad[:10]:
        print("  失败:", r["url"], r["error"][:70])


if __name__ == "__main__":
    main()
