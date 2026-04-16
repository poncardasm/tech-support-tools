# Reset VPN Connection

Reset VPN connection on macOS.

## Check Current Connection

```bash
scutil --nc list
```

## Disconnect All VPNs

```bash
scutil --nc show "*" 2>/dev/null | grep -E "(VPN|IPSec)" || echo "No active VPNs"
```

## Restart Network Services

```bash
sudo launchctl unload /System/Library/LaunchDaemons/com.apple.configd.plist
sudo launchctl load /System/Library/LaunchDaemons/com.apple.configd.plist
```

## Flush DNS

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

## Reconnect VPN

```bash
echo "Please reconnect to your VPN manually through System Settings"
```
