{
  description = "A high-performance Hydra pre-update verification shield";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        safeUpdateScript = pkgs.writeShellScriptBin "safe-update" ''
          #!/usr/bin/env bash
          set -o pipefail

          CHECK_ONLY=false
          for arg in "$@"; do
            [ "$arg" = "--check" ] && CHECK_ONLY=true
          done

          if [ -f /run/current-system/nixos-version ]; then
            CHANNEL=$(cut -d. -f1,2 /run/current-system/nixos-version)
          elif nix-channel --list | grep -q "nixos-"; then
            CHANNEL=$(nix-channel --list | grep "nixos-" | head -n1 | awk -F/ '{print $NF}' | sed 's/nixos-//')
          else
            CHANNEL="unstable"
          fi

          [[ "$CHANNEL" == *"pre"* || "$CHANNEL" == *"unstable"* ]] && CHANNEL="unstable"

          FAILED=0

          echo "🔍 Detecting unfree package allowance..."
          ALLOW_UNFREE=$(${pkgs.nix}/bin/nix-instantiate --eval -E '(import <nixpkgs> {}).config.allowUnfree or false' 2>/dev/null || echo "false")
          ALLOW_UNFREE=$(echo "$ALLOW_UNFREE" | tr -d '"')

          declare -A UNFREE_PACKAGES
          if [ "$ALLOW_UNFREE" = "true" ]; then
            echo "   Global allowUnfree detected — no package filtering needed"
          else
            for pkg in ferdium discord google-chrome vivaldi brave steam zen-browser unrar coolercontrol; do
              UNFREE_PACKAGES["$pkg"]=1
            done
          fi

          echo "🔍 Fetching currently installed packages (System + Home Manager)..."
          user_pkgs=$(home-manager packages 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $1}')
          system_pkgs=$(${pkgs.nix}/bin/nix-env -p /run/current-system/sw -q 2>/dev/null)

          packages=()
          while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            [[ "$pkg" =~ ^(hm-session-vars.*|home-configuration-reference.*|home-manager-path|safe-update)$ ]] && continue
            packages+=("$pkg")
          done < <(printf "%s\n%s" "$user_pkgs" "$system_pkgs" | ${pkgs.gnused}/bin/sed -E 's/-[0-9](\.[0-9])*.*//' | sort -u)

          if [ ''${#packages[@]} -eq 0 ]; then
            echo "❌ Error: No packages detected in your profile. Aborting."
            exit 1
          fi

          echo "🔍 Checking ''${#packages[@]} unique packages on nixos-$CHANNEL..."
          echo "─────────────────────────────────────────────────"

          for pkg in "''${packages[@]}"; do
            if [ "$ALLOW_UNFREE" = "true" ]; then
              :
            elif [[ -n "''${UNFREE_PACKAGES[$pkg]}" ]]; then
              echo "📦 $pkg → Unfree package — assumed OK"
              continue
            fi
            if [[ "$pkg" == nerd-fonts-* ]]; then
              echo "📦 $pkg → Font package — skipped verification"
              continue
            fi

            hydra_name="$pkg"
            case "$pkg" in
              kcalc|yakuake|filelight|kolourpaint|ktorrent|sweeper|isoimagewriter)
                hydra_name="kdePackages.$pkg"
                ;;
            esac

            if ! result=$(${pkgs.hydra-check}/bin/hydra-check "$hydra_name" --channel "$CHANNEL" 2>&1); then
              echo "⚠️  $hydra_name → Not found or query error (Skipped)"
              continue
            fi

            if echo "$result" | ${pkgs.gnugrep}/bin/grep -q "✔"; then
              echo "✅ $pkg → OK"
            elif echo "$result" | ${pkgs.gnugrep}/bin/grep -q "✖"; then
              echo "❌ $pkg → FAILED"
              FAILED=1
            else
              echo "⚠️  $pkg → Unknown or unbuilt status"
            fi
          done

          echo "─────────────────────────────────────────────────"

          if [ "$FAILED" -eq 1 ]; then
            echo "❌ Some packages failed on Hydra. Update aborted!"
            exit 1
          elif [ "$CHECK_ONLY" = true ]; then
            echo "✅ All packages green. --check mode: no update performed."
            exit 0
          else
            echo "✅ All packages green. Safe to update!"
            echo "🚀 Running update..."

            if [ -f /etc/nixos/flake.nix ] && nix flake metadata /etc/nixos/flake.nix &>/dev/null; then
              echo "❄️ Pure Flake environment detected at /etc/nixos/flake.nix"
              sudo nix flake update --flake /etc/nixos && \
              sudo nixos-rebuild switch --flake /etc/nixos && \
              home-manager switch
            elif [ -f ~/.config/nix/flake.nix ] && nix flake metadata ~/.config/nix/flake.nix &>/dev/null; then
              echo "❄️ Pure Flake environment detected at ~/.config/nix/"
              sudo nix flake update --flake ~/.config/nix && \
              sudo nixos-rebuild switch --flake ~/.config/nix/ && \
              home-manager switch
            elif [ -f ~/nixos/flake.nix ] && nix flake metadata ~/nixos/flake.nix &>/dev/null; then
              echo "❄️ Pure Flake environment detected at ~/nixos/"
              sudo nix flake update --flake ~/nixos && \
              sudo nixos-rebuild switch --flake ~/nixos && \
              home-manager switch
            elif [ -f ~/.dotfiles/flake.nix ] && nix flake metadata ~/.dotfiles/flake.nix &>/dev/null; then
              echo "❄️ Pure Flake environment detected at ~/.dotfiles/"
              sudo nix flake update --flake ~/.dotfiles && \
              sudo nixos-rebuild switch --flake ~/.dotfiles && \
              home-manager switch
            else
              echo "📦 Traditional NixOS channel system detected."
              sudo nix-channel --update && \
              sudo nixos-rebuild switch --upgrade && \
              home-manager switch
            fi
          fi
        '';
      in
      {
        packages.default = safeUpdateScript;
        apps.default = {
          type = "app";
          program = "${safeUpdateScript}/bin/safe-update";
        };
      }
    );
}
