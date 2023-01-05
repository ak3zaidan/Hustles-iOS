import SwiftUI
import Kingfisher

struct MainStoryBottom: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var profileModel: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @State var showLoader: Bool = false
    @State var getOnChange: Bool = false
    
    @Binding var storiesUidOrder: [String]
    @Binding var isMainExpanded: Bool
    @Binding var showCamera: Bool
    @Binding var mutedStories: [String]
    @Binding var showProfile: Bool
    @Binding var profileUID: String
    @Binding var refreshStories: Bool
    @Binding var noneFound: Bool
    @Binding var selection: String
    @Binding var tempMid: String
    @Binding var storiesUnseen: [(String, String, String, String)]
    let animation: Namespace.ID

    var body: some View {
        HStack(spacing: 0){
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 8){
                        Color.clear.frame(width: 1).id("start")
                        profilePart()
                            .id(auth.currentUser?.id ?? "NAN")
                            .padding(.trailing, storiesUidOrder.isEmpty ? 0 : 8)
                        
                        if !storiesUidOrder.isEmpty {
                            ForEach(storiesUidOrder, id: \.self) { uid in
                                if let data = profileModel.users.first(where: { $0.user.id == uid }) {
                                    userStory(user: data.user)
                                        .id(uid)
                                        .padding(.trailing, 8)
                                        .transition(.move(edge: .trailing))
                                        .onTapGesture {
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            if let uid = data.user.id {
                                                showStories(uid: uid)
                                            }
                                        }
                                }
                            }
                        } else if !noneFound {
                            HStack(spacing: 9){
                                ForEach(0..<10, id: \.self) { _ in
                                    VStack(spacing: 10){
                                        ZStack {
                                            StoryRingView(size: 84, active: false, strokeSize: 2.6)
                                            Circle().foregroundStyle(.gray).opacity(0.3).frame(width: 73, height: 73)
                                        }
                                        Text(".").font(.caption)
                                    }.padding(.trailing, 8)
                                }
                            }
                            .padding(.leading, 8).frame(height: 126).shimmering()
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            NavigationLink {
                                DiscoverPeople().enableFullSwipePop(true)
                            } label: {
                                VStack(spacing: 10){
                                    ZStack {
                                        StoryRingView(size: 84, active: false, strokeSize: 2.6)
                                        Circle().foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).opacity(0.7).frame(width: 73, height: 73)
                                        Image(systemName: "sparkle.magnifyingglass")
                                            .font(.title3).foregroundStyle(.white)
                                    }
                                    Text("Discover").font(.caption)
                                }
                            }.padding(.leading, 8).frame(height: 126).transition(.scale.combined(with: .opacity))
                        }
                        
                        Color.clear.frame(width: 1)
                    }
                }
                .scrollIndicators(.hidden)
                .onChange(of: refreshStories) { _, _ in
                    withAnimation(.easeInOut(duration: 0.15)){
                        proxy.scrollTo("start")
                    }
                    if popRoot.timeSinceLastStoryUpdate == nil {
                        if let user = auth.currentUser, let uid = user.id {
                            setUp(following: user.following, uid: uid)
                        }
                    } else if let dateVal = popRoot.timeSinceLastStoryUpdate, isDateAtLeastOneMinuteOld(date: dateVal) {
                        if let user = auth.currentUser, let uid = user.id {
                            setUp(following: user.following, uid: uid)
                        }
                    } else {
                        orderStoriesSoft()
                    }
                }
                .onChange(of: selection) { _, _ in
                    withAnimation(.easeInOut(duration: 0.15)){
                        proxy.scrollTo(selection)
                    }
                }
            }
            .frame(height: 126)
        }
        .onAppear(perform: {
            if let user = auth.currentUser, let uid = user.id {
                setUp(following: user.following, uid: uid)
            } else {
                getOnChange = true
            }
        })
        .onChange(of: auth.currentUser?.id) { _, _ in
            if let user = auth.currentUser, let uid = user.id, getOnChange {
                getOnChange = false
                setUp(following: user.following, uid: uid)
            }
        }
    }
    func setUp(following: [String], uid: String) {
        popRoot.timeSinceLastStoryUpdate = Date()
        orderStoriesSoft()

        storiesUidOrder.forEach { uid in
            if let user = profileModel.users.first(where: { $0.user.id == uid })?.user {
                profileModel.updateStoriesUser(user: user)
            }
        }
        
        var toFetch = following
        toFetch.removeAll { storiesUidOrder.contains($0) }
        toFetch.removeAll { mutedStories.contains($0) }
        toFetch.removeAll(where: { $0 == auth.currentUser?.id ?? "" })
        toFetch = Array(Set(toFetch))
        toFetch = Array(toFetch.shuffled().prefix(300))
        
        if toFetch.isEmpty && storiesUidOrder.isEmpty {
            withAnimation(.easeInOut(duration: 0.15)){
                noneFound = true
            }
        }
        
        if let user = auth.currentUser {
            profileModel.updateStoriesUser(user: user)
        }

        let myUID = auth.currentUser?.id ?? ""
        toFetch.forEach { uid in
            let user = profileModel.users.first(where: { $0.user.id == uid })?.user
            profileModel.getUpdatedStoriesUser(user: user, uid: uid) { stories in
                if !stories.isEmpty {
                    withAnimation(.easeInOut(duration: 0.15)){
                        if storiesLeftToView(otherUID: uid) {
                            self.storiesUidOrder.insert(uid, at: 0)
                        } else {
                            self.storiesUidOrder.append(uid)
                        }
                        noneFound = false
                    }
                    if storiesUnseen.count < 5 {
                        for i in 0..<stories.count {
                            if let image = stories[i].imageURL, let sid = stories[i].id, !image.isEmpty {
                                if !(stories[i].views ?? []).contains(where: { $0.contains(myUID) }) {
                                    let photo = user?.profileImageUrl ?? String((user?.fullname ?? "").first ?? Character("-"))
                                    storiesUnseen.append((image, sid, uid, photo))
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    func orderStoriesSoft() {
        let sortedStories = storiesUidOrder.sorted { uid1, uid2 in
            let uid1HasStoriesLeft = storiesLeftToView(otherUID: uid1)
            let uid2HasStoriesLeft = storiesLeftToView(otherUID: uid2)
            
            if uid1HasStoriesLeft == uid2HasStoriesLeft {
                return false
            }
            return uid1HasStoriesLeft && !uid2HasStoriesLeft
        }
        withAnimation(.easeInOut(duration: 0.15)) {
            self.storiesUidOrder = sortedStories
        }
    }
    func userStory(user: User) -> some View {
        VStack(spacing: 10){
            ZStack {
                StoryRingView(size: 84, active: storiesLeftToView(otherUID: user.id), strokeSize: 2.6)
 
                let mid = (user.id ?? "")
                let size = isMainExpanded && selection == mid ? 200.0 : 73
                
                GeometryReader { _ in
                    ZStack {
                        Circle()
                            .foregroundStyle(.gray).opacity(0.3)
                            .frame(width: size, height: size)
                        
                        if let first = user.fullname.first {
                            Text(String(first).uppercased()).font(.title).bold().foregroundStyle(.white)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.headline).foregroundStyle(.white)
                        }

                        if let image = user.profileImageUrl {
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .scaledToFill()
                                .clipShape(Circle())
                                .frame(width: size, height: size)
                        }
                    }.opacity(isMainExpanded && selection == mid ? 0.0 : 1.0)
                }
                .matchedGeometryEffect(id: mid, in: animation, anchor: .top)
                .frame(width: 73, height: 73)
            }
            Text(user.username).font(.caption).lineLimit(1)
                .truncationMode(.tail).frame(maxWidth: 80)
        }
        .padding(.top, 2).padding(.horizontal, 2)
        .contextMenu {
            Button(role: .destructive, action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let id = user.id {
                    mutedStories.append(id)
                    withAnimation(.easeInOut(duration: 0.15)){
                        storiesUidOrder.removeAll(where: { $0 == id })
                        if storiesUidOrder.isEmpty {
                            noneFound = true
                        }
                    }
                }
            }, label: {
                Label(
                    title: { Text("Mute") },
                    icon: { Image(systemName: "xmark.shield") }
                )
            })
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let id = user.id {
                    profileUID = id
                    showProfile = true
                }
            }, label: {
                Label(
                    title: { Text("View Profile") },
                    icon: { Image(systemName: "eye") }
                )
            })
        }
    }
    func profilePart() -> some View {
        VStack(spacing: 10){
            ZStack {
                let hasStory = hasStories()
                
                if hasStory {
                    StoryRingView(size: 84, active: false, strokeSize: 2.6)
                        .transition(.scale)
                } else if showLoader {
                    LottieView(loopMode: .loop, name: "loadingStory")
                        .scaleEffect(0.133)
                        .frame(width: 76, height: 76)
                        .transition(.scale)
                }
                
                let mid = (auth.currentUser?.id ?? "")
                let size = isMainExpanded && selection == mid ? 200.0 : 73
                
                GeometryReader { _ in
                    ZStack {
                        Circle()
                            .foregroundStyle(.gray).opacity(0.3)
                            .frame(width: size, height: size)
                        
                        Image(systemName: "plus")

                        if let image = auth.currentUser?.profileImageUrl {
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .scaledToFill()
                                .clipShape(Circle())
                                .frame(width: size, height: size)
                                .shadow(color: hasStory ? .clear : .gray, radius: 1)
                                .overlay(alignment: .bottomTrailing){
                                    Button(action: {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showCamera = true
                                    }, label: {
                                        ZStack {
                                            Circle()
                                                .foregroundStyle(colorScheme == .dark ? .black : .white)
                                                .frame(width: 29, height: 29)
                                            Circle()
                                                .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                                                .frame(width: 26, height: 26)
                                            
                                            Text("+")
                                                .bold().foregroundStyle(.white).font(.title3)
                                                .offset(y: -1)
                                        }
                                    }).offset(x: 3, y: 3)
                                }
                        }
                    }.opacity(isMainExpanded && selection == mid ? 0.0 : 1.0)
                }
                .matchedGeometryEffect(id: mid, in: animation, anchor: .top)
                .frame(width: 73, height: 73)
            }
            Text("Your Story").font(.caption)
        }
        .padding(.top, 2).padding(.horizontal, 2)
        .contextMenu {
            Button(action: {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showCamera = true
            }, label: {
                Label(
                    title: { Text("Add Story") },
                    icon: { Image(systemName: "plus") }
                )
            })
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            if let user = auth.currentUser, let uid = user.id {
                if let profile = profileModel.users.first(where: { $0.user.id == uid }) {
                    if let stories = profile.stories, !stories.isEmpty {
                        showStories(uid: uid)
                    } else if profile.lastUpdatedStories == nil {
                        withAnimation(.easeInOut(duration: 0.1)){ showLoader = true }
                        profileModel.getUpdatedStoriesUser(user: user, uid: uid) { stories in
                            withAnimation(.easeInOut(duration: 0.1)){ showLoader = false }
                            if stories.isEmpty {
                                showCamera = true
                            } else {
                                showStories(uid: uid)
                            }
                        }
                    } else {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showCamera = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.1)){ showLoader = true }
                    profileModel.getUpdatedStoriesUser(user: user, uid: uid) { stories in
                        withAnimation(.easeInOut(duration: 0.1)){ showLoader = false }
                        if stories.isEmpty {
                            showCamera = true
                        } else {
                            showStories(uid: uid)
                        }
                    }
                }
            }
        }
    }
    func showStories(uid: String) {
        withAnimation(.easeInOut(duration: 0.15)){
            selection = uid
        }
        
        if let idx = profileModel.users.firstIndex(where: { $0.user.id == auth.currentUser?.id }) {
            profileModel.users[idx].storyIndex = 0
        }
        
        storiesUidOrder.forEach { uid in
            if let idx = profileModel.users.firstIndex(where: { $0.user.id == uid }) {
                var didSet = false
                
                let stories = profileModel.users[idx].stories ?? []
                
                for i in 0..<stories.count {
                    if let sid = stories[i].id {
                        if !messageModel.viewedStories.contains(where: { $0.0 == sid }) && !(stories[i].views ?? []).contains(where: { $0.contains(uid) }) {
                            profileModel.users[idx].storyIndex = i
                            didSet = true
                            break
                        }
                    }
                }
                
                if !didSet {
                    profileModel.users[idx].storyIndex = 0
                }
            }
        }

        tempMid = uid
        withAnimation(.easeInOut(duration: 0.15)){
            popRoot.hideTabBar = true
            isMainExpanded = true
        }
    }
    func hasStories() -> Bool {
        if let uid = auth.currentUser?.id {
            if let stories = profileModel.users.first(where: { $0.user.id == uid })?.stories {
                return !stories.isEmpty
            }
        }
        return false
    }
    func storiesLeftToView(otherUID: String?) -> Bool {
        if let uid = auth.currentUser?.id, let otherUID {
            if otherUID == uid {
                return false
            }
            if let stories = profileModel.users.first(where: { $0.user.id == otherUID })?.stories {
                
                for i in 0..<stories.count {
                    if let sid = stories[i].id {
                        if !messageModel.viewedStories.contains(where: { $0.0 == sid }) && !(stories[i].views ?? []).contains(where: { $0.contains(uid) }) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
}
