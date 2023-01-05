import Firebase
import Foundation

struct QuestionService {
    let db = Firestore.firestore()
    
    func uploadQuestion(title: String, caption: String, tags: [String], promoted: Int, username: String, profilePhoto: String?, completion: @escaping(Bool) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let tagString = tags.joined(separator: ",")
        var data = ["uid": uid,
                    "caption": caption,
                    "title": title,
                    "votes": 0,
                    "username": username,
                    "tagJoined": tagString,
                    "timestamp": Timestamp(date: Date())] as [String : Any]
        
        if promoted > 0 {
            let date = Calendar.current.date(byAdding: .day, value: promoted + 1, to: Date())!
            data["promoted"] = Timestamp(date: date)
        }
        if let userPhoto = profilePhoto {
            data["profilePhoto"] = userPhoto
        }

        db.collection("Questions").document()
            .setData(data) { error in
                if error != nil {
                    completion(false)
                    return
                }
                completion(true)
            }
    }
    func uploadQuestionImage(caption: String, promoted: Int, username: String, profilePhoto: String?, image1: String, image2: String?, completion: @escaping(Bool) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var data = ["uid": uid,
                    "caption": caption,
                    "votes": 0,
                    "username": username,
                    "image1": image1,
                    "timestamp": Timestamp(date: Date())] as [String : Any]
        
        if promoted > 0 {
            let date = Calendar.current.date(byAdding: .day, value: promoted + 1, to: Date())!
            data["promoted"] = Timestamp(date: date)
        }
        if let userPhoto = profilePhoto {
            data["profilePhoto"] = userPhoto
        }
        if let pic2 = image2 {
            data["image2"] = pic2
        }
        db.collection("Questions").document()
            .setData(data) { error in
                if error != nil {
                    completion(false)
                    return
                }
                completion(true)
            }
    }
    func uploadAnswer(questionID: String?, caption: String, username: String, profilePhoto: String?){
        if let id = questionID {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            var data = ["uid": uid,
                        "caption": caption,
                        "votes": 0,
                        "username": username,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            if let userPhoto = profilePhoto {
                data["profilePhoto"] = userPhoto
            }
            db.collection("Questions").document(id).collection("answers").document(uid)
                .setData(data) { _ in }
            db.collection("Questions").document(id).updateData([ "answersCount": FieldValue.increment(Int64(1)) ]){ _ in }
        }
    }
    func uploadAnswerImage(questionID: String?, caption: String, username: String, profilePhoto: String?, image: String?){
        if let id = questionID {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            var data = ["uid": uid,
                        "caption": caption,
                        "username": username,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            if let userPhoto = profilePhoto {
                data["profilePhoto"] = userPhoto
            }
            if let photo = image {
                data["image"] = photo
            }
            db.collection("Questions").document(id).collection("answers").document(uid)
                .setData(data) { _ in }
            db.collection("Questions").document(id).updateData([ "answersCount": FieldValue.increment(Int64(1)) ]){ _ in }
        }
    }
    func getAnswers(questionID: String, completion: @escaping([Answer]) -> Void){
        if !questionID.isEmpty {
            db.collection("Questions").document(questionID).collection("answers")
                .getDocuments { snapshot, _ in
                    if let documents = snapshot?.documents {
                        let answers = documents.compactMap({ try? $0.data(as: Answer.self)} )
                        completion(answers.sorted(by: { $0.votes ?? 0 > $1.votes ?? 0 }))
                    } else {
                        completion([])
                    }
                }
        } else {
            completion([])
        }
    }
    func refreshNew(last: Timestamp, completion: @escaping([Question]) -> Void){
        let query = db.collection("Questions").whereField("timestamp", isGreaterThan: last).order(by: "timestamp", descending: true).limit(to: 20)
        
        query.getDocuments { snapshot, _ in
            if let documents = snapshot?.documents {
                let questions = documents.compactMap({ try? $0.data(as: Question.self)} )
                completion(questions)
            } else {
                completion([])
            }
        }
    }
    func getNew(last: Timestamp?, completion: @escaping([Question]) -> Void){
        var query = db.collection("Questions").order(by: "timestamp", descending: true).limit(to: 20)
        
        if let last = last {
            query = db.collection("Questions").whereField("timestamp", isLessThan: last).order(by: "timestamp", descending: true).limit(to: 20)
        }
        
        query.getDocuments { snapshot, _ in
            if let documents = snapshot?.documents {
                let questions = documents.compactMap({ try? $0.data(as: Question.self)} )
                completion(questions)
            } else {
                completion([])
            }
        }
    }
    func getTop(last: Int?, completion: @escaping([Question]) -> Void){
        var query = db.collection("Questions").order(by: "votes", descending: true).limit(to: 20)
        
        if let last = last {
            query = db.collection("Questions").whereField("votes", isLessThan: last).order(by: "votes", descending: true).limit(to: 20)
        }
        
        query.getDocuments { snapshot, _ in
            if let documents = snapshot?.documents {
                let questions = documents.compactMap({ try? $0.data(as: Question.self)} )
                completion(questions)
            } else {
                completion([])
            }
        }
    }
    func deleteQuestion(questionID: String?, answersCount: Int){
        if let id = questionID {
            if answersCount > 0 {
                let collectionRef = db.collection("Questions").document(id).collection("answers")
                collectionRef
                    .getDocuments { snapshot, _ in
                        guard let documents = snapshot?.documents else { return }
                        for document in documents {
                            collectionRef.document(document.documentID).delete { _ in }
                        }
                    }
            }
            db.collection("Questions").document(id).delete()
        }
    }
    func deleteAnswer(questionID: String?, answerID: String?){
        if let id = questionID, let ansID = answerID {
            db.collection("Questions").document(id).collection("answers").document(ansID).delete()
            
            db.collection("Questions").document(id).updateData([ "answersCount": FieldValue.increment(Int64(-1)) ]) { _ in }
        }
    }
    func voteQuestion(questionID: String?, value: Int){
        guard let currentUser = Auth.auth().currentUser else { return }
        let uid = String(currentUser.uid.suffix(4))
        if let id = questionID {
            if value == 1 {
                db.collection("Questions").document(id)
                    .updateData([ "votes": FieldValue.increment(Int64(1)),
                                  "upvoteIds": FieldValue.arrayUnion([uid])]) { _ in }
            } else {
                db.collection("Questions").document(id)
                    .updateData([ "votes": FieldValue.increment(Int64(-1)),
                                  "downVoteIds": FieldValue.arrayUnion([uid])]) { _ in }
            }
        }
    }
    func voteAnswer(questionID: String?, answerID: String?, value: Int){
        guard let currentUser = Auth.auth().currentUser else { return }
        let uid = String(currentUser.uid.suffix(4))
        if let id = questionID, let ansID = answerID {
            if value == 1 {
                db.collection("Questions").document(id).collection("answers").document(ansID)
                    .updateData([ "votes": FieldValue.increment(Int64(1)),
                                  "upvoteIds": FieldValue.arrayUnion([uid])]) { _ in }
            } else {
                db.collection("Questions").document(id).collection("answers").document(ansID)
                    .updateData([ "votes": FieldValue.increment(Int64(-1)),
                                  "downVoteIds": FieldValue.arrayUnion([uid])]) { _ in }
            }
        }
    }
    func acceptAnswer(questionID: String?, answerID: String?){
        if let id = questionID, let ansID = answerID {
            db.collection("Questions").document(id).updateData([ "acceptedAnswer": ansID ]) { _ in }
            UserService().editElo(withUid: answerID, withAmount: 10) { }
        }
    }
}
