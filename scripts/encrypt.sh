if [ $# -eq 0 ]; then
    echo "Usage: $0 <path> [name]"
    exit 1
fi

path="$1"
name="${2:-secrets}"

sops --encrypt "${path}/${name}.cleartext.yaml" > "${path}/${name}.yaml"