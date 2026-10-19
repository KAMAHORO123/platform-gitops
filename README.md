# rssb-config

The **config repository** of the RSSB platform simulation: Git is the single source
of truth for what runs in the cluster, and Argo CD keeps the cluster equal to it.

| Path | What | Who changes it |
|---|---|---|
| `charts/generic-app/` | One Helm chart reused by every NestJS / Next.js app | Platform team (reviewed) |
| `apps/<app>/values.yaml` | App settings shared by all environments | Platform team (reviewed) |
| `apps/<app>/values-uat.yaml` | UAT settings; `image.tag` written by CI on merge to `develop` | CI bot / platform team |
| `apps/<app>/values-staging.yaml` | Staging settings; `image.tag` written by CI on merge to `qa` | CI bot / platform team |
| `apps/<app>/values-prod.yaml` | Production settings; changed only through a reviewed PR | Reviewed PR only |
| `cluster/` | Namespaces, external services, quotas, network policies, RBAC | Platform team (reviewed) |
| `argocd/` | Argo CD projects and ApplicationSets | Platform team (reviewed) |
| `sealed-secrets/` | Encrypted secrets (safe to commit) | Platform team (reviewed) |

## Render an app locally

```bash
helm template rssb-pilot-backend charts/generic-app -n uat \
  -f apps/rssb-pilot-backend/values.yaml -f apps/rssb-pilot-backend/values-uat.yaml
```

## Roll back

`git revert` the commit that changed the image tag. Argo CD restores the previous version.
