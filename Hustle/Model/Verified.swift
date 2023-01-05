import Firebase
import FirebaseFirestoreSwift

struct Verified: Decodable, Equatable {
    let hustles: [String]
    let ratings: [String]
}
