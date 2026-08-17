# clusters/lab — Flux entrypoint for the k3s lab cluster

This directory is the reconciliation root for the standing **k3s** cluster
(nodes `k3s-1` on pve5, `k3s-2` on pve4 — provisioned by *kalmia*; this repo
owns everything above the nodes). GitOps is **pull-based**: Flux runs *in* the
cluster and reconciles this path. Nothing here is pushed from CI.

## Layout

| Path | Purpose |
|---|---|
| `flux-system/` | Placeholder — populated by `flux bootstrap` (see below) |
| `infrastructure.yaml` | Flux `Kustomization` → `./infra` (ingress, storage) |
| `apps.yaml` | Flux `Kustomization` → `./apps` (n8n, …); depends on `infrastructure` |

## Bootstrap (one-time, run by an operator)

`flux bootstrap` writes the GitOps-toolkit components and the `GitRepository` +
root `Kustomization` into `flux-system/`, commits them, and installs the
controllers in-cluster. Node provisioning and the k3s install happen **outside**
this repo — do not run them from CI.

```bash
flux bootstrap github \
  --owner=lentago --repository=osmunda \
  --branch=main --path=clusters/lab \
  --personal=false
```

After bootstrap, the controllers reconcile `infrastructure.yaml` then
`apps.yaml` on the interval set in each `Kustomization`.
