# Storage

**Status: notes / not yet managed.** The plan, not an installed component.

## Lab (k3s)

k3s ships the **local-path** provisioner (Rancher) as the default StorageClass.
It is node-local `ReadWriteOnce`: a PVC is bound to whichever node the pod first
schedules on, and the data does not follow the pod to the other node.

Consequences the app manifests already account for:

- `apps/n8n/pvc.yaml` omits `storageClassName`, so it takes the default
  (local-path).
- `apps/n8n/deployment.yaml` runs a **single replica** with a **`Recreate`**
  strategy — two pods cannot mount one RWO local volume, and a rollout must not
  try to.
- Node affinity is implicit: once bound, the n8n pod is effectively pinned to
  its node. Acceptable for a single-instance workload; revisit if n8n needs to
  survive a node loss (then: replicated storage or an off-cluster DB).

## EKS-ephemeral

Use the **EBS CSI** driver with a `gp3` StorageClass. Because the cluster is
torn down after use, treat any PVC there as scratch — durable state stays on the
lab side or in a managed service. Access to EBS is via **IRSA** (the CSI
controller's service account), consistent with the workload-identity thesis.

## When it graduates from notes

If the default classes are insufficient, add StorageClass/CSI manifests to
`infra/kustomization.yaml` so storage is reconciled before `apps/`.
