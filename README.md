# 🛡️ Hydra Pre-Update Verifier (`safe-update`)

 Personal use but anyone can use it, this script dynamically audits your installed software profiles, auto-detects your environment's active release track framework, cross-references it with upstream **Hydra build servers**, and aborts your upgrade sequence if any critical package update is broken or unbuilt upstream.

---

## 🚀 Instant Usage

No configuration editing or `home.nix` rewriting required. Run this portable command directly in your terminal to safely check and upgrade your system:

```fish
nix run github:sircam-html/safe-update-nix
```

*This command dynamically streams the verification shield, adapts its engine to target your local channel track, checks your unique packages, and triggers your upgrade sequence if all indicators report green.*
    
---

## 🏆 Core Advantages
* **Immune System:** Never download a broken rolling package update again.
* **Zero Maintenance:** Adapts automatically whenever you add, change, or remove software profiles.
* **Permissive License:** Open-source architecture distributed under the **MIT License**.
    
---

## 📋 Recommended Deep Cleaning Routine

Run these raw sequential commands 24–48 hours after your monthly upgrade to completely delete old system generations and optimize your storage space:

```bash
# 1. Collect user-level garbage
nix-collect-garbage -d

# 2. Collect system-level garbage 
sudo nix-collect-garbage -d

# 3. Purge old system boot entries and refresh bootloader profile
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old
sudo nixos-rebuild boot

# 4. Optimize the Nix store by hardlinking duplicate files
nix-store --optimise
```

---
