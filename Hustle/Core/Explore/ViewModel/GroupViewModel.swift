import Foundation
import Firebase
import UIKit
import AudioToolbox
import SwiftUI

class GroupViewModel: ObservableObject {
    @Published var imageMessages: [(String, Image)] = []
    @Published var audioMessages: [(String, URL)] = []
    @Published var reactionAdded: [(String, String)] = []
    let service = ExploreService()
    let userService = UserService()
    @Published var ads = [Tweet]()
    @Published var gotAds: Bool = false
    @Published var tempMes = [Tweet]()
    @Published var groups: [(String, GroupX)] = []
    @Published var subContainers: [(String, [subSquares])] = []
    @Published var groupsDev = [GroupY]()
    @Published var currentGroup: Int?
    @Published var didUploadGroup: Bool = false
    @Published var groupId: String = ""
    var refreshTime = 15
    @Published var requested = [String]()
    @Published var uploaded: Bool = false
    @Published var timeRemaining = 20.0
    var users: [User] = []
    @Published var uploadFaliure: String = ""
    @Published var startNextAudio: String = ""
    @Published var currentAudio: String = ""
    @Published var scrollToReply: String = ""
    @Published var scrollToReplyNow: String = ""
    @Published var editedMessage: String = ""
    @Published var editedMessageID: String = ""
    @Published var newIndex: String? = nil

    func fillSubContainers(){
        if let index = currentGroup, index < groups.count {
            if !subContainers.contains(where: { $0.0 == groups[index].1.id }) {
                subContainers.append((groups[index].1.id, []))
                let position = subContainers.count - 1
                
                let allSqaures = groups[index].1.squares ?? []
                
                var removeIndex = -1

                for i in 0..<allSqaures.count {
                    if allSqaures[i].hasPrefix(":"){
                        if removeIndex == -1 {
                            removeIndex = i
                        }
                        let real = allSqaures[i].dropFirst()
                        subContainers[position].1.append(subSquares(id: "\(UUID())", name: String(real), sub: [], show: true))
                    } else if removeIndex != -1 {
                        let insert = subContainers[position].1.count - 1
                        subContainers[position].1[insert].sub.append(allSqaures[i])
                    }
                }
                
                if removeIndex >= 0 && removeIndex < allSqaures.count {
                    groups[index].1.squares?.removeSubrange(removeIndex..<allSqaures.count)
                }
            }
        }
    }
    func tagUserGroup(myUsername: String, otherUsername: String, message: String, groupName: String) {
        ExploreService().sendNotification(type: "Group", taggerUsername: myUsername, taggedUsername: otherUsername, taggedUID: nil, caption: message, tweetID: nil, groupName: groupName, newsName: nil, questionID: nil, taggerUID: nil)
    }
    func start(group: GroupX, uid: String, blocked: [String]){
        var found: Bool = false
        if let index = groups.firstIndex(where: { $0.1.id == group.id }) {
            currentGroup = index
            found = true
        }
        if !found {
            groups.append(("Main", group))
            currentGroup = groups.count - 1
        }
        let currentSquare = groups[currentGroup ?? 0].0
        fillSubContainers()
        
        if currentSquare != "Rules" && currentSquare != "Info/Description" {
            if let mess = groups[currentGroup ?? 0].1.messages?.first(where: { $0.id == currentSquare }) {
                if mess.messages.count <= 1 {
                    beginGroupConvo(groupId: groups[currentGroup ?? 0].1.id, devGroup: false, blocked: blocked, square: currentSquare)
                } else {
                    beginGroupConvoNew(groupId: groups[currentGroup ?? 0].1.id, devGroup: false, userId: uid, blocked: blocked, square: currentSquare, initialFetch: true)
                }
            } else {
                beginGroupConvo(groupId: groups[currentGroup ?? 0].1.id, devGroup: false, blocked: blocked, square: currentSquare)
            }
        }
    }
    func startGroupDev(groupId: String, uid: String, blocked: [String]){
        var found: Bool = false
        if let index = groupsDev.firstIndex(where: { $0.id == groupId }) {
            currentGroup = index
            found = true
        }
        if !found {
            let new = GroupY(id: groupId, messages: [], last: nil)
            groupsDev.append(new)
            currentGroup = groupsDev.count - 1
        }
        if let mess = groupsDev[currentGroup ?? 0].messages {
            if mess.count <= 1 {
                beginGroupConvo(groupId: groupsDev[currentGroup ?? 0].id, devGroup: true, blocked: blocked, square: "")
            } else {
                beginGroupConvoNew(groupId: groupsDev[currentGroup ?? 0].id, devGroup: true, userId: uid, blocked: blocked, square: "", initialFetch: true)
            }
        } else {
            beginGroupConvo(groupId: groupsDev[currentGroup ?? 0].id, devGroup: true, blocked: blocked, square: "")
        }
    }
    func getGroupConvo(groupId: String, devGroup: Bool, blocked: [String], square: String){
        if let index = self.currentGroup {
            service.getGroupConvo(userGroupId: groupId, groupDev: devGroup, square: devGroup ? "" : groups[index].0) { tweets in
                var temp = tweets
                blocked.forEach { element in
                    temp.removeAll(where: { $0.uid == element })
                }
                if devGroup {
                    self.groupsDev[index].messages = temp
                    self.groupsDev[index].last = tweets.last?.timestamp
                } else {
                    if let x = self.groups[index].1.messages?.firstIndex(where: { $0.id == square }) {
                        self.groups[index].1.messages?[x].messages = temp
                        self.groups[index].1.messages?[x].timestamp = tweets.last?.timestamp
                    } else {
                        let new = GroupMessages(id: square, messages: temp, timestamp: tweets.last?.timestamp)
                        if let all = self.groups[index].1.messages {
                            self.groups[index].1.messages = all + [new]
                        } else {
                            self.groups[index].1.messages = [new]
                        }
                    }
                    self.getLastSeenIndex()
                }
            }
        }
    }
    func beginGroupConvo(groupId: String, devGroup: Bool, blocked: [String], square: String){
        getGroupConvo(groupId: groupId, devGroup: devGroup, blocked: blocked, square: square)
    }
    func getGroupConvoMore(groupId: String, devGroup: Bool, blocked: [String], square: String, completion: @escaping([Tweet]) -> Void){
        if devGroup {
            if let index = currentGroup, let lastdoc = groupsDev[index].last {
                service.getGroupConvoMore(userGroupId: groupId, lastdoc: lastdoc, groupDev: true, square: ""){ tweets in
                    if !tweets.isEmpty {
                        self.groupsDev[index].last = tweets.last?.timestamp
                    }
                    var temp = tweets
                    blocked.forEach { element in
                        temp.removeAll(where: { $0.uid == element })
                    }
                    completion(temp)
                }
            } else { completion([]) }
        } else {
            if let index = currentGroup {
                if let x = groups[index].1.messages?.firstIndex(where: { $0.id == square }), let lastdoc = groups[index].1.messages?[x].timestamp {
                    service.getGroupConvoMore(userGroupId: groupId, lastdoc: lastdoc, groupDev: false, square: groups[index].0){ tweets in
                        if !tweets.isEmpty {
                            self.groups[index].1.messages?[x].timestamp = tweets.last?.timestamp
                        }
                        var temp = tweets
                        blocked.forEach { element in
                            temp.removeAll(where: { $0.uid == element })
                        }
                        completion(temp)
                    }
                }
            } else { completion([]) }
        }
    }
    func beginGroupConvoMore(groupId: String, devGroup: Bool, blocked: [String], square: String){
        if let index = currentGroup {
            getGroupConvoMore(groupId: groupId, devGroup: devGroup, blocked: blocked, square: square){ tweets in
                if !tweets.isEmpty {
                    if devGroup {
                        if let messages = self.groupsDev[index].messages {
                            self.groupsDev[index].messages = messages + tweets
                        }
                    } else {
                        if let x = self.groups[index].1.messages?.firstIndex(where: { $0.id == square }) {
                            if let messages = self.groups[index].1.messages?[x].messages {
                                self.groups[index].1.messages?[x].messages = messages + tweets
                            } else {
                                self.groups[index].1.messages?.append(GroupMessages(id: square, messages: tweets, timestamp: tweets.last?.timestamp))
                            }
                        }
                    }
                } else if !devGroup {
                    if let x = self.groups[index].1.messages?.firstIndex(where: { $0.id == square }) {
                        if self.groups[index].1.messages?[x].messages == nil {
                            self.groups[index].1.messages?.append(GroupMessages(id: square, messages: tweets, timestamp: tweets.last?.timestamp))
                        }
                    }
                }
            }
        }
    }
    func getGroupConvoNew(groupId: String, devGroup: Bool, userId: String, blocked: [String], square: String, initialFetch: Bool, completion: @escaping([Tweet]) -> Void){
        if let index = currentGroup {
            if devGroup {
                if let firstdoc = groupsDev[index].messages?.first?.timestamp {
                    service.fetchNewest(userGroupId: groupId, firstDoc: firstdoc, groupDev: true, square: ""){ tweets in
                        self.tempMes = tweets.filter { $0.uid != userId }
                        blocked.forEach { element in
                            self.tempMes.removeAll(where: { $0.uid == element })
                        }
                        completion(self.tempMes)
                        return
                    }
                } else { completion([]) }
            } else {
                if let x = groups[index].1.messages?.firstIndex(where: { $0.id == square }) {
                    if let firstdoc = groups[index].1.messages?[x].messages.first(where: { $0.uid != userId })?.timestamp {
                        service.fetchNewest(userGroupId: groupId, firstDoc: firstdoc, groupDev: false, square: groups[index].0){ tweets in
                            self.tempMes = tweets.filter { $0.uid != userId }
                            blocked.forEach { element in
                                self.tempMes.removeAll(where: { $0.uid == element })
                            }
                            completion(self.tempMes)
                            return
                        }
                    } else if let firstdoc = groups[index].1.messages?[x].messages.first?.timestamp {
                        service.fetchNewest(userGroupId: groupId, firstDoc: firstdoc, groupDev: false, square: groups[index].0){ tweets in
                            self.tempMes = tweets.filter { $0.uid != userId }
                            blocked.forEach { element in
                                self.tempMes.removeAll(where: { $0.uid == element })
                            }
                            completion(self.tempMes)
                            return
                        }
                    }
                }
            }
        } else { completion([]) }
    }
    func beginGroupConvoNew(groupId: String, devGroup: Bool, userId: String, blocked: [String], square: String, initialFetch: Bool){
        if let index = currentGroup {
            var count = 0.0
            getGroupConvoNew(groupId: groupId, devGroup: devGroup, userId: userId, blocked: blocked, square: square, initialFetch: initialFetch) { tweets in
               if !tweets.isEmpty {
                    self.refreshTime += 8
                    if devGroup {
                        if self.groupsDev[index].messages == nil {
                            self.groupsDev[index].messages = []
                        }
                        if initialFetch {
                            self.groupsDev[index].messages?.insert(contentsOf: tweets, at: 0)
                        } else {
                            tweets.forEach { singleM in
                                count += 1
                                DispatchQueue.main.asyncAfter(deadline: .now() + (count * Double.random(in: 0.4...0.85))) {
                                    withAnimation(.bouncy(duration: 0.3)){
                                        self.groupsDev[index].messages?.insert(singleM, at: 0)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                        }
                    } else if let x = self.groups[index].1.messages?.firstIndex(where: { $0.id == square }) {
                        if self.groups[index].1.messages?[x].messages == nil {
                            self.groups[index].1.messages?[x].messages = []
                        }
                        if initialFetch {
                            var timeDiff: Bool = false
                            
                            if let newestTimestamp = tweets.last?.timestamp.dateValue(),
                               let oldestTimestamp = self.groups[index].1.messages?[x].messages.first?.timestamp.dateValue() {
                                if newestTimestamp.timeIntervalSince(oldestTimestamp) > 3600 {
                                    timeDiff = true
                                }
                            }
                            
                            self.groups[index].1.messages?[x].messages.insert(contentsOf: tweets, at: 0)
                            
                            if timeDiff {
                                self.getLastSeenIndex()
                            }
                        } else {
                            tweets.reversed().forEach { singleM in
                                count += 1
                                DispatchQueue.main.asyncAfter(deadline: .now() + (count * Double.random(in: 0.4...0.85))) {
                                    withAnimation(.bouncy(duration: 0.3)){
                                        self.groups[index].1.messages?[x].messages.insert(singleM, at: 0)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                        }
                    } else {
                        self.groups[index].1.messages?.append(GroupMessages(id: square, messages: tweets, timestamp: tweets.last?.timestamp))
                        
                        if initialFetch {
                            self.getLastSeenIndex()
                        }
                    }
                } else {
                    self.refreshTime += 15
                }
            }
        }
    }
    func getLastSeenIndex() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        if let index = currentGroup {
            let square = self.groups[index].0
            let historyID = self.groups[index].1.id + square
            LastSeenModel().getLastSeenMessageId(id: historyID) { result in
                if let messageID = result {
                    var topMost: String? = nil
                    var bottomMost: Bool? = nil
                    
                    if let x = self.groups[index].1.messages?.firstIndex(where: { $0.id == square }) {
                        self.groups[index].1.messages?[x].messages.forEach { element in
                            if element.uid != uid {
                                if element.id != messageID {
                                    if bottomMost == nil {
                                        topMost = element.id
                                    }
                                } else {
                                    bottomMost = true
                                }
                            } else {
                                bottomMost = true
                            }
                        }
                    } else {
                        self.newIndex = nil
                    }

                    if let mid = topMost {
                        self.newIndex = mid
                    }
                }
            }
        }
    }
    func requestJoin(leader: String, possible: [Chats]){
        if !leader.isEmpty {
            if let index = currentGroup {
                var found = false
                possible.forEach { chat in
                    if chat.convo.uid_one == leader || chat.convo.uid_two == leader {
                        MessageService().sendMessage(docID: chat.convo.id ?? "", otherUserUID: nil, text: "\(groups[index].1.id))(*&^%$#@!\(groups[index].1.title)", imageUrl: nil, elo: nil, is_uid_one: (chat.convo.uid_two == leader) ? true : false, newID: nil, messageID: "", fileData: nil, pathE: "", replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, audioURL: nil, lat: nil, long: nil, name: nil, replyVideo: nil, replyAudio: nil, pinmap: nil)
                        found = true
                    }
                }
                if !found {
                    MessageService().requestJoin(otherUID: leader, send: "\(groups[index].1.id))(*&^%$#@!\(groups[index].1.title)")
                }
            }
        }
    }
    func addReaction(id: String, emoji: String, devGroup: Bool){
        if let index = currentGroup {
            AudioServicesPlaySystemSound(1306)
            self.reactionAdded.append((id, emoji))
            if devGroup {
                service.addReaction(groupID: self.groupsDev[index].id, square: "", docID: id, emoji: emoji, devGroup: devGroup)
                if let x = self.groupsDev[index].messages?.firstIndex(where: { $0.id == id }) {
                    if emoji == "countSmile" {
                        self.groupsDev[index].messages?[x].countSmile = (self.groupsDev[index].messages?[x].countSmile ?? 0) + 1
                    } else if emoji == "countCry" {
                        self.groupsDev[index].messages?[x].countCry = (self.groupsDev[index].messages?[x].countCry ?? 0) + 1
                    } else if emoji == "countThumb" {
                        self.groupsDev[index].messages?[x].countThumb = (self.groupsDev[index].messages?[x].countThumb ?? 0) + 1
                    } else if emoji == "countBless" {
                        self.groupsDev[index].messages?[x].countBless = (self.groupsDev[index].messages?[x].countBless ?? 0) + 1
                    } else if emoji == "countHeart" {
                        self.groupsDev[index].messages?[x].countHeart = (self.groupsDev[index].messages?[x].countHeart ?? 0) + 1
                    } else {
                        self.groupsDev[index].messages?[x].countQuestion = (self.groupsDev[index].messages?[x].countQuestion ?? 0) + 1
                    }
                }
            } else {
                service.addReaction(groupID: self.groups[index].1.id, square: self.groups[index].0, docID: id, emoji: emoji, devGroup: devGroup)
                if let x = self.groups[index].1.messages?.firstIndex(where: { $0.id == self.groups[index].0 }), let y = self.groups[index].1.messages?[x].messages.firstIndex(where: { $0.id == id }) {
                    
                    if emoji == "countSmile" {
                        self.groups[index].1.messages?[x].messages[y].countSmile = (self.groups[index].1.messages?[x].messages[y].countSmile ?? 0) + 1
                        
                    } else if emoji == "countCry" {
                        self.groups[index].1.messages?[x].messages[y].countCry = (self.groups[index].1.messages?[x].messages[y].countCry ?? 0) + 1
                    } else if emoji == "countThumb" {
                        self.groups[index].1.messages?[x].messages[y].countThumb = (self.groups[index].1.messages?[x].messages[y].countThumb ?? 0) + 1
                    } else if emoji == "countBless" {
                        self.groups[index].1.messages?[x].messages[y].countBless = (self.groups[index].1.messages?[x].messages[y].countBless ?? 0) + 1
                    } else if emoji == "countHeart" {
                        self.groups[index].1.messages?[x].messages[y].countHeart = (self.groups[index].1.messages?[x].messages[y].countHeart ?? 0) + 1
                    } else {
                        self.groups[index].1.messages?[x].messages[y].countQuestion = (self.groups[index].1.messages?[x].messages[y].countQuestion ?? 0) + 1
                    }
                }
            }
        }
    }
    func uploadMessage(caption: String, image: UIImage?, devGroup: Bool, user: User, replyFrom: String?, replyID: String?, videoURL: URL?, audioURL: URL?, fileData: Data?, pathE: String, memoryImage: String?){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let tempId = "\(UUID())"
        if let index = currentGroup {
            var replyText, replyImage, replyFile, replyAudio, replyVideo: String?
            
            if replyFrom != nil {
                if devGroup {
                    if let temp_mess = self.groupsDev[index].messages?.first(where: { $0.id == replyID }) {
                        if !temp_mess.caption.isEmpty {
                            replyText = temp_mess.caption
                        } else if let temp_image = temp_mess.image, !temp_image.isEmpty {
                            replyImage = temp_image
                        } else if let temp_video = temp_mess.videoURL, !temp_video.isEmpty {
                            replyVideo = temp_video
                        } else if let temp_audio = temp_mess.audioURL, !temp_audio.isEmpty {
                            replyAudio = temp_audio
                        } else if let temp_file = temp_mess.fileURL, !temp_file.isEmpty {
                            replyFile = temp_file
                        }
                    }
                } else {
                    if let x = self.groups[index].1.messages?.firstIndex(where: { $0.id == self.groups[index].0 }), let temp_mess = self.groups[index].1.messages?[x].messages.first(where: { $0.id == replyID }) {
                        if !temp_mess.caption.isEmpty {
                            replyText = temp_mess.caption
                        } else if let temp_image = temp_mess.image, !temp_image.isEmpty {
                            replyImage = temp_image
                        } else if let temp_video = temp_mess.videoURL, !temp_video.isEmpty {
                            replyVideo = temp_video
                        } else if let temp_audio = temp_mess.audioURL, !temp_audio.isEmpty {
                            replyAudio = temp_audio
                        } else if let temp_file = temp_mess.fileURL, !temp_file.isEmpty {
                            replyFile = temp_file
                        }
                    }
                }
            }
            
            var newTweet = Tweet(id: tempId, caption: caption, timestamp: Timestamp(date: Date()), uid: uid, username: user.username, profilephoto: user.profileImageUrl, video: nil, verified: nil, veriUser: nil, image: nil, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, videoURL: videoURL?.absoluteString, replyFile: replyFile, replyAudio: replyAudio, replyVideo: replyVideo)
            AudioServicesPlaySystemSound(1004)
            
            var currentSquare: String? = nil
            if !devGroup {
                currentSquare = self.groups[index].0
            }
            
            if let image = image {
                imageMessages.append((tempId, Image(uiImage: image)))
            }
            if let audio = audioURL {
                audioMessages.append((tempId, audio))
            }
            if fileData != nil {
                newTweet.async = true
            }
            if let ImageUrl = memoryImage {
                newTweet.image = ImageUrl
            }
            
            if devGroup {
                AudioServicesPlaySystemSound(1004)
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.groupsDev[index].messages?.insert(newTweet, at: 0)
                }
            } else {
                if let x = self.groups[index].1.messages?.firstIndex(where: { $0.id == currentSquare }) {
                    AudioServicesPlaySystemSound(1004)
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.groups[index].1.messages?[x].messages.insert(newTweet, at: 0)
                    }
                }
            }
               
            if let image = image {
                ImageUploader.uploadImage(image: image, location: "groups", compression: 0.15) { ImageUrl, _ in
                    if devGroup {
                        if let pos = self.groupsDev[index].messages?.firstIndex(where: { $0.id == tempId }) {
                            self.groupsDev[index].messages?[pos].image = ImageUrl
                        }
                        self.service.uploadMessage(caption: caption, imagelink: ImageUrl, groupId: self.groupsDev[index].id, devGroup: true, docName: tempId, username: user.username, profilePhoto: user.profileImageUrl ?? "", square: "", replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, vidURL: nil, audioURL: nil, fileURL: nil, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile)
                    } else {
                        if let pos = self.groups[index].1.messages?.firstIndex(where: { $0.id == currentSquare }), let pos2 = self.groups[index].1.messages?[pos].messages.firstIndex(where: { $0.id == tempId }) {
                            self.groups[index].1.messages?[pos].messages[pos2].image = ImageUrl
                        }
                        self.service.uploadMessage(caption: caption, imagelink: ImageUrl, groupId: self.groups[index].1.id, devGroup: false, docName: tempId, username: user.username, profilePhoto: user.profileImageUrl ?? "", square: currentSquare ?? "", replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, vidURL: nil, audioURL: nil, fileURL: nil, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile)
                    }
                }
            } else if let video = videoURL {
                ImageUploader.uploadVideoToFirebaseStorage(localVideoURL: video) { newUrl in
                    if let finalURL = newUrl {
                        if devGroup {
                            if let pos = self.groupsDev[index].messages?.firstIndex(where: { $0.id == tempId }) {
                                self.groupsDev[index].messages?[pos].videoURL = finalURL
                            }
                            self.service.uploadMessage(caption: caption, imagelink: nil, groupId: self.groupsDev[index].id, devGroup: true, docName: tempId, username: user.username, profilePhoto: user.profileImageUrl ?? "", square: "", replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, vidURL: finalURL, audioURL: nil, fileURL: nil, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile)
                        } else {
                            if let pos = self.groups[index].1.messages?.firstIndex(where: { $0.id == currentSquare }), let pos2 = self.groups[index].1.messages?[pos].messages.firstIndex(where: { $0.id == tempId }) {
                                self.groups[index].1.messages?[pos].messages[pos2].videoURL = finalURL
                            }
                            self.service.uploadMessage(caption: caption, imagelink: nil, groupId: self.groups[index].1.id, devGroup: false, docName: tempId, username: user.username, profilePhoto: user.profileImageUrl ?? "", square: self.groups[index].0, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, vidURL: finalURL, audioURL: nil, fileURL: nil, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile)
                        }
                    }
                }
            } else if let audio = audioURL {
                ImageUploader.uploadAudioToFirebaseStorage(localURL: audio) { newUrl in
                    if let finalURL = newUrl {
                        if devGroup {
                            if let pos = self.groupsDev[index].messages?.firstIndex(where: { $0.id == tempId }) {
                                self.groupsDev[index].messages?[pos].audioURL = finalURL
                            }
                            self.service.uploadMessage(caption: caption, imagelink: nil, groupId: self.groupsDev[index].id, devGroup: true, docName: tempId, username: user.username, profilePhoto: user.profileImageUrl ?? "", square: "", replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, vidURL: nil, audioURL: finalURL, fileURL: nil, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile)
                        } else {
                            if let pos = self.groups[index].1.messages?.firstIndex(where: { $0.id == currentSquare }), let pos2 = self.groups[index].1.messages?[pos].messages.firstIndex(where: { $0.id == tempId }) {
                                self.groups[index].1.messages?[pos].messages[pos2].audioURL = finalURL
                            }
                            self.service.uploadMessage(caption: caption, imagelink: nil, groupId: self.groups[index].1.id, devGroup: false, docName: tempId, username: user.username, profilePhoto: user.profileImageUrl ?? "", square: self.groups[index].0, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, vidURL: nil, audioURL: finalURL, fileURL: nil, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile)
                        }
                    }
                }
            } else if let data = fileData {
                ImageUploader.uploadFile(data: data, location: "files", fileExtension: pathE) { newUrl in
                    if !newUrl.isEmpty {
                        if devGroup {
                            if let pos = self.groupsDev[index].messages?.firstIndex(where: { $0.id == tempId }) {
                                self.groupsDev[index].messages?[pos].fileURL = newUrl
                            }
                            self.service.uploadMessage(caption: caption, imagelink: nil, groupId: self.groupsDev[index].id, devGroup: true, docName: tempId, username: user.username, profilePhoto: user.profileImageUrl ?? "", square: "", replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, vidURL: nil, audioURL: nil, fileURL: newUrl, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile)
                        } else {
                            if let pos = self.groups[index].1.messages?.firstIndex(where: { $0.id == currentSquare }), let pos2 = self.groups[index].1.messages?[pos].messages.firstIndex(where: { $0.id == tempId }) {
                                self.groups[index].1.messages?[pos].messages[pos2].fileURL = newUrl
                            }
                            self.service.uploadMessage(caption: caption, imagelink: nil, groupId: self.groups[index].1.id, devGroup: false, docName: tempId, username: user.username, profilePhoto: user.profileImageUrl ?? "", square: self.groups[index].0, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, vidURL: nil, audioURL: nil, fileURL: newUrl, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile)
                        }
                    }
                }
            } else {
                if devGroup {
                    self.service.uploadMessage(caption: caption, imagelink: nil, groupId: self.groupsDev[index].id, devGroup: true, docName: tempId, username: user.username, profilePhoto: user.profileImageUrl ?? "", square: "", replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, vidURL: nil, audioURL: nil, fileURL: nil, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile)
                } else {
                    self.service.uploadMessage(caption: caption, imagelink: memoryImage, groupId: self.groups[index].1.id, devGroup: false, docName: tempId, username: user.username, profilePhoto: user.profileImageUrl ?? "", square: self.groups[index].0, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, vidURL: nil, audioURL: nil, fileURL: nil, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile)
                }
            }
        }
    }
    func uploadStory(caption: String, image: String, groupID: String, username: String, profileP: String?){
        self.service.uploadMessage(caption: caption, imagelink: image, groupId: groupID, devGroup: false, docName: "\(UUID())", username: username, profilePhoto: profileP ?? "", square: "Main", replyFrom: nil, replyText: nil, replyImage: nil, vidURL: nil, audioURL: nil, fileURL: nil, replyVideo: nil, replyAudio: nil, replyFile: nil)
    }
    func uploadStoryVideo(caption: String, video: String, groupID: String, username: String, profileP: String?){
        self.service.uploadMessage(caption: caption, imagelink: nil, groupId: groupID, devGroup: false, docName: "\(UUID())", username: username, profilePhoto: profileP ?? "", square: "Main", replyFrom: nil, replyText: nil, replyImage: nil, vidURL: video, audioURL: nil, fileURL: nil, replyVideo: nil, replyAudio: nil, replyFile: nil)
    }
    func createGroup(title: String, image: UIImage, rules: String, publicStatus: Bool, desc: String){
        service.createGroup(title: title, image: image, rules: rules, publicStatus: publicStatus, desc: desc) { success, id in
            if success {
                self.didUploadGroup = true
                self.groupId = id
            } else {
                if !id.isEmpty { self.groupId = id }
                self.uploadFaliure = "Failed to create, try again later"
            }
        }
    }
    func usersMenu(){
        if let index = currentGroup {
            if groups[index].1.users != nil && !(groups[index].1.users?.isEmpty ?? true){
                return
            } else {
                groups[index].1.users = []
                for i in 0 ..< groups[index].1.members.count {
                    let uid = groups[index].1.members[i]
                    if let x = self.users.firstIndex(where: { $0.id == uid }) {
                        self.groups[index].1.users?.append(self.users[x])
                    } else {
                        self.userService.fetchUser(withUid: uid) { user in
                            self.groups[index].1.users?.append(user)
                            self.users.append(user)
                        }
                    }
                }
            }
        }
    }
    func kick(user: String){
        if let index = currentGroup{
            if let i = groups[index].1.members.firstIndex(of: user) {
                groups[index].1.members.remove(at: i)
            }
            if let users = groups[index].1.users{
                if let x = users.firstIndex(where: { $0.id == user }) {
                    groups[index].1.users?.remove(at: x)
                }
            }
            service.kick(user: user, groupId: groups[index].1.id)
        }
    }
    func promote(user: String){
        if let index = currentGroup {
            groups[index].1.leaders.append(user)
            service.promote(user: user, groupId: groups[index].1.id)
        }
    }
    func demote(user: String){
        if let index = currentGroup {
            service.demote(user: user, groupId: groups[index].1.id)
            groups[index].1.leaders.removeAll(where: { $0 == user })
        }
    }
    func joinGroup(){
        if let index = currentGroup {
            service.joinGroup(groupId: groups[index].1.id)
        }
    }
    func leaveGroup(userId: String){
        if let index = currentGroup {
            if userId != "" {
                groups[index].1.members.removeAll(where: { $0 == userId })
                service.leaveGroup(groupId: groups[index].1.id)
            }
        }
    }
    func editRules(rules: String){
        if let index = currentGroup {
            service.editRules(rules: rules, groupId: groups[index].1.id)
        }
    }
    func editDesc(desc: String) {
        if let index = currentGroup {
            service.editDesc(desc: desc, groupId: groups[index].1.id)
        }
    }
    func editPublic(publicStat: Bool) {
        if let index = currentGroup {
            service.editPublic(publicStat: publicStat, groupId: groups[index].1.id)
        }
    }
    func editCoverImage(image: UIImage, oldImage: String?){
        if let index = currentGroup{
            ImageUploader.uploadImage(image: image, location: "groups", compression: 0.05) { ImageUrl, _ in
                self.service.editCoverImage(groupId: self.groups[index].1.id, imageUrl: ImageUrl)
                self.groups[index].1.imageUrl = ImageUrl
            }
        }
        if let url = oldImage {
            ImageUploader.deleteImage(fileLocation: url) { _ in }
        }
    }
    func editTitle(newTitle: String){
        if let index = currentGroup{
            groups[index].1.title = newTitle
            service.editTitle(groupId: groups[index].1.id, newTitle: newTitle)
        }
    }
    func deleteMessage(messageId: String, image: String?, privateG: Bool){
        if let index = currentGroup {
            if privateG {
                let currentSquare = groups[index].0
                if let x = groups[index].1.messages?.firstIndex(where: { $0.id == currentSquare }) {
                    groups[index].1.messages?[x].messages.removeAll(where: { $0.id == messageId })
                    service.deleteMessage(messageId: messageId, groupId: groups[index].1.id, privateG: true, square: groups[index].0)
                }
            } else {
                groupsDev[index].messages?.removeAll(where: { $0.id == messageId })
                service.deleteMessage(messageId: messageId, groupId: groupsDev[index].id, privateG: false, square: "")
            }
        }
        if let imageURl = image {
            ImageUploader.deleteImage(fileLocation: imageURl) { _ in }
        }
    }
}
