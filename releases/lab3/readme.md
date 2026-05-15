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

## Flux artifact recovery

If Flux shows `OCIRepository/releases` errors such as
`lookup pkg-containers.githubusercontent.com: i/o timeout`, or CRD
`HelmRelease` objects show `Could not load chart` from
`source-controller.flux-system.svc.cluster.local`, the issue is usually
in-cluster DNS/service routing after a Codespaces or kind restart. It is not a
GHCR permission problem unless the error says `DENIED`.

Recover the cluster networking and controllers:

```bash
kubectl rollout restart daemonset -n kube-system kube-proxy
kubectl rollout status daemonset -n kube-system kube-proxy --timeout=120s

kubectl rollout restart daemonset -n kube-system kindnet
kubectl rollout status daemonset -n kube-system kindnet --timeout=120s

kubectl rollout restart deployment -n kube-system coredns
kubectl rollout status deployment -n kube-system coredns --timeout=120s

kubectl rollout restart deployment -n flux-system source-controller
kubectl rollout status deployment -n flux-system source-controller --timeout=120s

kubectl rollout restart deployment -n flux-system helm-controller
kubectl rollout status deployment -n flux-system helm-controller --timeout=120s
```

Validate DNS and HTTPS from inside the cluster:

```bash
kubectl run netcheck --rm -it --restart=Never \
  --image=curlimages/curl:8.7.1 -- \
  sh -c 'nslookup pkg-containers.githubusercontent.com && curl -I --max-time 15 https://pkg-containers.githubusercontent.com'
```

Then reconcile the artifact, CRD HelmReleases, and release kustomizations:

```bash
kubectl -n flux-system annotate ocirepository releases \
  reconcile.fluxcd.io/requestedAt="$(date +%s)" --overwrite

kubectl -n agentgateway-system annotate helmrelease agentgateway-crds \
  reconcile.fluxcd.io/requestedAt="$(date +%s)" --overwrite

kubectl -n flux-system annotate helmrelease gateway-api-crds \
  reconcile.fluxcd.io/requestedAt="$(date +%s)" --overwrite

kubectl -n kagent annotate helmrelease kagent-crds \
  reconcile.fluxcd.io/requestedAt="$(date +%s)" --overwrite

kubectl -n flux-system annotate kustomization releases-crds \
  reconcile.fluxcd.io/requestedAt="$(date +%s)" --overwrite

kubectl -n flux-system annotate kustomization releases \
  reconcile.fluxcd.io/requestedAt="$(date +%s)" --overwrite
```

Avoid deleting CRDs for this failure mode. The CRDs can already be installed;
the failing part is Flux reading chart and OCI artifacts from source-controller.



RESULTS:

```
deployment.apps/platform-upgrade-advisor         1/1     1            1           4m46s
deployment.apps/platform-upgrade-advisor-mcp     1/1     1            1           4m46s
service/platform-upgrade-advisor                         ClusterIP   10.96.234.73    <none>        8080/TCP   4m46s
service/platform-upgrade-advisor-mcp                     ClusterIP   10.96.71.118    <none>        3001/TCP   4m46s
NAME                       PROTOCOL          URL                                                   ACCEPTED
platform-upgrade-advisor   STREAMABLE_HTTP   http://platform-upgrade-advisor-mcp.kagent:3001/mcp   True
NAME                       TYPE          RUNTIME   READY   ACCEPTED
platform-upgrade-advisor   Declarative   python    True    True
@lotysh ➜ /workspaces/abox_study (main) $ kubectl get kustomization releases-crds releases -n flux-system
kubectl get ocirepository releases -n flux-system
kubectl get deploy,svc -n kagent | grep platform-upgrade-advisor
kubectl get remotemcpservers -n kagent platform-upgrade-advisor -o yaml
kubectl get agents -n kagent platform-upgrade-advisor -o yaml
NAME            AGE     READY   STATUS
releases-crds   6d22h   True    Applied revision: 0.7.0@sha256:d097889aaad2335ebe85c926b57317816088c703e33ac257fbd605861f814fab
releases        6d22h   True    Applied revision: 0.7.0@sha256:d097889aaad2335ebe85c926b57317816088c703e33ac257fbd605861f814fab
NAME       URL                                        READY   STATUS                                                                                                       AGE
releases   oci://ghcr.io/lotysh/abox_study/releases   True    stored artifact for digest '0.7.0@sha256:d097889aaad2335ebe85c926b57317816088c703e33ac257fbd605861f814fab'   6d22h
deployment.apps/platform-upgrade-advisor         1/1     1            1           14m
deployment.apps/platform-upgrade-advisor-mcp     1/1     1            1           14m
service/platform-upgrade-advisor                         ClusterIP   10.96.234.73    <none>        8080/TCP   14m
service/platform-upgrade-advisor-mcp                     ClusterIP   10.96.71.118    <none>        3001/TCP   14m
apiVersion: kagent.dev/v1alpha2
kind: RemoteMCPServer
metadata:
  creationTimestamp: "2026-05-15T13:53:39Z"
  generation: 1
  labels:
    kustomize.toolkit.fluxcd.io/name: releases
    kustomize.toolkit.fluxcd.io/namespace: flux-system
  name: platform-upgrade-advisor
  namespace: kagent
  resourceVersion: "176086"
  uid: c08f72ac-67dc-4034-b2f3-fb16ef446410
spec:
  description: Platform upgrade advisor MCP app for GitOps-managed Kubernetes components.
  protocol: STREAMABLE_HTTP
  sseReadTimeout: 5m0s
  terminateOnClose: true
  timeout: 10s
  url: http://platform-upgrade-advisor-mcp.kagent:3001/mcp
status:
  conditions:
  - lastTransitionTime: "2026-05-15T13:54:40Z"
    message: Remote MCP server configuration accepted
    observedGeneration: 1
    reason: Reconciled
    status: "True"
    type: Accepted
  discoveredTools:
  - description: Discover GitOps-managed platform components that can be considered
      for upgrades.
    name: discover_upgrade_targets
  - description: Return current versions and revisions for GitOps-controlled components.
    name: get_current_versions
  - description: Explain common upgrade risks for a platform component type.
    name: explain_upgrade_risks
  - description: Propose a safe GitOps upgrade plan without applying any changes.
    name: propose_gitops_upgrade_plan
  observedGeneration: 1
apiVersion: kagent.dev/v1alpha2
kind: Agent
metadata:
  creationTimestamp: "2026-05-15T13:53:39Z"
  generation: 1
  labels:
    kustomize.toolkit.fluxcd.io/name: releases
    kustomize.toolkit.fluxcd.io/namespace: flux-system
  name: platform-upgrade-advisor
  namespace: kagent
  resourceVersion: "175905"
  uid: d765471f-2bdb-4b66-b780-6be2423b2274
spec:
  declarative:
    modelConfig: default-model-config
    runtime: python
    stream: true
    systemMessage: |-
      You are the Platform Upgrade Advisor for this Kubernetes lab environment.

      Use your MCP tools to inspect current platform state, identify GitOps-managed
      upgrade targets, explain risks, and propose safe upgrade plans.

      Guardrails:
      - Never apply changes directly to the cluster.
      - Prefer GitOps/IaC changes and one component per pull request.
      - Mention CRD-first ordering when a component has CRDs.
      - Always include verification and rollback guidance.
      - If a target version is unknown, ask for it or recommend release-note review.

      Response format:
      - Start with a short status summary.
      - List discovered components or versions.
      - Provide risk level and recommended next actions.
      - Include concrete GitOps files or kubectl checks when relevant.
    tools:
    - mcpServer:
        apiGroup: kagent.dev
        kind: RemoteMCPServer
        name: platform-upgrade-advisor
        toolNames:
        - discover_upgrade_targets
        - get_current_versions
        - explain_upgrade_risks
        - propose_gitops_upgrade_plan
      type: McpServer
  description: Advises platform engineers on safe GitOps-driven upgrades for cluster
    components.
  type: Declarative
status:
  conditions:
  - lastTransitionTime: "2026-05-15T13:53:39Z"
    message: Agent configuration accepted
    observedGeneration: 1
    reason: Reconciled
    status: "True"
    type: Accepted
  - lastTransitionTime: "2026-05-15T13:53:57Z"
    message: Deployment is ready
    observedGeneration: 1
    reason: DeploymentReady
    status: "True"
    type: Ready
  observedGeneration: 1
```
