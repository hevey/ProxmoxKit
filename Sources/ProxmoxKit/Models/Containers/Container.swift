import Foundation

/// Represents a Container (LXC) in Proxmox.
public struct Container: Codable, Identifiable, Sendable {
    /// The unique container ID.
    public let id: Int
    
    /// The container ID (same as id for compatibility).
    public var vmid: Int { id }
    
    /// The container name.
    public let name: String?
    
    /// The node where the container is located.
    public let node: String?
    
    /// Current status of the container.
    public let status: ContainerStatus?
    
    /// Container type (usually "lxc").
    public let type: String?
    
    /// Allocated memory in MB.
    public let maxmem: Int?
    
    /// Number of CPU cores.
    public let cpus: Int?
    
    /// Allocated disk space in bytes.
    public let maxdisk: Int64?
    
    /// Current CPU usage percentage.
    public let cpu: Double?
    
    /// Current memory usage in bytes.
    public let mem: Int64?
    
    /// Current disk usage in bytes.
    public let disk: Int64?
    
    /// Network interfaces usage.
    public let netin: Int64?
    public let netout: Int64?
    
    /// Disk I/O statistics.
    public let diskread: Int64?
    public let diskwrite: Int64?
    
    /// System uptime in seconds.
    public let uptime: Int?
    
    /// Template flag.
    public let template: Bool?
    
    /// Tags associated with the container.
    public let tags: String?
    
    /// Whether the container is privileged.
    public let unprivileged: Bool?
    
    /// Container OS type.
    public let ostype: String?
    
    /// Initializes a new Container.
    public init(
        id: Int,
        name: String? = nil,
        node: String? = nil,
        status: ContainerStatus? = nil,
        type: String? = nil,
        maxmem: Int? = nil,
        cpus: Int? = nil,
        maxdisk: Int64? = nil,
        cpu: Double? = nil,
        mem: Int64? = nil,
        disk: Int64? = nil,
        netin: Int64? = nil,
        netout: Int64? = nil,
        diskread: Int64? = nil,
        diskwrite: Int64? = nil,
        uptime: Int? = nil,
        template: Bool? = nil,
        tags: String? = nil,
        unprivileged: Bool? = nil,
        ostype: String? = nil
    ) {
        self.id = id
        self.name = name
        self.node = node
        self.status = status
        self.type = type
        self.maxmem = maxmem
        self.cpus = cpus
        self.maxdisk = maxdisk
        self.cpu = cpu
        self.mem = mem
        self.disk = disk
        self.netin = netin
        self.netout = netout
        self.diskread = diskread
        self.diskwrite = diskwrite
        self.uptime = uptime
        self.template = template
        self.tags = tags
        self.unprivileged = unprivileged
        self.ostype = ostype
    }
    
    /// Whether the container is currently running.
    public var isRunning: Bool {
        return status == .running
    }
    
    /// Whether the container is stopped.
    public var isStopped: Bool {
        return status == .stopped
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "vmid"
        case name, node, status, type, maxmem, cpus, maxdisk
        case cpu, mem, disk, netin, netout, diskread, diskwrite
        case uptime, template, tags, unprivileged, ostype
    }
}

/// Container status enumeration.
public enum ContainerStatus: String, Codable, CaseIterable, Sendable {
    case running
    case stopped
    case unknown
    
    /// Initializes from decoder, handling unknown cases.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let statusString = try container.decode(String.self)
        self = ContainerStatus(rawValue: statusString) ?? .unknown
    }
}

/// Configuration for creating or updating a Container.
public struct ContainerConfig: Codable, Sendable {
    /// Container hostname.
    public var hostname: String?
    
    /// Memory allocation in MB.
    public var memory: Int?
    
    /// Number of CPU cores.
    public var cores: Int?
    
    /// CPU units (relative weight).
    public var cpuunits: Int?
    
    /// Network interfaces.
    public var net: [String: String]?
    
    /// Mount points.
    public var mp: [String: String]?
    
    /// Root filesystem.
    public var rootfs: String?
    
    /// Container OS template.
    public var ostemplate: String?
    
    /// Container description.
    public var description: String?
    
    /// Whether to start container on boot.
    public var onboot: Bool?
    
    /// Container tags.
    public var tags: String?
    
    /// Protection flag.
    public var protection: Bool?
    
    /// Whether the container is unprivileged.
    public var unprivileged: Bool?
    
    /// OS type.
    public var ostype: String?
    
    /// Password for the root user.
    public var password: String?
    
    /// SSH public key.
    public var ssh_public_keys: String?
    
    /// Initializes a new ContainerConfig.
    public init(
        hostname: String? = nil,
        memory: Int? = nil,
        cores: Int? = nil,
        cpuunits: Int? = nil,
        net: [String: String]? = nil,
        mp: [String: String]? = nil,
        rootfs: String? = nil,
        ostemplate: String? = nil,
        description: String? = nil,
        onboot: Bool? = nil,
        tags: String? = nil,
        protection: Bool? = nil,
        unprivileged: Bool? = nil,
        ostype: String? = nil,
        password: String? = nil,
        ssh_public_keys: String? = nil
    ) {
        self.hostname = hostname
        self.memory = memory
        self.cores = cores
        self.cpuunits = cpuunits
        self.net = net
        self.mp = mp
        self.rootfs = rootfs
        self.ostemplate = ostemplate
        self.description = description
        self.onboot = onboot
        self.tags = tags
        self.protection = protection
        self.unprivileged = unprivileged
        self.ostype = ostype
        self.password = password
        self.ssh_public_keys = ssh_public_keys
    }
}
