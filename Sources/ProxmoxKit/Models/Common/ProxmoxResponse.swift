import Foundation

/// Generic response wrapper for Proxmox API responses.
public struct ProxmoxResponse<T: Codable>: Codable {
    /// The response data.
    public let data: T?
    
    /// Any errors returned by the API.
    public let errors: [String]?
    
    /// Success status of the response.
    public let success: Bool?
    
    /// Additional response metadata.
    public let total: Int?
    
    /// Initializes a new ProxmoxResponse.
    /// - Parameters:
    ///   - data: The response data.
    ///   - errors: Any errors returned by the API.
    ///   - success: Success status of the response.
    ///   - total: Additional response metadata.
    public init(data: T? = nil, errors: [String]? = nil, success: Bool? = nil, total: Int? = nil) {
        self.data = data
        self.errors = errors
        self.success = success
        self.total = total
    }
}

/// A simple response wrapper for array data.
public struct ProxmoxArrayResponse<T: Codable>: Codable {
    /// The array of response data.
    public let data: [T]
    
    /// Any errors returned by the API.
    public let errors: [String]?
    
    /// Success status of the response.
    public let success: Bool?
    
    /// Total number of items.
    public let total: Int?
    
    /// Initializes a new ProxmoxArrayResponse.
    /// - Parameters:
    ///   - data: The array of response data.
    ///   - errors: Any errors returned by the API.
    ///   - success: Success status of the response.
    ///   - total: Total number of items.
    public init(data: [T], errors: [String]? = nil, success: Bool? = nil, total: Int? = nil) {
        self.data = data
        self.errors = errors
        self.success = success
        self.total = total
    }
}
