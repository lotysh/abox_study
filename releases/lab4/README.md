# Lab 4: A2A, Inventory, MCP Governance, and Qdrant

## Goal

This lab extends the existing abox GitOps environment with:

- A2A protocol research and two custom A2A agents
- Agent cards exposed from well-known URIs
- A2A task communication between two agents
- Agent Registry Inventory
- MCP Security Governance
- Qdrant vector database

## Research: A2A

A2A lets agents describe themselves with an Agent Card and communicate using a
task/message protocol. The Agent Card is discoverable over HTTP at:

```text
/.well-known/agent-card.json
```

In this lab:

- `lab4-orchestrator-a2a` exposes an Agent Card and accepts A2A task messages.
- `lab4-inventory-analyst-a2a` exposes an Agent Card and returns an AI resource inventory.
- The orchestrator delegates work to the analyst with an A2A JSON-RPC
  `message/send` request.

## GitOps Resources

Manifests live in `releases/lab4/`:

- `qdrant.yaml`
- `agentregistry-inventory.yaml`
- `mcp-governance.yaml`
- `a2a-agents.yaml`
- `a2a-routes.yaml`

The deployment continues to use the same Flux OCI release workflow as previous
labs.

## Deploy

Use the next minor release tag so the ResourceSetInputProvider selects the new
artifact:

```bash
git add lab4 releases/kustomization.yaml releases/lab4
git commit -m "Add lab4 A2A and inventory infrastructure"
git push origin main
git tag v0.8.0
git push origin v0.8.0
```

Then reconcile the release image:

```bash
kubectl -n flux-system annotate resourcesetinputprovider releases-image \
  fluxcd.controlplane.io/reconcileAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --overwrite
```

If Flux does not pick the new tag because of tag ordering, patch the OCI source
explicitly:

```bash
kubectl -n flux-system patch ocirepository releases \
  --type=merge \
  -p '{"spec":{"ref":{"tag":"0.8.0"}}}'

kubectl -n flux-system annotate ocirepository releases \
  reconcile.fluxcd.io/requestedAt="$(date +%s)" --overwrite
```

## Verify Infrastructure

```bash
kubectl get kustomization releases-crds releases -n flux-system
kubectl get helmrelease -A
kubectl get pods,svc -n qdrant
kubectl get pods,svc -n agentregistry
kubectl get pods,svc -n mcp-governance
kubectl get deploy,svc -n kagent | grep lab4
kubectl get httproute lab4-a2a -n kagent
```

## Verify A2A Agent Cards

Direct service checks:

```bash
kubectl -n kagent port-forward svc/lab4-orchestrator-a2a 34080:8080
kubectl -n kagent port-forward svc/lab4-inventory-analyst-a2a 34081:8080
```

```bash
curl http://127.0.0.1:34080/.well-known/agent-card.json
curl http://127.0.0.1:34081/.well-known/agent-card.json
```

Gateway checks:

```bash
kubectl -n agentgateway-system port-forward svc/agentgateway-external 30081:80
```

```bash
curl http://127.0.0.1:30081/lab4/a2a/orchestrator/.well-known/agent-card.json
curl http://127.0.0.1:30081/lab4/a2a/analyst/.well-known/agent-card.json
```

## Verify A2A Task Communication

```bash
curl -s http://127.0.0.1:34080/a2a \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": "lab4-task-1",
    "method": "message/send",
    "params": {
      "message": {
        "role": "user",
        "parts": [
          {
            "kind": "text",
            "text": "Ask the inventory analyst to summarize AI resources in this cluster."
          }
        ]
      }
    }
  }'
```

Expected evidence:

- The response comes from `lab4-orchestrator-a2a`.
- The response includes `A2A handoff completed`.
- The artifact contains a nested peer result from `lab4-inventory-analyst-a2a`.
- The peer result lists kagent agents, MCP servers, remote MCP servers, model configs,
  Helm releases, and Flux kustomizations.

## Inventory

Agent Registry Inventory is deployed from:

```text
https://github.com/den-vasyliev/agentregistry-inventory
```

Useful checks:

```bash
kubectl get gitrepository agentregistry-inventory -n flux-system
kubectl get kustomization agentregistry-inventory-crds -n flux-system
kubectl get helmrelease agentregistry-inventory -n agentregistry
kubectl get pods,svc -n agentregistry
```

The controller exposes:

- HTTP API on `:8080`
- MCP server on `:8083`

## MCP Governance

MCP Security Governance is deployed from the upstream Git repository Helm chart:

```text
https://github.com/techwithhuz/mcp-security-governance
chart: ./charts/mcp-governance
```

Useful checks:

```bash
kubectl get gitrepository mcp-governance -n flux-system
kubectl get helmrelease mcp-governance -n mcp-governance
kubectl get pods,svc -n mcp-governance
```

## Qdrant

Qdrant is deployed from the official Helm repository:

```text
https://qdrant.github.io/qdrant-helm
```

Useful checks:

```bash
kubectl get helmrepository qdrant -n flux-system
kubectl get helmrelease qdrant -n qdrant
kubectl get pods,svc -n qdrant
```
