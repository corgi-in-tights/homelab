if [ $# -eq 0 ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

path="$1"

sops --encrypt "${path}/secrets.cleartext.yaml" > "${path}/secrets.yaml"