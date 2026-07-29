#!/usr/bin/env bash
set -euo pipefail

force=false
target=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=true
      ;;
    -h | --help)
      printf 'usage: %s [--force] <project-directory>\n' "$0"
      exit 0
      ;;
    -*)
      printf 'usage: %s [--force] <project-directory>\n' "$0" >&2
      exit 2
      ;;
    *)
      if [[ -n "$target" ]]; then
        printf 'error: multiple project directories provided\n' >&2
        exit 2
      fi
      target="$1"
      ;;
  esac
  shift
done

if [[ -z "$target" ]]; then
  printf 'usage: %s [--force] <project-directory>\n' "$0" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_dir="$repo_root/templates/project-docs"

if [[ ! -d "$template_dir" ]]; then
  printf 'error: template directory missing: %s\n' "$template_dir" >&2
  exit 1
fi

mkdir -p "$target"
target="$(cd "$target" && pwd)"

created=0
skipped=0
overwritten=0

for source in "$template_dir"/*; do
  [[ -f "$source" ]] || continue
  name="$(basename "$source")"
  dest="$target/$name"

  if [[ -e "$dest" && "$force" != true ]]; then
    printf 'skip (exists): %s\n' "$dest"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ -e "$dest" && "$force" == true ]]; then
    printf 'overwrite: %s\n' "$dest"
    overwritten=$((overwritten + 1))
  else
    printf 'create: %s\n' "$dest"
    created=$((created + 1))
  fi

  cp "$source" "$dest"
done

printf '\nbootstrap complete for %s\n' "$target"
printf 'created=%d skipped=%d overwritten=%d\n' "$created" "$skipped" "$overwritten"
printf 'Next: adapt AGENTS.md, SPEC.md, ROADMAP.md, and TASKS.md to this project.\n'
