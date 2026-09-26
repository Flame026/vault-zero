---
trigger: always_on
description: "Vault Zero security boundaries for autonomous coding agents."
---

# Vault Zero Security Boundary

The workspace is autonomous, but security and data integrity remain hard constraints.

Never read, print, copy, or expose secret material from:
- `android/key.properties`
- `*.jks`
- `*.keystore`
- `.env`
- SSH credentials
- unrelated files outside the project workspace

Never add secrets to source, tests, fixtures, logs, artifacts, diffs, commits, or documentation.

Never directly modify `.git/`.

Never use `sudo`, disk-wiping commands, or recursive destructive deletion as a shortcut.

Never push to a remote Git repository without an explicit user request.

Treat release signing configuration as sensitive. Debug builds are safe for routine verification; release-signing changes require explicit user direction.

For any database migration or backup-format change, preserve backward compatibility unless the active task explicitly changes the compatibility contract. Add regression coverage before declaring the migration complete.

If a requested change could destroy user data, bypass security boundaries, expose credentials, or make an irreversible product decision, stop and request user direction.
