import Foundation
import Firebase
import FirebaseFirestoreSwift
import SwiftUI
import CoreData

class LastSeenModel: ObservableObject {
    var store: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LastSeen")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    var context: NSManagedObjectContext {
        return self.store.viewContext
    }
    
    func getLastSeenMessageId(id: String, completion: @escaping(String?) -> Void) {
        if !id.isEmpty {
            let results = fetchSeen()
            
            for seen in results {
                if let seenArr = seen.seen as? [String] {
                    seenArr.forEach { element in
                        if element.contains(id) {
                            let split = element.split(separator: ",")
                            if split.count == 2 {
                                completion(String(split[1]))
                                return
                            }
                        }
                    }
                }
            }
            completion(nil)
        } else {
            completion(nil)
        }
    }
    func setLastSeen(id: String, messageID: String){
        if !id.isEmpty && !messageID.isEmpty {
            let fullName = id + "," + messageID
            let allSeen = fetchSeen()
            var seenArray: [String] = []
            for seen in allSeen {
                if let seenArr = seen.seen as? [String] {
                    seenArray.append(contentsOf: seenArr)
                }
            }
            deleteAllSeen()
            seenArray.removeAll(where: { $0.contains(id) })
            seenArray.append(fullName)
            let finalArr = Array(Set(seenArray))
            createSeen(seenArray: finalArr)
        }
    }
    func fetchSeen() -> [LastSeen] {
        var seen: [LastSeen] = []
        let fetchRequest: NSFetchRequest<LastSeen> = LastSeen.fetchRequest()

        do {
            seen = try self.context.fetch(fetchRequest)
        } catch {
            print("E")
        }
        return seen
    }
    func deleteAllSeen() {
        let allSeen = self.fetchSeen()
        for seen in allSeen {
            seen.seen = nil
        }
        do {
            try self.context.save()
        } catch {
            print("E")
        }
    }
    func createSeen(seenArray: [String]) {
        let newSeen = LastSeen(context: self.context)
        newSeen.seen = seenArray as NSObject
        
        do {
            try self.context.save()
        } catch {
            print("E")
        }
    }
}

class GroupChatViewModel: Identifiable, ObservableObject {
    @Published var reactionAdded: [(String, String)] = []
    @Published var chats = [GroupConvo]()
    @Published var currentChat: Int?
    @Published var dayArr: [(Int, String)] = []
    @Published var newIndex: Int? = nil
    @Published var imageMessages: [(String, Image)] = []
    @Published var audioMessages: [(String, URL)] = []
    var currentlyFetchingData = false
    var timeRemaining = 7.0
    @Published var possibleUsers = [User]()
    @Published var user_colors: [(String, [String: Color])] = []
    let service = GroupChatService()
    @Published var updateMessages = false
    var timeSinceLast: Date? = nil
    @Published var startNextAudio: String = ""
    @Published var currentAudio: String = ""
    @Published var scrollToReply: String = ""
    @Published var scrollToReplyNow: String = ""
    @Published var editedMessage: String = ""
    @Published var editedMessageID: String = ""
    @Published var GoToPin: String = ""
    
    @Published var navigateMapGroup = false
    @Published var newMapGroupId = ""
    
    func startSingle(id: String?) {
        currentChat = nil
        if let id = id, let index = self.chats.firstIndex(where: { $0.id ?? "" == id })  {
            currentChat = index
            if (self.chats[index].messages ?? []).isEmpty {
                getMessages()
            } else {
                getMessagesNew(initialFetch: true)
                setDate()
            }
            getOnline()
            if (self.chats[index].users ?? []).isEmpty && self.chats[index].allUsersUID.count > 1 {
                guard let myUID = Auth.auth().currentUser?.uid else { return }
                var allPossible = Array(Set(self.chats[index].allUsersUID))
                allPossible.removeAll(where: { $0 == myUID })
                self.chats[index].users = []
                
                allPossible.forEach { element in
                    if let toAdd = self.possibleUsers.first(where: { $0.id == element }) {
                        self.chats[index].users?.append(toAdd)
                    } else {
                        UserService().fetchUser(withUid: element) { toAdd in
                            self.chats[index].users?.append(toAdd)
                            self.possibleUsers.append(toAdd)
                        }
                    }
                }
            }
            
            var allC: [Color] = [.blue, .green, .yellow, .purple, .orange, .indigo, .brown, .pink, .teal, .mint, .cyan, .gray]
            
            if !self.user_colors.contains(where: { $0.0 == id }) {
                var dict: [String: Color] = [:]
                let allPossible = Array(Set(self.chats[index].allUsersUID))
                
                allPossible.forEach { element in
                    if allC.isEmpty {
                        dict[String(element.prefix(6))] = [.blue, .green, .yellow, .purple, .orange, .indigo, .brown, .pink, .teal, .mint, .cyan, .gray].randomElement()
                    } else {
                        dict[String(element.prefix(6))] = allC.removeFirst()
                    }
                }
                self.user_colors.append((id, dict))
            }
        }
    }
    func getAll(pointers: [String], byPass: Bool) {
        if !currentlyFetchingData {
            if (self.chats.isEmpty || byPass) && !pointers.isEmpty {
                currentlyFetchingData = true
                var count = 0
                pointers.forEach { element in
                    service.getConversations(docID: element) { convo in
                        if let convo = convo {
                            self.chats.append(convo)
                            
                            self.service.getFirst(docID: element) { message in
                                if let first = message.first, let index = self.chats.firstIndex(where: {$0.id == element}){
                                    self.chats[index].lastM = first
                                }
                            }
                            
                            if convo.allUsersUID.count > 1 {
                                guard let myUID = Auth.auth().currentUser?.uid else { return }
                                var allPossible = Array(Set(convo.allUsersUID))
                                allPossible.removeAll(where: { $0 == myUID })
                                if let index = self.chats.firstIndex(where: { $0.id == element }){
                                    self.chats[index].users = []
                                }
                                
                                allPossible.forEach { elementX in
                                    if let toAdd = self.possibleUsers.first(where: { $0.id == elementX }) {
                                        if let index = self.chats.firstIndex(where: { $0.id == element }){
                                            self.chats[index].users?.append(toAdd)
                                        }
                                    } else {
                                        UserService().fetchUser(withUid: elementX) { toAdd in
                                            if let index = self.chats.firstIndex(where: { $0.id == element }){
                                                self.chats[index].users?.append(toAdd)
                                            }
                                            self.possibleUsers.append(toAdd)
                                        }
                                    }
                                }
                            }
                            
                            count += 1
                            if count == pointers.count {
                                self.currentlyFetchingData = false
                            }
                        } else {
                            count += 1
                            if count == pointers.count {
                                self.currentlyFetchingData = false
                            }
                        }
                    }
                }
            } else {
                refreshFirst()
            }
        }
    }
    func refreshConvos(pointers: [String]) {
        var finalP = [String]()
        pointers.forEach { element in
            if !chats.contains(where: { $0.id == element }) {
                finalP.append(element)
            }
        }
        if !finalP.isEmpty {
            self.getAll(pointers: finalP, byPass: true)
        }
    }
    func getOnline() {
        if let index = currentChat, let messages = self.chats[index].messages {
            self.chats[index].activeUsers = []
            let final = filterMessagesWithinLast30Minutes(messages: messages)
            final.forEach { element in
                let prefix = (element.id ?? "").prefix(6)
                if let uid = self.chats[index].allUsersUID.first(where: { $0.hasPrefix(prefix) }) {
                    if let temp = self.chats[index].activeUsers, !temp.contains(uid) {
                        self.chats[index].activeUsers?.append(uid)
                    }
                }
            }
        }
    }
    func filterMessagesWithinLast30Minutes(messages: [GroupMessage]) -> [GroupMessage] {
        let thirtyMinutesAgo = Timestamp(date: Date(timeIntervalSinceNow: -1800))
        let filteredMessages = messages.filter { $0.timestamp.dateValue() > thirtyMinutesAgo.dateValue() }
        return filteredMessages
    }
    func getLastSeenIndex() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let uid_prefix = String(uid.prefix(6))
        if let index = currentChat, let id = chats[index].id {
            LastSeenModel().getLastSeenMessageId(id: id) { result in
                if let messageID = result {
                    var topMost: Int? = nil
                    var bottomMost: Int? = nil
   
                    self.chats[index].messages?.enumerated().forEach({ (pos, element) in
                        if let mid = element.id, !mid.hasPrefix(uid_prefix) {
                            if mid != messageID {
                                if bottomMost == nil {
                                    topMost = pos
                                }
                            } else {
                                bottomMost = pos
                            }
                        } else {
                            bottomMost = pos
                        }
                    })
                    
                    if let position = topMost {
                        self.newIndex = position
                    }
                }
            }
        }
    }
    func getMessages() {
        if let index = currentChat {
            service.getMessages(docID: chats[index].id ?? "") { messages in
                self.chats[index].messages = messages
                if !messages.isEmpty {
                    self.chats[index].lastM = messages.first
                    self.setDate()
                    self.getOnline()
                    self.getLastSeenIndex()
                }
            }
        }
    }
    func getMessagesNew(initialFetch: Bool) {
        if let index = currentChat {
            guard let myUID = Auth.auth().currentUser?.uid else { return }
            let prefix = myUID.prefix(6)
            
            if let first = self.chats[index].messages?.first(where: { $0.id?.prefix(6) != prefix })?.timestamp ?? self.chats[index].messages?.first?.timestamp {
                service.getMessagesNew(docID: self.chats[index].id ?? "", lastdoc: first) { messages in
                    if messages.isEmpty {
                        self.timeRemaining += 6
                    } else {
                        var final = messages

                        var count = 0.0
                        if let avoid = self.chats[index].messages {
                            final = final.filter { temp in
                                !avoid.contains { $0.id == temp.id }
                            }
                            
                            if initialFetch {
                                var timeDiff: Bool = false
                                
                                if let newestTimestamp = final.last?.timestamp.dateValue(),
                                   let oldestTimestamp = self.chats[index].messages?.first?.timestamp.dateValue() {
                                    if newestTimestamp.timeIntervalSince(oldestTimestamp) > 3600 {
                                        timeDiff = true
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    self.chats[index].messages?.insert(contentsOf: final, at: 0)
                                }
                                self.setDate()
                                if timeDiff {
                                    DispatchQueue.main.async {
                                        self.getLastSeenIndex()
                                    }
                                }
                            } else {
                                final.reversed().forEach { singleM in
                                    count += 1
                                    DispatchQueue.main.asyncAfter(deadline: .now() + (count * Double.random(in: 0.7...1.1))) {
                                        withAnimation(.bouncy(duration: 0.3)){
                                            self.chats[index].messages?.insert(singleM, at: 0)
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        self.setDate()
                                    }
                                }
                            }
                            
                            self.getOnline()
                            
                            if let first = final.first, first.id != self.chats[index].lastM?.id && (first.timestamp.dateValue() > self.chats[index].lastM?.timestamp.dateValue() ?? Timestamp().dateValue() || self.chats[index].lastM?.timestamp == nil) {
                                DispatchQueue.main.async {
                                    self.chats[index].lastM = first
                                }
                            }
                        } else {
                            self.chats[index].messages = []
                            
                            if initialFetch {
                                var timeDiff: Bool = false
                                
                                if let newestTimestamp = final.last?.timestamp.dateValue(),
                                   let oldestTimestamp = self.chats[index].messages?.first?.timestamp.dateValue() {
                                    if newestTimestamp.timeIntervalSince(oldestTimestamp) > 3600 {
                                        timeDiff = true
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    self.chats[index].messages?.insert(contentsOf: final, at: 0)
                                }
                                self.setDate()
                                if timeDiff {
                                    DispatchQueue.main.async {
                                        self.getLastSeenIndex()
                                    }
                                }
                            } else {
                                final.forEach { singleM in
                                    count += 1
                                    DispatchQueue.main.asyncAfter(deadline: .now() + (count * Double.random(in: 0.7...1.1))) {
                                        withAnimation(.bouncy(duration: 0.3)){
                                            self.chats[index].messages?.append(singleM)
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        self.setDate()
                                    }
                                }
                            }
                            self.getOnline()
                            
                            if let first = final.first, first.id != self.chats[index].lastM?.id && (first.timestamp.dateValue() > self.chats[index].lastM?.timestamp.dateValue() ?? Timestamp().dateValue() || self.chats[index].lastM?.timestamp == nil) {
                                DispatchQueue.main.async {
                                    self.chats[index].lastM = first
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    func getMessagesOld() {
        if let index = currentChat, let last = chats[index].messages?.last?.timestamp {
            service.getMessagesMore(docID: chats[index].id ?? "", lastdoc: last){ messages in
                if !messages.isEmpty {
                    let final = messages
                    
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
    func refreshFirst() {
        if isAtLeast30SecondsOld(date: timeSinceLast) {
            timeSinceLast = Date()
            for (i, chat) in self.chats.enumerated() {
                if let last = chat.lastM {
                    let timestampDate = last.timestamp.dateValue()
                    let currentDate = Date()
                    let timeDifference = currentDate.timeIntervalSince(timestampDate)
                    if let id = chat.id, timeDifference < (24 * 60 * 60) {
                        service.getFirst(docID: id) { message in
                            if let first_message = message.first, first_message.id != last.id && first_message.timestamp.dateValue() > last.timestamp.dateValue() {
                                self.chats[i].lastM = first_message
                            }
                        }
                    }
                }
            }
        }
    }
    func setDate() {
        if let index = currentChat {
            self.dayArr = []
            if let messages = chats[index].messages {
                if let first = messages.first {
                    var last = getDate(date: first.timestamp)
                    for (index, message) in messages.enumerated() {
                        let current = getDate(date: message.timestamp)
                        if last != current {
                            if !dayArr.contains(where: { $0.1 == last }) {
                                self.dayArr.append((index - 1, last))
                            }
                        }
                        if index == (messages.count - 1) {
                            if !dayArr.contains(where: { $0.1 == current }) {
                                self.dayArr.append((index, current))
                            }
                        }
                        last = current
                    }
                }
            }
        }
    }
}

func isAtLeast30SecondsOld(date: Date?) -> Bool {
    guard let date = date else {
        return true
    }
    let thirtySecondsAgo = Date(timeIntervalSinceNow: -8)
    return date <= thirtySecondsAgo
}

func isDateAtLeastOneMinuteOld(date: Date) -> Bool {
    let currentDate = Date()
    let timeInterval = currentDate.timeIntervalSince(date)
    return timeInterval >= 60
}

func isAtLeastXSecondsOld(seconds: Double, date: Date) -> Bool {
    let xSecondsAgo = Date(timeIntervalSinceNow: -seconds)
    return date <= xSecondsAgo
}
