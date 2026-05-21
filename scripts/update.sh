#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

REPO="can1357/oh-my-pi"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

echo "Fetching latest release from ${REPO}..."
RELEASE_JSON=$(curl -fsSL "${API_URL}")

TAG=$(echo "${RELEASE_JSON}" | jq -r '.tag_name')
VERSION="${TAG#v}"

if [[ -f versions.json ]]; then
  CURRENT_VERSION=$(jq -r '.ompVersions.version' versions.json)
else
  CURRENT_VERSION=""
fi

if [[ "$VERSION" == "$CURRENT_VERSION" ]]; then
  echo "Already up to date: ${VERSION}"
  exit 0
fi

echo "New version found: ${VERSION}"

declare -A ASSET_MAP=(
  ["omp-linux-x64"]="linux.x86_64"
  ["omp-linux-arm64"]="linux.aarch64"
  ["omp-darwin-x64"]="darwin.x86_64"
  ["omp-darwin-arm64"]="darwin.aarch64"
)

declare -A URLS
declare -A HASHES

for asset_name in "${!ASSET_MAP[@]}"; do
  url=$(echo "${RELEASE_JSON}" | jq -r ".assets[] | select(.name == \"${asset_name}\") | .browser_download_url")
  if [[ -z "$url" ]]; then
    echo "WARNING: Asset ${asset_name} not found in release"
    continue
  fi

  echo "Computing hash for ${asset_name}..."
  NIX_HASH=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null)
  SRI_HASH=$(nix hash convert --hash-algo sha256 --to sri "$NIX_HASH")

  key="${ASSET_MAP[$asset_name]}"
  URLS[$key]="$url"
  HASHES[$key]="$SRI_HASH"
  echo "  ${asset_name}: ${SRI_HASH}"
done

jq -n \
  --arg version "$VERSION" \
  --arg linux_x64_url "${URLS[linux.x86_64]}" \
  --arg linux_x64_hash "${HASHES[linux.x86_64]}" \
  --arg linux_arm64_url "${URLS[linux.aarch64]}" \
  --arg linux_arm64_hash "${HASHES[linux.aarch64]}" \
  --arg darwin_x64_url "${URLS[darwin.x86_64]}" \
  --arg darwin_x64_hash "${HASHES[darwin.x64]}" \
  --arg darwin_arm64_url "${URLS[darwin.aarch64]}" \
  --arg darwin_arm64_hash "${HASHES[darwin.aarch64]}" \
  '{
    ompVersions: {
      version: $version,
      urls: {
        linux: {
          x86_64: { url: $linux_x64_url, hash: $linux_x64_hash },
          aarch64: { url: $linux_arm64_url, hash: $linux_arm64_hash }
        },
        darwin: {
          x86_64: { url: $darwin_x64_url, hash: $darwin_x64_hash },
          aarch64: { url: $darwin_arm64_url, hash: $darwin_arm64_hash }
        }
      }
    }
  }' > versions.json

echo "Updated versions.json to ${VERSION}"