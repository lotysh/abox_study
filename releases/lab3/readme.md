
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
