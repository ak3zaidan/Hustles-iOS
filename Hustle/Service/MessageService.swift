import Firebase
import FirebaseFirestoreSwift

class MessageService: ObservableObject {
    let db = Firestore.firestore()
    
    func addReaction(convoID: String, id: String, emoji: String){
        if !convoID.isEmpty && !id.isEmpty && !emoji.isEmpty {
            db.collection("convos").document(convoID).collection("texts").document(id).updateData(["emoji": emoji]) { _ in }
        }
    }
    func get_question_tag(id: String, completion: @escaping(Question) -> Void){
        if !id.isEmpty {
            db.collection("Questions").document(id)
                .getDocument { snapshot, _ in
                    guard let snapshot = snapshot else { return }
                    guard let question = try? snapshot.data(as: Question.self) else { return }
                    completion(question)
                }
        }
    }
    func get_hustle_tag(id: String, completion: @escaping(Tweet) -> Void){
        if !id.isEmpty{
            db.collection("tweets").document(id)
                .getDocument { snapshot, _ in
                    guard let snapshot = snapshot else { return }
                    guard let hustle = try? snapshot.data(as: Tweet.self) else { return }
                    completion(hustle)
                }
        }
    }
    func getNotifications(completion: @escaping([Notification]) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let date = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let interval = Timestamp(date: date)
        db.collection("users").document(uid).collection("notifications").whereField("timestamp", isGreaterThan: interval)
            .limit(to: 30)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let notifs = documents.compactMap({ try? $0.data(as: Notification.self)} )
                completion(notifs.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }))
            }
    }
    func deleteNotif(id: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if !id.isEmpty {
            db.collection("users").document(uid).collection("notifications").document(id).delete()
        }
    }
    func acceptInvt(groupId: String, userID: String?){
        guard var uid = Auth.auth().currentUser?.uid else { return }
        if let id = userID {
            uid = id
        }
        if !groupId.isEmpty {
            ExploreService().getUserGroupCover(userGroupId: groupId) { group in
                if !group.members.contains(uid){
                    let docRef = self.db.collection("userGroups").document(groupId)
                    docRef.updateData([
                        "members": FieldValue.arrayUnion([uid]),
                        "membersCount": FieldValue.increment(Int64(1))
                    ]) { _ in }
                    
                    let docRefSec = self.db.collection("users").document(uid)
                    docRefSec.updateData([
                        "pinnedGroups": FieldValue.arrayUnion([groupId])
                    ]) { _ in }
                }
            }
        }
    }
    func deleteOld(convoID: String, messageId: String){
        if !convoID.isEmpty && !messageId.isEmpty {
            db.collection("convos").document(convoID).collection("texts").document(messageId).delete()
        }
    }
    func changeEncryption(docID: String, bool: Bool){
        if !docID.isEmpty {
            db.collection("convos").document(docID).updateData(["encrypted": bool]) { _ in }
        }
    }
    func shareLocation(docID: String, shareBool: Bool, isUidOne: Bool){
        if !docID.isEmpty {
            if isUidOne {
                db.collection("convos").document(docID).updateData(["uid_one_sharing_location": shareBool]) { _ in }
            } else {
                db.collection("convos").document(docID).updateData(["uid_two_sharing_location": shareBool]) { _ in }
            }
        }
    }
    func addPinForChat(docID: String, name: String, lat: Double, long: Double) {
        if !docID.isEmpty {
            let pinString = String(lat) + "," + String(long) + "," + name
            
            db.collection("convos").document(docID).updateData(["chatPins": FieldValue.arrayUnion([pinString]) ]) { _ in }
        }
    }
    func removePinForChat(docID: String, name: String) {
        if !docID.isEmpty {
            db.collection("convos").document(docID).updateData(["chatPins": FieldValue.arrayRemove([name]) ]) { _ in }
        }
    }
    func editMessage(newText: String, docID: String, textID: String?){
        if let textID = textID, !docID.isEmpty && !newText.isEmpty {
            db.collection("convos").document(docID).collection("texts")
                .document(textID)
                .updateData([ "text" : newText ]) { _ in }
        }
    }
    func sendMessage(docID: String, otherUserUID: String?, text: String, imageUrl: String?, elo: String?, is_uid_one: Bool, newID: String?, messageID: String, fileData: String?, pathE: String, replyFrom: String?, replyText: String?, replyImage: String?, replyELO: String?, replyFile: String?, videoURL: String?, audioURL: String?, lat: Double?, long: Double?, name: String?, replyVideo: String?, replyAudio: String?, pinmap: String?){
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if !docID.isEmpty {
            var data = ["uid_one_did_recieve": is_uid_one ? false : true,
                        "seen_by_reciever": false,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            if !text.isEmpty { data["text"] = text }
            if let url = imageUrl, !url.isEmpty { data["imageUrl"] = url }
            if let elo = elo { data["elo"] = elo }
            if let vid = videoURL { data["videoURL"] = vid }
            if let audio = audioURL { data["audioURL"] = audio }
            if let fileD = fileData { data["file"] = fileD }
            if let pin = pinmap { data["pinmap"] = pin }
            
            if let lat = lat, let long = long, let name = name {
                data["lat"] = lat
                data["long"] = long
                data["name"] = name
            }

            if let from = replyFrom {
                data["replyFrom"] = from
                if let rep_text = replyText {
                    if extractCoordinates(from: rep_text) != nil {
                        data["replyText"] = rep_text
                    } else {
                        data["replyText"] = String(rep_text.prefix(50))
                    }
                } else if let rep_image = replyImage {
                    data["replyImage"] = rep_image
                } else if let rep_ELO = replyELO {
                    data["replyELO"] = rep_ELO
                } else if let rep_file = replyFile {
                    data["replyFile"] = rep_file
                } else if let rep_Vid = replyVideo {
                    data["replyVideo"] = rep_Vid
                } else if let rep_Audio = replyAudio {
                    data["replyAudio"] = rep_Audio
                }
            }

            if messageID.isEmpty {
                db.collection("convos").document(docID).collection("texts").document().setData(data) { _ in }
            } else {
                db.collection("convos").document(docID).collection("texts").document(messageID).setData(data) { _ in }
            }
        } else if let id = newID, let otherUID = otherUserUID {
            if !id.isEmpty && !otherUID.isEmpty {
                let startData = ["uid_one": uid,
                                 "uid_two": otherUID,
                                 "uid_one_active": true,
                                 "uid_two_active": true,
                                 "encrypted": otherUID == "lQTwtFUrOMXem7UXesJbDMLbV902" ? false : true] as [String : Any]
                db.collection("convos").document(id).setData(startData) { error in
                    if error == nil {
                        self.sendMessage(docID: id, otherUserUID: nil, text: text, imageUrl: imageUrl, elo: elo, is_uid_one: true, newID: nil, messageID: messageID, fileData: fileData, pathE: pathE, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyELO: replyELO, replyFile: replyFile, videoURL: videoURL, audioURL: audioURL, lat: lat, long: long, name: name, replyVideo: replyVideo, replyAudio: replyAudio, pinmap: nil)
                    }
                }
                db.collection("users").document(uid).updateData([ "myMessages": FieldValue.arrayUnion([id]) ]) { _ in }
                db.collection("users").document(otherUID).updateData([ "myMessages": FieldValue.arrayUnion([id]) ]) { _ in }
            }
        }
    }
    func getFirst(docID: String, completion: @escaping([Message]) -> Void){
        if !docID.isEmpty {
            db.collection("convos").document(docID).collection("texts")
                .order(by: "timestamp", descending: true).limit(to: 1)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let messages = documents.compactMap({ try? $0.data(as: Message.self)} )
                    completion(messages)
                }
        } else { completion([]) }
    }
    func getMessages(docID: String, otherUser: String?, completion: @escaping(([Message], Convo?)) -> Void){
        if !docID.isEmpty {
            db.collection("convos").document(docID).collection("texts")
                .order(by: "timestamp", descending: true).limit(to: 20)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let messages = documents.compactMap({ try? $0.data(as: Message.self)} )
                    let final = messages.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
                    completion((final, nil))
                }
        } else if let otherUID = otherUser {
            getConvoIfExist(otherUID: otherUID) { convo in
                if let convoID = convo?.id {
                    self.db.collection("convos").document(convoID).collection("texts")
                        .order(by: "timestamp", descending: true).limit(to: 20)
                        .getDocuments { snapshot, _ in
                            guard let documents = snapshot?.documents else { return }
                            let messages = documents.compactMap({ try? $0.data(as: Message.self)} )
                            let final = messages.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
                            completion((final, convo))
                        }
                } else { completion(([], nil)) }
            }
        }
    }
    func getMessagesMore(docID: String, lastdoc: Timestamp, completion: @escaping([Message]) -> Void){
        if !docID.isEmpty {
            db.collection("convos").document(docID).collection("texts")
                .whereField("timestamp", isLessThan: lastdoc)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let messages = documents.compactMap({ try? $0.data(as: Message.self)} )
                    completion(messages.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }))
                }
        } else { completion([]) }
    }
    func getMessagesNew(docID: String, lastdoc: Timestamp, completion: @escaping([Message]) -> Void){
        if !docID.isEmpty {
            db.collection("convos").document(docID).collection("texts")
                .whereField("timestamp", isGreaterThan: lastdoc)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let messages = documents.compactMap({ try? $0.data(as: Message.self)} )
                    completion(messages.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }))
                }
        } else { completion([]) }
    }
    func reactivate(convoID: String, one: Bool){
        if let uid = Auth.auth().currentUser?.uid, !convoID.isEmpty {
            if one {
                db.collection("convos").document(convoID).updateData([ "uid_one_active": true ]) { _ in }
            } else {
                db.collection("convos").document(convoID).updateData([ "uid_two_active": true ]) { _ in }
            }
            db.collection("users").document(uid).updateData([ "myMessages": FieldValue.arrayUnion([convoID]) ]) { _ in }
        }
    }
    func getConversations(pointers: [String], completion: @escaping([(Convo, User)]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var conversations = [(Convo, User)]()
        var count = 0
        pointers.forEach { pointer in
            if !pointer.isEmpty {
                db.collection("convos").document(pointer)
                    .getDocument { snapshot, _ in
                        if let snapshot = snapshot {
                            if let convo = try? snapshot.data(as: Convo.self) {
                                var userID = convo.uid_one
                                if uid == convo.uid_one {
                                    userID = convo.uid_two
                                }
                                self.db.collection("users").document(userID)
                                    .getDocument { snapshot, _ in
                                        if let snapshot = snapshot, let user = try? snapshot.data(as: User.self) {
                                            conversations.append((convo, user))
                                            count += 1
                                            if count == pointers.count { completion(conversations) }
                                        } else {
                                            count += 1
                                            if count == pointers.count { completion(conversations) }
                                        }
                                    }
                            } else {
                                count += 1
                                if count == pointers.count { completion(conversations) }
                            }
                        } else {
                            count += 1
                            if count == pointers.count { completion(conversations) }
                        }
                    }
            } else {
                count += 1
                if count == pointers.count { completion(conversations) }
            }
        }
    }
    func deleteConvo(docID: String, otherUserDidDelete: Bool){
        if !docID.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            if otherUserDidDelete {
                db.collection("convos").document(docID).collection("texts")
                    .getDocuments { snapshot, _ in
                        if let documents = snapshot?.documents {
                            documents.forEach { doc in
                                let textID = doc.documentID
                                Firestore.firestore().collection("convos").document(docID).collection("texts")
                                    .document(textID).delete()
                            }
                        }
                        Firestore.firestore().collection("convos").document(docID).delete()
                        
                        self.db.collection("users").document(uid).updateData([ "myMessages": FieldValue.arrayRemove([docID]) ]) { _ in }
                    }
            } else {
                db.collection("convos").document(docID)
                    .getDocument { snapshot, _ in
                        guard let snapshot = snapshot else { return }
                        guard let convo = try? snapshot.data(as: Convo.self) else { return }
                        let other_active = (convo.uid_one == uid) ? convo.uid_two_active : convo.uid_one_active
                        if other_active {
                            self.db.collection("users").document(uid).updateData([ "myMessages": FieldValue.arrayRemove([docID]) ]) { _ in }
                            if convo.uid_one == uid {
                                self.db.collection("convos").document(docID).updateData([ "uid_one_active": false ]) { _ in }
                            } else {
                                self.db.collection("convos").document(docID).updateData([ "uid_two_active": false ]) { _ in }
                            }
                        } else {
                            self.db.collection("convos").document(docID).collection("texts")
                                .getDocuments { snapshot, _ in
                                    if let documents = snapshot?.documents {
                                        documents.forEach { doc in
                                            let textID = doc.documentID
                                            Firestore.firestore().collection("convos").document(docID).collection("texts")
                                                .document(textID).delete()
                                        }
                                    }
                                    Firestore.firestore().collection("convos").document(docID).delete()
                                    
                                    self.db.collection("users").document(uid).updateData([ "myMessages": FieldValue.arrayRemove([docID]) ]) { _ in }
                                }
                            
                        }
                    }
                
            }
        }
    }
    func messageSeen(docID: String, textId: String){
        if !docID.isEmpty && !textId.isEmpty {
            db.collection("convos").document(docID).collection("texts").document(textId)
                .updateData(["seen_by_reciever": true]) { _ in }
        }
    }
    func requestJoin(otherUID: String, send: String){
        getDocID(otherUID: otherUID) { id in
            if let docID = id {
                self.sendMessage(docID: docID, otherUserUID: nil, text: send, imageUrl: nil, elo: nil, is_uid_one: false, newID: nil, messageID: "", fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
            } else {
                guard let uid = Auth.auth().currentUser?.uid else { return }
                self.sendMessage(docID: "", otherUserUID: otherUID, text: send, imageUrl: nil, elo: nil, is_uid_one: true, newID: otherUID + uid, messageID: "", fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
            }
        }
    }
    func getDocID(otherUID: String, completion: @escaping(String?) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        if !otherUID.isEmpty {
            let testOne = uid + otherUID
            db.collection("convos").document(testOne)
                .getDocument { snapshot, _ in
                    if let snapshot = snapshot, snapshot.exists {
                        completion(testOne)
                    } else {
                        let testTwo = otherUID + uid
                        self.db.collection("convos").document(testTwo)
                            .getDocument { snapshot, _ in
                                if let snapshot = snapshot, snapshot.exists {
                                   completion(testTwo)
                                } else {
                                    completion(nil)
                                }
                            }
                        
                    }
                }
            
        }
    }
    func getSpecificDoc(otherUID: String, completion: @escaping(Convo?) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        if !otherUID.isEmpty {
            let testOne = uid + otherUID
            db.collection("convos").document(testOne)
                .getDocument { snapshot, _ in
                    if let snapshot = snapshot, let convo = try? snapshot.data(as: Convo.self) {
                        completion(convo)
                    } else {
                        let testTwo = otherUID + uid
                        self.db.collection("convos").document(testTwo)
                            .getDocument { snapshot, _ in
                                if let snapshot = snapshot, let convo = try? snapshot.data(as: Convo.self) {
                                    completion(convo)
                                } else {
                                    completion(nil)
                                }
                            }
                        
                    }
                }
            
        }
    }
    func getConvoIfExist(otherUID: String, completion: @escaping(Convo?) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        if !otherUID.isEmpty {
            let testOne = uid + otherUID
            db.collection("convos").document(testOne)
                .getDocument { snapshot, _ in
                    if let snapshot = snapshot, let convo = try? snapshot.data(as: Convo.self) {
                        completion(convo)
                    } else {
                        let testTwo = otherUID + uid
                        self.db.collection("convos").document(testTwo)
                            .getDocument { snapshot, _ in
                                if let snapshot = snapshot, let convo = try? snapshot.data(as: Convo.self) {
                                    completion(convo)
                                } else {
                                    completion(nil)
                                }
                            }
                        
                    }
                }
            
        }
    }
}
