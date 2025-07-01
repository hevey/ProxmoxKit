import Foundation

/// Service for managing Containers (LXC) in Proxmox.
public class ContainerService: BaseService {
    
    /// Lists all containers in the cluster.
    /// - Parameter node: Optional node name to filter containers by node.
    /// - Returns: An array of Container objects.
    /// - Throws: ProxmoxError if the request fails.
    public func list(node: String? = nil) async throws -> [Container] {
        try ensureAuthenticated()
        
        let url: URL
        if let nodeName = node {
            url = buildURL(path: "nodes/\(nodeName)/lxc")
        } else {
            url = buildURL(path: "cluster/resources?type=lxc")
        }
        
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxArrayResponse<Container>.self)
        
        return response.data
    }
    
    /// Gets detailed information about a specific container.
    /// - Parameters:
    ///   - node: The node name where the container is located.
    ///   - vmid: The container ID.
    /// - Returns: A Container object with detailed information.
    /// - Throws: ProxmoxError if the request fails.
    public func get(node: String, vmid: Int) async throws -> Container {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/lxc/\(vmid)/config")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxResponse<Container>.self)
        
        guard let container = response.data else {
            throw ProxmoxError.resourceNotFound("Container \(vmid) not found on node \(node)")
        }
        
        return container
    }
    
    /// Gets the current status of a container.
    /// - Parameters:
    ///   - node: The node name where the container is located.
    ///   - vmid: The container ID.
    /// - Returns: A Container object with current status information.
    /// - Throws: ProxmoxError if the request fails.
    public func getStatus(node: String, vmid: Int) async throws -> Container {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/lxc/\(vmid)/status/current")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxResponse<Container>.self)
        
        guard let container = response.data else {
            throw ProxmoxError.resourceNotFound("Container \(vmid) status not found on node \(node)")
        }
        
        return container
    }
    
    /// Starts a container.
    /// - Parameters:
    ///   - node: The node name where the container is located.
    ///   - vmid: The container ID.
    /// - Throws: ProxmoxError if the request fails.
    public func start(node: String, vmid: Int) async throws {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/lxc/\(vmid)/status/start")
        let _ = try await httpClient.post(url, body: nil)
    }
    
    /// Stops a container.
    /// - Parameters:
    ///   - node: The node name where the container is located.
    ///   - vmid: The container ID.
    ///   - force: Whether to force stop the container.
    /// - Throws: ProxmoxError if the request fails.
    public func stop(node: String, vmid: Int, force: Bool = false) async throws {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/lxc/\(vmid)/status/stop")
        let parameters = force ? ["force": "1"] : [:]
        let body = encodeFormData(parameters)
        
        let _ = try await httpClient.post(url, body: body, contentType: "application/x-www-form-urlencoded")
    }
    
    /// Restarts a container.
    /// - Parameters:
    ///   - node: The node name where the container is located.
    ///   - vmid: The container ID.
    /// - Throws: ProxmoxError if the request fails.
    public func restart(node: String, vmid: Int) async throws {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/lxc/\(vmid)/status/reboot")
        let _ = try await httpClient.post(url, body: nil)
    }
    
    /// Creates a new container.
    /// - Parameters:
    ///   - node: The node name where to create the container.
    ///   - vmid: The container ID for the new container.
    ///   - config: The container configuration.
    /// - Returns: The created Container object.
    /// - Throws: ProxmoxError if the request fails.
    public func create(node: String, vmid: Int, config: ContainerConfig) async throws -> Container {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/lxc")
        
        // Convert ContainerConfig to form parameters
        var parameters: [String: Any] = ["vmid": vmid]
        
        if let hostname = config.hostname { parameters["hostname"] = hostname }
        if let memory = config.memory { parameters["memory"] = memory }
        if let cores = config.cores { parameters["cores"] = cores }
        if let cpuunits = config.cpuunits { parameters["cpuunits"] = cpuunits }
        if let rootfs = config.rootfs { parameters["rootfs"] = rootfs }
        if let ostemplate = config.ostemplate { parameters["ostemplate"] = ostemplate }
        if let description = config.description { parameters["description"] = description }
        if let onboot = config.onboot { parameters["onboot"] = onboot ? "1" : "0" }
        if let tags = config.tags { parameters["tags"] = tags }
        if let protection = config.protection { parameters["protection"] = protection ? "1" : "0" }
        if let unprivileged = config.unprivileged { parameters["unprivileged"] = unprivileged ? "1" : "0" }
        if let ostype = config.ostype { parameters["ostype"] = ostype }
        if let password = config.password { parameters["password"] = password }
        if let sshKeys = config.ssh_public_keys { parameters["ssh-public-keys"] = sshKeys }
        
        // Add network interfaces
        if let net = config.net {
            for (key, value) in net {
                parameters[key] = value
            }
        }
        
        // Add mount points
        if let mp = config.mp {
            for (key, value) in mp {
                parameters[key] = value
            }
        }
        
        let body = encodeFormData(parameters)
        let (_, _) = try await httpClient.post(url, body: body, contentType: "application/x-www-form-urlencoded")
        
        // Return the created container
        return try await get(node: node, vmid: vmid)
    }
    
    /// Updates a container configuration.
    /// - Parameters:
    ///   - node: The node name where the container is located.
    ///   - vmid: The container ID.
    ///   - config: The container configuration changes.
    /// - Throws: ProxmoxError if the request fails.
    public func update(node: String, vmid: Int, config: ContainerConfig) async throws {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/lxc/\(vmid)/config")
        
        // Convert ContainerConfig to form parameters (only non-nil values)
        var parameters: [String: Any] = [:]
        
        if let hostname = config.hostname { parameters["hostname"] = hostname }
        if let memory = config.memory { parameters["memory"] = memory }
        if let cores = config.cores { parameters["cores"] = cores }
        if let cpuunits = config.cpuunits { parameters["cpuunits"] = cpuunits }
        if let description = config.description { parameters["description"] = description }
        if let onboot = config.onboot { parameters["onboot"] = onboot ? "1" : "0" }
        if let tags = config.tags { parameters["tags"] = tags }
        if let protection = config.protection { parameters["protection"] = protection ? "1" : "0" }
        
        let body = encodeFormData(parameters)
        let _ = try await httpClient.put(url, body: body, contentType: "application/x-www-form-urlencoded")
    }
    
    /// Deletes a container.
    /// - Parameters:
    ///   - node: The node name where the container is located.
    ///   - vmid: The container ID.
    ///   - purge: Whether to purge the container from all configurations.
    /// - Throws: ProxmoxError if the request fails.
    public func delete(node: String, vmid: Int, purge: Bool = false) async throws {
        try ensureAuthenticated()
        
        var path = "nodes/\(node)/lxc/\(vmid)"
        if purge {
            path += "?purge=1"
        }
        
        let url = buildURL(path: path)
        let _ = try await httpClient.delete(url)
    }
    
    /// Executes a command inside a container.
    /// - Parameters:
    ///   - node: The node name where the container is located.
    ///   - vmid: The container ID.
    ///   - command: The command to execute.
    /// - Returns: The command output.
    /// - Throws: ProxmoxError if the request fails.
    public func executeCommand(node: String, vmid: Int, command: String) async throws -> String {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/lxc/\(vmid)/exec")
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
