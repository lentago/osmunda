# apps/n8n — first migrated workload (pre-cutover draft)

n8n is the first workload moving off the LXC estate (currently **LXC 113**) onto
the platform. These manifests are a **draft**: they describe the target shape but
are not yet serving production traffic. Cutover is gated by
[`runbooks/`](../../runbooks/) and the migration ADRs.

## What's here

| File | Purpose |
|---|---|
| `namespace.yaml` | `n8n` namespace |
| `pvc.yaml` | 5Gi `ReadWriteOnce` PVC for n8n runtime state (default storage class) |
| `deployment.yaml` | Single replica, `Recreate` strategy, digest-pinned image, port 5678 |
| `service.yaml` | ClusterIP `:80 → :5678` |
| `ingress.yaml` | `nginx` IngressClass, host `n8n.lab.lentago.dev` |
| `kustomization.yaml` | Bundles the above for Flux/kustomize |

## Draft → cutover checklist (not done here)

- [ ] Move the workflow DB from SQLite-on-PVC to Postgres (`DB_*` env via ConfigMap/Secret).
- [ ] Supply `N8N_ENCRYPTION_KEY`, `N8N_HOST`, and `WEBHOOK_URL` (Secret).
- [ ] Wire TLS via cert-manager and confirm the real hostname.
- [ ] Import existing workflows/credentials from LXC 113 and verify.
- [ ] Cut DNS over only after a dry run; keep LXC 113 as rollback.

## Image pinning

`docker.n8n.io/n8nio/n8n@sha256:31375a4f730081a139bba2d379bf2efaa8e662cc9e131d12bb5e15859d4f0282`
(tag `2.35.3`). The digest is authoritative; the tag comment is a human hint.
Bump both together. `docker.n8n.io` is n8n's registry (a Docker Hub mirror), so
the digest is identical to `docker.io/n8nio/n8n`.
