import Foundation

/// Base class for all Proxmox API services.
public class BaseService {
    /// The HTTP client for making requests.
    internal let httpClient: HTTPClient
    
    /// The session manager for authentication.
    internal let sessionManager: ProxmoxSession
    
    /// The base URL for the Proxmox API.
    internal let baseURL: URL
    
    /// Initializes a new BaseService.
    /// - Parameters:
    ///   - httpClient: The HTTP client to use.
    ///   - sessionManager: The session manager.
    ///   - baseURL: The base URL of the Proxmox API.
    public init(httpClient: HTTPClient, sessionManager: ProxmoxSession, baseURL: URL) {
        self.httpClient = httpClient
        self.sessionManager = sessionManager
        self.baseURL = baseURL
    }
    
    /// Builds a URL for the given API path.
    /// - Parameter path: The API path (e.g., "nodes/pve1/qemu").
    /// - Returns: The complete URL.
    internal func buildURL(path: String) -> URL {
        return baseURL.appendingPathComponent("api2/json/\(path)")
    }
    
    /// Ensures the client is authenticated before making requests.
    /// - Throws: ProxmoxError.notAuthenticated if not authenticated.
    internal func ensureAuthenticated() throws {
        guard sessionManager.isAuthenticated else {
            throw ProxmoxError.notAuthenticated
        }
    }
    
    /// Decodes a JSON response into the specified type.
    /// - Parameters:
    ///   - data: The response data to decode.
    ///   - type: The type to decode to.
    /// - Returns: The decoded object.
    /// - Throws: ProxmoxError.decodingError if decoding fails.
    internal func decode<T: Codable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            let decoder = JSONDecoder()
            // Configure decoder for Proxmox-specific date formats if needed
            return try decoder.decode(type, from: data)
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }
    
    /// Encodes an object to JSON data.
    /// - Parameter object: The object to encode.
    /// - Returns: The encoded JSON data.
    /// - Throws: ProxmoxError.decodingError if encoding fails.
    internal func encode<T: Codable>(_ object: T) throws -> Data {
        do {
            let encoder = JSONEncoder()
            return try encoder.encode(object)
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }
    
    /// Converts a dictionary to URL-encoded form data.
    /// - Parameter parameters: The parameters to encode.
    /// - Returns: The URL-encoded data.
    internal func encodeFormData(_ parameters: [String: Any]) -> Data? {
        let formData = parameters.compactMap { key, value in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
        
        return formData.data(using: .utf8)
    }
}
