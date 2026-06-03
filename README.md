# 🛡️ Hydra Pre-Update Verifier (`safe-update`)

 For personal use. This script dynamically audits your installed software profiles, auto-detects your environment's active release track framework, cross-references it with upstream **Hydra build servers**, and aborts your upgrade sequence if any critical package update is broken or unbuilt upstream.

---

## 🚀 Instant Usage

No configuration editing or `home.nix` rewriting required. Choose your mode:

**🔍 Audit only** — check packages against Hydra without updating:
```bash
nix run github:sircam-html/safe-update-nix -- --check
```

**🚀 Full auto-upgrade** — check, verify, and update in one shot:
```bash
nix run github:sircam-html/safe-update-nix
```

The script adapts its engine to your local channel track, checks your unique packages against Hydra, and triggers the upgrade sequence only if all indicators report green.
