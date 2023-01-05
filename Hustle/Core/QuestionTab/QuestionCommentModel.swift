import Foundation
import Firebase

class QuestionCommentModel: ObservableObject {
    @Published var comments = [CommentParent]()
    @Published var currentHustle: Int?
    @Published var commentReplies: [(String, [Comment])] = []
    let service = QuestionCommentService()

    func getComments(videoID: String){
        if !videoID.isEmpty {
            if let x = comments.firstIndex(where: { $0.id == videoID }){
                currentHustle = x
            } else {
                comments.append(CommentParent(id: videoID, isAd: false, comments: []))
                currentHustle = comments.count - 1
            }
        }
        if let index = currentHustle, comments[index].comments.isEmpty {
            service.getComments(videoID: videoID) { comments in
                self.comments[index].comments = comments
            }
        }
    }
    func getCommentsMore(){
        if let index = currentHustle {
            if let last = comments[index].comments.last {
                service.getCommentsMore(videoID: comments[index].id, date: last.timestamp, ad: false) { comments in
                    self.comments[index].comments += comments
                }
            }
        }
    }
    func sendComment(text: String, username: String, userPhoto: String, commentID: String, questionID: String, answerID: String, isAnswer: Bool){
        service.uploadComment(questionId: questionID, answerID: answerID, text: text, photo: userPhoto, username: username, ad: false, commentID: commentID, isAnswer: isAnswer)
    }
    func deleteComment(commentID: String?, hasReps: Bool, questionID: String, answerID: String, isAnswer: Bool){
        if let index = currentHustle {
            if let x = comments[index].comments.firstIndex(where: { $0.id == commentID }) {
                comments[index].comments.remove(at: x)
            }
            service.deleteComment(questionId: questionID, answerID: answerID, commentID: commentID, ad: false, hasReps: hasReps, isAnswer: isAnswer)
        }
    }
    
    func tagUserComment(myUsername: String, otherUsername: String, message: String, questionID: String?, imageQ: Bool) {
        let type = "Question " + (imageQ ? "Image" : "Text")
        ExploreService().sendNotification(type: type, taggerUsername: myUsername, taggedUsername: otherUsername, taggedUID: nil, caption: message, tweetID: nil, groupName: nil, newsName: nil, questionID: questionID, taggerUID: nil)
    }
    
    func getReplies(commentID: String){
        if let index = currentHustle {
            let hustleID = comments[index].id
            let isAd = false
            
            if let x = commentReplies.firstIndex(where: { $0.0 == commentID }) {
                service.getReplies(videoID: hustleID, commentId: commentID, date: commentReplies[x].1.last?.timestamp, ad: isAd) { comments in
                    var temp = comments
                    temp.removeAll(where: { self.commentReplies[x].1.contains($0) })
                    self.commentReplies[x].1.append(contentsOf: temp)
                }
            } else {
                service.getReplies(videoID: hustleID, commentId: commentID, date: nil, ad: isAd) { comments in
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
            service.deleteCommentReply(videoID: comments[index].id, commentID: commentID, replyID: replyID, ad: comments[index].isAd)
        }
    }
    func uploadReply(text: String, username: String, userPhoto: String, commentID: String, userID: String){
        if let index = currentHustle {
            let id = userID + String("\(UUID())".prefix(4))
            service.uploadReply(videoId: comments[index].id, text: text, photo: userPhoto, username: username, ad: comments[index].isAd, commentID: commentID, replyID: id)
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
