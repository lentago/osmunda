#!/usr/bin/env bash
# eks-down.sh — tear down the ephemeral EKS overlay and PROVE zero residue.
# The teardown isn't done when the delete returns; it's done when nothing
# billable or nameable is left. The residue check is the deliverable.
set -euo pipefail

CLUSTER="${CLUSTER:-osmunda-eph}"
REGION="${REGION:-us-east-1}"

echo "T0 $(date -u +%FT%TZ) — deleting IRSA service-account stack(s) first"
eksctl delete iamserviceaccount --cluster "$CLUSTER" --region "$REGION" \
  --namespace default --name irsa-demo --wait || true

echo "T1 $(date -u +%FT%TZ) — deleting cluster (waits for CloudFormation)"
eksctl delete cluster --name "$CLUSTER" --region "$REGION" --wait

echo "T2 $(date -u +%FT%TZ) — residue check"
fail=0
clusters=$(aws eks list-clusters --region "$REGION" --query 'clusters[?starts_with(@, `osmunda-eph`)]' --output text)
[ -n "$clusters" ] && { echo "RESIDUE: EKS clusters remain: $clusters"; fail=1; }
stacks=$(aws cloudformation list-stacks --region "$REGION" \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE DELETE_FAILED \
  --query "StackSummaries[?starts_with(StackName, 'eksctl-$CLUSTER')].StackName" --output text)
[ -n "$stacks" ] && { echo "RESIDUE: CloudFormation stacks remain: $stacks"; fail=1; }
oidc=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text | tr '\t' '\n' | grep -c "$CLUSTER" || true)
[ "$oidc" != "0" ] && { echo "RESIDUE: OIDC provider(s) referencing $CLUSTER remain"; fail=1; }
if [ "$fail" = "0" ]; then
  echo "CLEAN $(date -u +%FT%TZ) — no clusters, no stacks, no OIDC providers. Meter is off."
else
  echo "RESIDUE FOUND — clean up manually NOW; every listed item may be billing." >&2
  exit 1
fi
