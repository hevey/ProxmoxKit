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
        
        let url = buildURL(path: "nodes/\(nodeName)")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxResponse<Node>.self)
        
        guard let node = response.data else {
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
}
