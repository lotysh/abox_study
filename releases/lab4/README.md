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


```bash
NAME       AGE   READY   STATUS
releases   9d    True    Applied revision: 0.8.3@sha256:1d8edca527467e1912939ba814b02d72e176388a3efb815c1517850ce43f14c3
agentregistry         agentregistry-inventory   35m   True    Helm install succeeded for release agentregistry/agentregistry-inventory.v1 with chart agentregistry@0.1.0
mcp-governance        mcp-governance            35m   True    Helm upgrade succeeded for release mcp-governance/mcp-governance.v2 with chart mcp-governance@0.1.0
qdrant                qdrant                    35m   True    Helm install succeeded for release qdrant/qdrant.v1 with chart qdrant@1.18.0
NAME                                                      READY   STATUS    RESTARTS   AGE
pod/agentregistry-inventory-controller-75f7658466-chkrs   1/1     Running   0          35m

NAME                                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
service/agentregistry-inventory-api       ClusterIP   10.96.157.1     <none>        8080/TCP,8083/TCP   35m
service/agentregistry-inventory-metrics   ClusterIP   10.96.203.132   <none>        8081/TCP            35m
NAME                                             READY   STATUS    RESTARTS   AGE
pod/mcp-governance-controller-55db4f8ccf-n7tp5   1/1     Running   0          20m
pod/mcp-governance-dashboard-6d78fd877b-kksfr    1/1     Running   0          20m

NAME                                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/mcp-governance-controller   ClusterIP   10.96.40.57    <none>        8090/TCP   28m
service/mcp-governance-dashboard    ClusterIP   10.96.162.49   <none>        3000/TCP   28m
NAME           READY   STATUS    RESTARTS   AGE
pod/qdrant-0   1/1     Running   0          35m

NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
service/qdrant            ClusterIP   10.96.231.82   <none>        6333/TCP,6334/TCP,6335/TCP   35m
service/qdrant-headless   ClusterIP   None           <none>        6333/TCP,6334/TCP,6335/TCP   35m

@lotysh ➜ /workspaces/abox_study (main) $ curl -s http://127.0.0.1:34080/.well-known/agent-card.json | jq
{
  "protocolVersion": "0.3.0",
  "name": "lab4-orchestrator-a2a",
  "description": "Coordinates an A2A task with the inventory analyst agent.",
  "url": "http://lab4-orchestrator-a2a.kagent:8080",
  "preferredTransport": "JSONRPC",
  "capabilities": {
    "streaming": false,
    "pushNotifications": false
  },
  "skills": [
    {
      "id": "a2a-orchestration",
      "name": "A2A Orchestration",
      "description": "Return a cluster AI resource inventory summary via A2A task communication.",
      "tags": [
        "a2a",
        "inventory",
        "kubernetes",
        "gitops"
      ],
      "examples": [
        "List AI resources in this cluster."
      ]
    }
  ]
}
@lotysh ➜ /workspaces/abox_study (main) $ curl -s http://127.0.0.1:34081/.well-known/agent-card.json | jq
{
  "protocolVersion": "0.3.0",
  "name": "lab4-inventory-analyst-a2a",
  "description": "Analyzes AI resources discovered in the Kubernetes cluster.",
  "url": "http://lab4-inventory-analyst-a2a.kagent:8080",
  "preferredTransport": "JSONRPC",
  "capabilities": {
    "streaming": false,
    "pushNotifications": false
  },
  "skills": [
    {
      "id": "inventory-analysis",
      "name": "Inventory Analysis",
      "description": "Return a cluster AI resource inventory summary via A2A task communication.",
      "tags": [
        "a2a",
        "inventory",
        "kubernetes",
        "gitops"
      ],
      "examples": [
        "List AI resources in this cluster."
      ]
    }
  ]
}
```
