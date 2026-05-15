# Lab 3: Platform Upgrade Advisor MCP App

This lab deploys a GitOps-managed MCP App that inspects platform components and
proposes safe GitOps upgrade plans.

Resources:

- `Deployment/platform-upgrade-advisor-mcp`
- `Service/platform-upgrade-advisor-mcp`
- `RemoteMCPServer/platform-upgrade-advisor`
- `Agent/platform-upgrade-advisor`
- read-only RBAC for Flux, kagent, Gateway API, agentgateway, workloads, and nodes

The app intentionally does not apply changes. It only discovers state, explains
risks, and proposes GitOps/IaC edits.

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
