import Foundation

// MARK: - Main Export
// Export the new service-oriented client as the primary interface
public typealias ProxmoxKit = ProxmoxClient

// MARK: - Re-exports for convenience
// Core types
public typealias ProxmoxConfiguration = ProxmoxConfig

// Model types - common
public typealias Resource = ProxmoxResource

// Model types - VMs
public typealias VM = VirtualMachine

// Service types
public typealias NodeManager = NodeService
public typealias VMManager = VMService
public typealias ContainerManager = ContainerService
public typealias ClusterManager = ClusterService

// MARK: - Convenience initializers and factory methods

extension ProxmoxClient {
    /// Creates a ProxmoxKit client with common settings.
    /// - Parameters:
    ///   - host: The hostname or IP address of the Proxmox server.
    ///   - port: The port number (defaults to 8006).
    ///   - useHTTPS: Whether to use HTTPS (defaults to true).
    /// - Returns: A configured ProxmoxClient instance.
    public static func create(
        host: String,
        port: Int = 8006,
        useHTTPS: Bool = true
    ) throws -> ProxmoxClient {
        let scheme = useHTTPS ? "https" : "http"
        guard let url = URL(string: "\(scheme)://\(host):\(port)") else {
            throw ProxmoxError.invalidConfiguration("Invalid host or port configuration")
        }
        
        let config = ProxmoxConfig(baseURL: url)
        return ProxmoxClient(config: config)
    }
    
    /// Creates a ProxmoxKit client with custom configuration.
    /// - Parameters:
    ///   - host: The hostname or IP address of the Proxmox server.
    ///   - port: The port number (defaults to 8006).
    ///   - useHTTPS: Whether to use HTTPS (defaults to true).
    ///   - timeout: Request timeout in seconds (defaults to 30).
    ///   - validateSSL: Whether to validate SSL certificates (defaults to true).
    /// - Returns: A configured ProxmoxClient instance.
    public static func create(
        host: String,
        port: Int = 8006,
        useHTTPS: Bool = true,
        timeout: TimeInterval = 30,
        validateSSL: Bool = true
    ) throws -> ProxmoxClient {
        let scheme = useHTTPS ? "https" : "http"
        guard let url = URL(string: "\(scheme)://\(host):\(port)") else {
            throw ProxmoxError.invalidConfiguration("Invalid host or port configuration")
        }
        
        let config = ProxmoxConfig(
            baseURL: url,
            timeout: timeout,
            validateSSL: validateSSL
        )
        return ProxmoxClient(config: config)
    }
}

// MARK: - Builder pattern helpers

/// Creates a new VM configuration builder.
/// - Returns: A VMConfigBuilder instance.
public func buildVMConfig() -> VMConfigBuilder {
    return VMConfigBuilder()
}

// MARK: - Version information

extension ProxmoxClient {
    /// The version of ProxmoxKit.
    public static let version = "0.1.0"
    
    /// Information about the ProxmoxKit library.
    public static let info = """
        ProxmoxKit v\(version)
        A Swift library for interacting with the Proxmox Virtual Environment API
        """
}