# AGENTS.md

## Architecture Conventions
- **State Management:** Riverpod (using `riverpod_generator`)
- **Routing:** go_router
- **Dependency Injection:** get_it + injectable
- **Folder Structure:** Feature-first (`lib/features/<feature>/{presentation,domain,data}`)
- **Network/AI Calls:** All AI or network calls must go through a service class in each feature's `data` layer. They should never be called directly from the UI.
- **Data Source:** Drift (SQLite) is the local-first source of truth.

## Repo Rules for AI Agents
1. Commit after every meaningful unit of work (not once per phase) using conventional commit messages (e.g., `feat(scope): ...`, `fix(scope): ...`, `chore(scope): ...`).
2. Never create or commit any `.md` file other than `README.md` at the repo root – no `docs/`, no `SPEC.md`, no `NOTES.md`, no self-generated planning files. If you need to keep notes for yourself mid-task, keep them out of the repo entirely.
