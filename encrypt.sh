CURR_DIR=$(dirname "$0")
FILE_PATH="${1:?Please provide a file path relative to the repo root}"
sops -e --in-place "$CURR_DIR/$FILE_PATH"


# Grab the release secret
kubectl -n auth get secret sh.helm.release.v1.authentik.v1 \
  -o jsonpath='{.data.release}' | base64 -d > release.protobuf

# Use helm to decode
helm get values authentik -n auth
helm get manifest authentik -n auth
asm