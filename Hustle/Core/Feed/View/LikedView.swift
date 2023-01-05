import SwiftUI
import Kingfisher

struct LikedView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var feedModel: FeedViewModel
    @FocusState private var focusField: FocusedField?
    @Environment(\.colorScheme) var colorSc
    @Environment(\.presentationMode) private var presentationMode
    @Namespace private var animation
    @State var search = ""
    @State var isExpanded: Bool = false
    @State var allUsers = [User]()
    @State var storyUID = ""
    @State var showStoryChat: Bool = false
    @State var showStoryProfile: Bool = false
    
    @State var likes: [String]
    let tid: String
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15){
                Color.clear.frame(height: 85)
                searchBar().padding(.horizontal)
                if likes.isEmpty {
                    Color.clear.frame(height: 80)
                    VStack(spacing: 10){
                        Text("No friends have liked yet!")
                            .font(.title2).bold()
                        Text("Likes will appear here.")
                            .font(.subheadline).fontWeight(.light)
                    }.foregroundStyle(.white)
                } else if allUsers.isEmpty {
                    VStack {
                        ForEach(0..<20, id: \.self) { _ in
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
                } else {
                    Color.clear.frame(height: 5)
                    ForEach(allUsers) { user in
                        if let uid = user.id {
                            userRow(user: user, uid: uid)
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .enableFullSwipePop(true)
        .refreshable {
            refresh()
        }
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .top, content: {
            ZStack {
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            ZStack {
                                Rectangle()
                                    .frame(width: 45, height: 30)
                                    .foregroundStyle(.gray).opacity(0.001)
                                Image(systemName: "chevron.left").font(.title3)
                                    .foregroundStyle(colorSc == .dark ? .white : .black)
                            }
                        }
                        Spacer()
                    }
                }.padding(.bottom, 10)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Likes").font(.title3).bold()
                        Spacer()
                    }
                }.padding(.bottom, 10)
            }
            .frame(height: 95)
            .background(content: {
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 14, opaque: true)
                    .background(colorSc == .dark ? .black.opacity(0.8) : .white.opacity(0.8))
            })
            .ignoresSafeArea()
        })
        .onAppear(perform: {
            getData()
        })
        .navigationDestination(isPresented: $showStoryProfile) {
            ProfileView(showSettings: false, showMessaging: true, uid: storyUID, photo: "", user: nil, expand: false, isMain: false).enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $showStoryChat) {
            MessagesView(exception: false, user: nil, uid: storyUID, tabException: false, canCall: true)
                .enableFullSwipePop(true)
        }
        .overlay(content: {
            if isExpanded {
                MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: viewModel.mid, isHome: true, canOpenChat: true, canOpenProfile: true, openChat: { uid in
                    storyUID = uid
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
                        showStoryChat = true
                    }
                }, openProfile: { uid in
                    storyUID = uid
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
                        showStoryProfile = true
                    }
                })
                .transition(.scale)
            }
        })
        .ignoresSafeArea()
    }
    func getData() {
        let tempLikes = Array(Set(likes))
        
        let filteredUsers = allUsers.filter { user in
            tempLikes.contains(user.id ?? "")
        }
        self.allUsers = filteredUsers
        
        tempLikes.forEach { uid in
            if !self.allUsers.contains(where: { $0.id == uid }) {
                if let user = viewModel.users.first(where: { $0.user.id == uid })?.user {
                    withAnimation(.easeInOut(duration: 0.15)){
                        self.allUsers.append(user)
                    }
                } else {
                    UserService().fetchSafeUser(withUid: uid) { user_op in
                        if !self.allUsers.contains(where: { $0.id == uid }) {
                            if let new_user = user_op {
                                withAnimation(.easeInOut(duration: 0.15)){
                                    self.allUsers.append(new_user)
                                }
                                if !viewModel.users.contains(where: { $0.user.id == uid }) {
                                    viewModel.users.append(Profile(user: new_user))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    func refresh() {
        let date = feedModel.refreshedHustles[tid]
            
        if date == nil || isDateAtLeastOneMinuteOld(date: date ?? Date()) {
            TweetService().fetchLikedTweets(tweetID: tid) { hustle in
                if let hustle {
                    if let updatedLikes = hustle.likes {
                        self.likes = updatedLikes
                        getData()
                    }
                    if let idx = feedModel.followers.firstIndex(where: { $0.id == tid }) {
                        feedModel.followers[idx] = hustle
                    }
                    if let idx = feedModel.new.firstIndex(where: { $0.id == tid }) {
                        feedModel.new[idx] = hustle
                    }
                    if let idx = viewModel.users.firstIndex(where: { $0.user.id == auth.currentUser?.id }), let idx2 = viewModel.users[idx].tweets?.firstIndex(where: { $0.id == tid }) {
                        viewModel.users[idx].tweets?[idx2] = hustle
                    }
                }
            }
        }
    }
    func userRow(user: User, uid: String) -> some View {
        HStack {
            ZStack {
                if hasStories(uid: uid) {
                    StoryRingView(size: 55.0, active: storiesLeftToView(otherUID: uid), strokeSize: 1.8)
                        .scaleEffect(1.21)
                    
                    let mid = uid + "UpStory"
                    let size = isExpanded && viewModel.mid == mid ? 200.0 : 55.0
                    GeometryReader { _ in
                        ZStack {
                            personLetterView(size: size, letter: String(user.fullname.first ?? Character("M")))
                            if let image = user.profileImageUrl {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .scaledToFill()
                                    .clipShape(Circle())
                                    .frame(width: size, height: size)
                                    .shadow(radius: 1)
                            }
                        }.opacity(isExpanded && viewModel.mid == mid ? 0.0 : 1.0)
                    }
                    .matchedGeometryEffect(id: mid, in: animation, anchor: .topLeading)
                    .frame(width: 55.0, height: 55.0)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        setupStory(uid: uid)
                        viewModel.mid = mid
                        withAnimation(.easeInOut(duration: 0.15)){
                            isExpanded = true
                        }
                    }
                } else {
                    NavigationLink {
                        ProfileView(showSettings: false, showMessaging: false, uid: uid, photo: "", user: user, expand: false, isMain: false).enableFullSwipePop(true)
                    } label: {
                        ZStack {
                            personLetterView(size: 55, letter: String(user.fullname.first ?? Character("M")))
                            if let image = user.profileImageUrl {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .scaledToFill()
                                    .clipShape(Circle())
                                    .frame(width: 55, height:55)
                                    .shadow(radius: 1)
                            }
                        }
                    }
                }
            }
            NavigationLink {
                ProfileView(showSettings: false, showMessaging: false, uid: uid, photo: "", user: user, expand: false, isMain: false).enableFullSwipePop(true)
            } label: {
                VStack(alignment: .leading){
                    Text(user.fullname).bold()
                        .font(.subheadline)
                        .foregroundStyle(colorSc == .dark ? .white : .black)
                    Text("@\(user.username)")
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
                }
            }.padding(.leading, 8)
            Spacer()
            if uid != auth.currentUser?.id {
                Button(action: {
                    if let following = auth.currentUser?.following {
                        if following.contains(uid){
                            viewModel.unfollow(withUid: uid)
                            auth.currentUser?.following.removeAll(where: { $0 == uid })
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        } else {
                            viewModel.follow(withUid: uid)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            auth.currentUser?.following.append(uid)
                            if !viewModel.startedFollowing.contains(uid) {
                                viewModel.startedFollowing.append(uid)
                                if let myUID = auth.currentUser?.id, let name = auth.currentUser?.fullname {
                                    viewModel.sendNotif(taggerName: name, taggerUID: myUID, taggedUID: uid)
                                }
                            }
                        }
                    }
                }, label: {
                    ZStack {
                        let following = auth.currentUser?.following ?? []
                        
                        if following.contains(uid) {
                            RoundedRectangle(cornerRadius: 8)
                                .frame(width: 90, height: 28)
                                .foregroundStyle(.gray).opacity(0.3)
                            Text("Following").font(.subheadline).bold()
                                .foregroundStyle(.white)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .frame(width: 90, height: 28)
                                .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                            Text("Follow").font(.subheadline).bold()
                                .foregroundStyle(.white)
                        }
                    }
                })
            }
        }.padding(.horizontal)
    }
    func hasStories(uid: String) -> Bool {
        return !(viewModel.users.first(where: { $0.user.id == uid })?.stories ?? []).isEmpty
    }
    func setupStory(uid: String) {
        if let stories = viewModel.users.first(where: { $0.user.id == uid })?.stories {
            viewModel.selectedStories = stories
        }
    }
    func storiesLeftToView(otherUID: String) -> Bool {
        if let uid = auth.currentUser?.id {
            if otherUID == uid {
                return false
            }
            if let stories = viewModel.users.first(where: { $0.user.id == otherUID })?.stories {
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
    func searchBar() -> some View {
        TextField("Search", text: $search)
            .tint(.blue)
            .autocorrectionDisabled(true)
            .padding(8)
            .padding(.horizontal, 24)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .focused($focusField, equals: .one)
            .onSubmit {
                focusField = .two
            }
            .onChange(of: search) { _, _ in
                sortSearch()
            }
            .overlay (
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    Spacer()
                    if !search.isEmpty {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            search = ""
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
    }
    func sortSearch() {
        let query = search.lowercased()

        func matchScore(for text: String, query: String) -> Int {
            let textLowercased = text.lowercased()
            let queryLowercased = query.lowercased()

            if textLowercased.contains(queryLowercased) {
                return queryLowercased.count
            } else {
                return 0
            }
        }

        allUsers.sort { user1, user2 in
            let fullname1 = user1.fullname
            let username1 = user1.username
            let fullname2 = user2.fullname
            let username2 = user2.username
            let score1 = matchScore(for: fullname1, query: query) + matchScore(for: username1, query: query)
            let score2 = matchScore(for: fullname2, query: query) + matchScore(for: username2, query: query)
            return score1 > score2
        }
    }
}
