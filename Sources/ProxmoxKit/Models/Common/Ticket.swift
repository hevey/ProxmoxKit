import Foundation

/// Represents an authentication ticket returned by the Proxmox API.
public struct Ticket: Decodable {
    /// The authenticated username.
    public let username: String
    
    /// The CSRF prevention token for write operations.
    public let CSRFPreventionToken: String?
    
    /// The cluster name, if available.
    public let clustername: String?
    
    /// The authentication ticket string.
    public let ticket: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case CSRFPreventionToken
        case clustername
        case ticket
    }
}
