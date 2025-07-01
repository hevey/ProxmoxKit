import Foundation

/// Simple example showing how to authenticate with Proxmox and get all cluster resources
/// Replace the configuration values with your actual Proxmox server details

@main
struct ProxmoxExample {
    static func main() async {
        await loginAndGetClusterResources()
    }
}

func loginAndGetClusterResources() async {
    do {
        // MARK: - Configuration - Update these values for your environment
        
        let proxmoxHost = "barret.home.hevey.au"  // Your Proxmox server IP/hostname
        let proxmoxPort = 443             // Default Proxmox web interface port
        let username = "root@pam"          // Your username@realm (e.g., root@pam, user@pve)
        let password = "YLQRLzp3bmaLDa@Yw-H8Q"      // Your password
        let useHTTPS = true                // true for HTTPS, false for HTTP
        let validateSSL = true            // false for self-signed certificates
        
        // MARK: - Step 1: Create ProxmoxKit client
        
        print("🚀 Creating ProxmoxKit client...")
        let client = try ProxmoxClient.create(
            host: proxmoxHost,
            port: proxmoxPort,
            useHTTPS: useHTTPS,
            validateSSL: validateSSL
        )
        print("✅ Client created successfully")
        
        // MARK: - Step 2: Authenticate
        
        print("\n🔐 Authenticating with Proxmox...")
        let ticket = try await client.authenticate(username: username, password: password)
        
        print("✅ Authentication successful!")
        print("   Username: \(ticket.username)")
        print("   Has CSRF Token: \(ticket.CSRFPreventionToken != nil)")
        print("   Session Debug: \(client.sessionDebugInfo)")
        
        // MARK: - Step 3: Get cluster overview
        
        print("\n📊 Getting cluster status...")
        let clusterStatus = try await client.cluster.getStatus()
        print("✅ Cluster has \(clusterStatus.count) components")
        
        // MARK: - Step 4: Get all nodes
        
        print("\n🖥️  Getting all nodes...")
        let nodes = try await client.nodes.list()
        print("✅ Found \(nodes.count) nodes:")
        
        for node in nodes {
            print("   📍 \(node.node): \(node.status ?? "unknown") (\(node.type ?? "unknown"))")
            
            // Get detailed node information
            let nodeStatus = try await client.nodes.getStatus(node.node)
            if let cpu = nodeStatus.cpu {
                print("      CPU: \(String(format: "%.1f", cpu * 100))%")
            }
            if let memory = nodeStatus.memory {
                let usedMB = (memory.used ?? 0) / (1024 * 1024)
                let totalMB = (memory.total ?? 0) / (1024 * 1024)
                print("      Memory: \(usedMB)/\(totalMB) MB")
            }
        }
        
        // MARK: - Step 5: Get all virtual machines
        
        print("\n💻 Getting all virtual machines...")
        let allVMs = try await client.vms.list()
        print("✅ Found \(allVMs.count) virtual machines:")
        
        let runningVMs = allVMs.filter { $0.status == .running }
        let stoppedVMs = allVMs.filter { $0.status == .stopped }
        
        print("   Running: \(runningVMs.count)")
        print("   Stopped: \(stoppedVMs.count)")
        
        // Show details for first few VMs
        for vm in allVMs.prefix(5) {
            let statusIcon = vm.status == .running ? "🟢" : "🔴"
            print("   \(statusIcon) VM \(vm.id): \(vm.name ?? "unnamed") on \(vm.node ?? "unknown")")
        }
        
        if allVMs.count > 5 {
            print("   ... and \(allVMs.count - 5) more VMs")
        }
        
        // MARK: - Step 6: Get all containers
        
        print("\n📦 Getting all containers...")
        let allContainers = try await client.containers.list()
        print("✅ Found \(allContainers.count) containers:")
        
        let runningContainers = allContainers.filter { $0.status == .running }
        let stoppedContainers = allContainers.filter { $0.status == .stopped }
        
        print("   Running: \(runningContainers.count)")
        print("   Stopped: \(stoppedContainers.count)")
        
        // Show details for first few containers
        for container in allContainers.prefix(5) {
            let statusIcon = container.status == .running ? "🟢" : "🔴"
            print("   \(statusIcon) CT \(container.id): \(container.name ?? "unnamed") on \(container.node ?? "unknown")")
        }
        
        if allContainers.count > 5 {
            print("   ... and \(allContainers.count - 5) more containers")
        }
        
        // MARK: - Step 7: Summary
        
        print("\n📋 Cluster Summary:")
        print("=" * 40)
        print("Nodes:              \(nodes.count)")
        print("Virtual Machines:   \(allVMs.count) (\(runningVMs.count) running, \(stoppedVMs.count) stopped)")
        print("Containers:         \(allContainers.count) (\(runningContainers.count) running, \(stoppedContainers.count) stopped)")
        print("Authentication:     \(client.isAuthenticated ? "✅ Active" : "❌ Inactive")")
        print("=" * 40)
        
        // Demonstration of error handling for operations
        print("\n🔧 Testing VM operations (if VMs exist)...")
        if let firstVM = allVMs.first {
            do {
                let vmStatus = try await client.vms.getStatus(node: firstVM.node ?? "", vmid: firstVM.id)
                print("✅ Got status for VM \(firstVM.id): \(vmStatus.status?.rawValue ?? "unknown")")
            } catch {
                print("⚠️  Could not get VM status: \(error)")
            }
        }
        
    } catch {
        print("\n❌ Error occurred: \(error)")
        
        // Provide helpful error handling
        if let proxmoxError = error as? ProxmoxError {
            switch proxmoxError {
            case .authenticationFailed(let reason):
                print("\n🔐 Authentication Error:")
                print("   Reason: \(reason)")
                print("   💡 Solutions:")
                print("   - Check username and password")
                print("   - Ensure user has proper permissions")
                print("   - Verify the realm (e.g., @pam, @pve)")
                
            case .networkError(let networkError):
                print("\n🌐 Network Error:")
                print("   Details: \(networkError.localizedDescription)")
                print("   💡 Solutions:")
                print("   - Check if Proxmox server is reachable")
                print("   - Verify host and port are correct")
                print("   - Check firewall settings")
                
            case .invalidConfiguration(let message):
                print("\n⚙️  Configuration Error:")
                print("   Details: \(message)")
                print("   💡 Check your host, port, and protocol settings")
                
            case .apiError(let code, let message):
                print("\n🔌 API Error:")
                print("   Code: \(code)")
                print("   Message: \(message)")
                print("   💡 Check Proxmox API documentation for error code \(code)")
                
            default:
                print("\n❓ Other Proxmox Error: \(proxmoxError.localizedDescription)")
            }
        } else {
            print("   Unexpected error: \(error.localizedDescription)")
        }
        
        print("\n📚 For more help, check:")
        print("   - Proxmox documentation: https://pve.proxmox.com/pve-docs/")
        print("   - ProxmoxKit examples in the repository")
    }
}

// Helper extension for string multiplication
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
