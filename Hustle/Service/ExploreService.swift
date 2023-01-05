import Firebase
import UIKit

struct ExploreService {
    let db = Firestore.firestore()
    
    func sendNotification(type: String, taggerUsername: String, taggedUsername: String, taggedUID: String?, caption: String, tweetID: String?, groupName: String?, newsName: String?, questionID: String?, taggerUID: String?){
        var data = ["type": type,
                    "caption": caption,
                    "tagger": taggerUsername,
                    "timestamp": Timestamp(date: Date())] as [String : Any]
        if let id = tweetID { data["tweetID"] = id }
        if let id = groupName { data["groupName"] = id }
        if let id = newsName { data["newsName"] = id }
        if let id = questionID { data["questionID"] = id }
        if let id = taggerUID { data["taggerUID"] = id }
        
        if let uid = taggedUID, !uid.isEmpty {
            db.collection("users").document(uid).collection("notifications").document()
                .setData(data) { _ in }
        } else {
            db.collection("users").whereField("username", isEqualTo: taggedUsername).limit(to: 1)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let users = documents.compactMap({ try? $0.data(as: User.self)} )
                    if let uid = users.first?.id {
                        self.db.collection("users").document(uid).collection("notifications").document()
                            .setData(data) { _ in }
                    }
                }
            
        }
    }
    func uploadNewsReply(caption: String, docID: String, user: String, newDocID: String, completion: @escaping(Bool) -> Void){
        if !docID.isEmpty {
            db.collection("news").document(docID).collection("reply").whereField(FieldPath.documentID(), isEqualTo: newDocID).limit(to: 1)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion(false)
                        return
                    }
                    if documents.isEmpty {
                        var data = ["response": caption,
                                    "actions": 0,
                                    "timestamp": Timestamp(date: Date())] as [String : Any]
                        
                        if !user.isEmpty {
                            data["username"] = user
                        }
                        
                        db.collection("news").document(docID).collection("reply").document(newDocID)
                            .setData(data) { _ in }
                        
                        db.collection("news").document(docID).updateData(["priority": FieldValue.increment(Int64(1))]) { _ in }
                        
                        completion(true)
                    } else {
                        completion(false)
                    }
            }
        } else {
            completion(false)
        }
    }
    func uploadOpinionReply(caption: String, newsID: String, opinionID: String, user: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if !newsID.isEmpty && !opinionID.isEmpty {
            let data = ["uid": uid,
                        "username": user,
                        "response": caption,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            
            db.collection("news").document(newsID).collection("reply").document(opinionID).collection("o_reply")
                .document().setData(data) { _ in }
            
            db.collection("news").document(newsID).collection("reply").document(opinionID).updateData(["actions": FieldValue.increment(Int64(1))]) { _ in }
        }
    }
    func getNewsReply(new: Bool, newsId: String, lastdoc: Timestamp?, lastTop: Int?, completion: @escaping([Reply]) -> Void){
        if !newsId.isEmpty {
            if lastTop == nil && !new {
                var toReturn = [Reply]()
                guard let uid = Auth.auth().currentUser?.uid else { return }
                db.collection("news").document(newsId).collection("reply").whereField(FieldPath.documentID(), isEqualTo: uid).limit(to: 1)
                    .getDocuments { snapshot, _ in
                        if let documents = snapshot?.documents {
                            let my_reps = documents.compactMap({ try? $0.data(as: Reply.self)} )
                            toReturn += my_reps
                        }
                        db.collection("news").document(newsId).collection("reply").order(by: "actions", descending: true).limit(to: 15)
                            .getDocuments { snapshot, _ in
                                guard let documents = snapshot?.documents else { return }
                                let reps = documents.compactMap({ try? $0.data(as: Reply.self)} )
                                toReturn += reps
                                completion(toReturn)
                            }
                    }
            } else {
                var query = db.collection("news").document(newsId).collection("reply").order(by: "timestamp", descending: true).limit(to: 15)
                if let last = lastdoc {
                    query = db.collection("news").document(newsId).collection("reply").whereField("timestamp", isLessThan: last).order(by: "timestamp", descending: true).limit(to: 17)
                }
                if let last = lastTop {
                    query = db.collection("news").document(newsId).collection("reply").whereField("actions", isLessThan: last).order(by: "actions", descending: true).limit(to: 17)
                }
                query.getDocuments { snapshot, _ in
                        guard let documents = snapshot?.documents else { return }
                        let reps = documents.compactMap({ try? $0.data(as: Reply.self)} )
                        completion(reps)
                    }
            }
        } else {
            completion([])
        }
    }
    func getNewsReplyNew(newsId: String, newest: Timestamp?, completion: @escaping([Reply]) -> Void){
        if let new = newest, !newsId.isEmpty {
            let query = db.collection("news").document(newsId).collection("reply").whereField("timestamp", isGreaterThan: new).order(by: "timestamp", descending: true).limit(to: 17)
            
            query.getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let reps = documents.compactMap({ try? $0.data(as: Reply.self)} )
                    completion(reps)
                }
        } else {
            completion([])
        }
    }
    func getOpinionReply(newsId: String, opinionID: String, lastdoc: Timestamp?, completion: @escaping([Reply]) -> Void){
        if !newsId.isEmpty && !opinionID.isEmpty{
            var query = db.collection("news").document(newsId).collection("reply").document(opinionID).collection("o_reply").order(by: "timestamp", descending: true).limit(to: 15)
            
            if let last = lastdoc {
                query = db.collection("news").document(newsId).collection("reply").document(opinionID).collection("o_reply").whereField("timestamp", isLessThan: last).order(by: "timestamp", descending: true).limit(to: 17)
            }
                        
            query.getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let reps = documents.compactMap({ try? $0.data(as: Reply.self)} )
                    completion(reps)
                }
        } else {
            completion([])
        }
    }
    func addNewsView(id: String) {
        if !id.isEmpty {
            db.collection("news").document(id).updateData(["views": FieldValue.increment(Int64(1))]) { _ in }
        }
    }
    func getNews(lastdoc: Timestamp?, completion: @escaping([News]) -> Void){
        var query = db.collection("news")
            .order(by: "timestamp", descending: true)
            .limit(to: 15)
        
        if let lastdoc {
            query = db.collection("news")
                .whereField("timestamp", isLessThan: lastdoc)
                .order(by: "timestamp", descending: true)
                .limit(to: 15)
        }
        
        query
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let news = documents.compactMap { document -> News? in
                    do {
                        return try document.data(as: News.self)
                    } catch {
                        return nil
                    }
                }
                completion(news)
            }
    }
    func getNewsSingle(title: String, completion: @escaping(News?) -> Void){
        db.collection("news").whereField("id", isEqualTo: title).limit(to: 1)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion(nil)
                    return
                }
                let news = documents.compactMap { document -> News? in
                    do {
                        return try document.data(as: News.self)
                    } catch {
                        return nil
                    }
                }
                if let first = news.first {
                    completion(first)
                } else {
                    completion(nil)
                }
            }
    }
    func getBreakingNews(completion: @escaping(News?) -> Void){
        db.collection("news").whereField("breaking", isEqualTo: true).limit(to: 1)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion(nil)
                    return
                }
                let news = documents.compactMap { document -> News? in
                    do {
                        return try document.data(as: News.self)
                    } catch {
                        return nil
                    }
                }
                if let first = news.first {
                    completion(first)
                } else {
                    completion(nil)
                }
            }
    }
    func getNewsOld(last: Timestamp?, completion: @escaping([News]) -> Void){
        if let last = last {
            db.collection("oldNews")
                .whereField("timestamp", isLessThan: last)
                .order(by: "timestamp", descending: true).limit(to: 12)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let tips = documents.compactMap({ try? $0.data(as: News.self)} )
                    completion(tips)
                }
        } else {
            db.collection("oldNews")
                .order(by: "timestamp", descending: true).limit(to: 10)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let tips = documents.compactMap({ try? $0.data(as: News.self)} )
                    completion(tips)
                }
            
        }
    }
    func uploadNews(link: String){
        let data = ["link": link] as [String : Any]
        db.collection("NewsOption").document().setData(data) { _ in }
    }
    func verifyTip(category: String, id: String?){
        if let id = id {
            db.collection("tips").document(category).collection("tipGroup")
                .document(id)
                .updateData([ "verified": true ]) { _ in }
        }
    }
    func deleteTip(category: String, id: String?){
        if let id = id {
            db.collection("tips").document(category).collection("tipGroup").document(id).delete()
        }
    }
    func uploadTip(caption: String, category: String){
        if !category.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let data = ["uid": uid,
                        "caption": caption,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            db.collection("tips").document(category).collection("tipGroup").document()
                .setData(data) { _ in }
        }
    }
    func getTips(Genra: String, lastDoc: Timestamp?, size: Int, completion: @escaping([Tip]) -> Void){
        if !Genra.isEmpty {
            let query = db.collection("tips").document(Genra).collection("tipGroup")
            if let last = lastDoc {
                query
                    .whereField("timestamp", isLessThan: last)
                    .order(by: "timestamp", descending: true).limit(to: size)
                    .getDocuments { snapshot, _ in
                        guard let documents = snapshot?.documents else {
                            completion([])
                            return
                        }
                        let tips = documents.compactMap({ try? $0.data(as: Tip.self)} )
                        completion(tips)
                    }
            } else {
                query
                    .order(by: "timestamp", descending: true).limit(to: size)
                    .getDocuments { snapshot, _ in
                        guard let documents = snapshot?.documents else {
                            completion([])
                            return
                        }
                        let tips = documents.compactMap({ try? $0.data(as: Tip.self)} )
                        completion(tips)
                    }
                
            }
        } else {
            completion([])
        }
    }
    func searchUsers(name: String, completion: @escaping([User]) -> Void){
        let lower = name.lowercased()
        db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: lower)
            .whereField("username", isLessThanOrEqualTo: lower + "\u{f8ff}")
            .limit(to: 15)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let users = documents.compactMap({ try? $0.data(as: User.self)} )
                completion(users)
            }
    }
    func searchFullname(name: String, completion: @escaping([User]) -> Void){
        db.collection("users")
            .whereField("fullname", isGreaterThanOrEqualTo: name)
            .whereField("fullname", isLessThanOrEqualTo: name + "\u{f8ff}")
            .limit(to: 15)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let users = documents.compactMap({ try? $0.data(as: User.self)} )
                completion(users)
            }
    }
    func searchGroups(name: String, completion: @escaping([GroupX]) -> Void){
        db.collection("userGroups")
            .whereField("title", isGreaterThanOrEqualTo: name)
            .whereField("title", isLessThanOrEqualTo: name + "\u{f8ff}")
            .limit(to: 15)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let groups = documents.compactMap({ try? $0.data(as: GroupX.self)} )
                completion(groups)
            }
    }
    func joinGroup(groupId: String){
        if !groupId.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let docRef = db.collection("userGroups").document(groupId)
            docRef.updateData([ "members": FieldValue.arrayUnion([uid]),
                                "membersCount": FieldValue.increment(Int64(1))
                              ]) { _ in }
            
            let docRefSec = db.collection("users").document(uid)
            docRefSec.updateData([ "pinnedGroups": FieldValue.arrayUnion([groupId]) ]) { _ in }
        }
    }
    func leaveGroup(groupId: String){
        if !groupId.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let docRef = Firestore.firestore().collection("userGroups").document(groupId)
            docRef.updateData([ "members": FieldValue.arrayRemove([uid]),
                                "membersCount": FieldValue.increment(Int64(-1))
                              ]) { _ in }
            
            let docRefSec = Firestore.firestore().collection("users").document(uid)
            docRefSec.updateData([ "pinnedGroups": FieldValue.arrayRemove([groupId]) ]) { _ in }
        }
    }
    func addSquare(groupId: String, square: [String]){
        if !groupId.isEmpty && !square.isEmpty {
            db.collection("userGroups").document(groupId).updateData([ "squares": square ]) { _ in }
        }
    }
    func removeSquare(groupId: String, square: String){
        if !groupId.isEmpty && !square.isEmpty {
            let docRef = db.collection("userGroups").document(groupId)
            
            docRef.updateData([ "squares": FieldValue.arrayRemove([square]) ]) { _ in }
            
            let query = db.collection("userGroups").document(groupId).collection(square)

            query
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    documents.forEach { doc in
                        query.document(doc.documentID).delete()
                    }
                }
            
        }
    }
    func kick(user: String, groupId: String){
        if !groupId.isEmpty && !user.isEmpty {
            let docRef = db.collection("userGroups").document(groupId)
            let docRefSec = db.collection("users").document(user)
            
            docRef.updateData([ "members": FieldValue.arrayRemove([user]),
                                "membersCount": FieldValue.increment(Int64(-1))
                              ]) { _ in }
            
            docRefSec.updateData([ "pinnedGroups": FieldValue.arrayRemove([groupId]) ]) { _ in }
        }
    }
    func promote(user: String, groupId: String){
        if !groupId.isEmpty && !user.isEmpty {
            let docRef = db.collection("userGroups").document(groupId)
            
            docRef.updateData([ "leaders": FieldValue.arrayUnion([user]) ]) { _ in }
        }
    }
    func demote(user: String, groupId: String){
        if !groupId.isEmpty && !user.isEmpty {
            let docRef = db.collection("userGroups").document(groupId)
            
            docRef.updateData([ "leaders": FieldValue.arrayRemove([user]) ]) { _ in }
        }
    }
    func editRules(rules: String, groupId: String){
        if !groupId.isEmpty {
            let docRef = db.collection("userGroups").document(groupId)
            
            docRef.updateData([ "rules": rules ]) { _ in }
        }
    }
    func editDesc(desc: String, groupId: String){
        if !groupId.isEmpty {
            let docRef = db.collection("userGroups").document(groupId)
            
            docRef.updateData([ "desc": desc ]) { _ in }
        }
    }
    func editPublic(publicStat: Bool, groupId: String){
        if !groupId.isEmpty {
            let docRef = db.collection("userGroups").document(groupId)
            
            docRef.updateData([ "publicstatus": publicStat ]) { _ in }
        }
    }
    func editCoverImage(groupId: String, imageUrl: String){
        if !groupId.isEmpty {
            let docRef = db.collection("userGroups").document(groupId)
            
            docRef.updateData([ "imageUrl": imageUrl ]) { _ in }
        }
    }
    func editTitle(groupId: String, newTitle: String){
        if !groupId.isEmpty {
            let docRef = db.collection("userGroups").document(groupId)
            
            docRef.updateData([ "title": newTitle ]) { _ in }
        }
    }
    func deleteMessage(messageId: String, groupId: String, privateG: Bool, square: String){
        if !groupId.isEmpty && !messageId.isEmpty && (!square.isEmpty || !privateG) {
            db.collection(privateG ? "userGroups" : "Groups").document(groupId).collection(privateG ? square : "convo")
                .document(messageId)
                .delete()
        }
    }
    func addReaction(groupID: String, square: String, docID: String, emoji: String, devGroup: Bool){
        if !groupID.isEmpty && !docID.isEmpty && !emoji.isEmpty {
            if devGroup {
                db.collection("Groups").document(groupID).collection("convo").document(docID)
                    .updateData([emoji: FieldValue.increment(Int64(1))]) { _ in }
            } else {
                db.collection("userGroups").document(groupID).collection(square).document(docID)
                    .updateData([emoji: FieldValue.increment(Int64(1))]) { _ in }
            }
        }
    }
    func editMessage(newText: String, groupId: String, textID: String?, square: String){
        if let textID = textID, !groupId.isEmpty && !newText.isEmpty && !square.isEmpty {
            db.collection("userGroups").document(groupId).collection(square)
                .document(textID)
                .updateData([ "caption" : newText ]) { _ in }
        }
    }
    func uploadMessage(caption: String, imagelink: String?, groupId: String, devGroup: Bool, docName: String, username: String, profilePhoto: String, square: String, replyFrom: String?, replyText: String?, replyImage: String?, vidURL: String?, audioURL: String?, fileURL: String?, replyVideo: String?, replyAudio: String?, replyFile: String?){
        if !groupId.isEmpty && (!square.isEmpty || devGroup) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            var data = ["uid": uid,
                        "caption": caption,
                        "username": username,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            if let link = imagelink {
                data["image"] = link
            }
            if !profilePhoto.isEmpty {
                data["profilephoto"] = profilePhoto
            }
            if let link = vidURL {
                data["videoURL"] = link
            }
            if let link = audioURL {
                data["audioURL"] = link
            }
            if let link = fileURL {
                data["fileURL"] = link
            }

            if let from = replyFrom {
                data["replyFrom"] = from
                if let rep_text = replyText {
                    data["replyText"] = String(rep_text.prefix(45))
                } else if let rep_image = replyImage {
                    data["replyImage"] = rep_image
                } else if let rep_file = replyFile {
                    data["replyFile"] = rep_file
                } else if let rep_Vid = replyVideo {
                    data["replyVideo"] = rep_Vid
                } else if let rep_Audio = replyAudio {
                    data["replyAudio"] = rep_Audio
                }
            }
            
            var query = db.collection("Groups").document(groupId).collection("convo").document(docName)
            if !devGroup {
                query = db.collection("userGroups").document(groupId).collection(square).document(docName)
            }
            query.setData(data) { _ in }
        }
    }
    func votePoll(textID: String?, groupID: String?, square: String, devGroup: Bool, count: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let suffix = uid + "\(count)"
        
        if let id = textID, let gID = groupID, (!square.isEmpty || devGroup) {
            var query = db.collection("Groups").document(gID).collection("convo").document(id)
            if !devGroup {
                query = db.collection("userGroups").document(gID).collection(square).document(id)
            }
            
            if count == 1 {
                query.updateData([
                    "count1": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            } else if count == 2 {
                query.updateData([
                    "count2": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            } else if count == 3 {
                query.updateData([
                    "count3": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            } else {
                query.updateData([
                    "count4": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            }
        }
    }
    func uploadPoll(question: String, text1: String, text2: String, text3: String?, text4: String?, groupId: String, username: String, profileP: String?, square: String, devGroup: Bool, newTextID: String){
        if !groupId.isEmpty && (!square.isEmpty || devGroup) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            var data = ["uid": uid,
                        "caption": question,
                        "username": username,
                        "choice1": text1,
                        "choice2": text2,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            if let c3 = text3 {
                data["choice3"] = c3
            }
            if let c4 = text4 {
                data["choice4"] = c4
            }
            
            var query = db.collection("Groups").document(groupId).collection("convo").document(newTextID)
            if !devGroup {
                query = db.collection("userGroups").document(groupId).collection(square).document(newTextID)
            }
            query.setData(data) { _ in }
        }
    }
    func createGroup(title: String, image: UIImage, rules: String, publicStatus: Bool, desc: String, completion: @escaping(Bool, String) -> Void){
        let id = UUID().uuidString
        guard let uid = Auth.auth().currentUser?.uid else { return }
        ImageUploader.uploadImage(image: image, location: "groups", compression: 0.05) { jobImageUrl, error in
            if !error {
                completion(false, "")
                return
            }
            var data = ["id": id,
                       "title": title,
                       "imageUrl": jobImageUrl,
                       "desc": desc,
                       "membersCount": 1,
                       "members": [uid],
                       "publicstatus": publicStatus,
                        "leaders": [uid]] as [String : Any]
            if !rules.isEmpty {
                data["rules"] = rules
            }
            db.collection("userGroups").document(id)
                .setData(data) { error in
                    if error != nil {
                        completion(false, id)
                        return
                    } else {
                        let docRef = Firestore.firestore().collection("users").document(uid)
                        
                        docRef.updateData([ "groupIdentifier": FieldValue.arrayUnion([id]) ]) { error in
                            if error != nil {
                                completion(false, "")
                            } else {
                                completion(true, "\(id)")
                            }
                        }
                    }
                }
            
        }
    }
    func fetchAdPlus(completion: @escaping([Tweet]) -> Void){
        let query = db.collection("ads").whereField("plus", isEqualTo: true).limit(to: 10)
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
            let final = tweets.filter { element in
                guard let AdStartDate = element.start?.dateValue() else { return false }
                return AdStartDate <= Timestamp(date: Date()).dateValue()
            }
            completion(final)
        }
    }
    func getGroupConvo(userGroupId: String, groupDev: Bool, square: String, completion: @escaping([Tweet]) -> Void){
        if !userGroupId.isEmpty && (!square.isEmpty || groupDev) {
            var query = db.collection("Groups").document(userGroupId).collection("convo")
            if !groupDev {
                query = db.collection("userGroups").document(userGroupId).collection(square)
            }
            query
                .order(by: "timestamp", descending: true).limit(to: 25)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                    completion(tweets)
                }
        } else {
            completion([])
        }
    }
    func getFirst(docID: String, completion: @escaping([Tweet]) -> Void){
        if !docID.isEmpty {
            db.collection("userGroups").document(docID).collection("Main")
                .order(by: "timestamp", descending: true).limit(to: 1)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let messages = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                    completion(messages)
                }
        } else { completion([]) }
    }
    func getGroupConvoMore(userGroupId: String, lastdoc: Timestamp, groupDev: Bool, square: String, completion: @escaping([Tweet]) -> Void){
        if !userGroupId.isEmpty && (!square.isEmpty || groupDev) {
            var query = db.collection("Groups").document(userGroupId).collection("convo")
            if !groupDev {
                query = db.collection("userGroups").document(userGroupId).collection(square)
            }
            query
                .whereField("timestamp", isLessThan: lastdoc).order(by: "timestamp", descending: true).limit(to: 25)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                    completion(tweets)
                }
        } else {
            completion([])
        }
    }
    func fetchNewest(userGroupId: String, firstDoc: Timestamp, groupDev: Bool, square: String, completion: @escaping([Tweet]) -> Void){
        if !userGroupId.isEmpty && (!square.isEmpty || groupDev) {
            var query = db.collection("Groups").document(userGroupId).collection("convo")
            if !groupDev {
                query = db.collection("userGroups").document(userGroupId).collection(square)
            }
            query
                .whereField("timestamp", isGreaterThan: firstDoc).order(by: "timestamp", descending: true).limit(to: 25)
                .getDocuments { snapshot, error in
                    if error != nil{
                        completion([])
                    }
                    guard let documents = snapshot?.documents else { return }
                    let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                    completion(tweets )
                }
        } else {
            completion([])
        }
    }
    func getUserGroupCover(userGroupId: String, completion: @escaping(GroupX) -> Void){
        if !userGroupId.isEmpty {
            db.collection("userGroups").document(userGroupId)
                .getDocument { snapshot, _ in
                    guard let snapshot = snapshot else { return }
                    guard let cover = try? snapshot.data(as: GroupX.self) else { return }
                    completion(cover)
                }
        }
    }
    func get10GroupCovers(completion: @escaping([GroupX]) -> Void){
        db.collection("userGroups").order(by: "membersCount", descending: true).limit(to: 10)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let groups = documents.compactMap({ try? $0.data(as: GroupX.self)} )
                completion(groups)
            }
    }
    func get10GroupCoversMore(lastdoc: Int, completion: @escaping([GroupX]) -> Void){
        db.collection("userGroups")
            .whereField("membersCount", isLessThan: lastdoc).order(by: "membersCount", descending: true).limit(to: 10)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let groups = documents.compactMap({ try? $0.data(as: GroupX.self)} )
                completion(groups)
            }
        
    }
}
