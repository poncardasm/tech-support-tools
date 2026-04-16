# Log Parse Test Fixtures

## Sample Syslog

```
Jan 15 10:30:45 server1 sshd[1234]: Authentication failure for user admin from 192.168.1.100
Jan 15 10:31:02 server1 sshd[1235]: Accepted publickey for user bob from 192.168.1.101
Jan 15 10:32:15 server1 kernel: [UFW BLOCK] IN=eth0 OUT= MAC=... SRC=10.0.0.50
Jan 15 10:33:22 server1 postgres[2345]: ERROR: connection refused to db:5432
Jan 15 10:33:45 server1 postgres[2346]: ERROR: connection refused to db:5432
Jan 15 10:34:01 server1 postgres[2347]: ERROR: disk space threshold exceeded on /dev/sda1
Jan 15 10:35:12 server1 app[3456]: WARN: Session token expired (idle timeout)
Jan 15 10:35:15 server1 app[3457]: WARN: Session token expired (idle timeout)
Jan 15 10:35:18 server1 app[3458]: WARN: Retry attempt for external API call
Jan 15 10:36:00 server1 nginx: 192.168.1.102 - - [15/Jan/2024:10:36:00 +0000] "GET /api/health HTTP/1.1" 200 23
```

## Sample JSON Lines

```json
{"timestamp": "2024-01-15T10:30:45Z", "level": "ERROR", "source": "database", "message": "Connection refused to db:5432"}
{"timestamp": "2024-01-15T10:31:00Z", "level": "WARN", "source": "cache", "message": "Cache miss for key user:1234"}
{"timestamp": "2024-01-15T10:32:15Z", "level": "INFO", "source": "api", "message": "Request processed in 23ms"}
```

## Sample Docker Logs

```json
{"log": "Starting application server...\n", "stream": "stdout", "time": "2024-01-15T10:30:00.123456789Z"}
{"log": "Error connecting to database: connection refused\n", "stream": "stderr", "time": "2024-01-15T10:30:05.234567890Z"}
{"log": "Retrying connection (attempt 1/3)...\n", "stream": "stdout", "time": "2024-01-15T10:30:06.345678901Z"}
```
