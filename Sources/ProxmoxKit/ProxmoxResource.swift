/// Represents the list of Proxmox resources.
public struct ProxmoxResourceList: Decodable {
    public let data: [ProxmoxResource]
}

/// Common Proxmox resource types.
public enum ProxmoxResourceType: String, Decodable {
    case node
    case qemu
    case lxc
    case storage
    case cluster
    case pool
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ProxmoxResourceType(rawValue: rawValue) ?? .unknown
    }
}

/// Represents a Proxmox resource.
public struct ProxmoxResource: Decodable {
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
}
