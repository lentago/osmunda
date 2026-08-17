# ADR-0002: Flux for GitOps reconciliation (over Argo CD)

**Status:** Accepted (2026-08-17)

## Context

osmunda is GitOps-managed: the desired state of the cluster lives in this repo
and a controller reconciles the cluster toward it. The fleet's stance is
**pull-based** GitOps — the reconciler runs *inside* the cluster and pulls from
git, rather than CI pushing manifests into the cluster from outside. This record
settles which GitOps engine implements that.

The two mainstream choices are **Flux** (CNCF GitOps-toolkit) and **Argo CD**.
Both are mature CNCF projects; both do continuous reconciliation from git. The
decision is a fit judgement for *this* lab, not a ranking of the tools.

Forces:

- **2-node lab, light footprint wanted** — the platform should not cost more to
  run than the workloads it hosts.
- **Pull-not-push thesis** — the reconciler should live in-cluster and pull; CI
  validates, it does not deploy.
- **Two reconciliation roots** — a standing k3s cluster and an ephemeral EKS
  overlay that is bootstrapped fresh each time it exists.

## Decision

Use **Flux**.

- **Footprint fits a small lab.** Flux is a set of focused controllers
  (source, kustomize, helm, notification) with no bundled UI/API server or
  dedicated datastore to run. On 2 nodes that is less standing overhead than
  Argo CD's application server + UI. This is a fit-for-this-lab reason, not a
  claim that a smaller footprint makes Flux the better tool in general —
  Argo CD's UI is a real asset in larger, multi-team settings.
- **Reconcilers match the pull-not-push thesis.** The GitOps-toolkit
  controllers run in-cluster and pull from git by design; that is exactly the
  model the fleet already commits to, so the tool and the thesis line up
  without adapting either.
- **Bootstrap fits the ephemeral overlay.** `flux bootstrap` cleanly
  (re)establishes the toolkit + sync objects each time the EKS cluster is stood
  up and torn down, which suits a cluster that does not persist.

## Alternatives

**Argo CD** — Equally mature; app-of-apps model, a strong web UI, and rich
multi-cluster/multi-team RBAC. For a 2-node single-operator lab those strengths
are mostly latent while the standing application-server + UI footprint is paid
continuously. *Lateral overall, worse fit here*: the capabilities that justify
Argo CD's heavier footprint (team-facing UI, large multi-tenant estates) are not
what this lab needs yet, and its push-toward-a-UI-centric-workflow sits less
squarely on the pull-not-push thesis than Flux's controller-only model. A
defensible choice; simply not the fit-for-this-context one.

**Plain CI push (kubectl/kustomize apply from Actions)** *(retrospective — not
considered at the time)* — CI applies manifests directly. *Worse*: it is
push-based (the exact model the fleet rejects), has no continuous drift
correction, and would need cluster credentials handed to CI. Rejected on thesis
grounds before footprint even matters.

**Helm + a scheduled job / Helmfile** *(retrospective — not considered at the
time)* — Templating without a reconciler, driven on a timer. *Worse*: no real
reconciliation loop or drift detection, and it reinvents a slice of what Flux's
helm-controller already provides. Flux subsumes the Helm use case via
`HelmRelease` when needed (see [`infra/ingress-nginx.md`](../../infra/ingress-nginx.md)).

## Consequences

- Reconciliation is controller-driven and in-cluster; CI's job is
  **validation** ([`kubeconform`](../../.github/workflows/kubeconform.yml)),
  never deployment. The pull/push boundary stays clean.
- Cluster entrypoints are Flux `Kustomization` objects
  ([`clusters/lab/`](../../clusters/lab/)); the `flux-system` directories are
  populated by `flux bootstrap`, not hand-authored.
- No GitOps UI out of the box. If a visual surface is later wanted, that is a
  new decision (add one, or reconsider Argo CD) recorded as its own ADR — not a
  silent reversal of this one.
- Helm-based components install as Flux `HelmRelease` resources, keeping a
  single reconciliation path rather than a second deploy mechanism.
