# Runbook: EKS overlay — stand up

**Status: exercised.** First drill run 2026-08-17 (lentago/.github#119); the
scripts are real and live in [`bin/`](bin/). Measured on that run:

| Phase | Wall clock |
|---|---|
| `eks-up.sh` start → control plane + Fargate profile ready | **13m 54s** |
| IRSA OIDC provider + service-account role | 33s |
| Fargate smoke pod scheduled → identity proven | 62s |
| **Total, meter-on → IRSA proven** | **15m 29s** |

The IRSA proof is the pod's own `sts get-caller-identity` returning the
`irsa-demo` role ARN — workload identity flowed issuer → role → pod with no
stored keys anywhere in the cluster.

> ⛔ **Cost gate — read first.** The EKS control plane bills **~$0.10/hour** for
> as long as it exists (a flagged exception to free-tier-first). You are turning
> on a meter. Do not run this without a concrete task and a planned teardown.
> The moment the task is done, run [`eks-down.md`](eks-down.md). Never leave the
> control plane up idle overnight.

## Preconditions

- [ ] A specific, time-boxed reason to need cloud k8s (burst, cloud-only test, managed dep).
- [ ] Teardown time budgeted in the same session.
- [ ] AWS access via the fleet's OIDC path (no long-lived keys).

## Procedure

```
CLUSTER=osmunda-eph REGION=us-east-1 ./bin/eks-up.sh
```

The script refuses to run if a prior ephemeral cluster exists, creates a
Fargate-only cluster (no node group to size or forget — an idle cluster's only
cost is control plane + NAT), associates the IRSA OIDC provider, creates the
`irsa-demo` service account, and proves identity with a smoke pod. Then do the
task you came for.

**Flux on EKS — deliberate gap from drill #1:** `clusters/eks-ephemeral/`
reconciles `apps/`, but the n8n manifests assume the lab's `local-path`
storage class, which Fargate cannot satisfy (EFS CSI is the Fargate-shaped
answer). Wiring the overlay's storage story is tracked work; until it lands,
the overlay reconcile step stays out of the drill.

## Exit

Go straight to [`eks-down.md`](eks-down.md). Standing up without tearing down is
the failure this runbook exists to prevent.

## Remaining TODO

- [ ] EKS storage story for the overlay (EFS CSI or stateless-only app set),
      then add the Flux reconcile step to the drill.
- [ ] Move drill credentials from the operator IAM user to a role assumption.
