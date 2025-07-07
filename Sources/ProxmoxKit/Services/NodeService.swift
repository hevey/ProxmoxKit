import Foundation

/// Service for managing Proxmox nodes.
public class NodeService: BaseService {
    
    /// Lists all nodes in the cluster.
    /// - Returns: An array of Node objects.
    /// - Throws: ProxmoxError if the request fails.
    public func list() async throws -> [Node] {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxArrayResponse<Node>.self)
        
        return response.data
    }
    
    /// Gets detailed information about a specific node.
    /// - Parameter nodeName: The name of the node.
    /// - Returns: A Node object with detailed information.
    /// - Throws: ProxmoxError if the request fails.
    public func get(_ nodeName: String) async throws -> Node {
        try ensureAuthenticated()
        
        // The nodes endpoint returns an array, so we need to filter for the specific node
        let nodes = try await list()
        guard let node = nodes.first(where: { $0.node == nodeName }) else {
            throw ProxmoxError.resourceNotFound("Node '\(nodeName)' not found")
        }
        
        return node
    }
    
    /// Gets the status of a specific node.
    /// - Parameter nodeName: The name of the node.
    /// - Returns: NodeStatus with current system information.
    /// - Throws: ProxmoxError if the request fails.
    public func getStatus(_ nodeName: String) async throws -> NodeStatus {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(nodeName)/status")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxResponse<NodeStatus>.self)
        
        guard let status = response.data else {
            throw ProxmoxError.resourceNotFound("Status for node '\(nodeName)' not found")
        }
        
        return status
    }
    
    /// Gets the version information of a specific node.
    /// - Parameter nodeName: The name of the node.
    /// - Returns: A dictionary containing version information.
    /// - Throws: ProxmoxError if the request fails.
    public func getVersion(_ nodeName: String) async throws -> [String: Any] {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(nodeName)/version")
        let data = try await httpClient.get(url)
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let response = json as? [String: Any],
               let versionData = response["data"] as? [String: Any] {
                return versionData
            } else {
                throw ProxmoxError.invalidResponse
            }
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }
    
    /// Lists all virtual machines on a specific node.
    /// - Parameter nodeName: The name of the node.
    /// - Returns: An array of VirtualMachine objects.
    /// - Throws: ProxmoxError if the request fails.
    public func getVirtualMachines(_ nodeName: String) async throws -> [VirtualMachine] {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(nodeName)/qemu")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxArrayResponse<VirtualMachine>.self)
        
        return response.data
    }
    
    /// Lists all containers on a specific node.
    /// - Parameter nodeName: The name of the node.
    /// - Returns: An array of Container objects.
    /// - Throws: ProxmoxError if the request fails.
    public func getContainers(_ nodeName: String) async throws -> [Container] {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(nodeName)/lxc")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxArrayResponse<Container>.self)
        
        return response.data
    }

    /// Executes a command on the node (requires appropriate permissions).
    /// - Parameters:
    ///   - nodeName: The name of the node.
    ///   - command: The command to execute.
    /// - Returns: The command output.
    /// - Throws: ProxmoxError if the request fails.
    public func executeCommand(_ nodeName: String, command: String) async throws -> String {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(nodeName)/execute")
        let parameters = ["command": command]
        let body = encodeFormData(parameters)
        
        let (data, _) = try await httpClient.post(url, body: body, contentType: "application/x-www-form-urlencoded")
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let response = json as? [String: Any],
               let output = response["data"] as? String {
                return output
            } else {
                throw ProxmoxError.invalidResponse
            }
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }
    
    /// Changes the status of a specific node (e.g., reboot or shutdown).
    /// - Parameters:
    ///   - nodeName: The name of the node to operate on.
    ///   - action: The action to perform ("reboot" or "shutdown").
    /// - Throws: ProxmoxError if the request fails.
    public func status(_ nodeName: String, action: String) async throws {
        try ensureAuthenticated()
        let url = buildURL(path: "nodes/\(nodeName)/status")
        let parameters = ["command": action]
        let body = encodeFormData(parameters)
        let (data, _) = try await httpClient.post(url, body: body, contentType: "application/x-www-form-urlencoded")
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let response = json as? [String: Any], response["data"] != nil {
                return
            } else {
                throw ProxmoxError.invalidResponse
            }
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }

    /// Starts all VMs and containers on a node.
    /// - Parameters:
    ///   - nodeName: The name of the node.
    ///   - vms: Comma-separated list of VM/CT IDs to start (optional, if not specified all are started).
    ///   - force: Force start even if already running.
    /// - Throws: ProxmoxError if the request fails.
    public func startAll(_ nodeName: String, vms: String? = nil, force: Bool = false) async throws {
        try ensureAuthenticated()
        let url = buildURL(path: "nodes/\(nodeName)/startall")
        
        var parameters: [String: Any] = [:]
        if let vms = vms {
            parameters["vms"] = vms
        }
        if force {
            parameters["force"] = "1"
        }
        
        let body = parameters.isEmpty ? nil : encodeFormData(parameters)
        _ = try await httpClient.post(url, body: body, contentType: "application/x-www-form-urlencoded")
    }

    /// Suspends all VMs and containers on a node.
    /// - Parameters:
    ///   - nodeName: The name of the node.
    ///   - vms: Comma-separated list of VM/CT IDs to suspend (optional, if not specified all are suspended).
    /// - Throws: ProxmoxError if the request fails.
    public func suspendAll(_ nodeName: String, vms: String? = nil) async throws {
        try ensureAuthenticated()
        let url = buildURL(path: "nodes/\(nodeName)/suspendall")
        
        var parameters: [String: Any] = [:]
        if let vms = vms {
            parameters["vms"] = vms
        }
        
        let body = parameters.isEmpty ? nil : encodeFormData(parameters)
        _ = try await httpClient.post(url, body: body, contentType: "application/x-www-form-urlencoded")
    }

    /// Stops all VMs and containers on a node.
    /// - Parameters:
    ///   - nodeName: The name of the node.
    ///   - vms: Comma-separated list of VM/CT IDs to stop (optional, if not specified all are stopped).
    ///   - force: Force stop even if already stopped.
    ///   - timeout: Maximum time (in seconds) to wait for shutdown (default: 180, range: 0-7200).
    /// - Throws: ProxmoxError if the request fails or timeout is invalid.
    public func stopAll(_ nodeName: String, vms: String? = nil, force: Bool = false, timeout: Int = 180) async throws {
        try ensureAuthenticated()
        
        // Validate timeout parameter
        guard timeout >= 0 && timeout <= 7200 else {
            throw ProxmoxError.invalidConfiguration("Timeout must be between 0 and 7200 seconds")
        }
        
        let url = buildURL(path: "nodes/\(nodeName)/stopall")
        
        var parameters: [String: Any] = [:]
        if let vms = vms {
            parameters["vms"] = vms
        }
        if force {
            parameters["force"] = "1"
        }
        parameters["timeout"] = "\(timeout)"
        
        let body = encodeFormData(parameters)
        _ = try await httpClient.post(url, body: body, contentType: "application/x-www-form-urlencoded")
    }

    /// Restarts all VMs and containers on a node (convenience method: stop then start).
    /// Note: This is not a native Proxmox API endpoint but a convenience method that performs stopAll followed by startAll.
    /// - Parameters:
    ///   - nodeName: The name of the node.
    ///   - vms: Comma-separated list of VM/CT IDs to restart (optional, if not specified all are restarted).
    ///   - force: Force restart operations.
    ///   - timeout: Maximum time (in seconds) to wait for shutdown during stop phase (default: 180, range: 0-7200).
    /// - Throws: ProxmoxError if the request fails or timeout is invalid.
    public func restartAll(_ nodeName: String, vms: String? = nil, force: Bool = false, timeout: Int = 180) async throws {
        // Stop all first
        try await stopAll(nodeName, vms: vms, force: force, timeout: timeout)
        
        // Wait a moment for proper shutdown
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Then start all
        try await startAll(nodeName, vms: vms, force: force)
    }
}
