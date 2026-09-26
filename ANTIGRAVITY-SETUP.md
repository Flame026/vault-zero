# Vault Zero + Google Antigravity Setup

## 1. Open the correct workspace

Create an Antigravity Project containing exactly this folder:

`/home/flame26/Documents/VScode,antigravity/Vault Zero/Vault Zero Project`

Use **Local Mode**, not New Worktree Mode, when you want agent edits to land directly in that folder. Google documents Local Mode as working directly in the active local folders/checkouts, while New Worktree creates an isolated Git worktree. 

## 2. Cloud model vs. local execution

Your laptop does not need to run the Gemini model locally.

Antigravity's documented architecture runs the agent against cloud-hosted model services while the Antigravity development environment, filesystem, terminal, Flutter SDK, Android SDK, tests, and builds are controlled from the local machine. Remote Control lets you operate that desktop session from a browser, but it does not turn the local workstation into a Google-hosted build VM.

So your machine mainly needs to be capable of:
- running Antigravity;
- running Flutter/Dart tooling;
- compiling/tests when the agent invokes them.

The model reasoning itself is not the workload that needs to fit in your laptop's RAM/VRAM.

## 3. Workspace rules

Copy this setup's `.agents/rules/` directory into the project root.

These rules are workspace-scoped and persistent. Antigravity discovers `.agents/rules/*.md` and applies `always_on` rules automatically.

The existing `Vault Zero Project Guidelines.md` remains the project's source of truth. `AGENTS.md` adds the autonomous operating behavior without replacing that constitution.

## 4. Automatic approvals

There are two separate things to configure:

### Agent/code review
Set **Artifact Review Policy → Always Proceed** so the agent does not stop waiting for plan/code-review approval.

### Terminal execution
For truly unrestricted no-prompt behavior, Antigravity's **Turbo** permission preset uses Always Proceed terminal execution and removes filesystem isolation. This is the closest match to "approve everything", but it is deliberately high-risk because the agent can access the wider filesystem.

For a bounded project workflow, prefer a sandboxed configuration with **Proceed in Sandbox** and pre-authorize only the external operations your Flutter toolchain genuinely needs. This retains the project boundary, but a command that needs to escape the sandbox can still require approval.

There is no documented configuration that simultaneously means "every possible host-level action is automatically approved" and "the agent is cryptographically confined to one folder." Those are different security postures.

## 5. Recommended project boundary

For this project, the safer autonomous setup is:

- Project folder: only the Vault Zero repository.
- Local Mode: enabled.
- Workspace rules: enabled.
- Artifact Review: Always Proceed.
- Terminal: sandbox + proceed automatically inside the sandbox where supported.
- Non-workspace file access: do not grant it unless specifically needed.
- Never grant unrestricted filesystem access merely to eliminate a prompt.

If you decide you value absolute zero prompts more than the filesystem boundary, use the project-level Turbo preset instead and keep the security rules in this bundle active.

## 6. Permission deny rules worth adding

Even in a highly autonomous project, explicitly deny:

```text
command(sudo)
command(rm -rf)
command(regex:rm -rf .*)
command(git push)
write_file(.git/)
read_file(android/key.properties)
write_file(android/key.properties)
read_file(*.jks)
write_file(*.jks)
read_file(*.keystore)
write_file(*.keystore)
read_file(.env)
write_file(.env)
```

Antigravity's permission engine gives Deny higher precedence than Ask or Allow.

Path-specific deny rules are particularly useful for keeping signing material away from an autonomous coding agent.

## 7. Important security issue found in the supplied archive

The supplied archive contains `android/key.properties` with plaintext Android release-signing credentials.

The current Gradle script loads that file if it exists, so the file is functional signing configuration rather than a dead artifact.

The file is not tracked by the repository according to the supplied Git history, which is good. However, it should still not be exposed to a cloud-facing coding agent.

Before giving the workspace broad autonomous access, remove the plaintext signing file from the agent-visible workspace or move signing configuration to a secure local mechanism/environment that the agent cannot read.

Also rotate the exposed signing credential if it has been shared outside your trusted machine or source-control environment.

The existing `.gitignore` already ignores `android/key.properties`, `*.jks`, and `*.keystore`, which is the right direction.

## 8. First Antigravity task

After opening the project and installing these rules, start with:

> Read `Vault Zero Project Guidelines.md` and inspect the entire live repository. Do not change code yet. Build a prioritized maintenance backlog covering correctness, data safety, tests, architecture, performance, UX/accessibility, and documentation. Verify your observations against the actual implementation rather than trusting comments or roadmap text. Then begin implementing the highest-value safe item and continue autonomously until I say STOP. After every meaningful change, format, test, analyze, build, and inspect the diff before proceeding.

This gives the agent an initial audit instead of letting it blindly start rewriting code.
