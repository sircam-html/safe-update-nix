# 🛡️ Hydra Pre-Update Verifier (`safe-update`)

A high-performance, fully universal update shield for NixOS and Home Manager. This script dynamically audits your installed software profiles, auto-detects your environment's active release track, cross-references it with upstream **Hydra build servers**, and aborts your upgrade sequence if any critical package update is broken or unbuilt upstream.

## 🚀 Key Features & Architectural Enhancements

*   **🌍 Universal Channel Engine:** Auto-detects your runtime host machine version via `/run/current-system/nixos-version` (works out of the box on stable channels like `25.11`, `26.05`, or rolling `unstable` paths).
*   **⚡ Instant Profile Auditing (\(O(1)\) Complexity):** Replaced slow, global network tree evaluations (`nix-env -qaP`) with localized link-parsing directly from `/run/current-system/sw`. Profile fetching takes milliseconds instead of minutes.
*   **🔮 Dynamic Unfree Detection:** Completely autonomous. The script leverages `nix-instantiate` to evaluate your configuration's `allowUnfreePredicate` in real-time, adapting instantly when you add or remove unfree software.
*   **🫧 Zero False Positives:** Built-in RegEx filters purge internal environment shell noise (such as Fish shell's `hm-session-vars.fish`, `safe-update`, and manual page structures) to ensure only valid user-facing applications are queried.

---

## 🛠️ How It Works Under the Hood

```text
STEP 1: [Local Audit]
        └──> Dynamically extracts all system packages & Home Manager profiles.

STEP 2: [Dynamic Sync]
        └──> Auto-detects host release version and syncs active allowed unfree apps.

STEP 3: [Hydra Query]
        └──> Checks status for ALL your unique packages on your runtime channel.
             │
             ├──> [❌ FAILED] ──> Abort Update! (Protects system state)
             └──> [✅ GREEN]  ──> Running update... (Executes Upgrade Sequence)
```

---

## 🚀 Instant Usage

No configuration editing or `home.nix` rewriting required. Run this portable command directly in your terminal to safely check and upgrade your system:

```fish
nix run github:sircam-html/safe-update-nix
```

*This command dynamically streams the verification shield, adapts its engine to target your local channel track, checks your unique packages, and triggers your upgrade sequence if all indicators report green.*

### 💡 Advanced: Force Local Cache Override
To bypass downloading an independent tracking copy of Nixpkgs and force the script to use your host machine's already-cached system inputs (saving major network bandwidth), append the override flag:
```fish
nix run github:sircam-html/safe-update-nix --override-input nixpkgs nixpkgs
```

---

## ⚡ One-Word Global Installation (Any Shell)

If you don't want to type long GitHub strings or manage custom dotfile aliases, you can instantly turn `safe-update` into a permanent, native system command. 

### Step 1: Create the launcher script
Open your terminal and run this single line to drop the portable script directly into your safe user binary space:

```bash
mkdir -p ~/.local/bin && echo 'exec nix run github:sircam-html/safe-update-nix --refresh "\$@"' > ~/.local/bin/safe-update && chmod +x ~/.local/bin/safe-update
```

### Step 2: Ensure the path is visible to your Shell
If your terminal reports `command not found`, your shell simply needs to register your local bin path. Run the command that matches your active shell, then restart your terminal (`exec fish` or `exec zsh`):

* **If you use Fish shell:**
  ```fish
  fish_add_path ~/.local/bin/
  ```
* **If you use Zsh shell:**
  ```zsh
  echo 'export PATH="\(HOME/.local/bin:\)PATH"' >> ~/.zshrc
  ```
* **If you use Bash shell:**
  ```bash
  echo 'export PATH="\(HOME/.local/bin:\)PATH"' >> ~/.bashrc
  ```

Once executed, you can fire up your entire live defensive shield from anywhere on your system by typing a single word:

```fish
safe-update
```

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
* **Zero Maintenance:** Adapts automatically whenever you add, change, or remove software profiles.
* **Permissive License:** Open-source architecture distributed under the **MIT License**.
