import Foundation
import Firebase
import SwiftUI
import FirebaseFirestore

class ExploreViewModel: ObservableObject {
    let serviceSec = ExploreService()
    
    @Published var news = [News]()
    @Published var NewsGroups: [(String, [Reply], [Reply], Timestamp?, Int?)] = []
    @Published var currentNews = -1
    @Published var avoidReplies: [String] = []
    @Published var showOnlyOne: Bool = false
    @Published var opinion_Reply: [(String, [Reply], Timestamp?)] = []
    @Published var showBreaking = false
    var gotBreaking: Bool = false
    var gettingNews: Bool = false
    var singleNewsFetched: Int = 0
    var fetchingInProgress = [String]()
    
    @Published var userGroup: [GroupX]? = nil
    @Published var joinedGroups = [GroupX]()
    @Published var exploreGroups = [GroupX]()
    @Published var groupFromMessage = [GroupX]()
    @Published var groupFromMessageSet = false
    @Published var lastGroup: Int = 0
    
    @Published var searchText = ""
    @Published var selectedSearch = 0
    @Published var showSearch = false
    @Published var noResults = false
    @Published var searchG = [GroupX]()
    @Published var matchedG = [GroupX]()
    @Published var searchU = [User]()
    @Published var matchedU = [User]()
    @Published var submittedSearch = false
    var oldestNews: Timestamp? = nil
    
    func start() {
        getNews()
    }
    func getBreaking() {
        gotBreaking = true
        ExploreService().getBreakingNews { breaking_news in
            if let breaking_news, !self.news.contains(where: { $0.id == breaking_news.id }) {
                self.news.insert(breaking_news, at: 0)
                withAnimation(.easeInOut(duration: 0.35)){
                    self.showBreaking = true
                }
            }
        }
    }
    func getSingleNews(id: String, completion: @escaping(News?) -> Void) {
        if !fetchingInProgress.contains(id) {
            fetchingInProgress.append(id)
            if let first = self.news.first(where: { $0.id == id } ) {
                completion(first)
                self.fetchingInProgress.removeAll(where: { $0 == id })
                return
            }
            serviceSec.getNewsSingle(title: id) { op_news in
                completion(op_news)
                if let op_news {
                    if !self.news.contains(where: { $0.id == op_news.id }) {
                        self.singleNewsFetched += 1
                        self.news.append(op_news)
                    }
                    if let id = op_news.id, !self.NewsGroups.contains(where: { $0.0 == op_news.id }) {
                        self.NewsGroups.append((id, [], [], nil, nil))
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.fetchingInProgress.removeAll(where: { $0 == id })
                }
            }
        } else {
            completion(nil)
        }
    }
    func getNews(){
        if !self.gettingNews {
            self.gettingNews = true
            
            serviceSec.getNews(lastdoc: oldestNews) { fetchedNews in
                fetchedNews.forEach { n in
                    if !self.news.contains(where: { $0.id == n.id }) {
                        withAnimation(.easeInOut(duration: 0.2)){
                            self.news.append(n)
                        }
                    }
                    if let id = n.id, !self.NewsGroups.contains(where: { $0.0 == id }) {
                        self.NewsGroups.append((id, [], [], nil, nil))
                    }
                }
                if let last = fetchedNews.last?.timestamp {
                    self.oldestNews = last
                }
                self.gettingNews = false
            }
        }
    }
    func tagUserNews(myUsername: String, otherUsername: String, message: String, newsName: String?) {
        ExploreService().sendNotification(type: "News", taggerUsername: myUsername, taggedUsername: otherUsername, taggedUID: nil, caption: message, tweetID: nil, groupName: nil, newsName: newsName, questionID: nil, taggerUID: nil)
    }
    func startNewsGroup(newsID: String, blocked: [String], newOrTop: Int) {
        if let index = NewsGroups.firstIndex(where: { $0.0 == newsID }){
            currentNews = index
            if (NewsGroups[currentNews].1.isEmpty && newOrTop == 0) || (NewsGroups[currentNews].2.isEmpty && newOrTop == 1) {
                getNewsReps(blocked: blocked, newOrTop: newOrTop)
            }
        } else {
            self.NewsGroups.append((newsID, [], [], nil, nil))
            currentNews = (self.NewsGroups.count - 1)
            getNewsReps(blocked: blocked, newOrTop: newOrTop)
        }
    }
    func getNewsReps(blocked: [String], newOrTop: Int) {
        if currentNews >= 0 && NewsGroups.count > currentNews {
            let temp = currentNews
            serviceSec.getNewsReply(new: newOrTop == 0 ? true : false, newsId: self.NewsGroups[temp].0, lastdoc: self.NewsGroups[temp].3, lastTop: self.NewsGroups[temp].4) { replies in
                if !replies.isEmpty {
                    var reps = replies
                    blocked.forEach { element in
                        reps.removeAll(where: { $0.id == element })
                    }
                    if newOrTop == 0 {
                        self.NewsGroups[temp].1.append(contentsOf: reps)
                        if let last = replies.last {
                            self.NewsGroups[temp].3 = last.timestamp
                        }
                    } else {
                        reps.removeAll(where: { self.NewsGroups[temp].2.contains($0) })
                        self.NewsGroups[temp].2.append(contentsOf: reps)
                        if let last = replies.last {
                            self.NewsGroups[temp].4 = last.actions
                        }
                    }
                }
            }
        }
    }
    func getNewsRepsNew(blocked: [String]) {
        if currentNews >= 0 && NewsGroups.count > currentNews {
            let temp = currentNews
            if let first = self.NewsGroups[temp].1.first?.timestamp {
                serviceSec.getNewsReplyNew(newsId: self.NewsGroups[temp].0, newest: first) { replies in
                    if !replies.isEmpty {
                        var reps = replies
                        blocked.forEach { element in
                            reps.removeAll(where: { $0.id == element })
                        }
                        self.NewsGroups[temp].1.insert(contentsOf: reps, at: 0)
                    }
                }
            }
        }
    }
    func sendNewsRep(caption: String, user: String, completion: @escaping(Bool) -> Void) {
        if currentNews >= 0 && NewsGroups.count > currentNews {
            if !avoidReplies.contains(NewsGroups[currentNews].0) {
                let id = NewsGroups[currentNews].0
                guard let docID = Auth.auth().currentUser?.uid else {
                    completion(false)
                    return
                }
                serviceSec.uploadNewsReply(caption: caption, docID: id, user: user, newDocID: docID){ bool in
                    self.avoidReplies.append(id)
                    if !bool {
                        completion(false)
                        self.showOnlyOne = true
                    } else {
                        completion(true)
                        let element = Reply(id: docID, username: user.isEmpty ? nil : user, response: caption, actions: 0, timestamp: Timestamp(date: Date()))
                        self.NewsGroups[self.currentNews].1.insert(element, at: 0)
                    }
                }
            } else {
                completion(false)
                showOnlyOne = true
            }
        }
    }
    func setOpinionReplies(newsID: String, opinionID: String, blocked: [String]){
        if let x = opinion_Reply.firstIndex(where: { $0.0 == opinionID }){
            if opinion_Reply[x].1.isEmpty {
                getOpinionReplies(newsID: newsID, opinionID: opinionID, blocked: blocked)
            }
        } else {
            opinion_Reply.append((opinionID, [], nil))
            getOpinionReplies(newsID: newsID, opinionID: opinionID, blocked: blocked)
        }
    }
    func getOpinionReplies(newsID: String, opinionID: String, blocked: [String]){
        if let x = opinion_Reply.firstIndex(where: { $0.0 == opinionID }){
            serviceSec.getOpinionReply(newsId: newsID, opinionID: opinionID, lastdoc: self.opinion_Reply[x].2) { new in
                var reps = new
                blocked.forEach { element in
                    reps.removeAll(where: { $0.uid ?? "NA" == element })
                }
                self.opinion_Reply[x].1 += reps
                if let last = new.last?.timestamp {
                    self.opinion_Reply[x].2 = last
                }
            }
        }
    }
    func sendOpinionReplies(newsID: String, opinionID: String, caption: String, user: String){
        let new = Reply(id: "\(UUID())", uid: Auth.auth().currentUser?.uid, username: user, response: caption, timestamp: Timestamp())
        if let x = opinion_Reply.firstIndex(where: { $0.0 == opinionID }){
            opinion_Reply[x].1.insert(new, at: 0)
        } else {
            let newElement = (opinionID, [new], nil as Timestamp?)
            opinion_Reply.append(newElement)
        }
        if let i = NewsGroups.firstIndex(where: { $0.0 == newsID }) {
            if let j = NewsGroups[i].1.firstIndex(where: { $0.id == opinionID }){
                if let count = NewsGroups[i].1[j].actions {
                    NewsGroups[i].1[j].actions = count + 1
                } else {
                    NewsGroups[i].1[j].actions = 1
                }
            }
        }
        serviceSec.uploadOpinionReply(caption: caption, newsID: newsID, opinionID: opinionID, user: user)
    }
    func uploadNews(link: String){
        serviceSec.uploadNews(link: link)
    }

    func get10GroupCovers(groupId: [String], joinedGroups: [String]){
        var avoid = joinedGroups
        avoid += groupId
        for i in 0 ..< exploreGroups.count {
            avoid.append(exploreGroups[i].id)
        }
        if self.lastGroup != 0 {
            serviceSec.get10GroupCoversMore(lastdoc: self.lastGroup) { groups in
                let filteredArr = groups.filter { !avoid.contains($0.id) }
                if !filteredArr.isEmpty {
                    self.exploreGroups += filteredArr
                    self.lastGroup = filteredArr.last?.membersCount ?? 0
                }
            }
        } else {
            serviceSec.get10GroupCovers { groups in
                let filteredArr = groups.filter { !avoid.contains($0.id) }
                if !filteredArr.isEmpty {
                    self.exploreGroups = filteredArr
                    self.lastGroup = filteredArr.last?.membersCount ?? 0
                }
            }
        }
    }
    func getSearchGroups(query: String){
        submittedSearch = true
        serviceSec.searchGroups(name: query) { groups1 in
            if groups1.isEmpty {
                self.serviceSec.searchGroups(name: query.lowercased()) { groups2 in
                    if !groups2.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                            self.submittedSearch = false
                        }
                        groups2.forEach { elemenet in
                            if !self.matchedG.contains(where: { $0.id == elemenet.id }) && !self.exploreGroups.contains(where: { $0.id == elemenet.id }) {
                                self.matchedG.insert(elemenet, at: 0)
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                    self.submittedSearch = false
                }
                groups1.forEach { elemenet in
                    if !self.matchedG.contains(where: { $0.id == elemenet.id }) && !self.exploreGroups.contains(where: { $0.id == elemenet.id }) {
                        self.matchedG.insert(elemenet, at: 0)
                    }
                }
            }
        }
    }
    func getUserJoinedGroupCovers(groupIds: [String]){
        joinedGroups = []
        for i in 0 ..< groupIds.count {
            let id = groupIds[i]
            serviceSec.getUserGroupCover(userGroupId: id) { group in
                if !group.id.isEmpty {
                    self.joinedGroups.append(group)
                    
                    self.serviceSec.getFirst(docID: id) { all in
                        if let first = all.first, let index = self.joinedGroups.firstIndex(where: { $0.id == id }) {
                            self.joinedGroups[index].lastM = first
                        }
                    }
                }
            }
        }
    }
    func getUserGroupCover(userGroupId: [String]){
        let final = Array(Set(userGroupId))
        if self.userGroup == nil {
            self.userGroup = []
        }
        for i in 0..<final.count {
            self.serviceSec.getUserGroupCover(userGroupId: final[i]) { group in
                self.userGroup?.append(group)
                
                self.serviceSec.getFirst(docID: final[i]) { all in
                    if let first = all.first, let index = self.userGroup?.firstIndex(where: { $0.id == final[i] }) {
                        self.userGroup?[index].lastM = first
                    }
                }
            }
        }
    }
    func fetchGroupForMessages(id: String) {
        if let x = exploreGroups.firstIndex(where: { $0.id == id }) {
            groupFromMessage = [exploreGroups[x]]
            groupFromMessageSet.toggle()
        } else if let x = joinedGroups.firstIndex(where: { $0.id == id }) {
            groupFromMessage = [joinedGroups[x]]
            groupFromMessageSet.toggle()
        } else if id != "" {
            serviceSec.getUserGroupCover(userGroupId: id) { group in
                self.exploreGroups.insert(group, at: 0)
                self.groupFromMessage.insert(group, at: 0)
                self.groupFromMessageSet.toggle()
            }
        }
    }
    func UserSearchBestFit(){
        let lowercasedQuery = searchText.lowercased()
        self.matchedU = searchU.filter({
            $0.username.lowercased().contains(lowercasedQuery) ||
            $0.fullname.lowercased().contains(lowercasedQuery)
        })
    }
    func UserSearch(userId: String){
        serviceSec.searchUsers(name: searchText) { users in
            self.serviceSec.searchFullname(name: self.searchText) { usersSec in
                var all = users + usersSec
                all = all.filter { $0.id != userId }
                all = Array(Set(all))
                self.searchU += all.filter { !self.searchU.contains($0) }
                if !all.isEmpty {
                    let tempUsers = all.filter { !self.matchedU.contains($0) }
                    self.matchedU.insert(contentsOf: tempUsers, at: 0)
                }
                if self.matchedU.isEmpty {
                    self.noResults = true
                }
            }
        }
    }
    func GroupSearchBestFit(){
        let lowercasedQuery = searchText.lowercased()
        self.matchedG = searchG.filter({ $0.title.contains(lowercasedQuery) })
    }
    func GroupSearch(){
        serviceSec.searchGroups(name: searchText) { groups in
            if groups.isEmpty {
                self.serviceSec.searchGroups(name: self.searchText.lowercased()) { Groups in
                    if Groups.isEmpty {
                        self.noResults = true
                    } else {
                        let matched = groups.filter { !self.matchedG.contains($0) }
                        self.matchedG.insert(contentsOf: matched, at: 0)
                        self.searchG += matched
                        if self.matchedG.isEmpty {
                            self.noResults = true
                        }
                    }
                }
            } else {
                let matched = groups.filter { !self.matchedG.contains($0) }
                self.matchedG.insert(contentsOf: matched, at: 0)
                self.searchG += matched
                if self.matchedG.isEmpty {
                    self.noResults = true
                }
            }
        }
    }
}
