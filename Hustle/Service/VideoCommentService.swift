import Firebase
import UIKit

struct VideoCommentService {
    let db = Firestore.firestore()
    
    func getComments(videoID: String, completion: @escaping([Comment]) -> Void){
        if !videoID.isEmpty {
            let query =  db.collection("vidreply")
   
            query.document(videoID).collection("comments").order(by: "timestamp", descending: true).limit(to: 15)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let comments = documents.compactMap({ try? $0.data(as: Comment.self)} )
                    completion(comments)
                }
        }
    }
    func getCommentsMore(videoID: String, date: Timestamp, ad: Bool, completion: @escaping([Comment]) -> Void){
        if !videoID.isEmpty {
            let query = db.collection("vidreply")

            query.document(videoID).collection("comments").whereField("timestamp", isLessThan: date).order(by: "timestamp", descending: true).limit(to: 15)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let comments = documents.compactMap({ try? $0.data(as: Comment.self)} )
                    completion(comments)
                }
        }
    }
    func uploadComment(videoId: String, text: String, photo: String, username: String, ad: Bool, commentID: String){
        if !videoId.isEmpty {
            var data = ["text": text,
                        "username": username,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            if !photo.isEmpty {
                data["profilephoto"] = photo
            }
            let query = db.collection("vidreply")

            query.document(videoId).collection("comments").document(commentID)
                .setData(data) { _ in }
        }
    }
    func deleteComment(videoId: String, commentID: String?, ad: Bool, hasReps: Bool){
        if let id2 = commentID, !videoId.isEmpty {
            if hasReps {
                let query = db.collection("vidreply").document(videoId).collection("comments").document(id2).collection("replies")
                query.getDocuments { snapshot, _ in
                        if let documents = snapshot?.documents {
                            documents.forEach { doc in
                                query.document(doc.documentID).delete()
                            }
                        }
                    }
            }

            db.collection("vidreply").document(videoId).collection("comments").document(id2).delete()
        }
    }
    func deleteCommentReply(videoID: String, commentID: String, replyID: String, ad: Bool){
        if !videoID.isEmpty && !commentID.isEmpty && !replyID.isEmpty {
            db.collection("vidreply").document(videoID).collection("comments").document(commentID).collection("replies").document(replyID).delete()
            
            db.collection("vidreply").document(videoID).collection("comments").document(commentID)
                .updateData(["replies": FieldValue.increment(Int64(-1))]) { _ in }
        }
    }
    func uploadReply(videoId: String, text: String, photo: String, username: String, ad: Bool, commentID: String, replyID: String){
        if !videoId.isEmpty && !commentID.isEmpty {
            var data = ["text": text,
                        "username": username,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            if !photo.isEmpty {
                data["profilephoto"] = photo
            }
            let query = db.collection("vidreply")
            
            query.document(videoId).collection("comments").document(commentID)
                .updateData(["replies": FieldValue.increment(Int64(1))]) { _ in }

            query.document(videoId).collection("comments").document(commentID).collection("replies").document(replyID)
                .setData(data) { _ in }
        }
    }
    func getReplies(videoID: String, commentId: String, date: Timestamp?, ad: Bool, completion: @escaping([Comment]) -> Void){
        if !videoID.isEmpty && !commentId.isEmpty {
            let query = db.collection("vidreply")

            if let last = date {
                query.document(videoID).collection("comments").document(commentId).collection("replies").whereField("timestamp", isLessThan: last).order(by: "timestamp", descending: true).limit(to: 15)
                    .getDocuments { snapshot, _ in
                        guard let documents = snapshot?.documents else { return }
                        let comments = documents.compactMap({ try? $0.data(as: Comment.self)} )
                        completion(comments)
                    }
            } else {
                query.document(videoID).collection("comments").document(commentId).collection("replies").order(by: "timestamp", descending: true).limit(to: 15)
                    .getDocuments { snapshot, _ in
                        guard let documents = snapshot?.documents else { return }
                        let comments = documents.compactMap({ try? $0.data(as: Comment.self)} )
                        completion(comments)
                    }
            }
        }
    }
}
