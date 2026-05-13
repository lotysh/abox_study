```
kubectl get kustomization releases -n flux-system
NAME       AGE     READY   STATUS
releases   4d22h   True    Applied revision: 0.6.0@sha256:cbf631fa73975db17e472d6c6aaa722493531da54e9caad9dc6d5e39a04de947
@lotysh ➜ /workspaces/abox_study (main) $ kubectl get mcpservers -n kagent
NAME                   READY   AGE
lab2-website-fetcher   True    7m28s
@lotysh ➜ /workspaces/abox_study (main) $ kubectl describe mcpservers -n kagent lab2-website-fetcher
Name:         lab2-website-fetcher
Namespace:    kagent
Labels:       kustomize.toolkit.fluxcd.io/name=releases
              kustomize.toolkit.fluxcd.io/namespace=flux-system
Annotations:  <none>
API Version:  kagent.dev/v1alpha1
Kind:         MCPServer
Metadata:
  Creation Timestamp:  2026-05-13T13:13:51Z
  Generation:          1
  Resource Version:    67983
  UID:                 b74540c9-4eec-482d-8844-2c3bf0439bc5
Spec:
  Deployment:
    Args:
      mcp-server-fetch
    Cmd:       uvx
    Port:      3000
    Replicas:  1
  Stdio Transport:
  Timeout:         30s
  Transport Type:  stdio
Status:
  Conditions:
    Last Transition Time:  2026-05-13T13:13:51Z
    Message:               MCPServer configuration is valid
    Observed Generation:   1
    Reason:                Accepted
    Status:                True
    Type:                  Accepted
    Last Transition Time:  2026-05-13T13:13:51Z
    Message:               All references resolved successfully
    Observed Generation:   1
    Reason:                ResolvedRefs
    Status:                True
    Type:                  ResolvedRefs
    Last Transition Time:  2026-05-13T13:13:51Z
    Message:               All resources created successfully
    Observed Generation:   1
    Reason:                Programmed
    Status:                True
    Type:                  Programmed
    Last Transition Time:  2026-05-13T13:15:22Z
    Message:               Deployment is ready and all pods are running
    Observed Generation:   1
    Reason:                Available
    Status:                True
    Type:                  Ready
  Observed Generation:     1
Events:                    <none>

kubectl get agents -n kagent lab2-fetch-agent
NAME               TYPE          RUNTIME   READY   ACCEPTED
lab2-fetch-agent   Declarative   python    True    True


kubectl get modelconfigs -n kagent
NAME                   PROVIDER   MODEL
default-model-config   OpenAI     gpt-4.1-nano

```