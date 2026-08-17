# infra — cluster infrastructure

Cluster-level infrastructure reconciled by the `infrastructure` Flux
`Kustomization` (see [`../clusters/lab/infrastructure.yaml`](../clusters/lab/infrastructure.yaml))
**before** any workload in `apps/`. This is the layer that must exist for an
app's Service/Ingress/PVC to mean anything.

| Topic | Notes |
|---|---|
| Ingress | [`ingress-nginx.md`](ingress-nginx.md) |
| Storage | [`storage.md`](storage.md) |

`kustomization.yaml` is currently an **empty resource list** — a valid
reconcile target that installs nothing yet. As the ingress controller and any
storage config move from notes into managed manifests (likely Flux
`HelmRelease` resources), add them here so `infrastructure` provisions them.
