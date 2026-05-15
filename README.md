# abox

> One command. Full AI infrastructure.

`make run` gives you a local Kubernetes cluster with everything an AI project needs: an AI-aware API gateway, an agent runtime, observability, distributed tracing, and an eval harness — ready to use.

## What's included

| Component | Role |
|---|---|
| **agentgateway v2.2.1** | AI-aware API gateway (Gateway API–native, MCP-aware) |
| **kagent** | Kubernetes-native AI agent framework |
| **Flux CD 2.x** | GitOps/GitLessOps operator — keeps the cluster in sync with OCI artifacts |
| **KinD** | Local Kubernetes (1 control-plane + 2 workers) - can be any k8s |
| **cloud-provider-kind** | LoadBalancer support so gateway gets a real IP for local development |

## Quickstart

```bash
make run
```

That's it. Installs OpenTofu and k9s, provisions the cluster, bootstraps Flux, and reconciles all components. When it finishes:

```bash
kubectl get gateway,httproute -A        # gateway is up
kubectl get agents -n kagent            # agent runtime is up
kubectl get svc -n agentgateway-system  # grab the LoadBalancer IP
```

Point your AI app at the gateway IP on port 80.

## LLM gateway

The Kubernetes deployment routes OpenAI-compatible requests through agentgateway.
The real provider key is not stored in Git. Create it locally after the cluster is up:

```bash
OPENAI_API_KEY=sk-... ./scripts/create-llm-secrets.sh
```

Then reconcile or re-run the release flow. For local checks, port-forward the gateway proxy:

```bash
kubectl --kubeconfig bootstrap/abox-config -n agentgateway-system port-forward deployment/agentgateway-external 8080:80
```

Test the LLM route:

```bash
curl "localhost:8080/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4.1-nano",
    "messages": [{"role": "user", "content": "What is Kubernetes in one sentence?"}]
  }'
```

Inspect the agentgateway Admin UI:

```bash
kubectl --kubeconfig bootstrap/abox-config -n agentgateway-system port-forward deployment/agentgateway-external 15000:15000
```

Open http://localhost:15000/ui/.

kagent uses the `agentgateway-openai` `ModelConfig`, which points at the in-cluster
agentgateway endpoint instead of calling OpenAI directly.

## Codespaces restart recovery

After a Codespaces restart, wait for the cluster and Flux to settle:

```bash
kubectl get kustomization -n flux-system
kubectl get pods -n agentgateway-system
kubectl get agents,mcpservers -n kagent
```

If `agentgateway-external` is stuck in `CrashLoopBackOff` or the UI/API port
forward drops with connection refused, restart both agentgateway deployments:

```bash
kubectl rollout restart deployment -n agentgateway-system agentgateway
kubectl rollout restart deployment -n agentgateway-system agentgateway-external
kubectl rollout status deployment -n agentgateway-system agentgateway --timeout=120s
kubectl rollout status deployment -n agentgateway-system agentgateway-external --timeout=120s
```

Useful UI forwards after recovery:

```bash
kubectl -n flux-system port-forward svc/flux-operator 30080:9080
kubectl -n agentgateway-system port-forward deployment/agentgateway-external 30081:15000
kubectl -n kagent port-forward svc/kagent-ui 30082:8080
```

## How it works

```
make run  →  scripts/setup.sh
  → tofu apply (bootstrap/)
      → KinD cluster
      → Flux Operator + FluxInstance
      → ResourceSetInputProvider   polls oci://ghcr.io/den-vasyliev/abox/releases
      → ResourceSet                creates OCIRepository + 2 Kustomizations
          → releases/crds/    gateway-api-crds, agentgateway-crds, kagent-crds
          → releases/         agentgateway (Gateway + GatewayClass)
                              kagent (agent runtime + HTTPRoute)
```

Everything after the cluster is **gitless GitOps via OCI**: no Git polling, no deploy keys. CI publishes `releases/` as an OCI artifact on every version tag. The cluster reconciles from that artifact automatically.

## Releasing

```bash
make push   # bumps patch version, tags, pushes → CI publishes OCI artifact → cluster reconciles
```

> **Note:** RSIP tag sorting is lexicographic. If the patch version would exceed 9, bump the minor instead: `git tag vX.Y+1.0`.

## Directory layout

| Path | Purpose |
|---|---|
| `bootstrap/` | OpenTofu: KinD + Flux bootstrap (operator, instance, RSIP, ResourceSet) |
| `releases/crds/` | CRD HelmReleases: gateway-api, agentgateway, kagent |
| `releases/` | App HelmReleases + Gateway + HTTPRoutes |
| `scripts/setup.sh` | Full setup script (`make run`) |
| `.github/workflows/flux-push.yaml` | CI: publish `releases/` as OCI artifact on `v*` tags |

## Adding components

1. Put CRD charts in `releases/crds/` as HelmReleases.
2. Put app charts in `releases/` as HelmReleases.
3. Run `make push` — the cluster reconciles automatically.

The CRD kustomization runs first (`wait: true`), apps run after (`dependsOn: releases-crds`). This ordering is enforced by Flux and must be preserved.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

Apache 2.0 — see [LICENSE](./LICENSE).
