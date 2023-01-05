import Firebase

struct UserService {
    let db = Firestore.firestore()
    
    func addPinForUser(name: String, lat: Double, long: Double) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let pinString = String(lat) + "," + String(long) + "," + name
        
        db.collection("users").document(uid).updateData(["mapPins": FieldValue.arrayUnion([pinString]) ]) { _ in }
    }
    func removePinForUser(name: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        db.collection("users").document(uid).updateData(["mapPins": FieldValue.arrayRemove([name]) ]) { _ in }
    }
    func getHighlightMemories(start: Timestamp, end: Timestamp, completion: @escaping([Memory]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("memories").document(uid).collection("all")
            .whereField("createdAt", isLessThanOrEqualTo: end)
            .whereField("createdAt", isGreaterThanOrEqualTo: start)
            .order(by: "createdAt", descending: true).limit(to: 30)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let memories = documents.compactMap({ try? $0.data(as: Memory.self)} )
                completion(memories)
            }
    }
    func fetchMemory(uid: String, id: String, completion: @escaping(Memory?) -> Void){
        if !id.isEmpty && !uid.isEmpty {
            db.collection("memories").document(uid).collection("all")
                .document(id)
                .getDocument { snapshot, _ in
                    guard let snapshot = snapshot else {
                        completion(nil)
                        return
                    }
                    let tweet = try? snapshot.data(as: Memory.self)
                    completion(tweet)
                }
        } else {
            completion(nil)
        }
    }
    func getMemories(after: Timestamp?, completion: @escaping([Memory]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        var query = db.collection("memories").document(uid).collection("all").order(by: "createdAt", descending: true).limit(to: 30)
        if let after = after {
            query = db.collection("memories").document(uid).collection("all").whereField("createdAt", isLessThan: after).order(by: "createdAt", descending: true).limit(to: 30)
        }
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let memories = documents.compactMap({ try? $0.data(as: Memory.self)} )
            completion(memories)
        }
    }
    func getMemoriesMap(completion: @escaping ([Memory], Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([], false)
            return
        }
        
        let query = db.collection("memories").document(uid).collection("all")
            .order(by: "lat")
            .limit(to: 200)

        query.getDocuments { snapshot, error in
            if error != nil {
                completion([], false)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion([], true)
                return
            }

            let memories = documents.compactMap { try? $0.data(as: Memory.self) }
            completion(memories, true)
        }
    }
    func deleteMemory(memID: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if !memID.isEmpty {
            db.collection("memories").document(uid).collection("all").document(memID).delete()
            
            db.collection("memories").document(uid)
                .updateData(["count": FieldValue.increment(Int64(-1))]) { _ in }
        }
    }
    func saveMemories(docID: String, imageURL: String?, videoURL: String?, lat: CGFloat?, long: CGFloat?) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if imageURL != nil || videoURL != nil {
            var data = ["createdAt": Timestamp(date: Date())] as [String : Any]
            
            if let image = imageURL {
                data["image"] = image
            } else if let video = videoURL {
                data["video"] = video
            }
            
            if let lat = lat {
                data["lat"] = lat
            }
            if let long = long {
                data["long"] = long
            }
            
            updateMemoryCount(uid: uid) {
                db.collection("memories").document(uid).collection("all").document(docID)
                    .setData(data) { _ in }
            }
        }
    }
    func updateMemoryCount(uid: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("memories").document(uid)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let docSnapshot: DocumentSnapshot
            do {
                try docSnapshot = transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            if docSnapshot.exists {
                if (docSnapshot.data()?["count"] as? Int64) != nil {
                    transaction.updateData(["count": FieldValue.increment(Int64(1))], forDocument: docRef)
                } else {
                    transaction.updateData(["count": 1], forDocument: docRef)
                }
            } else {
                transaction.setData(["count": 1], forDocument: docRef)
            }
            return nil
        }) { (object, _) in
            completion()
        }
    }
    func updateUserLocation(newString: String){
        if !newString.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            db.collection("users").document(uid).updateData(["currentLocation": newString]) { _ in }
        }
    }
    func updateUserBattery(percent: Double){
        if percent >= 0.0 && percent <= 1.0 {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            db.collection("users").document(uid).updateData(["currentBatteryPercentage": percent]) { _ in }
        }
    }
    func seenNow(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData(["lastSeen": Timestamp()]) { _ in }
    }
    func addChatPin(id: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if !id.isEmpty {
            db.collection("users").document(uid).updateData(["pinnedChats": FieldValue.arrayUnion([id]) ]) { _ in }
        }
    }
    func removeChatPin(id: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if !id.isEmpty {
            db.collection("users").document(uid).updateData(["pinnedChats": FieldValue.arrayRemove([id]) ]) { _ in }
        }
    }
    func getFriendsNumber(numbers: [String], completion: @escaping([User]) -> Void) {
        if numbers.isEmpty {
            completion([])
        } else {
            db.collection("users")
                .whereField("phoneNumber", in: numbers)
                .limit(to: 50)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let users = documents.compactMap({ try? $0.data(as: User.self)} )
                    completion(users)
                }
        }
    }
    func getManyUsers(users: [String], limit: Int, completion: @escaping([User]) -> Void) {
        if users.isEmpty {
            completion([])
        } else {
            db.collection("users")
                .whereField(FieldPath.documentID(), in: users)
                .limit(to: limit)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let users = documents.compactMap({ try? $0.data(as: User.self)} )
                    completion(users)
                }
        }
    }
    func addNumber(new: String) {
        if !new.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            db.collection("users").document(uid).updateData(["phoneNumber": new ]) { _ in }
        }
    }
    func addPostSave(id: String?) {
        if let id = id, !id.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            db.collection("users").document(uid).updateData(["savedPosts": FieldValue.arrayUnion([id]) ]) { _ in }
        }
    }
    func removePostSave(id: String?) {
        if let id = id, !id.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            db.collection("users").document(uid).updateData(["savedPosts": FieldValue.arrayRemove([id]) ]) { _ in }
        }
    }
    func getTop(completion: @escaping([User]) -> Void){
        db.collection("users").order(by: "followers", descending: true).limit(to: 8)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let users = documents.compactMap({ try? $0.data(as: User.self)} )
                completion(users)
            }
    }
    func verifyUser(withUid uid: String, completion: @escaping(Bool) -> Void){
        if !uid.isEmpty {
            db.collection("users").document(uid)
                .getDocument { snapshot, _ in
                    guard snapshot != nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                }
            
        }
    }
    func fetchUserWithRedo(withUid uid: String, completion: @escaping(User) -> Void){
        if !uid.isEmpty {
            db.collection("users")
                .document(uid)
                .getDocument { snapshot, _ in
                    if let snapshot = snapshot, let user = try? snapshot.data(as: User.self) {
                        completion(user)
                    } else {
                        db.collection("users")
                            .document(uid)
                            .getDocument { snapshot, _ in
                                guard let snapshot = snapshot else { return }
                                guard let user = try? snapshot.data(as: User.self) else { return }
                                completion(user)
                            }
                        
                    }
                }
            
        }
    }
    func fetchUser(withUid uid: String, completion: @escaping(User) -> Void){
        if !uid.isEmpty {
            db.collection("users")
                .document(uid)
                .getDocument { snapshot, _ in
                    guard let snapshot = snapshot else { return }
                    guard let user = try? snapshot.data(as: User.self) else { return }
                    completion(user)
                }
        }
    }
    func fetchTweet(id: String, completion: @escaping(Tweet?) -> Void){
        if !id.isEmpty {
            db.collection("tweets")
                .document(id)
                .getDocument { snapshot, _ in
                    guard let snapshot = snapshot else {
                        completion(nil)
                        return
                    }
                    let tweet = try? snapshot.data(as: Tweet.self)
                    completion(tweet)
                }
        } else {
            completion(nil)
        }
    }
    func fetchStory(id: String, completion: @escaping(Story?) -> Void){
        if !id.isEmpty {
            db.collection("stories")
                .document(id)
                .getDocument { snapshot, _ in
                    guard let snapshot = snapshot else {
                        completion(nil)
                        return
                    }

                    if let story = try? snapshot.data(as: Story.self) {
                        let twentyFourHoursInSeconds: TimeInterval = 48 * 60 * 60
                        let currentTime = Date()
                        
                        if story.infinite == nil {
                            let storyTimestamp = story.timestamp.dateValue()
                            let timeDifference = currentTime.timeIntervalSince(storyTimestamp)
                            
                            if timeDifference <= twentyFourHoursInSeconds {
                                completion(story)
                            } else {
                                completion(nil)
                                db.collection("stories").document(id).delete()
                            }
                        }

                        completion(story)
                    } else {
                        completion(nil)
                        return
                    }
                }
        } else {
            completion(nil)
        }
    }
    func fetchUserUsername(username: String, completion: @escaping(User?) -> Void){
        if !username.isEmpty {
            db.collection("users")
                .whereField("username", isEqualTo: username).limit(to: 1)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion(nil)
                        return
                    }
                    let user = documents.compactMap({ try? $0.data(as: User.self)} ).first
                    completion(user)
                }
        }
    }
    func fetchSafeUser(withUid uid: String, completion: @escaping(User?) -> Void){
        if !uid.isEmpty {
            db.collection("users")
                .document(uid)
                .getDocument { snapshot, _ in
                    guard let snapshot = snapshot else {
                        completion(nil)
                        return
                    }
                    guard let user = try? snapshot.data(as: User.self) else {
                        completion(nil)
                        return
                    }
                    completion(user)
                }
        } else {
            completion(nil)
        }
    }
    func editElo(withUid userid: String?, withAmount elo: Int, completion: @escaping() -> Void){
        let uid: String
        if let userid = userid{
            uid = userid
        } else {
            guard let u1 = Auth.auth().currentUser?.uid else { return }
            uid = u1
        }
        if !uid.isEmpty {
            db.collection("users").document(uid)
                .updateData(["elo": FieldValue.increment(Int64(elo))]) { _ in
                    completion()
                }
        }
    }
    func editBio(new: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if !uid.isEmpty {
            db.collection("users").document(uid)
                .updateData(["bio": new]) { _ in }
        }
    }
    func editBackground(newURL: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if !uid.isEmpty {
            db.collection("users").document(uid)
                .updateData(["userBackground": newURL]) { _ in }
        }
    }
    func editAlerts(count: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(uid)

        docRef.updateData([ "alertsShown": count ]) { _ in }
    }
    func editBadges(title: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(uid)
 
        docRef.updateData([ "badges": FieldValue.arrayUnion([title]) ]) { _ in }
    }
    func follow(withUid userId: String, completion: @escaping() -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if !userId.isEmpty {
            db.collection("users").document(uid)
                .updateData(["following": FieldValue.arrayUnion([userId])]) { _ in
                    db.collection("users").document(userId)
                        .updateData(["followers": FieldValue.increment(Int64(1))]) { _ in
                            completion()
                        }
                }
        }
    }
    func unfollow(withUid userId: String, completion: @escaping() -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if !userId.isEmpty {
            db.collection("users").document(uid)
                .updateData(["following": FieldValue.arrayRemove([userId])]) { _ in
                    db.collection("users").document(userId)
                        .updateData(["followers": FieldValue.increment(Int64(-1))]) { _ in
                            completion()
                        }
                    
                }
        }
    }
    func deleteAccount(userID: String){
        if !userID.isEmpty { db.collection("users").document(userID).delete() }
    }
    func blockUser(uid: String){
        if !uid.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            db.collection("users").document(uid)
                .updateData(["blockedUsers": FieldValue.arrayUnion([uid])]) { _ in }
        }
    }
    func unblockUser(uid: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if !uid.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            db.collection("users").document(uid)
                .updateData(["blockedUsers": FieldValue.arrayRemove([uid])]) { _ in }
        }
    }
    func reportContent(type: String, postID: String){
        if Auth.auth().currentUser != nil {
            let data = ["type": type, "id": postID, "timestamp": Timestamp(date: Date())] as [String : Any]
            db.collection("reported").document().setData(data) { _ in }
        }
    }
}
