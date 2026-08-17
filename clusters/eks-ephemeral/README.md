# clusters/eks-ephemeral — overlay skeleton (stood up on demand)

This is the reconciliation root for the **ephemeral EKS overlay** — a cloud
cluster that is created for a specific need (burst capacity, a cloud-only
integration test, a managed-service dependency) and **torn down immediately
after**. It is not a standing environment.

> **Cost gate.** The EKS control plane bills ~**$0.10/hour** whenever it exists
> — a deliberately flagged exception to the fleet's free-tier-first rule. It
> must never be left running idle. See [`runbooks/eks-up.md`](../../runbooks/eks-up.md)
> and [`runbooks/eks-down.md`](../../runbooks/eks-down.md).

## Status: skeleton

The cluster provisioning scripts and Flux bootstrap for EKS land later
(tracked with the runbooks). This directory currently holds only the intended
shape:

| Path | Purpose |
|---|---|
| `flux-system/` | Placeholder — `flux bootstrap` writes toolkit + sync here at stand-up |
| `apps.yaml` | Flux `Kustomization` → `./apps`, so the overlay reconciles the same workload set |

Workload identity on this side uses **IRSA** (OIDC), continuing the fleet's
workload-identity thesis. The lab side (k3s) uses its own in-cluster identity;
manifests shared via `apps/` stay cloud-agnostic, with any EKS-specific
patches layered here as a kustomize overlay when the scripts exist.
