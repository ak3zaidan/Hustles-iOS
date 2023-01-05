import Foundation
import Firebase
import UIKit
import SwiftUI
import CryptoKit
import LocalAuthentication
import AuthenticationServices
import AudioToolbox

struct callInfo: Identifiable, Hashable {
    let id: String
    let uid: String
    let photo: String?
    let outgoing: Bool
    let name: String
    let missed: Bool?
    let timestamp: Timestamp
}

func getDate(date: Timestamp) -> String {
    let val = date.dateValue()
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let dateToCompare = calendar.startOfDay(for: val)
    let dayOfWeek = calendar.component(.weekday, from: val)

    if dateToCompare == today {
        return "Today"
    } else if dateToCompare == yesterday {
        return "Yesterday"
    } else if dateToCompare >= calendar.date(byAdding: .day, value: -7, to: today)! {
        let possibleDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return possibleDays[dayOfWeek - 1]
    } else {
        let dayOfMonth = calendar.component(.day, from: val)
        let month = calendar.component(.month, from: val)
        let possibleDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let rDay = possibleDays[dayOfWeek - 1]
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let rMonth = monthNames[month - 1]
        
        return "\(rDay), \(rMonth) \(dayOfMonth)"
    }
}

class MessageViewModel: Identifiable, ObservableObject {
    @Published var selection: Int = 3
    @Published var replyImages: [(String, String)] = []
    @Published var groups = [GroupX]()
    @Published var chats = [Chats]()
    @Published var requests = [Chats]()
    @Published var calls = [callInfo]()
    @Published var suggestedChats = [Chats]()
    @Published var currentChat: Int?
    @Published var matchedUsers = [User]()
    @Published var searchUsers = [User]()
    @Published var following = [User]()
    @Published var mutualFriends = [User]()
    @Published var searchText = ""
    @Published var noUsersFound = true
    @Published var submitted = false
    @Published var loading = false
    @Published var groupsToAdd = [GroupX]()
    @Published var audioMessages: [(String, URL)] = []
    @Published var imageMessages: [(Image, String)] = []
    @Published var fileMessages: [(String, String)] = []
    @Published var dayArr: [(Int, String)] = []
    @Published var newIndex: Int? = nil
    @Published var currentlyFetchingData = false
    @Published var gotConversations = false
    let service = MessageService()
    let userService = UserService()
    let searchService = ExploreService()
    var timeRemaining = 7.0
    @Published var priv_Key_Saved: String?
    var canRefresh = false
    @Published var gotNotifications = false
    @Published var notifs = [Notification]()
    @Published var secondary_notifs = [Notif_Data]()
    var timeSinceLast: Date? = nil
    @Published var startNextAudio: String = ""
    @Published var currentAudio: String = ""
    @Published var scrollToReply: String = ""
    @Published var scrollToReplyNow: String = ""
    @Published var editedMessage: String = ""
    @Published var editedMessageID: String = ""
    var initialSend: messageSendType? = nil
    @Published var navigateOut: Bool = false
    @Published var GoToPin: String = ""
    var postStoryLoc: (CGFloat, CGFloat)? = nil
    @Published var navigateUserMap: Bool = false
    @Published var userMap: User? = nil
    var userMapID: String = ""
    @Published var navigateStoryProfile: Bool = false
    var viewedStories: [(String, String)] = []
    @Published var getStoriesQueue = [String]()
 
    func getSearchContent(currentID: String, following: [String]) {
        if self.following.isEmpty {
            var final_follow = [String]()
            
            for i in 0..<following.count {
                if !chats.contains(where: { $0.user.id == following[i] }) && following[i] != currentID {
                    final_follow.append(following[i])
                    if final_follow.count == 8 {
                        break
                    }
                }
            }
            if !final_follow.isEmpty {
                userService.getManyUsers(users: final_follow, limit: 8) { users in
                    self.following.append(contentsOf: users)
                }
            }
        }
        if mutualFriends.isEmpty {
            userService.getTop { users in
                self.mutualFriends = users
                self.mutualFriends.removeAll(where: { $0.id == currentID })
            }
        }
    }
    func addReaction(id: String, emoji: String){
        AudioServicesPlaySystemSound(1306)
        if let index = currentChat {
            if let convoID = chats[index].convo.id {
                service.addReaction(convoID: convoID, id: id, emoji: emoji)
            }
            if let x = chats[index].messages?.firstIndex(where: { $0.id == id }) {
                chats[index].messages?[x].emoji = emoji
            }
        }
    }
    func getNotifications(profile: Profile){
        gotNotifications = true
        service.getNotifications { notification in
            self.notifs = notification
        }
        let hustles = profile.tweets ?? []
        let questions = profile.questions ?? []
        let shop = profile.forSale ?? []
        
        secondary_notifs = []
        for i in 0..<hustles.count {
            let date = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
            if hustles[i].timestamp.dateValue() > date {
                if hustles[i].likes?.count ?? 0 > 3 && hustles[i].comments ?? 0 > 3 {
                    secondary_notifs.append(Notif_Data(id: "\(UUID())", text1: "You have \(hustles[i].likes?.count ?? 0) new likes and \(hustles[i].comments ?? 0) new comments on your post:", text2: "\(hustles[i].caption.prefix(80))..."))
                } else if hustles[i].likes?.count ?? 0 > 3 {
                    secondary_notifs.append(Notif_Data(id: "\(UUID())", text1: "You have \(hustles[i].likes?.count ?? 0) new likes on your post:", text2: "\(hustles[i].caption.prefix(80))..."))
                } else if hustles[i].comments ?? 0 > 3 {
                    secondary_notifs.append(Notif_Data(id: "\(UUID())", text1: "You have \(hustles[i].comments ?? 0) new comments on your post:", text2: "\(hustles[i].caption.prefix(80))..."))
                }
            }
        }
        for i in 0..<questions.count {
            let date = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
            if questions[i].timestamp.dateValue() > date {
                if questions[i].acceptedAnswer != nil && questions[i].answersCount ?? 0 > 1 {
                    secondary_notifs.append(Notif_Data(id: "\(UUID())", text1: "You have \(questions[i].answersCount ?? 1) new answers on your question:", text2: "\(questions[i].title ?? "")"))
                } else {
                    if questions[i].votes > 0 && questions[i].answersCount ?? 0 > 0 {
                        secondary_notifs.append(Notif_Data(id: "\(UUID())", text1: "You have \(questions[i].answersCount ?? 0) new answers and \(questions[i].votes) upvotes on your question:", text2: "\(questions[i].title ?? "")"))
                    } else if questions[i].votes > 0 {
                        secondary_notifs.append(Notif_Data(id: "\(UUID())", text1: "You have \(questions[i].votes) upvotes on your question:", text2: "\(questions[i].title ?? "")"))
                    } else if questions[i].answersCount ?? 0 > 0 {
                        secondary_notifs.append(Notif_Data(id: "\(UUID())", text1: "You have \(questions[i].answersCount ?? 0) new answers on your question:", text2: "\(questions[i].title ?? "")"))
                    }
                }
            }
        }
        var x = 0
        for i in 0..<shop.count {
            if x == 2 {
                break
            }
            let date = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
            if shop[i].timestamp.dateValue() < date {
                x += 1
                secondary_notifs.append(Notif_Data(id: "\(UUID())", text1: "Your post has been active for a while, try lowering the price to attract people", text2: "\(shop[i].title)"))
            }
        }
    }
    func deleteNotication(id: String?){
        if let id = id {
            service.deleteNotif(id: id)
        }
    }
    func setDate() {
        if let position = currentChat {
            dayArr = []
            if let messages = chats[position].messages {
                if let first = messages.first {
                    var last = getDate(date: first.timestamp)
                    for (index, message) in messages.enumerated() {
                        let current = getDate(date: message.timestamp)
                        if last != current {
                            if !dayArr.contains(where: { $0.1 == last }) {
                                dayArr.append((index - 1, last))
                            }
                        }
                        if index == (messages.count - 1) {
                            if !dayArr.contains(where: { $0.1 == current }) {
                                dayArr.append((index, current))
                            }
                        }
                        last = current
                    }
                    for i in 0..<dayArr.count {
                        if dayArr[i].0 < messages.count {
                            let toAdd = messages[dayArr[i].0].timestamp.dateValue().formatted(.dateTime.hour().minute())
                            if self.dayArr[i].1.contains(",") {
                                self.dayArr[i].1 = "\(self.dayArr[i].1) at \(toAdd)"
                            } else {
                                self.dayArr[i].1 = "\(self.dayArr[i].1) \(toAdd)"
                            }
                        }
                    }
                }
            }
        }
    }
    func start(user: User?, uid: String, pointers: [String]){
        self.newIndex = nil
        var found: Bool = false
        if let index = chats.firstIndex(where: { $0.user == user || ($0.user.id == uid && !uid.isEmpty) }){
            self.currentChat = index
            found = true
        }
        if !found {
            guard let myUID = Auth.auth().currentUser?.uid else { return }
            var discov = ""
            if let ssID = pointers.first(where: { $0.contains(uid) }) {
                discov = ssID
            }
            if let user = user {
                let newChat = Chats(id: "\(UUID())", user: user, convo: Convo(id: discov, uid_one: myUID, uid_two: uid, uid_one_active: true, uid_two_active: true, encrypted: true))
                self.chats.append(newChat)
                self.currentChat = self.chats.count - 1
            } else {
                userService.fetchUser(withUid: uid) { newUser in
                    let newChat = Chats(id: "\(UUID())", user: newUser, convo: Convo(id: discov, uid_one: myUID, uid_two: uid, uid_one_active: true, uid_two_active: true, encrypted: true))
                    self.chats.append(newChat)
                    self.currentChat = self.chats.count - 1
                    self.getMessages()
                }
            }
        }
        if let index = currentChat {
            if let messages = self.chats[index].messages, !messages.isEmpty {
                getMessagesNew(initialFetch: true)
            } else {
                getMessages()
            }
        }
        setDate()
    }
    func acceptInvt(groupId: String, message: Message){
        if let index = currentChat, let id = chats[index].convo.id {
            if let x = chats[index].messages?.firstIndex(where: { $0.id == message.id }) {
                chats[index].messages?.remove(at: x)
                guard let myUID = Auth.auth().currentUser?.uid else { return }
                let new = Message(id: "\(UUID())", uid_one_did_recieve: (chats[index].convo.uid_one == myUID) ? false : true, seen_by_reciever: false, text: "invite accepted", timestamp: Timestamp())
                chats[index].messages?.insert(new, at: 0)
                chats[index].lastM = new
                service.deleteOld(convoID: id, messageId: message.id ?? "")
                service.sendMessage(docID: id, otherUserUID: nil, text: "invite accepted", imageUrl: nil, elo: nil, is_uid_one: (chats[index].convo.uid_one == myUID) ? true : false, newID: nil, messageID: "", fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
                service.acceptInvt(groupId: groupId, userID: nil)
                searchService.getUserGroupCover(userGroupId: groupId) { group in
                    self.groupsToAdd.append(group)
                }
                setDate()
            }
        }
    }
    func denyReq(message: Message){
        if let index = currentChat, let id = chats[index].convo.id {
            if let x = chats[index].messages?.firstIndex(where: { $0.id == message.id }) {
                chats[index].messages?.remove(at: x)
                guard let uid = Auth.auth().currentUser?.uid else { return }
                let new = Message(id: "\(UUID())", uid_one_did_recieve: (chats[index].convo.uid_one == uid) ? false : true, seen_by_reciever: false, text: "request denied...", timestamp: Timestamp())
                chats[index].messages?.insert(new, at: 0)
                chats[index].lastM = new
                service.deleteOld(convoID: id, messageId: message.id ?? "")
                service.sendMessage(docID: id, otherUserUID: nil, text: "request denied...", imageUrl: nil, elo: nil, is_uid_one: (chats[index].convo.uid_one == uid) ? true : false, newID: nil, messageID: "", fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
                setDate()
            }
        }
    }
    func acceptReq(message: Message, title: String, groupId: String){
        if let index = currentChat, let id = chats[index].convo.id {
            if let x = chats[index].messages?.firstIndex(where: { $0.id == message.id }) {
                chats[index].messages?.remove(at: x)
                guard let uid = Auth.auth().currentUser?.uid else { return }
                let new = Message(id: "\(UUID())", uid_one_did_recieve: (chats[index].convo.uid_one == uid) ? false : true, seen_by_reciever: false, text: "✅request accepted", timestamp: Timestamp())
                chats[index].messages?.insert(new, at: 0)
                chats[index].lastM = new
                service.deleteOld(convoID: id, messageId: message.id ?? "")
                service.acceptInvt(groupId: groupId, userID: chats[index].user.id ?? "")
                service.sendMessage(docID: id, otherUserUID: nil, text: "✅request accepted", imageUrl: nil, elo: nil, is_uid_one: (chats[index].convo.uid_one == uid) ? true : false, newID: nil, messageID: "", fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
                setDate()
            }
        }
    }
    func refreshConvos(pointers: [String]) {
        var finalP = [String]()
        pointers.forEach { element in
            if !chats.contains(where: { $0.convo.id == element }) {
                finalP.append(element)
            }
        }
        if !finalP.isEmpty {
            service.getConversations(pointers: finalP) { elements in
                elements.forEach { element in
                    if let id = element.0.id, !self.chats.contains(where: { $0.user.id == element.1.id }) {
                        self.service.getFirst(docID: id) { message in
                            var final: Message? = message.first
                            if let text = message.first?.text {
                                if let decrypted_text = self.decrypt(text: text, key: element.1.publicKey){
                                    final?.text = decrypted_text
                                }
                            }
                            var newChat = Chats(id: "\(UUID())", user: element.1, convo: element.0, lastM: final, messages: nil)
                            newChat.convo.verified = true
                            self.chats.insert(newChat, at: 0)
                        }
                    }
                }
            }
        }
    }
    func fetchConvos(pointers: [String]) {
        if !currentlyFetchingData {
            if !gotConversations {
                currentlyFetchingData = true
                var final_p = pointers
                let chatIDs = Set(chats.map { $0.convo.id })
                final_p.removeAll { chatIDs.contains($0) }
                
                if final_p.isEmpty {
                    addDev()
                } else {
                    var x = 0
                    service.getConversations(pointers: final_p) { elements in
                        if elements.isEmpty {
                            self.currentlyFetchingData = false
                            self.addDev()
                        }
                        elements.forEach { element in
                            if let id = element.0.id, !self.chats.contains(where: { $0.user.id == element.1.id }) {
                                self.service.getFirst(docID: id) { message in
                                    var final: Message? = message.first
                                    if let text = message.first?.text {
                                        if let decrypted_text = self.decrypt(text: text, key: element.1.publicKey){
                                            final?.text = decrypted_text
                                        }
                                    }
                                    x += 1
                                    if let id = element.1.id {
                                        self.getStoriesQueue.append(id)
                                    }
                                    var newChat = Chats(id: "\(UUID())", user: element.1, convo: element.0, lastM: final, messages: nil)
                                    newChat.convo.verified = true
                                    self.chats.append(newChat)
                                    if x == elements.count {
                                        self.gotConversations = true
                                        self.addDev()
                                        self.currentlyFetchingData = false
                                    }
                                }
                            } else {
                                x += 1
                                if x == elements.count {
                                    self.gotConversations = true
                                    self.addDev()
                                    self.currentlyFetchingData = false
                                }
                            }
                        }
                    }
                }
            } else {
                refreshFirstMessages()
            }
        }
    }
    func addDev(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.canRefresh = true
        }
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        if !chats.contains(where: { $0.user.dev != nil }) {
            userService.fetchUser(withUid: "lQTwtFUrOMXem7UXesJbDMLbV902") { user in
                let newMessage = Message(id: "\(UUID())", uid_one_did_recieve: true, seen_by_reciever: true, text: "Welcome to Hustles. This platform was built to spread lucrative business ideas, connect people with jobs, and educate across all fields. Our Terms and Privacy policy can be found here: https://hustle.page/.", timestamp: Timestamp(date: Date(timeIntervalSince1970: 0)))
                var newChat = Chats(id: "\(UUID())", user: user, convo: Convo(id: "lQTwtFUrOMXem7UXesJbDMLbV902" + myUID, uid_one: myUID, uid_two: "lQTwtFUrOMXem7UXesJbDMLbV902", uid_one_active: true, uid_two_active: true, encrypted: false))
                newChat.messages = [newMessage]
                newChat.lastM = newMessage
                self.chats.append(newChat)
            }
        }
    }
    func refreshFirstMessages() {
        if isAtLeast30SecondsOld(date: timeSinceLast) {
            timeSinceLast = Date()
            for (i, chat) in self.chats.enumerated() {
                if let last = chat.lastM {
                    let timestampDate = last.timestamp.dateValue()
                    let currentDate = Date()
                    let timeDifference = currentDate.timeIntervalSince(timestampDate)
                    if let id = chat.convo.id, timeDifference < (24 * 60 * 60) {
                        service.getFirst(docID: id) { message in
                            if var first_message = message.first {
                                if first_message.id != last.id {
                                    if let text = first_message.text {
                                        if let decrypted_text = self.decrypt(text: text, key: chat.user.publicKey){
                                            first_message.text = decrypted_text
                                        }
                                    }
                                    self.chats[i].lastM = first_message
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    func getNewIndex() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var topMost: Int? = nil
        var bottomMost: Int? = nil
        
        if let index = currentChat {
            self.chats[index].messages?.enumerated().forEach { (pos, element) in
                if (chats[index].convo.uid_one == uid && element.uid_one_did_recieve) || (chats[index].convo.uid_two == uid && !(element.uid_one_did_recieve)){
                    if !(element.seen_by_reciever) {
                        if bottomMost == nil {
                            topMost = pos
                        }
                    } else if bottomMost == nil {
                        bottomMost = pos
                    }
                } else if bottomMost == nil {
                    bottomMost = pos
                }
            }
            if let position = topMost {
                self.newIndex = position
            }
        }
    }
    func getMessages(){
        if let index = currentChat {
            service.getMessages(docID: chats[index].convo.id ?? "", otherUser: chats[index].user.id) { messages in
                var new_messages = messages.0
                for i in 0..<new_messages.count {
                    if let text = new_messages[i].text {
                        if let decrypted_text = self.decrypt(text: text, key: self.chats[index].user.publicKey){
                            new_messages[i].text = decrypted_text
                        }
                    }
                }
                if let realConvo = messages.1 {
                    self.chats[index].convo = realConvo
                    self.chats[index].convo.verified = true
                } else if let random = messages.0.first, let uid = Auth.auth().currentUser?.uid, let testID = random.id {
                    let uid_prefix = String(uid.prefix(5))
                    if testID.hasPrefix(uid_prefix) && self.chats[index].convo.uid_one == uid && random.uid_one_did_recieve {
                        let temp = self.chats[index].convo.uid_one
                        self.chats[index].convo.uid_one = self.chats[index].convo.uid_two
                        self.chats[index].convo.uid_two = temp
                    }
                }
                self.chats[index].messages = new_messages
                self.chats[index].lastM = new_messages.first
                self.setDate()
                self.getNewIndex()
            }
        }
    }
    func getMessagesNew(initialFetch: Bool){
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        if let index = currentChat {
            if let last = chats[index].messages?.first(where: { (chats[index].convo.uid_one == myUID) ? $0.uid_one_did_recieve == true : $0.uid_one_did_recieve == false } )?.timestamp {
                
                service.getMessagesNew(docID: chats[index].convo.id ?? "", lastdoc: last) { messages in
                    var new = [Message]()
                    if self.chats[index].convo.uid_one == myUID {
                        new = messages.filter({ $0.uid_one_did_recieve == true })
                    } else {
                        new = messages.filter({ $0.uid_one_did_recieve == false })
                    }
                    if !new.isEmpty {
                        for i in 0..<new.count {
                            if let text = new[i].text {
                                if let decrypted_text = self.decrypt(text: text, key: self.chats[index].user.publicKey){
                                    new[i].text = decrypted_text
                                }
                            }
                        }
                        if initialFetch {
                            var timeDiff: Bool = false
                            if let mess = self.chats[index].messages {
                                let newMessages = new.filter { message in
                                    !mess.contains(where: { $0.id == message.id })
                                }
                                
                                if let newestTimestamp = newMessages.last?.timestamp.dateValue(),
                                   let oldestTimestamp = self.chats[index].messages?.first?.timestamp.dateValue() {
                                    if newestTimestamp.timeIntervalSince(oldestTimestamp) > 3600 {
                                        timeDiff = true
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    self.chats[index].messages?.insert(contentsOf: newMessages, at: 0)
                                }
                                
                                DispatchQueue.main.async {
                                    self.chats[index].lastM = newMessages.first
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.chats[index].messages = new
                                }
                                
                                DispatchQueue.main.async {
                                    self.chats[index].lastM = new.first
                                }
                            }
                            self.setDate()
                            if timeDiff {
                                DispatchQueue.main.async {
                                    self.getNewIndex()
                                }
                            }
                            return
                        }
                        var count = 0.0
                        if let mess = self.chats[index].messages {
                            let newMessages = new.filter { message in
                                !mess.contains(where: { $0.id == message.id })
                            }
                            
                            if !newMessages.isEmpty {
                                if self.newIndex != nil {
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        self.newIndex = nil
                                    }
                                }
                                newMessages.reversed().forEach { singleM in
                                    count += 1
                                    DispatchQueue.main.asyncAfter(deadline: .now() + (count * Double.random(in: 0.7...1.1))) {
                                        withAnimation(.bouncy(duration: 0.3)){
                                            self.chats[index].messages?.insert(singleM, at: 0)
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        }
                                        self.setDate()
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    self.chats[index].lastM = newMessages.first
                                }
                            } else {
                                self.timeRemaining += 8
                            }
                        } else {
                            if self.newIndex != nil {
                                withAnimation(.easeInOut(duration: 0.2)){
                                    self.newIndex = nil
                                }
                            }
                            self.chats[index].messages = []
                            new.forEach { singleM in
                                count += 1
                                DispatchQueue.main.asyncAfter(deadline: .now() + (count * Double.random(in: 0.7...1.1))) {
                                    withAnimation(.bouncy(duration: 0.3)){
                                        self.chats[index].messages?.append(singleM)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                    self.setDate()
                                }
                            }
                            DispatchQueue.main.async {
                                self.chats[index].lastM = new.first
                            }
                        }
                    } else {
                        self.timeRemaining += 8
                    }
                }
            } else if let last = chats[index].messages?.first?.timestamp {
                service.getMessagesNew(docID: chats[index].convo.id ?? "", lastdoc: last) { messages in
                    var new = [Message]()
                    if self.chats[index].convo.uid_one == myUID {
                        new = messages.filter({ $0.uid_one_did_recieve == true })
                    } else {
                        new = messages.filter({ $0.uid_one_did_recieve == false })
                    }
                    if !new.isEmpty {
                        for i in 0..<new.count {
                            if let text = new[i].text {
                                if let decrypted_text = self.decrypt(text: text, key: self.chats[index].user.publicKey){
                                    new[i].text = decrypted_text
                                }
                            }
                        }
                        if initialFetch {
                            var timeDiff: Bool = false
                            if let mess = self.chats[index].messages {
                                let newMessages = new.filter { message in
                                    !mess.contains(where: { $0.id == message.id })
                                }
                                
                                if let newestTimestamp = newMessages.last?.timestamp.dateValue(),
                                   let oldestTimestamp = self.chats[index].messages?.first?.timestamp.dateValue() {
                                    if newestTimestamp.timeIntervalSince(oldestTimestamp) > 3600 {
                                        timeDiff = true
                                    }
                                }
                                
                                self.chats[index].messages?.insert(contentsOf: newMessages, at: 0)
                                
                                DispatchQueue.main.async {
                                    self.chats[index].lastM = newMessages.first
                                }
                            } else {
                                self.chats[index].messages = new
                                
                                DispatchQueue.main.async {
                                    self.chats[index].lastM = new.first
                                }
                            }
                            self.setDate()
                            if timeDiff {
                                DispatchQueue.main.async {
                                    self.getNewIndex()
                                }
                            }
                            return
                        }
                        var count = 0.0
                        if let mess = self.chats[index].messages {
                            let newMessages = new.filter { message in
                                !mess.contains(where: { $0.id == message.id })
                            }
                            
                            if !newMessages.isEmpty {
                                if self.newIndex != nil {
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        self.newIndex = nil
                                    }
                                }
                                newMessages.reversed().forEach { singleM in
                                    count += 1
                                    DispatchQueue.main.asyncAfter(deadline: .now() + (count * Double.random(in: 0.7...1.1))) {
                                        withAnimation(.bouncy(duration: 0.3)){
                                            self.chats[index].messages?.insert(singleM, at: 0)
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        }
                                        self.setDate()
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    self.chats[index].lastM = newMessages.first
                                }
                            } else {
                                self.timeRemaining += 8
                            }
                        } else {
                            if self.newIndex != nil {
                                withAnimation(.easeInOut(duration: 0.2)){
                                    self.newIndex = nil
                                }
                            }
                            self.chats[index].messages = []
                            new.forEach { singleM in
                                count += 1
                                DispatchQueue.main.asyncAfter(deadline: .now() + (count * Double.random(in: 0.7...1.1))) {
                                    withAnimation(.bouncy(duration: 0.3)){
                                        self.chats[index].messages?.append(singleM)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                    self.setDate()
                                }
                            }
                            DispatchQueue.main.async {
                                self.chats[index].lastM = new.first
                            }
                        }
                    } else {
                        self.timeRemaining += 12
                    }
                }
            }
        }
    }
    func getMessagesOld(){
        if let index = currentChat {
            if let last = chats[index].messages?.last?.timestamp {
                service.getMessagesMore(docID: chats[index].convo.id ?? "", lastdoc: last){ messages in
                    if !messages.isEmpty {
                        var final = messages
                        for i in 0..<final.count {
                            if let text = final[i].text {
                                if let decrypted_text = self.decrypt(text: text, key: self.chats[index].user.publicKey){
                                    final[i].text = decrypted_text
                                }
                            }
                        }
                        if let mess = self.chats[index].messages {
                            let newMessages = final.filter { message in
                                !mess.contains(where: { $0.id == message.id })
                            }
                            self.chats[index].messages =  mess + newMessages
                        } else {
                            self.chats[index].messages = final
                            self.chats[index].lastM = final.first
                        }
                        self.setDate()
                    }
                }
            }
        }
    }
    func sendMessagesMain(myMessArr: [String], otherUserUid: String, text: String, elo: String?, image: String?, messageID: String, fileData: String?, replyID: String?, selfReply: Bool?, myUsername: String, videoURL: String?, audioURL: String?){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var newText = text
        if let i = currentChat ?? self.chats.firstIndex(where: { $0.user.id ?? "" == otherUserUid }) {
            if !newText.isEmpty && chats[i].convo.encrypted {
                if let enc_string = encrypt(text: newText, i: i) {
                    newText = enc_string
                }
            }
            var first = true
            if let mess = chats[i].messages {
                if !mess.isEmpty {
                    first = false
                }
                if mess.count == 1 && chats[i].user.dev != nil {
                    first = true
                }
            }
            myMessArr.forEach { item in
                if item.contains(otherUserUid) {
                    first = false
                }
            }
            if let veri = chats[i].convo.verified, veri {
                first = false
            }
            
            var replyFrom, replyText, replyImage, replyELO, replyFile, replyAudio, replyVideo: String?
            
            if let rep_id = replyID, let temp = self.chats[i].messages?.first(where: { $0.id == rep_id }), let self_rep = selfReply {
                replyFrom = self_rep ? myUsername : self.chats[i].user.username
                if let text = temp.text, !text.isEmpty {
                    if let result = extractTextEmojiFromStoryURL(urlStr: text), result.emoji != nil || result.text != nil {
                        if let emoji = result.emoji {
                            replyText = getEmojiFromAsset(assetName: emoji)
                        } else if let sText = result.text {
                            replyText = sText
                        }
                    } else {
                        replyText = text
                    }
                } else if let pic = temp.imageUrl ?? self.replyImages.first(where: { $0.0 == rep_id})?.1 {
                    replyImage = pic
                } else if let vid_temp = temp.videoURL {
                    replyVideo = vid_temp
                } else if let audio_temp = temp.audioURL {
                    replyAudio = audio_temp
                } else if let elo_temp = temp.elo {
                    replyELO = elo_temp
                } else if let file_temp = temp.file {
                    replyFile = file_temp
                } else if let lat = temp.lat, let long = temp.long {
                    let name = temp.name ?? "Location"
                    replyText = "https://hustle.page/location/lat=\(lat),long=\(long),name=\(name.trimmingCharacters(in: .whitespacesAndNewlines))"
                } else if let pinmap = temp.pinmap {
                    replyText = pinmap
                }
            }
            
            if first {
                service.getDocID(otherUID: otherUserUid) { optID in
                    if let foundID = optID {
                        self.chats[i].convo.id = optID
                        self.service.sendMessage(docID: foundID, otherUserUID: nil, text: newText, imageUrl: image, elo: elo, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: fileData, pathE: "", replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyELO: replyELO, replyFile: replyFile, videoURL: videoURL, audioURL: audioURL, lat: nil, long: nil, name: nil, replyVideo: replyVideo, replyAudio: replyAudio, pinmap: nil)
                        if self.chats[i].convo.uid_one == uid && !self.chats[i].convo.uid_one_active {
                            self.chats[i].convo.uid_one_active = true
                            self.service.reactivate(convoID: foundID, one: true)
                        } else if self.chats[i].convo.uid_two == uid && !self.chats[i].convo.uid_two_active {
                            self.chats[i].convo.uid_two_active = true
                            self.service.reactivate(convoID: foundID, one: false)
                        }
                    } else {
                        self.chats[i].convo.id = otherUserUid + uid
                        self.service.sendMessage(docID: "", otherUserUID: otherUserUid, text: newText, imageUrl: image, elo: elo, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: otherUserUid + uid, messageID: messageID, fileData: fileData, pathE: "", replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyELO: replyELO, replyFile: replyFile, videoURL: videoURL, audioURL: audioURL, lat: nil, long: nil, name: nil, replyVideo: replyVideo, replyAudio: replyAudio, pinmap: nil)
                    }
                }
            } else {
                self.service.sendMessage(docID: self.chats[i].convo.id ?? "", otherUserUID: nil, text: newText, imageUrl: image, elo: elo, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: fileData, pathE: "", replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyELO: replyELO, replyFile: replyFile, videoURL: videoURL, audioURL: audioURL, lat: nil, long: nil, name: nil, replyVideo: replyVideo, replyAudio: replyAudio, pinmap: nil)
                
                if chats[i].convo.uid_one == uid && !chats[i].convo.uid_one_active {
                    chats[i].convo.uid_one_active = true
                    service.reactivate(convoID: chats[i].convo.id ?? "", one: true)
                } else if chats[i].convo.uid_two == uid && !chats[i].convo.uid_two_active {
                    chats[i].convo.uid_two_active = true
                    service.reactivate(convoID: chats[i].convo.id ?? "", one: false)
                }
            }
            if let elo = elo {
                if let amount = Int(elo) {
                    userService.editElo(withUid: nil, withAmount: -(amount)) { }
                    userService.editElo(withUid: otherUserUid, withAmount: amount) { }
                }
            }
        }
    }
    func sendMessages(myMessArr: [String], otherUserUid: String, withText text: String, elo: String?, image: UIImage?, messageID: String, fileData: String?, pathE: String, replyID: String?, selfReply: Bool?, myUsername: String, videoURL: String?, audioURL: String?, lat: Double?, long: Double?, name: String?){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var newText = text
        if let i = currentChat ?? self.chats.firstIndex(where: { $0.user.id ?? "" == otherUserUid }) {
            if !newText.isEmpty && chats[i].convo.encrypted {
                if let enc_string = encrypt(text: newText, i: i) {
                    newText = enc_string
                }
            }
            var first = true
            if let mess = chats[i].messages {
                if !mess.isEmpty {
                    first = false
                }
                if mess.count == 1 && chats[i].user.dev != nil {
                    first = true
                }
            }
            myMessArr.forEach { item in
                if item.contains(otherUserUid) {
                    first = false
                }
            }
            if let veri = chats[i].convo.verified, veri {
                first = false
            }
            if fileData != nil {
                self.fileMessages.append((messageID, pathE))
            }
            
            var replyFrom, replyText, replyImage, replyELO, replyFile, replyAudio, replyVideo: String?
            
            if let rep_id = replyID, let temp = self.chats[i].messages?.first(where: { $0.id == rep_id }), let self_rep = selfReply {
                replyFrom = self_rep ? myUsername : self.chats[i].user.username
                if let text = temp.text, !text.isEmpty {
                    replyText = text
                } else if let pic = temp.imageUrl ?? self.replyImages.first(where: { $0.0 == rep_id})?.1 {
                    replyImage = pic
                } else if let vid_temp = temp.videoURL {
                    replyVideo = vid_temp
                } else if let audio_temp = temp.audioURL {
                    replyAudio = audio_temp
                } else if let elo_temp = temp.elo {
                    replyELO = elo_temp
                } else if let file_temp = temp.file {
                    replyFile = file_temp
                } else if let lat = temp.lat, let long = temp.long {
                    let name = temp.name ?? "Location"
                    replyText = "https://hustle.page/location/lat=\(lat),long=\(long),name=\(name.trimmingCharacters(in: .whitespacesAndNewlines))"
                }
            }
            
            if first {
                service.getDocID(otherUID: otherUserUid) { optID in
                    if let foundID = optID {
                        self.chats[i].convo.id = optID
                        if let image = image {
                            ImageUploader.uploadImage(image: image, location: "messages", compression: 0.15) { imageUrl, _ in
                                self.service.sendMessage(docID: foundID, otherUserUID: nil, text: newText, imageUrl: imageUrl, elo: elo, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: fileData, pathE: pathE, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyELO: replyELO, replyFile: replyFile, videoURL: videoURL, audioURL: audioURL, lat: lat, long: long, name: name, replyVideo: replyVideo, replyAudio: replyAudio, pinmap: nil)
                                self.replyImages.append((messageID, imageUrl))
                            }
                        } else {
                            self.service.sendMessage(docID: foundID, otherUserUID: nil, text: newText, imageUrl: nil, elo: elo, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: fileData, pathE: pathE, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyELO: replyELO, replyFile: replyFile, videoURL: videoURL, audioURL: audioURL, lat: lat, long: long, name: name, replyVideo: replyVideo, replyAudio: replyAudio, pinmap: nil)
                        }
                        if self.chats[i].convo.uid_one == uid && !self.chats[i].convo.uid_one_active {
                            self.chats[i].convo.uid_one_active = true
                            self.service.reactivate(convoID: foundID, one: true)
                        } else if self.chats[i].convo.uid_two == uid && !self.chats[i].convo.uid_two_active {
                            self.chats[i].convo.uid_two_active = true
                            self.service.reactivate(convoID: foundID, one: false)
                        }
                    } else {
                        self.chats[i].convo.id = otherUserUid + uid
                        if let image = image {
                            ImageUploader.uploadImage(image: image, location: "messages", compression: 0.15) { imageUrl, _ in
                                self.service.sendMessage(docID: "", otherUserUID: otherUserUid, text: newText, imageUrl: imageUrl, elo: elo, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: otherUserUid + uid, messageID: messageID, fileData: fileData, pathE: pathE, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyELO: replyELO, replyFile: replyFile, videoURL: videoURL, audioURL: audioURL, lat: lat, long: long, name: name, replyVideo: replyVideo, replyAudio: replyAudio, pinmap: nil)
                                self.replyImages.append((messageID, imageUrl))
                            }
                        } else {
                            self.service.sendMessage(docID: "", otherUserUID: otherUserUid, text: newText, imageUrl: nil, elo: elo, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: otherUserUid + uid, messageID: messageID, fileData: fileData, pathE: pathE, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyELO: replyELO, replyFile: replyFile, videoURL: videoURL, audioURL: audioURL, lat: lat, long: long, name: name, replyVideo: replyVideo, replyAudio: replyAudio, pinmap: nil)
                        }
                    }
                }
            } else {
                if let image = image {
                    ImageUploader.uploadImage(image: image, location: "messages", compression: 0.15) { imageUrl, _ in
                        self.service.sendMessage(docID: self.chats[i].convo.id ?? "", otherUserUID: nil, text: newText, imageUrl: imageUrl, elo: elo, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: fileData, pathE: pathE, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyELO: replyELO, replyFile: replyFile, videoURL: videoURL, audioURL: audioURL, lat: lat, long: long, name: name, replyVideo: replyVideo, replyAudio: replyAudio, pinmap: nil)
                        self.replyImages.append((messageID, imageUrl))
                    }
                } else {
                    self.service.sendMessage(docID: chats[i].convo.id ?? "", otherUserUID: nil, text: newText, imageUrl: nil, elo: elo, is_uid_one: (chats[i].convo.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: fileData, pathE: pathE, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyELO: replyELO, replyFile: replyFile, videoURL: videoURL, audioURL: audioURL, lat: lat, long: long, name: name, replyVideo: replyVideo, replyAudio: replyAudio, pinmap: nil)
                }
                if chats[i].convo.uid_one == uid && !chats[i].convo.uid_one_active {
                    chats[i].convo.uid_one_active = true
                    service.reactivate(convoID: chats[i].convo.id ?? "", one: true)
                } else if chats[i].convo.uid_two == uid && !chats[i].convo.uid_two_active {
                    chats[i].convo.uid_two_active = true
                    service.reactivate(convoID: chats[i].convo.id ?? "", one: false)
                }
            }
            if let elo = elo {
                if let amount = Int(elo) {
                    userService.editElo(withUid: nil, withAmount: -(amount)) { }
                    userService.editElo(withUid: otherUserUid, withAmount: amount) { }
                }
            }
        }
    }
    func sendStory(i: Int, myMessArr: [String], otherUserUid: String, caption: String, imageUrl: String?, videoUrl: String?, messageID: String, audioStr: String?, lat: Double?, long: Double?, name: String?, pinmap: String?){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var newText = caption
        if i < self.chats.count {
            if !newText.isEmpty && chats[i].convo.encrypted {
                if let enc_string = encrypt(text: newText, i: i) {
                    newText = enc_string
                }
            }
            var first = true
            if let mess = chats[i].messages {
                if !mess.isEmpty {
                    first = false
                }
                if mess.count == 1 && chats[i].user.dev != nil {
                    first = true
                }
            }
            myMessArr.forEach { item in
                if item.contains(otherUserUid) {
                    first = false
                }
            }
            if let veri = chats[i].convo.verified, veri {
                first = false
            }
            
            if first {
                service.getDocID(otherUID: otherUserUid) { optID in
                    if let foundID = optID {
                        self.chats[i].convo.id = optID

                        self.service.sendMessage(docID: foundID, otherUserUID: nil, text: newText, imageUrl: imageUrl, elo: nil, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: videoUrl, audioURL: audioStr, lat: lat, long: long, name: name, replyVideo: nil, replyAudio: nil, pinmap: pinmap)
                        
                        if self.chats[i].convo.uid_one == uid && !self.chats[i].convo.uid_one_active {
                            self.chats[i].convo.uid_one_active = true
                            self.service.reactivate(convoID: foundID, one: true)
                        } else if self.chats[i].convo.uid_two == uid && !self.chats[i].convo.uid_two_active {
                            self.chats[i].convo.uid_two_active = true
                            self.service.reactivate(convoID: foundID, one: false)
                        }
                    } else {
                        self.chats[i].convo.id = otherUserUid + uid

                        self.service.sendMessage(docID: "", otherUserUID: otherUserUid, text: newText, imageUrl: imageUrl, elo: nil, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: otherUserUid + uid, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: videoUrl, audioURL: audioStr, lat: lat, long: long, name: name, replyVideo: nil, replyAudio: nil, pinmap: pinmap)
                    }
                }
            } else {
                self.service.sendMessage(docID: chats[i].convo.id ?? "", otherUserUID: nil, text: newText, imageUrl: imageUrl, elo: nil, is_uid_one: (chats[i].convo.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: videoUrl, audioURL: audioStr, lat: lat, long: long, name: name, replyVideo: nil, replyAudio: nil, pinmap: pinmap)
                
                if chats[i].convo.uid_one == uid && !chats[i].convo.uid_one_active {
                    chats[i].convo.uid_one_active = true
                    service.reactivate(convoID: chats[i].convo.id ?? "", one: true)
                } else if chats[i].convo.uid_two == uid && !chats[i].convo.uid_two_active {
                    chats[i].convo.uid_two_active = true
                    service.reactivate(convoID: chats[i].convo.id ?? "", one: false)
                }
            }
        }
    }
    func sendStorySec(otherUserUid: String, caption: String, imageUrl: String?, videoUrl: String?, messageID: String, audioStr: String?, lat: Double?, long: Double?, name: String?, pinmap: String?){
        guard let uid = Auth.auth().currentUser?.uid else { return }

        service.getSpecificDoc(otherUID: otherUserUid) { convo in
            if let convof = convo, let id = convof.id {
                self.service.sendMessage(docID: id, otherUserUID: nil, text: caption, imageUrl: imageUrl, elo: nil, is_uid_one: (convof.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: videoUrl, audioURL: audioStr, lat: lat, long: long, name: name, replyVideo: nil, replyAudio: nil, pinmap: pinmap)
                
                if convof.uid_one == uid && !convof.uid_one_active {
                    self.service.reactivate(convoID: id, one: true)
                } else if convof.uid_two == uid && !convof.uid_two_active {
                    self.service.reactivate(convoID: id, one: false)
                }
            } else {
                self.service.sendMessage(docID: "", otherUserUID: otherUserUid, text: caption, imageUrl: imageUrl, elo: nil, is_uid_one: false, newID: otherUserUid + uid, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: videoUrl, audioURL: audioStr, lat: lat, long: long, name: name, replyVideo: nil, replyAudio: nil, pinmap: pinmap)
            }
        }
    }
    func sendInvt(myMessArr: [String], otherUserUid: String, withText text: String, messageID: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let newText = text
        if let i = self.chats.firstIndex(where: { $0.user.id == otherUserUid }) {
            var first = true
            if let mess = chats[i].messages {
                if !mess.isEmpty {
                    first = false
                }
                if mess.count == 1 && chats[i].user.dev != nil {
                    first = true
                }
            }
            myMessArr.forEach { item in
                if item.contains(otherUserUid) {
                    first = false
                }
            }
            if let veri = chats[i].convo.verified, veri {
                first = false
            }
            if first {
                service.getDocID(otherUID: otherUserUid) { optID in
                    if let foundID = optID {
                        self.chats[i].convo.id = optID

                        self.service.sendMessage(docID: foundID, otherUserUID: nil, text: newText, imageUrl: nil, elo: nil, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
                    
                        if self.chats[i].convo.uid_one == uid && !self.chats[i].convo.uid_one_active {
                            self.chats[i].convo.uid_one_active = true
                            self.service.reactivate(convoID: foundID, one: true)
                        } else if self.chats[i].convo.uid_two == uid && !self.chats[i].convo.uid_two_active {
                            self.chats[i].convo.uid_two_active = true
                            self.service.reactivate(convoID: foundID, one: false)
                        }
                    } else {
                        self.chats[i].convo.id = otherUserUid + uid
                        self.service.sendMessage(docID: "", otherUserUID: otherUserUid, text: newText, imageUrl: nil, elo: nil, is_uid_one: (self.chats[i].convo.uid_one == uid) ? true : false, newID: otherUserUid + uid, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
                    }
                }
            } else {
                self.service.sendMessage(docID: chats[i].convo.id ?? "", otherUserUID: nil, text: newText, imageUrl: nil, elo: nil, is_uid_one: (chats[i].convo.uid_one == uid) ? true : false, newID: nil, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
                
                if chats[i].convo.uid_one == uid && !chats[i].convo.uid_one_active {
                    chats[i].convo.uid_one_active = true
                    service.reactivate(convoID: chats[i].convo.id ?? "", one: true)
                } else if chats[i].convo.uid_two == uid && !chats[i].convo.uid_two_active {
                    chats[i].convo.uid_two_active = true
                    service.reactivate(convoID: chats[i].convo.id ?? "", one: false)
                }
            }
        } else if let docID = myMessArr.first(where: { $0.contains(otherUserUid) }) {
            var isFirst = false
            if docID.hasPrefix(otherUserUid) {
                isFirst = true
            }
            self.service.sendMessage(docID: docID, otherUserUID: nil, text: newText, imageUrl: nil, elo: nil, is_uid_one: isFirst, newID: nil, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
        } else {
            service.getDocID(otherUID: otherUserUid) { optID in
                if let foundID = optID {
                    var isFirst = false
                    if foundID.hasPrefix(otherUserUid) {
                        isFirst = true
                    }
                    self.service.sendMessage(docID: foundID, otherUserUID: nil, text: newText, imageUrl: nil, elo: nil, is_uid_one: isFirst, newID: nil, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
                } else {
                    self.service.sendMessage(docID: "", otherUserUID: otherUserUid, text: newText, imageUrl: nil, elo: nil, is_uid_one: true, newID: otherUserUid + uid, messageID: messageID, fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
                }
            }
        }
    }
    func deleteConvo(docID: String){
        var didDelete = false
        if let x = chats.first(where: { $0.convo.id == docID }){
            guard let uid = Auth.auth().currentUser?.uid else { return }
            if x.convo.uid_one == uid {
                if !x.convo.uid_two_active { didDelete = true }
            } else {
                if !x.convo.uid_one_active { didDelete = true }
            }
        }
        service.deleteConvo(docID: docID, otherUserDidDelete: didDelete)
    }
    func seen(docID: String, textId: String){
        service.messageSeen(docID: docID, textId: textId)
    }
    func setEncyption(value: Bool) {
        if let i = currentChat, let id =  chats[i].convo.id{
            service.changeEncryption(docID: id, bool: value)
        }
    }
    func deleteMessage(id: String) {
        if let i = currentChat, let chatID = chats[i].convo.id {
            if let x = chats[i].messages?.firstIndex(where: { $0.id == id }) {
                if let imageID = chats[i].messages?[x].imageUrl {
                    ImageUploader.deleteImage(fileLocation: imageID) { _ in }
                }
                if let id = chats[i].messages?[x].id {
                    service.deleteOld(convoID: chatID, messageId: id)
                    chats[i].messages?.remove(at: x)
                    setDate()
                }
            }
        }
    }
    func deleteMessageID(id: String?) {
        if let i = currentChat, let chatID = chats[i].convo.id, let id = id {
            if let x = chats[i].messages?.firstIndex(where: { $0.id == id }) {
                if let imageID = chats[i].messages?[x].imageUrl {
                    ImageUploader.deleteImage(fileLocation: imageID) { _ in }
                }
                if let url = chats[i].messages?[x].audioURL {
                    ImageUploader.deleteImage(fileLocation: url) { _ in }
                }
                if let url = chats[i].messages?[x].videoURL {
                    ImageUploader.deleteImage(fileLocation: url) { _ in }
                }
                if let url = chats[i].messages?[x].file {
                    ImageUploader.deleteImage(fileLocation: url) { _ in }
                }
                service.deleteOld(convoID: chatID, messageId: id)
                chats[i].messages?.remove(at: x)
                chats[i].lastM = chats[i].messages?.first
                setDate()
            }
        }
    }
    func UserSearchBestFit(){
        let lowercasedQuery = searchText.lowercased()
        self.matchedUsers = searchUsers.filter({
            $0.username.lowercased().contains(lowercasedQuery) ||
            $0.fullname.lowercased().contains(lowercasedQuery)
        })
        chats.forEach { chat in
            if chat.user.fullname.lowercased().contains(lowercasedQuery) || chat.user.username.contains(lowercasedQuery) {
                if !matchedUsers.contains(chat.user){
                    matchedUsers.insert(chat.user, at: 0)
                }
            }
        }
    }
    func UserSearch(userId: String){
        self.loading = true
        searchService.searchUsers(name: searchText) { users in
            self.searchService.searchFullname(name: self.searchText) { usersSec in
                self.loading = false
                
                var all = Array(Set(users + usersSec))
                all = all.filter { $0.id != userId }
                self.searchUsers += all.filter { !self.searchUsers.contains($0) }
                if !all.isEmpty {
                    let tempUsers = all.filter { !self.matchedUsers.contains($0) }
                    self.matchedUsers.insert(contentsOf: tempUsers, at: 0)
                }
                
                if self.matchedUsers.isEmpty {
                    self.noUsersFound = true
                }
            }
        }
    }
    func encrypt(text: String, i: Int) -> String? {
        let temp_pub = chats[i].user.publicKey
        if let publicKeyData = Data(base64Encoded: temp_pub) {
            do {
                let recipientPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKeyData)
                let basic_salt = "Hustlers Salt".data(using: .utf8)!
                if let temp_priv = read(){
                    if let privateKeyData = Data(base64Encoded: temp_priv) {
                        do {
                            let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData)
                            let sharedSecret = try! privateKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)
                            let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                                                    salt: basic_salt,
                                                                                    sharedInfo: Data(),
                                                                                    outputByteCount: 32)
                            let sensitiveMessage = text.data(using: .utf8)!
                            let encryptedData = try! ChaChaPoly.seal(sensitiveMessage, using: symmetricKey).combined
                            let final = encryptedData.base64EncodedString()
                            return final
                        } catch {
                            return nil
                        }
                    }
                }
            } catch { return nil }
        }
        return nil
    }
    func decrypt(text: String, key: String) -> String? {
        if let publicKeyData = Data(base64Encoded: key) {
            do {
                let senderPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKeyData)
                let basic_salt = "Hustlers Salt".data(using: .utf8)!
                if let temp_priv = read(){
                    if let privateKeyData = Data(base64Encoded: temp_priv) {
                        do {
                            let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData)
                            let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: senderPublicKey)
                            let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                                                    salt: basic_salt,
                                                                                    sharedInfo: Data(),
                                                                                    outputByteCount: 32)
                            if let data = Data(base64Encoded: text) {
                                do {
                                    let sealedBox = try ChaChaPoly.SealedBox(combined: data)
                                    let decryptedData = try ChaChaPoly.open(sealedBox, using: symmetricKey)
                                    let final = String(data: decryptedData, encoding: .utf8)
                                    return final
                                } catch {
                                    return nil
                                }
                            }
                        } catch {
                            return nil
                        }
                    }
                }
            } catch { return nil }
        }
        return nil
    }
    func read() -> String? {
        if let key = priv_Key_Saved {
            return key
        } else {
            guard let uid = Auth.auth().currentUser?.uid else { return nil }
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrSynchronizable as String: kCFBooleanTrue!,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
                kSecAttrService as String: "hustles/\(uid)",
                kSecAttrAccount as String: uid,
                kSecReturnData as String: kCFBooleanTrue!,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            
            guard status == errSecSuccess else {
                return nil
            }

            if let keyData = item as? Data,
               let keyString = String(data: keyData, encoding: .utf8) {
                return keyString
            }
            return nil
        }
    }
}

struct Notif_Data: Identifiable, Equatable, Hashable {
    var id: String
    let text1: String
    let text2: String
}
