import SwiftUI
import Kingfisher
import Firebase
import AVFoundation

struct emojiUser: Identifiable {
    let id: String = UUID().uuidString
    var user: User
    var emoji: String
}

struct StoryStatsView: View {
    @EnvironmentObject var popRoot: PopToRoot
    @Environment(\.colorScheme) var colorScheme
    @State var users = [emojiUser]()
    @State var tempHold = [emojiUser]()
    @State var viewers: [String] = []
    @State var searchText = ""
    @State var recentsFirst = false
    @State var onlyFriends = false
    @State var keyboardGone = false
    @State var rotation = 0.0
    @State var disableRot = false
    @State var showUpToDate = false
    @FocusState var focusField: FocusedField?
    @State private var showForward: Bool = false
    @State private var sendLink: String = ""
    @State var NavigateToChat = false
    //upload post
    @State private var showNewTweetView = false
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State var initialContent: uploadContent? = nil
    @State var place: myLoc? = nil
    
    @Binding var showStats: Bool
    @Binding var storyID: String
    @Binding var disableDrag: Bool
    let contentURL: String
    let isVideo: Bool
    let lat: Double?
    let long: Double?
    let views: [String]
    let following: [String]
    let isMap: Bool
    let cid: String
    let disableNav: Bool
    let canOpenProfile: Bool
    let canOpenChat: Bool
    let externalUpload: Bool
    let bigger: Bool
    let openUser: (String) -> Void
    let openChat: (String) -> Void
    let stopVideo: (Bool) -> Void
    let upload: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            if !showStats {
                bottomOptions()
                    .transition(.move(edge: .bottom))
            }
        }
        .fullScreenCover(isPresented: $showNewTweetView){
            NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent, yelpID: nil)
                .onDisappear(perform: {
                    stopVideo(false)
                })
        }
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink, bigger: bigger ? true : nil)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.7), .large])
        })
        .onChange(of: storyID, initial: true, {
            setUpViewers()
        })
        .onChange(of: showStats, { _, _ in
            if showStats {
                mainInit()
            }
        })
        .sheet(isPresented: $showStats, content: {
            ZStack {
                if colorScheme == .dark {
                    Color.white.opacity(1.0)
                }
                Color.black.opacity(0.9)
                sheetView()
                    .overlay {
                        if showUpToDate {
                            VStack {
                                Spacer()
                                Text("Story up to Date.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .padding(11)
                                    .background(content: {
                                        ZStack {
                                            Color.white.opacity(0.5)
                                            TransparentBlurView(removeAllFilters: true)
                                                .blur(radius: 10, opaque: true)
                                                .background(.black.opacity(0.7))
                                        }
                                    })
                                    .overlay(content: {
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(.blue, lineWidth: 1.0)
                                    })
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.15)){
                                            showUpToDate = false
                                        }
                                    }
                            }
                            .padding(.bottom, 50)
                            .transition(.move(edge: .bottom))
                        }
                    }
            }
            .ignoresSafeArea()
            .presentationDetents([.fraction(0.7)])
            .interactiveDismissDisabled()
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.7)))
        })
    }
    func mainInit() {
        var tempViews = self.views
        
        if let newViews = popRoot.updatedView.first(where: { $0.0 == storyID })?.3 {
            tempViews = newViews
        }
        
        tempViews.forEach { element in
            if let info = extractUidAndEmoji(from: element), let uid = info.0 {
                addUser(uid: uid, emoji: info.1, sid: storyID)
            }
        }
    }
    func setUpViewers() {
        viewers = []
        users = []
        tempHold = []
        let viewerUIDs = uidArray(onlyIncludeFriends: false)
        for i in 0..<viewerUIDs.count {
            if viewers.count == 3 {
                return
            }
            if let photo = popRoot.randomUsers.first(where: { $0.id == viewerUIDs[i] })?.profileImageUrl {
                viewers.append(photo)
            }
        }
    }
    func refreshStoryView() {
        let sid = storyID
        GlobeService().getSingleStory(id: sid) { optional_story in
            if let storyViews = optional_story?.views, !storyViews.isEmpty {
                if let index = popRoot.updatedView.firstIndex(where: { $0.0 == sid }) {
                    popRoot.updatedView[index].1 = storyViews.count
                    popRoot.updatedView[index].2 = countViewsContainsReaction(views: storyViews)
                    popRoot.updatedView[index].3 = storyViews
                } else {
                    popRoot.updatedView.append((sid, storyViews.count, countViewsContainsReaction(views: storyViews), storyViews))
                }
                storyViews.forEach { element in
                    if let info = extractUidAndEmoji(from: element), let uid = info.0 {
                        addUser(uid: uid, emoji: info.1, sid: sid)
                    }
                }
                withAnimation(.easeInOut(duration: 0.2)){
                    showUpToDate = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.2)){
                        showUpToDate = false
                    }
                }
            } else if self.views.isEmpty {
                withAnimation(.easeInOut(duration: 0.2)){
                    showUpToDate = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.2)){
                        showUpToDate = false
                    }
                }
            }
        }
    }
    func addUser(uid: String, emoji: String?, sid: String) {
        if sid == storyID {
            if let index = self.users.firstIndex(where: { $0.user.id == uid }) {
                if let emoji, isValidAssetName(assetName: emoji) && self.users[index].emoji != emoji {
                    self.users[index].emoji = emoji
                }
            } else if let index = self.tempHold.firstIndex(where: { $0.user.id == uid }) {
                if let emoji, isValidAssetName(assetName: emoji) && self.tempHold[index].emoji != emoji {
                    self.tempHold[index].emoji = emoji
                }
            } else if let user = popRoot.randomUsers.first(where: { $0.id == uid }){
                insertUser(new: emojiUser(user: user, emoji: emoji ?? ""))
            } else {
                UserService().fetchSafeUser(withUid: uid) { user in
                    if let user {
                        if sid == storyID {
                            insertUser(new: emojiUser(user: user, emoji: emoji ?? ""))
                        }
                        if !popRoot.randomUsers.contains(where: { $0.id == user.id }) {
                            popRoot.randomUsers.append(user)
                        }
                    }
                }
            }
        }
    }
    func insertUser(new: emojiUser) {
        if showStats && (new.user.id ?? "") != cid {
            if onlyFriends && !following.contains(new.user.id ?? "") {
                tempHold.append(new)
            } else if recentsFirst {
                let arr = Array(uidArray(onlyIncludeFriends: onlyFriends).reversed())
                
                if let index = arr.firstIndex(where: { $0 == (new.user.id ?? "") }) {
                    if users.isEmpty || index == (users.count) {
                        users.append(new)
                    } else if index < users.count {
                        users.insert(new, at: index)
                    } else {
                        users.append(new)
                    }
                }
            } else {
                if new.emoji.isEmpty {
                    users.append(new)
                } else {
                    users.insert(new, at: 0)
                }
            }
        }
    }
    func sortSearch() {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if recentsFirst {
                sortRecent()
            } else {
                sortReactions()
            }
            return
        }
        let query = searchText.lowercased()

        func matchScore(for text: String, query: String) -> Int {
            let textLowercased = text.lowercased()
            let queryLowercased = query.lowercased()

            if textLowercased.contains(queryLowercased) {
                return queryLowercased.count
            } else {
                return 0
            }
        }

        users.sort { user1, user2 in
            let fullname1 = user1.user.fullname
            let username1 = user1.user.username
            let fullname2 = user2.user.fullname
            let username2 = user2.user.username
            let score1 = matchScore(for: fullname1, query: query) + matchScore(for: username1, query: query)
            let score2 = matchScore(for: fullname2, query: query) + matchScore(for: username2, query: query)
            return score1 > score2
        }
    }
    func sortRecent() {
        let uidArray: [String] = uidArray(onlyIncludeFriends: false).reversed()

        var uidIndexMap: [String: Int] = [:]
        for (index, uid) in uidArray.enumerated() {
            uidIndexMap[uid] = index
        }

        self.users.sort { user1, user2 in
            let uid1 = user1.user.id ?? ""
            let uid2 = user2.user.id ?? ""

            let index1 = uidIndexMap[uid1, default: Int.max]
            let index2 = uidIndexMap[uid2, default: Int.max]

            return index1 < index2
        }
    }
    func uidArray(onlyIncludeFriends: Bool) -> [String] {
        var final = [String]()
        
        var toLoop = views
        if let found = popRoot.updatedView.first(where: { $0.0 == storyID })?.3 {
            toLoop = found
        }
        toLoop.forEach { element in
            if let uid = extractUidAndEmoji(from: element)?.0 {
                if onlyIncludeFriends {
                    if following.contains(uid) {
                        final.append(uid)
                    }
                } else {
                    final.append(uid)
                }
            }
        }
        return final
    }
    func sortReactions() {
        users.sort { user1, user2 in
            if !user1.emoji.isEmpty && user2.emoji.isEmpty {
                return true
            }
            if user1.emoji.isEmpty && !user2.emoji.isEmpty {
                return false
            }
            return false
        }
    }
    func friendsOnly() {
        let usersToMove = self.users.filter { user in
            return !following.contains(user.user.id ?? "")
        }

        self.users.removeAll { user in
            return usersToMove.contains(where: { $0.user.id == user.user.id })
        }

        self.tempHold.append(contentsOf: usersToMove)
        
        if recentsFirst {
            sortRecent()
        } else {
            sortReactions()
        }
    }
    func allViewers() {
        self.tempHold.forEach { element in
            if !self.users.contains(where: { $0.user.id == element.user.id }) {
                self.users.append(element)
            }
        }
        self.tempHold = []
        if recentsFirst {
            sortRecent()
        } else {
            sortReactions()
        }
    }
    func openUserFunc(uid: String) {
        withAnimation(.easeInOut(duration: 0.1)){
            showStats = false
        }
        disableDrag = false
        if isMap {
            openUser(uid)
        }
    }
    func openChatFunc(uid: String) {
        withAnimation(.easeInOut(duration: 0.1)){
            showStats = false
        }
        disableDrag = false
        if isMap {
            openChat(uid)
        }
    }
    @ViewBuilder
    func sheetView() -> some View {
        ScrollView {
            LazyVStack(spacing: 25){
                Color.clear.frame(height: 40)
                TextField("", text: $searchText)
                    .focused($focusField, equals: .one)
                    .padding(.horizontal).padding(.vertical, 5)
                    .foregroundStyle(.white).tint(.blue)
                    .submitLabel(.search)
                    .background(.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(content: {
                        if searchText.isEmpty {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search")
                                Spacer()
                            }
                            .foregroundStyle(.white).opacity(0.7)
                            .padding(.horizontal)
                            .onTapGesture {
                                focusField = .one
                            }
                        }
                    })
                    .onChange(of: searchText) { _, _ in
                        sortSearch()
                    }
                if onlyFriends && users.isEmpty && !tempHold.isEmpty {
                    Color.clear.frame(height: 80)
                    VStack(spacing: 10){
                        Text("No friends have viewed yet!")
                            .font(.title2).bold()
                        Text("Views will appear here.")
                            .font(.subheadline).fontWeight(.light)
                    }.foregroundStyle(.white)
                } else if users.isEmpty && !views.isEmpty {
                    LazyVStack {
                        ForEach(0..<15, id: \.self) { _ in
                            HStack(spacing: 12){
                                Circle()
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.gray).opacity(0.6)
                                VStack(alignment: .leading, spacing: 5){
                                    Rectangle()
                                        .frame(width: 70, height: 7)
                                        .foregroundStyle(.gray).opacity(0.6)
                                    Rectangle()
                                        .frame(width: 50, height: 3)
                                        .foregroundStyle(.gray).opacity(0.6)
                                }
                                Spacer()
                            }
                        }
                    }.shimmering()
                } else if !users.isEmpty {
                    ForEach(users) { user in
                        userRow(user: user.user, emoji: user.emoji)
                    }
                } else {
                    Color.clear.frame(height: 80)
                    VStack(spacing: 10){
                        Text("No views yet!")
                            .font(.title2).bold()
                        Text("Views will appear here.")
                            .font(.subheadline).fontWeight(.light)
                    }.foregroundStyle(.white)
                }
                Color.clear.frame(height: 40)
            }
            .padding(.horizontal)
            .background(GeometryReader {
                Color.clear.preference(key: ViewOffsetKey.self,
                                       value: -$0.frame(in: .named("scroll")).origin.y)
            })
            .onPreferenceChange(ViewOffsetKey.self) { value in
                withAnimation(.easeInOut(duration: 0.1)){
                    keyboardGone = value > 80
                }
            }
        }
        .coordinateSpace(name: "scroll")
        .overlay(alignment: .top){
            ZStack {
                HStack(spacing: 6){
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if onlyFriends {
                            allViewers()
                        }
                        withAnimation(.easeInOut(duration: 0.1)){
                            onlyFriends = false
                        }
                    }, label: {
                        Text("All viewers")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.gray.opacity(onlyFriends ? 0.0 : 0.2))
                            .clipShape(Capsule())
                    })
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if !onlyFriends {
                            friendsOnly()
                        }
                        withAnimation(.easeInOut(duration: 0.1)){
                            onlyFriends = true
                        }
                    }, label: {
                        Text("Friends")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.gray.opacity(onlyFriends ? 0.2 : 0.0))
                            .clipShape(Capsule())
                    })
                    Spacer()
                }
                HStack {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if !disableRot {
                            withAnimation(.easeInOut(duration: 4.0)){
                                rotation += 5080.0
                            }
                            disableRot = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                disableRot = false
                            }
                            refreshStoryView()
                        }
                    }, label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.blue)
                            .font(.title2)
                            .rotationEffect(.degrees(rotation))
                    })
                    Spacer()
                }.padding(.horizontal)
                HStack {
                    Spacer()
                    Menu {
                        Button(action: {
                            recentsFirst = false
                            sortReactions()
                        }, label: {
                            Label("Reactions first", systemImage: "heart")
                        })
                        Button(action: {
                            recentsFirst = true
                            sortRecent()
                        }, label: {
                            Label("Recents first", systemImage: "clock")
                        })
                        Divider()
                        Text("Choose the order for the list of viewers.")
                            .font(.caption)
                    } label: {
                        HStack(spacing: 2){
                            if recentsFirst {
                                Image(systemName: "clock")
                            } else {
                                Image(systemName: "heart")
                            }
                            Image(systemName: "chevron.down")
                        }
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.gray.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }.padding(.trailing, 15)
            }
            .padding(.top, 15).padding(.bottom, 10)
            .background {
                ZStack {
                    Color.white.opacity(keyboardGone ? 0.3 : 1.0)
                    TransparentBlurView(removeAllFilters: true)
                        .blur(radius: 10, opaque: true)
                        .background(.black.opacity(keyboardGone ? 0.5 : 0.9))
                }
            }
            .gesture(
                DragGesture()
                    .onEnded({ val in
                        if val.translation.height > 20 || val.velocity.height > 100 {
                            withAnimation(.easeInOut(duration: 0.2)){
                                showStats = false
                            }
                            disableDrag = false
                        }
                    })
            )
        }
    }
    @ViewBuilder
    func userRow(user: User, emoji: String) -> some View {
        HStack(spacing: 12){
            ZStack {
                personLetterView(size: 40, letter: String(user.fullname.first ?? Character("M")))
                if let image = user.profileImageUrl {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .shadow(color: .gray, radius: 2)
                }
            }
            .onTapGesture {
                if !disableNav && canOpenProfile {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let uid = user.id {
                        openUserFunc(uid: uid)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 3){
                HStack(spacing: 15){
                    Text(user.fullname)
                        .font(.title3).bold()
                        .foregroundStyle(.white)
                        .onTapGesture {
                            if !disableNav && canOpenProfile {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if let uid = user.id {
                                    openUserFunc(uid: uid)
                                }
                            }
                        }
                    Menu {
                        Button(role: .destructive) {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            if let uid = user.id {
                                UserService().blockUser(uid: uid)
                                popRoot.alertImage = "checkmark"
                                popRoot.alertReason = "\(user.fullname) blocked"
                                withAnimation(.easeInOut(duration: 0.2)){
                                    popRoot.showAlert = true
                                }
                            }
                        } label: {
                            Label("Block User", systemImage: "xmark")
                        }
                        if !disableNav && canOpenChat {
                            Divider()
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if let uid = user.id {
                                    openChatFunc(uid: uid)
                                }
                            }, label: {
                                Label("Message", systemImage: "message.fill")
                            })
                        }
                    } label: {
                        ZStack {
                            Rectangle()
                                .frame(width: 35, height: 12)
                                .foregroundStyle(.gray).opacity(0.001)
                            Image(systemName: "ellipsis")
                                .font(.headline).foregroundStyle(.blue)
                        }
                    }
                }
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .onTapGesture {
                        if !disableNav && canOpenProfile {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if let uid = user.id {
                                openUserFunc(uid: uid)
                            }
                        }
                    }
            }
            Spacer()
            Text(getEmojiFromAsset(assetName: emoji))
                .font(.system(size: 30))
        }
    }
    @ViewBuilder
    func bottomOptions() -> some View {
        HStack(spacing: 20){
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.easeInOut(duration: 0.15)){
                    showStats = true
                }
                disableDrag = true
            }, label: {
                VStack(spacing: 3){
                    if viewers.count == 3 {
                        ZStack {
                            KFImage(URL(string: viewers[0]))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 25, height: 25)
                                .clipShape(Circle())
                                .shadow(color: .gray, radius: 1)
                                .offset(x: -18.5)
                            KFImage(URL(string: viewers[1]))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 25, height: 25)
                                .clipShape(Circle())
                                .padding(2)
                                .background(.black)
                                .clipShape(Circle())

                            KFImage(URL(string: viewers[2]))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 25, height: 25)
                                .clipShape(Circle())
                                .padding(2)
                                .background(.black)
                                .clipShape(Circle())
                                .offset(x: 18.5)
                        }.frame(height: 25)
                    } else {
                        let updated = popRoot.updatedView.first(where: { $0.0 == storyID })
                        let viewsCount = updated?.1 ?? views.count
                        let reactions = updated?.2 ?? countViewsContainsReaction(views: views)
                        
                        HStack(spacing: 14){
                            HStack(spacing: 2){
                                Image(systemName: "eye")
                                    .font(.system(size: 16))
                                Text("\(viewsCount)")
                                    .fontWeight(.light)
                                    .font(.subheadline)
                            }
                            HStack(spacing: 2){
                                Image(systemName: "heart")
                                    .font(.system(size: 16))
                                Text("\(reactions)")
                                    .fontWeight(.light)
                                    .font(.subheadline)
                            }
                        }
                        .foregroundStyle(.white)
                    }
                    Text("Activity")
                        .font(.system(size: 10))
                }.foregroundStyle(.white)
            }).padding(.leading, (viewers.count == 3) ? 15 : 0)
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                stopVideo(true)
                if externalUpload {
                    upload()
                } else {
                    if isVideo {
                        if let url = URL(string: contentURL) {
                            initialContent = uploadContent(isImage: false, videoURL: url)
                            showNewTweetView = true
                        }
                    } else if !contentURL.isEmpty {
                        initialContent = uploadContent(isImage: true, imageURL: contentURL)
                        showNewTweetView = true
                    }
                }
            }, label: {
                VStack(spacing: 3){
                    Image(systemName: "plus")
                        .font(.system(size: 23))
                        .frame(height: 20)
                    Text("Create")
                        .font(.system(size: 10))
                }.foregroundStyle(.white)
            })
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                sendLink = "https://hustle.page/story/\(storyID)/"
                showForward = true
            }, label: {
                VStack(spacing: 3){
                    Image(systemName: "paperplane")
                        .font(.system(size: 18))
                        .frame(height: 20)
                        .rotationEffect(.degrees(45.0))
                    Text("Share")
                        .font(.system(size: 10))
                }.foregroundStyle(.white)
            })
            Menu {
                Button(role: .destructive) {
                    GlobeService().deleteStory(storyID: storyID)
                    popRoot.alertImage = "checkmark"
                    popRoot.alertReason = "Story Deleted"
                    withAnimation(.easeInOut(duration: 0.2)){
                        popRoot.showAlert = true
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Divider()
                Button(action: {
                    if !contentURL.isEmpty {
                        let newID = UUID().uuidString
                        var newLat: CGFloat?
                        var newLong: CGFloat?
                        if let lat {
                            newLat = CGFloat(lat)
                        }
                        if let long {
                            newLong = CGFloat(long)
                        }
                        if isVideo {
                            if let url = URL(string: contentURL) {
                                UserService().saveMemories(docID: newID, imageURL: nil, videoURL: contentURL, lat: newLat, long: newLong)
                                let new = animatableMemory(isImage: false, player: AVPlayer(url: url), memory: Memory(id: newID, video: contentURL, lat: newLat, long: newLong, createdAt: Timestamp()))
                                if let idx = popRoot.allMemories.firstIndex(where: { $0.date == "Recents" }) {
                                    popRoot.allMemories[idx].allMemories.insert(new, at: 0)
                                } else {
                                    let newMonth = MemoryMonths(date: "Recents", allMemories: [new])
                                    popRoot.allMemories.insert(newMonth, at: 0)
                                }
                            }
                        } else {
                            UserService().saveMemories(docID: newID, imageURL: contentURL, videoURL: nil, lat: newLat, long: newLong)
                            let new = animatableMemory(isImage: true, memory: Memory(id: newID, image: contentURL, lat: newLat, long: newLong, createdAt: Timestamp()))
                            if let idx = popRoot.allMemories.firstIndex(where: { $0.date == "Recents" }) {
                                popRoot.allMemories[idx].allMemories.insert(new, at: 0)
                            } else {
                                let newMonth = MemoryMonths(date: "Recents", allMemories: [new])
                                popRoot.allMemories.insert(newMonth, at: 0)
                            }
                        }
                        popRoot.alertReason = "Memory Saved"
                        popRoot.alertImage = "checkmark"
                        withAnimation(.easeInOut(duration: 0.2)){
                            popRoot.showAlert = true
                        }
                    }
                }, label: {
                    Label("Save to Memories", systemImage: "square.and.arrow.down")
                })
                Button(action: {
                    if let url = URL(string: contentURL) {
                        if isVideo {
                            downloadVideoFromURL(url)
                        } else {
                            downloadAndSaveImage(url: contentURL)
                        }
                    }
                    popRoot.alertReason = "Image Saved to Photos."
                    popRoot.alertImage = "checkmark"
                    withAnimation(.easeInOut(duration: 0.2)){
                        popRoot.showAlert = true
                    }
                }, label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                })
                Button(action: {
                    UIPasteboard.general.string = "https://hustle.page/story/\(storyID)/"
                    popRoot.alertReason = "Story link copied."
                    popRoot.alertImage = "link"
                    withAnimation(.easeInOut(duration: 0.2)){
                        popRoot.showAlert = true
                    }
                }, label: {
                    Label("Copy Link", systemImage: "link")
                })
            } label: {
                VStack(spacing: 3){
                    Image(systemName: "ellipsis")
                        .font(.system(size: 19))
                        .frame(height: 20)
                    Text("More")
                        .font(.system(size: 10))
                }.foregroundStyle(.white)
            }
        }.padding(.horizontal, 18)
    }
}

func countViewsContainsReaction(views: [String]) -> Int {
    return views.filter { $0.contains("/") }.count
}
