#!/usr/bin/env bash

set -eou pipefail

if [ "${INPUT_DEBUG}" = "true" ]; then
  set -x
fi

_sha256sum() {
  if command -v shasum >/dev/null; then
    # MacOS
    shasum -a 256 "$@"
  else
    sha256sum "$@"
  fi
}

CACHE_LOCATION="${RUNNER_TOOL_CACHE}/tfsec/${INPUT_VERSION}"
echo "${CACHE_LOCATION}" >> "${GITHUB_PATH}"

if [ "$INPUT_CACHE" = "true" ] && [ -x "${CACHE_LOCATION}/tfsec" ]; then
  if VERSION=$("${CACHE_LOCATION}/tfsec" --version); then
    printf "Found tfsec version %s in cache." "${VERSION}"
    exit 0
  fi
fi

if [ "$INPUT_VERSION" != "latest" ] && [ -n "$INPUT_VERSION" ]; then
  TFSEC_VERSION="download/${INPUT_VERSION}"
else
  TFSEC_VERSION="latest/download"
fi

arch="$(uname -m)"
if [ "$arch" = "x86_64" ]; then
  arch="amd64"
fi

os="$(uname | tr '[:upper:]' '[:lower:]')"
binary_suffix=""
if [ "$os" != "linux" ] && [ "$os" != "darwin" ]; then
  os="windows"
  binary_suffix=".exe"
fi

binary="tfsec-${os}-${arch}${binary_suffix}"
checksum="tfsec_checksums.txt"

if ! curl -sSfL "https://github.com/aquasecurity/tfsec/releases/${TFSEC_VERSION}/${checksum}" -o "${checksum}"; then
  echo "Failed to download https://github.com/aquasecurity/tfsec/releases/${TFSEC_VERSION}/${checksum}"
  exit 1
fi

if ! curl -sSfL "https://github.com/aquasecurity/tfsec/releases/${TFSEC_VERSION}/${binary}" -o "${binary}"; then
  echo "Failed to download https://github.com/aquasecurity/tfsec/releases/${TFSEC_VERSION}/${binary}"
  exit 1
fi

if ! _sha256sum --quiet --ignore-missing -w -c "${checksum}" >/dev/null; then
  echo "Checksum mismatch!"
  printf "Expected: "
  grep "${binary}" "${checksum}"
  printf "Actual:   "
  _sha256sum "${binary}"
  exit 1
fi

mkdir -p "${CACHE_LOCATION}"
cp "${binary}" "${CACHE_LOCATION}/tfsec${binary_suffix}"
chmod +x "${CACHE_LOCATION}/tfsec${binary_suffix}"

printf "Installed tfsec version: "
"${CACHE_LOCATION}/tfsec" --version
