#!/usr/bin/env bash
# 클라우드 세션에 Godot 4.4.1과 웹 내보내기 템플릿을 설치한다.
set -euo pipefail
VER=4.4.1
URL=https://github.com/godotengine/godot/releases/download/${VER}-stable
TMP=$(mktemp -d)
if ! command -v godot >/dev/null; then
  curl -sSL -o "$TMP/godot.zip" "$URL/Godot_v${VER}-stable_linux.x86_64.zip"
  mkdir -p /opt/godot && unzip -oq "$TMP/godot.zip" -d /opt/godot
  mv -f /opt/godot/Godot_v${VER}-stable_linux.x86_64 /opt/godot/godot
  ln -sf /opt/godot/godot /usr/local/bin/godot
fi
TPL=~/.local/share/godot/export_templates/${VER}.stable
if [ ! -f "$TPL/web_nothreads_release.zip" ]; then
  curl -sSL -o "$TMP/tpl.tpz" "$URL/Godot_v${VER}-stable_export_templates.tpz"
  mkdir -p "$TPL"
  unzip -joq "$TMP/tpl.tpz" 'templates/web_nothreads_*' 'templates/version.txt' -d "$TPL"
fi
rm -rf "$TMP"
godot --version --headless
