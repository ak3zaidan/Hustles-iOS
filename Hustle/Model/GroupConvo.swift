import Foundation
import Firebase
import FirebaseFirestoreSwift

struct GroupConvo: Identifiable, Equatable, Decodable {
    @DocumentID var id: String?
    var groupName: String?
    var allUsersUID: [String]
    var activeUsers: [String]?
    var users: [User]?
    var timestamp: Timestamp
    var chatText: String?
    var lastM: GroupMessage?
    var messages: [GroupMessage]?
    var photo: String?
    
    var sharingLocationUIDS: [String]?
    var chatPins: [String]?
}

struct GroupMessage: Identifiable, Equatable, Decodable {
    @DocumentID var id: String?
    var seen: Bool?
    
    var text: String?
    var imageUrl: String?
    var audioURL: String?
    var videoURL: String?
    var file: String?
    
    var replyFrom: String?
    var replyText: String?
    var replyImage: String?
    var replyFile: String?
    var replyAudio: String?
    var replyVideo: String?
    
    var countSmile: Int?
    var countCry: Int?
    var countThumb: Int?
    var countBless: Int?
    var countHeart: Int?
    var countQuestion: Int?

    var normal: Bool?
    var timestamp: Timestamp
    var async: Bool?
    
    var lat: Double?
    var long: Double?
    var name: String?
    
    var choice1: String?
    var choice2: String?
    var choice3: String?
    var choice4: String?
    var count1: Int?
    var count2: Int?
    var count3: Int?
    var count4: Int?
    var voted: [String]?
    var pinmap: String?
    
    var stories: [Story]? = nil
    var gotStories: [String]? = nil
}
