# Safe PR Creation

Create a branch and PR following Cainmani standards. This command enforces the correct
workflow so changes never go directly to main.

## Pre-flight Checks

1. Verify we are NOT on main:
   ```bash
   BRANCH=$(git branch --show-current)
   ```
   If on main, determine the correct branch prefix from the changes and create a new branch:
   - `feature/` for new functionality
   - `bugfix/` for bug fixes
   - `docs/` for documentation changes
   - `chore/` for maintenance, dependencies, CI
   - `hotfix/` for urgent production fixes

2. Check for uncommitted changes:
   ```bash
   git status
   git diff --stat
   ```

## Commit

3. Stage and commit with a conventional commit message:
   - `feat:` — new feature
   - `fix:` — bug fix
   - `docs:` — documentation only
   - `chore:` — maintenance (deps, CI, config)
   - `ci:` — CI/CD changes
   - `refactor:` — code restructuring (no behaviour change)
   - `test:` — adding or fixing tests

   The commit message must:
   - Start with a type prefix
   - Be concise (under 72 characters for the first line)
   - Explain WHY, not just WHAT

## Push and PR

4. Push the branch:
   ```bash
   git push -u origin <branch-name>
   ```

5. Create the PR with:
   - Title following conventional commit format
   - Body with Summary (bullet points) and Test Plan sections
   - Appropriate label (`bug`, `documentation`, `enhancement`, `chore`)
   - Assigned to the repo maintainer

   ```bash
   gh pr create --title "<type>: <description>" --body "..." --label <label>
   ```

## Safety Checks

- **NEVER** create the PR targeting anything other than `main`
- **NEVER** commit `.env`, credentials, or IP addresses
- **NEVER** use `--no-verify` to skip pre-commit hooks
- If any uncommitted `.env` files are detected in `git status`, warn the user and do NOT stage them
- Verify `.gitignore` includes `.env` and `.claude/settings.local.json` before committing
