# dsh-win-build

Build a **portable (no-install, unsigned) DeepSeek Harness desktop app for Windows 10/11 x64**
in the cloud with GitHub Actions, so no local Windows machine is needed.

This repository contains only the workflow. It checks out
[`deepseek-ai/deepseek-harness`](https://github.com/deepseek-ai/deepseek-harness)
at a release tag and runs the official packaging command:

```
pnpm --filter "@deepseek-ai/dsh-desktop" run package:win:x64:dir --unsigned
```

## Result

Each run uploads the artifact **`dsh-desktop-win-x64-portable`** (a zip). Inside it is the
portable application directory produced by electron-builder (normally `win-unpacked/`):

```
win-unpacked/
  DeepSeek Harness.exe
  resources/app.asar            <- dsh production dependency tree
  resources/app.asar.unpacked/  <- native modules
  resources/runtime/            <- bundled Python / Node / pnpm
```

Copy that **whole folder** to the target machine and run `DeepSeek Harness.exe`.
No Node.js, no pnpm, no Python, no internet required at runtime.
Because the build is unsigned, Windows SmartScreen shows a warning on first launch
(click *More info* -> *Run anyway*).

## Triggering

* push to `main` — runs automatically with the default tag;
* **Actions -> dsh-desktop-win-portable -> Run workflow** — pick any upstream tag.

Build time is roughly 30-60 minutes. The artifact is several GB because it bundles
Electron, a CPython runtime and the full dsh dependency tree.

## Changing the version

Run the workflow manually and enter another tag, e.g. `dsh-v0.1.7-alpha.1`.
Note that the desktop shell and the bundled `@deepseek-ai/dsh` must ship the same
version, so upgrading always means rebuilding from a new tag.
