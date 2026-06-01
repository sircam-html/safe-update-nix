# 🛡️ Hydra Pre-Update Verifier (`safe-update`)

An automated pre-flight update shield for NixOS and Home Manager. It instantly scans your installed software profiles against upstream **Hydra build servers** in milliseconds and aborts your upgrade sequence if any package is currently broken or unbuilt upstream.

---

## 🚀 Instant Usage

No configuration editing required. Run this portable command directly in your terminal to safely update your system:

```fish
nix run github:sircam-html/safe-update-nix
```

*This command dynamically pulls the verification shield, checks your unique System + Home Manager packages, and safely fires your upgrade sequence if all indicators report green.*

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

## 🏆 Core Advantages
* **Immune System:** Never download a broken rolling package update again.
* **Zero Maintenance:** Automatically reads your allowed unfree packages in real-time.
* **Permissive License:** Open-source architecture distributed under the **MIT License**.
