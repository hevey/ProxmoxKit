import Foundation

/// An asynchronous client for interacting with the Proxmox API, managing session cookies for authentication and subsequent requests.
public class ProxmoxKit {
    /// The base URL of the Proxmox API endpoint.
    let url: URL
    /// The URLSession used for networking requests.
    let session: URLSession
    
    /// Stored cookies from the last authentication response, used for session management.
    private(set) var cookies: [HTTPCookie] = []
    
    /// Initializes a new ProxmoxKit instance.
    /// - Parameters:
    ///   - url: The base URL of the Proxmox API.
    ///   - session: The URLSession instance to use for network requests. Defaults to `.shared`.
    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }
    
    /// Authenticates with the Proxmox API using the provided username and password, returning an authentication ticket.
    ///
    /// On successful authentication, stores a cookie representing the Proxmox ticket to be used for subsequent requests.
    ///
    /// - Parameters:
    ///   - username: The username to authenticate with.
    ///   - password: The password to authenticate with.
    /// - Returns: A `Ticket` object containing authentication details.
    /// - Throws: An error if authentication fails, no data is returned, or decoding of the response fails.
    public func authenticate(username: String, password: String) async throws -> Ticket {
        let loginURL = url.appendingPathComponent("api2/json/access/ticket")
        let params = "username=\(username)&password=\(password)"
        let body = params.data(using: .utf8)
        
        let (data, _) = try await httpPost(loginURL, body: body, contentType: "application/x-www-form-urlencoded")
        
        guard !data.isEmpty else {
            throw NSError(domain: "ProxmoxKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned"])
        }
        
        struct TicketResponse: Decodable {
            let data: Ticket
        }
        
        do {
            let ticketResponse = try JSONDecoder().decode(TicketResponse.self, from: data)
            
            // After successful decoding:
            // Create a cookie representing the Proxmox ticket and store it in the cookies property
            let ticketValue = ticketResponse.data.Ticket
            if let cookieDomain = url.host {
                let cookie = HTTPCookie(properties: [
                    .domain: cookieDomain,
                    .path: "/",
                    .name: "PVEAuthCookie",
                    .value: ticketValue,
                    .secure: "TRUE",
                    .expires: Date(timeIntervalSinceNow: 3600),
                    .discard: "FALSE"
                ])
                if let cookie = cookie {
                    // Remove existing cookie with same name, domain, and path before adding
                    self.cookies.removeAll(where: {
                        $0.name == cookie.name &&
                        $0.domain == cookie.domain &&
                        $0.path == cookie.path
                    })
                    self.cookies.append(cookie)
                }
            }
            
            return ticketResponse.data
        } catch {
            throw NSError(domain: "ProxmoxKit", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode Ticket: \(error.localizedDescription)"])
        }
    }
    
    /// Fetches cluster resources from the Proxmox API.
    ///
    /// This method sends a GET request to the `/api2/json/cluster/resources` endpoint,
    /// attaching all stored cookies (including the `PVEAuthCookie`) to maintain session state.
    ///
    /// - Returns: An array of `ProxmoxResource` representing the cluster resources.
    /// - Throws: An error if the request fails, no data is returned, or decoding of the response fails.
    public func getResources() async throws -> [ProxmoxResource] {
        let resourcesURL = url.appendingPathComponent("/api2/json/cluster/resources")
        let data = try await httpGet(resourcesURL)
        print(String(data: data, encoding: .utf8))
        let resourceList = try JSONDecoder().decode(ProxmoxResourceList.self, from: data)
        return resourceList.data
    }
    
    /// Attaches all stored cookies relevant for the request's URL to the request's Cookie header.
    ///
    /// Cookies are filtered based on domain matching, including handling of domain cookies that start with a dot (`.`) indicating subdomain validity.
    /// Constructs a Cookie header string in the format `name=value; name2=value2` and sets it on the request.
    ///
    /// - Parameter request: The `URLRequest` to modify by adding the appropriate `Cookie` header.
    private func attachCookies(to request: inout URLRequest) {
        guard !cookies.isEmpty, let url = request.url else { return }
        // Filter cookies whose domain matches the request host (including subdomain matching)
        let relevantCookies = cookies.filter { cookie in
            guard let host = url.host else { return false }
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
    
    /// Sends an HTTP GET request with all attached cookies and returns response data.
    ///
    /// - Parameter url: The URL to send the GET request to.
    /// - Returns: The response data from the server.
    /// - Throws: An error if the request fails or no data is returned.
    private func httpGet(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        attachCookies(to: &request)
        let data: Data
        if #available(iOS 15.0, macOS 12.0, *) {
            (data, _) = try await session.data(for: request)
        } else {
            data = try await withCheckedThrowingContinuation { continuation in
                let task = session.dataTask(with: request) { data, _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let data = data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: NSError(domain: "ProxmoxKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned"]))
                    }
                }
                task.resume()
            }
        }
        return data
    }
    
    /// Sends an HTTP POST request with a body and attached cookies. Returns response data and URLResponse.
    ///
    /// - Parameters:
    ///   - url: The URL to send the POST request to.
    ///   - body: The HTTP body data to include in the request.
    ///   - contentType: The Content-Type header value. Defaults to `nil`.
    /// - Returns: A tuple containing the response data and URLResponse.
    /// - Throws: An error if the request fails or no data is returned.
    private func httpPost(_ url: URL, body: Data?, contentType: String? = nil) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let body = body {
            request.httpBody = body
        }
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        attachCookies(to: &request)
        let data: Data
        let response: URLResponse
        if #available(iOS 15.0, macOS 12.0, *) {
            (data, response) = try await session.data(for: request)
        } else {
            (data, response) = try await withCheckedThrowingContinuation { continuation in
                let task = session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let data = data, let response = response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: NSError(domain: "ProxmoxKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned"]))
                    }
                }
                task.resume()
            }
        }
        return (data, response)
    }
    
    /// Sends an HTTP PUT request with a body and attached cookies. Returns response data and URLResponse.
    ///
    /// - Parameters:
    ///   - url: The URL to send the PUT request to.
    ///   - body: The HTTP body data to include in the request.
    ///   - contentType: The Content-Type header value. Defaults to `nil`.
    /// - Returns: A tuple containing the response data and URLResponse.
    /// - Throws: An error if the request fails or no data is returned.
    private func httpPut(_ url: URL, body: Data?, contentType: String? = nil) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        if let body = body {
            request.httpBody = body
        }
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        attachCookies(to: &request)
        let data: Data
        let response: URLResponse
        if #available(iOS 15.0, macOS 12.0, *) {
            (data, response) = try await session.data(for: request)
        } else {
            (data, response) = try await withCheckedThrowingContinuation { continuation in
                let task = session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let data = data, let response = response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: NSError(domain: "ProxmoxKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned"]))
                    }
                }
                task.resume()
            }
        }
        return (data, response)
    }
    
    /// Sends an HTTP DELETE request with attached cookies. Returns response data and URLResponse.
    ///
    /// - Parameter url: The URL to send the DELETE request to.
    /// - Returns: A tuple containing the response data and URLResponse.
    /// - Throws: An error if the request fails or no data is returned.
    private func httpDelete(_ url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        attachCookies(to: &request)
        let data: Data
        let response: URLResponse
        if #available(iOS 15.0, macOS 12.0, *) {
            (data, response) = try await session.data(for: request)
        } else {
            (data, response) = try await withCheckedThrowingContinuation { continuation in
                let task = session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let data = data, let response = response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: NSError(domain: "ProxmoxKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned"]))
                    }
                }
                task.resume()
            }
        }
        return (data, response)
    }
}
