import Foundation

/// Represents a Proxmox node in the cluster.
public struct Node: Codable, Identifiable, Sendable {
    /// The unique identifier for the node.
    public var id: String
    
    /// The node name.
    public let node: String
    
    /// The node type (usually "node").
    public let type: String?
    
    /// Current status of the node.
    public let status: String?
    
    /// Whether the node is online.
    public let online: Bool?
    
    /// CPU usage percentage.
    public let cpu: Double?
    
    /// Maximum CPU count.
    public let maxcpu: Int?
    
    /// Memory usage in bytes.
    public let mem: Int64?
    
    /// Maximum memory in bytes.
    public let maxmem: Int64?
    
    /// Disk usage in bytes.
    public let disk: Int64?
    
    /// Maximum disk space in bytes.
    public let maxdisk: Int64?
    
    /// System uptime in seconds.
    public let uptime: Int?
    
    /// Node level in the cluster hierarchy.
    public let level: String?
    
    /// Proxmox VE version.
    public let version: String?
    
    /// Subscription status.
    public let subscription: String?
    
    /// Initializes a new Node.
    public init(
        id: String,
        node: String,
        type: String? = nil,
        status: String? = nil,
        online: Bool? = nil,
        cpu: Double? = nil,
        maxcpu: Int? = nil,
        mem: Int64? = nil,
        maxmem: Int64? = nil,
        disk: Int64? = nil,
        maxdisk: Int64? = nil,
        uptime: Int? = nil,
        level: String? = nil,
        version: String? = nil,
        subscription: String? = nil
    ) {
        self.id = id
        self.node = node
        self.type = type
        self.status = status
        self.online = online
        self.cpu = cpu
        self.maxcpu = maxcpu
        self.mem = mem
        self.maxmem = maxmem
        self.disk = disk
        self.maxdisk = maxdisk
        self.uptime = uptime
        self.level = level
        self.version = version
        self.subscription = subscription
    }
}

/// Status information for a specific node.
public struct NodeStatus: Codable, Sendable {
    /// Current CPU usage percentage.
    public let cpu: Double?
    
    /// CPU information string.
    public let cpuinfo: String?
    
    /// Current memory usage in bytes.
    public let memory: NodeMemoryInfo?
    
    /// Current disk usage information.
    public let rootfs: NodeDiskInfo?
    
    /// System uptime in seconds.
    public let uptime: Int?
    
    /// Current system load averages.
    public let loadavg: [Double]?
    
    /// Kernel version.
    public let kversion: String?
    
    /// Proxmox VE version.
    public let pveversion: String?
    
    /// Initializes a new NodeStatus.
    public init(
        cpu: Double? = nil,
        cpuinfo: String? = nil,
        memory: NodeMemoryInfo? = nil,
        rootfs: NodeDiskInfo? = nil,
        uptime: Int? = nil,
        loadavg: [Double]? = nil,
        kversion: String? = nil,
        pveversion: String? = nil
    ) {
        self.cpu = cpu
        self.cpuinfo = cpuinfo
        self.memory = memory
        self.rootfs = rootfs
        self.uptime = uptime
        self.loadavg = loadavg
        self.kversion = kversion
        self.pveversion = pveversion
    }
}

/// Memory information for a node.
public struct NodeMemoryInfo: Codable, Sendable {
    /// Used memory in bytes.
    public let used: Int64?
    
    /// Total memory in bytes.
    public let total: Int64?
    
    /// Free memory in bytes.
    public let free: Int64?
    
    /// Initializes new NodeMemoryInfo.
    public init(used: Int64? = nil, total: Int64? = nil, free: Int64? = nil) {
        self.used = used
        self.total = total
        self.free = free
    }
}

/// Disk information for a node.
public struct NodeDiskInfo: Codable, Sendable {
    /// Used disk space in bytes.
    public let used: Int64?
    
    /// Total disk space in bytes.
    public let total: Int64?
    
    /// Available disk space in bytes.
    public let avail: Int64?
    
    /// Initializes new NodeDiskInfo.
    public init(used: Int64? = nil, total: Int64? = nil, avail: Int64? = nil) {
        self.used = used
        self.total = total
        self.avail = avail
    }
}
