import Foundation

/// Configuration for the Proxmox client.
public struct ProxmoxConfig: Sendable {
    /// The base URL of the Proxmox API endpoint.
    public let baseURL: URL
    
    /// Request timeout interval in seconds.
    public let timeout: TimeInterval
    
    /// Number of retry attempts for failed requests.
    public let retryCount: Int
    
    /// Whether to validate SSL certificates.
    public let validateSSL: Bool
    
    /// Custom URLSession configuration.
    public let sessionConfiguration: URLSessionConfiguration
    
    /// Default configuration with common settings.
    public static let `default` = ProxmoxConfig(
        baseURL: URL(string: "https://localhost:8006")!,
        timeout: 30,
        retryCount: 3,
        validateSSL: true,
        sessionConfiguration: .default
    )
    
    /// Initializes a new ProxmoxConfig.
    /// - Parameters:
    ///   - baseURL: The base URL of the Proxmox API.
    ///   - timeout: Request timeout interval. Defaults to 30 seconds.
    ///   - retryCount: Number of retry attempts. Defaults to 3.
    ///   - validateSSL: Whether to validate SSL certificates. Defaults to true.
    ///   - sessionConfiguration: URLSession configuration. Defaults to .default.
    public init(
        baseURL: URL,
        timeout: TimeInterval = 30,
        retryCount: Int = 3,
        validateSSL: Bool = true,
        sessionConfiguration: URLSessionConfiguration = .default
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.retryCount = retryCount
        self.validateSSL = validateSSL
        self.sessionConfiguration = sessionConfiguration
    }
}
