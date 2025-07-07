import Foundation

/// URLSessionDelegate that bypasses SSL certificate validation.
/// Used when validateSSL is set to false in ProxmoxConfig.
private final class InsecureURLSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Accept any certificate when SSL validation is disabled
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        // For other authentication methods, use default handling
        completionHandler(.performDefaultHandling, nil)
    }
}

/// Main client for interacting with the Proxmox Virtual Environment API.
///
/// `ProxmoxClient` provides a service-oriented architecture for managing Proxmox VE resources
/// including nodes, virtual machines, containers, and cluster operations. It handles authentication,
/// session management, and provides type-safe access to the Proxmox API.
///
/// ## Usage
///
/// ```swift
/// let config = ProxmoxConfig(
///     host: "https://proxmox.example.com:8006",
///     username: "root@pam",
///     password: "password"
/// )
/// 
/// let client = ProxmoxClient(config: config)
/// try await client.authenticate(username: config.username, password: config.password)
/// 
/// // Use services to interact with Proxmox
/// let nodes = try await client.nodes.list()
/// ```
///
/// ## Topics
///
/// ### Creating a Client
/// - ``init(config:)``
/// - ``create(host:port:useHTTPS:)``
///
/// ### Authentication
/// - ``authenticate(username:password:)``
/// - ``isAuthenticated``
///
/// ### Services
/// - ``nodes``
/// - ``vms``
/// - ``containers``
/// - ``cluster``
public class ProxmoxClient: @unchecked Sendable {
    /// Configuration for the client.
    public let config: ProxmoxConfig
    
    /// Session manager for authentication.
    private let sessionManager: ProxmoxSession
    
    /// HTTP client for making requests.
    private let httpClient: HTTPClient
    
    /// Service for node operations.
    public lazy var nodes = NodeService(
        httpClient: httpClient,
        sessionManager: sessionManager,
        baseURL: config.baseURL
    )
    
    /// Service for virtual machine operations.
    public lazy var vms = VMService(
        httpClient: httpClient,
        sessionManager: sessionManager,
        baseURL: config.baseURL
    )
    
    /// Service for container operations.
    public lazy var containers = ContainerService(
        httpClient: httpClient,
        sessionManager: sessionManager,
        baseURL: config.baseURL
    )
    
    /// Service for cluster operations.
    public lazy var cluster = ClusterService(
        httpClient: httpClient,
        sessionManager: sessionManager,
        baseURL: config.baseURL
    )
    
    /// Whether the client is currently authenticated.
    public var isAuthenticated: Bool {
        return sessionManager.isAuthenticated
    }
    
    /// Current authentication ticket, if any.
    public var currentTicket: Ticket? {
        return sessionManager.currentTicket
    }
    
    /// Debug information about the current session state.
    public var sessionDebugInfo: String {
        return sessionManager.debugInfo
    }
    
    /// Initializes a new ProxmoxClient.
    /// - Parameter config: The configuration for the client.
    public init(config: ProxmoxConfig) {
        self.config = config
        self.sessionManager = ProxmoxSession(baseURL: config.baseURL)
        
        // Configure URLSession based on config
        let sessionConfig = config.sessionConfiguration
        sessionConfig.timeoutIntervalForRequest = config.timeout
        sessionConfig.timeoutIntervalForResource = config.timeout * 2
        
        // Create URLSession with optional SSL validation
        let urlSession: URLSession
        if config.validateSSL {
            urlSession = URLSession(configuration: sessionConfig)
        } else {
            // Create session with delegate that bypasses SSL validation
            let delegate = InsecureURLSessionDelegate()
            urlSession = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
        }
        
        self.httpClient = HTTPClient(session: urlSession, sessionManager: sessionManager)
    }
    
    /// Convenience initializer with just a base URL.
    /// - Parameter baseURL: The base URL of the Proxmox API.
    public convenience init(baseURL: URL) {
        let config = ProxmoxConfig(baseURL: baseURL)
        self.init(config: config)
    }
    
    /// Authenticates with the Proxmox API using the provided username and password.
    /// - Parameters:
    ///   - username: The username to authenticate with (format: user@realm, e.g., "root@pam").
    ///   - password: The password to authenticate with.
    /// - Returns: A Ticket object containing authentication details.
    /// - Throws: ProxmoxError if authentication fails.
    public func authenticate(username: String, password: String) async throws -> Ticket {
        let loginURL = config.baseURL.appendingPathComponent("api2/json/access/ticket")
        let params = "username=\(username)&password=\(password)"
        let body = params.data(using: .utf8)
        
        do {
            let (data, _) = try await httpClient.post(loginURL, body: body, contentType: "application/x-www-form-urlencoded")
            
            guard !data.isEmpty else {
                throw ProxmoxError.authenticationFailed("No data returned from authentication")
            }
            
            struct TicketResponse: Decodable {
                let data: Ticket
            }
            
            let ticketResponse = try JSONDecoder().decode(TicketResponse.self, from: data)
            
            // Store authentication cookies
            sessionManager.storeAuthenticationCookies(from: ticketResponse.data)
            
            return ticketResponse.data
            
        } catch let error as ProxmoxError {
            throw error
        } catch {
            throw ProxmoxError.authenticationFailed("Authentication failed: \(error.localizedDescription)")
        }
    }
    
    /// Clears all authentication data.
    public func logout() {
        sessionManager.clearAuthentication()
    }
}
