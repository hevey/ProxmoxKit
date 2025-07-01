import Foundation

/// Represents a Virtual Machine in Proxmox.
public struct VirtualMachine: Codable, Identifiable, Sendable {
    /// The unique VM ID.
    public let id: Int
    
    /// The VMID (same as id for compatibility).
    public var vmid: Int { id }
    
    /// The VM name.
    public let name: String?
    
    /// The node where the VM is located.
    public let node: String?
    
    /// Current status of the VM.
    public let status: VMStatus?
    
    /// VM type (usually "qemu").
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
    
    /// Agent enabled flag.
    public let agent: Bool?
    
    /// Tags associated with the VM.
    public let tags: String?
    
    /// Initializes a new VirtualMachine.
    public init(
        id: Int,
        name: String? = nil,
        node: String? = nil,
        status: VMStatus? = nil,
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
        agent: Bool? = nil,
        tags: String? = nil
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
        self.agent = agent
        self.tags = tags
    }
    
    /// Whether the VM is currently running.
    public var isRunning: Bool {
        return status == .running
    }
    
    /// Whether the VM is stopped.
    public var isStopped: Bool {
        return status == .stopped
    }
    
    /// Whether the VM is paused.
    public var isPaused: Bool {
        return status == .paused
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "vmid"
        case name, node, status, type, maxmem, cpus, maxdisk
        case cpu, mem, disk, netin, netout, diskread, diskwrite
        case uptime, template, agent, tags
    }
}

/// Virtual Machine status enumeration.
public enum VMStatus: String, Codable, CaseIterable, Sendable {
    case running
    case stopped
    case paused
    case suspended
    case prelaunch
    case unknown
    
    /// Initializes from decoder, handling unknown cases.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let statusString = try container.decode(String.self)
        self = VMStatus(rawValue: statusString) ?? .unknown
    }
}

/// Configuration for creating or updating a Virtual Machine.
public struct VMConfig: Codable, Sendable {
    /// VM name.
    public var name: String?
    
    /// Memory allocation in MB.
    public var memory: Int?
    
    /// Number of CPU cores.
    public var cores: Int?
    
    /// CPU type.
    public var cpu: String?
    
    /// Network interfaces.
    public var net: [String: String]?
    
    /// Storage configuration.
    public var scsi: [String: String]?
    public var virtio: [String: String]?
    public var ide: [String: String]?
    public var sata: [String: String]?
    
    /// Boot order.
    public var boot: String?
    
    /// VM description.
    public var description: String?
    
    /// Whether to start VM on boot.
    public var onboot: Bool?
    
    /// VM tags.
    public var tags: String?
    
    /// Protection flag.
    public var protection: Bool?
    
    /// Initializes a new VMConfig.
    public init(
        name: String? = nil,
        memory: Int? = nil,
        cores: Int? = nil,
        cpu: String? = nil,
        net: [String: String]? = nil,
        scsi: [String: String]? = nil,
        virtio: [String: String]? = nil,
        ide: [String: String]? = nil,
        sata: [String: String]? = nil,
        boot: String? = nil,
        description: String? = nil,
        onboot: Bool? = nil,
        tags: String? = nil,
        protection: Bool? = nil
    ) {
        self.name = name
        self.memory = memory
        self.cores = cores
        self.cpu = cpu
        self.net = net
        self.scsi = scsi
        self.virtio = virtio
        self.ide = ide
        self.sata = sata
        self.boot = boot
        self.description = description
        self.onboot = onboot
        self.tags = tags
        self.protection = protection
    }
}
