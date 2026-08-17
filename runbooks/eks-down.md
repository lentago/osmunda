# Runbook: EKS overlay — tear down

**Status: skeleton.** The scripts referenced here land later; this documents the
procedure and the cost gate it closes.

> ✅ **This runbook stops the meter.** The control plane bills **~$0.10/hour**
> until the cluster is deleted (see [`eks-up.md`](eks-up.md)). Run this as soon
> as the task that needed EKS is done — do not defer it.

## Procedure (to be scripted)

1. Confirm any state worth keeping is already off-cluster (durable state lives on the lab side or in a managed service — EKS PVCs are scratch).
2. Delete workloads / suspend Flux so nothing recreates resources mid-teardown.
3. Delete the node group, then the control plane.
4. Delete the OIDC provider / IAM roles created for IRSA (or confirm the script did).
5. Confirm **no** EKS control plane, NAT gateway, load balancer, or orphaned EBS volume remains — each is its own meter.

## Verify the meter is off

- [ ] `aws eks list-clusters` returns none for the overlay.
- [ ] No orphaned NLB/ALB, NAT gateway, or unattached EBS volumes.
- [ ] Billing/Cost Explorer shows the spend stopping.

## TODO (when scripts exist)

- [ ] Teardown script that deletes in dependency order and is safe to re-run.
- [ ] Orphan sweep (load balancers, NAT gateways, unattached volumes).
- [ ] A scheduled backstop that alerts/deletes if a cluster outlives a max TTL.
