#!/usr/bin/env bash
# eks-up.sh — stand up the ephemeral EKS overlay cluster (runbooks/eks-up.md).
#
# COST GATE: the control plane bills ~$0.10/h from the moment this succeeds,
# plus a NAT gateway (~$0.045/h) in the eksctl-managed VPC. This script is the
# meter-ON switch; eks-down.sh is the only exit. Never leave it up idle.
#
# Fargate-only by design: no EC2 node group to size or forget — pods bill by
# the second, and an empty cluster's only running cost is control plane + NAT.
set -euo pipefail

CLUSTER="${CLUSTER:-osmunda-eph}"
REGION="${REGION:-us-east-1}"

# Guard: refuse to stand up if any prior ephemeral cluster is still running —
# the runbook's whole reason to exist is preventing a forgotten meter.
existing=$(aws eks list-clusters --region "$REGION" --query 'clusters[?starts_with(@, `osmunda-eph`)]' --output text)
if [ -n "$existing" ]; then
  echo "REFUSING: ephemeral cluster(s) already exist: $existing — run eks-down.sh first." >&2
  exit 1
fi

echo "T0 $(date -u +%FT%TZ) — creating $CLUSTER (control plane + Fargate profile)"
eksctl create cluster \
  --name "$CLUSTER" \
  --region "$REGION" \
  --fargate \
  --tags "project=osmunda,lifecycle=ephemeral" \
  --vpc-nat-mode Single

echo "T1 $(date -u +%FT%TZ) — cluster up; associating IRSA OIDC provider"
eksctl utils associate-iam-oidc-provider --cluster "$CLUSTER" --region "$REGION" --approve

# IRSA demo: a service account whose pods can read S3 — the smallest honest
# proof that workload identity flows issuer→role→pod with no stored keys.
eksctl create iamserviceaccount \
  --cluster "$CLUSTER" --region "$REGION" \
  --namespace default --name irsa-demo \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve

echo "T2 $(date -u +%FT%TZ) — IRSA SA ready; running identity smoke test pod"
kubectl run irsa-smoke --overrides='{"spec":{"serviceAccountName":"irsa-demo"}}' \
  --image=public.ecr.aws/aws-cli/aws-cli:latest --restart=Never --command -- \
  aws sts get-caller-identity --output json
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/irsa-smoke --timeout=300s
kubectl logs irsa-smoke
echo "T3 $(date -u +%FT%TZ) — IRSA proven if the ARN above is the irsa-demo role (not a node/user identity)."
echo "NEXT: do the task you stood this up for, then RUN eks-down.sh."
