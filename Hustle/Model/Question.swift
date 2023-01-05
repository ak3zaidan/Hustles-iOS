import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Question: Identifiable, Equatable, Decodable {
    @DocumentID var id: String?
    var uid: String
    var username: String
    var profilePhoto: String?
    var title: String?
    var caption: String
    var votes: Int
    var answersCount: Int?
    var acceptedAnswer: String?
    var image1: String?
    var image2: String?
    var upvoteIds: [String]?
    var downVoteIds: [String]?
    var tagJoined: String?
    var tags: [String]?
    var promoted: Timestamp?
    var timestamp: Timestamp
    var commentsCount: Int?
}
