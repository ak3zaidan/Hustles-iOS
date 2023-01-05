import Firebase
import UIKit

struct QuestionCommentService {
    let db = Firestore.firestore()
    
    func getComments(videoID: String, completion: @escaping([Comment]) -> Void){
        if !videoID.isEmpty {
            let query =  db.collection("questionreply")
   
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
            let query = db.collection("questionreply")

            query.document(videoID).collection("comments").whereField("timestamp", isLessThan: date).order(by: "timestamp", descending: true).limit(to: 15)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let comments = documents.compactMap({ try? $0.data(as: Comment.self)} )
                    completion(comments)
                }
        }
    }
    func uploadComment(questionId: String, answerID: String, text: String, photo: String, username: String, ad: Bool, commentID: String, isAnswer: Bool){
        if !questionId.isEmpty {
            var data = ["text": text,
                        "username": username,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            if !photo.isEmpty { data["profilephoto"] = photo }

            if isAnswer {
                db.collection("Questions").document(questionId).collection("answers").document(answerID)
                    .updateData([ "commentsCount": FieldValue.increment(Int64(1)) ]){ _ in }
                db.collection("questionreply").document(answerID).collection("comments").document(commentID)
                    .setData(data) { _ in }
            } else {
                db.collection("Questions").document(questionId)
                    .updateData([ "commentsCount": FieldValue.increment(Int64(1)) ]){ _ in }
                db.collection("questionreply").document(questionId).collection("comments").document(commentID)
                    .setData(data) { _ in }
            }
        }
    }
    func deleteComment(questionId: String, answerID: String, commentID: String?, ad: Bool, hasReps: Bool, isAnswer: Bool){
        if let id2 = commentID, !questionId.isEmpty {
            if hasReps {
                let query = db.collection("questionreply").document(isAnswer ? answerID : questionId).collection("comments").document(id2).collection("replies")
                query.getDocuments { snapshot, _ in
                        if let documents = snapshot?.documents {
                            documents.forEach { doc in
                                query.document(doc.documentID).delete()
                            }
                        }
                    }
            }
            if isAnswer {
                db.collection("questionreply").document(answerID).collection("comments").document(id2).delete()
                db.collection("Questions").document(questionId).collection("answers").document(answerID)
                    .updateData([ "commentsCount": FieldValue.increment(Int64(-1)) ]){ _ in }
            } else {
                db.collection("questionreply").document(questionId).collection("comments").document(id2).delete()
                db.collection("Questions").document(questionId).updateData([ "commentsCount": FieldValue.increment(Int64(-1)) ]){ _ in }
            }
        }
    }
    func deleteCommentReply(videoID: String, commentID: String, replyID: String, ad: Bool){
        if !videoID.isEmpty && !commentID.isEmpty && !replyID.isEmpty {
            db.collection("questionreply").document(videoID).collection("comments").document(commentID).collection("replies").document(replyID).delete()
            db.collection("questionreply").document(videoID).collection("comments").document(commentID)
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
            let query = db.collection("questionreply")
            
            query.document(videoId).collection("comments").document(commentID)
                .updateData(["replies": FieldValue.increment(Int64(1))]) { _ in }

            query.document(videoId).collection("comments").document(commentID).collection("replies").document(replyID)
                .setData(data) { _ in }
        }
    }
    func getReplies(videoID: String, commentId: String, date: Timestamp?, ad: Bool, completion: @escaping([Comment]) -> Void){
        if !videoID.isEmpty && !commentId.isEmpty {
            let query = db.collection("questionreply")

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
