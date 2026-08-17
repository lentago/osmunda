# Ingress — ingress-nginx

**Status: notes / not yet managed.** The plan, not an installed component.

## Choice

Use **ingress-nginx** as the single IngressClass (`nginx`) for the lab. It is
the class the app manifests already reference (`apps/n8n/ingress.yaml`). One
controller for a 2-node lab keeps the moving-part count low; no multi-class
routing is needed yet.

- k3s ships **Traefik** by default. Decide explicitly: either keep Traefik and
  retarget the app `ingressClassName`, or disable the bundled Traefik (k3s
  `--disable=traefik`, done at node-provision time in *kalmia*, **not here**)
  and run ingress-nginx via Flux. This scaffold assumes the latter so ingress
  is GitOps-managed like everything else.

## When it graduates from notes

Add to `infra/kustomization.yaml` as a Flux `HelmRelease`:

- `HelmRepository` → `https://kubernetes.github.io/ingress-nginx`
- `HelmRelease` `ingress-nginx`, pinned chart version, `controller.ingressClassResource.name: nginx`
- On EKS-ephemeral, front it with a Service `type: LoadBalancer` (NLB); on the
  k3s lab, expose via the nodes (host network or `externalIPs`).

## TLS

cert-manager (separate note when added) issues certs; the n8n Ingress gains
its `tls:` block and issuer annotation at cutover — omitted from the draft.
