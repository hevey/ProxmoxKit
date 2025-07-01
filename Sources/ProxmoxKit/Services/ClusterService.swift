import Foundation

/// Service for managing Proxmox cluster operations.
public class ClusterService: BaseService {
    
    /// Gets cluster status information.
    /// - Returns: A dictionary containing cluster status information.
    /// - Throws: ProxmoxError if the request fails.
    public func getStatus() async throws -> [String: Any] {
        try ensureAuthenticated()
        
        let url = buildURL(path: "cluster/status")
        let data = try await httpClient.get(url)
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let response = json as? [String: Any],
               let statusData = response["data"] as? [String: Any] {
                return statusData
            } else {
                throw ProxmoxError.invalidResponse
            }
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }
    
    /// Gets all cluster resources.
    /// - Parameter type: Optional resource type filter ("vm", "storage", "node").
    /// - Returns: An array of ProxmoxResource objects.
    /// - Throws: ProxmoxError if the request fails.
    public func getResources(type: String? = nil) async throws -> [ProxmoxResource] {
        try ensureAuthenticated()
        
        var path = "cluster/resources"
        if let resourceType = type {
            path += "?type=\(resourceType)"
        }
        
        let url = buildURL(path: path)
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxArrayResponse<ProxmoxResource>.self)
        
        return response.data
    }
    
    /// Gets cluster nodes information.
    /// - Returns: An array of Node objects representing cluster nodes.
    /// - Throws: ProxmoxError if the request fails.
    public func getNodes() async throws -> [Node] {
        try ensureAuthenticated()
        
        let url = buildURL(path: "cluster/resources?type=node")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxArrayResponse<Node>.self)
        
        return response.data
    }
    
    /// Gets all virtual machines in the cluster.
    /// - Returns: An array of VirtualMachine objects.
    /// - Throws: ProxmoxError if the request fails.
    public func getVirtualMachines() async throws -> [VirtualMachine] {
        try ensureAuthenticated()
        
        let url = buildURL(path: "cluster/resources?type=vm")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxArrayResponse<VirtualMachine>.self)
        
        return response.data
    }
    
    /// Gets cluster configuration.
    /// - Returns: A dictionary containing cluster configuration.
    /// - Throws: ProxmoxError if the request fails.
    public func getConfig() async throws -> [String: Any] {
        try ensureAuthenticated()
        
        let url = buildURL(path: "cluster/config")
        let data = try await httpClient.get(url)
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let response = json as? [String: Any],
               let configData = response["data"] as? [String: Any] {
                return configData
            } else {
                throw ProxmoxError.invalidResponse
            }
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }
    
    /// Gets cluster backup schedule.
    /// - Returns: An array of backup job configurations.
    /// - Throws: ProxmoxError if the request fails.
    public func getBackupSchedule() async throws -> [[String: Any]] {
        try ensureAuthenticated()
        
        let url = buildURL(path: "cluster/backup")
        let data = try await httpClient.get(url)
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let response = json as? [String: Any],
               let backupData = response["data"] as? [[String: Any]] {
                return backupData
            } else {
                throw ProxmoxError.invalidResponse
            }
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }
    
    /// Performs a cluster backup.
    /// - Parameters:
    ///   - vmids: Array of VM IDs to backup (optional, defaults to all).
    ///   - node: Target node for backup.
    ///   - storage: Storage location for backup.
    /// - Returns: Task ID for the backup operation.
    /// - Throws: ProxmoxError if the request fails.
    public func createBackup(vmids: [Int]? = nil, node: String, storage: String) async throws -> String {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/vzdump")
        
        var parameters: [String: Any] = [
            "storage": storage,
            "mode": "snapshot"
        ]
        
        if let vmids = vmids {
            parameters["vmid"] = vmids.map { String($0) }.joined(separator: ",")
        } else {
            parameters["all"] = "1"
        }
        
        let body = encodeFormData(parameters)
        let (data, _) = try await httpClient.post(url, body: body, contentType: "application/x-www-form-urlencoded")
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let response = json as? [String: Any],
               let taskId = response["data"] as? String {
                return taskId
            } else {
                throw ProxmoxError.invalidResponse
            }
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }
}
