import Foundation

/// Errors that can occur when interacting with the Proxmox API.
public enum ProxmoxError: Error {
    /// Authentication with the Proxmox API failed.
    case authenticationFailed(String)
    
    /// A network-related error occurred.
    case networkError(Error)
    
    /// The Proxmox API returned an error response.
    case apiError(code: Int, message: String)
    
    /// Failed to decode the API response.
    case decodingError(Error)
    
    /// The API response was invalid or unexpected.
    case invalidResponse
    
    /// The client is not authenticated with the Proxmox API.
    case notAuthenticated
    
    /// Invalid configuration or parameters.
    case invalidConfiguration(String)
    
    /// Resource not found.
    case resourceNotFound(String)
    
    /// Operation not supported.
    case unsupportedOperation(String)
    
    /// The client has not been initialized properly.
    case notInitialized
}

extension ProxmoxError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .notAuthenticated:
            return "Not authenticated with Proxmox API"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .resourceNotFound(let resource):
            return "Resource not found: \(resource)"
        case .unsupportedOperation(let operation):
            return "Unsupported operation: \(operation)"
        case .notInitialized:
            return "Not Initialized"
        }
    }
}
