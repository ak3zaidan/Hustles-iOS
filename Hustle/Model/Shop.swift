import Firebase
import FirebaseFirestoreSwift

struct Shop: Identifiable, Decodable, Equatable {
    @DocumentID var id: String?
    
    let uid: String
    var username: String
    var profilephoto: String?
    let title: String
    let caption: String
    var price: Int
    let location: String
    let photos: [String]
    let tagJoined: String
    var tags: [String]?
    let promoted: Timestamp?
    let timestamp: Timestamp
}
