#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT="${1:-"$SCRIPT_DIR/function.zip"}"
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

mkdir -p "$(dirname "$ARTIFACT")"

tar -C "$SCRIPT_DIR" -cf - ./handler.py \
  | tar -C "$BUILD_DIR" --strip-components=1 -xf -

python - "$BUILD_DIR" "$ARTIFACT" <<'PY'
import os
import stat
import sys
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

build_dir = Path(sys.argv[1])
artifact = Path(sys.argv[2])

with ZipFile(artifact, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
    for root, dirs, files in os.walk(build_dir):
        dirs.sort()
        for filename in sorted(files):
            source = Path(root) / filename
            relative_path = source.relative_to(build_dir).as_posix()
            info = ZipInfo(relative_path)
            info.date_time = (1980, 1, 1, 0, 0, 0)
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            archive.writestr(info, source.read_bytes())
PY

echo "Wrote $ARTIFACT"
