//
//  Usage Examples for ProxmoxKit
//  
//  This file demonstrates how to use the new service-oriented ProxmoxKit library.
//  These are examples only and not part of the actual library.
//

import Foundation

private func exampleUsage() async {
    do {
        // MARK: - Client Creation
        
        // Method 1: Simple creation with host (HTTPS by default)
        let client1 = try ProxmoxClient.create(host: "192.168.1.100")
        
        // Method 2: Custom configuration with HTTPS and self-signed cert
        let client2 = try ProxmoxClient.create(
            host: "pve.example.com",
            port: 8006,
            useHTTPS: true,
            timeout: 60,
            validateSSL: false  // For self-signed certificates
        )
        
        // Method 3: HTTP configuration (for testing/development)
        let client3 = try ProxmoxClient.create(
            host: "192.168.1.100",
            port: 8080,  // Custom port for HTTP
            useHTTPS: false,  // Use HTTP instead of HTTPS
            timeout: 30,
            validateSSL: false  // Not relevant for HTTP, but good practice
        )
        
        // Method 4: Full configuration object
        let config = ProxmoxConfig(
            baseURL: URL(string: "https://pve.example.com:8006")!,
            timeout: 30,
            retryCount: 5,
            validateSSL: true
        )
        let client4 = ProxmoxClient(config: config)
        
        // MARK: - Authentication
        
        let client = client1
        let ticket = try await client.authenticate(username: "root@pam", password: "yourpassword")
        print("Authenticated successfully!")
        print("Ticket: \(ticket.ticket ?? "nil")")
        print("Username: \(ticket.username)")
        print("CSRF Token: \(ticket.CSRFPreventionToken ?? "nil")")
        print("Session Debug: \(client.sessionDebugInfo)")
        
        // MARK: - Node Operations
        
        // List all nodes
        let nodes = try await client.nodes.list()
        print("Found \(nodes.count) nodes:")
        for node in nodes {
            print("  - \(node.node): \(node.status ?? "unknown")")
        }
        
        // Get detailed node information
        if let firstNode = nodes.first {
            let nodeDetails = try await client.nodes.get(firstNode.node)
            print("Node details: \(nodeDetails)")
            
            // Get node status
            let nodeStatus = try await client.nodes.getStatus(firstNode.node)
            print("CPU usage: \(nodeStatus.cpu ?? 0)%")
            if let memory = nodeStatus.memory {
                print("Memory: \(memory.used ?? 0)/\(memory.total ?? 0) bytes")
            }
            
            // Get VMs on this node
            let nodeVMs = try await client.nodes.getVirtualMachines(firstNode.node)
            print("VMs on \(firstNode.node): \(nodeVMs.count)")
        }
        
        // MARK: - Virtual Machine Operations
        
        // List all VMs in cluster
        let allVMs = try await client.vms.list()
        print("Total VMs in cluster: \(allVMs.count)")
        
        // List VMs on specific node
        if let nodeName = nodes.first?.node {
            let nodeVMs = try await client.vms.list(node: nodeName)
            print("VMs on \(nodeName): \(nodeVMs.count)")
            
            // Work with first VM if available
            if let vm = nodeVMs.first {
                print("Working with VM \(vm.id): \(vm.name ?? "unnamed")")
                
                // Get VM status
                let vmStatus = try await client.vms.getStatus(node: nodeName, vmid: vm.id)
                print("VM Status: \(vmStatus.status?.rawValue ?? "unknown")")
                
                // Start VM if stopped
                if vmStatus.status == .stopped {
                    try await client.vms.start(node: nodeName, vmid: vm.id)
                    print("Started VM \(vm.id)")
                }
                
                // Update VM configuration
                let updatedConfig = VMConfig(
                    name: "updated-name",
                    memory: 2048,
                    cores: 2,
                    description: "Updated via ProxmoxKit"
                )
                try await client.vms.update(node: nodeName, vmid: vm.id, config: updatedConfig)
                print("Updated VM configuration")
            }
        }
        
        // MARK: - Create a new VM using builder pattern
        
        if let nodeName = nodes.first?.node {
            let vmConfig = buildVMConfig()
                .name("test-vm-swift")
                .memory(1024)
                .cores(1)
                .cpu("host")
                .addNetwork(interface: "net0", configuration: "virtio,bridge=vmbr0")
                .addVirtIODisk(device: "virtio0", configuration: "local:32")
                .boot("order=virtio0")
                .description("Created with ProxmoxKit Swift")
                .startOnBoot(true)
                .tags("swift,test")
                .build()
            
            let newVM = try await client.vms.create(node: nodeName, vmid: 999, config: vmConfig)
            print("Created new VM: \(newVM.id)")
        }
        
        // MARK: - Cluster Operations
        
        // Get cluster resources
        let resources = try await client.cluster.getResources()
        print("Total cluster resources: \(resources.count)")
        
        // Get only VM resources
        let vmResources = try await client.cluster.getResources(type: "vm")
        print("VM resources: \(vmResources.count)")
        
        // Get cluster status
        let clusterStatus = try await client.cluster.getStatus()
        print("Cluster status: \(clusterStatus)")
        
        // Get all VMs via cluster service
        let clusterVMs = try await client.cluster.getVirtualMachines()
        print("Cluster VMs: \(clusterVMs.count)")
        
        // MARK: - Error Handling Examples
        
        // Handle specific errors
        do {
            try await client.vms.get(node: "nonexistent", vmid: 999)
        } catch ProxmoxError.resourceNotFound(let message) {
            print("Resource not found: \(message)")
        } catch ProxmoxError.authenticationFailed(let reason) {
            print("Auth failed: \(reason)")
        } catch ProxmoxError.apiError(let code, let message) {
            print("API Error \(code): \(message)")
        }
        
        // MARK: - Logout
        
        client.logout()
        print("Logged out successfully")
        
    } catch {
        print("Error: \(error)")
        if let proxmoxError = error as? ProxmoxError {
            print("Proxmox Error: \(proxmoxError.localizedDescription)")
        }
    }
}

// MARK: - Helper Functions for Advanced Usage

private func advancedExamples() async {
    // Example: Mass VM operations
    func stopAllVMs(client: ProxmoxClient, node: String) async throws {
        let vms = try await client.vms.list(node: node)
        let runningVMs = vms.filter { $0.status == .running }
        
        print("Stopping \(runningVMs.count) running VMs...")
        
        // Stop VMs concurrently
        await withTaskGroup(of: Void.self) { group in
            for vm in runningVMs {
                group.addTask {
                    do {
                        try await client.vms.stop(node: node, vmid: vm.id)
                        print("Stopped VM \(vm.id)")
                    } catch {
                        print("Failed to stop VM \(vm.id): \(error)")
                    }
                }
            }
        }
    }
    
    // Example: Backup operations
    func createClusterBackup(client: ProxmoxClient) async throws {
        let nodes = try await client.nodes.list()
        guard let targetNode = nodes.first?.node else {
            throw ProxmoxError.resourceNotFound("No nodes available")
        }
        
        let taskId = try await client.cluster.createBackup(
            node: targetNode,
            storage: "local"
        )
        print("Backup started with task ID: \(taskId)")
    }
}

// MARK: - Error Handling Examples

private func errorHandlingExamples() async {
    do {
        let client = try ProxmoxClient.create(host: "192.168.1.100")
        
        // This will fail if credentials are wrong
        let ticket = try await client.authenticate(username: "root@pam", password: "wrongpassword")
        
        // Try to list nodes (requires authentication)
        let nodes = try await client.nodes.list()
        
    } catch ProxmoxError.authenticationFailed(let message) {
        print("Authentication failed: \(message)")
        // The message now includes debug information about the session state
        
    } catch ProxmoxError.notAuthenticated {
        print("Not authenticated - call authenticate() first")
        
    } catch ProxmoxError.apiError(let code, let message) {
        print("API Error \(code): \(message)")
        
    } catch ProxmoxError.networkError(let error) {
        print("Network error: \(error.localizedDescription)")
        
    } catch {
        print("Unexpected error: \(error)")
    }
}

// MARK: - Complete Example: Login and Get All Cluster Resources

/// Complete example showing how to authenticate and retrieve all cluster resources
private func loginAndGetClusterResources() async {
    do {
        // MARK: - Step 1: Create the client
        
        // Option A: Using HTTPS with self-signed certificate (most common)
        let client = try ProxmoxClient.create(
            host: "192.168.1.100",  // Replace with your Proxmox host
            port: 8006,             // Default Proxmox port
            useHTTPS: true,
            validateSSL: false      // Set to true if you have valid SSL certificates
        )
        
        // Option B: Using HTTP (for testing/development)
        // let client = try ProxmoxClient.create(
        //     host: "192.168.1.100",
        //     port: 8080,
        //     useHTTPS: false,
        //     validateSSL: false
        // )
        
        print("✅ ProxmoxKit client created successfully")
        
        // MARK: - Step 2: Authenticate
        
        print("\n🔐 Authenticating...")
        let ticket = try await client.authenticate(
            username: "root@pam",      // Replace with your username
            password: "yourpassword"   // Replace with your password
        )
        
        print("✅ Authentication successful!")
        print("   Username: \(ticket.username)")
        print("   Ticket: \(ticket.ticket?.prefix(20) ?? "nil")...")
        print("   CSRF Token: \(ticket.CSRFPreventionToken?.prefix(20) ?? "nil")...")
        print("   Session Info: \(client.sessionDebugInfo)")
        
        // MARK: - Step 3: Get All Cluster Resources
        
        print("\n📊 Retrieving cluster resources...")
        
        // Get cluster status
        let clusterStatus = try await client.cluster.getStatus()
        print("✅ Cluster Status: \(clusterStatus.count) items")
        for status in clusterStatus {
            print("   - \(status.name ?? "Unknown"): \(status.type ?? "Unknown") (\(status.online == 1 ? "Online" : "Offline"))")
        }
        
        // Get all nodes
        print("\n🖥️  Getting all nodes...")
        let nodes = try await client.nodes.list()
        print("✅ Found \(nodes.count) nodes:")
        
        var totalVMs = 0
        var totalContainers = 0
        
        for node in nodes {
            print("\n   📍 Node: \(node.node)")
            print("      Status: \(node.status ?? "unknown")")
            print("      Type: \(node.type ?? "unknown")")
            if let uptime = node.uptime {
                let days = uptime / (24 * 3600)
                print("      Uptime: \(days) days")
            }
            
            // Get detailed node status
            let nodeStatus = try await client.nodes.getStatus(node.node)
            if let cpu = nodeStatus.cpu {
                print("      CPU Usage: \(String(format: "%.1f", cpu * 100))%")
            }
            if let memory = nodeStatus.memory {
                let usedGB = Double(memory.used ?? 0) / (1024 * 1024 * 1024)
                let totalGB = Double(memory.total ?? 0) / (1024 * 1024 * 1024)
                print("      Memory: \(String(format: "%.1f", usedGB))/\(String(format: "%.1f", totalGB)) GB")
            }
            
            // Get VMs on this node
            let nodeVMs = try await client.nodes.getVirtualMachines(node.node)
            totalVMs += nodeVMs.count
            print("      VMs: \(nodeVMs.count)")
            for vm in nodeVMs.prefix(3) { // Show first 3 VMs
                print("        - VM \(vm.vmid): \(vm.name ?? "unnamed") (\(vm.status ?? "unknown"))")
            }
            if nodeVMs.count > 3 {
                print("        ... and \(nodeVMs.count - 3) more")
            }
            
            // Get containers on this node
            let nodeContainers = try await client.nodes.getContainers(node.node)
            totalContainers += nodeContainers.count
            print("      Containers: \(nodeContainers.count)")
            for container in nodeContainers.prefix(3) { // Show first 3 containers
                print("        - CT \(container.vmid): \(container.name ?? "unnamed") (\(container.status ?? "unknown"))")
            }
            if nodeContainers.count > 3 {
                print("        ... and \(nodeContainers.count - 3) more")
            }
        }
        
        // Get all VMs across cluster
        print("\n🖥️  Getting all virtual machines...")
        let allVMs = try await client.vms.list()
        print("✅ Total VMs in cluster: \(allVMs.count)")
        
        let runningVMs = allVMs.filter { $0.status == .running }
        let stoppedVMs = allVMs.filter { $0.status == .stopped }
        print("   Running: \(runningVMs.count), Stopped: \(stoppedVMs.count)")
        
        // Show sample VMs
        for vm in allVMs.prefix(5) {
            print("   - VM \(vm.id): \(vm.name ?? "unnamed") on \(vm.node ?? "unknown") (\(vm.status?.rawValue ?? "unknown"))")
        }
        
        // Get all containers across cluster
        print("\n📦 Getting all containers...")
        let allContainers = try await client.containers.list()
        print("✅ Total containers in cluster: \(allContainers.count)")
        
        let runningContainers = allContainers.filter { $0.status == .running }
        let stoppedContainers = allContainers.filter { $0.status == .stopped }
        print("   Running: \(runningContainers.count), Stopped: \(stoppedContainers.count)")
        
        // Show sample containers
        for container in allContainers.prefix(5) {
            print("   - CT \(container.id): \(container.name ?? "unnamed") on \(container.node ?? "unknown") (\(container.status?.rawValue ?? "unknown"))")
        }
        
        // MARK: - Step 4: Summary
        
        print("\n📋 Cluster Summary:")
        print("   Nodes: \(nodes.count)")
        print("   Virtual Machines: \(totalVMs) (\(runningVMs.count) running)")
        print("   Containers: \(totalContainers) (\(runningContainers.count) running)")
        print("   Authentication: \(client.isAuthenticated ? "✅ Active" : "❌ Inactive")")
        
    } catch {
        print("❌ Error: \(error)")
        
        // Handle specific authentication errors
        if let proxmoxError = error as? ProxmoxError {
            switch proxmoxError {
            case .authenticationFailed(let reason):
                print("🔐 Authentication failed: \(reason)")
                print("💡 Check your username/password and ensure the user has proper permissions")
            case .networkError(let networkError):
                print("🌐 Network error: \(networkError.localizedDescription)")
                print("💡 Check if the Proxmox server is reachable and the port is correct")
            case .apiError(let code, let message):
                print("🔌 API error (\(code)): \(message)")
                print("💡 Check the Proxmox API documentation for this error code")
            default:
                print("❓ Other Proxmox error: \(proxmoxError.localizedDescription)")
            }
        }
    }
}

// MARK: - Quick Start Example

/// Minimal example for quick testing
private func quickStartExample() async {
    do {
        // Create client and authenticate
        let client = try ProxmoxClient.create(host: "your-proxmox-host", validateSSL: false)
        _ = try await client.authenticate(username: "root@pam", password: "password")
        
        // Get basic cluster info
        let nodes = try await client.nodes.list()
        let vms = try await client.vms.list()
        let containers = try await client.containers.list()
        
        print("Cluster: \(nodes.count) nodes, \(vms.count) VMs, \(containers.count) containers")
        
    } catch {
        print("Error: \(error)")
    }
}
