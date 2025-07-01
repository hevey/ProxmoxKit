import Foundation

/// Service for managing Virtual Machines in Proxmox.
public class VMService: BaseService {
    
    /// Lists all virtual machines in the cluster.
    /// - Parameter node: Optional node name to filter VMs by node.
    /// - Returns: An array of VirtualMachine objects.
    /// - Throws: ProxmoxError if the request fails.
    public func list(node: String? = nil) async throws -> [VirtualMachine] {
        try ensureAuthenticated()
        
        let url: URL
        if let nodeName = node {
            url = buildURL(path: "nodes/\(nodeName)/qemu")
        } else {
            url = buildURL(path: "cluster/resources?type=vm")
        }
        
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxArrayResponse<VirtualMachine>.self)
        
        return response.data
    }
    
    /// Gets detailed information about a specific virtual machine.
    /// - Parameters:
    ///   - node: The node name where the VM is located.
    ///   - vmid: The VM ID.
    /// - Returns: A VirtualMachine object with detailed information.
    /// - Throws: ProxmoxError if the request fails.
    public func get(node: String, vmid: Int) async throws -> VirtualMachine {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/qemu/\(vmid)/config")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxResponse<VirtualMachine>.self)
        
        guard let vm = response.data else {
            throw ProxmoxError.resourceNotFound("VM \(vmid) not found on node \(node)")
        }
        
        return vm
    }
    
    /// Gets the current status of a virtual machine.
    /// - Parameters:
    ///   - node: The node name where the VM is located.
    ///   - vmid: The VM ID.
    /// - Returns: A VirtualMachine object with current status information.
    /// - Throws: ProxmoxError if the request fails.
    public func getStatus(node: String, vmid: Int) async throws -> VirtualMachine {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/qemu/\(vmid)/status/current")
        let data = try await httpClient.get(url)
        let response = try decode(data, as: ProxmoxResponse<VirtualMachine>.self)
        
        guard let vm = response.data else {
            throw ProxmoxError.resourceNotFound("VM \(vmid) status not found on node \(node)")
        }
        
        return vm
    }
    
    /// Starts a virtual machine.
    /// - Parameters:
    ///   - node: The node name where the VM is located.
    ///   - vmid: The VM ID.
    /// - Throws: ProxmoxError if the request fails.
    public func start(node: String, vmid: Int) async throws {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/qemu/\(vmid)/status/start")
        let _ = try await httpClient.post(url, body: nil)
    }
    
    /// Stops a virtual machine.
    /// - Parameters:
    ///   - node: The node name where the VM is located.
    ///   - vmid: The VM ID.
    ///   - force: Whether to force stop the VM.
    /// - Throws: ProxmoxError if the request fails.
    public func stop(node: String, vmid: Int, force: Bool = false) async throws {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/qemu/\(vmid)/status/stop")
        let parameters = force ? ["force": "1"] : [:]
        let body = encodeFormData(parameters)
        
        let _ = try await httpClient.post(url, body: body, contentType: "application/x-www-form-urlencoded")
    }
    
    /// Restarts a virtual machine.
    /// - Parameters:
    ///   - node: The node name where the VM is located.
    ///   - vmid: The VM ID.
    /// - Throws: ProxmoxError if the request fails.
    public func restart(node: String, vmid: Int) async throws {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/qemu/\(vmid)/status/reboot")
        let _ = try await httpClient.post(url, body: nil)
    }
    
    /// Pauses a virtual machine.
    /// - Parameters:
    ///   - node: The node name where the VM is located.
    ///   - vmid: The VM ID.
    /// - Throws: ProxmoxError if the request fails.
    public func pause(node: String, vmid: Int) async throws {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/qemu/\(vmid)/status/suspend")
        let _ = try await httpClient.post(url, body: nil)
    }
    
    /// Resumes a paused virtual machine.
    /// - Parameters:
    ///   - node: The node name where the VM is located.
    ///   - vmid: The VM ID.
    /// - Throws: ProxmoxError if the request fails.
    public func resume(node: String, vmid: Int) async throws {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/qemu/\(vmid)/status/resume")
        let _ = try await httpClient.post(url, body: nil)
    }
    
    /// Creates a new virtual machine.
    /// - Parameters:
    ///   - node: The node name where to create the VM.
    ///   - vmid: The VM ID for the new VM.
    ///   - config: The VM configuration.
    /// - Returns: The created VirtualMachine object.
    /// - Throws: ProxmoxError if the request fails.
    public func create(node: String, vmid: Int, config: VMConfig) async throws -> VirtualMachine {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/qemu")
        
        // Convert VMConfig to form parameters
        var parameters: [String: Any] = ["vmid": vmid]
        
        if let name = config.name { parameters["name"] = name }
        if let memory = config.memory { parameters["memory"] = memory }
        if let cores = config.cores { parameters["cores"] = cores }
        if let cpu = config.cpu { parameters["cpu"] = cpu }
        if let boot = config.boot { parameters["boot"] = boot }
        if let description = config.description { parameters["description"] = description }
        if let onboot = config.onboot { parameters["onboot"] = onboot ? "1" : "0" }
        if let tags = config.tags { parameters["tags"] = tags }
        if let protection = config.protection { parameters["protection"] = protection ? "1" : "0" }
        
        // Add network interfaces
        if let net = config.net {
            for (key, value) in net {
                parameters[key] = value
            }
        }
        
        // Add storage devices
        if let scsi = config.scsi {
            for (key, value) in scsi {
                parameters[key] = value
            }
        }
        
        if let virtio = config.virtio {
            for (key, value) in virtio {
                parameters[key] = value
            }
        }
        
        let body = encodeFormData(parameters)
        let (_, _) = try await httpClient.post(url, body: body, contentType: "application/x-www-form-urlencoded")
        
        // Return the created VM
        return try await get(node: node, vmid: vmid)
    }
    
    /// Updates a virtual machine configuration.
    /// - Parameters:
    ///   - node: The node name where the VM is located.
    ///   - vmid: The VM ID.
    ///   - config: The VM configuration changes.
    /// - Throws: ProxmoxError if the request fails.
    public func update(node: String, vmid: Int, config: VMConfig) async throws {
        try ensureAuthenticated()
        
        let url = buildURL(path: "nodes/\(node)/qemu/\(vmid)/config")
        
        // Convert VMConfig to form parameters (only non-nil values)
        var parameters: [String: Any] = [:]
        
        if let name = config.name { parameters["name"] = name }
        if let memory = config.memory { parameters["memory"] = memory }
        if let cores = config.cores { parameters["cores"] = cores }
        if let cpu = config.cpu { parameters["cpu"] = cpu }
        if let boot = config.boot { parameters["boot"] = boot }
        if let description = config.description { parameters["description"] = description }
        if let onboot = config.onboot { parameters["onboot"] = onboot ? "1" : "0" }
        if let tags = config.tags { parameters["tags"] = tags }
        if let protection = config.protection { parameters["protection"] = protection ? "1" : "0" }
        
        let body = encodeFormData(parameters)
        let _ = try await httpClient.put(url, body: body, contentType: "application/x-www-form-urlencoded")
    }
    
    /// Deletes a virtual machine.
    /// - Parameters:
    ///   - node: The node name where the VM is located.
    ///   - vmid: The VM ID.
    ///   - purge: Whether to purge the VM from all configurations.
    /// - Throws: ProxmoxError if the request fails.
    public func delete(node: String, vmid: Int, purge: Bool = false) async throws {
        try ensureAuthenticated()
        
        var path = "nodes/\(node)/qemu/\(vmid)"
        if purge {
            path += "?purge=1"
        }
        
        let url = buildURL(path: path)
        let _ = try await httpClient.delete(url)
    }
}
