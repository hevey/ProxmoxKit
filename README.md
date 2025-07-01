# ProxmoxKit v0.1

A modern Swift library for interacting with the Proxmox Virtual Environment API, featuring a service-oriented architecture for better organization and maintainability.

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
    .package(url: "https://github.com/your-repo/ProxmoxKit.git", from: "0.1.0")
]
```

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

// Create a backup
let taskId = try await client.cluster.createBackup(node: "pve-node1", storage: "local")
```

## Quick Start Example

Here's a complete example showing how to authenticate and retrieve all cluster resources:

### Basic Usage

```swift
import Foundation

func getClusterResources() async {
    do {
        // 1. Create the client
        let client = try ProxmoxClient.create(
            host: "192.168.1.100",     // Your Proxmox server IP
            port: 8006,                // Default Proxmox port
            useHTTPS: true,
            validateSSL: false         // false for self-signed certificates
        )
        
        // 2. Authenticate
        let ticket = try await client.authenticate(
            username: "root@pam",      // Your username@realm
            password: "yourpassword"   // Your password
        )
        
        print("✅ Authenticated as: \(ticket.username)")
        print("🔍 Session info: \(client.sessionDebugInfo)")
        
        // 3. Get cluster resources
        let nodes = try await client.nodes.list()
        let vms = try await client.vms.list()
        let containers = try await client.containers.list()
        
        print("📊 Cluster Summary:")
        print("   Nodes: \(nodes.count)")
        print("   VMs: \(vms.count)")
        print("   Containers: \(containers.count)")
        
        // 4. Get detailed information
        for node in nodes {
            print("\n🖥️  Node: \(node.node)")
            let nodeStatus = try await client.nodes.getStatus(node.node)
            if let cpu = nodeStatus.cpu {
                print("   CPU: \(String(format: "%.1f", cpu * 100))%")
            }
            
            // Get VMs on this node
            let nodeVMs = try await client.nodes.getVirtualMachines(node.node)
            print("   VMs: \(nodeVMs.count)")
        }
        
    } catch {
        print("❌ Error: \(error)")
    }
}
```

### Complete Example File

For a comprehensive example with error handling and detailed output, see `SimpleExample.swift` in the repository. To run it:

```bash
# Copy the SimpleExample.swift file to your project
# Update the configuration values at the top
# Run with:
swift run SimpleExample
```

### Configuration Options

```swift
// HTTPS with self-signed certificate (most common)
let client = try ProxmoxClient.create(
    host: "pve.example.com",
    port: 8006,
    useHTTPS: true,
    validateSSL: false  // Set to true for valid SSL certificates
)

// HTTP for development/testing
let client = try ProxmoxClient.create(
    host: "192.168.1.100",
    port: 8080,
    useHTTPS: false,
    validateSSL: false
)

// Advanced configuration
let config = ProxmoxConfig(
    baseURL: URL(string: "https://pve.example.com:8006")!,
    timeout: 30,
    retryCount: 5,
    validateSSL: false
)
let client = ProxmoxClient(config: config)
```

### Authentication

ProxmoxKit supports all Proxmox authentication realms:

```swift
// PAM authentication (Linux system users)
let ticket = try await client.authenticate(username: "root@pam", password: "password")

// Proxmox VE authentication
let ticket = try await client.authenticate(username: "admin@pve", password: "password")

// LDAP/Active Directory (if configured)
let ticket = try await client.authenticate(username: "user@ldap", password: "password")
```

### Error Handling

```swift
do {
    let ticket = try await client.authenticate(username: "root@pam", password: "password")
    // Success - proceed with operations
} catch ProxmoxError.authenticationFailed(let reason) {
    print("Authentication failed: \(reason)")
    // Check credentials and permissions
} catch ProxmoxError.networkError(let error) {
    print("Network error: \(error)")
    // Check connectivity and firewall
} catch ProxmoxError.apiError(let code, let message) {
    print("API error \(code): \(message)")
    // Check Proxmox API documentation
} catch {
    print("Unexpected error: \(error)")
}
```

## Architecture

### Core Components

- **ProxmoxClient**: Main client class that provides access to all services
- **ProxmoxConfig**: Configuration object for client setup
- **ProxmoxSession**: Manages authentication and session state
- **HTTPClient**: Handles HTTP requests with cookie management

### Services

- **NodeService**: Node management and monitoring
- **VMService**: Virtual machine operations
- **ContainerService**: LXC container management  
- **ClusterService**: Cluster-wide operations and monitoring

### Models

- **VirtualMachine**: VM representation with status and configuration
- **Container**: LXC container representation
- **Node**: Physical/virtual node in the cluster
- **ProxmoxResource**: Generic cluster resource

### Error Handling

ProxmoxKit provides comprehensive error handling through the `ProxmoxError` enum:

```swift
do {
    try await client.vms.start(node: "pve-node1", vmid: 100)
} catch ProxmoxError.authenticationFailed(let reason) {
    print("Authentication failed: \(reason)")
} catch ProxmoxError.resourceNotFound(let resource) {
    print("Resource not found: \(resource)")
} catch ProxmoxError.apiError(let code, let message) {
    print("API Error \(code): \(message)")
}
```

## Advanced Configuration

```swift
let config = ProxmoxConfig(
    baseURL: URL(string: "https://pve.example.com:8006")!,
    timeout: 60,
    retryCount: 5,
    validateSSL: false  // For self-signed certificates
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
