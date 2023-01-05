import Firebase
import UIKit

struct TweetService {
    let db = Firestore.firestore()
    
    func rateTweet(tweetID: String?, rating: Int) {
        if Auth.auth().currentUser?.uid != nil {
            if let id = tweetID, !id.isEmpty {
                db.collection("tweets").document(id).updateData(["rating": FieldValue.increment(Int64(rating))]) { _ in }
            }
        }
    }
    func addViewTweet(tweetID: String?) {
        if let id = tweetID, !id.isEmpty {
            db.collection("tweets").document(id)
                .updateData(["views": FieldValue.increment(Int64(1))]) { _ in }
        }
    }
    func votePoll(tweetID: String?, count: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let suffix = String(uid.suffix(5))
        if let id = tweetID, !id.isEmpty {
            if count == 1 {
                db.collection("tweets").document(id).updateData([
                    "count1": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            } else if count == 2 {
                db.collection("tweets").document(id).updateData([
                    "count2": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            } else if count == 3 {
                db.collection("tweets").document(id).updateData([
                    "count3": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            } else {
                db.collection("tweets").document(id).updateData([
                    "count4": FieldValue.increment(Int64(1)),
                    "voted": FieldValue.arrayUnion([suffix])
                ]) { _ in }
            }
        }
    }
    func uploadTweet(caption: String, promoted: Int, photo: String, username: String, videoLink: String, content: [uploadContent], userVeri: Bool?, audioURL: URL?, sloc: String?, bloc: String?, lat: Double?, long: Double?, choice1: String?, choice2: String?, choice3: String?, choice4: String?, fullname: String, yelpID: String?, newsID: String?, completion: @escaping(Bool) -> Void){
        
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        var data = ["uid": uid,
                    "caption": caption,
                    "comments": 0,
                    "username": username,
                    "fullname": fullname,
                    "timestamp": Timestamp(date: Date())] as [String : Any]
        if promoted > 0 {
            let date = Calendar.current.date(byAdding: .day, value: promoted + 1, to: Date())!
            data["promoted"] = Timestamp(date: date)
        }
        if !photo.isEmpty {
            data["profilephoto"] = photo
        }
        if let id = yelpID, !id.isEmpty {
            data["yelpID"] = id
        }
        if let id = newsID, !id.isEmpty {
            data["newsID"] = id
        }
        if !videoLink.isEmpty {
            data["video"] = videoLink
        }
        if let veri = userVeri {
            if veri { data["veriUser"] = true }
        }
        let hashtags = Array(Set(extractHashtags(from: caption)).prefix(10))
        if !hashtags.isEmpty {
            data["hashtags"] = hashtags
        }
        if let sloc = sloc, let bloc = bloc, let lat = lat, let long = long {
            data["sLoc"] = sloc
            data["bLoc"] = bloc
            data["lat"] = lat
            data["long"] = long
        }
        if let c1 = choice1, let c2 = choice2 {
            data["choice1"] = c1
            data["choice2"] = c2
            if let c3 = choice3, let c4 = choice4 {
                data["choice3"] = c3
                data["choice4"] = c4
            }
        }
        if !content.isEmpty {
            var finalArr = [String?](repeating: nil, count: content.count)
            for i in 0..<content.count {
                if let image = content[i].selectedImage, content[i].isImage {
                    ImageUploader.uploadImage(image: image, location: "hustlesImages", compression: 0.25) { new, _ in
                        finalArr[i] = new

                        if finalArr.compactMap({ $0 }).count == content.count {
                            finalArr.removeAll(where: { ($0 ?? "").isEmpty })
                            data["contentArray"] = finalArr
                            db.collection("tweets").document()
                                .setData(data) { error in
                                    if error != nil {
                                        completion(false)
                                        return
                                    }
                                    completion(true)
                                }
                        }
                    }
                } else if let vid = content[i].videoURL {
                    ImageUploader.uploadVideoToFB(localVideoURL: vid) { new in
                        finalArr[i] = new ?? ""
                        if finalArr.compactMap({ $0 }).count == content.count {
                            finalArr.removeAll(where: { ($0 ?? "").isEmpty })
                            data["contentArray"] = finalArr
                            db.collection("tweets").document()
                                .setData(data) { error in
                                    if error != nil {
                                        completion(false)
                                        return
                                    }
                                    completion(true)
                                }
                        }
                    }
                } else if let already = content[i].imageURL {
                    finalArr[i] = already
                    if finalArr.compactMap({ $0 }).count == content.count {
                        finalArr.removeAll(where: { ($0 ?? "").isEmpty })
                        data["contentArray"] = finalArr
                        db.collection("tweets").document()
                            .setData(data) { error in
                                if error != nil {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                    }
                } else {
                    finalArr[i] = ""
                    if finalArr.compactMap({ $0 }).count == content.count {
                        finalArr.removeAll(where: { ($0 ?? "").isEmpty })
                        data["contentArray"] = finalArr
                        db.collection("tweets").document()
                            .setData(data) { error in
                                if error != nil {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                    }
                }
            }
        } else if let audio = audioURL {
            ImageUploader.uploadAudioToFirebaseStorage(localURL: audio) { tweetUrl in
                data["audioURL"] = tweetUrl
                db.collection("tweets").document()
                    .setData(data) { error in
                        if error != nil {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
            }
        } else {
            db.collection("tweets").document()
                .setData(data) { error in
                    if error != nil {
                        completion(false)
                        return
                    }
                    completion(true)
                }
        }
    }
    func getComments(tweet: Tweet, completion: @escaping([Comment]) -> Void){
        if var tweetId = tweet.id {
            var query =  db.collection("tweets")
            if tweet.start != nil {
                query =  db.collection("ads")
                tweetId = String(tweetId.dropLast(4))
            }
            query.document(tweetId).collection("comments").order(by: "timestamp", descending: true).limit(to: 15)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let comments = documents.compactMap({ try? $0.data(as: Comment.self)} )
                    completion(comments)
                }
            
        } else {
            completion([])
        }
    }
    func getCommentsMore(tweetId: String, date: Timestamp, ad: Bool, completion: @escaping([Comment]) -> Void){
        if !tweetId.isEmpty {
            var query = db.collection("tweets")
            if ad {
                query = db.collection("ads")
            }
            query.document(tweetId).collection("comments").whereField("timestamp", isLessThan: date).order(by: "timestamp", descending: true).limit(to: 15)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let comments = documents.compactMap({ try? $0.data(as: Comment.self)} )
                    completion(comments)
                }
        } else {
            completion([])
        }
    }
    func uploadComment(tweetId: String, text: String, photo: String, username: String, ad: Bool, commentID: String){
        if !tweetId.isEmpty {
            var data = ["text": text,
                        "username": username,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            if !photo.isEmpty {
                data["profilephoto"] = photo
            }
            var query = db.collection("tweets")
            if ad {
                query = db.collection("ads")
            }
            query.document(tweetId)
                .updateData(["comments": FieldValue.increment(Int64(1))]) { _ in }
            query.document(tweetId).collection("comments").document(commentID)
                .setData(data) { _ in }
        }
    }
    func deleteComment(tweetId: String?, commentID: String?, ad: Bool, hasReps: Bool){
        if let id1 = tweetId, let id2 = commentID {
            if hasReps {
                let query = db.collection(ad ? "ads" : "tweets").document(id1).collection("comments").document(id2).collection("replies")
                query.getDocuments { snapshot, _ in
                        if let documents = snapshot?.documents {
                            documents.forEach { doc in
                                query.document(doc.documentID).delete()
                            }
                        }
                    }
            }
            if ad {
                db.collection("ads").document(id1).collection("comments").document(id2).delete()
                db.collection("ads").document(id1).updateData(["comments": FieldValue.increment(Int64(-1))]) { _ in }
            } else {
                db.collection("tweets").document(id1).collection("comments").document(id2).delete()
                db.collection("tweets").document(id1).updateData(["comments": FieldValue.increment(Int64(-1))]) { _ in }
            }
        }
    }
    func deleteCommentReply(hustleID: String, commentID: String, replyID: String, ad: Bool){
        if !hustleID.isEmpty && !commentID.isEmpty {
            if ad {
                db.collection("ads").document(hustleID).collection("comments").document(commentID).collection("replies").document(replyID).delete()
                db.collection("ads").document(hustleID).collection("comments").document(commentID).updateData(["replies": FieldValue.increment(Int64(-1))]) { _ in }
            } else {
                db.collection("tweets").document(hustleID).collection("comments").document(commentID).collection("replies").document(replyID).delete()
                db.collection("tweets").document(hustleID).collection("comments").document(commentID).updateData(["replies": FieldValue.increment(Int64(-1))]) { _ in }
            }
        }
    }
    func uploadReply(tweetId: String, text: String, photo: String, username: String, ad: Bool, commentID: String, replyID: String){
        if !tweetId.isEmpty && !commentID.isEmpty {
            var data = ["text": text,
                        "username": username,
                        "timestamp": Timestamp(date: Date())] as [String : Any]
            if !photo.isEmpty {
                data["profilephoto"] = photo
            }
            var query = db.collection("tweets")
            if ad {
                query = db.collection("ads")
            }
            query.document(tweetId).collection("comments").document(commentID)
                .updateData(["replies": FieldValue.increment(Int64(1))]) { _ in }
            
            query.document(tweetId).collection("comments").document(commentID).collection("replies").document(replyID)
                .setData(data) { _ in }
        }
    }
    func getReplies(tweetId: String, commentId: String, date: Timestamp?, ad: Bool, completion: @escaping([Comment]) -> Void){
        if !tweetId.isEmpty && !commentId.isEmpty {
            var query = db.collection("tweets")
            if ad {
                query = db.collection("ads")
            }
            if let last = date {
                query.document(tweetId).collection("comments").document(commentId).collection("replies").whereField("timestamp", isLessThan: last).order(by: "timestamp", descending: true).limit(to: 15)
                    .getDocuments { snapshot, _ in
                        guard let documents = snapshot?.documents else {
                            completion([])
                            return
                        }
                        let comments = documents.compactMap({ try? $0.data(as: Comment.self)} )
                        completion(comments)
                    }
            } else {
                query.document(tweetId).collection("comments").document(commentId).collection("replies").order(by: "timestamp", descending: true).limit(to: 15)
                    .getDocuments { snapshot, _ in
                        guard let documents = snapshot?.documents else {
                            completion([])
                            return
                        }
                        let comments = documents.compactMap({ try? $0.data(as: Comment.self)} )
                        completion(comments)
                    }
            }
        } else {
            completion([])
        }
    }
    func fetchUserTweet(forUid uid: String, completion: @escaping([Tweet]) -> Void){
        db.collection("tweets")
            .whereField("uid", isEqualTo: uid).limit(to: 1000)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                completion(tweets.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }) )
            }
    }
    func fetchSaved(all: [String], completion: @escaping([Tweet]) -> Void) {
        if !all.isEmpty {
            db.collection("tweets")
                .whereField(FieldPath.documentID(), in: all).limit(to: 100)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                    completion(tweets.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }) )
                }
        }
    }
    func fetchUserQuestions(uid: String, completion: @escaping([Question]) -> Void){
        db.collection("Questions")
            .whereField("uid", isEqualTo: uid).limit(to: 300)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let questions = documents.compactMap({ try? $0.data(as: Question.self)} )
                completion(questions.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }) )
            }
    }
    func fetchUserJob(country: String, state: String, city: String, remote: Bool, forUid uid: String, completion: @escaping([Tweet]) -> Void){
        if ((country.isEmpty || city.isEmpty) && !remote) || uid.isEmpty {
            completion([])
            return
        }
        
        var query = db.collection("remote")
        if !remote {
            if state.isEmpty {
                query = db.collection("jobs").document(country).collection("jobs").document(city).collection("jobs")
            } else {
                query = db.collection("jobs").document(country).collection("jobs").document(state).collection("jobs").document(city).collection("jobs")
            }
        }
        query.whereField("uid", isEqualTo: uid).limit(to: 50)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let jobs = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                completion(jobs.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }) )
            }
    }
    func fetchUserShop(country: String, state: String, city: String, uid: String, completion: @escaping([Shop]) -> Void){
        if (country.isEmpty && city.isEmpty) || uid.isEmpty {
            completion([])
            return
        }
        var query = db.collection("shop").document(country).collection("shop").document(city).collection("shop")
        
        if !state.isEmpty {
            query = db.collection("shop").document(country).collection("shop").document(state).collection("shop").document(city).collection("shop")
        }
        
        query.whereField("uid", isEqualTo: uid)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let sales = documents.compactMap({ try? $0.data(as: Shop.self)} )
                completion(sales.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }) )
            }
    }
    func fetchLocation(city: String, completion: @escaping([Tweet]) -> Void){
        let query = db.collection("tweets").whereField("sLoc", isEqualTo: city).limit(to: 50)
        query.getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                completion(tweets.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }))
            }
    }
    func fetchRecentHashtags(completion: @escaping([String]) -> Void){
        let query = db.collection("tweets")
                        .order(by: "hashtags")
                        .order(by: "timestamp", descending: true)
                        .limit(to: 10)
        
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let hustles = documents.compactMap({ try? $0.data(as: Tweet.self)} )
            var allHashes = [String]()
            hustles.forEach { element in
                if let hashes = element.hashtags {
                    allHashes += hashes
                }
            }
            allHashes = Array(Set(allHashes)).shuffled()
            completion(allHashes)
        }
    }
    func fetchSuggested(completion: @escaping([User]) -> Void){
        let uid = Auth.auth().currentUser?.uid ?? ""
        let query = db.collection("users").whereField("verified", isEqualTo: true).limit(to: 25)
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            var users = documents.compactMap({ try? $0.data(as: User.self)} )
            users.removeAll(where: { $0.id == uid })
            if users.count < 5 {
                let querySec = db.collection("users").order(by: "followers", descending: true).limit(to: 25 - users.count)
                querySec.getDocuments { snapshotSec, _ in
                    guard let documents = snapshotSec?.documents else {
                        completion(users)
                        return
                    }
                    var usersSec = documents.compactMap({ try? $0.data(as: User.self)} )
                    usersSec.removeAll(where: { $0.id == uid })
                    let total = users + usersSec.filter { !users.contains($0) }
                    completion(total)
                }
            } else {
                completion(users)
            }
        }
    }
    func fetchNew(newest: Timestamp?, completion: @escaping([Tweet]) -> Void){
        var query = db.collection("tweets").order(by: "timestamp", descending: true).limit(to: 25)
        
        if let newest {
            query = db.collection("tweets")
                        .whereField("timestamp", isGreaterThan: newest)
                        .order(by: "timestamp", descending: true)
                        .limit(to: 25)
        }
        
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
            completion(tweets)
        }
    }
    func fetchNewMore(lastdoc: Timestamp, completion: @escaping([Tweet]) -> Void){
        let query = db.collection("tweets")
                        .whereField("timestamp", isLessThan: lastdoc)
                        .order(by: "timestamp", descending: true)
                        .limit(to: 25)
        
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
            completion(tweets)
        }
    }
    func fetchFollowers(newest: Timestamp?, following: [String], completion: @escaping([Tweet]) -> Void){
        var final = following
        let uid = Auth.auth().currentUser?.uid ?? ""
        final.removeAll(where: { $0 == uid })

        var query = db.collection("tweets")
            .whereField("uid", in: final)
            .whereField("timestamp", isLessThan: Timestamp())
            .order(by: "timestamp", descending: true)
            .limit(to: 25)
        
        if let newest {
            query = db.collection("tweets")
                        .whereField("uid", in: final)
                        .whereField("timestamp", isGreaterThan: newest)
                        .order(by: "timestamp", descending: true)
                        .limit(to: 25)
        }
        
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
            completion(tweets.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }) )
        }
    }
    func fetchFollowersMore(following: [String], lastdoc: Timestamp, completion: @escaping([Tweet]) -> Void){
        var final = following
        let uid = Auth.auth().currentUser?.uid ?? ""
        final.removeAll(where: { $0 == uid })
        
        let query = db.collection("tweets")
                        .whereField("uid", in: final)
                        .whereField("timestamp", isLessThan: lastdoc)
                        .order(by: "timestamp", descending: true)
                        .limit(to: 25)
        
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
            completion(tweets)
        }
    }
    func fetchAudioPosts(newest: Timestamp?, completion: @escaping([Tweet]) -> Void){
        var query = db.collection("tweets")
                        .order(by: "audioURL")
                        .order(by: "timestamp", descending: true)
                        .limit(to: 15)
        
        if let newest {
            query = db.collection("tweets")
                        .order(by: "audioURL")
                        .whereField("timestamp", isGreaterThan: newest)
                        .order(by: "timestamp", descending: true)
                        .limit(to: 15)
        }
        
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
            completion(tweets)
        }
    }
    func fetchAudioPostsMore(lastdoc: Timestamp, completion: @escaping([Tweet]) -> Void){
        let query = db.collection("tweets")
                        .order(by: "audioURL")
                        .whereField("timestamp", isLessThan: lastdoc)
                        .order(by: "timestamp", descending: true)
                        .limit(to: 25)
        
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
            completion(tweets)
        }
    }
    func deleteHustle(hustle: Tweet){
        if let id = hustle.id {
            if let comments = hustle.comments, comments > 0 {
                let collectionRef = db.collection("tweets").document(id).collection("comments")
                collectionRef
                    .getDocuments { snapshot, _ in
                        guard let documents = snapshot?.documents else { return }
                        for document in documents {
                            collectionRef.document(document.documentID).delete { _ in }
                        }
                    }
            }
            db.collection("tweets").document(id).delete()
        }
    }
    func verifyHustle(id: String?, good: Bool, uid: String, amount: Int){
        if let id = id {
            let docRef = db.collection("tweets").document(id)
            docRef.updateData([ "verified": good ]) { _ in }
            
            db.collection("users").document(uid)
                .updateData([ "elo": FieldValue.increment(Int64(amount)) ]) { _ in }
        }
    }
    func likeTweet(_ tweet: Tweet){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let tweetId = tweet.id else { return }
        let docRef = db.collection("users").document(uid)
        
        db.collection("tweets").document(tweetId)
            .updateData(["likes": FieldValue.arrayUnion([uid])]) { _ in
                docRef.updateData([
                    "likedHustles": FieldValue.arrayUnion([tweetId])
                ]) { _ in }
            }
    }
    func unlikeTweet(_ tweet: Tweet){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let tweetId = tweet.id else { return }
        if let likes = tweet.likes {
            if likes.count > 0 {
                let docRef = db.collection("users").document(uid)
                
                db.collection("tweets").document(tweetId)
                    .updateData(["likes": FieldValue.arrayRemove([uid])]) { _ in
                        docRef.updateData([
                            "likedHustles": FieldValue.arrayRemove([tweetId])
                        ]) { _ in }
                    }
                
            }
        }
    }
    func fetchLikedTweets(tweetID: String, completion: @escaping(Tweet?) -> Void){
        if !tweetID.isEmpty {
            db.collection("tweets")
                .document(tweetID)
                .getDocument { snapshot, _ in
                    guard let tweet = try? snapshot?.data(as: Tweet.self) else {
                        completion(nil)
                        return
                    }
                    completion(tweet)
            }
        } else {
            completion(nil)
        }
    }
}
