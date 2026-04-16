# Reset Password

Example runbook for password reset workflows.

## Check User Exists

```bash
id username
```

## Reset Password

```bash
sudo passwd username
```

## Verify Password Change

```bash
su - username -c "whoami"
```
