# ADR-0001: k3s on the lab, EKS only when ephemeral

**Status:** Accepted (2026-08-17)

## Context

osmunda is the platform layer for Lentago Labs: the GitOps-managed Kubernetes
estate sitting above the nodes. The question this record settles is *where the
cluster lives*.

Forces in play:

- **Cost.** The lab runs on hardware Lentago Labs already owns (Proxmox hosts
  pve4/pve5 with LXC guests). A standing managed cloud cluster (EKS/GKE/AKS)
  bills a control-plane fee **continuously** whether or not it is doing
  anything — for a learning lab that is idle most of the day, that is paying
  rent on capacity that mostly sits unused.
- **Sovereignty.** The fleet's thesis is free-tier-first and keep-control-of-
  your-own-substrate. A cluster on owned hardware has no per-hour meter and no
  external dependency for the platform to exist at all.
- **Occasional real need for cloud.** Some tasks genuinely want cloud k8s:
  burst capacity, a cloud-only integration test, or exercising IRSA/OIDC
  workload identity against real AWS. Those are episodic, not continuous.
- **Scale.** This is a **2-node** lab, not a fleet of clusters. The platform
  should match that: light to run, cheap to reason about.

## Decision

Two clusters with different lifecycles:

1. **Standing lab cluster — k3s in LXC.** The default, always-on environment is
   a k3s cluster on the lab's LXC guests (`k3s-1` on pve5, `k3s-2` on pve4).
   Nodes are provisioned outside this repo (by *kalmia*); osmunda owns
   everything above them. k3s is chosen for a small lab specifically because it
   is a single lightweight binary with a small footprint — a fit for 2 nodes,
   not a claim that it is a better distribution than upstream k8s.

2. **Ephemeral EKS overlay — created and destroyed per task.** When a task
   genuinely needs cloud k8s, an EKS cluster is stood up via runbook, used, and
   **torn down immediately**. The control plane bills **~$0.10/hour** while it
   exists; this is called out as a **deliberate, flagged exception** to
   free-tier-first, and the runbooks
   ([`eks-up.md`](../../runbooks/eks-up.md) / [`eks-down.md`](../../runbooks/eks-down.md))
   make "never leave it up idle" the load-bearing rule. Durable state never
   lives on the ephemeral side.

## Alternatives

**Standing managed cloud cluster (EKS/GKE/AKS) as the primary environment** —
The conventional production choice: a managed control plane always available.
For *this* lab it means paying a control-plane fee around the clock for a
cluster idle most of the time, and moving the substrate off owned hardware.
*Worse for this context* on both cost and the sovereignty thesis — the very
thing the ephemeral-overlay pattern is designed to avoid. (Not a judgement on
managed k8s for production workloads with steady load, where the trade math is
different.)

**Full upstream Kubernetes (kubeadm) on the LXC guests** *(retrospective — not
considered at the time)* — Run vanilla k8s on the same owned hardware. Keeps
cost sovereignty, but a multi-component control plane (etcd, separate
apiserver/controller-manager/scheduler) is more to operate and patch than k3s's
single binary on a 2-node lab. *Lateral, leaning worse here*: more operational
surface for no benefit at this scale; closer to "real" production topology if
that were ever the goal, which for a learning lab it is not.

**No cloud path at all — lab only** *(retrospective — not considered at the
time)* — Simplest and cheapest. *Worse* only in that it forecloses the episodic
cloud needs (burst, cloud-only tests, exercising IRSA against real AWS) that the
ephemeral overlay exists to serve without a standing bill.

## Consequences

- The platform has **zero standing cloud cost**; the only cloud spend is the
  metered, deliberately-flagged EKS control plane during an active task.
- Two reconciliation roots to maintain ([`clusters/lab/`](../../clusters/lab/)
  and [`clusters/eks-ephemeral/`](../../clusters/eks-ephemeral/)). Shared
  workloads live once in [`apps/`](../../apps/); cloud-specific differences are
  layered as overlays, keeping the app manifests cloud-agnostic.
- The ephemeral model puts a **discipline burden** on teardown: forgetting
  `eks-down` turns a flagged exception into a silent recurring bill. The
  runbooks and a planned TTL backstop exist to contain that.
- Local-node storage on k3s (`ReadWriteOnce`, node-pinned) shapes workload
  design — see [`infra/storage.md`](../../infra/storage.md); the first workload
  (n8n) is single-replica as a direct result.
