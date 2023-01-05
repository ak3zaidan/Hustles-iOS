import SwiftUI
import Kingfisher
import Contacts
import MessageUI
import Firebase

struct DiscoverPeople: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var feedModel: FeedViewModel
    
    @State private var tabs: [TabModel2] = [
        .init(id: "Suggested"),
        .init(id: "Contacts")
    ]
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var animation
    @State var isExpanded: Bool = false
    @State var storyUID = ""
    @State var showStoryChat: Bool = false
    @State var showStoryProfile: Bool = false
    @State private var activeTab: String = "Suggested"
    @State private var tabBarScrollState: String?
    @State private var progress: CGFloat = .zero
    @State private var isDragging: Bool = false
    @State private var delayTask: DispatchWorkItem?
    @State private var recipients: [String] = []
    @State private var message = "Download Hustles, the leading social media and entrepreneurship platform. https://apps.apple.com/us/app/hustles/id6452946210"
    @State private var isShowingMessages = false
    
    var body: some View {
        VStack(spacing: 0){
            ZStack {
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
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Text("Discover People").font(.title3).bold()
                    Spacer()
                }
            }.padding(.top, top_Inset()).padding(.bottom, 10)
            
            CustomTabBar()
            
            GeometryReader {
                let size = $0.size
                TabView(selection: $activeTab) {
                    ScrollView {
                        LazyVStack(spacing: 20){
                            Color.clear.frame(height: 5)
                            if feedModel.suggestedFollow.isEmpty {
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
                            } else {
                                ForEach(feedModel.suggestedFollow) { user in
                                    if user.id != auth.currentUser?.id {
                                        singleUser(user: user)
                                    }
                                }
                            }
                            Color.clear.frame(height: 85)
                        }
                    }
                    .scrollIndicators(.hidden)
                    .tag("Suggested")
                    .frame(width: size.width, height: size.height)
                    .rect { tabProgress("Suggested", rect: $0, size: size) }
                    
                    ScrollView {
                        LazyVStack(spacing: 20){
                            Color.clear.frame(height: 5)
                            
                            if !viewModel.contactFriends.isEmpty {
                                LazyVStack(spacing: 10){
                                    HStack {
                                        Text("Contacts on Hustles")
                                            .font(.headline).bold()
                                        Spacer()
                                    }.padding(.leading).padding(.top, 10)
                                    
                                    ForEach(viewModel.contactFriends){ contact in
                                        singleUser(user: contact.user)
                                    }
                                }
                            }
                            LazyVStack(spacing: 10){
                                HStack {
                                    Text("Invite to Hustles")
                                        .font(.headline).bold()
                                    Spacer()
                                }.padding(.leading).padding(.top, 10)
                                
                                if viewModel.allContacts.isEmpty {
                                    Button(action: {
                                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }, label: {
                                        VStack(spacing: 4){
                                            HStack {
                                                Text("Enable Hustles to access Contacts.")
                                                    .font(.subheadline).fontWeight(.semibold)
                                                Spacer()
                                            }.padding(.bottom, 5)
                                            HStack {
                                                Text("We need this data to find your friends that are active on Hustles. This data is not saved on our servers.")
                                                    .foregroundStyle(.gray).font(.caption)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                            }
                                        }
                                        .padding(8)
                                        .overlay(content: {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(.blue, lineWidth: 1.0)
                                        })
                                        .padding(.horizontal)
                                    })
                                } else {
                                    ForEach(viewModel.allContacts, id: \.self){ contact in
                                        if !contact.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            contactUser(name: contact.name, number: contact.phoneNumber, image: contact.getImage())
                                        }
                                    }
                                }
                            }
                            Color.clear.frame(height: 85)
                        }
                    }
                    .scrollIndicators(.hidden)
                    .tag("Contacts")
                    .frame(width: size.width, height: size.height)
                    .rect { tabProgress("Contacts", rect: $0, size: size) }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: {
            fetchContacts { final in
                withAnimation(.easeInOut(duration: 0.2)){
                    self.viewModel.allContacts = final
                }
                self.viewModel.getContacts()
            }
        })
        .navigationDestination(isPresented: $showStoryProfile) {
            ProfileView(showSettings: false, showMessaging: true, uid: storyUID, photo: "", user: nil, expand: false, isMain: false).enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $showStoryChat) {
            MessagesView(exception: false, user: nil, uid: storyUID, tabException: false, canCall: true)
                .enableFullSwipePop(true)
        }
        .sheet(isPresented: self.$isShowingMessages) {
            MessageUIView(recipients: $recipients, body: $message, completion: handleCompletion(_:))
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
    func handleCompletion(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            break
        case .sent:
            if let first = recipients.first {
                viewModel.invited.append(first)
                auth.currentUser?.elo += 15
                if let curr = auth.currentUser {
                    if let x = viewModel.users.firstIndex(where: { $0.user.id == curr.id }) {
                        viewModel.users[x].user.elo += 15
                    }
                }
                UserService().editElo(withUid: nil, withAmount: 15) { }
            }
            break
        case .failed:
            break
        @unknown default:
            break
        }
    }
    func tabProgress(_ tab: String, rect: CGRect, size: CGSize) {
        if let index = tabs.firstIndex(where: { $0.id == activeTab }), activeTab == tab, !isDragging {
            let offsetX = rect.minX - (size.width * CGFloat(index))
            progress = -offsetX / size.width
        }
    }
    func singleUser(user: User) -> some View {
        HStack {
            let uid = user.id ?? ""
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
                VStack(alignment: .leading, spacing: 6){
                    Text(user.fullname).bold()
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
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
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)){
                    viewModel.contactFriends.removeAll(where: { $0.user.id == user.id })
                    feedModel.suggestedFollow.removeAll(where: { $0.id == user.id })
                }
            }, label: {
                Image(systemName: "xmark").foregroundStyle(.gray)
                    .font(.caption)
            })
        }.padding(.horizontal)
    }
    func contactUser(name: String, number: String, image: Image?) -> some View {
        HStack {
            ZStack {
                personLetterView(size: 55, letter: String(name.first ?? Character("M")))
                
                if let image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 55, height:55)
                        .shadow(radius: 1)
                }
            }
            VStack(alignment: .leading, spacing: 6){
                Text(name).bold()
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                Text(number)
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
            }.padding(.leading, 8)
            Spacer()
            Button {
                if !viewModel.invited.contains(number) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    recipients = [number]
                    isShowingMessages = true
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: 90, height: 28)
                        .foregroundStyle(viewModel.invited.contains(number) ? .gray : Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).opacity(0.3)
                    Text(viewModel.invited.contains(number) ? "Invited" : "Invite").font(.subheadline).bold()
                        .foregroundStyle(.white)
                }
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
    @ViewBuilder
    func CustomTabBar() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach($tabs, id: \.id) { $tab in
                    Button(action: {
                        delayTask?.cancel()
                        delayTask = nil
                        
                        isDragging = true
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            activeTab = tab.id
                            tabBarScrollState = tab.id
                            progress = CGFloat(tabs.firstIndex(where: { $0.id == tab.id }) ?? 0)
                        }
                        
                        delayTask = .init { isDragging = false }
                        
                        if let delayTask { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: delayTask)
                        }
                    }) {
                        Text(tab.id)
                            .fontWeight(.bold)
                            .font(.subheadline)
                            .padding(.vertical, 12)
                            .foregroundStyle(activeTab == tab.id ? Color.primary : .gray)
                            .contentShape(.rect)
                    }
                    .frame(width: widthOrHeight(width: true) * 0.48)
                    .buttonStyle(.plain)
                    .rect { rect in
                        tab.size = rect.size
                        tab.minX = rect.minX
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: .init(get: {
            return tabBarScrollState
        }, set: { _ in
            
        }), anchor: .center)
        .overlay(alignment: .bottom) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, -15)
                
                let inputRange = tabs.indices.compactMap { return CGFloat($0) }
                let ouputRange = tabs.compactMap { return $0.size.width }
                let outputPositionRange = tabs.compactMap { return $0.minX }
                let indicatorWidth = progress.interpolate(inputRange: inputRange, outputRange: ouputRange)
                let indicatorPosition = progress.interpolate(inputRange: inputRange, outputRange: outputPositionRange)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue)
                    .frame(width: indicatorWidth, height: 3)
                    .offset(x: indicatorPosition)
                    .offset(y: -2)
            }
        }
        .scrollIndicators(.hidden)
    }
}
