import Foundation

struct CommentParent: Identifiable {
    let id: String
    let isAd: Bool
    var comments: [Comment]
}
