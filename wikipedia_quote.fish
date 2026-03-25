#!/usr/bin/env fish
#
# wikipedia_quote.fish — Fetch the daily quote from Wikipedia / Wikiquote
#
# Usage:  ./wikipedia_quote.fish
#
# ── How to add a new language ─────────────────────────────────────────────────
#   1. Append the language key, display name, and URL to the three LANG_* lists.
#   2. Add a  set -g _PY_<KEY>  variable with the Python extraction code.
#   3. Add a  parse_<key>  function that pipes the fetched page into that code.
# ─────────────────────────────────────────────────────────────────────────────

# ── Language Registry ────────────────────────────────────────────────────────

set -g LANG_KEYS  es  en  nl

set -g LANG_NAMES \
    "Español   — Wikipedia  (Frase del día)" \
    "English   — Wikiquote  (Quote of the Day)" \
    "Nederlands — Wikiquote  (Citaat van de dag)"

set -g LANG_URLS \
    "https://es.wikipedia.org/wiki/Wikipedia:Frase_del_d%C3%ADa" \
    "https://en.wikiquote.org/wiki/Main_Page" \
    "https://nl.wikiquote.org/wiki/Hoofdpagina"

# ── Python extraction scripts (stored in single-quoted Fish variables) ────────
# Single-quoted Fish strings are passed 100 % literally — no escaping needed.
# All Python string literals therefore use double quotes to stay compatible.

set -g _PY_ES '
import sys, re, html as html_mod
from datetime import date

MONTHS_ES = ["enero","febrero","marzo","abril","mayo","junio",
             "julio","agosto","septiembre","octubre","noviembre","diciembre"]

today = date.today()
month_str = MONTHS_ES[today.month - 1]

# Wikipedia uses anchors like "24_de_marzo" for each day entry
anchors = [
    str(today.day) + "_de_" + month_str,
    str(today.day) + "_" + month_str,
    str(today.day) + "de" + month_str,
]

content = sys.stdin.read()

def strip_tags(s):
    s = re.sub(r"<[^>]+>", " ", s)
    s = html_mod.unescape(s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

found = ""

# Look for the section whose id matches today and grab the next blockquote/p/td
for anchor in anchors:
    escaped = re.escape(anchor)
    # id=[^>]*<anchor>[^>]*>  — robust: avoids quoting the id delimiters
    pattern = r"id=[^>]*" + escaped + r"[^>]*>.*?(<(?:blockquote|td|p)[^>]*>.*?</(?:blockquote|td|p)>)"
    m = re.search(pattern, content, re.DOTALL | re.IGNORECASE)
    if m:
        text = strip_tags(m.group(1))
        if len(text) > 20:
            found = text
            break

# Fallback 1: first <blockquote> on the page
if not found:
    m = re.search(r"<blockquote[^>]*>(.*?)</blockquote>", content, re.DOTALL | re.IGNORECASE)
    if m:
        found = strip_tags(m.group(1))

# Fallback 2: first sizeable <p>
if not found:
    for m in re.finditer(r"<p[^>]*>(.*?)</p>", content, re.DOTALL | re.IGNORECASE):
        text = strip_tags(m.group(1))
        if len(text) > 40:
            found = text
            break

print(found if found else "[Quote not found — the page structure may have changed]")
'

set -g _PY_EN '
import sys, re, html as html_mod

content = sys.stdin.read()

def strip_tags(s):
    s = re.sub(r"<[^>]+>", " ", s)
    s = html_mod.unescape(s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

def best_para(html_frag):
    """Return the first non-trivial paragraph or blockquote text."""
    for m in re.finditer(r"<p[^>]*>(.*?)</p>", html_frag, re.DOTALL | re.IGNORECASE):
        text = strip_tags(m.group(1))
        if len(text) > 20:
            return text
    m = re.search(r"<blockquote[^>]*>(.*?)</blockquote>", html_frag, re.DOTALL | re.IGNORECASE)
    if m:
        text = strip_tags(m.group(1))
        if len(text) > 20:
            return text
    return ""

found = ""

# 1) Mobile / MinervaNeue skin:  id="mf-qotd"
m = re.search(r"id=[^>]*mf-qotd[^>]*>(.*?)</(?:div|section)>", content, re.DOTALL | re.IGNORECASE)
if m:
    found = best_para(m.group(1))

# 2) Desktop Vector skin:  id="mp-right"
if not found:
    m = re.search(r"id=[^>]*mp-right[^>]*>(.*?)</td>", content, re.DOTALL | re.IGNORECASE)
    if m:
        found = best_para(m.group(1))

# 3) Any element whose id contains "qotd"
if not found:
    m = re.search(r"id=[^>]*qotd[^>]*>(.*?)</(?:div|td|section)>", content, re.DOTALL | re.IGNORECASE)
    if m:
        found = best_para(m.group(1))

# 4) First <p> after the heading "Quote of the Day"
if not found:
    m = re.search(r"Quote of the [Dd]ay.*?<p[^>]*>(.*?)</p>", content, re.DOTALL)
    if m:
        found = strip_tags(m.group(1))

print(found if found else "[Quote not found — the page structure may have changed]")
'

set -g _PY_NL '
import sys, re, html as html_mod

content = sys.stdin.read()

def strip_tags(s):
    s = re.sub(r"<[^>]+>", " ", s)
    s = html_mod.unescape(s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

def best_para(html_frag):
    for m in re.finditer(r"<p[^>]*>(.*?)</p>", html_frag, re.DOTALL | re.IGNORECASE):
        text = strip_tags(m.group(1))
        if len(text) > 20:
            return text
    m = re.search(r"<blockquote[^>]*>(.*?)</blockquote>", html_frag, re.DOTALL | re.IGNORECASE)
    if m:
        text = strip_tags(m.group(1))
        if len(text) > 20:
            return text
    return ""

found = ""

# 1) id="mf-qotd"  (used by many Wikiquote wikis)
m = re.search(r"id=[^>]*mf-qotd[^>]*>(.*?)</(?:div|section)>", content, re.DOTALL | re.IGNORECASE)
if m:
    found = best_para(m.group(1))

# 2) Any element whose id contains "citaat" or "qotd"
if not found:
    m = re.search(r"id=[^>]*(?:citaat|qotd)[^>]*>(.*?)</(?:div|td|section)>", content, re.DOTALL | re.IGNORECASE)
    if m:
        found = best_para(m.group(1))

# 3) First <p> or <blockquote> after the heading "Citaat van de dag"
if not found:
    m = re.search(r"Citaat van de dag.*?<(?:p|blockquote)[^>]*>(.*?)</(?:p|blockquote)>", content, re.DOTALL)
    if m:
        found = strip_tags(m.group(1))

# 4) Desktop skin fallback: id="mp-right"
if not found:
    m = re.search(r"id=[^>]*mp-right[^>]*>(.*?)</td>", content, re.DOTALL | re.IGNORECASE)
    if m:
        found = best_para(m.group(1))

print(found if found else "[Quote not found — de paginastructuur is mogelijk veranderd]")
'

# ── Shared helpers ────────────────────────────────────────────────────────────

function _check_deps
    for cmd in curl python3 fold
        if not command -v $cmd >/dev/null 2>/dev/null
            echo "Error: '$cmd' is required but not installed." >&2
            return 1
        end
    end
end

# _fetch_page <url> <accept-language-header>
function _fetch_page
    curl -sL --max-time 20 \
        -A "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0" \
        -H "Accept-Language: $argv[2]" \
        -H "Accept: text/html,application/xhtml+xml" \
        "$argv[1]"
end

function _display_quote
    set -l lang_name $argv[1]
    set -l quote $argv[2]
    set -l line (string repeat -n 60 "─")
    echo ""
    echo "  $line"
    set_color --bold cyan
    printf "  %s\n" $lang_name
    set_color normal
    echo "  $line"
    echo ""
    # Word-wrap at 56 columns, indent each line
    echo $quote | fold -s -w 56 | while read -l qline
        printf "    %s\n" $qline
    end
    echo ""
    echo "  $line"
    echo ""
end

# ── Per-language parsers ──────────────────────────────────────────────────────
# Pipe the fetched HTML directly into the matching Python script.

function parse_es
    _fetch_page $argv[1] "es,es-ES;q=0.9" | python3 -c "$_PY_ES"
end

function parse_en
    _fetch_page $argv[1] "en,en-US;q=0.9" | python3 -c "$_PY_EN"
end

function parse_nl
    _fetch_page $argv[1] "nl,nl-NL;q=0.9" | python3 -c "$_PY_NL"
end

# ── Menu ──────────────────────────────────────────────────────────────────────

function _show_menu
    echo ""
    set_color --bold cyan
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║        Wikipedia Daily Quote Fetcher         ║"
    echo "  ╚══════════════════════════════════════════════╝"
    set_color normal
    echo ""
    for i in (seq (count $LANG_KEYS))
        printf "    \033[1;33m%d)\033[0m  %s\n" $i $LANG_NAMES[$i]
    end
    echo ""
    printf "    \033[1;31m0)\033[0m  Quit\n"
    echo ""
end

# ── Entry point ───────────────────────────────────────────────────────────────

_check_deps; or exit 1

set -l total (count $LANG_KEYS)

while true
    _show_menu
    read -P "  Choose a language [0-$total]: " choice

    # Validate: must be a non-negative integer
    if not string match -qr '^[0-9]+$' -- $choice
        printf "  Please enter a number between 0 and %d.\n" $total
        continue
    end

    if test "$choice" = "0"
        echo "  Goodbye!"
        break
    end

    if test $choice -lt 1; or test $choice -gt $total
        printf "  Please enter a number between 0 and %d.\n" $total
        continue
    end

    set -l key  $LANG_KEYS[$choice]
    set -l name $LANG_NAMES[$choice]
    set -l url  $LANG_URLS[$choice]

    printf "\n  \033[90mFetching — please wait...\033[0m\n"
    set -l quote (parse_$key $url)
    _display_quote $name $quote
end

