import Foundation

/// Manages authentication session state for Proxmox API interactions.
public class ProxmoxSession: @unchecked Sendable {
    /// The base URL of the Proxmox API endpoint.
    let baseURL: URL
    
    /// Stored cookies from the last authentication response, used for session management.
    private let cookieLock = NSLock()
    private var _cookies: [HTTPCookie] = []
    
    /// Thread-safe access to cookies.
    public var cookies: [HTTPCookie] {
        cookieLock.lock()
        defer { cookieLock.unlock() }
        return _cookies
    }
    
    /// The current authentication ticket, if any.
    private let ticketLock = NSLock()
    private var _currentTicket: Ticket?
    
    /// Thread-safe access to the current ticket.
    public var currentTicket: Ticket? {
        ticketLock.lock()
        defer { ticketLock.unlock() }
        return _currentTicket
    }
    
    /// Whether the session is currently authenticated.
    public var isAuthenticated: Bool {
        let ticket = currentTicket
        let cookiesExist = !cookies.isEmpty
        return ticket != nil && cookiesExist
    }
    
    /// Debug information about the current session state.
    public var debugInfo: String {
        let ticket = currentTicket
        let cookieCount = cookies.count
        let hasCSRF = ticket?.CSRFPreventionToken != nil
        return "Session Debug: authenticated=\(isAuthenticated), cookies=\(cookieCount), hasCSRF=\(hasCSRF), ticket=\(ticket?.ticket?.prefix(10) ?? "nil")..."
    }
    
    /// Initializes a new ProxmoxSession.
    /// - Parameter baseURL: The base URL of the Proxmox API.
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    /// Stores authentication cookies from a successful login.
    /// - Parameter ticket: The authentication ticket from the login response.
    public func storeAuthenticationCookies(from ticket: Ticket) {
        guard let cookieDomain = baseURL.host else { return }
        
        // Determine if we should mark the cookie as secure based on the URL scheme
        let isSecure = baseURL.scheme?.lowercased() == "https"
        
        var cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .domain: cookieDomain,
            .path: "/",
            .name: "PVEAuthCookie",
            .value: ticket.ticket ?? "",
            .expires: Date(timeIntervalSinceNow: 3600),
            .discard: "FALSE"
        ]
        
        // Only set secure flag for HTTPS connections
        if isSecure {
            cookieProperties[.secure] = "TRUE"
        }
        
        guard let cookie = HTTPCookie(properties: cookieProperties) else { return }
        
        cookieLock.lock()
        defer { cookieLock.unlock() }
        
        // Remove existing cookie with same name, domain, and path before adding
        _cookies.removeAll { existingCookie in
            existingCookie.name == cookie.name &&
            existingCookie.domain == cookie.domain &&
            existingCookie.path == cookie.path
        }
        _cookies.append(cookie)
        
        ticketLock.lock()
        defer { ticketLock.unlock() }
        _currentTicket = ticket
    }
    
    /// Clears all authentication data.
    public func clearAuthentication() {
        cookieLock.lock()
        defer { cookieLock.unlock() }
        _cookies.removeAll()
        
        ticketLock.lock()
        defer { ticketLock.unlock() }
        _currentTicket = nil
    }
    
    /// Attaches all stored cookies relevant for the request's URL to the request's Cookie header.
    /// - Parameter request: The URLRequest to modify by adding the appropriate Cookie header.
    public func attachCookies(to request: inout URLRequest) {
        let currentCookies = cookies
        guard !currentCookies.isEmpty, let requestURL = request.url else { return }
        
        // Filter cookies whose domain matches the request host (including subdomain matching)
        let relevantCookies = currentCookies.filter { cookie in
            guard let host = requestURL.host else { return false }
            if cookie.domain.hasPrefix(".") {
                // Domain cookies starting with '.' are valid for subdomains
                return host.hasSuffix(cookie.domain)
            } else {
                // Exact domain match
                return cookie.domain == host
            }
        }
        
        guard !relevantCookies.isEmpty else { return }
        
        // Create cookie header string as "name=value; name2=value2"
        let cookieHeader = relevantCookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
    }
}
