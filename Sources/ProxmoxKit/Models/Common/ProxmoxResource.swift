import Foundation

/// Represents the list of Proxmox resources.
public struct ProxmoxResourceList: Codable {
    public let data: [ProxmoxResource]
}

/// Common Proxmox resource types.
public enum ProxmoxResourceType: String, Codable, CaseIterable, Sendable {
    
    
    case node
    case qemu
    case lxc
    case storage
    case sdn
    case pool
    case openvz
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ProxmoxResourceType(rawValue: rawValue) ?? .unknown
    }
}

/// Represents a Proxmox resource.
public struct ProxmoxResource: Codable, Sendable {
    public let id: String
    /// The type of the Proxmox resource.
    public let type: ProxmoxResourceType
    public let status: String?
    public let name: String?
    public let node: String?
    public let maxmem: Int?
    public let maxcpu: Int?
    public let mem: Int?
    public let cpu: Double?
    public let disk: Int?
    public let maxdisk: Int?
    public let uptime: Int?
    public let vmid: Int?
    public let template: Int?
    public let description: String?
    
    public init(id: String, type: ProxmoxResourceType, status: String? = nil, name: String? = nil, node: String? = nil, maxmem: Int? = nil, maxcpu: Int? = nil, mem: Int? = nil, cpu: Double? = nil, disk: Int? = nil, maxdisk: Int? = nil, uptime: Int? = nil, vmid: Int? = nil, template: Int? = nil, description: String? = nil) {
        self.id = id
        self.type = type
        self.status = status
        self.name = name
        self.node = node
        self.maxmem = maxmem
        self.maxcpu = maxcpu
        self.mem = mem
        self.cpu = cpu
        self.disk = disk
        self.maxdisk = maxdisk
        self.uptime = uptime
        self.vmid = vmid
        self.template = template
        self.description = description
    }
}

