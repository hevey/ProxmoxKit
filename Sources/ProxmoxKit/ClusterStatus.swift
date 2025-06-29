import Foundation

/// Info about the cluster and its members.
public struct ClusterNode: Decodable {
    public let name: String
    public let nodeid: Int
    public let online: Int?
    public let quorum: Int?
    public let votes: Int?
    public let type: String?
}

public struct ClusterStatus: Decodable {
    public let data: [ClusterNode]
}
