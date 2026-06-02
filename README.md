# 🛡️ Hydra Pre-Update Verifier (`safe-update`)

A high-performance, fully universal update shield for NixOS and Home Manager. This script dynamically audits your installed software profiles, auto-detects your environment's active release track, cross-references it with upstream **Hydra build servers**, and aborts your upgrade sequence if any critical package update is broken or unbuilt upstream.

## 🚀 Key Features & Architectural Enhancements

*   **🌍 Universal Channel & Flake Engine:** Auto-detects your runtime host machine version via `/run/current-system/nixos-version`.
    *   Works out of the box on stable release tracks (`25.11`, `26.05`) and rolling `unstable` paths.
    *   Dynamically pivots its deployment engine to natively support modern, pure Flake-driven profiles.

*   **⚡ Instant Profile Auditing ($O(1)$ Complexity):** Swaps heavy network overhead for ultra-fast local parsing.
    *   Replaced slow, global network tree evaluations (`nix-env -qaP`) with localized link-parsing from `/run/current-system/sw`.
    *   Reduces profile evaluation and user-package mapping times down to milliseconds instead of minutes.

*   **🔮 Dynamic Unfree Detection:** Completely autonomous environment syncing.
    *   Leverages `nix-instantiate` to evaluate your live `allowUnfreePredicate` block in real-time.
    *   Adapts instantly as you scale your software suite without requiring manually maintained exception lists.

*   **🫧 Zero False Positives:** Immaculate terminal visualization output grids.
    *   Built-in RegEx engine filters out internal declarative environmental noise and shell metadata variables.
    *   Purges rows like `hm-session-vars.fish`, manual pages, and `safe-update` to query only true applications.


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
