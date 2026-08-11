#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_test_root="$(mktemp -d "${TMPDIR:-/tmp}/agent-rules-install-test.XXXXXX")"
test_codex_home="$task_test_root/codex home"
test_agents_home="$task_test_root/agents home"
test_claude_home="$task_test_root/claude home"
test_grok_home="$task_test_root/grok home"
test_cursor_home="$task_test_root/cursor home"
test_user_home="$task_test_root/user home"
test_coding_repo="$test_user_home/coding/nested/project"
test_github_repo="$test_user_home/github/nested/project"

cleanup() {
  if [[ -d "$task_test_root" && "$(basename "$task_test_root")" == agent-rules-install-test.* ]]; then
    rm -rf -- "$task_test_root"
  fi
}
trap cleanup EXIT

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

assert_link() {
  local target="$1"
  local source="$2"

  [[ -L "$target" ]] || fail "expected symbolic link: $target"
  [[ "$(readlink "$target")" == "$source" ]] ||
    fail "unexpected link target: $target -> $(readlink "$target") (expected $source)"
}

mkdir -p "$test_codex_home"
mkdir -p "$test_coding_repo/.git"
mkdir -p "$test_github_repo/.git"
printf 'original global instructions\n' >"$test_codex_home/AGENTS.md"

HOME="$test_user_home" \
  CODEX_HOME="$test_codex_home" \
  AGENTS_HOME="$test_agents_home" \
  CLAUDE_HOME="$test_claude_home" \
  GROK_HOME="$test_grok_home" \
  CURSOR_HOME="$test_cursor_home" \
  "$repo_root/scripts/install.sh" --claude --grok --cursor >/dev/null

assert_link "$test_codex_home/AGENTS.md" "$repo_root/codex-home/AGENTS.md"
[[ -f "$test_codex_home/config.toml" && ! -L "$test_codex_home/config.toml" ]] ||
  fail "expected generated config file: $test_codex_home/config.toml"
grep -Fqx "[projects.\"$test_user_home/coding\"]" "$test_codex_home/config.toml" ||
  fail "generated config does not trust the user coding root"
grep -Fqx "[projects.\"$test_coding_repo\"]" "$test_codex_home/config.toml" ||
  fail "generated config does not trust a nested coding repository"
grep -Fqx "[projects.\"$test_user_home/github\"]" "$test_codex_home/config.toml" ||
  fail "generated config does not trust the user GitHub root"
grep -Fqx "[projects.\"$test_github_repo\"]" "$test_codex_home/config.toml" ||
  fail "generated config does not trust a nested GitHub repository"
assert_link "$test_codex_home/rules" "$repo_root/codex-home/rules"
assert_link "$test_codex_home/ollama.config.toml" "$repo_root/codex-home/ollama.config.toml"
assert_link "$test_codex_home/llamacpp.config.toml" "$repo_root/codex-home/llamacpp.config.toml"
assert_link "$test_claude_home/CLAUDE.md" "$repo_root/claude-home/CLAUDE.md"

for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  assert_link "$test_agents_home/skills/$name" "$skill_dir"
  assert_link "$test_claude_home/skills/$name" "$skill_dir"
  assert_link "$test_grok_home/skills/$name" "$skill_dir"
  assert_link "$test_cursor_home/skills/$name" "$skill_dir"
done

shopt -s nullglob
instruction_backups=("$test_codex_home"/backups/agent-rules-*/AGENTS.md)
shopt -u nullglob
[[ ${#instruction_backups[@]} -eq 1 ]] ||
  fail "expected one AGENTS.md backup, found ${#instruction_backups[@]}"
[[ "$(sed -n '1p' "${instruction_backups[0]}")" == "original global instructions" ]] ||
  fail "AGENTS.md backup content changed"

# Idempotent reinstall should not create another backup of already-managed links.
HOME="$test_user_home" \
  CODEX_HOME="$test_codex_home" \
  AGENTS_HOME="$test_agents_home" \
  CLAUDE_HOME="$test_claude_home" \
  GROK_HOME="$test_grok_home" \
  CURSOR_HOME="$test_cursor_home" \
  "$repo_root/scripts/install.sh" --claude --grok --cursor >/dev/null

shopt -s nullglob
instruction_backups=("$test_codex_home"/backups/agent-rules-*/AGENTS.md)
shopt -u nullglob
[[ ${#instruction_backups[@]} -eq 1 ]] ||
  fail "idempotent install created another AGENTS.md backup"

# Cyclic symlink detection
cycle_fixture_dir="$task_test_root/cycle fixtures"
mkdir -p "$cycle_fixture_dir"
ln -s "cycle-b" "$cycle_fixture_dir/cycle-a"
ln -s "cycle-a" "$cycle_fixture_dir/cycle-b"
rm -- "$test_codex_home/ollama.config.toml"
ln -s "../cycle fixtures/cycle-a" "$test_codex_home/ollama.config.toml"
cycle_error_log="$task_test_root/cycle-error.log"

HOME="$test_user_home" \
  CODEX_HOME="$test_codex_home" \
  AGENTS_HOME="$test_agents_home" \
  CLAUDE_HOME="$test_claude_home" \
  GROK_HOME="$test_grok_home" \
  "$repo_root/scripts/install.sh" >/dev/null 2>"$cycle_error_log"
grep -q '^error: too many symbolic-link hops:' "$cycle_error_log" ||
  fail "cyclic link did not report a bounded-resolution error"
assert_link "$test_codex_home/ollama.config.toml" "$repo_root/codex-home/ollama.config.toml"

# Bootstrap project docs
bootstrap_target="$task_test_root/bootstrap target"
"$repo_root/scripts/bootstrap-project.sh" "$bootstrap_target" >/dev/null
for doc in AGENTS.md SPEC.md ROADMAP.md TASKS.md; do
  [[ -f "$bootstrap_target/$doc" ]] || fail "bootstrap missing $doc"
done
# Second run without --force should keep existing files
printf 'custom\n' >"$bootstrap_target/AGENTS.md"
"$repo_root/scripts/bootstrap-project.sh" "$bootstrap_target" >/dev/null
[[ "$(cat "$bootstrap_target/AGENTS.md")" == "custom" ]] ||
  fail "bootstrap overwrote AGENTS.md without --force"

printf 'installer integration tests passed\n'
