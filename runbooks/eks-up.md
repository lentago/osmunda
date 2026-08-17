# Runbook: EKS overlay — stand up

**Status: skeleton.** The scripts referenced here land later; this documents the
procedure and, above all, the cost gate.

> ⛔ **Cost gate — read first.** The EKS control plane bills **~$0.10/hour** for
> as long as it exists (a flagged exception to free-tier-first). You are turning
> on a meter. Do not run this without a concrete task and a planned teardown.
> The moment the task is done, run [`eks-down.md`](eks-down.md). Never leave the
> control plane up idle overnight.

## Preconditions

- [ ] A specific, time-boxed reason to need cloud k8s (burst, cloud-only test, managed dep).
- [ ] Teardown time budgeted in the same session.
- [ ] AWS access via the fleet's OIDC path (no long-lived keys).

## Procedure (to be scripted)

1. Provision the cluster (control plane + a minimal node group; smallest viable, spot where possible).
2. Configure IRSA (OIDC provider + IAM roles) for workload identity.
3. `flux bootstrap` against `clusters/eks-ephemeral/` so the overlay reconciles the shared workloads.
4. Verify the target workload, do the task.

## Exit

Go straight to [`eks-down.md`](eks-down.md). Standing up without tearing down is
the failure this runbook exists to prevent.

## TODO (when scripts exist)

- [ ] Provisioning script (eksctl/Terraform) + exact node-group sizing.
- [ ] IRSA setup steps and role ARNs.
- [ ] Flux bootstrap command for the EKS path.
- [ ] A guard that refuses to stand up if a prior cluster is already running.
