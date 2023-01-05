import FirebaseFirestoreSwift
import Firebase

struct User: Identifiable, Decodable, Hashable {
    @DocumentID var id: String?
    let username: String
    var fullname: String
    var profileImageUrl: String?
    let email: String
    var zipCode: String
    var following: [String]
    var badges: [String]
    var elo: Int
    var followers: Int
    var completedjobs: Int
    var verifiedTips: Int
    var groupIdentifier: [String]?
    var pinnedGroups: [String]
    var jobPointer: [String]
    var shopPointer: [String]
    var alertsShown: String
    var likedHustles: [String]
    let dev: String?
    let timestamp: Timestamp
    let verified: Bool?
    let publicKey: String
    var myMessages: [String]
    var userCountry: String
    var blockedUsers: [String]?
    var userBackground: String?
    var sold: Int?
    var bought: Int?
    var bio: String?
    var lastSeen: Timestamp?
    var silent: Int?    //1 for online, 2 for silent, 3 for DND, 4 for ghost mode
    var socials: [String]?
    var groupChats: [String]?
    var phoneNumber: String?
    var myCommunities: [String]?
    var savedPosts: [String]?
    var pinnedChats: [String]?
    
    var mapPins: [String]?
    var currentLocation: String?
    var currentBatteryPercentage: Double?
}
