import Foundation

/// Extensions for URLRequest to handle Proxmox-specific functionality.
extension URLRequest {
    /// Adds Proxmox-specific headers to the request.
    /// - Parameter csrfToken: Optional CSRF token for write operations.
    mutating func addProxmoxHeaders(csrfToken: String? = nil) {
        // Set common headers for Proxmox API
        setValue("application/json", forHTTPHeaderField: "Accept")
        setValue("ProxmoxKit/0.1", forHTTPHeaderField: "User-Agent")
        
        // Add CSRF token if provided (required for some operations)
        if let token = csrfToken {
            setValue(token, forHTTPHeaderField: "CSRFPreventionToken")
        }
    }
}

/// Extensions for URL to build Proxmox API endpoints.
extension URL {
    /// Builds a Proxmox API URL with the given path components.
    /// - Parameter path: The API path components.
    /// - Returns: The complete API URL.
    func proxmoxAPIURL(path: String) -> URL {
        return self.appendingPathComponent("api2/json/\(path)")
    }
}
