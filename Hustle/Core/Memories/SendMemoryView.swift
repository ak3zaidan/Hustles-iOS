import SwiftUI
import Kingfisher
import Firebase
import AVFoundation

struct SendMemoryView: View {
    let data: [Memory]
    @Binding var caption: String
    var position: CGFloat
    let infinite: Bool
    let close: () -> Void
    
    @State var allG = [groupsSend]()
    @State var allGCs = [groupsSend]()
    @State var allU = [userSend]()
    @State var addToStory: Bool = false
    @FocusState var focusedField: FocusedField?
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var groupViewModel: GroupViewModel
    @EnvironmentObject var groupChats: GroupChatViewModel
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var exploreModel: ExploreViewModel
    @EnvironmentObject var popRoot: PopToRoot

    var body: some View {
        VStack(spacing: 12){
            HStack(spacing: 10){
                TextField("Search", text: $viewModel.searchText)
                    .tint(.blue)
                    .autocorrectionDisabled(true)
                    .padding(8)
                    .padding(.horizontal, 24)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .onSubmit {
                        if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.UserSearch(userId: auth.currentUser?.id ?? "")
                            viewModel.submitted = true
                        }
                    }
                    .onChange(of: viewModel.searchText) { _, _ in
                        viewModel.noUsersFound = false
                        viewModel.UserSearchBestFit()
                        viewModel.submitted = false
                    }
                    .overlay (
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            Spacer()
                            if viewModel.loading {
                                ProgressView().padding(.trailing, 10)
                            } else if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    viewModel.searchText = ""
                                }, label: {
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.001)
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.gray).font(.headline).bold()
                                    }.frame(width: 40, height: 40)
                                })
                            }
                        }.padding(.leading, 8)
                    )
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.searchText = ""
                    viewModel.submitted = false
                    viewModel.noUsersFound = false
                    close()
                }, label: {
                    Text("Back").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                })
            }
            .padding(.horizontal, 12)
            ScrollView {
                LazyVStack {
                    previewSend()
                    if !viewModel.matchedUsers.isEmpty {
                        HStack {
                            Text("Results").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                            Spacer()
                        }.padding(.top).padding(.horizontal, 12)
                        VStack(spacing: 8){
                            ForEach(viewModel.matchedUsers){ user in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)){
                                        if allU.contains(where: { $0.username == user.username }) {
                                            allU.removeAll(where: { $0.username == user.username })
                                        } else {
                                            allU.append(userSend(id: user.id ?? "", username: user.username))
                                        }
                                    }
                                } label: {
                                    userViewThreeX(user: user, selected: allU.contains(where: { $0.username == user.username }))
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .cornerRadius(8, corners: .allCorners)
                        .padding(.horizontal, 12)
                    }
                    
                    HStack {
                        Text("Stories").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                        Spacer()
                    }.padding(.top).padding(.horizontal, 12)
                    VStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)){
                                addToStory.toggle()
                            }
                        } label: {
                            HStack {
                                if let image = auth.currentUser?.profileImageUrl {
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                } else {
                                    ZStack(alignment: .center){
                                        Image(systemName: "circle.fill")
                                            .resizable()
                                            .foregroundColor(.black)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "questionmark")
                                            .resizable()
                                            .foregroundColor(.white)
                                            .frame(width: 12, height: 17)
                                    }
                                }
                                VStack(alignment: .leading){
                                    Text("My Story - Public").font(.system(size: 16))
                                        .foregroundStyle(addToStory ? .blue : colorScheme == .dark ? .white : .black)
                                    Text("Friends, Followers, and Everyone").foregroundStyle(.gray).font(.caption)
                                }
                                Spacer()
                                if addToStory {
                                    ZStack {
                                        Circle().frame(width: 25, height: 25).foregroundStyle(.blue)
                                        Image(systemName: "checkmark").foregroundStyle(.white).font(.headline)
                                    }
                                } else {
                                    Circle().stroke(.gray, lineWidth: 1).frame(width: 25, height: 25)
                                }
                            }.padding(.horizontal, 10)
                        }
                    }
                    .frame(height: 50)
                    .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .cornerRadius(8, corners: .allCorners)
                    .padding(.horizontal, 12)
                    
                    let eight = viewModel.chats.filter { $0.user.dev == nil }.prefix(8)
                    if !eight.isEmpty {
                        HStack {
                            Text("Best Friends").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                            Spacer()
                        }.padding(.top, 6).padding(.horizontal, 12)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(eight){ chat in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)){
                                        if allU.contains(where: { $0.username == chat.user.username }) {
                                            allU.removeAll(where: { $0.username == chat.user.username })
                                        } else {
                                            allU.append(userSend(id: chat.user.id ?? "", username: chat.user.username))
                                        }
                                    }
                                } label: {
                                    userViewOneX(user: chat.user, selected: allU.contains(where: { $0.username == chat.user.username }))
                                }
                            }
                        }.padding(.horizontal, 12)
                    }
                    if !(exploreModel.userGroup ?? []).isEmpty || !exploreModel.joinedGroups.isEmpty {
                        HStack {
                            Text("My Channels").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                            Spacer()
                        }.padding(.top, 6).padding(.horizontal, 12)
                        ScrollView(.horizontal) {
                            HStack(spacing: 8){
                                Color.clear.frame(width: 12)
                                let userG = exploreModel.userGroup ?? []
                                let all = userG + exploreModel.joinedGroups
                                ForEach(all) { single in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)){
                                            if allG.contains(where: { $0.id == single.id }) {
                                                allG.removeAll(where: { $0.id == single.id })
                                            } else {
                                                allG.append(groupsSend(id: single.id, title: single.title))
                                            }
                                        }
                                    } label: {
                                        groupViewX(group: single, selected: allG.contains(where: { $0.id == single.id }))
                                    }
                                }
                                Color.clear.frame(width: 1)
                            }.padding(.vertical, 4)
                        }.offset(x: -5).scrollIndicators(.hidden)
                    }
                    
                    if !groupChats.chats.isEmpty {
                        HStack {
                            Text("Group Chats").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                            Spacer()
                        }.padding(.top).padding(.horizontal, 12)
                        VStack(spacing: 8){
                            ForEach(groupChats.chats){ chat in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)){
                                        if allGCs.contains(where: { $0.id == chat.id ?? "" }) {
                                            allGCs.removeAll(where: { $0.id == chat.id ?? "" })
                                        } else {
                                            if let title = chat.groupName {
                                                allGCs.append(groupsSend(id: chat.id ?? "", title: title))
                                            } else if let all_u = chat.users?.compactMap({ $0 }) {
                                                if all_u.count <= 3 {
                                                    let title = all_u.map { $0.username }.joined(separator: ", ")
                                                    allGCs.append(groupsSend(id: chat.id ?? "", title: title))
                                                } else {
                                                    var title = all_u.prefix(3).map { $0.username }.joined(separator: ", ")
                                                    title = "\(title)..."
                                                    allGCs.append(groupsSend(id: chat.id ?? "", title: title))
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    if let title = chat.groupName {
                                        groupViewThreeX(title: title, photo: chat.photo, selected: allGCs.contains(where: { $0.id == chat.id ?? "" }))
                                    } else if let all_u = chat.users?.compactMap({ $0 }) {
                                        groupViewThreeX(title: all_u.map { $0.username }.joined(separator: ", "), photo: chat.photo, selected: allGCs.contains(where: { $0.id == chat.id ?? "" }))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .cornerRadius(8, corners: .allCorners)
                        .padding(.horizontal, 12)
                    }
                    
                    let all = viewModel.chats.filter { $0.user.dev == nil }
                    if !all.isEmpty {
                        HStack {
                            Text("Recents").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                            Spacer()
                        }.padding(.top).padding(.horizontal, 12)
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                Color.clear.frame(width: 12)
                                ForEach(all){ chat in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)){
                                            if allU.contains(where: { $0.username == chat.user.username }) {
                                                allU.removeAll(where: { $0.username == chat.user.username })
                                            } else {
                                                allU.append(userSend(id: chat.user.id ?? "", username: chat.user.username))
                                            }
                                        }
                                    } label: {
                                        userViewTwoX(user: chat.user, selected: allU.contains(where: { $0.username == chat.user.username }))
                                    }
                                }
                                Color.clear.frame(width: 1)
                            }
                        }.frame(height: 130).offset(x: -5).scrollIndicators(.hidden)
                    }
                    if !viewModel.following.isEmpty {
                        HStack {
                            Text("Following").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                            Spacer()
                        }.padding(.top).padding(.horizontal, 12)
                        VStack(spacing: 8){
                            ForEach(viewModel.following){ user in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)){
                                        if allU.contains(where: { $0.username == user.username }) {
                                            allU.removeAll(where: { $0.username == user.username })
                                        } else {
                                            allU.append(userSend(id: user.id ?? "", username: user.username))
                                        }
                                    }
                                } label: {
                                    userViewThreeX(user: user, selected: allU.contains(where: { $0.username == user.username }))
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .cornerRadius(8, corners: .allCorners)
                        .padding(.horizontal, 12)
                    }
                    if !viewModel.mutualFriends.isEmpty {
                        HStack {
                            Text("Mutual Friends").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                            Spacer()
                        }.padding(.top).padding(.horizontal, 12)
                        VStack(spacing: 8){
                            let all = viewModel.mutualFriends.filter { $0.dev == nil && $0.id != auth.currentUser?.id }
                            ForEach(all){ user in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)){
                                        if allU.contains(where: { $0.username == user.username }) {
                                            allU.removeAll(where: { $0.username == user.username })
                                        } else {
                                            allU.append(userSend(id: user.id ?? "", username: user.username))
                                        }
                                    }
                                } label: {
                                    userViewThreeX(user: user, selected: allU.contains(where: { $0.username == user.username }))
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .cornerRadius(8, corners: .allCorners)
                        .padding(.horizontal, 12)
                    }
                    Color.clear.frame(height: (!allU.isEmpty || !allG.isEmpty || addToStory) ? 155 : 85)
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(content: {
            if colorScheme == .dark {
                Color.black.ignoresSafeArea()
            } else {
                Color.white.ignoresSafeArea()
            }
        })
        .overlay {
            if !allU.isEmpty || !allG.isEmpty || addToStory || !allGCs.isEmpty {
                VStack {
                    Spacer()
                    sendView()
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
    @ViewBuilder
    func previewSend() -> some View {
        HStack(alignment: .top){
            VStack(spacing: 4){
                if let image = data.first?.image {
                    KFImage(URL(string: image))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 55, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                } else if let video = data.first?.video, let url = URL(string: video) {
                    SendSmallVideoPlayer(videoURL: url).frame(width: 55, height: 80)
                }
                if data.count > 1 {
                    Text("+\(data.count - 1) More").font(.subheadline).fontWeight(.semibold)
                }
            }
            TextField("Add a chat", text: $caption, axis: .vertical)
                .tint(.blue)
                .lineLimit(data.count > 1 ? 5 : 4)
                .focused($focusedField, equals: .one)
        }
        .padding(10)
        .background(.gray.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 10)
        .onTapGesture {
            focusedField = .one
        }
    }
    func sendView() -> some View {
        HStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal){
                    HStack(spacing: 5){
                        if addToStory {
                            Text("My Story-Public")
                                .padding(6).foregroundStyle(.white)
                                .background(Color.white.opacity(0.25)).cornerRadius(15, corners: .allCorners)
                        }
                        ForEach(allGCs) { group in
                            Text(group.title)
                                .padding(6).foregroundStyle(.white)
                                .background(Color.white.opacity(0.25)).cornerRadius(15, corners: .allCorners)
                        }
                        ForEach(allG) { group in
                            if !allU.isEmpty || group != allG.last {
                                Text("\(group.title),").foregroundStyle(.white)
                            } else {
                                Text("\(group.title)").foregroundStyle(.white)
                            }
                        }
                        ForEach(allU) { user in
                            if user == allU.last {
                                Text("\(user.username)").foregroundStyle(.white)
                            } else {
                                Text("\(user.username),").foregroundStyle(.white)
                            }
                        }
                        Color.clear.frame(width: 1, height: 1).id("end")
                            .onChange(of: allGCs) { old, new in
                                if old.count < new.count {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        proxy.scrollTo("end", anchor: .trailing)
                                    }
                                }
                            }
                            .onChange(of: allG) { old, new in
                                if old.count < new.count {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        proxy.scrollTo("end", anchor: .trailing)
                                    }
                                }
                            }
                            .onChange(of: allU) { old, new in
                                if old.count < new.count {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        proxy.scrollTo("end", anchor: .trailing)
                                    }
                                }
                            }
                    }.padding(.leading)
                }
            }
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                sendMessages()
                sendGroupChats()
                sendServers()
                if addToStory {
                    sendStory()
                }
                
                //showing notification
                popRoot.chatSentError = false
                popRoot.chatAlertID = UUID().uuidString
                withAnimation {
                    popRoot.chatSentAlert = true
                }
                
                close()
            }, label: {
                ZStack {
                    Circle().frame(width: 40, height: 40).foregroundStyle(.white)
                    Image(systemName: "arrowtriangle.right.fill").foregroundStyle(.blue).font(.title3)
                }
            }).padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .frame(height: 70)
        .padding(.bottom, bottom_Inset())
        .background(Color.blue)
    }
    func sendMessages() {
        data.forEach { element in
            for i in 0..<allU.count {
                if allU[i].id != "lQTwtFUrOMXem7UXesJbDMLbV902" {
                    let uid = Auth.auth().currentUser?.uid ?? ""
                    let uid_prefix = String(uid.prefix(5))
                    let id = uid_prefix + String("\(UUID())".prefix(15))
                    
                    if let index = viewModel.chats.firstIndex(where: { $0.user.id == allU[i].id }) {
                        let new = Message(id: id, uid_one_did_recieve: (viewModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? false : true, seen_by_reciever: false, text: caption.isEmpty ? nil : caption, imageUrl: element.image, timestamp: Timestamp(), sentAImage: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: element.video)
                        
                        viewModel.sendStory(i: index, myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: allU[i].id, caption: caption, imageUrl: element.image, videoUrl: element.video, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: nil)
                        
                        viewModel.chats[index].lastM = new
                        
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    } else {
                        viewModel.sendStorySec(otherUserUid: allU[i].id, caption: caption, imageUrl: element.image, videoUrl: element.video, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: nil)
                    }
                }
            }
        }
    }
    func sendGroupChats() {
        data.forEach { element in
            let id = String((auth.currentUser?.id ?? "").prefix(6)) + String("\(UUID())".prefix(10))
            
            let new = GroupMessage(id: id, seen: nil, text: caption.isEmpty ? nil : caption, imageUrl: element.image, audioURL: nil, videoURL: element.video, file: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyFile: nil, replyAudio: nil, replyVideo: nil, countSmile: nil, countCry: nil, countThumb: nil, countBless: nil, countHeart: nil, countQuestion: nil, timestamp: Timestamp())
            
            for i in 0..<allGCs.count {
                if let index = groupChats.chats.firstIndex(where: { $0.id == allGCs[i].id }) {
                    GroupChatService().sendMessage(docID: allGCs[i].id, text: caption, imageUrl: element.image, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: element.video, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                    
                    groupChats.chats[index].lastM = new

                    groupChats.chats[index].messages?.insert(new, at: 0)
                } else {
                    GroupChatService().sendMessage(docID: allGCs[i].id, text: caption, imageUrl: element.image, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: element.video, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                }
            }
        }
    }
    func sendServers() {
        if let user = auth.currentUser {
            data.forEach { element in
                for i in 0..<allG.count {
                    if let image = element.image {
                        groupViewModel.uploadStory(caption: caption, image: image, groupID: allG[i].id, username: user.username, profileP: user.profileImageUrl)
                    } else if let video = element.video {
                        groupViewModel.uploadStoryVideo(caption: caption, video: video, groupID: allG[i].id, username: user.username, profileP: user.profileImageUrl)
                    }
                }
            }
        }
    }
    func sendStory() {
        if let user = auth.currentUser {
            data.forEach { element in
                let size = widthOrHeight(width: false)
                let pos = (size - position) / size
                
                var lat: Double? = nil
                var long: Double? = nil
                if let latTemp = element.lat, let longTemp = element.long {
                    lat = Double(latTemp)
                    long = Double(longTemp)
                }
                
                let postID = "\(UUID())"
                GlobeService().uploadStory(caption: caption, captionPos: pos, link: nil, imageLink: element.image, videoLink: element.video, id: postID, uid: user.id ?? "", username: user.username, userphoto: user.profileImageUrl, long: long, lat: lat, muted: false, infinite: infinite == true ? true : nil)
                
                if let x = profile.users.firstIndex(where: { $0.user.id == user.id }) {
                    let new = Story(id: postID, uid: user.id ?? "", username: user.username, profilephoto: user.profileImageUrl, long: long, lat: lat, text: caption.isEmpty ? nil : caption, textPos: pos, imageURL: element.image, videoURL: element.video, timestamp: Timestamp(), link: nil, geoHash: "")
                    
                    if profile.users[x].stories != nil {
                        profile.users[x].stories?.append(new)
                    }
                }
            }
        }
    }
}

struct SendSmallVideoPlayer: View {
    private let screenSize = UIScreen.main.bounds
    var videoURL: URL
    var videoPlayer: AVPlayer? = nil
    @State var thumbNail: UIImage? = nil
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        self.videoPlayer = AVPlayer(url: videoURL)
    }
    
    var body: some View {
        GeometryReader {
            let size = $0.size

            if let thumbnail = thumbNail, let player = videoPlayer {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .overlay {
                        CustomVideoPlayer(player: player)
                            .transition(.identity)
                            .onAppear {
                                player.isMuted = true
                                player.play()
                                videoPlayer?.isMuted = true
                                videoPlayer?.play()
                                NotificationCenter.default.addObserver (
                                    forName: .AVPlayerItemDidPlayToEndTime,
                                    object: player.currentItem,
                                    queue: .main
                                ) { _ in
                                    player.seek(to: .zero)
                                    player.play()
                                }
                                player.actionAtItemEnd = .none
                            }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.gray).opacity(0.2)
                    .overlay(content: {
                        ProgressView().scaleEffect(1.2)
                    })
                    .onAppear {
                        extractImageAt(f_url: videoURL, time: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) { thumbnail in
                            self.thumbNail = thumbnail
                        }
                    }
            }
        }
    }
}
