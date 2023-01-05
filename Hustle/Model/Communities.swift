import Foundation
import Firebase
import FirebaseFirestoreSwift

struct CommHolder: Identifiable, Equatable {
    var id: UUID = UUID()
    var new: [Tweet]
    var lastNew: Timestamp?
    var top: [Tweet]
    var lastTop: Int?
    var community: Communities
}

struct Communities: Identifiable, Equatable, Decodable, Hashable {
    @DocumentID var id: String?
    var image: String
    var name: String
    var description: String
    var membersCount: Int
}
