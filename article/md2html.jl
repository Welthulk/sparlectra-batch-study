# Copyright 2026 Udo Schmitz
# Licensed under the Apache License, Version 2.0 (see LICENSE).
# file: article/md2html.jl
# Markdown to a printable HTML page (standard library only)
using Markdown
src, out = ARGS[1], ARGS[2]
text = read(src, String)
text = replace(text, r"<!--.*?-->"s => "")
body = Markdown.html(Markdown.parse(text))
css = """
body { font-family: 'DejaVu Serif', serif; font-size: 10.5pt; line-height: 1.4; max-width: 17cm; margin: 1.5cm auto; color: #111; }
h1 { font-size: 17pt; } h2 { font-size: 13pt; margin-top: 1.4em; } h3 { font-size: 11pt; }
table { border-collapse: collapse; margin: 0.6em 0; font-size: 9pt; }
th, td { border: 1px solid #999; padding: 2px 6px; text-align: left; }
code { font-family: 'DejaVu Sans Mono', monospace; font-size: 8.5pt; }
pre { font-size: 8pt; background: #f4f4f4; padding: 6px; white-space: pre-wrap; }
"""
open(out, "w") do io
  print(io, "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>Batches of power flows on one workstation: processes, threads and a GPU</title><style>", css, "</style></head><body>", body, "</body></html>")
end
