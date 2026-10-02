#!/usr/bin/env bash
# Resolves Starship's current main + submodule pins into the manifest.
# Needed because upstream's libultraship pin can't be fetched with `git submodule`.
set -euo pipefail
MANIFEST="${1:-io.github.HarbourMasters.Starship.yml}"
WORK="$(mktemp -d)"
export GIT_LFS_SKIP_SMUDGE=1

git clone --quiet --no-recurse-submodules --filter=blob:none \
  https://github.com/HarbourMasters/Starship.git "$WORK/src"
STARSHIP=$(git -C "$WORK/src" rev-parse HEAD)
LUS=$(git -C "$WORK/src" rev-parse HEAD:libultraship)
TORCH=$(git -C "$WORK/src" rev-parse HEAD:tools/Torch)
echo "Starship $STARSHIP | libultraship $LUS | Torch $TORCH"

# GitHub serves archives for commits in a repo's fork network, even when
# `git fetch` refuses them. Try the likely repos in turn.
LUS_URL=""
for repo in Kenix3 HarbourMasters KiritoDv; do
  url="https://github.com/$repo/libultraship/archive/$LUS.tar.gz"
  if curl -fsSL "$url" -o "$WORK/lus.tar.gz"; then LUS_URL="$url"; break; fi
done
[ -n "$LUS_URL" ] || { echo "Could not download libultraship $LUS from any known repo" >&2; exit 1; }
LUS_SHA=$(sha256sum "$WORK/lus.tar.gz" | cut -d' ' -f1)

# libultraship expects this beside the executable; upstream doesn't ship it.
GCDB_URL="https://raw.githubusercontent.com/mdqinc/SDL_GameControllerDB/5a12daa568d19344f9b6e9286ef5929833b25c7c/gamecontrollerdb.txt"
curl -fsSL "$GCDB_URL" -o "$WORK/gcdb.txt"
GCDB_SHA=$(sha256sum "$WORK/gcdb.txt" | cut -d' ' -f1)

sed -i \
  -e "s|@STARSHIP_COMMIT@|$STARSHIP|" \
  -e "s|@TORCH_COMMIT@|$TORCH|" \
  -e "s|@LUS_URL@|$LUS_URL|" \
  -e "s|@LUS_SHA@|$LUS_SHA|" \
  -e "s|@GCDB_URL@|$GCDB_URL|" \
  -e "s|@GCDB_SHA@|$GCDB_SHA|" \
  "$MANIFEST"
echo "Manifest updated: $MANIFEST"
