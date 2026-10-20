# platform-gitops

The **GitOps repository** of the RSSB platform simulation (plan v3.2 §5.4). Git is the
single source of truth for what runs in the cluster; Argo CD keeps the cluster equal to it.
One branch (`main`), **one folder per environment**.

```
platform-gitops/
├── bootstrap/                      applied once, by hand, in order
│   ├── bootstrap.sh                Argo CD + Sealed Secrets (pinned), settings, root app
│   ├── argocd/                     Argo CD settings patches + root-app.yaml
│   ├── sealed-secrets/             public sealing certificate (safe to commit)
│   └── argo-config/                AppProject, ApplicationSet, platform apps, add-ons
├── charts/rssb-app/               ONE shared Helm chart for every app: Deployment, Service,
│                                   Ingress, ConfigMap, migration Job, SealedSecret, HPA, PDB, VPA
├── apps/<app>/
│   ├── values.yaml                 what all environments of the app share (ports, probes, ...)
│   └── envs/{uat,staging,prod}/
│       └── values.yaml             image digests, host, config, sealed secrets, HPA/PDB on/off
└── infra/                          namespaces, external services, security, alerts, monitoring
```

## Who changes what

| Path | Changed by |
|---|---|
| `apps/*/envs/uat`, `envs/staging` → `images:` digests in `values.yaml` | CI bot (deploy key), after a merge to `develop` / `staging` |
| `apps/*/envs/prod` → `images:` digests in `values.yaml` | CI bot, **only after approval** in the app repo's `production` GitHub Environment (D18) |
| everything else | Platform team, through a reviewed PR (CODEOWNERS) |

## Helm: how an app is rendered

Argo CD renders each `apps/<app>/envs/<env>` folder with the chart, layering
three values files (later wins): `charts/rssb-app/values.yaml` (defaults, every
option documented) → `apps/<app>/values.yaml` → `apps/<app>/envs/<env>/values.yaml`.
The Helm release name is the app folder name, which is also the object name.

Decision: the plan (v3.2, D9) chose Kustomize; this lab uses **Helm** instead
(one chart, all apps), so a new app is a values file instead of a copy of YAML.
CI still only edits the `images:` digest lines, so the delivery flow is unchanged.

## How a deploy runs inside the cluster (plan 6.4)

wave −2 SealedSecret → wave −1 migration Job (must succeed) → wave 0 rolling update.
UAT and staging sync automatically; production waits for a person to press **SYNC**.

## Render or roll back

```bash
helm template rssb-pilot-backend charts/rssb-app -n production \
  -f apps/rssb-pilot-backend/values.yaml -f apps/rssb-pilot-backend/envs/prod/values.yaml   # what production runs
git revert <commit that changed a digest>                # rollback (through a PR)
```

## Instant sync (GitHub webhook)

Argo CD polls Git every ~3 minutes. A GitHub webhook on this repo (push events,
signed with `webhook.github.secret`) makes it refresh immediately. GitHub cannot
reach the lab's Argo CD, so `infra-automation/webhook-relay.sh` relays the
webhook through smee.io to `https://localhost:8443/api/webhook`. In RSSB: an
internal relay or a firewall path to Argo CD (plan story 3.7).
