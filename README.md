# ProxmoxKit

A modern Swift library for interacting with the Proxmox Virtual Environment API

> **⚠️ DEVELOPMENT VERSION**  
> This library is currently in active development and has not yet reached a stable release. APIs may change without notice. For production use, we recommend pinning to a specific commit hash rather than using the main branch.



## Features

- **Service-Oriented Architecture**: Organized into logical services (Nodes, VMs, Containers, Cluster)
- **Type Safety**: Strong typing for all API responses and requests
- **Async/Await Support**: Modern Swift concurrency
- **Comprehensive Error Handling**: Custom error types with detailed information
- **Builder Patterns**: Easy configuration building for VMs and containers
- **Thread Safety**: Concurrent access support

## Installation

Add ProxmoxKit to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/hevey/ProxmoxKit.git", branch: "main")
]
```

Or add it via Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/hevey/ProxmoxKit.git`
3. Select "Branch" and enter `main`

> **Note**: This package is currently in development. We recommend pinning to a specific commit for production use:
> ```swift
> .package(url: "https://github.com/hevey/ProxmoxKit.git", revision: "your-commit-hash")
> ```

## Quick Start

### Basic Setup

```swift
import ProxmoxKit

// Create a client (HTTPS by default)
let client = try ProxmoxClient.create(host: "192.168.1.100")

// Authenticate
let ticket = try await client.authenticate(username: "root@pam", password: "password")
print("Authenticated successfully!")
```

### HTTP vs HTTPS Configuration

```swift
// HTTPS with SSL validation (production)
let httpsClient = try ProxmoxClient.create(
    host: "pve.example.com",
    useHTTPS: true,
    validateSSL: true
)

// HTTPS with self-signed certificates (common setup)
let selfSignedClient = try ProxmoxClient.create(
    host: "192.168.1.100",
    useHTTPS: true,
    validateSSL: false  // Bypasses SSL certificate validation
)

// HTTP for development/testing (not recommended for production)
let httpClient = try ProxmoxClient.create(
    host: "192.168.1.100",
    port: 8080,
    useHTTPS: false
)
```

### Working with Nodes

```swift
// List all nodes
let nodes = try await client.nodes.list()

// Get node details
let nodeStatus = try await client.nodes.getStatus("pve-node1")
print("CPU usage: \(nodeStatus.cpu ?? 0)%")
```

### Virtual Machine Operations

```swift
// List all VMs
let vms = try await client.vms.list()

// Start a VM
try await client.vms.start(node: "pve-node1", vmid: 100)

// Create a new VM using builder pattern
let vmConfig = buildVMConfig()
    .name("test-vm")
    .memory(2048)
    .cores(2)
    .addNetwork(interface: "net0", configuration: "virtio,bridge=vmbr0")
    .build()

let newVM = try await client.vms.create(node: "pve-node1", vmid: 999, config: vmConfig)
```

### Container Operations

```swift
// List containers
let containers = try await client.containers.list()

// Create a container
let containerConfig = ContainerConfig(
    hostname: "test-container",
    memory: 1024,
    cores: 1,
    rootfs: "local:8",
    ostemplate: "local:vztmpl/ubuntu-20.04-standard_20.04-1_amd64.tar.gz"
)

let container = try await client.containers.create(node: "pve-node1", vmid: 200, config: containerConfig)
```

### Cluster Operations

```swift
// Get cluster resources
let resources = try await client.cluster.getResources()

// Get cluster status
let status = try await client.cluster.getStatus()
```

## Complete Example

For a comprehensive example, see `SimpleExample.swift` in the repository.

## Error Handling

```swift
do {
    let ticket = try await client.authenticate(username: "root@pam", password: "password")
} catch ProxmoxError.authenticationFailed(let reason) {
    print("Authentication failed: \(reason)")
} catch ProxmoxError.networkError(let error) {
    print("Network error: \(error)")
} catch ProxmoxError.apiError(let code, let message) {
    print("API error \(code): \(message)")
}
```

## Architecture

### Core Components

- **ProxmoxClient**: Main client class that provides access to all services
- **ProxmoxConfig**: Configuration object for client setup
- **ProxmoxSession**: Manages authentication and session state

### Services

- **NodeService**: Node management and monitoring
- **VMService**: Virtual machine operations
- **ContainerService**: LXC container management  
- **ClusterService**: Cluster-wide operations and monitoring

## Configuration

```swift
// Advanced configuration
let config = ProxmoxConfig(
    baseURL: URL(string: "https://pve.example.com:8006")!,
    timeout: 60,
    retryCount: 5,
    validateSSL: false
)
let client = ProxmoxClient(config: config)
```

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.5+
- Xcode 13.0+

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
