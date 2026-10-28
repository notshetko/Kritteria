#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VENV="$HOME/.local/share/end4-pC/lyrics-venv"
if [[ -x "$VENV/bin/python" ]]; then
    exec "$VENV/bin/python" "$SCRIPT_DIR/lyrics.py" "$@"
fi
exec python3 "$SCRIPT_DIR/lyrics.py" "$@"
