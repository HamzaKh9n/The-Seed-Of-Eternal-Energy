#!/bin/sh
printf '\033c\033]0;%s\a' Beneath-The-Smog
base_path="$(dirname "$(realpath "$0")")"
"$base_path/TheEternalSeed.x86_64" "$@"
