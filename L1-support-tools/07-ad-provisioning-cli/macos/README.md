# AD/User Provisioning CLI (macOS)

A single-command tool for L1 support to provision Azure AD/EntraID user accounts, group memberships, and mailboxes without touching the slow Admin Center UI.

## Overview

`ad-provision` replaces 10 clicks with one command. L1 gets clean confirmation output; no accidental misclicks. Errors are loud and clear.

## Installation

### Homebrew (Recommended)

```bash
brew tap your-org/tools
brew install ad-provision
```

### From Source

```bash
git clone https://github.com/your-org/ad-provisioning-cli.git
cd ad-provisioning-cli/macos
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
```

## Configuration

### Azure AD App Registration

1. Create an App Registration in Azure AD/EntraID
2. Grant the following Microsoft Graph API permissions:
   - `User.ReadWrite.All` - Create and manage users
   - `Group.ReadWrite.All` - Manage group memberships
   - `Organization.Read.All` - Read organization info
3. Create a client secret or upload a certificate for authentication
4. Note your **Application (client) ID** and **Directory (tenant) ID**

### Certificate Setup (Recommended for Production)

1. Generate a certificate:
   ```bash
   openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
   ```

2. Upload the public certificate (`cert.pem`) to your Azure AD App Registration

3. Note the certificate thumbprint

### Local Configuration

Create the config directory and credentials file:

```bash
mkdir -p ~/.config/ad-provision
cp config/creds.env.example ~/.config/ad-provision/creds.env
```

Edit `~/.config/ad-provision/creds.env`:

```env
# Azure AD App Registration credentials
AZURE_CLIENT_ID=your-app-client-id
AZURE_TENANT_ID=your-tenant-id

# Option 1: Certificate-based auth (recommended)
AZURE_CERTIFICATE_PATH=~/.config/ad-provision/certificate.pem

# Option 2: Client secret auth (for development)
# AZURE_CLIENT_SECRET=your-client-secret
```

## Usage

### Create a New User

```bash
ad-provision new-user \
  --username alice \
  --name "Alice Smith" \
  --email alice@company.com \
  --department IT \
  --group "IT-All" \
  --group "Engineering" \
  --enable-mailbox
```

Output:
```
[OK]   User alice@company.com created
[TEMP] Initial password: Xy#9aBc!dEf$ — force change required
[OK]   Added to group: IT-All
[OK]   Added to group: Engineering
[OK]   Exchange Online mailbox enabled
```

### Add User to Group

```bash
ad-provision add-group --username alice --group "Project-Team"
```

### Enable Mailbox

```bash
ad-provision enable-mailbox --username alice
```

### Reset Password

```bash
ad-provision reset-password --username alice
```

Output:
```
[OK]   Password reset for alice
[TEMP] New password: Ab#3xYz$9qR — force change required
```

### Deprovision User

```bash
ad-provision deprovision --username alice --reason "terminated"
```

Output:
```
[OK]   Account disabled
[OK]   Removed from all groups
[OK]   Sessions revoked
[WARN] Deprovision reason: terminated
```

## Dry-Run Mode

Every command supports `--dry-run` to preview changes:

```bash
ad-provision new-user \
  --username bob \
  --name "Bob Jones" \
  --email bob@company.com \
  --department Sales \
  --dry-run
```

Output:
```
[DRY]  Would create user bob@company.com
[DRY]  Display name: Bob Jones
[DRY]  Department: Sales
```

## Output Prefixes

| Prefix | Meaning |
|--------|---------|
| `[OK]`   | Operation successful |
| `[FAIL]` | Operation failed (exits with code 1) |
| `[TEMP]` | Temporary value (e.g., password) |
| `[WARN]` | Warning or notice |
| `[DRY]`  | Dry-run preview |

## Development

### Running Tests

```bash
cd macos
source .venv/bin/activate
pytest tests/ -v
```

### Project Structure

```
macos/
├── ad_provision/          # Main package
│   ├── __init__.py        # Version info
│   ├── __main__.py        # CLI entry point
│   ├── commands.py        # Click CLI commands
│   ├── config.py          # Configuration loading
│   ├── graph_client.py    # Microsoft Graph API client
│   └── output.py          # Output formatting
├── tests/                 # Test suite
│   ├── test_commands.py   # CLI command tests
│   ├── test_config.py     # Config validation tests
│   ├── test_graph_client.py  # Graph client tests
│   └── test_output.py     # Output formatting tests
├── config/                # Configuration templates
│   └── creds.env.example  # Example credentials file
├── Formula/               # Homebrew formula
│   └── ad-provision.rb
├── pyproject.toml         # Package configuration
└── README.md              # This file
```

## macOS-Specific Notes

### Keychain Integration

For enhanced security, you can store your certificate in the macOS Keychain:

```bash
# Import certificate to Keychain
security import cert.pem -k ~/Library/Keychains/login.keychain-db

# Export from Keychain when needed
security find-certificate -c "Your Cert Name" -p > ~/.config/ad-provision/cert.pem
```

### Certificate Path

Always use absolute paths or `~` expansion in your config file. The tool automatically expands `~` to your home directory.

## Error Handling

- Missing config file → `FileNotFoundError` with clear path
- Invalid credentials → `ValueError` with specific field
- API errors → Printed to stderr with `[FAIL]` prefix, exit code 1

## Security Considerations

1. **Never commit credentials** to version control
2. **Use certificate-based auth** in production
3. **Set restrictive permissions** on config files:
   ```bash
   chmod 600 ~/.config/ad-provision/creds.env
   chmod 600 ~/.config/ad-provision/certificate.pem
   ```
4. **Enable password change on first login** for all new users
5. **Use --dry-run** to verify commands before executing

## Troubleshooting

### "Config not found" error

```bash
# Verify config file exists
ls -la ~/.config/ad-provision/creds.env

# If missing, copy from example
cp config/creds.env.example ~/.config/ad-provision/creds.env
```

### Permission denied on certificate

```bash
chmod 600 ~/.config/ad-provision/certificate.pem
```

### Azure AD authentication errors

1. Verify your App Registration has the required API permissions
2. Check that permissions have been **granted admin consent**
3. Ensure your client secret hasn't expired (if using secret auth)
4. Verify certificate hasn't expired (if using cert auth)

## License

MIT

## See Also

- [Microsoft Graph API Documentation](https://docs.microsoft.com/en-us/graph/api/overview)
- [Azure AD App Registration Guide](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [Microsoft Graph SDK for Python](https://github.com/microsoftgraph/msgraph-sdk-python)
