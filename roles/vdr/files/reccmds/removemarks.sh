#!/usr/bin/env sh
find "$1" -maxdepth 1 \( -name "marks" -o -name "marks.vdr" \) -delete
