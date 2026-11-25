#!/bin/sh
# Copyright 2026 Udo Schmitz
# Licensed under the Apache License, Version 2.0 (see LICENSE).
# file: article/build_pdf.sh
# purpose: article/article.md to article/article.pdf: Julia Markdown to HTML,
#          figures embedded, tables at full width, LibreOffice Writer import
#          to PDF. Needs julia, python3 and LibreOffice (soffice, or the
#          flatpak org.libreoffice.LibreOffice).
# usage:   sh article/build_pdf.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
w=$(mktemp -d "$HOME/.article_pdf.XXXXXX")
julia --startup-file=no "$here/md2html.jl" "$here/article.md" "$w/article.html"
python3 -I - "$w/article.html" "$here/figures" <<'PY'
import re, sys, base64, os
p, figdir = sys.argv[1], sys.argv[2]
s = open(p, encoding="utf-8").read()
s = re.sub(r"<style>.*?</style>", '<style>body{font-family:"DejaVu Serif";font-size:10pt} td,th{font-size:9pt} code{font-family:"DejaVu Sans Mono";font-size:8.5pt}</style>', s, flags=re.S)
s = s.replace("<table>", '<table width="100%" border="1" cellpadding="3">')
def emb(m):
    data = base64.b64encode(open(os.path.join(figdir, os.path.basename(m.group(1))), "rb").read()).decode()
    return '<img src="data:image/png;base64,' + data + '" width="640"/><br/><i>' + m.group(2) + "</i>"
s = re.sub(r'<img src="([^"]+)" alt="([^"]*)"\s*/?>', emb, s)
open(p, "w", encoding="utf-8").write(s)
PY
if command -v soffice >/dev/null 2>&1; then
  soffice --headless --infilter="HTML (StarWriter)" --convert-to pdf:writer_pdf_Export --outdir "$w" "$w/article.html" >/dev/null 2>&1
else
  flatpak run --filesystem="$w" org.libreoffice.LibreOffice --headless --infilter="HTML (StarWriter)" --convert-to pdf:writer_pdf_Export --outdir "$w" "$w/article.html" >/dev/null 2>&1
fi
cp "$w/article.pdf" "$here/article.pdf"
rm -rf "$w"
echo "written $here/article.pdf"
