{
  description = "A hardened pre-flight update validation utility for NixOS system channels";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Bakes a secure wrapper that contains hydra-check right inside its execution path
        safeUpdateScript = pkgs.writeShellScriptBin "safe-update" ''
          #!/usr/bin/env bash
          set -euo pipefail

          # 1. Gracefully guarantee hydra-check is present at runtime (Fixes Point #3)
          export PATH="${pkgs.hydra-check}/bin:${pkgs.gawk}/bin:$PATH"

          echo "🛡️ Starting pre-flight update validation tracks..."

          # 2. Extract active system channels safely using robust awk tracking (Fixes Point #5)
          CURRENT_CHANNEL=$(nix-channel --list | grep nixos | awk -F'/' '{print $NF}' || echo "nixos-unstable")

          # 3. Handle unstable channel drift gracefully (Fixes Point #4)
          if [[ "$CURRENT_CHANNEL" == "nixos" ]]; then
              CHANNEL_VER="unstable"
          else
              CHANNEL_VER=$(echo "$CURRENT_CHANNEL" | sed -E 's/.*nixos-//')
          fi

          echo "📡 Active System Target Track: $CURRENT_CHANNEL ($CHANNEL_VER)"

          # 4. Correctly filter unfree system packages via a safe array list (Fixes Point #1 & #2)
          # Since Nix evaluates functions opaquely, this explicit list matches your core profile
          UNFREE_PACKAGES=("google-chrome" "discord" "ferdium" "steam" "wine")

          echo "🔍 Auditing Hydra build status matrices for unfree channels..."
          FAILED_BUILDS=0

          for pkg in "''${UNFREE_PACKAGES[@]}"; do
              echo "⚙️ Evaluating: $pkg on channel: $CHANNEL_VER..."
              if ! hydra-check "$pkg" --channel "$CHANNEL_VER" > /dev/null 2>&1; then
                  echo "❌ WARNING: $pkg build is currently broken or pending on upstream Hydra!"
                  FAILED_BUILDS=$((FAILED_BUILDS + 1))
              else
                  echo "✅ Pass: $pkg build is green."
              fi
          done

          if [ "$FAILED_BUILDS" -gt 0 ]; then
              echo "🚨 PRE-FLIGHT ALERT: $FAILED_BUILDS critical packages are broken upstream!"
              echo "🛑 Aborting safe update path to prevent system-generation breakages."
              exit 1
          fi

          echo "🟢 ALL PRE-FLIGHT CHECKS PASSED SUCCESSFULLY!"
          echo "🚀 Initiating system upgrade track..."
          sudo nix-channel --update && sudo nixos-rebuild switch --upgrade && home-manager switch
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
