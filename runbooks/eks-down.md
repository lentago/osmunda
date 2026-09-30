# Runbook: EKS overlay — tear down

**What you're about to do:** delete the ephemeral EKS cluster and every AWS resource it created, then confirm nothing is left billing.

**Why bother:** the control plane bills **~$0.10/hour** until it's gone. This runbook is the other half of [`eks-up.md`](eks-up.md) — every minute you defer it costs money.

**How long:** about 5 minutes. The first drill measured 5m 07s from teardown start to a CLEAN residue check.

**Status: exercised.** First drill run 2026-08-17; the script is real:
[`bin/eks-down.sh`](bin/eks-down.sh). Measured on that run: teardown start →
`all cluster resources were deleted` → residue check **CLEAN** in **5m 07s**.
Whole drill, meter-on to meter-off: **21 minutes**, ≈ **$0.05** (control plane
+ single NAT + Fargate pod-seconds) — the flagged free-tier exception at its
intended size.

> **Heads up.** The control plane bills **~$0.10/hour** until the cluster is
> deleted (see [`eks-up.md`](eks-up.md)). Run this as soon as the task that
> needed EKS is done — do not defer it.

## Procedure

```
CLUSTER=osmunda-eph REGION=us-east-1 ./bin/eks-down.sh
```

Deletes the IRSA service-account stack, then the cluster (waiting on
CloudFormation), then runs the residue check: no `osmunda-eph*` clusters, no
`eksctl-*` stacks, no OIDC providers referencing the cluster. **The teardown
isn't done when the delete returns — it's done when the residue check prints
CLEAN.** A non-clean exit is a failing exit code on purpose: every listed
leftover may be billing.

## You know the meter is off when

All three of these are clear:

- [ ] `aws eks list-clusters` returns none for the overlay.
- [ ] No orphaned NLB/ALB, NAT gateway, or unattached EBS volumes.
- [ ] Billing/Cost Explorer shows the spend stopping.

## TODO (when scripts exist)

- [ ] Teardown script that deletes in dependency order and is safe to re-run.
- [ ] Orphan sweep (load balancers, NAT gateways, unattached volumes).
- [ ] A scheduled backstop that alerts/deletes if a cluster outlives a max TTL.
