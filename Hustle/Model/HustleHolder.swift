import FirebaseFirestoreSwift
import Firebase

struct HustleHolder: Identifiable, Hashable {
    var id: String
    var mainPost: Tweet
    
    var quoted: Tweet?
    var replyingTo: Tweet?
}
