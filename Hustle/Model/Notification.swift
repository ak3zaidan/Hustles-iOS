import Firebase
import FirebaseFirestoreSwift

struct Notification: Identifiable, Decodable, Equatable {
    @DocumentID var id: String?
    
    let type: String
    let tagger: String
    let timestamp: Timestamp
    let caption: String
    
    let tweetID: String?
    let groupName: String?
    let newsName: String?
    let questionID: String?
    let taggerUID: String?
}
