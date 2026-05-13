Deployed agentgateway and kagent via Flux/Helm in Kubernetes.
Configured OpenAI access through Kubernetes Secret and GitOps-managed ConfigMap/AgentgatewayBackend/HTTPRoute.
Routed OpenAI-compatible /v1/chat/completions requests through agentgateway and verified HTTP 200 response.
Published releases as OCI artifacts and confirmed Flux reconciled version 0.5.10.
Verified built-in kagent/k8s-agent successfully responds using OpenAI gpt-4.1-nano.

kubectl -n agentgateway-system port-forward deployment/agentgateway-external 15000:15000
kubectl -n kagent port-forward svc/kagent-ui 8080:8080
