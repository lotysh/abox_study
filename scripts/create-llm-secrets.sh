#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_PATH="${KUBECONFIG:-$ROOT_DIR/bootstrap/abox-config}"

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "OPENAI_API_KEY is required" >&2
  echo "Usage: OPENAI_API_KEY=sk-... $0" >&2
  exit 1
fi

kubectl --kubeconfig "$KUBECONFIG_PATH" create namespace agentgateway-system \
  --dry-run=client -o yaml | kubectl --kubeconfig "$KUBECONFIG_PATH" apply -f -
kubectl --kubeconfig "$KUBECONFIG_PATH" create namespace kagent \
  --dry-run=client -o yaml | kubectl --kubeconfig "$KUBECONFIG_PATH" apply -f -

kubectl --kubeconfig "$KUBECONFIG_PATH" -n agentgateway-system create secret generic openai-secret \
  --from-literal=Authorization="$OPENAI_API_KEY" \
  --dry-run=client -o yaml | kubectl --kubeconfig "$KUBECONFIG_PATH" apply -f -

# kagent requires an API key field for OpenAI-compatible ModelConfig. Agentgateway
# owns the real provider key, so this local value is only used as a client token.
kubectl --kubeconfig "$KUBECONFIG_PATH" -n kagent create secret generic kagent-agentgateway-api-key \
  --from-literal=OPENAI_API_KEY="${KAGENT_AGENTGATEWAY_API_KEY:-unused}" \
  --dry-run=client -o yaml | kubectl --kubeconfig "$KUBECONFIG_PATH" apply -f -

echo "Created/updated LLM secrets in agentgateway-system and kagent."
