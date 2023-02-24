#!/usr/bin/env bash

set -ex

if [ "$INPUT_VERSION" != "latest" ] && [ -n "$INPUT_VERSION" ]; then
  TFSEC_VERSION="download/${INPUT_VERSION}"
else
  TFSEC_VERSION="latest/download"
fi

function install_release() {
  repo="$1"
  version="$2"
  binary="$3-linux-amd64"
  checksum="$4"

  if ! curl -sSfL "https://github.com/aquasecurity/tfsec/releases/${TFSEC_VERSION}/${checksum}" -o "${checksum}"; then
    echo "Failed to download https://github.com/aquasecurity/tfsec/releases/${TFSEC_VERSION}/${checksum}"
    exit 1
  fi

  if ! curl -sSfL "https://github.com/aquasecurity/tfsec/releases/${TFSEC_VERSION}/${binary}" -o "${binary}"; then
    echo "Failed to download https://github.com/aquasecurity/tfsec/releases/${TFSEC_VERSION}/${binary}"
    exit 1
  fi

  if ! sha256sum --quiet --ignore-missing -w -c "${checksum}"; then
    echo "Checksum mismatch!"
    printf "Expected: "
    grep "${binary}" "${checksum}"
    printf "Actual:   "
    sha256sum "${binary}"
    exit 1
  fi

  install "${binary}" "/usr/local/bin/${3}"
}

install_release aquasecurity/tfsec "${TFSEC_VERSION}" tfsec tfsec_checksums.txt

if [ -n "${GITHUB_WORKSPACE}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit
fi

if [ -n "${INPUT_ADDITIONAL_ARGS}" ]; then
  TFSEC_ARGS_OPTION="${INPUT_ADDITIONAL_ARGS}"
fi

if [ -n "${INPUT_SOFT_FAIL}" ]; then
  SOFT_FAIL="--soft-fail"
fi

FORMAT=${INPUT_FORMAT:-default}

tfsec --format="${FORMAT}" ${SOFT_FAIL} ${TFSEC_ARGS_OPTION} "${INPUT_WORKING_DIRECTORY}"
