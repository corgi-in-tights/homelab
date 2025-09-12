CURR_DIR=$(dirname "$0")
FILE_PATH="${1:?Please provide a file path relative to the repo root}"
sops --config "$CURR_DIR/clusters/stable/.sops.yaml" -e --in-place "$CURR_DIR/$FILE_PATH"