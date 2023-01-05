import SwiftUI
import Kingfisher
import Firebase

struct TempData: Identifiable, Equatable {
    var id: String
    var name: String
    var image: [String]
    var isGroup: Bool
    var timestamp: Timestamp
}

struct SendProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var userModel: MessageViewModel
    @EnvironmentObject var groups: GroupChatViewModel
    @EnvironmentObject var viewModel: JobViewModel
    @EnvironmentObject var popRoot: PopToRoot
    
    @State var noData: Bool = false
    @State private var searchText = ""
    @State private var caption = ""
    @State var allData: [TempData] = []
    @State var selectedData: [TempData] = []
    @State var sameTime = Timestamp(seconds: 1000, nanoseconds: 1000)
    
    @Binding var sendLink: String
    var bigger: Bool? = nil

    var body: some View {
        VStack(spacing: 0){
            TextField("Search", text: $searchText)
                .submitLabel(.search)
                .tint(.blue)
                .autocorrectionDisabled(true)
                .padding(8)
                .padding(.horizontal, 24)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .overlay (
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        Spacer()
                        if extractLatLongName(from: sendLink) == nil {
                            Button {
                                popRoot.alertImage = "link"
                                popRoot.alertReason = "Link Copied"
                                withAnimation {
                                    popRoot.showAlert = true
                                }
                                UIPasteboard.general.string = sendLink
                            } label: {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .onSubmit {
                    if let uid = auth.currentUser?.id, !searchText.isEmpty {
                        viewModel.searchCompleteJob(string: searchText, uid: uid)
                    }
                }
                .padding(.horizontal)
            
            if !allData.isEmpty {
                ScrollView {
                    Color.clear.frame(height: 15)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 30) {
                        ForEach(allData) { element in
                            single(element: element)
                        }
                    }.padding(.horizontal)
                    Color.clear.frame(height: 15)
                }.padding(.top, bigger == nil ? 0 : 12)
            } else if noData {
                VStack(spacing: 10){
                    Spacer()
                    Text("Try searching for users.")
                    Image(systemName: "sparkle.magnifyingglass").foregroundStyle(.gray)
                    Spacer()
                }.font(.headline).bold()
            } else {
                VStack {
                    Spacer()
                    ProgressView().scaleEffect(1.3)
                    Spacer()
                }
            }
            
            Divider().overlay(Color.gray).padding(.bottom, 13)
            
            TextField("Write a message...", text: $caption, axis: .vertical)
                .tint(.blue).lineLimit(4)
                .autocorrectionDisabled(true)
                .padding(.horizontal)
                .padding(.bottom, 13)
            
            Divider().overlay(Color.gray).padding(.bottom, 10)
            
            Button {
                if !selectedData.isEmpty {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    presentationMode.wrappedValue.dismiss()
                    var place: String? = nil
                    if sendLink.contains("post") {
                        popRoot.alertReason = "Post sent"
                    } else if sendLink.contains("story") {
                        popRoot.alertReason = "Story sent"
                    } else if sendLink.contains("$") && sendLink.count < 15 {
                        popRoot.alertReason = "Stock Asset Shared"
                    } else if sendLink.contains("news") {
                        popRoot.alertReason = "News Thread Sent"
                    } else if sendLink.contains("memory") {
                        popRoot.alertReason = "Memory Shared"
                    } else if sendLink.contains("yelp") {
                        popRoot.alertReason = "Place Shared"
                    } else if sendLink.contains("profile") {
                        popRoot.alertReason = "Profile sent"
                    } else if extractLatLongName(from: sendLink) != nil {
                        popRoot.alertReason = "Pin Shared"
                        place = sendLink
                    }
                    popRoot.alertImage = "paperplane.fill"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                    if place == nil {
                        self.caption += (" " + sendLink)
                    }
                    let uid = auth.currentUser?.id ?? ""
                    let uid_prefix = String(uid.prefix(5))
                    selectedData.forEach { element in
                        if element.isGroup {
                            let id = String((auth.currentUser?.id ?? "").prefix(6)) + String("\(UUID())".prefix(10))
                            
                            let new = GroupMessage(id: id, seen: nil, text: caption.isEmpty ? nil : caption, imageUrl: nil, audioURL: nil, videoURL: nil, file: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyFile: nil, replyAudio: nil, replyVideo: nil, countSmile: nil, countCry: nil, countThumb: nil, countBless: nil, countHeart: nil, countQuestion: nil, timestamp: Timestamp(), pinmap: place)
                            
                            if let index = groups.chats.firstIndex(where: { $0.id == element.id }) {
                                GroupChatService().sendMessage(docID: element.id, text: caption, imageUrl: nil, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: place)
                                
                                groups.chats[index].lastM = new
                                groups.chats[index].messages?.insert(new, at: 0)
                                
                                if let indexSec = groups.currentChat, indexSec == index {
                                    if groups.chats[index].messages == nil {
                                        groups.chats[index].messages = [new]
                                    }
                                    groups.setDate()
                                }
                            } else {
                                GroupChatService().sendMessage(docID: element.id, text: caption, imageUrl: nil, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: place)
                            }
                        } else {
                            let id = uid_prefix + String("\(UUID())".prefix(15))
                            
                            if let index = userModel.chats.firstIndex(where: { $0.user.id == element.id }) {
                                let new = Message(id: id, uid_one_did_recieve: (userModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? false : true, seen_by_reciever: false, text: caption.isEmpty ? nil : caption, imageUrl: nil, timestamp: Timestamp(), sentAImage: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, pinmap: place)
                                
                                userModel.sendStory(i: index, myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: element.id, caption: caption, imageUrl: nil, videoUrl: nil, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: place)
                                
                                userModel.chats[index].lastM = new
                                
                                userModel.chats[index].messages?.insert(new, at: 0)
                                
                                if let indexSec = userModel.currentChat, indexSec == index {
                                    if userModel.chats[index].messages == nil {
                                        userModel.chats[index].messages = [new]
                                    }
                                    userModel.setDate()
                                }
                            } else {
                                userModel.sendStorySec(otherUserUid: element.id, caption: caption, imageUrl: nil, videoUrl: nil, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: place)
                            }
                        }
                    }
                }
            } label: {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .overlay {
                        if selectedData.count <= 1 {
                            Text("Send").foregroundStyle(.white).bold()
                        } else {
                            Text("Send separately").foregroundStyle(.white).bold()
                        }
                    }
            }
            .frame(height: 43).padding(.horizontal).padding(.bottom, 12)
        }
        .padding(.top, 20)
        .onAppear {
            userModel.fetchConvos(pointers: auth.currentUser?.myMessages ?? [])
            groups.getAll(pointers: auth.currentUser?.groupChats ?? [], byPass: false)
            
            let chatUsers = userModel.chats.map { $0.user }
            let allUser = Array(Set(chatUsers + viewModel.allUsers))
            allUser.forEach { element in
                if element.id != auth.currentUser?.id && element.dev == nil {
                    addUser(element: element, shouldSort: true)
                }
            }
            
            let allGroups = groups.chats.compactMap({ $0.id })
            allGroups.forEach { element in
                addGroup(gid: element, shouldSort: true)
            }
                
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5){
                if self.allData.count < 9 {
                    viewModel.getFollowing(following: auth.currentUser?.following ?? [], count: (12 - self.allData.count))
                    if self.allData.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5){
                            if self.allData.isEmpty {
                                self.noData = true
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: groups.chats, { _, _ in
            let allGroups = groups.chats.compactMap({ $0.id })
            allGroups.forEach { element in
                addGroup(gid: element, shouldSort: true)
            }
        })
        .onChange(of: userModel.chats, { _, _ in
            let chatUsers = userModel.chats.map { $0.user }
            chatUsers.forEach { element in
                if !self.allData.contains(where: { $0.id == element.id }) && element.dev == nil {
                    addUser(element: element, shouldSort: true)
                }
            }
        })
        .onChange(of: viewModel.allUsers, { _, _ in
            viewModel.allUsers.forEach { element in
                if !self.allData.contains(where: { $0.id == element.id }) {
                    if element.id != auth.currentUser?.id && element.dev == nil {
                        addUser(element: element, shouldSort: true)
                    }
                }
            }
        })
        .onChange(of: searchText) { _, _ in
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.allData = self.allData.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            } else {
                let lowercasedQuery = searchText.lowercased()
                self.allData.sort { (user1, user2) -> Bool in
                    let lowercasedUser1 = user1.name.lowercased()
                    let lowercasedUser2 = user2.name.lowercased()
                    
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
    }
    func addUser(element: User, shouldSort: Bool) {
        var images = [String]()
        var timestamp = Timestamp()
        
        if let image = element.profileImageUrl {
            images.append(image)
        } else if let char = element.fullname.first {
            images.append(String(char))
        }
        
        if let first = userModel.chats.first(where: { $0.user.id == element.id })?.lastM?.timestamp {
            timestamp = first
        } else {
            timestamp = sameTime
        }
        
        self.allData.insert(TempData(id: element.id ?? "", name: element.fullname, image: images, isGroup: false, timestamp: timestamp), at: 0)
        
        if shouldSort && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.allData = self.allData.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
        }
    }
    func addGroup(gid: String, shouldSort: Bool) {
        if let element = groups.chats.first(where: { $0.id == gid }) {
            var images = [String]()
            var groupName = ""
            
            if let name = element.groupName, !name.isEmpty {
                groupName = name
            } else {
                if let first = element.users?.first(where: { $0.username != auth.currentUser?.username })?.username {
                    groupName = first.trimmingCharacters(in: .whitespacesAndNewlines)
                    groupName += " + \(element.users?.count ?? 1)"
                } else {
                    groupName = "Just you"
                }
            }
            
            if let image = element.photo, !image.isEmpty {
                images.append(image)
            } else if let users = element.users {
                let usersWithImageUrl = users.filter { $0.profileImageUrl != nil }
                for user in usersWithImageUrl {
                    if let imageUrl = user.profileImageUrl, images.count < 3 {
                        images.append(imageUrl)
                    }
                }
                if images.count < 3 {
                    let usersWithoutImageUrl = users.filter { $0.profileImageUrl == nil }
                    for user in usersWithoutImageUrl {
                        if let first = user.fullname.first, images.count < 3 {
                            images.append(String(first).uppercased())
                        }
                    }
                }
            }

            if let index = self.allData.firstIndex(where: { $0.id == gid }) {
                self.allData.remove(at: index)
                
                self.allData.insert(TempData(id: element.id ?? "", name: groupName, image: images, isGroup: true, timestamp: element.lastM?.timestamp ?? sameTime), at: index)
            } else {
                self.allData.insert(TempData(id: element.id ?? "", name: groupName, image: images, isGroup: true, timestamp: element.lastM?.timestamp ?? sameTime), at: 0)
            }
            
            if shouldSort && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.allData = self.allData.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            }
        }
    }
    @ViewBuilder
    func single(element: TempData) -> some View {
        VStack(spacing: 6){
            ZStack {
                if element.isGroup {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color(UIColor.darkGray).gradient : Color(UIColor.lightGray).gradient)
                            .frame(width: 70, height: 70)
                            .opacity(0.6)
                        galleryUsers(userPhotos: element.image).scaleEffect(element.image.count == 1 ? 1.0 : 0.78)
                    }
                } else {
                    if let firstImage = element.image.first, let firstChar = firstImage.first, firstImage.count == 1 {
                        personLetterView(size: 70, letter: String(firstChar))
                    } else {
                        personView(size: 70)
                    }
                    if let image = element.image.first {
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .contentShape(Circle())
                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing){
                if selectedData.contains(where: { $0.id == element.id }) {
                    Image(systemName: "checkmark")
                        .font(.caption).foregroundStyle(colorScheme == .dark ? .black : .white)
                        .padding(7).background(Color(red: 5 / 255, green: 136 / 255, blue: 255 / 255))
                        .clipShape(Circle())
                }
            }
            .overlay(alignment: .topLeading){
                if element.isGroup {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 8))
                        .padding(6).background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .offset(x: -1, y: -1)
                }
            }
            Text(element.name)
                .font(.subheadline).lineLimit(1).minimumScaleFactor(0.8).truncationMode(.tail)
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if selectedData.contains(where: { $0.id == element.id }) {
                selectedData.removeAll(where: { $0.id == element.id })
            } else {
                selectedData.append(element)
            }
        }
    }
    @ViewBuilder
    func galleryUsers(userPhotos: [String]) -> some View {
        ZStack {
            if userPhotos.count == 3 {
                if userPhotos[0].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 48, height: 48)
                        .overlay(content: {
                            Text(userPhotos[0]).font(.system(size: 22)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: -13, y: -13)
                } else {
                    KFImage(URL(string: userPhotos[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .offset(x: -13, y: -13)
                }
                if userPhotos[1].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 32, height: 32)
                        .overlay(content: {
                            Text(userPhotos[1]).font(.system(size: 19)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: 23, y: 12)
                } else {
                    KFImage(URL(string: userPhotos[1]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .offset(x: 23, y: 12)
                }
                if userPhotos[2].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 27, height: 27)
                        .overlay(content: {
                            Text(userPhotos[2]).font(.system(size: 15)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: -5, y: 28)
                } else {
                    KFImage(URL(string: userPhotos[2]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 27, height: 27)
                        .clipShape(Circle())
                        .offset(x: -5, y: 28)
                }
            } else if userPhotos.count == 2 {
                if userPhotos[0].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 49, height: 49)
                        .overlay(content: {
                            Text(userPhotos[0]).font(.system(size: 22)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: -12, y: -12)
                } else {
                    KFImage(URL(string: userPhotos[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 49, height: 49)
                        .clipShape(Circle())
                        .offset(x: -12, y: -12)
                }
                if userPhotos[1].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 31, height: 31)
                        .overlay(content: {
                            Text(userPhotos[1]).font(.system(size: 20)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: 18, y: 18)
                } else {
                    KFImage(URL(string: userPhotos[1]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 31, height: 31)
                        .clipShape(Circle())
                        .offset(x: 18, y: 18)
                }
            } else if userPhotos.count == 1 {
                if userPhotos[0].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 70, height: 70)
                        .overlay(content: {
                            Text(userPhotos[0]).font(.system(size: 30)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                } else {
                    KFImage(URL(string: userPhotos[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                }
            } else {
                ProgressView().scaleEffect(0.7)
            }
        }
    }
}

struct ForwardContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var userModel: MessageViewModel
    @EnvironmentObject var groups: GroupChatViewModel
    @EnvironmentObject var viewModel: JobViewModel
    @EnvironmentObject var popRoot: PopToRoot
    
    @State var noData: Bool = false
    @State private var searchText = ""
    @State private var caption = ""
    @State var allData: [TempData] = []
    @State var selectedData: [TempData] = []
    @State var sameTime = Timestamp(seconds: 1000, nanoseconds: 1000)
    
    @Binding var sendLink: String
    @Binding var whichData: Int

    var body: some View {
        VStack(spacing: 0){
            TextField("Search", text: $searchText)
                .submitLabel(.search)
                .tint(.blue)
                .autocorrectionDisabled(true)
                .padding(8)
                .padding(.horizontal, 24)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .overlay (
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        Spacer()
                        Button {
                            popRoot.alertImage = "link"
                            popRoot.alertReason = "Link Copied"
                            withAnimation {
                                popRoot.showAlert = true
                            }
                            UIPasteboard.general.string = sendLink
                        } label: {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                                .padding(.trailing, 8)
                        }
                    }
                )
                .onSubmit {
                    if let uid = auth.currentUser?.id, !searchText.isEmpty {
                        viewModel.searchCompleteJob(string: searchText, uid: uid)
                    }
                }
                .padding(.horizontal)
            
            if !allData.isEmpty {
                ScrollView {
                    Color.clear.frame(height: 15)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 30) {
                        ForEach(allData) { element in
                            single(element: element)
                        }
                    }.padding(.horizontal)
                    Color.clear.frame(height: 15)
                }
            } else if noData {
                VStack(spacing: 10){
                    Spacer()
                    Text("Try searching for users.")
                    Image(systemName: "sparkle.magnifyingglass").foregroundStyle(.gray)
                    Spacer()
                }.font(.headline).bold()
            } else {
                VStack {
                    Spacer()
                    ProgressView().scaleEffect(1.3)
                    Spacer()
                }
            }
            
            Divider().overlay(Color.gray).padding(.bottom, 13)
            
            TextField("Write a message...", text: $caption, axis: .vertical)
                .tint(.blue).lineLimit(4)
                .autocorrectionDisabled(true)
                .padding(.horizontal)
                .padding(.bottom, 13)
            
            Divider().overlay(Color.gray).padding(.bottom, 10)
            
            Button {
                if !selectedData.isEmpty {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    presentationMode.wrappedValue.dismiss()
                    if whichData == 1 {
                        popRoot.alertReason = "Photo Forwarded"
                    } else if whichData == 2 {
                        popRoot.alertReason = "Video Forwarded"
                    } else if whichData == 3 {
                        popRoot.alertReason = "Audio Forwarded"
                    } else if whichData == 4 {
                        popRoot.alertReason = "Location Forwarded"
                    }
                    popRoot.alertImage = "paperplane.fill"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                    
                    let uid = auth.currentUser?.id ?? ""
                    let uid_prefix = String(uid.prefix(5))
                    selectedData.forEach { element in
                        if element.isGroup {
                            let id = String((auth.currentUser?.id ?? "").prefix(6)) + String("\(UUID())".prefix(10))
                            
                            var new = GroupMessage(id: id, seen: nil, text: caption.isEmpty ? nil : caption, imageUrl: nil, audioURL: nil, videoURL: nil, file: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyFile: nil, replyAudio: nil, replyVideo: nil, countSmile: nil, countCry: nil, countThumb: nil, countBless: nil, countHeart: nil, countQuestion: nil, timestamp: Timestamp())
                            
                            let coord = extractCoordinates(from: sendLink)
                            
                            if whichData == 1 {
                                new.imageUrl = sendLink
                            } else if whichData == 2 {
                                new.videoURL = sendLink
                            } else if whichData == 3 {
                                new.audioURL = sendLink
                            } else if let coord = coord, whichData == 4 {
                                new.lat = coord.lat
                                new.long = coord.long
                                new.name = coord.name
                            }
                            
                            if let index = groups.chats.firstIndex(where: { $0.id == element.id }) {
                                GroupChatService().sendMessage(docID: element.id, text: caption, imageUrl: nil, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                                
                                groups.chats[index].lastM = new
                                groups.chats[index].messages?.insert(new, at: 0)
                            } else {
                                GroupChatService().sendMessage(docID: element.id, text: caption, imageUrl: nil, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                            }
                        } else {
                            let id = uid_prefix + String("\(UUID())".prefix(15))
                            if let index = userModel.chats.firstIndex(where: { $0.user.id == element.id }) {
                                var new = Message(id: id, uid_one_did_recieve: (userModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? false : true, seen_by_reciever: false, text: caption, imageUrl: nil, timestamp: Timestamp(), sentAImage: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil)
                                
                                let coord = extractCoordinates(from: sendLink)
                                
                                if whichData == 1 {
                                    new.imageUrl = sendLink
                                } else if whichData == 2 {
                                    new.videoURL = sendLink
                                } else if whichData == 3 {
                                    new.audioURL = sendLink
                                } else if let coord = coord, whichData == 4 {
                                    new.lat = coord.lat
                                    new.long = coord.long
                                    new.name = coord.name
                                }
                                
                                userModel.sendStory(i: index, myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: element.id, caption: caption, imageUrl: whichData == 1 ? sendLink : nil, videoUrl: whichData == 2 ? sendLink : nil, messageID: id, audioStr: whichData == 3 ? sendLink : nil, lat: coord?.lat, long: coord?.long, name: coord?.name, pinmap: nil)
                                
                                userModel.chats[index].lastM = new
                                userModel.chats[index].messages?.insert(new, at: 0)
                                
                                if let indexSec = userModel.currentChat, indexSec == index {
                                    if userModel.chats[index].messages == nil {
                                        userModel.chats[index].messages = [new]
                                    }
                                    userModel.setDate()
                                }
                            } else {
                                let coord = extractCoordinates(from: sendLink)
                                
                                userModel.sendStorySec(otherUserUid: element.id, caption: caption, imageUrl: whichData == 1 ? sendLink : nil, videoUrl: whichData == 2 ? sendLink : nil, messageID: id, audioStr: whichData == 3 ? sendLink : nil, lat: coord?.lat, long: coord?.long, name: coord?.name, pinmap: nil)
                            }
                        }
                    }
                }

            } label: {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .overlay {
                        if selectedData.count <= 1 {
                            Text("Send").foregroundStyle(.white).bold()
                        } else {
                            Text("Send separately").foregroundStyle(.white).bold()
                        }
                    }
            }
            .frame(height: 43).padding(.horizontal).padding(.bottom, 12)
        }
        .padding(.top, 20)
        .onAppear {
            userModel.fetchConvos(pointers: auth.currentUser?.myMessages ?? [])
            groups.getAll(pointers: auth.currentUser?.groupChats ?? [], byPass: false)
            
            let chatUsers = userModel.chats.map { $0.user }
            let allUser = Array(Set(chatUsers + viewModel.allUsers))
            allUser.forEach { element in
                if element.id != auth.currentUser?.id && element.dev == nil {
                    addUser(element: element, shouldSort: true)
                }
            }
            
            let allGroups = groups.chats.compactMap({ $0.id })
            allGroups.forEach { element in
                addGroup(gid: element, shouldSort: true)
            }
                
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5){
                if self.allData.count < 9 {
                    viewModel.getFollowing(following: auth.currentUser?.following ?? [], count: (12 - self.allData.count))
                    if self.allData.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5){
                            if self.allData.isEmpty {
                                self.noData = true
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: groups.chats, { _, _ in
            let allGroups = groups.chats.compactMap({ $0.id })
            allGroups.forEach { element in
                addGroup(gid: element, shouldSort: true)
            }
        })
        .onChange(of: userModel.chats, { _, _ in
            let chatUsers = userModel.chats.map { $0.user }
            chatUsers.forEach { element in
                if !self.allData.contains(where: { $0.id == element.id }) && element.dev == nil {
                    addUser(element: element, shouldSort: true)
                }
            }
        })
        .onChange(of: viewModel.allUsers, { _, _ in
            viewModel.allUsers.forEach { element in
                if !self.allData.contains(where: { $0.id == element.id }) {
                    if element.id != auth.currentUser?.id && element.dev == nil {
                        addUser(element: element, shouldSort: true)
                    }
                }
            }
        })
        .onChange(of: searchText) { _, _ in
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.allData = self.allData.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            } else {
                let lowercasedQuery = searchText.lowercased()
                self.allData.sort { (user1, user2) -> Bool in
                    let lowercasedUser1 = user1.name.lowercased()
                    let lowercasedUser2 = user2.name.lowercased()
                    
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
    }
    func addUser(element: User, shouldSort: Bool) {
        var images = [String]()
        var timestamp = Timestamp()
        
        if let image = element.profileImageUrl {
            images.append(image)
        } else if let char = element.fullname.first {
            images.append(String(char))
        }
        
        if let first = userModel.chats.first(where: { $0.user.id == element.id })?.lastM?.timestamp {
            timestamp = first
        } else {
            timestamp = sameTime
        }
        
        self.allData.insert(TempData(id: element.id ?? "", name: element.fullname, image: images, isGroup: false, timestamp: timestamp), at: 0)
        
        if shouldSort && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.allData = self.allData.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
        }
    }
    func addGroup(gid: String, shouldSort: Bool) {
        if let element = groups.chats.first(where: { $0.id == gid }) {
            var images = [String]()
            var groupName = ""
            
            if let name = element.groupName, !name.isEmpty {
                groupName = name
            } else {
                if let first = element.users?.first(where: { $0.username != auth.currentUser?.username })?.username {
                    groupName = first.trimmingCharacters(in: .whitespacesAndNewlines)
                    groupName += " + \(element.users?.count ?? 1)"
                } else {
                    groupName = "Just you"
                }
            }
            
            if let image = element.photo, !image.isEmpty {
                images.append(image)
            } else if let users = element.users {
                let usersWithImageUrl = users.filter { $0.profileImageUrl != nil }
                for user in usersWithImageUrl {
                    if let imageUrl = user.profileImageUrl, images.count < 3 {
                        images.append(imageUrl)
                    }
                }
                if images.count < 3 {
                    let usersWithoutImageUrl = users.filter { $0.profileImageUrl == nil }
                    for user in usersWithoutImageUrl {
                        if let first = user.fullname.first, images.count < 3 {
                            images.append(String(first).uppercased())
                        }
                    }
                }
            }

            if let index = self.allData.firstIndex(where: { $0.id == gid }) {
                self.allData.remove(at: index)
                
                self.allData.insert(TempData(id: element.id ?? "", name: groupName, image: images, isGroup: true, timestamp: element.lastM?.timestamp ?? sameTime), at: index)
            } else {
                self.allData.insert(TempData(id: element.id ?? "", name: groupName, image: images, isGroup: true, timestamp: element.lastM?.timestamp ?? sameTime), at: 0)
            }
            
            if shouldSort && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.allData = self.allData.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            }
        }
    }
    @ViewBuilder
    func single(element: TempData) -> some View {
        VStack(spacing: 6){
            ZStack {
                if element.isGroup {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color(UIColor.darkGray).gradient : Color(UIColor.lightGray).gradient)
                            .frame(width: 70, height: 70)
                            .opacity(0.6)
                        galleryUsers(userPhotos: element.image).scaleEffect(element.image.count == 1 ? 1.0 : 0.78)
                    }
                } else {
                    if let firstImage = element.image.first, let firstChar = firstImage.first, firstImage.count == 1 {
                        personLetterView(size: 70, letter: String(firstChar))
                    } else {
                        personView(size: 70)
                    }
                    if let image = element.image.first {
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .contentShape(Circle())
                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing){
                if selectedData.contains(where: { $0.id == element.id }) {
                    Image(systemName: "checkmark")
                        .font(.caption).foregroundStyle(colorScheme == .dark ? .black : .white)
                        .padding(7).background(Color(red: 5 / 255, green: 136 / 255, blue: 255 / 255))
                        .clipShape(Circle())
                }
            }
            .overlay(alignment: .topLeading){
                if element.isGroup {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 8))
                        .padding(6).background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .offset(x: -1, y: -1)
                }
            }
            Text(element.name)
                .font(.subheadline).lineLimit(1).minimumScaleFactor(0.8).truncationMode(.tail)
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if selectedData.contains(where: { $0.id == element.id }) {
                selectedData.removeAll(where: { $0.id == element.id })
            } else {
                selectedData.append(element)
            }
        }
    }
    @ViewBuilder
    func galleryUsers(userPhotos: [String]) -> some View {
        ZStack {
            if userPhotos.count == 3 {
                if userPhotos[0].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 48, height: 48)
                        .overlay(content: {
                            Text(userPhotos[0]).font(.system(size: 22)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: -13, y: -13)
                } else {
                    KFImage(URL(string: userPhotos[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .offset(x: -13, y: -13)
                }
                if userPhotos[1].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 32, height: 32)
                        .overlay(content: {
                            Text(userPhotos[1]).font(.system(size: 19)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: 23, y: 12)
                } else {
                    KFImage(URL(string: userPhotos[1]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .offset(x: 23, y: 12)
                }
                if userPhotos[2].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 27, height: 27)
                        .overlay(content: {
                            Text(userPhotos[2]).font(.system(size: 15)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: -5, y: 28)
                } else {
                    KFImage(URL(string: userPhotos[2]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 27, height: 27)
                        .clipShape(Circle())
                        .offset(x: -5, y: 28)
                }
            } else if userPhotos.count == 2 {
                if userPhotos[0].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 49, height: 49)
                        .overlay(content: {
                            Text(userPhotos[0]).font(.system(size: 22)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: -12, y: -12)
                } else {
                    KFImage(URL(string: userPhotos[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 49, height: 49)
                        .clipShape(Circle())
                        .offset(x: -12, y: -12)
                }
                if userPhotos[1].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 31, height: 31)
                        .overlay(content: {
                            Text(userPhotos[1]).font(.system(size: 20)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: 18, y: 18)
                } else {
                    KFImage(URL(string: userPhotos[1]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 31, height: 31)
                        .clipShape(Circle())
                        .offset(x: 18, y: 18)
                }
            } else if userPhotos.count == 1 {
                if userPhotos[0].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 70, height: 70)
                        .overlay(content: {
                            Text(userPhotos[0]).font(.system(size: 30)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                } else {
                    KFImage(URL(string: userPhotos[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                }
            } else {
                ProgressView().scaleEffect(0.7)
            }
        }
    }
}

func extractCoordinates(from url: String) -> (lat: Double, long: Double, name: String)? {
    guard let parametersPart = url.split(separator: "/").last else {
        return nil
    }

    let parameters = parametersPart.split(separator: ",")
    var paramsDict = [String: String]()
    
    for param in parameters {
        let keyValue = param.split(separator: "=")
        if keyValue.count == 2 {
            let key = String(keyValue[0])
            let value = String(keyValue[1])
            paramsDict[key] = value
        }
    }

    if let latString = paramsDict["lat"],
       let longString = paramsDict["long"],
       let name = paramsDict["name"],
       let lat = Double(latString),
       let long = Double(longString) {
        return (lat, long, name)
    }
    return nil
}
