# Grok portable notes

Grok loads project `AGENTS.md` automatically when present. Global reusable
skills install into `~/.grok/skills/` when you run:

```bash
./scripts/install.sh --grok
```

For per-project conventions, prefer repository-root `AGENTS.md` created by:

```bash
./scripts/bootstrap-project.sh /path/to/project
```

Do not commit Grok auth tokens, session databases, or cache files into this
repository.
