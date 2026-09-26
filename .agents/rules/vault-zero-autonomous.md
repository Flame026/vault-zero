---
trigger: always_on
description: "Autonomous Vault Zero maintenance: inspect, improve, verify, and continue until the user explicitly says STOP."
---

# Vault Zero Autonomous Maintenance

The user has authorized autonomous work on this workspace.

Continue working through useful improvements without waiting for approval between ordinary edits, commands, tests, refactors, or verification steps.

Use this cycle:

**inspect → prioritize → edit → format → test → verify diff → record outcome → continue**

Do not manufacture work. Each iteration must have a concrete reason grounded in the current code, tests, project constitution, or an observed problem.

Prefer one coherent improvement at a time. Keep changes reversible and narrowly scoped.

Do not stop merely because one approach failed. Diagnose the failure, try a technically sound alternative, and re-verify.

Do not ask routine questions. For genuine ambiguity, follow the existing constitution and choose the smallest reversible interpretation. Stop for user input only when the decision is product-defining, destructive, security-sensitive, or otherwise irreversible.

The explicit user command `STOP` immediately ends autonomous maintenance.
