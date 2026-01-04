#!/bin/bash
set -e

CLUSTER_NAME="flux-e2e"
export KUBECONFIG="$(pwd)/.kubeconfig-kind"

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Found existing KinD cluster ${CLUSTER_NAME}"
  kind delete cluster --name $CLUSTER_NAME
fi

# Create a clean KinD cluster
kind create cluster --name $CLUSTER_NAME --kubeconfig "$KUBECONFIG"

echo "Current context: $(kubectl config current-context)"

# Install Flux (this installs the CRDs and controllers)
echo "Installing Flux..."
flux install

# Use flux-local to build the entire cluster state and apply it
# echo "Building and applying flux-system manifests via flux-local..."
# flux-local build ks -A --path ./clusters/staging | kubectl apply --server-side -f -
# flux-local build flux-system --path ./clusters/staging | kubectl apply -f -

# # 4. Wait for podinfo to be ready
# echo "Waiting for podinfo deployment..."
# kubectl wait --for=condition=available --timeout=120s deployment/podinfo -n default

# # 5. Ping podinfo via port-forward
# echo "Testing podinfo..."
# kubectl port-forward svc/podinfo 9898:9898 -n default &
# PF_PID=$!
# sleep 2

# curl -s http://localhost:9898/version
# echo ""

# # Cleanup port-forward
# kill $PF_PID 2>/dev/null || true

MANIFESTS_FILE="./tmp/manifests.yaml"
mkdir -p ./tmp

echo "Building manifests and placing into $MANIFESTS_FILE..."
flux-local build ks --path ./clusters/staging --no-skip-crds -A > $MANIFESTS_FILE

echo "Applying CRDs..."
yq 'select(.kind == "CustomResourceDefinition")' $MANIFESTS_FILE > ./tmp/crds.yaml
kubectl apply -f ./tmp/crds.yaml
# Wait for CRDs to be established
echo "Waiting for CRDs to be ready..."
kubectl wait --for=condition=Established crd --all --timeout=60s
echo "Sleeping for 30 seconds to ensure CRDs are fully established..."
sleep 30

# Apply everything except CRs that depend on controllers
echo "Applying all manifests (first pass)..."
kubectl apply -f $MANIFESTS_FILE 2>&1 | grep -v "no matches for kind" || true

# Wait for cert-manager to be ready
echo "Waiting for cert-manager..."
kubectl wait --for=condition=available deployment/cert-manager -n cert-manager --timeout=120s 2>/dev/null || true
kubectl wait --for=condition=available deployment/cert-manager-webhook -n cert-manager --timeout=120s 2>/dev/null || true

# Wait for other controllers (fixed time wait)
echo "Waiting for other controllers to start..."
sleep 30


# Now apply everything again to catch any resources that depend on controllers being present
echo "Applying all manifests (second pass)..."
kubectl apply -f $MANIFESTS_FILE

# Debug: See what was created
echo "Checking Flux kustomizations..."
kubectl get kustomizations -A

echo "Waiting for Flux to reconcile..."
sleep 30

echo "All deployments:"
kubectl get deployments -A

echo "All pods:"
kubectl get pods -A

echo "Done! Please note, the KinD cluster will persist until you delete it with:"
echo "kind delete cluster --name \"$CLUSTER_NAME\""