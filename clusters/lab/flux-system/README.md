# flux-system (placeholder)

`flux bootstrap` (see [`../README.md`](../README.md)) generates the real
contents of this directory and commits them here:

- `gotk-components.yaml` — GitOps-toolkit controllers (source, kustomize, helm, notification)
- `gotk-sync.yaml` — the `GitRepository` for this repo + the root `Kustomization`
- `kustomization.yaml` — bundles the two above

They are intentionally **absent** from the scaffold: they are cluster-specific
and must be produced by `flux bootstrap` against the live cluster, not
hand-authored. This file is a marker so the path exists in git; it is replaced
(or left alongside) once bootstrap runs.
