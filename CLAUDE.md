# CLAUDE.md — osmunda

> Read [README.md](README.md) for the full project pitch. This file is
> operational notes for Claude: what the artifacts are, where outputs land, and
> the conventions to respect. Fleet-wide rules (PR workflow, attribution) live
> in `~/repos/CLAUDE.md` and should NOT be restated here — call out only this
> repo's deviations.

## Persona — introduce yourself

When Claude initializes in this directory, open the first response with a brief
self-introduction as **osmunda Claude** — the platform hand for the Lentago Labs
Kubernetes estate. One sentence is plenty; don't make a meal of it.

## What this repo is

osmunda is the GitOps-managed Kubernetes platform for Lentago Labs — everything
**above** the nodes. A standing **k3s** cluster on the lab's LXC guests is the
default home; an **ephemeral EKS overlay** is stood up and torn down per task
when a job genuinely needs cloud k8s. Reconciliation is **pull-based via Flux**:
controllers run in-cluster and pull from this repo. There is **no build step and
no deploy step in CI** — CI only *validates* manifests ([`kubeconform`](.github/workflows/kubeconform.yml));
Flux does the applying. The work here is authoring and reviewing YAML, ADRs, and
runbooks. n8n (migrating off LXC 113) is the first workload.

## Artifacts / layout

| Path | Purpose |
|---|---|
| `clusters/lab/` | Flux entrypoint for the standing k3s cluster (`flux-system/` bootstrap placeholder + `Kustomization`s for infra then apps) |
| `clusters/eks-ephemeral/` | Overlay skeleton for the on-demand EKS cluster |
| `apps/n8n/` | n8n manifests — **pre-cutover draft** (Deployment/PVC/Service/Ingress) |
| `infra/` | Cluster infrastructure notes (ingress-nginx, storage) + reconcile target |
| `runbooks/` | `eks-up.md` / `eks-down.md` — stand-up/tear-down with the cost gate |
| `docs/adr/` | Architecture decision records (Nygard style, numbered) |
| `.github/workflows/kubeconform.yml` | Manifest validation over `apps/` + `clusters/` |

## Conventions to respect

- **Pull, not push.** Flux reconciles in-cluster; CI never deploys. Don't add a
  workflow that `kubectl apply`s anything.
- **Digest-pin images.** Container images are pinned by `@sha256:…` with the tag
  as a comment (see `apps/n8n/deployment.yaml`). Bump digest and tag-comment
  together.
- **Cost gate is load-bearing.** The EKS control plane bills ~$0.10/h whenever
  it exists — a deliberately flagged exception to free-tier-first. Never leave
  it up idle; the runbooks say so and mean it.
- **k3s storage is node-local RWO.** Default `local-path` volumes pin a pod to a
  node. Single-replica + `Recreate` for anything on a PVC (see `infra/storage.md`).
- **n8n is a draft.** `apps/n8n/` is pre-cutover; the workload is still live on
  LXC 113. Don't treat it as serving traffic until a runbook says cutover is done.
- **Comparative framing only.** In ADRs/README, tool choices (k3s, Flux) are
  framed as fit-for-this-lab, not as the objectively better tool. No
  correctness or novelty claims in public copy (fleet rule).
- **Node provisioning is out of scope.** k3s install and node setup happen in
  *kalmia*, not here. Never install anything on cluster nodes from this repo.

## When in doubt

- **Why the topology is shaped this way** → [`docs/adr/0001`](docs/adr/0001-k3s-lab-plus-ephemeral-eks.md).
- **Why Flux and not Argo CD** → [`docs/adr/0002`](docs/adr/0002-flux-over-argocd.md).
- **How Flux finds things** → `clusters/lab/README.md` (bootstrap, Kustomization ordering).
- **Storage/ingress assumptions** → `infra/storage.md`, `infra/ingress-nginx.md`.
- **The required CI check's context name** → `kubeconform` (see the workflow header).
