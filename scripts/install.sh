#!/usr/bin/env bash
set -euo pipefail

dry_run=false
install_plugins=false
install_claude=false
install_grok=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=true
      ;;
    --plugins)
      install_plugins=true
      ;;
    --claude)
      install_claude=true
      ;;
    --grok)
      install_grok=true
      ;;
    -h | --help)
      printf 'usage: %s [--dry-run] [--plugins] [--claude] [--grok]\n' "$0"
      exit 0
      ;;
    *)
      printf 'usage: %s [--dry-run] [--plugins] [--claude] [--grok]\n' "$0" >&2
      exit 2
      ;;
  esac
  shift
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
agents_home="${AGENTS_HOME:-$HOME/.agents}"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
grok_home="${GROK_HOME:-$HOME/.grok}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="$codex_home/backups/agent-rules-$timestamp-$$"
plugin_manifest="$repo_root/codex-plugins.txt"
config_source="$repo_root/codex-home/config.toml"
coding_root="$HOME/coding"
github_root="$HOME/github"
rendered_config=""

if "$install_plugins"; then
  if [[ ! -f "$plugin_manifest" ]]; then
    printf 'error: plugin manifest does not exist: %s\n' "$plugin_manifest" >&2
    exit 1
  fi
  if ! "$dry_run" && ! command -v codex >/dev/null 2>&1; then
    printf 'error: codex is required when using --plugins\n' >&2
    exit 1
  fi
fi

run() {
  if "$dry_run"; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

cleanup() {
  if [[ -n "$rendered_config" && -f "$rendered_config" ]]; then
    rm -f -- "$rendered_config"
  fi
}
trap cleanup EXIT

ensure_parent() {
  run mkdir -p "$(dirname "$1")"
}

resolve_path() {
  local path="$1"
  local directory
  local hops=0
  local link_target

  while [[ -L "$path" ]]; do
    hops=$((hops + 1))
    if ((hops > 64)); then
      printf 'error: too many symbolic-link hops: %s\n' "$1" >&2
      return 2
    fi

    if ! directory="$(cd -P "$(dirname "$path")" && pwd)"; then
      return 1
    fi
    if ! link_target="$(readlink "$path")"; then
      return 1
    fi
    if [[ "$link_target" == /* ]]; then
      path="$link_target"
    else
      path="$directory/$link_target"
    fi
  done

  if [[ -d "$path" ]]; then
    if ! directory="$(cd -P "$path" && pwd)"; then
      return 1
    fi
    printf '%s\n' "$directory"
    return
  fi

  if ! directory="$(cd -P "$(dirname "$path")" && pwd)"; then
    return 1
  fi
  printf '%s/%s\n' "$directory" "$(basename "$path")"
}

backup_path_for() {
  local target="$1"
  local relative
  local backup

  if [[ "$target" == "$codex_home/"* ]]; then
    relative="${target#"$codex_home"/}"
    backup="$backup_root/$relative"
  elif [[ "$target" == "$agents_home/"* ]]; then
    relative="${target#"$agents_home"/}"
    backup="$backup_root/agents/$relative"
  elif [[ "$target" == "$claude_home/"* ]]; then
    relative="${target#"$claude_home"/}"
    backup="$backup_root/claude/$relative"
  elif [[ "$target" == "$grok_home/"* ]]; then
    relative="${target#"$grok_home"/}"
    backup="$backup_root/grok/$relative"
  else
    relative="$(basename "$target")"
    backup="$backup_root/other/$relative"
  fi

  printf '%s\n' "$backup"
}

link_managed_path() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    printf 'error: managed source does not exist: %s\n' "$source" >&2
    exit 1
  fi

  ensure_parent "$target"

  if [[ -L "$target" ]]; then
    local resolved_source
    local resolved_target=""
    local resolve_status=0

    if ! resolved_source="$(resolve_path "$source")"; then
      return 1
    fi

    if resolved_target="$(resolve_path "$target")"; then
      resolve_status=0
    else
      resolve_status=$?
    fi

    if ((resolve_status != 0 && resolve_status != 2)); then
      return "$resolve_status"
    fi

    if ((resolve_status == 0)) && [[ "$resolved_target" == "$resolved_source" ]]; then
      printf 'already linked: %s\n' "$target"
      return
    fi
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup
    backup="$(backup_path_for "$target")"
    ensure_parent "$backup"
    run mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  run ln -s "$source" "$target"
  printf 'linked: %s -> %s\n' "$target" "$source"
}

append_trusted_project() {
  local config_file="$1"
  local project_path="$2"
  local escaped_path="$project_path"
  local table_header

  if [[ "$project_path" =~ [[:cntrl:]] ]]; then
    printf 'error: project path contains unsupported control characters: %q\n' \
      "$project_path" >&2
    exit 1
  fi

  escaped_path="${escaped_path//\\/\\\\}"
  escaped_path="${escaped_path//\"/\\\"}"
  table_header="[projects.\"$escaped_path\"]"

  if grep -Fqx "$table_header" "$config_file"; then
    return
  fi

  printf '\n%s\ntrust_level = "trusted"\n' "$table_header" >>"$config_file"
}

discover_git_projects() {
  local root="$1"
  local git_marker
  local project_path

  if [[ ! -d "$root" ]]; then
    return
  fi

  append_trusted_project "$rendered_config" "$root"

  while IFS= read -r -d '' git_marker; do
    project_path="${git_marker%/.git}"
    append_trusted_project "$rendered_config" "$project_path"
  done < <(
    find "$root" \
      \( -name .git -o -name node_modules -o -name .venv -o -name venv \
      -o -name target -o -name build -o -name dist \) -prune \
      -name .git -print0 2>/dev/null || true
  )
}

render_managed_config() {
  rendered_config="$(mktemp "${TMPDIR:-/tmp}/agent-rules-config.XXXXXX")"
  cp "$config_source" "$rendered_config"
  printf '\n# Generated by the agent-rules installer. Rerun after adding repositories.\n' \
    >>"$rendered_config"

  discover_git_projects "$coding_root"
  discover_git_projects "$github_root"
}

install_managed_config() {
  local target="$1"

  ensure_parent "$target"

  if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$rendered_config" "$target"; then
    printf 'already installed: %s\n' "$target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup
    backup="$(backup_path_for "$target")"
    ensure_parent "$backup"
    run mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  run cp "$rendered_config" "$target"
  printf 'installed: %s\n' "$target"
}

install_recommended_plugins() {
  local plugin

  while IFS= read -r plugin || [[ -n "$plugin" ]]; do
    [[ -n "$plugin" ]] || continue
    [[ "$plugin" =~ ^# ]] && continue
    run codex plugin add "$plugin"
  done <"$plugin_manifest"
}

install_skills_into() {
  local skills_root="$1"
  local skill_dir

  for skill_dir in "$repo_root"/.agents/skills/*; do
    [[ -d "$skill_dir" ]] || continue
    link_managed_path "$skill_dir" "$skills_root/$(basename "$skill_dir")"
  done
}

render_managed_config
link_managed_path "$repo_root/codex-home/AGENTS.md" "$codex_home/AGENTS.md"
install_managed_config "$codex_home/config.toml"
link_managed_path "$repo_root/codex-home/rules" "$codex_home/rules"

for profile in "$repo_root"/codex-home/*.config.toml; do
  [[ -f "$profile" ]] || continue
  link_managed_path "$profile" "$codex_home/$(basename "$profile")"
done

install_skills_into "$agents_home/skills"

if "$install_claude"; then
  if [[ -f "$repo_root/claude-home/CLAUDE.md" ]]; then
    link_managed_path "$repo_root/claude-home/CLAUDE.md" "$claude_home/CLAUDE.md"
  fi
  install_skills_into "$claude_home/skills"
fi

if "$install_grok"; then
  install_skills_into "$grok_home/skills"
fi

if "$install_plugins"; then
  install_recommended_plugins
fi

if "$dry_run"; then
  printf 'dry run complete\n'
else
  printf 'installation complete. Restart coding agents to reload configuration.\n'
  if ! "$install_claude"; then
    printf 'tip: rerun with --claude to install Claude skills\n'
  fi
  if ! "$install_grok"; then
    printf 'tip: rerun with --grok to install Grok skills\n'
  fi
fi
