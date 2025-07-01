import Foundation

/// Builder pattern for creating VM configurations.
public class VMConfigBuilder {
    private var config = VMConfig()
    
    /// Initializes a new VMConfigBuilder.
    public init() {}
    
    /// Sets the VM name.
    /// - Parameter name: The VM name.
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func name(_ name: String) -> Self {
        config.name = name
        return self
    }
    
    /// Sets the memory allocation.
    /// - Parameter mb: Memory in MB.
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func memory(_ mb: Int) -> Self {
        config.memory = mb
        return self
    }
    
    /// Sets the number of CPU cores.
    /// - Parameter cores: Number of CPU cores.
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func cores(_ cores: Int) -> Self {
        config.cores = cores
        return self
    }
    
    /// Sets the CPU type.
    /// - Parameter cpuType: The CPU type (e.g., "host", "kvm64").
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func cpu(_ cpuType: String) -> Self {
        config.cpu = cpuType
        return self
    }
    
    /// Adds a network interface.
    /// - Parameters:
    ///   - interface: The network interface identifier (e.g., "net0").
    ///   - configuration: The network configuration string.
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func addNetwork(interface: String, configuration: String) -> Self {
        if config.net == nil {
            config.net = [:]
        }
        config.net?[interface] = configuration
        return self
    }
    
    /// Adds a SCSI disk.
    /// - Parameters:
    ///   - device: The SCSI device identifier (e.g., "scsi0").
    ///   - configuration: The disk configuration string.
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func addSCSIDisk(device: String, configuration: String) -> Self {
        if config.scsi == nil {
            config.scsi = [:]
        }
        config.scsi?[device] = configuration
        return self
    }
    
    /// Adds a VirtIO disk.
    /// - Parameters:
    ///   - device: The VirtIO device identifier (e.g., "virtio0").
    ///   - configuration: The disk configuration string.
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func addVirtIODisk(device: String, configuration: String) -> Self {
        if config.virtio == nil {
            config.virtio = [:]
        }
        config.virtio?[device] = configuration
        return self
    }
    
    /// Sets the boot order.
    /// - Parameter bootOrder: The boot order string (e.g., "order=scsi0;ide2").
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func boot(_ bootOrder: String) -> Self {
        config.boot = bootOrder
        return self
    }
    
    /// Sets the VM description.
    /// - Parameter description: The VM description.
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func description(_ description: String) -> Self {
        config.description = description
        return self
    }
    
    /// Sets whether to start the VM on boot.
    /// - Parameter enabled: Whether to start on boot.
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func startOnBoot(_ enabled: Bool = true) -> Self {
        config.onboot = enabled
        return self
    }
    
    /// Sets VM tags.
    /// - Parameter tags: Comma-separated tags.
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func tags(_ tags: String) -> Self {
        config.tags = tags
        return self
    }
    
    /// Sets VM protection.
    /// - Parameter enabled: Whether to enable protection.
    /// - Returns: The builder instance for chaining.
    @discardableResult
    public func protection(_ enabled: Bool = true) -> Self {
        config.protection = enabled
        return self
    }
    
    /// Builds and returns the VM configuration.
    /// - Returns: The configured VMConfig instance.
    public func build() -> VMConfig {
        return config
    }
}
