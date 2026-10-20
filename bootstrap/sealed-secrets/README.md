# Sealed Secrets

`sealing-cert.pem` is the controller's **public** certificate. It can only
encrypt, never decrypt, so it is safe in Git. Seal offline with:

```bash
kubectl create secret generic NAME -n NAMESPACE --dry-run=client -o yaml \
  --from-literal=KEY=VALUE | kubeseal --cert bootstrap/sealed-secrets/sealing-cert.pem --format yaml
```

The **private** key never goes in Git. It is backed up outside the repo
(`~/.rssb-backup/sealed-secrets-key.yaml` in the lab; RSSB's 3-2-1-1-0 backups /
Ansible Vault in production, plan D25) and restored by `bootstrap.sh` **before**
the controller starts on a rebuilt cluster.
