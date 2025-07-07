# Configuration

Configure ProxmoxKit for your Proxmox VE environment.

## Overview

ProxmoxKit uses ``ProxmoxConfig`` to store connection settings and authentication credentials. Proper configuration is essential for establishing a secure connection to your Proxmox VE server.

## Basic Configuration

Create a configuration with the minimum required settings:

```swift
import ProxmoxKit

let config = ProxmoxConfig(
    host: "https://your-proxmox-server.com:8006",
    username: "root@pam",
    password: "your-password"
)
```

## Configuration Parameters

### Required Parameters

- **host**: The full URL to your Proxmox VE server including port (typically 8006)
- **username**: Username with realm (e.g., `root@pam`, `admin@pve`)
- **password**: User password

### URL Format

The host URL should include:
- Protocol: `https://` (recommended) or `http://`
- Hostname or IP address
- Port: `:8006` (default Proxmox web interface port)

Examples:
```swift
// Using hostname
let config1 = ProxmoxConfig(
    host: "https://proxmox.example.com:8006",
    username: "admin@pve",
    password: "password"
)

// Using IP address
let config2 = ProxmoxConfig(
    host: "https://192.168.1.100:8006",
    username: "root@pam",
    password: "password"
)

// Custom port
let config3 = ProxmoxConfig(
    host: "https://proxmox.example.com:8007",
    username: "user@ldap",
    password: "password"
)
```

## Security Considerations

### HTTPS Usage
Always use HTTPS in production environments:

```swift
// ✅ Secure (recommended)
let secureConfig = ProxmoxConfig(
    host: "https://proxmox.example.com:8006",
    username: "admin@pve",
    password: "password"
)

// ❌ Insecure (avoid in production)
let insecureConfig = ProxmoxConfig(
    host: "http://proxmox.example.com:8006",
    username: "admin@pve", 
    password: "password"
)
```

### Credential Storage
Consider using secure storage for credentials:

```swift
import Security

// Store in Keychain (recommended for production apps)
func getPasswordFromKeychain(account: String) -> String? {
    // Keychain implementation
    return storedPassword
}

let config = ProxmoxConfig(
    host: "https://proxmox.example.com:8006",
    username: "admin@pve",
    password: getPasswordFromKeychain(account: "proxmox") ?? ""
)
```

## Environment-Specific Configuration

### Development
```swift
let devConfig = ProxmoxConfig(
    host: "https://dev-proxmox.internal:8006",
    username: "dev@pam",
    password: "dev-password"
)
```

### Production
```swift
let prodConfig = ProxmoxConfig(
    host: "https://proxmox.company.com:8006",
    username: "automation@pve",
    password: getSecurePassword()
)
```

## Configuration Validation

The configuration is validated when creating the ``ProxmoxClient``:

```swift
do {
    let client = ProxmoxClient(config: config)
    try await client.authenticate()
} catch ProxmoxError.invalidConfiguration(let message) {
    print("Configuration error: \(message)")
} catch {
    print("Other error: \(error)")
}
```

## Best Practices

1. **Use HTTPS**: Always use encrypted connections in production
2. **Secure Credentials**: Store passwords securely, not in source code
3. **Validate URLs**: Ensure the host URL is properly formatted
4. **Test Configuration**: Verify configuration works before deployment
5. **Use Specific Users**: Create dedicated API users instead of using root when possible
