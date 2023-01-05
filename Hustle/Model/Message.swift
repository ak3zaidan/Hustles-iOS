import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Message: Identifiable, Equatable, Decodable {
    @DocumentID var id: String?
    var uid_one_did_recieve: Bool
    var seen_by_reciever: Bool
    var text: String?
    var elo: String?
    var imageUrl: String?
    var timestamp: Timestamp
    var sentAImage: Bool?
    var file: String?
    var emoji: String?
    
    var replyFrom: String?
    var replyText: String?
    var replyImage: String?
    var replyELO: String?
    var replyFile: String?
    var audioURL: String?
    var videoURL: String?
    
    var replyAudio: String?
    var replyVideo: String?
    
    var lat: Double?
    var long: Double?
    var name: String?
    var async: Bool?
    var pinmap: String?
    var stories: [Story]? = nil
    var gotStories: [String]? = nil
}
