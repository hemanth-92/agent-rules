#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_dir="$repo_root/templates/project-docs"

if [[ ! -d "$template_dir" ]]; then
  printf 'error: template directory missing: %s\n' "$template_dir" >&2
  exit 1
fi

# Marker every unadapted template carries; see templates/project-docs.
template_marker='^> Status: TEMPLATE'

force=false
target=""
only_docs=()

# Doc names selectable with --only, derived from the template file names.
doc_names() {
  local source name
  for source in "$template_dir"/*; do
    [[ -f "$source" ]] || continue
    name="$(basename "$source")"
    printf '%s\n' "${name%.md}"
  done
}

contains_element() {
  local needle="$1"
  shift
  local candidate
  for candidate in "$@"; do
    [[ "$candidate" == "$needle" ]] && return 0
  done
  return 1
}

usage() {
  printf 'usage: %s [--force] [--only NAMES] <project-directory>\n\n' "$0"
  printf '  --force        overwrite files that already exist\n'
  printf '  --only NAMES   comma-separated docs to copy (repeatable)\n'
  printf '                 available: %s\n' "$(doc_names | paste -sd, -)"
}

add_only() {
  local raw="$1" part
  IFS=',' read -r -a parts <<<"$raw"
  for part in ${parts[@]+"${parts[@]}"}; do
    [[ -n "$part" ]] && only_docs+=("$part")
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=true
      ;;
    --only)
      if [[ $# -lt 2 ]]; then
        printf 'error: --only requires a value\n' >&2
        exit 2
      fi
      add_only "$2"
      shift
      ;;
    --only=*)
      add_only "${1#*=}"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      usage >&2
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
  usage >&2
  exit 2
fi

mapfile -t available_docs < <(doc_names)

for name in ${only_docs[@]+"${only_docs[@]}"}; do
  if ! contains_element "$name" "${available_docs[@]}"; then
    printf 'error: unknown doc: %s\n' "$name" >&2
    printf 'available docs: %s\n' "${available_docs[*]}" >&2
    exit 2
  fi
done

mkdir -p "$target"
target="$(cd "$target" && pwd)"

created=0
skipped=0
overwritten=0
unadapted=()

for source in "$template_dir"/*; do
  [[ -f "$source" ]] || continue
  name="$(basename "$source")"
  dest="$target/$name"

  if ((${#only_docs[@]} > 0)) && ! contains_element "${name%.md}" "${only_docs[@]}"; then
    continue
  fi

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

# Report docs that still carry the template marker, including ones a previous
# run created and nobody has adapted yet.
for source in "$template_dir"/*; do
  [[ -f "$source" ]] || continue
  dest="$target/$(basename "$source")"
  [[ -f "$dest" ]] || continue
  if grep -q "$template_marker" "$dest"; then
    unadapted+=("$(basename "$dest")")
  fi
done

printf '\nbootstrap complete for %s\n' "$target"
printf 'created=%d skipped=%d overwritten=%d\n' "$created" "$skipped" "$overwritten"

if ((${#unadapted[@]} > 0)); then
  printf '\nwarning: %d doc(s) still marked TEMPLATE: %s\n' \
    "${#unadapted[@]}" "${unadapted[*]}"
  printf 'Adapt each one and delete its "> Status: TEMPLATE" line.\n'
  printf 'Agents read an unadapted template as if it were real content.\n'
else
  printf '\nAll project docs are adapted.\n'
fi
