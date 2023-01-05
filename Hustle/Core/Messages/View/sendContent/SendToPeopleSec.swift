import SwiftUI
import Kingfisher
import Firebase

struct SendToPeopleSec: View {
    @Binding var showThisView: Bool
    var video: URL
    var caption: String
    @Binding var addToStory: Bool
    var position: CGFloat
    @State var allG = [groupsSend]()
    @State var allU = [userSend]()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var globeViewModel: GlobeViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var groupViewModel: GroupViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var exploreModel: ExploreViewModel
    @State var showUpdateLocation: Bool = false
    @State var uploaded: Bool = false
    @State var showError: Bool = false
    let manager = GlobeLocationManager()
    @State var fetchingLocation = false
    @EnvironmentObject var searchModel: CitySearchViewModel
    @State var selection = 0
    let muted: Bool
    @EnvironmentObject var groupChats: GroupChatViewModel
    @State var allGCs = [groupsSend]()
    let infinite: Bool
    @Binding var initialSend: messageSendType?
    let isMain: Bool
    let preSavedUrlString: String?
    
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
                    withAnimation(.easeIn(duration: 0.15)){
                        showThisView = false
                    }
                }, label: {
                    Text("Back").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                })
            }
            .padding(.horizontal, 12)
            ScrollView {
                LazyVStack {
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
        .onAppear(perform: {
            if let pre = initialSend {
                withAnimation(.easeInOut(duration: 0.15)){
                    if pre.type == 1 {
                        if let user = viewModel.chats.first(where: { $0.id == pre.id })?.user {
                            if !allU.contains(where: { $0.username == user.username }) {
                                allU.append(userSend(id: user.id ?? "", username: user.username))
                            }
                        }
                    } else if pre.type == 2 {
                        if let chat = groupChats.chats.first(where: { $0.id == pre.id }) {
                            if !allGCs.contains(where: { $0.id == chat.id ?? "" }) {
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
                    } else {
                        if let single = groupViewModel.groups.first(where: { $0.1.id == pre.id })?.1 {
                            if !allG.contains(where: { $0.id == single.id }) {
                                allG.append(groupsSend(id: single.id, title: single.title))
                            }
                        }
                    }
                }
            }
        })
        .alert("Error uploading, checking internet connection", isPresented: $showError) {
            Button("Done", role: .cancel) { }
        }
        .background(colorScheme == .dark ? .black : .white)
        .overlay {
            if showUpdateLocation {
                locUpdate().transition(.move(edge: .bottom))
            } else if !allU.isEmpty || !allG.isEmpty || addToStory || !allGCs.isEmpty {
                VStack {
                    Spacer()
                    sendView()
                }.transition(.move(edge: .bottom))
            }
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
            if uploaded {
                ProgressView().padding(.trailing)
            } else {
                Button(action: {
                    uploaded = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if addToStory {
                        if globeViewModel.currentLocation != nil {
                            finalSend()
                        } else {
                            uploaded = false
                            withAnimation(.easeInOut(duration: 0.1)){
                                showUpdateLocation = true
                            }
                        }
                    } else {
                        finalSend()
                    }
                }, label: {
                    ZStack {
                        Circle().frame(width: 40, height: 40).foregroundStyle(.white)
                        Image(systemName: "arrowtriangle.right.fill").foregroundStyle(.blue).font(.title3)
                    }
                }).padding(.horizontal)
            }
        }
        .scrollIndicators(.hidden)
        .frame(height: 70)
        .padding(.bottom, isMain ? bottom_Inset() : 0)
        .background(Color.blue)
    }
    func finalSend(){
        if let final = preSavedUrlString, !final.isEmpty {
            popRoot.chatSentError = false
            popRoot.chatAlertID = UUID().uuidString
            withAnimation {
                popRoot.chatSentAlert = true
            }
            if let loc = globeViewModel.currentLocation, addToStory {
                addStory(location: loc, videoURL: final)
            }
            sendOtherContent(videoURL: final)
            if isMain {
                viewModel.navigateOut.toggle()
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        } else {
            ImageUploader.uploadVideoToFirebaseStorage(localVideoURL: video) { link in
                if let final = link, !final.isEmpty {
                    popRoot.chatSentError = false
                    popRoot.chatAlertID = UUID().uuidString
                    withAnimation {
                        popRoot.chatSentAlert = true
                    }
                    if addToStory {
                        if let coords = viewModel.postStoryLoc {
                            addStory(location: myLoc(country: "", state: "", city: "", lat: coords.0, long: coords.1), videoURL: final)
                            viewModel.postStoryLoc = nil
                        } else if let loc = globeViewModel.currentLocation {
                            addStory(location: loc, videoURL: final)
                        }
                    }
                    sendOtherContent(videoURL: final)
                    if isMain {
                        viewModel.navigateOut.toggle()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    uploaded = false
                    showError.toggle()
                }
            }
        }
    }
    func addStory(location: myLoc, videoURL: String) {
        if let user = auth.currentUser {
            let size = widthOrHeight(width: false)
            let pos = (size - position) / size
            
            let postID = "\(UUID())"
            globeViewModel.uploadStoryVideo(caption: caption, captionPos: pos, link: nil, videoURL: video, id: postID, uid: user.id ?? "", username: user.username, userphoto: user.profileImageUrl, muted: muted, infinite: infinite == true ? true : nil, optionalLoc: location)
            
            if let x = profile.users.firstIndex(where: { $0.user.id == user.id }) {
                let new = Story(id: postID, uid: user.id ?? "", username: user.username, profilephoto: user.profileImageUrl, long: location.long, lat: location.lat, text: caption.isEmpty ? nil : caption, textPos: pos, videoURL: videoURL, timestamp: Timestamp(), link: nil, geoHash: "")
                
                if profile.users[x].stories != nil {
                    profile.users[x].stories?.append(new)
                } else if profile.users[x].lastUpdatedStories != nil {
                    profile.users[x].stories = [new]
                }
            }
        }
    }
    func sendOtherContent(videoURL: String){
        for i in 0..<allG.count {
            groupViewModel.uploadStoryVideo(caption: caption, video: videoURL, groupID: allG[i].id, username: auth.currentUser?.username ?? "", profileP: auth.currentUser?.profileImageUrl)
        }
        if !allGCs.isEmpty {
            let id = String((auth.currentUser?.id ?? "").prefix(6)) + String("\(UUID())".prefix(10))
            
            let new = GroupMessage(id: id, seen: nil, text: caption.isEmpty ? nil : caption, imageUrl: nil, audioURL: nil, videoURL: videoURL, file: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyFile: nil, replyAudio: nil, replyVideo: nil, countSmile: nil, countCry: nil, countThumb: nil, countBless: nil, countHeart: nil, countQuestion: nil, timestamp: Timestamp())
            
            for i in 0..<allGCs.count {
                if let index = groupChats.chats.firstIndex(where: { $0.id == allGCs[i].id }) {
                    GroupChatService().sendMessage(docID: allGCs[i].id, text: caption, imageUrl: nil, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: videoURL, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                    
                    groupChats.chats[index].lastM = new

                    groupChats.chats[index].messages?.insert(new, at: 0)
                } else {
                    GroupChatService().sendMessage(docID: allGCs[i].id, text: caption, imageUrl: nil, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: videoURL, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                }
            }
        }
        for i in 0..<allU.count {
            if allU[i].id != "lQTwtFUrOMXem7UXesJbDMLbV902" {
                let uid = Auth.auth().currentUser?.uid ?? ""
                let uid_prefix = String(uid.prefix(5))
                let id = uid_prefix + String("\(UUID())".prefix(15))
                if let index = viewModel.chats.firstIndex(where: { $0.user.id == allU[i].id }) {
                    let new = Message(id: id, uid_one_did_recieve: (viewModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? false : true, seen_by_reciever: false, text: caption.isEmpty ? nil : caption, imageUrl: nil, timestamp: Timestamp(), sentAImage: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: videoURL)
                    
                    viewModel.sendStory(i: index, myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: allU[i].id, caption: caption, imageUrl: nil, videoUrl: videoURL, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: nil)
                    
                    viewModel.chats[index].lastM = new
                    
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    }
                } else {
                    viewModel.sendStorySec(otherUserUid: allU[i].id, caption: caption, imageUrl: nil, videoUrl: videoURL, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: nil)
                }
            }
        }
    }
    func locUpdate() -> some View {
        ZStack {
            Rectangle().foregroundStyle(.ultraThickMaterial).ignoresSafeArea()
            VStack(spacing: 0){
                HStack {
                    Button(action: {
                        withAnimation {
                            selection = 0
                        }
                    }, label: {
                        HStack(spacing: 3){
                            Text("Current Location").foregroundStyle(colorScheme == .dark ? .white : .black)
                            Image(systemName: "mappin.and.ellipse").foregroundStyle(.gray)
                        }
                    })
                    Spacer()
                    Button(action: {
                        withAnimation {
                            selection = 1
                        }
                    }, label: {
                        HStack(spacing: 3){
                            Text("Input Location").foregroundStyle(colorScheme == .dark ? .white : .black)
                            Image(systemName: "globe").foregroundStyle(.gray)
                        }
                    })
                }.font(.system(size: 17)).bold().padding(.horizontal)
                ZStack {
                    Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray).padding(.top, 8)
                    HStack {
                        if selection == 1 {
                            Spacer()
                        }
                        Rectangle()
                            .frame(width: widthOrHeight(width: true) * 0.5, height: 3).foregroundStyle(.blue).offset(y: 3)
                            .animation(.easeInOut, value: selection)
                        if selection == 0 {
                            Spacer()
                        }
                    }
                }
                TabView(selection: $selection) {
                    VStack {
                        HStack(spacing: 50){
                            Spacer()
                            VStack {
                                Text("Latitude").font(.subheadline)
                                    .foregroundStyle(.gray)
                                Text(String(format: "%.2f", globeViewModel.currentLocation?.lat ?? 0.0))
                                    .foregroundStyle(.white).font(.title3).bold()
                                    .padding().background(.gray).cornerRadius(15, corners: .allCorners)
                            }
                            VStack {
                                Text("Longitude").font(.subheadline)
                                    .foregroundStyle(.gray)
                                Text(String(format: "%.2f", globeViewModel.currentLocation?.long ?? 0.0))
                                    .foregroundStyle(.white).font(.title3).bold()
                                    .padding().background(.gray).cornerRadius(15, corners: .allCorners)
                            }
                            Spacer()
                        }
                        
                        if fetchingLocation {
                            CirclesExpand()
                        } else if globeViewModel.currentLocation != nil {
                            foundView()
                        } else {
                            locateView()
                        }
                        
                        Spacer()
                        
                        if globeViewModel.currentLocation != nil {
                            Button {
                                fetchingLocation = true
                                manager.requestLocation() { place in
                                    if !place.0.isEmpty && !place.1.isEmpty && (place.2 != 0.0 || place.3 != 0.0){
                                        fetchingLocation = false
                                        globeViewModel.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                                    }
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .foregroundStyle(.blue)
                                    Text("Relocate").font(.title3).bold().foregroundStyle(.white)
                                }.frame(width: 135, height: 40)
                            }.padding(.bottom, 30).disabled(fetchingLocation)
                        }
                    }.padding(.top, 60).tag(0)
                    VStack {
                        ZStack {
                            TextField("Find a place", text: $searchModel.searchQuery)
                                .tint(.blue)
                                .autocorrectionDisabled(true)
                                .padding(15)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 24)
                                .padding(.trailing, 14)
                                .background(Color(.systemGray4))
                                .cornerRadius(20)
                                .onChange(of: searchModel.searchQuery) { _, _ in
                                    searchModel.sortSearch()
                                }
                                .onReceive (
                                    searchModel.$searchQuery
                                        .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
                                ) {
                                    guard !$0.isEmpty else { return }
                                    searchModel.performSearch()
                                }
                                .overlay (
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.gray)
                                            .padding(.leading, 8)
                                        Spacer()
                                        if searchModel.searching {
                                            ProgressView().scaleEffect(1.25).padding(.trailing, 8)
                                        } else {
                                            Button(action: {
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                withAnimation(.easeInOut(duration: 0.1)){
                                                    showUpdateLocation.toggle()
                                                }
                                                searchModel.searchQuery = ""
                                            }, label: {
                                                ZStack {
                                                    Circle().frame(width: 40, height: 40).foregroundStyle(Color.black.opacity(0.7))
                                                    Image(systemName: "mappin.and.ellipse")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 23))
                                                }
                                            }).padding(.trailing, 8)
                                        }
                                    }
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, top_Inset())
                        .ignoresSafeArea()
                        
                        ScrollView {
                            VStack(spacing: 10){
                                ForEach(searchModel.searchResults){ element in
                                    Button(action: {
                                        if !element.city.isEmpty && !element.country.isEmpty && (element.latitude != 0.0 || element.longitude != 0.0) {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            fetchingLocation = false
                                            globeViewModel.currentLocation = myLoc(country: element.country, state: "", city: element.city, lat: element.latitude, long: element.longitude)
                                            withAnimation(.easeIn(duration: 0.2)){
                                                selection = 0
                                            }
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }
                                    }, label: {
                                        HStack {
                                            Image(systemName: "globe")
                                                .font(.system(size: 20)).foregroundStyle(.blue)
                                            Text("\(element.city), \(element.country)").foregroundStyle(.white)
                                                .font(.system(size: 18))
                                            Spacer()
                                            Text("(\(String(format: "%.1f", element.latitude)), \(String(format: "%.1f", element.longitude)))").font(.caption2).foregroundStyle(.purple)
                                        }
                                    })
                                    if element.city != searchModel.searchResults.last?.city {
                                        Divider().overlay(Color(UIColor.lightGray))
                                    }
                                }
                            }.padding().padding(.horizontal, 5)
                        }.scrollIndicators(.hidden)
                    }
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }.padding(.top)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        searchModel.searchQuery = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.1)){
                            showUpdateLocation = false
                        }
                    } label: {
                        Image(systemName: "xmark").font(.title2).padding(12).foregroundStyle(.white)
                            .background(.black).clipShape(Circle())
                    }.padding(30)
                }
            }
        }
    }
    func foundView() -> some View {
        ZStack {
            ForEach(2..<6) { index in
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .opacity(1.0 - CGFloat(index) * 0.1)
                    .frame(width: (120 + CGFloat(index) * CGFloat(index) * 7), height: (120 + CGFloat(index) * CGFloat(index) * 7))
            }
            VStack(spacing: 3){
                Image(systemName: "mappin.and.ellipse").bold()
                Text("\(globeViewModel.currentLocation?.city ?? "---")").minimumScaleFactor(0.6).lineLimit(1).bold()
                if let state = globeViewModel.currentLocation?.state, !state.isEmpty {
                    Text(state).minimumScaleFactor(0.6).lineLimit(1).bold()
                }
                Text("\(globeViewModel.currentLocation?.country ?? "---")").minimumScaleFactor(0.6).lineLimit(1).bold()
            }.offset(y: -15).frame(maxWidth: 120)
        }.padding(.top, 50)
    }
    func locateView() -> some View {
        ZStack {
            ForEach(2..<6) { index in
                Circle()
                    .stroke(Color.gray, lineWidth: 3)
                    .opacity(1.0 - CGFloat(index) * 0.1)
                    .frame(width: (120 + CGFloat(index) * CGFloat(index) * 7), height: (120 + CGFloat(index) * CGFloat(index) * 7))
            }
            Button {
                fetchingLocation = true
                manager.requestLocation() { place in
                    if !place.0.isEmpty && !place.1.isEmpty && (place.2 != 0.0 || place.3 != 0.0){
                        fetchingLocation = false
                        globeViewModel.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                    }
                }
            } label: {
                ZStack {
                    Circle().frame(width: 100, height: 100).foregroundStyle(.blue)
                    Text("Locate me").foregroundStyle(.white).font(.subheadline).bold()
                }
            }
        }.padding(.top, 50)
    }
}

