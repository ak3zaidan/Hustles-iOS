import Foundation
import FirebaseFirestoreSwift
import Firebase

struct Tip: Identifiable, Hashable, Decodable {
    @DocumentID var id: String?
    let uid: String
    var timestamp: Timestamp
    var caption: String
    var verified: Bool?
}
