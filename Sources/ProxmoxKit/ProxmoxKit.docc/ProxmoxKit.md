# ``ProxmoxKit``

A modern Swift library for interacting with the Proxmox Virtual Environment API.

## Overview

ProxmoxKit provides a comprehensive, type-safe Swift interface for managing Proxmox VE clusters, nodes, virtual machines, and containers. Built with modern Swift concurrency (async/await) and following Swift best practices.

## Topics

### Getting Started

- <doc:Authentication>
- <doc:Configuration>

### Core Services

- ``ProxmoxClient``
- ``NodeService``
- ``VMService``
- ``ContainerService``
- ``ClusterService``

### Authentication & Configuration

- ``ProxmoxConfig``
- ``ProxmoxSession``
- ``Ticket``

### Models

- ``Node``
- ``VirtualMachine``
- ``Container``
- ``ClusterStatus``

### Error Handling

- ``ProxmoxError``

## Example Usage

```swift
import ProxmoxKit

// Configure the client
let config = ProxmoxConfig(
    host: "https://your-proxmox-server.com:8006",
    username: "root@pam",
    password: "your-password"
)

// Create and authenticate client
let client = ProxmoxClient(config: config)
try await client.authenticate()

// List all nodes
let nodes = try await client.nodeService.list()
print("Found \(nodes.count) nodes")

// Get VMs on a specific node
let vms = try await client.nodeService.getVirtualMachines("pve")
print("VMs: \(vms.map { $0.name })")

// Bulk operations
try await client.nodeService.stopAll("pve", timeout: 300)
```
