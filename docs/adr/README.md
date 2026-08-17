# Architecture decision records

The Nygard-style records below document platform decisions for osmunda — one
decision per record, numbered. Dates reflect when the decision was made.

## Index

| ADR | Title | Status | Date |
|---|---|---|---|
| [0001](0001-k3s-lab-plus-ephemeral-eks.md) | k3s on the lab, EKS only when ephemeral | Accepted | 2026-08-17 |
| [0002](0002-flux-over-argocd.md) | Flux for GitOps reconciliation (over Argo CD) | Accepted | 2026-08-17 |

---

## How to add an ADR to this repo

Create `docs/adr/NNNN-<short-slug>.md` and add a row to the index above. Use this structure:

```markdown
# ADR-NNNN: <Title>

**Status:** Accepted (<date>)

## Context

Why was a decision needed? What constraints and forces were in play?

## Decision

What was decided, and how does it address the context?

## Alternatives

List the options that were actually weighed, then add one or two marked
*"retrospective — not considered at the time"* with an honest assessment
(worse / better / lateral) and a short reason.

## Consequences

What does this decision make easier or harder going forward? What are the
known trade-offs or scars?
```

**Recorded vs. retrospective alternatives:** Alternatives that were actually weighed at decision
time go in the list without special marking. Options added later for completeness must be
explicitly labelled *"retrospective — not considered at the time"* so future readers know they
were not part of the original deliberation. Honest assessment (worse / better / lateral) is
required — do not present retrospective options as neutral.
