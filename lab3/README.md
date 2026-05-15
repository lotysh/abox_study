# Lab 3: Platform Upgrade Advisor MCP App

## Research

Platform teams need a safe way to keep GitOps-managed infrastructure current
without blindly changing controller, CRD, or platform component versions. A
Platform Upgrade Advisor MCP App can inspect the live cluster, summarize current
component versions, explain upgrade risks, and propose GitOps changes.

This MVP focuses on the current abox cluster. AWS-specific checks such as AMI,
VPC CNI, CoreDNS, kube-proxy, and CSI driver upgrade planning are future
extensions.

## Implemented Case

The app answers questions such as:

```text
Discover upgradeable platform components in this cluster and propose a safe
GitOps upgrade plan for kagent.
```

The MCP server exposes these tools:

- `discover_upgrade_targets`
- `get_current_versions`
- `explain_upgrade_risks`
- `propose_gitops_upgrade_plan`

## GitOps Resources

Manifests live in `releases/lab3/`:

- `rbac.yaml`
- `upgrade-advisor-mcp.yaml`
- `upgrade-advisor-agent.yaml`

## Deploy

Use a new minor release tag so Flux's lexicographic tag sorting picks it up:

```bash
git add lab3 releases/kustomization.yaml releases/lab3
git commit -m "Add lab3 platform upgrade advisor MCP app"
git push origin main
git tag v0.7.0
git push origin v0.7.0
```

Then reconcile:

```bash
kubectl -n flux-system annotate resourcesetinputprovider releases-image \
  fluxcd.controlplane.io/reconcileAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --overwrite
```

## Verify

```bash
kubectl get kustomization releases -n flux-system
kubectl get deploy,svc -n kagent | grep platform-upgrade-advisor
kubectl get remotemcpservers -n kagent platform-upgrade-advisor
kubectl get agents -n kagent platform-upgrade-advisor
```

In kagent UI, open `kagent/platform-upgrade-advisor` and ask:

```text
Discover upgradeable platform components in this cluster and propose a safe
GitOps upgrade plan for kagent.
```

Expected evidence:

- the agent calls `discover_upgrade_targets`
- the agent calls `propose_gitops_upgrade_plan`
- the answer lists Flux/Helm/kagent/agentgateway components and proposes a
  GitOps-only upgrade workflow

## MCP Inspector

Port-forward the MCP server:

```bash
kubectl -n kagent port-forward svc/platform-upgrade-advisor-mcp 33001:3001
```

Run the inspector:

```bash
npx @modelcontextprotocol/inspector@0.21.1
```

Connect with:

```text
Transport: Streamable HTTP
URL: http://127.0.0.1:33001/mcp
```

Call `discover_upgrade_targets` and `propose_gitops_upgrade_plan` as evidence.

## agents-cli Playground

Agents CLI can be used as a local development/playground workflow for an agent
that talks to this MCP server:

```bash
uvx google-agents-cli setup
agents-cli create platform-upgrade-advisor-agent --prototype --yes
cd platform-upgrade-advisor-agent
agents-cli install
agents-cli playground
```

In the playground, configure a tool connection to:

```text
http://127.0.0.1:33001/mcp
```

The production lab deployment remains the GitOps-managed kagent agent in
`releases/lab3/upgrade-advisor-agent.yaml`.
