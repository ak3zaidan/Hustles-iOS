import Firebase
import UIKit

enum TweetFilterViewModel: Int, CaseIterable {
    case hustles
    case jobs
    case likes
    case sale
    case questions
    
    var title: String {
        switch self {
            case .hustles: return "Hustles"
            case .jobs: return "Jobs"
            case .likes: return "Likes"
            case .sale: return "4Sale"
            case .questions: return "???"
        }
    }
}

class ProfileViewModel: ObservableObject {
    @Published var allSaved = [Tweet]()
    @Published var invited = [String]()
    @Published var allContacts = [Friends]()
    @Published var contactFriends = [matchFriends]()
    @Published var gettingContacts: Bool = false
    @Published var startedFollowing = [String]()
    @Published var fetching: Bool = false
    @Published var savedStories = [String]()
    @Published var storyViews: [(String, [User])] = []
    @Published var viewedStories = [String()]
    @Published var addedStoriesImages: [(String, UIImage)] = []
    @Published var addedStoriesVideos: [(String, String)] = []
    @Published var blockedUsers = [User]()
    @Published var users = [Profile]()
    @Published var currentUser: Int?
    @Published var isCurrentUser: Bool = false
    private let service = TweetService()
    private let userService = UserService()
    @Published var updatingElo: Bool = false
    @Published var tokenToShow = ""
    @Published var unlockToShow: Int? = nil
    @Published var exeFuncToDisplay: Bool = false
    @Published var canClickStoriesButton: Bool = true
    @Published var statusPiece: String = "PAWN"
    @Published var access = [""]
    @Published var degrees: Double = 70
    @Published var nextPiece: Int = 70
    @Published var nextUnlock: String = "PAWN"
    @Published var sliderValue = 0.0
    @Published var sliderBound = 0.0
    @Published var deleteAccountError = ""
    @Published var deleteUsername = ""
    @Published var deletePassword = ""
    @Published var newName = ""
    @Published var newPass = ""
    @Published var selectedStories = [Story]()
    var mid: String = ""
    var isStoryRow: Bool = false
    var pawnAccess = ["-1 hustle per hour", "-1 job/sale per hour", "-Create 1 Group", "-Ask Questions"]
    var bishopAccess = ["**Create Unlimited Groups**", "-3 Hustles or jobs per hour", "-Answer questions", "-Cast a vote"]
    var knightAccess = ["-Upload tips 1 per hour", "**Promote posts with ELO**", "-Unlimited Hustle/Job upload"]
    var rookAccess = ["-Unlimited Tip upload", "-Auto promoted Shop Posts", "-Bonus 150 ELO"]
    var queenAcess = ["-no delay in collection posts", "-Auto promoted Jobs", "-Bonus 100 ELO"]
    var kingAccess = ["-Auto promoted Hustles", "-Communicate with Developers", "-Featured Comments on Posts", "-Auto promoted questions"]
    var nextAccess = ["-Post Videos (Swipes)", "-Coming Soon"]
    
    func getAllSaved(all: [String]) {
        service.fetchSaved(all: all) { hustles in
            DispatchQueue.main.async {
                self.allSaved = hustles
            }
        }
    }
    func getContacts() {
        self.gettingContacts = true
        let numbers = allContacts.map { $0.phoneNumber }
        userService.getFriendsNumber(numbers: numbers) { users in
            self.gettingContacts = false
            
            users.forEach { user in
                if let first = self.allContacts.first(where: { $0.phoneNumber == user.phoneNumber ?? "NA" }) {
                    self.contactFriends.append(matchFriends(user: user, number: first.phoneNumber))
                } else {
                    self.contactFriends.append(matchFriends(user: user, number: nil))
                }
            }
            self.contactFriends.sort { $0.user.fullname < $1.user.fullname }
        }
    }
    func sendNotif(taggerName: String, taggerUID: String, taggedUID: String){
        ExploreService().sendNotification(type: "Profile", taggerUsername: taggerName, taggedUsername: "", taggedUID: taggedUID, caption: "", tweetID: nil, groupName: nil, newsName: nil, questionID: nil, taggerUID: taggerUID)
    }
    func fetchStoryViews(id: String, users: [String]){
        users.forEach { user in
            GlobeService().getStoryViews(id: user) { op_user in
                if let final = op_user {
                    if let x = self.storyViews.firstIndex(where: { $0.0 == id }){
                        self.storyViews[x].1.append(final)
                    } else {
                        self.storyViews.append((id, [final]))
                    }
                }
            }
        }
    }
    func sortStoryViews(id: String, query: String){
        if let x = self.storyViews.firstIndex(where: { $0.0 == id }){
            let lowercasedQuery = query.lowercased()
            storyViews[x].1.sort { (user1, user2) -> Bool in
                let lowercasedUser1 = user1.username.lowercased()
                let lowercasedUser2 = user2.username.lowercased()
                
                if lowercasedUser1.contains(lowercasedQuery) && !lowercasedUser2.contains(lowercasedQuery) {
                    return true
                } else if !lowercasedUser1.contains(lowercasedQuery) && lowercasedUser2.contains(lowercasedQuery) {
                    return false
                } else {
                    return lowercasedUser1 < lowercasedUser2
                }
            }
        }
    }
    func fetchStories(completion: @escaping() -> Void) {
        canClickStoriesButton = false
        if let index = self.currentUser {
            GlobeService().getUserStories(otherUser: self.users[index].user.id) { stories in
                self.canClickStoriesButton = true
                self.users[index].stories = stories
                self.users[index].lastUpdatedStories = Date()
                completion()
            }
        }
    }
    func fetchStoriesUser(user: User, completion: @escaping([Story]) -> Void) {
        if let uid = user.id {
            if !self.users.contains(where: { $0.user.id == uid }) {
                self.users.append(Profile(user: user))
            }
            GlobeService().getUserStories(otherUser: uid) { stories in
                if let index = self.users.firstIndex(where: { $0.user.id == uid }) {
                    self.users[index].stories = stories
                    self.users[index].lastUpdatedStories = Date()
                }
                completion(stories)
            }
        }
    }
    func updateStoriesUser(user: User) {
        if let uid = user.id {
            if let profile = self.users.first(where: { $0.user.id == uid }) {
                let date = profile.lastUpdatedStories
                
                if date == nil || (date != nil && isDateAtLeastOneMinuteOld(date: date ?? Date())) {
                    if let index = self.users.firstIndex(where: { $0.user.id == uid }) {
                        self.users[index].lastUpdatedStories = Date()
                    }
                    GlobeService().getUserStories(otherUser: uid) { stories in
                        if let index = self.users.firstIndex(where: { $0.user.id == uid }) {
                            self.users[index].stories = stories
                            
                            if let first = self.selectedStories.first?.uid, first == uid {
                                if self.selectedStories.count <= stories.count {
                                    self.selectedStories = stories
                                }
                            }
                        }
                    }
                }
            } else {
                fetchStoriesUser(user: user) { _ in }
            }
        }
    }
    func getUpdatedStoriesUser(user: User?, uid: String, completion: @escaping([Story]) -> Void) {
        if let profile = self.users.first(where: { $0.user.id == uid }) {
            let date = profile.lastUpdatedStories
            
            if date == nil || (date != nil && isDateAtLeastOneMinuteOld(date: date ?? Date())) {
                GlobeService().getUserStories(otherUser: uid) { stories in
                    if let index = self.users.firstIndex(where: { $0.user.id == uid }) {
                        self.users[index].stories = stories
                        self.users[index].lastUpdatedStories = Date()
                    }
                    completion(stories)
                }
            } else if let index = self.users.firstIndex(where: { $0.user.id == uid }) {
                completion(self.users[index].stories ?? [])
            }
        } else if let user {
            if !self.users.contains(where: { $0.user.id == uid }) {
                self.users.append(Profile(user: user))
            }
            GlobeService().getUserStories(otherUser: uid) { stories in
                if let index = self.users.firstIndex(where: { $0.user.id == uid }) {
                    self.users[index].stories = stories
                    self.users[index].lastUpdatedStories = Date()
                }
                completion(stories)
            }
        } else if !uid.isEmpty {
            UserService().fetchSafeUser(withUid: uid) { found_user in
                if let found_user {
                    if !self.users.contains(where: { $0.user.id == uid }) {
                        self.users.append(Profile(user: found_user))
                    }
                    GlobeService().getUserStories(otherUser: uid) { stories in
                        if let index = self.users.firstIndex(where: { $0.user.id == uid }) {
                            self.users[index].stories = stories
                            self.users[index].lastUpdatedStories = Date()
                        }
                        completion(stories)
                    }
                } else {
                    completion([])
                }
            }
        } else {
            completion([])
        }
    }
    func startUsername(currentUser: User, username: String){
        self.isCurrentUser = false
        self.currentUser = nil
        for (index, item) in users.enumerated() {
            if item.user.username == username {
                self.currentUser = index
                if users[index].user.id == currentUser.id {
                    self.isCurrentUser = true
                }
                if (users[index].tweets ?? []).isEmpty {
                    fetchUserTweets(currentUserId: currentUser.id ?? "")
                }
                return
            }
        }
        if username != currentUser.username {
            userService.fetchUserUsername(username: username) { user in
                if let user = user {
                    let newUser = Profile(user: user, tweets: nil, listJobs: nil, likedTweets: nil, forSale: nil, questions: nil, stories: nil)
                    self.users.append(newUser)
                    self.currentUser = self.users.count - 1
                    self.fetchUserTweets(currentUserId: currentUser.id ?? "")
                }
            }
        } else {
            isCurrentUser = true
            let newUser = Profile(user: currentUser, tweets: nil, listJobs: nil, likedTweets: nil, forSale: nil, questions: nil, stories: nil)
            self.users.append(newUser)
            self.currentUser = self.users.count - 1
            fetchUserTweets(currentUserId: currentUser.id ?? "")
        }
    }
    func start(uid: String, currentUser: User, optionalUser: User?){
        self.isCurrentUser = false
        self.currentUser = nil
        var found: Bool = false
        for (index, item) in users.enumerated() {
            if item.user.id == uid {
                self.currentUser = index
                if users[index].user.id == currentUser.id {
                    self.isCurrentUser = true
                }
                if (users[index].tweets ?? []).isEmpty {
                    fetchUserTweets(currentUserId: currentUser.id ?? "")
                }
                found = true
                self.updateStoriesUser(user: item.user)
                break
            }
            if let opUser = optionalUser {
                if item.user.id == opUser.id {
                    self.currentUser = index
                    if users[index].user.id == currentUser.id{
                        self.isCurrentUser = true
                    }
                    if (users[index].tweets ?? []).isEmpty {
                        fetchUserTweets(currentUserId: currentUser.id ?? "")
                    }
                    found = true
                    self.updateStoriesUser(user: item.user)
                    break
                }
            }
        }
        if !found {
            if let opUser = optionalUser {
                if (uid == currentUser.id ?? "") {
                    isCurrentUser = true
                }
                let newUser = Profile(user: opUser, tweets: nil, listJobs: nil, likedTweets: nil, forSale: nil, questions: nil, stories: nil)
                self.users.append(newUser)
                self.currentUser = self.users.count - 1
                fetchUserTweets(currentUserId: currentUser.id ?? "")
                self.updateStoriesUser(user: opUser)
            } else {
                if !(uid == currentUser.id ?? ""){
                    userService.fetchUser(withUid: uid) { user in
                        let newUser = Profile(user: user, tweets: nil, listJobs: nil, likedTweets: nil, forSale: nil, questions: nil, stories: nil)
                        self.users.append(newUser)
                        self.currentUser = self.users.count - 1
                        self.fetchUserTweets(currentUserId: currentUser.id ?? "")
                        self.updateStoriesUser(user: user)
                    }
                } else {
                    isCurrentUser = true
                    let newUser = Profile(user: currentUser, tweets: nil, listJobs: nil, likedTweets: nil, forSale: nil, questions: nil, stories: nil)
                    self.users.append(newUser)
                    self.currentUser = self.users.count - 1
                    fetchUserTweets(currentUserId: currentUser.id ?? "")
                    self.updateStoriesUser(user: currentUser)
                }
            }
        }
    }
    func fetchUserSales(userPhoto: String?, isCurrentUser: Bool){
        if let index = currentUser {
            if !users[index].user.shopPointer.isEmpty {
                if let id = self.users[index].user.id {
                    let arr = Array(Set(users[index].user.shopPointer))
                    for location in arr {
                        if !location.isEmpty && location.contains(","){
                            let components = location.components(separatedBy: ",")
                            if components.count == 3 {
                                let country = components[0]
                                let state = components[1]
                                let city = components[2]
                                service.fetchUserShop(country: country, state: state, city: city, uid: id) { shops in
                                    var temp = shops
                                    for i in 0..<temp.count {
                                        temp[i].tags = temp[i].tagJoined.split(separator: ",").map { String($0) }
                                    }
                                    if self.users[index].forSale == nil {
                                        self.users[index].forSale = temp
                                    } else {
                                        self.users[index].forSale?.insert(contentsOf: temp, at: 0)
                                    }
                                    if isCurrentUser {
                                        if !country.isEmpty && !city.isEmpty && !shops.isEmpty {
                                            self.updatePhotoUserSales(index: index, userPhoto: userPhoto, shops: shops, country: country, state: state, city: city)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                self.users[index].forSale = []
            }
        }
    }
    func updatePhotoUserSales(index: Int, userPhoto: String?, shops: [Shop], country: String, state: String, city: String){
        let db = Firestore.firestore()
        var query = db.collection("shop").document(country).collection("shop").document(city).collection("shop")
        if !state.isEmpty {
            query = db.collection("shop").document(country).collection("shop").document(state).collection("shop").document(city).collection("shop")
        }
        shops.forEach { shop in
            if let h_id = shop.id {
                if let photo = userPhoto {
                    if let hustle_photo = shop.profilephoto {
                        if photo != hustle_photo {
                            query.document(h_id).updateData(["profilephoto": photo]) { _ in }
                            if let x = users[index].forSale?.firstIndex(where: { $0.id == h_id }){
                                users[index].forSale?[x].profilephoto = photo
                            }
                        }
                    } else {
                        let dataToAdd: [String: Any] = [ "profilephoto": photo ]
                        query.document(h_id).setData(dataToAdd, merge: true) { _ in }
                        if let x = users[index].forSale?.firstIndex(where: { $0.id == h_id }){
                            users[index].forSale?[x].profilephoto = photo
                        }
                    }
                } else if shop.profilephoto != nil {
                    let fieldUpdate = ["profilephoto": FieldValue.delete()]
                    query.document(h_id).updateData(fieldUpdate) { _ in }
                    if let x = users[index].forSale?.firstIndex(where: { $0.id == h_id }){
                        users[index].forSale?[x].profilephoto = nil
                    }
                }
            }
        }
    }
    func fetchUserTweets(currentUserId: String) {
        if let index = currentUser, let id = self.users[index].user.id, !id.isEmpty {
            service.fetchUserTweet(forUid: id) { tweets in
                self.users[index].tweets = tweets
                if self.isCurrentUser && currentUserId == id {
                    self.tokens(bridge: false)
                    if !tweets.isEmpty {
                        self.updatePhotoUserHustles(index: index, user: self.users[index].user, hustles: tweets)
                    }
                }
            }
        }
    }
    func updatePhotoUserHustles(index: Int, user: User, hustles: [Tweet]){
        let db = Firestore.firestore()
        hustles.forEach { hustle in
            if let h_id = hustle.id {
                if let photo = user.profileImageUrl {
                    if let hustle_photo = hustle.profilephoto {
                        if photo != hustle_photo {
                            db.collection("tweets").document(h_id).updateData(["profilephoto": photo]) { _ in }
                            if let x = users[index].tweets?.firstIndex(where: { $0.id == h_id }){
                                users[index].tweets?[x].profilephoto = photo
                            }
                        }
                    } else {
                        let dataToAdd: [String: Any] = [ "profilephoto": photo ]
                        db.collection("tweets").document(h_id).setData(dataToAdd, merge: true) { _ in }
                        if let x = users[index].tweets?.firstIndex(where: { $0.id == h_id }){
                            users[index].tweets?[x].profilephoto = photo
                        }
                    }
                } else if hustle.profilephoto != nil {
                    let fieldUpdate = ["profilephoto": FieldValue.delete()]
                    db.collection("tweets").document(h_id).updateData(fieldUpdate) { _ in }
                    if let x = users[index].tweets?.firstIndex(where: { $0.id == h_id }){
                        users[index].tweets?[x].profilephoto = nil
                    }
                }
            }
        }
    }
    func fetchUserQuestions(userPhoto: String?, isCurrentUser: Bool) {
        if let index = currentUser, let id = self.users[index].user.id, !id.isEmpty {
            service.fetchUserQuestions(uid: id) { questions in
                var temp = questions
                for i in 0..<temp.count {
                    temp[i].tags = temp[i].tagJoined?.split(separator: ",").map { String($0) }
                }
                self.users[index].questions = temp
                if isCurrentUser && !questions.isEmpty {
                    self.updatePhotoUserQuestions(index: index, userPhoto: userPhoto, questions: questions)
                }
            }
        }
    }
    func updatePhotoUserQuestions(index: Int, userPhoto: String?, questions: [Question]){
        let db = Firestore.firestore()
        questions.forEach { question in
            if let h_id = question.id {
                if let photo = userPhoto {
                    if let hustle_photo = question.profilePhoto {
                        if photo != hustle_photo {
                            db.collection("Questions").document(h_id).updateData(["profilePhoto": photo]) { _ in }
                            if let x = users[index].questions?.firstIndex(where: { $0.id == h_id }){
                                users[index].questions?[x].profilePhoto = photo
                            }
                        }
                    } else {
                        let dataToAdd: [String: Any] = [ "profilePhoto": photo ]
                        db.collection("Questions").document(h_id).setData(dataToAdd, merge: true) { _ in }
                        if let x = users[index].questions?.firstIndex(where: { $0.id == h_id }){
                            users[index].questions?[x].profilePhoto = photo
                        }
                    }
                } else if question.profilePhoto != nil {
                    let fieldUpdate = ["profilePhoto": FieldValue.delete()]
                    db.collection("Questions").document(h_id).updateData(fieldUpdate) { _ in }
                    if let x = users[index].questions?.firstIndex(where: { $0.id == h_id }){
                        users[index].questions?[x].profilePhoto = nil
                    }
                }
            }
        }
    }
    func fetchUserJobs(userPhoto: String?, isCurrentUser: Bool) {
        if let index = currentUser {
            if let id = self.users[index].user.id, !users[index].user.jobPointer.isEmpty {
                let arr = Set(users[index].user.jobPointer).filter { !$0.isEmpty }
                var got = 0
                if arr.isEmpty {
                    self.users[index].listJobs = []
                }
                for location in arr {
                    if location.contains("remote") {
                        service.fetchUserJob(country: "", state: "", city: "", remote: true, forUid: id) { jobs in
                            for job in jobs {
                                let temp = Jobs(id: "\(UUID())", remote: true, job: job)
                                if self.users[index].listJobs == nil {
                                    self.users[index].listJobs = [temp]
                                } else {
                                    self.users[index].listJobs?.append(temp)
                                }
                            }
                            got += 1
                            if got == arr.count {
                                self.users[index].listJobs?.sort { (job1, job2) -> Bool in
                                    return job1.job.timestamp.dateValue() > job2.job.timestamp.dateValue()
                                }
                                if (self.users[index].listJobs ?? []).isEmpty {
                                    self.users[index].listJobs = []
                                }
                            }
                            if isCurrentUser && !jobs.isEmpty {
                                self.updatePhotoUserJobs(index: index, userPhoto: userPhoto, jobs: jobs, country: "", state: "", city: "", remote: true)
                            }
                        }
                    } else {
                        let components = location.components(separatedBy: ",")
                        if components.count == 3 {
                            let country = components[0]
                            let state = components[1]
                            let city = components[2]
                            service.fetchUserJob(country: country, state: state, city: city, remote: false, forUid: id) { jobs in
                                for job in jobs {
                                    let temp = Jobs(id: "\(UUID())", remote: false, job: job)
                                    if self.users[index].listJobs == nil {
                                        self.users[index].listJobs = [temp]
                                    } else {
                                        self.users[index].listJobs?.append(temp)
                                    }
                                }
                                got += 1
                                if got == arr.count {
                                    self.users[index].listJobs?.sort { (job1, job2) -> Bool in
                                        return job1.job.timestamp.dateValue() > job2.job.timestamp.dateValue()
                                    }
                                    if (self.users[index].listJobs ?? []).isEmpty {
                                        self.users[index].listJobs = []
                                    }
                                }
                                if isCurrentUser && !jobs.isEmpty {
                                    self.updatePhotoUserJobs(index: index, userPhoto: userPhoto, jobs: jobs, country: country, state: state, city: city, remote: false)
                                }
                            }
                        } else {
                            got += 1
                            if got == arr.count {
                                self.users[index].listJobs?.sort { (job1, job2) -> Bool in
                                    return job1.job.timestamp.dateValue() > job2.job.timestamp.dateValue()
                                }
                                if (self.users[index].listJobs ?? []).isEmpty {
                                    self.users[index].listJobs = []
                                }
                            }
                        }
                    }
                }
            } else {
                self.users[index].listJobs = []
            }
        }
    }
    func updatePhotoUserJobs(index: Int, userPhoto: String?, jobs: [Tweet], country: String, state: String, city: String, remote: Bool){
        let db = Firestore.firestore()
        var query = db.collection("remote")
        if !remote {
            query = db.collection("jobs").document(country).collection("jobs").document(city).collection("jobs")
            if !state.isEmpty {
                query = db.collection("jobs").document(country).collection("jobs").document(state).collection("jobs").document(city).collection("jobs")
            }
        }
        jobs.forEach { job in
            if let h_id = job.id {
                if let photo = userPhoto {
                    if let hustle_photo = job.profilephoto {
                        if photo != hustle_photo {
                            query.document(h_id).updateData(["profilephoto": photo]) { _ in }
                            if let x = users[index].listJobs?.firstIndex(where: { $0.job.id == h_id }){
                                users[index].listJobs?[x].job.profilephoto = photo
                            }
                        }
                    } else {
                        let dataToAdd: [String: Any] = [ "profilephoto": photo ]
                        query.document(h_id).setData(dataToAdd, merge: true) { _ in }
                        if let x = users[index].listJobs?.firstIndex(where: { $0.id == h_id }){
                            users[index].listJobs?[x].job.profilephoto = photo
                        }
                    }
                } else if job.profilephoto != nil {
                    let fieldUpdate = ["profilephoto": FieldValue.delete()]
                    query.document(h_id).updateData(fieldUpdate) { _ in }
                    if let x = users[index].listJobs?.firstIndex(where: { $0.id == h_id }){
                        users[index].listJobs?[x].job.profilephoto = nil
                    }
                }
            }
        }
    }
    func fetchLikedTweets(){
        if let index = currentUser {
            let tweets = Set(self.users[index].user.likedHustles)
            var got = 0
            if tweets.isEmpty {
                self.users[index].likedTweets = []
            }
            tweets.forEach { tweet in
                service.fetchLikedTweets(tweetID: tweet) { element in
                    if let hustle = element {
                        if self.users[index].likedTweets == nil {
                            self.users[index].likedTweets = [hustle]
                        } else {
                            self.users[index].likedTweets?.append(hustle)
                        }
                    }
                    got += 1
                    if got == tweets.count {
                        self.users[index].likedTweets?.sort { (tweet1, tweet2) -> Bool in
                            return tweet1.timestamp.dateValue() > tweet2.timestamp.dateValue()
                        }
                        if (self.users[index].likedTweets ?? []).isEmpty {
                            self.users[index].likedTweets = []
                        }
                    }
                }
            }
        }
    }
    func follow(withUid userId: String){
        userService.follow(withUid: userId){}
    }
    func unfollow(withUid userId: String){
        userService.unfollow(withUid: userId){}
    }
    func deleteAccount(oldImage: String?, completion: @escaping(Bool) -> Void){
        guard let user = Auth.auth().currentUser else { return }
        let credential = EmailAuthProvider.credential(withEmail: deleteUsername, password: deletePassword)
        user.reauthenticate(with: credential) { (result, error) in
            if let error = error {
                completion(false)
                let str = error.localizedDescription
                if str.contains("password") || str.contains("supplied credentials do not correspond to the previously signed"){
                    self.deleteAccountError = "Wrong username or password please try again"
                } else {
                    self.deleteAccountError = "Error deleting account, try again later"
                }
            } else {
                user.delete { error in
                    if error != nil {
                        completion(false)
                        self.deleteAccountError = "Error deleting account, try again later"
                    } else {
                        self.userService.deleteAccount(userID: user.uid)
                        completion(true)
                    }
                }
            }
        }
    }
    func editName(name: String){
        let data = ["fullname": name]
        guard let currentUser = Auth.auth().currentUser else { return }
        let changeRequest = currentUser.createProfileChangeRequest()
        changeRequest.displayName = name
        changeRequest.commitChanges { _ in }
        Firestore.firestore().collection("users").document(currentUser.uid).updateData(data) { _ in }
    }
    func editPhoto(uid: String, image: UIImage, oldimage: String?, completion: @escaping(String) -> Void){
        ImageUploader.uploadImage(image: image, location: "profile_image", compression: 0.05) { imageUrl, _ in
            Firestore.firestore().collection("users").document(uid).updateData(["profileImageUrl": imageUrl]) { _ in }
            completion(imageUrl)
        }
        if let url = oldimage {
            ImageUploader.deleteImage(fileLocation: url) { _ in }
        }
    }
    func editPass(completion: @escaping(Bool) -> Void){
        guard let user = Auth.auth().currentUser else { return }
        let credential = EmailAuthProvider.credential(withEmail: deleteUsername, password: deletePassword)
        user.reauthenticate(with: credential) { (result, error) in
            if let error = error {
                let str = error.localizedDescription
                if str.contains("password") || str.contains("supplied credentials do not correspond to the previously signed"){
                    self.deleteAccountError = "Wrong username or password please try again"
                } else {
                    self.deleteAccountError = "Error updating password, try again later"
                }
                completion(false)
            } else {
                user.updatePassword(to: self.newPass) { error in
                    if error != nil {
                        self.deleteAccountError = "Error updating password, try again later"
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
    func sendEmail(body: String, subject: String, email: String){
        var data = ["body": body,
                    "subject": subject]
        if !email.isEmpty {
            data["email"] = email
        }
        if let user = Auth.auth().currentUser {
            data["uid"] = user.uid
            Firestore.firestore().collection("emails").document()
                .setData(data as [String : Any]) { _ in }
        } else {
            Firestore.firestore().collection("emails").document()
                .setData(data as [String : Any]) { _ in }
        }
    }
    func editAlerts(count: String){
        if let index = currentUser {
            users[index].user.alertsShown = count
        }
        userService.editAlerts(count: count)
    }
    func editbadges(title: String){
        if let index = currentUser {
            users[index].user.badges.append(title)
        }
        userService.editBadges(title: title)
    }
    func tokens(bridge: Bool){
        if !self.exeFuncToDisplay || bridge {
            exeFuncToDisplay = true
            if let index = currentUser {
                let user = self.users[index].user
                if user.alertsShown.count == 0 && user.elo < 600 {
                    unlockToShow = 1
                } else if user.alertsShown.count <= 1 && user.elo >= 600 && user.elo < 850 {
                    unlockToShow = 2
                } else if user.alertsShown.count <= 2 && user.elo >= 850 && user.elo < 1300 {
                    unlockToShow = 3
                } else if user.alertsShown.count <= 3 && user.elo >= 1300 && user.elo < 2000 {
                    userService.editElo(withUid: nil, withAmount: 150) { }
                    unlockToShow = 4
                } else if user.alertsShown.count <= 4 && user.elo >= 2000 && user.elo < 2900 {
                    userService.editElo(withUid: nil, withAmount: 100) { }
                    unlockToShow = 5
                } else if user.alertsShown.count <= 5 && user.elo >= 2900 {
                    unlockToShow = 6
                }
                if unlockToShow != nil { return }
                let badges = user.badges
                if !badges.contains("write"){
                    tokenToShow = "write"
                } else if !badges.contains("tentips") && user.verifiedTips > 9 {
                    tokenToShow = "tentips"
                } else if !badges.contains("fivejobs") && user.completedjobs > 4 {
                    tokenToShow = "fivejobs"
                } else if !badges.contains("g_owner") && user.elo > 2899 {
                    tokenToShow = "g_owner"
                } else if !badges.contains("heart") {
                    self.users[index].tweets?.forEach { tweet in
                        if tweet.likes?.count ?? 0 > 1000 {
                            tokenToShow = "heart"
                            return
                        }
                    }
                }
                if !badges.contains("tenhustles") {
                    var x = 0
                    self.users[index].tweets?.forEach { tweet in
                        if (tweet.verified ?? false) == true { x += 1 }
                    }
                    if x > 9 { tokenToShow = "tenhustles" }
                }
            }
        }
    }
    func getBlocked(uid: [String]){
        uid.forEach { id in
            if !id.isEmpty {
                userService.fetchUser(withUid: id) { user in
                    self.blockedUsers.append(user)
                }
            }
        }
    }
}
