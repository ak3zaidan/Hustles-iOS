import Firebase

struct GroupX: Identifiable, Decodable, Equatable, Hashable {
    let id: String
    var title: String
    var imageUrl: String
    var last: Timestamp?
    var rules: String?
    var members: [String]
    var membersCount: Int
    var publicstatus: Bool
    var leaders: [String]
    var desc: String
    var users: [User]?
    var messages: [GroupMessages]?
    var squares: [String]?
    var lastM: Tweet?
}

struct GroupMessages: Identifiable, Decodable, Equatable, Hashable {
    let id: String
    var messages: [Tweet]
    var timestamp: Timestamp?
}
