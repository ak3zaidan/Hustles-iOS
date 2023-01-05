import Firebase
import FirebaseFirestoreSwift

struct Tweet: Identifiable, Decodable, Equatable, Hashable {
    @DocumentID var id: String?
    
    var caption: String
    let timestamp: Timestamp
    let uid: String
    var username: String
    var fullname: String?
    var profilephoto: String?
    var likes: [String]?
    var hashtags: [String]?
    var comments: Int?
    var tag: String?
    var promoted: Timestamp?
    var video: String?
    let verified: Bool?
    let veriUser: Bool?
    var rating: Double?

    var start: Timestamp?
    var end: Timestamp?
    var web: String?
    var appIdentifier: String?
    var image: String?
    var plus: Bool?
    var stars: Double?
    
    var countSmile: Int?
    var countCry: Int?
    var countThumb: Int?
    var countBless: Int?
    var countHeart: Int?
    var countQuestion: Int?
    
    var replyFrom: String?
    var replyText: String?
    var replyImage: String?
    
    var audioURL: String?
    var videoURL: String?
    var fileURL: String?
    var sLoc: String?
    var bLoc: String?
    var lat: Double?
    var long: Double?
    var contentArray: [String]?
    
    var choice1: String?
    var choice2: String?
    var choice3: String?
    var choice4: String?
    var count1: Int?
    var count2: Int?
    var count3: Int?
    var count4: Int?
    var voted: [String]?
    var views: Int?
    
    var replyFile: String?
    var replyAudio: String?
    var replyVideo: String?
    var async: Bool?
    var yelpID: String?
    var newsID: String?
    
    var stories: [Story]? = nil
    var gotStories: [String]? = nil
    
    
    var replyToPostId: String?
    var quotedPostId: String?
    var repostedPostId: String?
    var aiCategory: [String]?
}
