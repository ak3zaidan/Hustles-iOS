import Foundation
import Firebase
import FirebaseFirestoreSwift

struct News: Identifiable, Codable {
    @DocumentID var id: String?
    var source: String
    var title: String
    var link: String
    var imageUrl: String
    var timestamp: Timestamp
    var context: String?
    var tags: String
    var usersPick: Bool?
    var breaking: Bool?
    var views: Int?
}
