# Clear System Logs

Clear common macOS log files to free up disk space.

## Check Log Sizes

First, check how much space logs are using:

```bash
du -sh /var/log/* 2>/dev/null | sort -hr | head -10
du -sh ~/Library/Logs/* 2>/dev/null | sort -hr | head -10
```

## Clear System Logs (requires sudo)

```bash
sudo rm -rf /var/log/*.log.*
sudo rm -rf /var/log/asl/*.asl
```

## Clear User Logs

```bash
rm -rf ~/Library/Logs/*
```

## Clear Application Logs

```bash
rm -rf ~/Library/Containers/*/Data/Library/Logs/*
```

## Flush DNS Cache

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

## Verify Space Freed

```bash
df -h /
```
