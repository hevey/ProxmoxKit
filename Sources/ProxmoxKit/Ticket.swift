//
//  File.swift
//  ProxmoxKit
//
//  Created by Glenn Hevey on 12/6/2025.
//

import Foundation

public struct Ticket: Decodable {
    public let Username: String
    public let CSRFPreventionToken: String?
    public let ClusterName: String?
    public let Ticket: String?
    
    enum CodingKeys: String, CodingKey {
        case Username = "username"
        case CSRFPreventionToken = "CSRFPreventionToken"
        case ClusterName = "clustername"
        case Ticket = "ticket"
    }
}
