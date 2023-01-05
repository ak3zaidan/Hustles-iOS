import Firebase

struct GroupY: Identifiable, Decodable, Equatable{
    let id: String
    var messages: [Tweet]?
    var last: Timestamp?
}
