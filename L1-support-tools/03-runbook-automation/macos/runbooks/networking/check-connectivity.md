# Check Network Connectivity

Diagnose network connectivity issues.

## Check Interface Status

```bash
ifconfig | grep -E "(en0|en1|utun)" -A 3
```

## Test Basic Connectivity

```bash
ping -c 4 8.8.8.8
```

## Test DNS Resolution

```bash
nslookup google.com
```

## Check Routing Table

```bash
netstat -nr | head -20
```

## Check Wi-Fi Connection

```bash
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I
```
