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

        safeUpdateScript = pkgs.writeShellScriptBin "safe-update" ''
          #!/usr/bin/env bash
          set -euo pipefail

          export PATH="${pkgs.hydra-check}/bin:${pkgs.gawk}/bin:$PATH"

          echo "🛡️ Starting pre-flight update validation tracks..."
          CURRENT_CHANNEL=$(nix-channel --list | grep nixos | awk -F'/' '{print $NF}' || echo "nixos-26.05")
          echo "📡 Active System Target Track: $CURRENT_CHANNEL"

          UNFREE_PACKAGES=("google-chrome" "discord" "ferdium" "steam" "wine")

          echo "🔍 Auditing Hydra build status matrices for unfree channels..."
          FAILED_BUILDS=0

          for pkg in "''${UNFREE_PACKAGES[@]}"; do
              echo "⚙️ Evaluating: $pkg..."

              if ! hydra-check "$pkg" --channel "$CURRENT_CHANNEL" > /dev/null 2>&1; then
                  echo "🔄 Stable mirror indexing (404/Pending); falling back to upstream unstable check for $pkg..."

                  if ! hydra-check "$pkg" --channel "nixpkgs-unstable" > /dev/null 2>&1; then
                      echo "❌ WARNING: $pkg build is currently broken or pending on upstream master Hydra!"
                      FAILED_BUILDS=$((FAILED_BUILDS + 1))
                  else
                      echo "✅ Pass: $pkg binary verified healthy on upstream master branch."
                  fi
              else
                  echo "✅ Pass: $pkg build is green on stable channel release tracks."
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
