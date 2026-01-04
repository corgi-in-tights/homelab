#!/bin/bash
set -e

CLUSTER_NAME="flux-e2e"
export KUBECONFIG="$(pwd)/.kubeconfig-kind"

"$@"
