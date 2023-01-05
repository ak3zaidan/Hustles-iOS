import Foundation
import Firebase

class CommentViewModel: ObservableObject{
    @Published var comments = [CommentParent]()
    @Published var currentHustle: Int?
    @Published var commentReplies: [(String, [Comment])] = []
    let service = TweetService()

    func getComments(withTweet tweet: Tweet){
        if var id = tweet.id {
            if tweet.start != nil {
                id = String(id.dropLast(4))
            }
            if let x = comments.firstIndex(where: { $0.id ==  id }){
                currentHustle = x
            } else {
                comments.append(CommentParent(id: id, isAd: (tweet.start != nil) ? true : false, comments: []))
                currentHustle = comments.count - 1
            }
        }
        if let index = currentHustle, comments[index].comments.isEmpty {
            service.getComments(tweet: tweet) { comments in
                self.comments[index].comments = comments
            }
        }
    }
    func getCommentsMore(){
        if let index = currentHustle {
            if let last = comments[index].comments.last{
                service.getCommentsMore(tweetId: comments[index].id, date: last.timestamp, ad: comments[index].isAd) { comments in
                    self.comments[index].comments += comments
                }
            }
        }
    }
    func sendComment(text: String, username: String, userPhoto: String, commentID: String){
        if let index = currentHustle {
            service.uploadComment(tweetId: comments[index].id, text: text, photo: userPhoto, username: username, ad: comments[index].isAd, commentID: commentID)
        }
    }
    func deleteComment(commentID: String?, hasReps: Bool){
        if let index = currentHustle {
            if let x = comments[index].comments.firstIndex(where: { $0.id == commentID }) {
                comments[index].comments.remove(at: x)
            }
            service.deleteComment(tweetId: comments[index].id, commentID: commentID, ad: comments[index].isAd, hasReps: hasReps)
        }
    }
    func tagUserComment(myUsername: String, otherUsername: String, message: String, tweetID: String?) {
        ExploreService().sendNotification(type: "Comment", taggerUsername: myUsername, taggedUsername: otherUsername, taggedUID: nil, caption: message, tweetID: tweetID, groupName: nil, newsName: nil, questionID: nil, taggerUID: nil)
    }
    func getReplies(commentID: String){
        if let index = currentHustle {
            let hustleID = comments[index].id
            let isAd = comments[index].isAd
            if let x = commentReplies.firstIndex(where: { $0.0 == commentID }) {
                service.getReplies(tweetId: hustleID, commentId: commentID, date: commentReplies[x].1.last?.timestamp, ad: isAd) { comments in
                    var temp = comments
                    temp.removeAll(where: { self.commentReplies[x].1.contains($0) })
                    self.commentReplies[x].1.append(contentsOf: temp)
                }
            } else {
                service.getReplies(tweetId: hustleID, commentId: commentID, date: nil, ad: isAd) { comments in
                    self.commentReplies.append((commentID, comments))
                }
            }
        }
    }
    func deleteReply(commentID: String, replyID: String){
        if let index = currentHustle {
            if let x = commentReplies.firstIndex(where: { $0.0 == commentID }) {
                commentReplies[x].1.removeAll(where: { $0.id == replyID })
            }
            service.deleteCommentReply(hustleID: comments[index].id, commentID: commentID, replyID: replyID, ad: comments[index].isAd)
        }
    }
    func uploadReply(text: String, username: String, userPhoto: String, commentID: String, userID: String){
        if let index = currentHustle {
            let id = userID + String("\(UUID())".prefix(4))
            service.uploadReply(tweetId: comments[index].id, text: text, photo: userPhoto, username: username, ad: comments[index].isAd, commentID: commentID, replyID: id)
            let new = Comment(id: id, text: text, timestamp: Timestamp(), username: username, profilephoto: userPhoto)
            if let x = commentReplies.firstIndex(where: { $0.0 == commentID }) {
                commentReplies[x].1.insert(new, at: 0)
            } else {
                commentReplies.append((commentID, [new]))
            }
            if let y = comments[index].comments.firstIndex(where: { $0.id == commentID }) {
                if let count = comments[index].comments[y].replies {
                    comments[index].comments[y].replies = count + 1
                } else {
                    comments[index].comments[y].replies = 1
                }
            }
        }
    }
}
