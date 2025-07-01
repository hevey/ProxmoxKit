import Foundation

/// HTTP client for making requests to the Proxmox API.
public class HTTPClient: @unchecked Sendable {
    /// The URLSession used for networking requests.
    private let session: URLSession
    
    /// The session manager for authentication.
    private let sessionManager: ProxmoxSession
    
    /// Initializes a new HTTPClient.
    /// - Parameters:
    ///   - session: The URLSession to use for requests.
    ///   - sessionManager: The session manager for authentication.
    public init(session: URLSession, sessionManager: ProxmoxSession) {
        self.session = session
        self.sessionManager = sessionManager
    }
    
    /// Sends an HTTP GET request with all attached cookies and returns response data.
    /// - Parameter url: The URL to send the GET request to.
    /// - Returns: The response data from the server.
    /// - Throws: An error if the request fails or no data is returned.
    public func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add Proxmox headers (no CSRF token needed for GET requests)
        request.addProxmoxHeaders()
        
        sessionManager.attachCookies(to: &request)
        
        let (data, response) = try await performRequest(request)
        try validateResponse(response)
        return data
    }
    
    /// Sends an HTTP POST request with a body and attached cookies.
    /// - Parameters:
    ///   - url: The URL to send the POST request to.
    ///   - body: The HTTP body data to include in the request.
    ///   - contentType: The Content-Type header value.
    /// - Returns: A tuple containing the response data and URLResponse.
    /// - Throws: An error if the request fails or no data is returned.
    public func post(_ url: URL, body: Data?, contentType: String? = nil) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let body = body {
            request.httpBody = body
        }
        
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        // Add Proxmox headers including CSRF token for write operations
        let csrfToken = sessionManager.currentTicket?.CSRFPreventionToken
        request.addProxmoxHeaders(csrfToken: csrfToken)
        
        sessionManager.attachCookies(to: &request)
        
        let (data, response) = try await performRequest(request)
        try validateResponse(response)
        return (data, response)
    }
    
    /// Sends an HTTP PUT request with a body and attached cookies.
    /// - Parameters:
    ///   - url: The URL to send the PUT request to.
    ///   - body: The HTTP body data to include in the request.
    ///   - contentType: The Content-Type header value.
    /// - Returns: A tuple containing the response data and URLResponse.
    /// - Throws: An error if the request fails or no data is returned.
    public func put(_ url: URL, body: Data?, contentType: String? = nil) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        if let body = body {
            request.httpBody = body
        }
        
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        // Add Proxmox headers including CSRF token for write operations
        let csrfToken = sessionManager.currentTicket?.CSRFPreventionToken
        request.addProxmoxHeaders(csrfToken: csrfToken)
        
        sessionManager.attachCookies(to: &request)
        
        let (data, response) = try await performRequest(request)
        try validateResponse(response)
        return (data, response)
    }
    
    /// Sends an HTTP DELETE request with attached cookies.
    /// - Parameter url: The URL to send the DELETE request to.
    /// - Returns: A tuple containing the response data and URLResponse.
    /// - Throws: An error if the request fails or no data is returned.
    public func delete(_ url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add Proxmox headers including CSRF token for write operations
        let csrfToken = sessionManager.currentTicket?.CSRFPreventionToken
        request.addProxmoxHeaders(csrfToken: csrfToken)
        
        sessionManager.attachCookies(to: &request)
        
        let (data, response) = try await performRequest(request)
        try validateResponse(response)
        return (data, response)
    }
    
    /// Performs the actual HTTP request with backward compatibility.
    /// - Parameter request: The URLRequest to perform.
    /// - Returns: A tuple containing the response data and URLResponse.
    /// - Throws: An error if the request fails.
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, macOS 12.0, *) {
            var temp: (Data, URLResponse)
            do {
                temp = try await session.data(for: request)
            } catch {
                print(error)
                throw error
            }
            return temp
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let task = session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: ProxmoxError.networkError(error))
                    } else if let data = data, let response = response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: ProxmoxError.invalidResponse)
                    }
                }
                task.resume()
            }
        }
    }
    
    /// Validates the HTTP response and throws appropriate errors.
    /// - Parameter response: The URLResponse to validate.
    /// - Throws: ProxmoxError if the response indicates an error.
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProxmoxError.invalidResponse
        }
        
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200...299:
            // Success
            break
        case 401:
            // Authentication failure - provide more context
            let sessionInfo = sessionManager.debugInfo
            throw ProxmoxError.authenticationFailed("Unauthorized - Session: \(sessionInfo)")
        case 403:
            // Permission denied - may indicate CSRF token issues
            let hasCSRF = sessionManager.currentTicket?.CSRFPreventionToken != nil
            throw ProxmoxError.authenticationFailed("Forbidden - CSRF token present: \(hasCSRF)")
        case 404:
            throw ProxmoxError.resourceNotFound("Resource not found")
        case 400...499:
            throw ProxmoxError.apiError(code: statusCode, message: "Client error")
        case 500...599:
            throw ProxmoxError.apiError(code: statusCode, message: "Server error")
        default:
            throw ProxmoxError.apiError(code: statusCode, message: "Unknown error")
        }
    }
}
