import Firebase
import UIKit
import FirebaseFirestoreSwift

struct GroupChatService {
    let db = Firestore.firestore()
    
    func addReaction(groupID: String, textID: String, emoji: String){
        if !groupID.isEmpty && !textID.isEmpty && !emoji.isEmpty {
            db.collection("groupChats").document(groupID).collection("texts").document(textID)
                .updateData([emoji: FieldValue.increment(Int64(1))]) { _ in }
        }
    }
    func editGroupName(groupID: String, newName: String) {
        if !groupID.isEmpty && !newName.isEmpty {
            db.collection("groupChats").document(groupID).updateData([ "groupName": newName ]) { _ in }
        }
    }
    func editGroupPhoto(groupID: String, newP: String) {
        if !groupID.isEmpty && !newP.isEmpty {
            db.collection("groupChats").document(groupID).updateData([ "photo": newP ]) { _ in }
        }
    }
    func makeGC(name: String?, allU: [String], groupChatID: String, fullname: String){
        if !groupChatID.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            let final = [uid] + allU

            final.forEach { element in
                if !element.isEmpty {
                    db.collection("users").document(element)
                        .updateData(["groupChats": FieldValue.arrayUnion([groupChatID]) ]) { _ in }
                }
            }
            
            var data = ["allUsersUID": final, "timestamp": Timestamp(date: Date())] as [String : Any]
            
            if let r_name = name, !r_name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                data["groupName"] = r_name
            }
            db.collection("groupChats").document(groupChatID)
                .setData(data) { _ in }
            
            let prefix = String(uid.prefix(6)) + String(UUID().uuidString.prefix(8))
            var text = ""
            if fullname.isEmpty {
                text = "Chat created on \(getCurrentDateString())"
            } else {
                text = "\(fullname) started chatting on \(getCurrentDateString())"
            }
            self.sendMessage(docID: groupChatID, text: text, imageUrl: nil, messageID: prefix, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: nil, audioURL: nil, fileURL: nil, exception: true, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
        }
    }
    func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d"
        let dateString = dateFormatter.string(from: Date())
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        let day = dayFormatter.string(from: Date())
        var daySuffix = ""
        if let dayInt = Int(day) {
            switch dayInt {
            case 1, 21, 31:
                daySuffix = "st"
            case 2, 22:
                daySuffix = "nd"
            case 3, 23:
                daySuffix = "rd"
            default:
                daySuffix = "th"
            }
        }
        return dateString + daySuffix
    }
    func getFirst(docID: String, completion: @escaping([GroupMessage]) -> Void){
        if !docID.isEmpty {
            db.collection("groupChats").document(docID).collection("texts")
                .order(by: "timestamp", descending: true).limit(to: 1)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let messages = documents.compactMap({ try? $0.data(as: GroupMessage.self)} )
                    completion(messages)
                }
        } else { completion([]) }
    }
    func getMessages(docID: String, completion: @escaping([GroupMessage]) -> Void){
        if !docID.isEmpty {
            db.collection("groupChats").document(docID).collection("texts")
                .order(by: "timestamp", descending: true).limit(to: 20)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let messages = documents.compactMap({ try? $0.data(as: GroupMessage.self)} )
                    let final = messages.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
                    completion(final)
                }
        } else { completion([]) }
    }
    func getMessagesMore(docID: String, lastdoc: Timestamp, completion: @escaping([GroupMessage]) -> Void){
        if !docID.isEmpty {
            db.collection("groupChats").document(docID).collection("texts")
                .whereField("timestamp", isLessThan: lastdoc)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let messages = documents.compactMap({ try? $0.data(as: GroupMessage.self)} )
                    completion(messages.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }))
                }
        } else { completion([]) }
    }
    func getMessagesNew(docID: String, lastdoc: Timestamp, completion: @escaping([GroupMessage]) -> Void){
        if !docID.isEmpty {
            db.collection("groupChats").document(docID).collection("texts")
                .whereField("timestamp", isGreaterThan: lastdoc)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let messages = documents.compactMap({ try? $0.data(as: GroupMessage.self)} )
                    completion(messages.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }))
                }
        } else { completion([]) }
    }
    func addUserToGroup(docID: String, userID: String){
        if !docID.isEmpty && !userID.isEmpty {
            db.collection("users").document(userID)
                .updateData(["groupChats": FieldValue.arrayUnion([docID]) ]) { _ in }
            
            db.collection("groupChats").document(docID)
                .updateData([ "allUsersUID": FieldValue.arrayUnion([userID]) ]) { _ in }
        }
    }
    func addPinForChat(docID: String, name: String, lat: Double, long: Double) {
        if !docID.isEmpty {
            let pinString = String(lat) + "," + String(long) + "," + name
            
            db.collection("groupChats").document(docID).updateData(["chatPins": FieldValue.arrayUnion([pinString]) ]) { _ in }
        }
    }
    func shareLocation(docID: String, shouldShare: Bool) {
        if !docID.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            if shouldShare {
                db.collection("groupChats").document(docID)
                    .updateData(["sharingLocationUIDS": FieldValue.arrayUnion([uid]) ]) { _ in }
            } else {
                db.collection("groupChats").document(docID)
                    .updateData(["sharingLocationUIDS": FieldValue.arrayRemove([uid]) ]) { _ in }
            }
        }
    }
    func removePinForChat(docID: String, name: String) {
        if !docID.isEmpty {
            db.collection("groupChats").document(docID).updateData(["chatPins": FieldValue.arrayRemove([name]) ]) { _ in }
        }
    }
    func leaveGroup(docID: String, username: String){
        if !docID.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            db.collection("users").document(uid)
                .updateData(["groupChats": FieldValue.arrayRemove([docID]) ]) { _ in }
            
            self.getConversations(docID: docID) { real_convo in
                if let real = real_convo {
                    if real.allUsersUID.count == 1 {
                        db.collection("groupChats").document(docID).collection("texts")
                            .getDocuments { snapshot, _ in
                                if let documents = snapshot?.documents {
                                    documents.forEach { doc in
                                        Firestore.firestore().collection("convos").document(docID).collection("texts")
                                            .document(doc.documentID).delete()
                                    }
                                }
                                Firestore.firestore().collection("groupChats").document(docID).delete()
                            }
                    } else {
                        db.collection("groupChats").document(docID)
                            .updateData([ "allUsersUID": FieldValue.arrayRemove([uid]) ]) { _ in }
                        
                        let prefix = uid.prefix(6)
                        db.collection("groupChats").document(docID).collection("texts")
                            .whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: prefix)
                            .whereField(FieldPath.documentID(), isLessThan: prefix + "\u{f8ff}")
                            .getDocuments { snapshot, _ in
                                if let documents = snapshot?.documents {
                                    documents.forEach { doc in
                                        Firestore.firestore().collection("groupChats").document(docID).collection("texts")
                                            .document(doc.documentID).delete()
                                    }
                                }
                                
                                let m_id = prefix + UUID().uuidString.prefix(7)
                                sendMessage(docID: docID, text: "\(username) left the group", imageUrl: nil, messageID: String(m_id), replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: nil, audioURL: nil, fileURL: nil, exception: true, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                            }
                    }
                }
            }
        }
    }
    func messageSeen(docID: String, textId: String){
        if !docID.isEmpty && !textId.isEmpty {
            db.collection("groupChats").document(docID).collection("texts").document(textId)
                .updateData(["seen": true]) { _ in }
        }
    }
    func deleteOld(convoID: String, messageId: String){
        if !convoID.isEmpty && !messageId.isEmpty {
            db.collection("groupChats").document(convoID).collection("texts").document(messageId).delete()
        }
    }
    func editMessage(newText: String, docID: String, textID: String?){
        if let textID = textID, !docID.isEmpty && !newText.isEmpty {
            db.collection("groupChats").document(docID).collection("texts")
                .document(textID)
                .updateData([ "text" : newText ]) { _ in }
        }
    }
    func votePoll(textID: String?, groupID: String?, count: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let suffix = uid + "\(count)"
        if let id = textID, let gID = groupID {
            if count == 1 {
                db.collection("groupChats").document(gID).collection("texts").document(id)
                    .updateData([
                    "count1": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            } else if count == 2 {
                db.collection("groupChats").document(gID).collection("texts").document(id)
                    .updateData([
                    "count2": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            } else if count == 3 {
                db.collection("groupChats").document(gID).collection("texts").document(id)
                    .updateData([
                    "count3": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            } else {
                db.collection("groupChats").document(gID).collection("texts").document(id)
                    .updateData([
                    "count4": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            }
        }
    }
    func sendMessage(docID: String, text: String, imageUrl: String?, messageID: String, replyFrom: String?, replyText: String?, replyImage: String?, replyVideo: String?, replyAudio: String?, replyFile: String?, videoURL: String?, audioURL: String?, fileURL: String?, exception: Bool, lat: Double?, long: Double?, name: String?, choice1: String?, choice2: String?, choice3: String?, choice4: String?, pinmap: String?){
        if !docID.isEmpty {
            var data = ["timestamp": Timestamp(date: Date())] as [String : Any]
            
            if !text.isEmpty { data["text"] = text }
            if let url = imageUrl { data["imageUrl"] = url }
            if let vid = videoURL { data["videoURL"] = vid }
            if let audio = audioURL { data["audioURL"] = audio }
            if let file = fileURL { data["file"] = file }
            if exception { data["normal"] = true }
            if let pin = pinmap { data["pinmap"] = pin }
            
            if let lat = lat, let long = long, let name = name {
                data["lat"] = lat
                data["long"] = long
                data["name"] = name
            }
            
            if let c1 = choice1, let c2 = choice2 {
                data["choice1"] = c1
                data["choice2"] = c2
                if let c3 = choice3 {
                    data["choice3"] = c3
                }
                if let c4 = choice4 {
                    data["choice4"] = c4
                }
            }

            if let from = replyFrom {
                data["replyFrom"] = from
                if let rep_text = replyText {
                    if rep_text.contains("pub!@#$%^&*()") || extractCoordinates(from: rep_text) != nil {
                        data["replyText"] = rep_text
                    } else {
                        data["replyText"] = String(rep_text.prefix(90))
                    }
                } else if let rep_image = replyImage {
                    data["replyImage"] = rep_image
                } else if let rep_file = replyFile {
                    data["replyFile"] = rep_file
                } else if let rep_Video = replyVideo {
                    data["replyVideo"] = rep_Video
                } else if let rep_Audio = replyAudio {
                    data["replyAudio"] = rep_Audio
                }
            }

            if messageID.isEmpty {
                db.collection("groupChats").document(docID).collection("texts").document().setData(data) { _ in }
            } else {
                db.collection("groupChats").document(docID).collection("texts").document(messageID).setData(data) { _ in }
            }
        }
    }
    func getConversations(docID: String, completion: @escaping(GroupConvo?) -> Void) {
        if !docID.isEmpty {
            db.collection("groupChats").document(docID)
                .getDocument { snapshot, _ in
                    if let snapshot = snapshot, let convo = try? snapshot.data(as: GroupConvo.self) {
                        completion(convo)
                    } else {
                        completion(nil)
                    }
                }
        } else {
            completion(nil)
        }
    }
}
