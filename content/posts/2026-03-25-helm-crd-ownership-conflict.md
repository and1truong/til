---
date: '2026-03-25T00:00:00+10:00'
draft: false
title: 'Helm CRD Ownership Conflict Between Charts'
tags: ['helm', 'kubernetes']
---

When two Helm charts define the same CRD (e.g. `podlogs.monitoring.grafana.com` shipped by both Grafana Alloy and Grafana Tempo Distributed), the second release fails with a conflict error. Helm tracks resource ownership via `meta.helm.sh/release-name`, `meta.helm.sh/release-namespace` annotations and the `app.kubernetes.io/managed-by=Helm` label. Once one release owns a CRD, another release cannot create or adopt it.

## Resolution Options

### 1. Skip CRD creation on the conflicting chart (safest)

In the Helm values of the chart that does **not** need to own the CRD:

```yaml
crds:
  create: false
```

The chart still uses the CRD — it just won't try to install or manage it.

The exact values key varies by chart. Check with `helm show values <repo>/<chart> | grep -A5 crd`. Common variants: `crds.create`, `installCRDs`, `crd.enabled`.

### 2. Transfer CRD ownership to a different release

```bash
kubectl annotate crd <crd-name> \
  meta.helm.sh/release-name=<new-owner-release> \
  meta.helm.sh/release-namespace=<new-owner-namespace> \
  --overwrite

kubectl label crd <crd-name> \
  app.kubernetes.io/managed-by=Helm \
  --overwrite
```

Then disable CRD creation on the old owner chart.

### 3. Remove Helm ownership entirely (manage out-of-band)

```bash
kubectl annotate crd <crd-name> \
  meta.helm.sh/release-name- \
  meta.helm.sh/release-namespace-

kubectl label crd <crd-name> \
  app.kubernetes.io/managed-by-
```

Then set `crds.create: false` on both charts and manage the CRD separately (e.g. `kubectl apply`, dedicated CRDs chart, or raw Kustomize resource).

## Applying via Kustomize (Flux)

Patch the HelmRelease values using a Kustomize strategic merge patch:

```yaml
# kustomization.yaml
patches:
  - target:
      kind: HelmRelease
      name: alloy
    patch: |
      apiVersion: helm.toolkit.fluxcd.io/v2
      kind: HelmRelease
      metadata:
        name: alloy
      spec:
        values:
          crds:
            create: false
```

## Key Takeaway

When multiple Helm charts ship the same CRD, pick one chart to own it and disable CRD creation on all others. Prefer disabling on the newer/less-stable release so the already-running release keeps ownership undisturbed.
