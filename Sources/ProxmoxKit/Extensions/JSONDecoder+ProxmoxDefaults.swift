import Foundation

/// Extensions for JSONDecoder to handle Proxmox-specific data formats.
extension JSONDecoder {
    /// Creates a JSONDecoder configured for Proxmox API responses.
    /// - Returns: A configured JSONDecoder instance.
    static func proxmoxDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Handle different date formats used by Proxmox
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        // Handle missing or null values gracefully
        decoder.keyDecodingStrategy = .useDefaultKeys
        
        return decoder
    }
}

/// Extensions for JSONEncoder to handle Proxmox-specific data formats.
extension JSONEncoder {
    /// Creates a JSONEncoder configured for Proxmox API requests.
    /// - Returns: A configured JSONEncoder instance.
    static func proxmoxEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        
        // Use consistent date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        encoder.keyEncodingStrategy = .useDefaultKeys
        
        return encoder
    }
}
