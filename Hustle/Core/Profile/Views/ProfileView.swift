import SwiftUI
import Kingfisher
import StoreKit
import UIKit
import Firebase

struct ProfileView: View {
    @State private var showDevOption = false
    @StateObject var storeKit = StoreKitManager()
    
    @State private var selectedFilter: TweetFilterViewModel? = .hustles
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    let generator = UINotificationFeedbackGenerator()
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var showMenu = false
    @Namespace var animation
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var pop: PopToRoot
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var feed: FeedViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var messageModel: MessageViewModel
    @State private var showStatus = false
    @State private var dis: Option? = nil
    @State private var showEdit = false
    @State private var showMessage = false
    @State private var isRotating = false
    let showSettings: Bool
    let showMessaging: Bool
    let uid: String
    let photo: String
    let user: User?
    let expand: Bool
    let isMain: Bool
    @State private var displayUnlocked = false
    @State private var displayToken = false
    @State private var purchaseFailed = false
    @State private var showToken = false
    @State private var selectedToken = ""
    @State private var activateAwardsFuncOnDismiss = false
    @State private var offset: Double = 0
    @State private var viewIsTop = false
    
    @State var shiftOffset: CGFloat = 0
    @State var showName: Bool = false
    @State private var selection = 1
    @State private var yearString = ""
    @State var canRefresh: Bool = true
    @State private var shouldScroll = false
 
    @State var showShop: Bool = false
    @State var selectedShop: Shop = Shop(uid: "", username: "", title: "", caption: "", price: 0, location: "", photos: [], tagJoined: "", promoted: nil, timestamp: Timestamp())
    @State private var showQuestion = false
    @State var selectedQuestion: Question = Question(uid: "", username: "", caption: "", votes: 0, timestamp: Timestamp())
    @State private var showQuestionSec = false
    @State var selectedQuestionSec: Question = Question(uid: "", username: "", caption: "", votes: 0, timestamp: Timestamp())
    @State private var showAddStory = false
    @State private var seenNow = false
    @State private var showOnlineStatus = false
    @State private var showSocialLinks = false
    @State private var showAddNumberSheet = false
    @State private var showFriends = false
    @State private var tabProgress: CGFloat = 0
    
    @State private var postHustle = false
    @State private var postJob = false
    @State private var postMarketPlace = false
    @State private var postQuestion = false
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State var initialContent: uploadContent? = nil
    @State var place: myLoc? = nil
    @State var uploadJob: Int = 2
    @State var uploadShop: Int = 1
    @StateObject var uploadViewModel = UploadJobViewModel()
    @StateObject var PostShopViewModel = UploadShopViewModel()
    
    @State private var showShareProfileSheet = false
    @State var showMemories = false
    @State var sendLink: String = ""
    @State var currentAudio: String = ""
    
    @State var isExpanded: Bool = false
    @State var showStoryChat = false
    @State var showStoryProfile = false
    @State var navID = ""
    @State var tempSet: Bool = false
    @State var showStoryLoader: Bool = true
    @Namespace private var newsAnimation
    
    var body: some View {
        ZStack(alignment: .bottom){
            VStack {
                headerView
                GeometryReader {
                    let size = $0.size
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                middleProfile
                                if !showMemories {
                                    Section(header: tweetFilter.id("top")) {
                                        ScrollView(.horizontal) {
                                            LazyHStack(alignment: .top, spacing: 0) {
                                                if let index = viewModel.currentUser {
                                                    hustles(index)
                                                        .id(TweetFilterViewModel.hustles)
                                                        .containerRelativeFrame(.horizontal)
                                                    jobs(index)
                                                        .id(TweetFilterViewModel.jobs)
                                                        .containerRelativeFrame(.horizontal)
                                                    likes(index)
                                                        .id(TweetFilterViewModel.likes)
                                                        .containerRelativeFrame(.horizontal)
                                                    sale(index)
                                                        .id(TweetFilterViewModel.sale)
                                                        .containerRelativeFrame(.horizontal)
                                                    questions(index)
                                                        .id(TweetFilterViewModel.questions)
                                                        .containerRelativeFrame(.horizontal)
                                                }
                                            }
                                            .scrollTargetLayout()
                                            .offsetX { value in
                                                let progress = -value / (size.width * CGFloat(TweetFilterViewModel.allCases.count - 1))
                                                tabProgress = max(min(progress, 1), 0)
                                            }
                                        }
                                        .scrollPosition(id: $selectedFilter)
                                        .scrollIndicators(.hidden)
                                        .scrollTargetBehavior(.viewAligned)
                                        .scrollClipDisabled()
                                    }
                                }
                                Color.clear.frame(height: 80)
                            }
                            .background(GeometryReader {
                                Color.clear.preference(key: ViewOffsetKey.self,
                                                       value: -$0.frame(in: .named("scrollXX")).origin.y)
                            })
                            .onPreferenceChange(ViewOffsetKey.self) { value in
                                shiftOffset = value
                                if shiftOffset >= 150 {
                                    showName = true
                                } else {
                                    showName = false
                                }
                                if value < -60 && canRefresh {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    canRefresh = false
                                    updateData()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        shouldScroll.toggle()
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                        canRefresh = true
                                    }
                                }
                            }
                        }
                        .coordinateSpace(name: "scrollXX")
                        .scrollIndicators(.hidden)
                        .onChange(of: shouldScroll) { _, _ in
                            withAnimation { proxy.scrollTo("top", anchor: .top) }
                        }
                        .onChange(of: selectedFilter) { oldValue, newValue in
                            if shiftOffset >= 150 {
                                var c1 = 0
                                var c2 = 0
                                if let index = viewModel.currentUser {
                                    switch oldValue?.title {
                                    case "Hustles": c1 = viewModel.users[index].tweets?.count ?? 0
                                    case "Jobs": c1 = viewModel.users[index].listJobs?.count ?? 0
                                    case "Likes": c1 = viewModel.users[index].likedTweets?.count ?? 0
                                    case "4Sale": c1 = viewModel.users[index].forSale?.count ?? 0
                                    default: c1 = viewModel.users[index].questions?.count ?? 0
                                    }
                                    
                                    switch newValue?.title {
                                    case "Hustles": c2 = viewModel.users[index].tweets?.count ?? 0
                                    case "Jobs": c2 = viewModel.users[index].listJobs?.count ?? 0
                                    case "Likes": c2 = viewModel.users[index].likedTweets?.count ?? 0
                                    case "4Sale": c2 = viewModel.users[index].forSale?.count ?? 0
                                    default: c2 = viewModel.users[index].questions?.count ?? 0
                                    }
                                }
                                if c1 > c2 {
                                    withAnimation { proxy.scrollTo("top", anchor: .top) }
                                }
                            }
                            if let index = viewModel.currentUser {
                                if selectedFilter == .likes && (viewModel.users[index].likedTweets ?? []).isEmpty {
                                    viewModel.fetchLikedTweets()
                                }
                                if selectedFilter == .jobs && (viewModel.users[index].listJobs ?? []).isEmpty {
                                    viewModel.fetchUserJobs(userPhoto: auth.currentUser?.profileImageUrl, isCurrentUser: auth.currentUser?.id == viewModel.users[index].user.id)
                                }
                                if selectedFilter == .sale && (viewModel.users[index].forSale ?? []).isEmpty {
                                    viewModel.fetchUserSales(userPhoto: auth.currentUser?.profileImageUrl, isCurrentUser: auth.currentUser?.id == viewModel.users[index].user.id)
                                }
                                if selectedFilter == .questions && (viewModel.users[index].questions ?? []).isEmpty {
                                    viewModel.fetchUserQuestions(userPhoto: auth.currentUser?.profileImageUrl, isCurrentUser: auth.currentUser?.id == viewModel.users[index].user.id)
                                }
                            }
                        }
                    }
                }
            }
            .blur(radius: displayUnlocked ? 5 : 0)
            .blur(radius: (showToken || displayToken) ? 2 : 0)
            .background(colorScheme == .dark ? .black : .white)
            .zIndex((displayUnlocked || showToken || displayToken) ?  0.0 : showMenu ? 0.0 : 1.0)
            
            if shiftOffset < -60 {
                VStack {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer()
                }.padding(.top, 130).zIndex(2.0)
            }

            if showMenu {
                ZStack {
                    Color(.black).opacity(showMenu ? 0.25 : 0.0)
                }
                .onTapGesture {
                    withAnimation(.easeInOut){
                        showMenu = false
                    }
                }
                .ignoresSafeArea().transition(.opacity)
            }
            if let num = viewModel.unlockToShow, displayUnlocked {
                UnlocksView(num: num)
                    .onTapGesture {
                        let string = String(repeating: "*", count: num)
                        auth.currentUser?.alertsShown = string
                        viewModel.editAlerts(count: string)
                        viewModel.unlockToShow = nil
                        displayUnlocked = false
                    }
                    .onDisappear {
                        if let index = viewModel.currentUser {
                            var x = 0
                            withAnimation {
                                selection = 2
                            }
                            if num == 4 {
                                Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                                    viewModel.users[index].user.elo += 1
                                    x += 1
                                    if x == 150 {
                                        timer.invalidate()
                                    }
                                }
                            } else if num == 5 {
                                Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                                    viewModel.users[index].user.elo += 1
                                    x += 1
                                    if x == 100 {
                                        timer.invalidate()
                                    }
                                }
                            }
                        }
                    }
            }
            if showToken {
                TokenView(showText: false, showToken: $showToken, image: selectedToken)
                    .onDisappear { showToken = false }
            }
            if displayToken {
                TokenView(showText: true, showToken: $displayToken, image: viewModel.tokenToShow)
                    .onDisappear {
                        auth.currentUser?.badges.append(viewModel.tokenToShow)
                        viewModel.editbadges(title: viewModel.tokenToShow)
                        displayToken = false
                        viewModel.tokenToShow = ""
                    }
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showShareProfileSheet, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .fullScreenCover(isPresented: $postHustle, content: {
            NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent)
                .onDisappear {
                    place = nil
                }
        })
        .fullScreenCover(isPresented: $postJob, content: {
            TabView(selection: $uploadJob) {
                UploadJobView(viewModel: uploadViewModel, selTab: $uploadJob, lastTab: 2, isProfile: true)
                    .tag(2)
                PromoteUploadView(viewModel: uploadViewModel, selTab: $uploadJob, lastTab: 2, isProfile: true)
                    .tag(3)
            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        })
        .fullScreenCover(isPresented: $postMarketPlace, content: {
            TabView(selection: $uploadShop) {
                UploadFirstView(viewModel: PostShopViewModel, selTab: $uploadShop, lastTab: 1, isProfile: true).tag(1)
                UploadSecView(viewModel: PostShopViewModel, selTab: $uploadShop, lastTab: 1, isProfile: true).tag(2)
            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        })
        .fullScreenCover(isPresented: $postQuestion, content: {
            UploadQuestion()
        })
        .navigationDestination(isPresented: $showFriends) {
            FindFriendsView().enableFullSwipePop(true)
        }
        .overlay(content: {
            if showMemories {
                MemoriesView {
                    withAnimation(.easeInOut(duration: 0.2)){
                        popRoot.hideTabBar = false
                        showMemories = false
                    }
                }
                .background().transition(.move(edge: .trailing))
                .onDisappear {
                    if popRoot.hideTabBar {
                        withAnimation(.easeInOut(duration: 0.2)){
                            popRoot.hideTabBar = false
                        }
                    }
                }
            }
        })
        .onChange(of: showFriends) { _, _ in
            if !showFriends {
                if let current = auth.currentUser, !viewModel.fetching {
                    viewModel.fetching = true
                    viewModel.start(uid: uid, currentUser: current, optionalUser: user)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        viewModel.fetching = false
                    }
                }
            }
        }
        .sheet(isPresented: $showAddNumberSheet, content: {
            addPhoneNumber(showFriends: $showFriends)
        })
        .sheet(isPresented: $showSocialLinks, content: {
            SocialLinksView()
        })
        .sheet(isPresented: $showOnlineStatus, content: {
            SilentEditView()
        })
        .fullScreenCover(isPresented: $showAddStory, content: {
            MessageCamera(initialSend: .constant(nil), showMemories: true)
        })
        .navigationBarBackButtonHidden(true)
        .overlay(content: {
            VStack {
                if showMenu {
                    Spacer()
                    SideMenuView(showPhoneSheet: $showAddNumberSheet, showFriends: $showFriends).frame(height: 455).transition(AnyTransition.move(edge: .bottom))
                }
            }.ignoresSafeArea()
        })
        .onChange(of: pop.tap, { _, _ in
            if viewIsTop {
                if pop.tap == 6 || pop.tap == 1 {
                    if showMenu {
                        withAnimation(.easeInOut){
                            showMenu = false
                        }
                    } else {
                        withAnimation(.easeInOut){
                            shouldScroll.toggle()
                        }
                    }
                    pop.tap = 0
                } else {
                    presentationMode.wrappedValue.dismiss()
                    pop.tap = 0
                }
            }
        })
        .onChange(of: showStatus, { _, _ in
            if activateAwardsFuncOnDismiss && !showStatus {
                activateAwardsFuncOnDismiss = false
                viewModel.tokens(bridge: true)
            }
        })
        .onAppear {
            viewIsTop = true
            if let current = auth.currentUser, !viewModel.fetching {
                viewModel.fetching = true
                viewModel.start(uid: uid, currentUser: current, optionalUser: user)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    viewModel.fetching = false
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0){
                showStoryLoader = false
            }

            if viewModel.unlockToShow != nil && !viewModel.updatingElo && viewModel.isCurrentUser {
                displayUnlocked = true
            }
            if !viewModel.updatingElo && !viewModel.tokenToShow.isEmpty && viewModel.isCurrentUser {
                displayToken = true
            }
            setSeen()
        }
        .onChange(of: viewModel.unlockToShow, { _, _ in
            if viewModel.unlockToShow != nil && !viewModel.updatingElo && viewModel.isCurrentUser {
                displayUnlocked = true
            }
        })
        .onChange(of: viewModel.tokenToShow, { _, _ in
            if !viewModel.updatingElo && !viewModel.tokenToShow.isEmpty && viewModel.isCurrentUser {
                displayToken = true
            }
        })
        .onDisappear {
            viewIsTop = false
        }
        .sheet(isPresented: $showStatus) { sheetView }
        .fullScreenCover(isPresented: $showEdit){ AccountView() }
        .sheet(isPresented: $showShop, content: {
            SingleShopView(shopItem: selectedShop, disableUser: true, shouldCloseKeyboard: false)
                .presentationDetents([.large]).presentationDragIndicator(.hidden)
        })
        .sheet(isPresented: $showQuestion, content: {
            ImageQuestionView(question: selectedQuestion, disableUser: true, shouldShowTab: true)
                .presentationDetents([.large]).presentationDragIndicator(.hidden)
        })
        .sheet(isPresented: $showQuestionSec, content: {
            QuestionSingleView(disableUser: false, question: selectedQuestionSec, isSheet: true)
                .presentationDetents([.large]).presentationDragIndicator(.hidden)
        })
        .navigationDestination(isPresented: $showStoryChat) {
            MessagesView(exception: false, user: nil, uid: self.navID, tabException: true, canCall: true)
                .enableFullSwipePop(true)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.15)){
                        popRoot.hideTabBar = true
                    }
                }
                .onDisappear {
                    withAnimation(.easeInOut(duration: 0.15)){
                        popRoot.hideTabBar = false
                    }
                }
        }
        .navigationDestination(isPresented: $showStoryProfile) {
            ProfileView(showSettings: false, showMessaging: true, uid: self.navID, photo: "", user: nil, expand: false, isMain: false).enableFullSwipePop(true)
        }
        .overlay {
            if isExpanded {
                MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: "MainProfile", isHome: false, canOpenChat: true, canOpenProfile: false, openChat: { uid in
                    self.navID = uid
                    showStoryChat = true
                }, openProfile: { uid in
                    self.navID = uid
                    showStoryProfile = true
                })
                .transition(.scale)
                .onDisappear {
                    withAnimation(.easeInOut(duration: 0.15)){
                        popRoot.hideTabBar = false
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    @ViewBuilder
    func TagView(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Image(tag).resizable().aspectRatio(contentMode: .fit).frame(height: 25)
            Text(tag).font(.callout).fontWeight(.semibold)
        }
        .foregroundStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 35)
        .padding(.horizontal, 7)
        .background {
            Capsule().fill(Color.gray.gradient).opacity(0.3)
        }
    }
    func setSeen(){
        if let index = viewModel.currentUser {
            if let lastTime = viewModel.users[index].user.lastSeen {
                let dateString = lastTime.dateValue().formatted(.dateTime.month().day().year().hour().minute())
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
                if let date = dateFormatter.date(from:dateString){
                    if Calendar.current.isDateInToday(date){
                        seenNow = true
                    } else {
                        seenNow = false
                    }
                } else {
                    seenNow = false
                }
            } else {
                seenNow = false
            }
        }
    }
    func hasStories() -> Bool {
        if let index = viewModel.currentUser {
            let uid = viewModel.users[index].user.id
            return !(viewModel.users.first(where: { $0.user.id == uid })?.stories ?? []).isEmpty
        }
        return false
    }
    func storiesLeftToSee() -> Bool {
        if let index = viewModel.currentUser {
            if let uid = auth.currentUser?.id, let otherUID = viewModel.users[index].user.id {
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
        }
        return false
    }
}

extension ProfileView {
    var headerView: some View {
        VStack {
            ZStack {
                if let index = viewModel.currentUser, let back = viewModel.users[index].user.userBackground, !back.isEmpty {
                    let size = headerSize() + top_Inset()
                    Color.orange
                        .opacity(0.7)
                        .frame(height: size)
                        .cornerRadius(25, corners: [.bottomLeft, .bottomRight])
                        .ignoresSafeArea()
                    KFImage(URL(string: back))
                        .resizable()
                        .scaledToFill()
                        .blur(radius: headerBlur())
                        .frame(width: widthOrHeight(width: true), height: size)
                        .clipped()
                        .cornerRadius(25, corners: [.bottomLeft, .bottomRight])
                        .ignoresSafeArea()
                } else {
                    Color.orange
                        .opacity(0.7)
                        .cornerRadius(25, corners: [.bottomLeft, .bottomRight])
                        .ignoresSafeArea()
                }
                HStack {
                    Button {
                        if isMain {
                            withAnimation {
                                globe.option = 2
                            }
                            feed.showProfile = false
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } label: {
                        ZStack {
                            Circle().foregroundStyle(.gray)
                                .frame(width: 30)
                            Image(systemName: "arrow.backward")
                        }
                    }
                    Spacer()
                    if showSettings {
                        Button {
                            var x = 0
                            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                                x += 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if x == 5 {
                                    timer.invalidate()
                                }
                            }
                            withAnimation(.easeInOut){
                                showMenu.toggle()
                            }
                            withAnimation(.linear(duration: 0.5)) {
                                self.isRotating.toggle()
                            }
                        } label: {
                            Image(systemName: "gear")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(isRotating ? 360 : 0))
                        }
                    } else if let id = auth.currentUser?.id, id != uid {
                        Menu {
                            Button(role: .destructive, action: {
                                UserService().reportContent(type: "User", postID: uid)
                            }) {
                                Label("Report", systemImage: "flag.fill")
                            }
                            Button(role: .destructive, action: {
                                if auth.currentUser?.blockedUsers == nil {
                                    auth.currentUser?.blockedUsers = []
                                }
                                auth.currentUser?.blockedUsers?.append(uid)
                                UserService().blockUser(uid: uid)
                            }) {
                                Label("Block", systemImage: "hand.raised.fill")
                            }
                            Button {
                                sendLink = "https://hustle.page/profile/\(uid)/"
                                showShareProfileSheet = true
                            } label: {
                                Label("Share Profile", systemImage: "paperplane")
                            }
                            Button {
                                withAnimation {
                                    popRoot.alertReason = "Profile URL copied"
                                    popRoot.alertImage = "link"
                                    popRoot.showAlert = true
                                }
                                UIPasteboard.general.string = "https://hustle.page/profile/\(uid)/"
                            } label: {
                                Label("Copy Profile URL", systemImage: "link")
                            }
                        } label: {   
                            ZStack {
                                Rectangle().frame(width: 40, height: 40)
                                    .foregroundStyle(.gray).opacity(0.001)
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 35))
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 35)).foregroundStyle(.clear)
                    }
                }.padding(.horizontal, 25)
                HStack {
                    Spacer()
                    ZStack {
                        if hasStories() {
                            StoryRingView(size: 43.5, active: storiesLeftToSee(), strokeSize: 1.5)
                            
                            let size = isExpanded ? 200 : 35.0
                            GeometryReader { _ in
                                ZStack {
                                    personView(size: size)
                                    
                                    if let index = viewModel.currentUser, let image = viewModel.users[index].user.profileImageUrl {
                                        KFImage(URL(string: image))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .scaledToFill()
                                            .clipShape(Circle())
                                            .frame(width: size, height: size)
                                    }
                                }.opacity(isExpanded ? 0.0 : 1.0)
                            }
                            .matchedGeometryEffect(id: "MainProfile", in: animation, anchor: .top)
                            .frame(width: 35, height: 35)
                            .onTapGesture {
                                if let index = viewModel.currentUser {
                                    let uid = viewModel.users[index].user.id
                                    if let stories = viewModel.users.first(where: { $0.user.id == uid })?.stories {
                                        DispatchQueue.main.async {
                                            self.viewModel.selectedStories = stories
                                            
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            withAnimation(.easeInOut(duration: 0.15)){
                                                self.popRoot.hideTabBar = true
                                                self.isExpanded = true
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            ZStack {
                                if showStoryLoader {
                                    LottieView(loopMode: .loop, name: "loadingStory")
                                        .scaleEffect(0.066)
                                        .frame(width: 37.5, height: 37.5)
                                }
                                personView(size: 37.5)
                                if let index = viewModel.currentUser, let image = viewModel.users[index].user.profileImageUrl {
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .scaledToFill()
                                        .clipShape(Circle())
                                        .frame(width: 37.5, height: 37.5)
                                        .shadow(radius: 1)
                                }
                            }
                        }
                    }
                    .scaleEffect(2.0)
                    .offset(y: -5)
                    .offset(y: photoOffset())
                    Spacer()
                }
            }.frame(height: headerSize())

            HStack(spacing: 8){
                if let index = viewModel.currentUser, showName {
                    Button {
                        popRoot.alertReason = "Profile URL copied"
                        popRoot.alertImage = "link"
                        withAnimation {
                            popRoot.showAlert = true
                        }
                        UIPasteboard.general.string = "https://hustle.page/profile/\(uid)/"
                    } label: {
                        Text(viewModel.users[index].user.fullname).font(.title3).bold()
                    }
                    .zIndex(1)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    
                    if auth.currentUser?.id == viewModel.users[index].user.id {
                        Button(action: {
                            showOnlineStatus.toggle()
                        }, label: {
                            if let silent = viewModel.users[index].user.silent {
                                if silent == 1 {
                                    Circle().foregroundStyle(.green).frame(width: 12, height: 12)
                                } else if silent == 2 {
                                    Image(systemName: "moon.fill").foregroundStyle(.yellow).frame(width: 18, height: 18)
                                } else if silent == 3 {
                                    Image(systemName: "slash.circle.fill").foregroundStyle(.red).frame(width: 18, height: 18)
                                } else {
                                    Image("ghostMode")
                                        .resizable().scaledToFit().frame(width: 18, height: 18).scaleEffect(1.4)
                                }
                            } else if seenNow {
                                Circle().foregroundStyle(.green).frame(width: 12, height: 12)
                            }
                        }).transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    } else {
                        if let silent = viewModel.users[index].user.silent {
                            if silent == 1 {
                                Circle().foregroundStyle(.green).frame(width: 12, height: 12)
                                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                            } else if silent == 2 {
                                Image(systemName: "moon.fill").foregroundStyle(.yellow).frame(width: 18, height: 18)
                                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                            } else if silent == 3 {
                                Image(systemName: "slash.circle.fill").foregroundStyle(.red).frame(width: 18, height: 18).transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                            } else {
                                Image("ghostMode")
                                    .resizable().scaledToFit().frame(width: 18, height: 18).scaleEffect(1.4)
                            }
                        } else if seenNow {
                            Circle().foregroundStyle(.green).frame(width: 12, height: 12)
                                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                        }
                    }
                } else if let index = viewModel.currentUser, index < viewModel.users.count && viewModel.isCurrentUser {
                    if (viewModel.users[index].user.socials ?? []).isEmpty {
                        Button {
                            showSocialLinks = true
                        } label: {
                            Text("+ Socials")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .font(.subheadline).bold()
                                .frame(width: 74, height: 32)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray, lineWidth: 0.75))
                        }.animation(.easeInOut, value: showName)
                    }
                }
                if showName {
                    Spacer()
                }
                if let index = viewModel.currentUser, let user_uid = auth.currentUser?.id, user_uid != viewModel.users[index].user.id {
                    if viewModel.users[index].user.following.contains(user_uid) && (viewModel.users[index].user.silent ?? 1) != 3 {
                        Button {
                            
                        } label: {
                            Image(systemName: "video.fill")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .padding(6)
                                .padding(.vertical, 2)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 0.75))
                        }.animation(.easeInOut(duration: 0.12), value: showName)
                        Button {
                            
                        } label: {
                            Image(systemName: "phone.fill")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .padding(6)
                                .padding(.vertical, 2)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 0.75))
                        }.animation(.easeInOut(duration: 0.12), value: showName)
                    }
                } else if viewModel.isCurrentUser {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)){
                            showMemories = true
                            popRoot.hideTabBar = true
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 0){
                            ZStack {
                                Circle()
                                    .stroke(.gray, lineWidth: 1.0)
                                Image("memory")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .scaledToFit().offset(x: 1)
                                    .brightness(colorScheme == .dark ? 0.0 : -0.2)
                            }.frame(width: 32, height: 32)
                            Text("Memory").font(.caption2).fontWeight(.semibold)
                        }
                    }.animation(.easeInOut(duration: 0.12), value: showName)
                }
                if !showName {
                    Spacer()
                }
                
                if let index = viewModel.currentUser {
                    if viewModel.isCurrentUser {
                        Menu {
                            Button {
                                showAddStory = true
                            } label: {
                                Label("Add Story", systemImage: "globe")
                            }
                            Button {
                                //go live
                            } label: {
                                Label("Go Live", systemImage: "video.badge.plus")
                            }
                            Button {
                                postHustle = true
                            } label: {
                                Label("Hustle", systemImage: "newspaper")
                            }
                            Button {
                                postJob = true
                            } label: {
                                Label("Job", systemImage: "wrench.and.screwdriver.fill")
                            }
                            Button {
                                postMarketPlace = true
                            } label: {
                                Label("Marketplace", systemImage: "house")
                            }
                            Button {
                                postQuestion = true
                            } label: {
                                Label("Question", systemImage: "questionmark")
                            }
                        } label: {
                            VStack(spacing: 0){
                                Image(systemName: "plus")
                                    .font(.system(size: 15))
                                    .padding(8)
                                    .foregroundStyle(.white).background(Color(UIColor.darkGray).opacity(0.8)).clipShape(Circle())
                                    .frame(width: 32, height: 32)
                                Text("Create").font(.caption2).fontWeight(.semibold)
                            }
                        }

                        Button {
                            showEdit.toggle()
                        } label: {
                            Text("Edit")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .font(.subheadline).bold()
                                .frame(width: 60, height: 32)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray, lineWidth: 0.75))
                        }
                    } else {
                        if !viewModel.isCurrentUser && showMessaging {
                            Button {
                                showMessage.toggle()
                            } label: {
                                Image(systemName: "paperplane.fill")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                    .padding(6)
                                    .padding(.vertical, 2)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 0.75))
                            }
                            .fullScreenCover(isPresented: $showMessage) {
                                MessagesView(exception: false, user: viewModel.users[index].user, uid: viewModel.users[index].user.id ?? "", tabException: false, canCall: true)
                            }
                        }
                        Button {
                            if let following = auth.currentUser?.following {
                                if following.contains(uid){
                                    viewModel.unfollow(withUid: uid)
                                    auth.currentUser?.following.removeAll(where: { $0 == uid })
                                    generator.notificationOccurred(.error)
                                } else {
                                    viewModel.follow(withUid: uid)
                                    generator.notificationOccurred(.success)
                                    auth.currentUser?.following.append(uid)
                                    if !viewModel.startedFollowing.contains(uid) {
                                        viewModel.startedFollowing.append(uid)
                                        if let myUID = auth.currentUser?.id, let name = auth.currentUser?.fullname {
                                            viewModel.sendNotif(taggerName: name, taggerUID: myUID, taggedUID: uid)
                                        }
                                    }
                                }
                            }
                        } label: {
                            if let following = auth.currentUser?.following {
                                if following.contains(uid) {
                                    ZStack{
                                        Capsule()
                                            .foregroundColor(.blue)
                                        Text("Following")
                                            .padding(2)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white)
                                    }.frame(width: 70, height: 32)
                                } else {
                                    Text("Follow")
                                        .font(.subheadline).bold()
                                        .frame(width: 70, height: 32)
                                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray, lineWidth: 0.75))
                                }
                            }
                        }
                    }
                }
            }.padding(.horizontal, 10)
        }
    }
    var middleProfile: some View {
        VStack(spacing: 10){
            TabView(selection: $selection) {
                ZStack {
                    if let index = viewModel.currentUser {
                        RoundedRectangle(cornerRadius: 25)
                            .foregroundStyle(backgroundColor(elo: viewModel.users[index].user.elo))
                    } else {
                        RoundedRectangle(cornerRadius: 25)
                            .foregroundStyle(Color(red: 210/255, green: 180/255, blue: 140/255).opacity(0.5))
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 6){
                            HStack {
                                if let index = viewModel.currentUser {
                                    if auth.currentUser?.id == viewModel.users[index].user.id {
                                        Button(action: {
                                            showOnlineStatus.toggle()
                                        }, label: {
                                            if let silent = viewModel.users[index].user.silent {
                                                if silent == 1 {
                                                    Circle().foregroundStyle(.green).frame(width: 12, height: 12)
                                                } else if silent == 2 {
                                                    Image(systemName: "moon.fill").foregroundStyle(.yellow)
                                                        .frame(width: 18, height: 18).padding(4)
                                                        .background(.black)
                                                        .clipShape(Circle())
                                                } else if silent == 3 {
                                                    Image(systemName: "slash.circle.fill").foregroundStyle(.red).frame(width: 18, height: 18)
                                                } else {
                                                    Image("ghostMode")
                                                        .resizable().scaledToFit().frame(width: 18, height: 18).scaleEffect(1.4)
                                                }
                                            } else if seenNow {
                                                Circle().foregroundStyle(.green).frame(width: 12, height: 12)
                                            }
                                        })
                                    } else {
                                        if let silent = viewModel.users[index].user.silent {
                                            if silent == 1 {
                                                Circle().foregroundStyle(.green).frame(width: 12, height: 12)
                                            } else if silent == 2 {
                                                Image(systemName: "moon.fill").foregroundStyle(.yellow)
                                                    .frame(width: 18, height: 18).padding(4)
                                                    .background(.black)
                                                    .clipShape(Circle())
                                            } else if silent == 3 {
                                                Image(systemName: "slash.circle.fill").foregroundStyle(.red).frame(width: 18, height: 18)
                                            } else {
                                                Image("ghostMode")
                                                    .resizable().scaledToFit().frame(width: 18, height: 18).scaleEffect(1.4)
                                            }
                                        } else if seenNow {
                                            Circle().foregroundStyle(.green).frame(width: 12, height: 12)
                                        }
                                    }
                                    Button {
                                        popRoot.alertReason = "Profile URL copied"
                                        popRoot.alertImage = "link"
                                        withAnimation {
                                            popRoot.showAlert = true
                                        }
                                        UIPasteboard.general.string = "https://hustle.page/profile/\(uid)/"
                                    } label: {
                                        Text(viewModel.users[index].user.fullname)
                                            .bold().font(.title3).foregroundStyle(colorScheme == .dark ? .white : .black)
                                    }
                                    if viewModel.users[index].user.verified ?? false {
                                        Image("veriBlue")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: 25)
                                            .padding(.leading)
                                    }
                                }
                                Spacer()
                            }
                            if let index = viewModel.currentUser {
                                Text("@\(viewModel.users[index].user.username)").font(.body)
                                    .gesture(TapGesture(count: 2).onEnded {
                                        if let id = auth.currentUser?.dev {
                                            if id.contains("(DWK@)2))&DNWIDN:"){
                                                showDevOption = true
                                            }
                                        }
                                    })
                                    .simultaneousGesture(TapGesture().onEnded {
                                        popRoot.alertReason = "Username copied"
                                        popRoot.alertImage = "link"
                                        withAnimation {
                                            popRoot.showAlert = true
                                        }
                                        UIPasteboard.general.string = viewModel.users[index].user.username
                                    })
                                    .alert("User ID: \(viewModel.users[index].user.id ?? "")", isPresented: $showDevOption) {
                                        Button("User ID", role: .destructive) {
                                            UIPasteboard.general.string = viewModel.users[index].user.id ?? ""
                                        }
                                    }
                            }
                            Spacer()
                            if let index = viewModel.currentUser {
                                if let text = viewModel.users[index].user.bio, !text.isEmpty {
                                    Text(text).font(.body)
                                } else if pop.tab == 6 && viewModel.isCurrentUser {
                                    Button {
                                        showEdit.toggle()
                                    } label: {
                                        Text("Add a bio...").font(.body).underline()
                                    }.padding(.bottom)
                                } else {
                                    Text("Nothing yet...").font(.body).padding(.bottom)
                                }
                            } else {
                                Text("Nothing yet...").font(.body).padding(.bottom)
                            }
                        }.padding(5)
                        Spacer()
                        if let index = viewModel.currentUser {
                            VStack {
                                if viewModel.isCurrentUser{
                                    Button {
                                        generator.notificationOccurred(.success)
                                        let elo = viewModel.users[index].user.elo
                                        configure(elo: elo, change: true)
                                        showStatus.toggle()
                                    } label: {
                                        chessPiece(elo: viewModel.users[index].user.elo)
                                    }
                                } else {
                                    chessPiece(elo: viewModel.users[index].user.elo)
                                }
                                Text("\(viewModel.users[index].user.elo)").font(Font.custom("Revalia-Regular", size: 16, relativeTo: .title)).bold()
                            }
                        }
                    }.padding(7)
                }
                .padding(.horizontal)
                .tag(1)
                ZStack {
                    if let index = viewModel.currentUser {
                        RoundedRectangle(cornerRadius: 25)
                            .foregroundStyle(backgroundColor(elo: viewModel.users[index].user.elo))
                    } else {
                        RoundedRectangle(cornerRadius: 25)
                            .foregroundStyle(Color(red: 210/255, green: 180/255, blue: 140/255).opacity(0.5))
                    }
                    VStack {
                        if let index = viewModel.currentUser {
                            HStack {
                                HStack(alignment: .bottom){
                                    Text("ELO").font(.caption)
                                    Text("\(viewModel.users[index].user.elo)").font(Font.custom("Revalia-Regular", size: 24, relativeTo: .title)).bold()
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.followers)").font(.body).bold()
                                    Text("Followers").font(.caption)
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.following.count)").font(.body).bold()
                                    Text("Following").font(.caption)
                                }
                                Spacer()
                                VStack {
                                    Text(yearString).font(.body).bold()
                                    Text("Joined").font(.caption)
                                }
                                .onAppear {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyy"
                                    yearString = dateFormatter.string(from: viewModel.users[index].user.timestamp.dateValue())
                                }
                            }
                            Spacer()
                            HStack {
                                VStack {
                                    Text("\((viewModel.users[index].tweets ?? []).count)").font(.body).bold()
                                    Text("Hustles").font(.caption)
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.completedjobs)").font(.body).bold()
                                    HStack(spacing: 2){
                                        Image(systemName: "checkmark").font(.caption).foregroundColor(.green)
                                        Text("Jobs").font(.caption)
                                    }
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.sold ?? 0)").font(.body).bold()
                                    Text("Sold").font(.caption)
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.bought ?? 0)").font(.body).bold()
                                    Text("Bought").font(.caption)
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.verifiedTips)").font(.body).bold()
                                    Text("Tips").font(.caption)
                                }
                            }
                        }
                    }.padding().padding(.vertical, 5)
                }
                .padding(.horizontal)
                .tag(2)
                ZStack {
                    if let index = viewModel.currentUser {
                        let arr = ["g_owner", "write", "tentips", "fivejobs", "heart", "tenhustles"]
                        ForEach(0..<arr.count, id: \.self){ i in
                            let totalElements = 6
                            let angle = 2 * .pi * Double(i) / Double(totalElements)
                            let radius: CGFloat = 50.0
                            let offsetX = radius * cos(CGFloat(angle))
                            let offsetY = radius * sin(CGFloat(angle))
                            if viewModel.users[index].user.badges.contains(arr[i]) {
                                Button {
                                    selectedToken = arr[i]
                                    showToken.toggle()
                                } label: {
                                    if arr[i] == "g_owner" {
                                        Image(arr[i]).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 32)
                                    } else {
                                        Image(arr[i]).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 40)
                                    }
                                }.offset(x: offsetX, y: offsetY)
                            } else {
                                if arr[i] == "g_owner" {
                                    Image(arr[i]).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 32)
                                        .opacity(0.3).offset(x: offsetX, y: offsetY)
                                } else {
                                    Image(arr[i]).resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 40)
                                        .opacity(0.3).offset(x: offsetX, y: offsetY)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 150)
            if let index = viewModel.currentUser, index < viewModel.users.count && viewModel.isCurrentUser {
                if let all = viewModel.users[index].user.socials, !all.isEmpty {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 10){
                            Button {
                                showSocialLinks.toggle()
                            } label: {
                                HStack(spacing: 10) {
                                    Text("+ Socials").font(.callout).fontWeight(.semibold)
                                }
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .frame(height: 35)
                                .padding(.horizontal, 15)
                                .background {
                                    Capsule().fill(Color.gray.gradient).opacity(0.3)
                                }
                            }
                            ForEach(all, id: \.self) { element in
                                if element.contains(":") {
                                    let components = element.split(separator: ":", maxSplits: 1)
                                    if components.count >= 2 {
                                        if let firstElement = components.first, let secondElement = components.last {
                                            Button {
                                                if let url = URL(string: String(secondElement)) {
                                                    if UIApplication.shared.canOpenURL(url) {
                                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                                    }
                                                }
                                            } label: {
                                                TagView(String("\(firstElement)"))
                                            }
                                        }
                                    }
                                }
                            }
                        }.padding(.horizontal)
                    }
                }
            }
        }.padding(.bottom, 15).padding(.top, 6)
    }
    var tweetFilter: some View {
        HStack(spacing: 0) {
            ForEach(TweetFilterViewModel.allCases, id: \.rawValue) { tab in
                HStack(spacing: 10) {
                    Text(tab.title).font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(.capsule)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.snappy) {
                        selectedFilter = tab
                    }
                }
            }
        }
        .tabMask(tabProgress, tabCount: TweetFilterViewModel.allCases.count)
        .padding(.horizontal, 8)
        .background {
            GeometryReader {
                let size = $0.size
                let capusleWidth = size.width / CGFloat(TweetFilterViewModel.allCases.count)
                ZStack(alignment: .leading){
                    RoundedRectangle(cornerRadius: 0)
                        .fill(.gray)
                        .frame(height: 1)
                        .offset(y: 40)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.blue)
                        .frame(width: capusleWidth, height: 2)
                        .offset(x: tabProgress * (size.width - capusleWidth), y: 40)
                        .padding(.trailing, 8)
                }
            }
        }
        .background(colorScheme == .dark ? .black : .white)
    }
    
    @ViewBuilder
    func hustles(_ index: Int) -> some View {
        LazyVStack {
            if let hustles = viewModel.users[index].tweets {
                if hustles.isEmpty {
                    HStack {
                        Spacer()
                        Text("Nothing here...").gradientForeground(colors: [.green, .blue]).font(.system(size: 25))
                        Spacer()
                    }.padding(.vertical)
                } else {
                    ForEach(hustles) { tweet in
                        TweetRowView(tweet: tweet, edit: false, canShow: false, canSeeComments: true, map: false, currentAudio: $currentAudio, isExpanded: $tempSet, animationT: animation, seenAllStories: false, isMain: false, showSheet: $tempSet, newsAnimation: newsAnimation)
                        if tweet != hustles.last {
                            Divider().overlay(.gray).padding(.bottom, 6).opacity(0.4)
                        }
                    }
                }
            } else {
                VStack {
                    ForEach(0..<7){ i in
                        LoadingFeed(lesson: "")
                    }
                }.shimmering()
            }
        }.padding(.top, 12)
    }
    @ViewBuilder
    func jobs(_ index: Int) -> some View {
        LazyVStack {
            if let jobs = viewModel.users[index].listJobs {
                if jobs.isEmpty {
                    HStack {
                        Spacer()
                        Text("Nothing here...").gradientForeground(colors: [.green, .blue]).font(.system(size: 25))
                        Spacer()
                    }.padding(.vertical)
                } else {
                    ForEach(jobs){ item in
                        JobsRowView(canShowProfile: false, remote: item.remote, job: item.job, is100: false, canMessage: false)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }
            } else {
                VStack {
                    ForEach(0..<7){ i in
                        LoadingFeed(lesson: "")
                    }
                }.shimmering()
            }
        }.padding(.top, 12)
    }
    @ViewBuilder
    func likes(_ index: Int) -> some View {
        LazyVStack {
            if let liked = viewModel.users[index].likedTweets {
                if liked.isEmpty {
                    HStack {
                        Spacer()
                        Text("Nothing here...").gradientForeground(colors: [.green, .blue]).font(.system(size: 25))
                        Spacer()
                    }.padding(.vertical)
                } else {
                    ForEach(liked){ tweet in
                        TweetRowView(tweet: tweet, edit: false, canShow: false, canSeeComments: true, map: false, currentAudio: $currentAudio, isExpanded: $tempSet, animationT: animation, seenAllStories: false, isMain: false, showSheet: $tempSet, newsAnimation: newsAnimation)
                        if tweet != liked.last {
                            Divider().overlay(.gray).padding(.bottom, 6).opacity(0.4)
                        }
                    }
                }
            } else {
                VStack {
                    ForEach(0..<7){ i in
                        LoadingFeed(lesson: "")
                    }
                }.shimmering()
            }
        }.padding(.top, 12)
    }
    @ViewBuilder
    func sale(_ index: Int) -> some View {
        LazyVStack {
            if let sale = viewModel.users[index].forSale {
                if sale.isEmpty {
                    HStack {
                        Spacer()
                        Text("Nothing here...").gradientForeground(colors: [.green, .blue]).font(.system(size: 25))
                        Spacer()
                    }.padding(.vertical)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(sale){ shop in
                            Button {
                                selectedShop = shop
                                showShop = true
                            } label: {
                                ShopRowView(shopItem: shop, isSheet: false)
                            }
                        }
                    }.padding(.horizontal, 5)
                }
            } else {
                VStack {
                    ForEach(0..<7){ i in
                        LoadingFeed(lesson: "")
                    }
                }.shimmering()
            }
        }.padding(.top, 12)
    }
    @ViewBuilder
    func questions(_ index: Int) -> some View {
        LazyVStack {
            if let ques = viewModel.users[index].questions {
                if ques.isEmpty {
                    HStack {
                        Spacer()
                        Text("Nothing here...").gradientForeground(colors: [.green, .blue]).font(.system(size: 25))
                        Spacer()
                    }.padding(.vertical)
                } else {
                    ForEach(ques){ question in
                        if question.image1 == nil {
                            Button {
                                selectedQuestionSec = question
                                showQuestionSec = true
                            } label: {
                                QuestionRowView(question: question, bottomPad: false).padding(.bottom, 8)
                            }
                        } else {
                            Button {
                                selectedQuestion = question
                                showQuestion = true
                            } label: {
                                ImageQuestionRow(question: question, bottomPad: false).padding(.bottom, 8)
                            }
                        }
                    }
                }
            } else {
                VStack {
                    ForEach(0..<7){ i in
                        LoadingFeed(lesson: "")
                    }
                }.shimmering()
            }
        }.padding(.top, 12)
    }
    var sheetView: some View {
        VStack(spacing: 0){
            ZStack(alignment: .top){
                Color(.black)
                VStack{
                    HStack{
                        Text("Current Level").font(.title3).foregroundColor(.white).padding(.leading, 15)
                        Spacer()
                        Button {
                            showStatus.toggle()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .scaleEffect(1.3)
                        }
                        .padding(.trailing)
                    }.padding(.top, 20)
                    HStack{
                        Text("--\(viewModel.statusPiece)").font(.title2).bold().foregroundColor(.white).padding(.leading, 15).id(viewModel.statusPiece)
                        Spacer()
                        if let index = viewModel.currentUser{
                            if viewModel.users[index].user.elo <= 600{
                                MenuT(selectedOption: self.$dis, placeholder: "Points", options: Option.pawn)
                                    .padding(.trailing, 15)
                                    .frame(height: 20)
                            }
                            else if viewModel.users[index].user.elo <= 850{
                                MenuT(selectedOption: self.$dis, placeholder: "Points", options: Option.bishop)
                                    .padding(.trailing, 15)
                                    .frame(height: 20)
                            }
                            else if viewModel.users[index].user.elo <= 1300{
                                MenuT(selectedOption: self.$dis, placeholder: "Points", options: Option.knight)
                                    .padding(.trailing, 15)
                                    .frame(height: 20)
                            }
                            else if viewModel.users[index].user.elo <= 2000{
                                MenuT(selectedOption: self.$dis, placeholder: "Points", options: Option.rook)
                                    .padding(.trailing, 15)
                                    .frame(height: 20)
                            }
                            else if viewModel.users[index].user.elo <= 2899{
                                MenuT(selectedOption: self.$dis, placeholder: "Points", options: Option.queen)
                                    .padding(.trailing, 15)
                                    .frame(height: 20)
                            }
                            else if viewModel.users[index].user.elo >= 2900 {
                                MenuT(selectedOption: self.$dis, placeholder: "Points", options: Option.king)
                                    .padding(.trailing, 15)
                                    .frame(height: 20)
                            }
                        }
                    }
                    .padding(.bottom, 5)
                }
            }
            .frame(height: 110)
            .zIndex(1.0)
            ScrollViewReader{ proxy in
                ScrollView{
                    ZStack(alignment: .top){
                        Color(.gray).opacity(colorScheme == .dark ? 0.15 : 0.45)
                        VStack(spacing: 0){
                            HStack{
                                Text("Unlocked Access")
                                    .bold()
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.title3)
                                    .id("scrollTop")
                                Spacer()
                            }.padding()

                            VStack(spacing: 7){
                                ForEach(viewModel.access, id: \.self){ access in
                                    HStack {
                                        Text(access).foregroundColor(.green).font(.subheadline)
                                        Spacer()
                                    }.padding(.leading)
                                }
                            }.padding(.bottom, 15)
                            Divider()
                                .padding(.bottom, 10)
                            ZStack {
                                Circle()
                                    .stroke(Color.gray, lineWidth: 10)
                                    .frame(width: 170, height: 170)
                                Circle()
                                    .trim(from: 0, to: viewModel.degrees / 360)
                                    .stroke(Color.green, lineWidth: 10)
                                    .frame(width: 170, height: 170)
                                    .rotationEffect(Angle(degrees: -90))
                                VStack(spacing: 4){
                                    Text("\(viewModel.nextPiece) ELO").bold()
                                    Text("to Unlock").bold()
                                    Text(viewModel.nextUnlock).bold()
                                }
                            }
                            .padding(.vertical, 30)
                            
                            HStack(spacing: 3){
                                Text("Next Rank").bold()
                                Image(systemName: "lock")
                                Spacer()
                            }
                            .padding(.leading)
                            .padding(.bottom, 15)
                            VStack(spacing: 7){
                                ForEach(viewModel.nextAccess, id: \.self){ access in
                                    HStack{
                                        Text(access).foregroundColor(.gray).font(.subheadline)
                                        Spacer()
                                    }.padding(.leading)
                                }
                            }
                        }
                    }
                    .frame(height: viewModel.statusPiece == "PAWN" ? 570 : 545)
                    .padding(20)
                    if let index = viewModel.currentUser {
                        ZStack(alignment: .top){
                            Color(.gray).opacity(colorScheme == .dark ? 0.15 : 0.45)
                            VStack(spacing: 0){
                                HStack {
                                    Text("Buy Elo").font(.title3).bold()
                                    Spacer()
                                    Text("You'd have: \(viewModel.users[index].user.elo + Int(viewModel.sliderValue))ELO")
                                        .font(.caption).foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                                HStack(spacing: 4){
                                    Image(viewModel.statusPiece.lowercased())
                                        .resizable()
                                        .frame(width: 18, height: 26)
                                    Slider(value: $viewModel.sliderValue, in: 0...viewModel.sliderBound, step: 20)
                                    Image(viewModel.nextUnlock.lowercased())
                                        .resizable()
                                        .frame(width: 18, height: 26)
                                        .shadow(color: (viewModel.sliderBound == viewModel.sliderValue) ? .yellow : .clear, radius: 5, x: 0, y: 0)
                                        .shadow(color: (viewModel.sliderBound == viewModel.sliderValue) ? .yellow : .clear, radius: 5, x: 0, y: 0)
                                }
                                HStack(spacing: 20){
                                    Text("\(Int(viewModel.sliderValue)) ELO")
                                        .font(.title2)
                                    Image(systemName: "equal")
                                    Text("\((storeKit.storeProducts.first(where: { $0.id.dropLast(3) == "\(Int(viewModel.sliderValue))" }))?.displayPrice ?? "$0.00") USD")
                                        .font(.title2)
                                }
                                .padding(.bottom, 15)
                                .onChange(of: viewModel.sliderValue, { _, _ in
                                    if storeKit.storeProducts.first(where: { $0.id.dropLast(3) == "\(Int(viewModel.sliderValue))" }) == nil && storeKit.storeProducts.isEmpty {
                                        storeKit.updateEmptyDic()
                                    }
                                })
                                if viewModel.sliderValue > 0 {
                                    if let user = auth.currentUser {
                                        Button {
                                            Task {
                                                if let product = storeKit.storeProducts.first(where: { $0.id.dropLast(3) == "\(Int(viewModel.sliderValue))" }) {
                                                    do {
                                                        let result = try await storeKit.purchase(product)
                                                        if result {
                                                            activateAwardsFuncOnDismiss = true
                                                            viewModel.sliderValue = 0
                                                            if let elo = Int(product.id.dropLast(3)){
                                                                withAnimation {
                                                                    proxy.scrollTo("scrollTop", anchor: .bottom)
                                                                }
                                                                viewModel.updatingElo = true
                                                                configure(elo: user.elo + elo, change: false)
                                                                updateCircle(elo: elo)
                                                            } else {
                                                                if let elo = Int(product.displayName.dropLast(3)){
                                                                    withAnimation {
                                                                        proxy.scrollTo("scrollTop", anchor: .bottom)
                                                                    }
                                                                    viewModel.updatingElo = true
                                                                    configure(elo: user.elo + elo, change: false)
                                                                    updateCircle(elo: elo)
                                                                }
                                                            }
                                                        } else {
                                                            purchaseFailed = true
                                                        }
                                                    } catch {
                                                        purchaseFailed = true
                                                    }
                                                }
                                            }
                                        } label: {
                                            Text("_Buy_").bold().font(.headline).padding(2)
                                                .frame(width: 200)
                                                .background(Color(.systemBlue))
                                                .foregroundColor(.white)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 150).padding(.horizontal, 20)
                        .alert("Purchase failed", isPresented: $purchaseFailed) {
                            Button("Close", role: .cancel) {}
                        }
                    }
                    Color.clear.frame(height: 25)
                }.scrollIndicators(.hidden)
            }
        }
        .dynamicTypeSize(.large)
        .presentationDetents([.fraction(0.9)])
    }
    func updateData() {
        if viewModel.currentUser != nil {
            if selectedFilter == .hustles {
                viewModel.fetchUserTweets(currentUserId: auth.currentUser?.id ?? "")
            } else if selectedFilter == .likes {
                viewModel.fetchLikedTweets()
            } else if selectedFilter == .questions {
                viewModel.fetchUserQuestions(userPhoto: auth.currentUser?.profileImageUrl, isCurrentUser: isMain)
            }
        }
    }
    func photoOffset() -> CGFloat {
        if shiftOffset >= 0 {
            if shiftOffset >= 150 {
                return 0.0
            }
            let ratio = 1 - (shiftOffset / 150)
            
            return ratio * 32.0
        } else {
            return 32.0
        }
    }
    func headerSize() -> CGFloat {
        if shiftOffset > 0.0 {
            let final = abs(shiftOffset)
            if final >= 150 {
                return 85.0
            }
            let ratio = final / 150
            
            return (ratio * 35.0) + 50.0
        } else {
            return 50.0
        }
    }
    func headerBlur() -> CGFloat {
        var final = abs(shiftOffset)
        if final < 35.0 {
            final = 0.0
        }
        if final >= 150 {
            return 18.0
        }
        let ratio = final / 150
        
        return ratio * 18.0
    }
    func backgroundColor(elo: Int) -> Color {
        if elo < 600 {
            return Color(red: 210/255, green: 180/255, blue: 140/255).opacity(0.5)
        } else if elo < 850{
            return Color(red: 210/255, green: 180/255, blue: 140/255).opacity(0.5)
        } else if elo < 1300{
            return .green.opacity(0.7)
        } else if elo < 2000{
            return .yellow.opacity(0.7)
        } else if elo < 2900{
            return .red.opacity(0.7)
        } else {
            return .blue.opacity(0.7)
        }
    }
    func chessPiece(elo: Int) -> some View {
        VStack{
            if elo < 600 {
                Image("pawn")
                    .resizable()
                    .frame(width: 60, height: 90)
            } else if elo < 850{
                Image("bishop")
                    .resizable()
                    .frame(width: 60, height: 100)
            } else if elo < 1300{
                Image("knight")
                    .resizable()
                    .frame(width: 65, height: 100)
            } else if elo < 2000{
                Image("rook")
                    .resizable()
                    .frame(width: 65, height: 95)
            } else if elo < 2900{
                Image("queen")
                    .resizable()
                    .frame(width: 65, height: 110)
            } else if elo >= 2900 {
                Image("king")
                    .resizable()
                    .frame(width: 65, height: 110)
            }
        }
    }
    func configure(elo: Int, change: Bool){
        withAnimation{
            if elo < 600 {
                viewModel.statusPiece = "PAWN"
                viewModel.access = viewModel.pawnAccess
                if change {
                    viewModel.nextPiece = 600 - elo
                    viewModel.nextUnlock = "BISHOP"
                    viewModel.degrees = (1 - (Double(viewModel.nextPiece)) / 600) * 360
                }
                viewModel.nextAccess = viewModel.bishopAccess
                var temp = elo
                while temp < 600 { temp += 20 }
                viewModel.sliderBound = Double(temp - elo)
            }
            else if elo < 850{
                viewModel.statusPiece = "BISHOP"
                viewModel.access = viewModel.bishopAccess
                if change {
                    viewModel.nextPiece = 850 - elo
                    viewModel.nextUnlock = "KNIGHT"
                    viewModel.degrees = (1 - (Double(viewModel.nextPiece)) / 250) * 360
                }
                viewModel.nextAccess = viewModel.knightAccess
                var temp = elo
                while temp < 850 { temp += 20 }
                viewModel.sliderBound = Double(temp - elo)
            }
            else if elo < 1300{
                viewModel.statusPiece = "KNIGHT"
                viewModel.access = viewModel.knightAccess
                if change {
                    viewModel.nextPiece = 1300 - elo
                    viewModel.nextUnlock = "ROOK"
                    viewModel.degrees = (1 - (Double(viewModel.nextPiece)) / 450) * 360
                }
                viewModel.nextAccess = viewModel.rookAccess
                var temp = elo
                while temp < 1300 { temp += 20 }
                viewModel.sliderBound = Double(temp - elo)
            }
            else if elo < 2000{
                viewModel.statusPiece = "ROOK"
                viewModel.access = viewModel.rookAccess
                if change {
                    viewModel.nextPiece = 2000 - elo
                    viewModel.nextUnlock = "QUEEN"
                    viewModel.degrees = (1 - (Double(viewModel.nextPiece)) / 700) * 360
                }
                viewModel.nextAccess = viewModel.queenAcess
                var temp = elo
                while temp < 2000 { temp += 20 }
                viewModel.sliderBound = Double(temp - elo)
            }
            else if elo < 2900{
                viewModel.statusPiece = "QUEEN"
                viewModel.access = viewModel.queenAcess
                if change {
                    viewModel.nextPiece = 2900 - elo
                    viewModel.nextUnlock = "KING"
                    viewModel.degrees = (1 - (Double(viewModel.nextPiece)) / 900) * 360
                }
                viewModel.nextAccess = viewModel.kingAccess
                var temp = elo
                while temp < 2900 { temp += 20 }
                viewModel.sliderBound = Double(temp - elo)
            }
            else if elo >= 2900 {
                viewModel.statusPiece = "KING"
                viewModel.access = viewModel.kingAccess
                if change {
                    viewModel.nextUnlock = "Coming Soon"
                    viewModel.nextPiece = 0
                    viewModel.degrees = 360
                }
                viewModel.nextAccess = viewModel.nextAccess
                viewModel.sliderBound = 100
            }
        }
        viewModel.updatingElo = false
    }
    func updateCircle(elo: Int){
        if let index = viewModel.currentUser {
            let total = viewModel.users[index].user.elo + elo
            var amount = elo
            var degree = 0.0
     
            if amount >= viewModel.nextPiece {
                amount = amount - viewModel.nextPiece
                var width = 0.0
                if total < 850 {
                    width = 250
                } else if total < 1300 {
                    width = 450
                } else if total < 2000 {
                    width = 700
                } else if total < 2900 {
                    width = 900
                }
                degree = (1 - ((width - Double(amount))) / width) * 360
                if total >= 2900 {
                    degree = 360
                }
            } else {
                if total < 600 {
                    degree = (1 - Double(600 - total) / 600) * 360
                } else if total < 850 {
                    degree = (1 - Double(250 - (total - 600)) / 250) * 360
                } else if total < 1300 {
                    degree = (1 - Double(450 - (total - 850)) / 450) * 360
                } else if total < 2000 {
                    degree = (1 - Double(700 - (total - 1300)) / 700) * 360
                } else if total < 2900 {
                    degree = (1 - Double(900 - (total - 2000)) / 900) * 360
                } else {
                    degree = 360
                }
            }
            if degree != 0 {
                var repreats = 0
                let inc = degree / 15
                viewModel.degrees = 0
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    repreats += 1
                    impactFeedbackgenerator.impactOccurred()
                    withAnimation {
                        viewModel.degrees += inc
                    }
                    if repreats == 15 {
                        timer.invalidate()
                        if total < 600 {
                            viewModel.nextPiece = 6010 - total
                            viewModel.nextUnlock = "BISHOP"
                        } else if total < 850{
                            viewModel.nextPiece = 850 - total
                            viewModel.nextUnlock = "KNIGHT"
                        } else if total < 1300 {
                            viewModel.nextPiece = 1300 - total
                            viewModel.nextUnlock = "ROOK"
                        } else if total < 2000{
                            viewModel.nextPiece = 2000 - total
                            viewModel.nextUnlock = "QUEEN"
                        } else if total < 2900{
                            viewModel.nextPiece = 2900 - total
                            viewModel.nextUnlock = "KING"
                        } else if total >= 2900 {
                            viewModel.nextUnlock = "Coming Soon"
                            viewModel.nextPiece = 0
                        }
                    }
                }
            } else {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    impactFeedbackgenerator.impactOccurred()
                    withAnimation {
                        viewModel.degrees += 24
                    }
                    if viewModel.degrees > 360 {
                        timer.invalidate()
                        if total < 600 {
                            viewModel.nextPiece = 600 - total
                            viewModel.nextUnlock = "BISHOP"
                        } else if total < 850{
                            viewModel.nextPiece = 850 - total
                            viewModel.nextUnlock = "KNIGHT"
                        } else if total < 1300{
                            viewModel.nextPiece = 1300 - total
                            viewModel.nextUnlock = "ROOK"
                        } else if total < 2000{
                            viewModel.nextPiece = 2000 - total
                            viewModel.nextUnlock = "QUEEN"
                        } else if total < 2900{
                            viewModel.nextPiece = 2900 - total
                            viewModel.nextUnlock = "KING"
                        } else {
                            viewModel.nextPiece = 0
                            viewModel.nextUnlock = "Coming Soon"
                        }
                        viewModel.degrees = 0
                    }
                }
            }
            viewModel.users[index].user.elo += elo
            auth.currentUser?.elo = total
        }
    }
}

struct profileColors: View {
    @State var rotation: CGFloat = 0.0
    let gradientColors: [Color] = [.purple, .green, .blue]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 90, style: .continuous)
                .frame(width: 42, height: 42)
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .top,
                    endPoint: .bottom))
                .rotationEffect(.degrees(rotation))
                .mask {
                    RoundedRectangle(cornerRadius: 90, style: .continuous)
                        .stroke(lineWidth: 10)
                        .frame(width: 40 / 1.07, height: 40 / 1.07)
                }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
