import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Convo: Identifiable, Equatable, Decodable {
    @DocumentID var id: String?
    var uid_one: String
    var uid_two: String
    var uid_one_active: Bool
    var uid_two_active: Bool
    var encrypted: Bool
    var verified: Bool?
    
    var uid_one_sharing_location: Bool?
    var uid_two_sharing_location: Bool?
    var chatPins: [String]?
}
