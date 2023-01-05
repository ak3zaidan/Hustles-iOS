import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Answer: Identifiable, Equatable, Decodable {
    @DocumentID var id: String?
    var username: String
    var profilePhoto: String?
    var caption: String
    var image: String?
    var votes: Int?
    var upvoteIds: [String]?
    var downVoteIds: [String]?
    var timestamp: Timestamp
    var commentsCount: Int?
}
