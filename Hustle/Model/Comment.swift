import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Comment: Identifiable, Decodable, Hashable {
    @DocumentID var id: String?
    var text: String
    var timestamp: Timestamp
    var username: String
    var profilephoto: String?
    var replies: Int?
}
