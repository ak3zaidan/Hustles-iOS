import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Reply: Identifiable, Equatable, Decodable, Hashable {
    @DocumentID var id: String?
    var uid: String?
    var username: String?
    var response: String
    var actions: Int?
    var timestamp: Timestamp
}
