#!/bin/bash
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

set -euo pipefail

IS_KOKORO="false"
if [[ -n "${KOKORO_ARTIFACTS_DIR:-}" ]]; then
  IS_KOKORO="true"
fi
readonly IS_KOKORO

if [[ "${IS_KOKORO}" == "true" ]]; then
  cd "$(echo "${KOKORO_ARTIFACTS_DIR}"/git*/tink)"
fi

./kokoro/testutils/copy_credentials.sh "python/testdata" "gcp"
# Install protobuf pip packages.
pip3 install protobuf==3.20.3 --user

# Run manual tests which rely on key material injected into the Kokoro
# environement.
MANUAL_TARGETS=()
if [[ "${IS_KOKORO}" == "true" ]]; then
  MANUAL_TARGETS+=( "//tink/integration/gcpkms:_gcp_kms_aead_test" )
fi
readonly MANUAL_TARGETS

./kokoro/testutils/run_bazel_tests.sh python "${MANUAL_TARGETS[@]}"
