#!/bin/bash
set -e

echo "=== SkillTrack Vercel Web Build ==="

# 1. Download Flutter SDK if not cached
if [ ! -d "_flutter/bin" ]; then
  echo "[*] Cloning Flutter stable channel..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
fi

# 2. Add Flutter to PATH
export PATH="$PATH:$(pwd)/_flutter/bin"
echo "[+] Flutter path configured: $(which flutter)"

# 3. Verify Flutter environment
flutter --version

# 4. Fetch dependencies
flutter pub get

# 5. Build Flutter Web release
echo "[*] Compiling Flutter Web..."
flutter build web --release

# 6. Ensure sqlite3.wasm is in build/web
if [ -f "web/sqlite3.wasm" ]; then
  cp web/sqlite3.wasm build/web/sqlite3.wasm
fi

echo "=== Build Complete! Output directory: build/web ==="
