# Authentication

Learn how to authenticate with your Proxmox VE server.

## Overview

ProxmoxKit uses ticket-based authentication with the Proxmox VE API. The authentication process is handled automatically when you create a ``ProxmoxClient`` and call the `authenticate()` method.

## Basic Authentication

The simplest way to authenticate is with username and password:

```swift
import ProxmoxKit

let config = ProxmoxConfig(
    host: "https://your-proxmox-server.com:8006",
    username: "root@pam",
    password: "your-password"
)

let client = ProxmoxClient(config: config)
try await client.authenticate()
```

## Authentication Realms

Proxmox supports different authentication realms:

- `@pam` - Local Unix users
- `@pve` - Proxmox VE users
- `@ldap` - LDAP/Active Directory users (if configured)

```swift
// PAM authentication (local Unix users)
let config = ProxmoxConfig(
    host: "https://your-server.com:8006",
    username: "root@pam",
    password: "password"
)

// PVE authentication (Proxmox users)
let config2 = ProxmoxConfig(
    host: "https://your-server.com:8006",
    username: "admin@pve",
    password: "password"
)
```

## CSRF Token Handling

ProxmoxKit automatically handles CSRF tokens for write operations. The authentication ticket includes a CSRF prevention token that is automatically attached to POST/PUT requests.

## Session Management

Once authenticated, the session is maintained automatically. The ``Ticket`` includes:

- Authentication ticket string
- CSRF prevention token
- Username information
- Cluster name (if available)

## Error Handling

Authentication failures throw ``ProxmoxError`` with specific error types:

```swift
do {
    try await client.authenticate()
} catch ProxmoxError.authenticationFailed(let reason) {
    print("Authentication failed: \(reason)")
} catch ProxmoxError.networkError(let error) {
    print("Network error: \(error)")
}
```

## Important Notes

- Always use HTTPS in production environments
- Store credentials securely (consider using Keychain)
- The authentication ticket has an expiration time
- Re-authentication is handled automatically when needed
