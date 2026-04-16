# Restart Homebrew Services

Restart Homebrew services safely.

## Pre-check

Verify services are managed by Homebrew:

```bash
brew services list
```

## Restart All Services

```bash
brew services restart --all
```

## Verify Restart

Check service status:

```bash
brew services list | grep "started"
```

## Clear Service Logs

```bash
rm -rf ~/Library/Logs/Homebrew/*
```
