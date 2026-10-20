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
├── apps/<app>/
│   ├── base/                       Deployment, Service, Ingress, migration Job, VPA
│   └── envs/{uat,staging,prod}/    image digests, hashed config, sealed secrets, host, HPA/PDB
└── infra/                          namespaces, external services, security, alerts, monitoring
```

## Who changes what

| Path | Changed by |
|---|---|
| `apps/*/envs/uat`, `envs/staging` → `images:` digests | CI bot (deploy key), after a merge to `develop` / `staging` |
| `apps/*/envs/prod` → `images:` digests | CI bot, **only after approval** in the app repo's `production` GitHub Environment (D18) |
| everything else | Platform team, through a reviewed PR (CODEOWNERS) |

## How a deploy runs inside the cluster (plan 6.4)

wave −2 SealedSecret → wave −1 migration Job (must succeed) → wave 0 rolling update.
UAT and staging sync automatically; production waits for a person to press **SYNC**.

## Render or roll back

```bash
kubectl kustomize apps/rssb-pilot-backend/envs/prod     # see exactly what production runs
git revert <commit that changed a digest>                # rollback (through a PR)
```

## Instant sync (GitHub webhook)

Argo CD polls Git every ~3 minutes. A GitHub webhook on this repo (push events,
signed with `webhook.github.secret`) makes it refresh immediately. GitHub cannot
reach the lab's Argo CD, so `infra-automation/webhook-relay.sh` relays the
webhook through smee.io to `https://localhost:8443/api/webhook`. In RSSB: an
internal relay or a firewall path to Argo CD (plan story 3.7).
