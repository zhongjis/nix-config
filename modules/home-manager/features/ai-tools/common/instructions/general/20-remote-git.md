# Remote Git

## Rules

1. Do not use raw HTTP requests or web-fetch tools for remote git operations.
2. Use git-native commands for repository transport and sync:
   - `git clone`
   - `git fetch`
   - `git pull`
   - `git push`
3. If host-specific actions are needed, use the host's CLI or approved tooling instead of hand-rolled HTTP calls.
4. Apply this rule to GitHub, GitLab, Gitea, Bitbucket, Forgejo, and similar remote git hosts unless a task explicitly requires an HTTP API.
