import SwiftUI
import Kingfisher
import Combine
import Firebase
import CoreLocation

struct replyTo: Equatable {
    let messageID: String
    let selfReply: Bool
}

struct replyToGroup: Equatable {
    let messageID: String
    let selfReply: Bool
    let username: String
}

struct Editing: Equatable {
    let messageID: String
    let originalText: String
}

struct MessagesView: View {
    @FocusState var isFocused: FocusedField?
    @State var replying: replyTo? = nil
    @State var editing: Editing? = nil
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var exploreModel: ExploreViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profileModel: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    let exception: Bool
    let user: User?
    let uid: String
    let tabException: Bool
    let canCall: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var timeBetween = false
    @State var appeared: Bool = false
    @State var showScrollDown: Bool = false
    @State var encyption_val: Bool = true
    @State var show_encyption: Bool = false
    @State var isCollapsed: Bool = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var showFilePicker: Bool = false
    @State var showCameraPicker: Bool = false
    @State var showLibraryPicker: Bool = false
    @State var showMemoryPicker: Bool = false
    @State var sendElo: Bool = false
    @State var seenNowText: String = "Seen last year"
    @State var seenNow: Bool = false
    @State var searchMedia: Bool = false
    @State var addAudio: Bool = false
    @State var isOne: Bool = false
    @State var currentAudio: String = ""
    @State private var offset: Double = 0
    
    @State var searchText: String = ""
    @State var searchLoading: Bool = false
    @State var searchChat: Bool = false
    @FocusState var searchBarFocused: FocusedField?
    @State private var showShareProfileSheet = false
    @State var sendLink: String = ""
    @State var deletingPreventSuggested = false
    
    @State var viewOption = true
    @State var showNewMapMessage = false
    @State var captionBind: String = ""
    @State var disableTopGesture = false
    @State var showStoryProfile = false
    @State var storyProfileID: String = ""
    @State var matchedStocks = [String]()
    
    @Namespace private var animation
    @State var isExpanded: Bool = false
    @State var addPadding: Bool = false
    @State var editOrTagPadding: Bool = false
    @State var addTransition: Bool = false
    
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    private let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    private let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    
    var body: some View {
        ZStack {
            ZStack(alignment: .top){
                if viewOption {
                    VStack {
                        if let index = viewModel.currentChat, index < viewModel.chats.count {
                            GeometryReader { geometry in
                                ScrollViewReader { proxy in
                                    ZStack(alignment: .bottom){
                                        ScrollView {
                                            LazyVStack(spacing: 1){
                                                
                                                let extraPad = (editing != nil || replying != nil) ? 40.0 : 0.0
                                                
                                                Color.clear.frame(height: isKeyboardVisible ? (extraPad + 55.0 + keyboardHeight) : (extraPad + 88.0 + keyboardHeight)).id("scrollDown")
                                                    .onAppear {
                                                        withAnimation(.easeInOut(duration: 0.1)){
                                                            showScrollDown = false
                                                        }
                                                    }
                                                    .onDisappear {
                                                        withAnimation(.easeInOut(duration: 0.1)){
                                                            showScrollDown = true
                                                        }
                                                    }
                                                
                                                if let silent = viewModel.chats[index].user.silent {
                                                    silentView(silent: silent)
                                                }
                                                
                                                let id = auth.currentUser?.id ?? ""
                                                
                                                let isOneMain: Bool = (viewModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? true : false
                                                
                                                if let messages = viewModel.chats[index].messages {
                                                    if messages.isEmpty {
                                                        WaveButtonChat()
                                                            .padding(.bottom, 25)
                                                            .transition(.scale.combined(with: .opacity))
                                                            .rotationEffect(.degrees(180.0))
                                                            .scaleEffect(x: -1, y: 1, anchor: .center)
                                                    }
                                                    ForEach(Array(messages.enumerated()), id: \.element.id) { i, message in
                                                        
                                                        let didRec: Bool = (isOneMain && message.uid_one_did_recieve || !isOneMain && !message.uid_one_did_recieve) ? true : false
                                                        
                                                        if let text = message.text {
                                                            if text.contains(")(*&^%$#@!"){
                                                                if (viewModel.chats[index].convo.uid_one == (auth.currentUser?.id ?? "") && message.uid_one_did_recieve) || (viewModel.chats[index].convo.uid_two == (auth.currentUser?.id ?? "") && !message.uid_one_did_recieve){
                                                                    RequestBubble(message: message)
                                                                        .rotationEffect(.degrees(180.0))
                                                                        .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                } else {
                                                                    MessageBubble(message: Message(uid_one_did_recieve: message.uid_one_did_recieve, seen_by_reciever: true, text: "You sent a request.", timestamp: message.timestamp), is_uid_one: isOneMain, replying: $replying, currentAudio: $currentAudio, recieved: didRec, editing: $editing, searching: $searchChat, viewOption: $viewOption, isExpanded: $isExpanded, animation: animation, addPadding: $addPadding)
                                                                        .rotationEffect(.degrees(180.0))
                                                                        .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                        .id(message.id)
                                                                }
                                                            } else if text.contains("pub!@#$%^&*()"){
                                                                ViewGroupBubble(message: message, is_uid_one: (viewModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? true : false)
                                                                    .rotationEffect(.degrees(180.0))
                                                                    .scaleEffect(x: -1, y: 1, anchor: .center)
                                                            } else if text.contains("priv!@#$%^&*()"){
                                                                if viewModel.chats[index].convo.uid_one == id && message.uid_one_did_recieve {
                                                                    InviteBubble(message: message)
                                                                        .rotationEffect(.degrees(180.0))
                                                                        .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                } else if (viewModel.chats[index].convo.uid_two == id && !message.uid_one_did_recieve) {
                                                                    InviteBubble(message: message)
                                                                        .rotationEffect(.degrees(180.0))
                                                                        .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                } else {
                                                                    MessageBubble(message: Message(id: message.id ?? "", uid_one_did_recieve: message.uid_one_did_recieve, seen_by_reciever: true, text: "You sent a group Invite.", timestamp: message.timestamp), is_uid_one: isOneMain, replying: $replying, currentAudio: $currentAudio, recieved: didRec, editing: $editing, searching: $searchChat, viewOption: $viewOption, isExpanded: $isExpanded, animation: animation, addPadding: $addPadding)
                                                                        .rotationEffect(.degrees(180.0))
                                                                        .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                        .id(message.id)
                                                                }
                                                            } else {
                                                                MessageBubble(message: message, is_uid_one: isOneMain, replying: $replying, currentAudio: $currentAudio, recieved: didRec, editing: $editing, searching: $searchChat, viewOption: $viewOption, isExpanded: $isExpanded, animation: animation, addPadding: $addPadding)
                                                                    .rotationEffect(.degrees(180.0))
                                                                    .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                    .id(message.id)
                                                                    .overlay(GeometryReader { proxy in
                                                                        Color.clear
                                                                            .onChange(of: offset, { _, _ in
                                                                                if let vid_id = message.videoURL, let id = message.id, popRoot.currentSound.isEmpty {
                                                                                    let frame = proxy.frame(in: .global)
                                                                                    let bottomDistance = frame.minY - geometry.frame(in: .global).minY
                                                                                    let topDistance = geometry.frame(in: .global).maxY - frame.maxY
                                                                                    let diff = bottomDistance - topDistance
                                                                                    
                                                                                    if (bottomDistance < 0.0 && abs(bottomDistance) >= (frame.height / 2.0)) || (topDistance < 0.0 && abs(topDistance) >= (frame.height / 2.0)) {
                                                                                        if currentAudio == vid_id + id {
                                                                                            currentAudio = ""
                                                                                        }
                                                                                    } else if abs(diff) < 140 && abs(diff) > -140 {
                                                                                        currentAudio = vid_id + id
                                                                                    }
                                                                                }
                                                                            })
                                                                    })
                                                            }
                                                        } else {
                                                            MessageBubble(message: message, is_uid_one: isOneMain, replying: $replying, currentAudio: $currentAudio, recieved: didRec, editing: $editing, searching: $searchChat, viewOption: $viewOption, isExpanded: $isExpanded, animation: animation, addPadding: $addPadding)
                                                                .rotationEffect(.degrees(180.0))
                                                                .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                .id(message.id)
                                                                .overlay(GeometryReader { proxy in
                                                                    Color.clear
                                                                        .onChange(of: offset, { _, _ in
                                                                            if let vid_id = message.videoURL, let id = message.id, popRoot.currentSound.isEmpty {
                                                                                let frame = proxy.frame(in: .global)
                                                                                let bottomDistance = frame.minY - geometry.frame(in: .global).minY
                                                                                let topDistance = geometry.frame(in: .global).maxY - frame.maxY
                                                                                let diff = bottomDistance - topDistance
                                                                                
                                                                                if (bottomDistance < 0.0 && abs(bottomDistance) >= (frame.height / 2.0)) || (topDistance < 0.0 && abs(topDistance) >= (frame.height / 2.0)) {
                                                                                    if currentAudio == vid_id + id {
                                                                                        currentAudio = ""
                                                                                    }
                                                                                } else if abs(diff) < 140 && abs(diff) > -140 {
                                                                                    currentAudio = vid_id + id
                                                                                }
                                                                            }
                                                                        })
                                                                })
                                                        }
                                                        
                                                        if let dateStr = getString(forInt: i) {
                                                            HStack{
                                                                Spacer()
                                                                Text(dateStr)
                                                                    .font(.subheadline)
                                                                    .padding(.horizontal, 12).padding(.vertical, 5)
                                                                    .background(.gray.opacity(0.2))
                                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                                    .rotationEffect(.degrees(180.0))
                                                                    .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                Spacer()
                                                            }.padding(.vertical, 7)
                                                        }
                                                        if let newPos = viewModel.newIndex, newPos == i {
                                                            NewChatLine()
                                                                .rotationEffect(.degrees(180.0))
                                                                .scaleEffect(x: -1, y: 1, anchor: .center)
                                                        }
                                                    }
                                                    Color.clear.frame(height: 100)
                                                    Color.clear
                                                        .frame(height: 2)
                                                        .onAppear {
                                                            if messages.count > 15 {
                                                                if timeBetween {
                                                                    timeBetween = false
                                                                    viewModel.getMessagesOld()
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                                                                        timeBetween = true
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    
                                                }
                                            }
                                            .padding(.vertical, 8)
                                            .background(GeometryReader {
                                                Color.clear.preference(key: ViewOffsetKey.self,
                                                                       value: -$0.frame(in: .named("scroll")).origin.y)
                                            })
                                            .onPreferenceChange(ViewOffsetKey.self) { value in
                                                offset = value
                                            }
                                        }
                                        .contentMargins(.top, 85.0, for: .scrollIndicators)
                                        .coordinateSpace(name: "scroll")
                                        .scrollDismissesKeyboard(.immediately)
                                        .rotationEffect(.degrees(180.0))
                                        .scaleEffect(x: -1, y: 1, anchor: .center)
                                        .ignoresSafeArea(.keyboard)
                                        .background(colorScheme == .dark ? .black : .white)
                                        .animation(.easeOut(duration: 0.2), value: keyboardHeight)
                                        .onChange(of: viewModel.scrollToReply) { _, new in
                                            if !new.isEmpty {
                                                withAnimation(.linear(duration: 0.2)){
                                                    proxy.scrollTo(new, anchor: .center)
                                                }
                                            }
                                        }
                                        .onChange(of: viewModel.scrollToReplyNow) { _, new in
                                            if !new.isEmpty {
                                                withAnimation(.linear(duration: 0.1)){
                                                    proxy.scrollTo(new, anchor: .center)
                                                }
                                            }
                                        }
                                        
                                        if showScrollDown {
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.15)){
                                                    proxy.scrollTo("scrollDown", anchor: .bottom)
                                                }
                                                withAnimation(.easeInOut(duration: 0.1)){
                                                    showScrollDown = false
                                                }
                                            } label: {
                                                ZStack {
                                                    Circle().foregroundStyle(colorScheme == .dark ? Color(red: 0.5, green: 0.6, blue: 1.0) : .indigo)
                                                    Image(systemName: "chevron.down")
                                                        .font(.title3).foregroundStyle(.white).offset(y: 1)
                                                }
                                                .frame(width: 39, height: 39)
                                                .shadow(color: .gray, radius: 1)
                                            }
                                            .padding(.bottom, isKeyboardVisible ? (80.0 + keyboardHeight) : (105.0 + keyboardHeight)).transition(.scale)
                                            .padding(.bottom, (editing != nil || replying != nil) ? 40.0 : 0.0)
                                        }
                                    }
                                }
                            }.ignoresSafeArea()
                        }
                        if let index = viewModel.currentChat, index < viewModel.chats.count {
                            if !((auth.currentUser?.elo ?? 0) >= 2900 || viewModel.chats[index].user.dev == nil) {
                                HStack {
                                    Spacer()
                                    Text("Only Developer can message.").font(.headline)
                                    Spacer()
                                }
                                .ignoresSafeArea()
                                .frame(height: 80)
                                .background(.ultraThickMaterial)
                            }
                        }
                    }
                    .disabled(show_encyption)
                    .blur(radius: show_encyption ? 5 : 0)
                    .transition(.move(edge: .top))
                } else if let index = viewModel.currentChat {
                    SwiftfulMapAppApp(disableTopGesture: $disableTopGesture, option: .constant(3), chatUsers: [viewModel.chats[index].user], close: { num in
                        if num == 9 {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            withAnimation(.easeIn(duration: 0.15)){
                                viewOption = true
                            }
                        }
                    })
                    .disabled(show_encyption)
                    .blur(radius: show_encyption ? 5 : 0)
                    .transition(.move(edge: .bottom))
                    .ignoresSafeArea(.keyboard)
                }
                
                if !disableTopGesture {
                    headerView()
                        .ignoresSafeArea()
                        .disabled(show_encyption)
                        .blur(radius: show_encyption ? 5 : 0)
                        .transition(.move(edge: .top))
                }
                
                if let index = viewModel.currentChat, viewModel.chats[index].messages == nil {
                    VStack {
                        Spacer()
                        LottieView(loopMode: .loop, name: "loaderMessage")
                            .scaleEffect(0.5)
                            .frame(width: 50,height: 50)
                            .padding(.top, 115)
                        Spacer()
                    }
                }
                if show_encyption {
                    encryptionView()
                }
            }
        }
        .overlay(content: {
            if isExpanded {
                if profileModel.mid == "MainStory" {
                    MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: profileModel.mid, isHome: false, canOpenChat: popRoot.tab == 5, canOpenProfile: true, openChat: { uid in
                        viewModel.userMapID = uid
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                            viewModel.navigateUserMap = true
                        }
                    }, openProfile: { uid in
                        storyProfileID = uid
                        showStoryProfile = true
                    })
                    .transition(.scale).ignoresSafeArea()
                    .onAppear(perform: { currentAudio = "" })
                    .onDisappear { addPadding = false }
                } else {
                    MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: profileModel.mid, isHome: false, canOpenChat: popRoot.tab == 5, canOpenProfile: true, openChat: { uid in
                        viewModel.userMapID = uid
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                            viewModel.navigateUserMap = true
                        }
                    }, openProfile: { uid in
                        storyProfileID = uid
                        showStoryProfile = true
                    })
                    .ignoresSafeArea()
                    .onAppear(perform: { currentAudio = "" })
                    .onDisappear { addPadding = false }
                }
            }
        })
        .ignoresSafeArea(edges: addPadding ? .all : [])
        .fullScreenCover(isPresented: $searchMedia, content: {
            MessagesMediaSearch(allMessages: viewModel.chats[viewModel.currentChat ?? 0].messages ?? [], replying: $replying)
        })
        .onChange(of: replying) { _, _ in
            if replying != nil {
                isFocused = .one
            }
        }
        .onChange(of: editing) { _, _ in
            if editing != nil {
                isFocused = .one
            }
        }
        .sheet(isPresented: $showShareProfileSheet, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .overlay(alignment: .bottom, content: {
            if let index = viewModel.currentChat, index < viewModel.chats.count && !isExpanded && viewOption {
                if (auth.currentUser?.elo ?? 0) >= 2900 || viewModel.chats[index].user.dev == nil {
                    HStack {
                        Spacer()
                        MessagesField(showFilePicker: $showFilePicker, showCameraPicker: $showCameraPicker, showLibraryPicker: $showLibraryPicker, sendElo: $sendElo, isFocused: $isFocused, replying: $replying, addAudio: $addAudio, editing: $editing, currentAudio: $currentAudio, searchText: $searchText, showSearch: $searchChat, showMemoryPicker: $showMemoryPicker, captionBind: $captionBind, matchedStocks: $matchedStocks)
                    }
                    .padding(.top, 5)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
                    .animation(.easeInOut(duration: 0.2), value: matchedStocks)
                }
            }
        })
        .overlay {
            if let index = viewModel.currentChat, !searchChat && viewOption && !isExpanded {
                if ((auth.currentUser?.elo ?? 0) >= 2900) || (viewModel.chats[index].user.dev == nil && viewModel.chats[index].user.id ?? "" != "lQTwtFUrOMXem7UXesJbDMLbV902"){
                    LiquidMenuButtons(isCollapsed: $isCollapsed, showFilePicker: $showFilePicker, showCameraPicker: $showCameraPicker, showLibraryPicker: $showLibraryPicker, sendElo: $sendElo, addAudio: $addAudio, isChat: true, showMemoryPicker: $showMemoryPicker, captionBind: $captionBind)
                        .disabled(show_encyption)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            addKeyboardObservers()
            viewModel.start(user: user, uid: uid, pointers: auth.currentUser?.myMessages ?? [])
            appeared = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                timeBetween = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                if let index = viewModel.currentChat, appeared {
                    withAnimation {
                        self.isOne = (auth.currentUser?.id ?? "") == viewModel.chats[index].convo.uid_one
                    }
                }
            }
            
            viewModel.timeRemaining = 7.0
            setSeenNow()
        }
        .onReceive(timer) { _ in
            if appeared && scenePhase == .active && !searchMedia {
                viewModel.timeRemaining -= 1
                if viewModel.timeRemaining == 0 {
                    viewModel.getMessagesNew(initialFetch: false)
                    viewModel.timeRemaining = 4.0
                }
            }
        }
        .onDisappear {
            removeKeyboardObservers()
            appeared = false
            leaveView()
        }
        .onChange(of: viewModel.groupsToAdd) { _, _ in
            if !viewModel.groupsToAdd.isEmpty {
                viewModel.groupsToAdd.forEach { group in
                    if !exploreModel.joinedGroups.contains(group) {
                        if exploreModel.joinedGroups.isEmpty{
                            exploreModel.joinedGroups = [group]
                        } else {
                            exploreModel.joinedGroups.append(group)
                        }
                        auth.currentUser?.pinnedGroups.append(group.id)
                    }
                }
                viewModel.groupsToAdd = []
            }
        }
        .onChange(of: popRoot.tap) { _, _ in
            if popRoot.tap == 5 {
                leaveView()
                popRoot.tap = 0
            }
        }
        .navigationDestination(isPresented: $showStoryProfile) {
            ProfileView(showSettings: false, showMessaging: false, uid: storyProfileID, photo: "", user: nil, expand: true, isMain: false)
                .dynamicTypeSize(.large).enableFullSwipePop(true)
        }
    }
    private func addKeyboardObservers() {
        keyboardWillShow
            .merge(with: keyboardWillHide)
            .sink { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation {
                        isKeyboardVisible = notification.name == UIResponder.keyboardWillShowNotification
                        keyboardHeight = isKeyboardVisible ? keyboardFrame.height : 0
                    }
                }
            }
            .store(in: &cancellables)
    }
    private func removeKeyboardObservers() {
        cancellables.removeAll()
    }
    func hasStories() -> Bool {
        if let index = viewModel.currentChat, index < viewModel.chats.count {
            let uid = viewModel.chats[index].user.id
            return !(profileModel.users.first(where: { $0.user.id == uid })?.stories ?? []).isEmpty
        }
        return false
    }
    func setupStory() {
        if let index = viewModel.currentChat, index < viewModel.chats.count {
            let uid = viewModel.chats[index].user.id
            if let stories = profileModel.users.first(where: { $0.user.id == uid })?.stories {
                profileModel.selectedStories = stories
            }
        }
    }
    func storiesLeftToSee() -> Bool {
        if let index = viewModel.currentChat, index < viewModel.chats.count {
            if let uid = auth.currentUser?.id, let otherUID = viewModel.chats[index].user.id {
                if otherUID == uid {
                    return false
                }
                if let stories = profileModel.users.first(where: { $0.user.id == otherUID })?.stories {
                    for i in 0..<stories.count {
                        if let sid = stories[i].id {
                            if !viewModel.viewedStories.contains(where: { $0.0 == sid }) && !(stories[i].views ?? []).contains(where: { $0.contains(uid) }) {
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 20){
            HStack(spacing: 0){
                ZStack {
                    Rectangle().frame(width: 25, height: 25).foregroundStyle(.gray).opacity(0.001)
                    Image(systemName: "chevron.backward").font(.system(size: 22)).bold()
                }
                .frame(width: 30, height: 25)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    presentationMode.wrappedValue.dismiss()
                }
                .padding(.trailing, 8)
                
                if let index = viewModel.currentChat, index < viewModel.chats.count {
                    let user = viewModel.chats[index].user
                    let hasStory = hasStories()
                    HStack(spacing: 8){
                        if hasStory {
                            ZStack {
                                StoryRingView(size: 51, active: storiesLeftToSee(), strokeSize: 2.0)
                                
                                let size = (isExpanded && profileModel.mid == "MainStory") ? 200 : 41.0
                                GeometryReader { _ in
                                    ZStack {
                                        personLetterViewColor(size: size, letter: String(user.fullname.first ?? Character("M")), color: viewModel.chats[index].color)
                                        
                                        if let image = user.profileImageUrl {
                                            KFImage(URL(string: image))
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .scaledToFill()
                                                .clipShape(Circle())
                                                .frame(width: size, height: size)
                                        }
                                    }.opacity((isExpanded && profileModel.mid == "MainStory") ? 0.0 : 1.0)
                                }
                                .matchedGeometryEffect(id: "MainStory", in: animation, anchor: .top)
                                .frame(width: 41, height: 41)
                                .onTapGesture {
                                    addPadding = true
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    setupStory()
                                    profileModel.mid = "MainStory"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            isExpanded = true
                                        }
                                    }
                                }
                            }
                            
                            NavigationLink {
                                ProfileView(showSettings: false, showMessaging: false, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: true, isMain: false)
                                    .dynamicTypeSize(.large).enableFullSwipePop(true)
                            } label: {
                                VStack(alignment: .leading, spacing: 2){
                                    HStack(spacing: 3){
                                        if let silent = user.silent {
                                            if silent == 1 {
                                                Circle().foregroundStyle(.green).frame(width: 7, height: 7)
                                            } else if silent == 2 {
                                                Image(systemName: "moon.fill").foregroundStyle(.yellow).font(.headline)
                                            } else if silent == 3 {
                                                Image(systemName: "slash.circle.fill").foregroundStyle(.red).font(.headline)
                                            } else {
                                                Image("ghostMode")
                                                    .resizable().scaledToFit().frame(width: 14, height: 14).scaleEffect(1.3)
                                            }
                                        } else if seenNow {
                                            Circle().foregroundStyle(.green).frame(width: 7, height: 7)
                                        }
                                        
                                        Text(user.fullname)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .font(.headline).bold().lineLimit(1).minimumScaleFactor(0.8)
                                        Spacer()
                                    }
                                    Text(seenNowText).font(.caption).lineLimit(1).minimumScaleFactor(0.6)
                                }
                            }.disabled(popRoot.tab != 5 && !exception ? true : false)
                        } else {
                            NavigationLink {
                                ProfileView(showSettings: false, showMessaging: false, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: true, isMain: false)
                                    .dynamicTypeSize(.large).enableFullSwipePop(true)
                            } label: {
                                HStack(spacing: 8){
                                    if let image = user.profileImageUrl {
                                        ZStack {
                                            personLetterViewColor(size: 45, letter: String(user.fullname.first ?? Character("M")), color: viewModel.chats[index].color)
                                            KFImage(URL(string: image))
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 45, height: 45)
                                                .clipShape(Circle())
                                        }
                                    } else {
                                        personLetterViewColor(size: 45, letter: String(user.fullname.first ?? Character("M")), color: viewModel.chats[index].color)
                                    }
                                    VStack(alignment: .leading, spacing: 2){
                                        HStack(spacing: 3){
                                            if let silent = user.silent {
                                                if silent == 1 {
                                                    Circle().foregroundStyle(.green).frame(width: 7, height: 7)
                                                } else if silent == 2 {
                                                    Image(systemName: "moon.fill").foregroundStyle(.yellow).font(.headline)
                                                } else if silent == 3 {
                                                    Image(systemName: "slash.circle.fill").foregroundStyle(.red).font(.headline)
                                                } else {
                                                    Image("ghostMode")
                                                        .resizable().scaledToFit().frame(width: 14, height: 14).scaleEffect(1.3)
                                                }
                                            } else if seenNow {
                                                Circle().foregroundStyle(.green).frame(width: 7, height: 7)
                                            }
                                            
                                            Text(user.fullname)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .font(.headline).bold().lineLimit(1).minimumScaleFactor(0.8)
                                            Spacer()
                                        }
                                        Text(seenNowText).font(.caption).lineLimit(1).minimumScaleFactor(0.6)
                                    }
                                }
                            }.disabled(popRoot.tab != 5 && !exception ? true : false)
                        }
                    }
                    .padding(.bottom, hasStory ? 5 : 3)
                    .onAppear(perform: {
                        profileModel.updateStoriesUser(user: viewModel.chats[index].user)
                    })
                }
                
                Spacer()
                
                if let index = viewModel.currentChat, viewModel.chats[index].user.dev == nil {
                    Menu {
                        Button(role: .destructive, action: {
                            deletingPreventSuggested = true
                            presentationMode.wrappedValue.dismiss()
                            if let all = auth.currentUser?.pinnedChats, let id = viewModel.chats[index].convo.id, all.contains(id) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    auth.currentUser?.pinnedChats?.removeAll(where: { $0 == id })
                                }
                                UserService().removeChatPin(id: id)
                            }
                            viewModel.deleteConvo(docID: viewModel.chats[index].convo.id ?? "")
                            auth.currentUser?.myMessages.removeAll(where: { $0 ==  viewModel.chats[index].convo.id ?? ""})
                            viewModel.chats.remove(at: index)
                        }) {
                            Label("Delete Chat", systemImage: "trash")
                        }
                        Button(role: .cancel, action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            if let docId = viewModel.chats[index].convo.id {
                                
                                let isUidOne = (auth.currentUser?.id ?? "") == viewModel.chats[index].convo.uid_one
                                
                                if (viewModel.chats[index].convo.uid_one_sharing_location ?? false && isUidOne) || (viewModel.chats[index].convo.uid_two_sharing_location ?? false && !isUidOne){
                                    MessageService().shareLocation(docID: docId, shareBool: false, isUidOne: isUidOne)
                                    popRoot.alertReason = "Stopped Sharing Live"
                                    if isUidOne {
                                        viewModel.chats[index].convo.uid_one_sharing_location = false
                                    } else {
                                        viewModel.chats[index].convo.uid_two_sharing_location = false
                                    }
                                } else {
                                    MessageService().shareLocation(docID: docId, shareBool: true, isUidOne: isUidOne)
                                    popRoot.alertReason = "Live Location Shared!"
                                    if isUidOne {
                                        viewModel.chats[index].convo.uid_one_sharing_location = true
                                    } else {
                                        viewModel.chats[index].convo.uid_two_sharing_location = true
                                    }
                                }
                                popRoot.alertImage = "checkmark.seal"
                            } else {
                                popRoot.alertReason = "Error updating value"
                                popRoot.alertImage = "exclamationmark.triangle.fill"
                            }
                            withAnimation(.easeInOut(duration: 0.15)){
                                popRoot.showAlert = true
                            }
                        }) {
                            let isUidOne = (auth.currentUser?.id ?? "") == viewModel.chats[index].convo.uid_one
                            
                            if (viewModel.chats[index].convo.uid_one_sharing_location ?? false && isUidOne) || (viewModel.chats[index].convo.uid_two_sharing_location ?? false && !isUidOne){
                                Label("Stop Sharing Live", systemImage: "globe")
                            } else {
                                Label("Share Live Location", systemImage: "globe")
                            }
                        }
                        Divider()
                        Button {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            encyption_val = viewModel.chats[index].convo.encrypted
                            withAnimation(.easeInOut){
                                show_encyption.toggle()
                            }
                        } label: {
                            Label("Encryption", systemImage: "lock")
                        }
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label("Mute", systemImage: "speaker.slash")
                        }
                        Divider()
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            searchMedia = true
                        } label: {
                            Label("Search Media", systemImage: "photo.stack.fill")
                        }
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeIn(duration: 0.1)){
                                viewOption = true
                                searchChat = true
                            }
                            searchBarFocused = .one
                        } label: {
                            Label("Search Messages", systemImage: "magnifyingglass")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle").font(.system(size: 23)).fontWeight(.semibold)
                    }.padding(.trailing, 25)
                    Menu {
                        Button {
                            //call
                        } label: {
                            Label("Audio Call", systemImage: "phone")
                        }
                        Button {
                            //call
                        } label: {
                            Label("Video Call", systemImage: "video")
                        }
                    } label: {
                        Image(systemName: "video").font(.system(size: 22)).fontWeight(.semibold)
                    }
                    .disabled(!canCall).padding(.trailing, 10)
                    .onChange(of: viewModel.chats[index].lastM) { _, newValue in
                        if let last = newValue, !viewOption {
                            let isOneMain: Bool = (viewModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? true : false
                            
                            let didRec: Bool = (isOneMain && last.uid_one_did_recieve || !isOneMain && !last.uid_one_did_recieve) ? true : false
                            
                            if didRec {
                                withAnimation(.easeIn(duration: 0.3)){
                                    showNewMapMessage = true
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, top_Inset())
            .background(content: {
                ZStack {
                    TransparentBlurView(removeAllFilters: true)
                        .blur(radius: 12, opaque: true)
                        .background(colorScheme == .dark ? .orange.opacity(0.5) : .orange.opacity(0.4))
                        .ignoresSafeArea()
                    TransparentBlurView(removeAllFilters: true)
                        .blur(radius: 2, opaque: true)
                        .background(colorScheme == .dark ? .black.opacity(0.6) : .white.opacity(0.4))
                        .ignoresSafeArea()
                }.ignoresSafeArea()
            })
            .overlay(alignment: .bottom, content: {
                Divider()
            })
            .overlay {
                if searchChat {
                    searchHeader()
                }
            }
            if let index = viewModel.currentChat, ((!showScrollDown && !searchChat) || !viewOption) && viewModel.chats[index].user.dev == nil {
                HStack {
                    if viewOption {
                        Spacer()
                    }
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)){
                            viewOption.toggle()
                            showNewMapMessage = false
                        }
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    } label: {
                        ZStack {
                            if showNewMapMessage {
                                Text("New!")
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .transition(.scale.combined(with: .identity))
                                    .lineLimit(3)
                                    .truncationMode(.tail)
                            } else {
                                Image(systemName: viewOption ? "globe" : "chevron.up")
                                    .contentTransition(.symbolEffect(.replace))
                                    .font(.title3).foregroundStyle(.white)
                            }
                        }
                        .frame(minWidth: 40, minHeight: 40)
                        .background(colorScheme == .dark ? Color(red: 0.5, green: 0.6, blue: 1.0) : .indigo)
                        .clipShape(RoundedRectangle(cornerRadius: showNewMapMessage ? 12 : 50))
                        .shadow(color: .gray, radius: 2)
                    }.offset(y: -10).transition(.scale)
                    Spacer()
                }.padding(.horizontal)
            }
        }
    }
    @ViewBuilder
    func silentView(silent: Int) -> some View {
        VStack {
            if let index = viewModel.currentChat {
                if silent == 2 {
                    VStack(spacing: 6){
                        HStack(spacing: 4){
                            Spacer()
                            Image(systemName: "moon.fill")
                            Text("\(viewModel.chats[index].user.username) has notifications silenced")
                            Spacer()
                        }
                        
                        if let last = viewModel.chats[index].lastM, (viewModel.chats[index].lastN ?? "").isEmpty {
                            if (isOne && !last.uid_one_did_recieve) || (!isOne && last.uid_one_did_recieve) {
                                let thirtySecondsAgo = Date(timeIntervalSinceNow: -60)
                                if last.timestamp.dateValue() > thirtySecondsAgo {
                                    HStack {
                                        Spacer()
                                        Button {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            withAnimation {
                                                viewModel.chats[index].lastN = last.id
                                            }
                                        } label: {
                                            Text("Notify Anyways").bold()
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .font(.subheadline)
                    .padding(.vertical).foregroundStyle(Color(red: 0.5, green: 0.6, blue: 1.0))
                    .rotationEffect(.degrees(180.0))
                    .scaleEffect(x: -1, y: 1, anchor: .center)
                } else if silent == 3 {
                    HStack(spacing: 4){
                        Spacer()
                        Image(systemName: "slash.circle.fill")
                        Text("\(viewModel.chats[index].user.username) has notifications muted")
                        Spacer()
                    }
                    .font(.subheadline)
                    .padding(.vertical).foregroundStyle(Color(red: 0.5, green: 0.6, blue: 1.0))
                    .rotationEffect(.degrees(180.0))
                    .scaleEffect(x: -1, y: 1, anchor: .center)
                }
            }
        }
    }
    @ViewBuilder
    func searchHeader() -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10){
                TextField("Search Chat", text: $searchText)
                    .tint(.blue)
                    .autocorrectionDisabled(true)
                    .padding(8)
                    .padding(.horizontal, 24)
                    .background(.gray.opacity(0.25))
                    .cornerRadius(12)
                    .focused($searchBarFocused, equals: .one)
                    .onSubmit {
                        searchBarFocused = .two
                        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            searchLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                                searchLoading = false
                            }
                        }
                    }
                    .overlay (
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            Spacer()
                            if searchLoading {
                                ProgressView().padding(.trailing, 10)
                            } else if !searchText.isEmpty {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    searchText = ""
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
                    searchBarFocused = .two
                    searchText = ""
                    withAnimation(.easeInOut(duration: 0.2)){
                        searchChat = false
                    }
                }, label: {
                    Text("Cancel").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).fontWeight(.semibold)
                })
            }.padding(.bottom, 8)
        }
        .ignoresSafeArea()
        .padding(.horizontal, 12)
        .background(.ultraThickMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    func setSeenNow(){
        if let index = viewModel.currentChat {
            if (viewModel.chats[index].user.silent ?? 0) == 4 {
                seenNowText = "Ghost mode"
                seenNow = false
                return
            }
            if let lastTime = viewModel.chats[index].user.lastSeen {
                let dateString = lastTime.dateValue().formatted(.dateTime.month().day().year().hour().minute())
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
                if let date = dateFormatter.date(from:dateString){
                    if Calendar.current.isDateInToday(date){
                        
                        let currentDate = Date()
                        let timeInterval = currentDate.timeIntervalSince(lastTime.dateValue())
                        let fiveMinute: TimeInterval = 300
                        
                        if timeInterval < fiveMinute {
                            seenNowText = "Seen now"
                        } else {
                            seenNowText = "Seen at " + lastTime.dateValue().formatted(.dateTime.hour().minute())
                        }
                        seenNow = true
                        if let locStr = viewModel.chats[index].user.currentLocation, let loc = extractLatLong(from: locStr) {
                            let location = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
                            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                                if error != nil { return }
                                
                                if let placemark = placemarks?.first, let city = placemark.locality {
                                    seenNowText += " - \(city)"
                                }
                            }
                        }
                    } else if Calendar.current.isDateInYesterday(date) {
                        seenNowText = "Seen yesterday"
                        seenNow = false
                    } else {
                        seenNow = false
                        if let dayBetween  = Calendar.current.dateComponents([.day], from: lastTime.dateValue(), to: Date()).day {
                            if dayBetween < 30 {
                                seenNowText = "Seen \(dayBetween) days ago"
                            } else if dayBetween < 365 {
                                seenNowText = "Seen last month"
                            } else {
                                seenNowText = "Seen last year"
                            }
                        }
                    }
                } else {
                    seenNowText = "Seen last year"
                    seenNow = false
                }
            } else {
                seenNowText = "AFK"
                seenNow = false
            }
        }
    }
    func leaveView(){
        viewModel.newIndex = nil
        if popRoot.tab != 5 && tabException {
            withAnimation(.spring()){
                popRoot.hideTabBar = false
            }
        }
        if let index = viewModel.currentChat {
            viewModel.currentChat = nil
            if (viewModel.chats[index].convo.uid_one == (auth.currentUser?.id ?? "") && viewModel.chats[index].lastM?.uid_one_did_recieve ?? false) || (viewModel.chats[index].convo.uid_two == (auth.currentUser?.id ?? "") && !(viewModel.chats[index].lastM?.uid_one_did_recieve ?? false)){
                if !(viewModel.chats[index].lastM?.seen_by_reciever ?? false) {
                    viewModel.seen(docID: viewModel.chats[index].convo.id ?? "", textId: viewModel.chats[index].lastM?.id ?? "")
                    viewModel.chats[index].lastM?.seen_by_reciever = true
                    if let id = viewModel.chats[index].lastM?.id, let firstID = viewModel.chats[index].messages?.first?.id, firstID == id {
                        viewModel.chats[index].messages?[0].seen_by_reciever = true
                    }
                }
            }
            if !deletingPreventSuggested {
                if let messages = viewModel.chats[index].messages {
                    if messages.isEmpty {
                        if !viewModel.suggestedChats.contains(where: { $0.user.id == viewModel.chats[index].user.id }) {
                            viewModel.suggestedChats.insert(viewModel.chats[index], at: 0)
                        }
                        viewModel.chats.remove(at: index)
                    } else {
                        viewModel.suggestedChats.removeAll(where: { $0.user.id == viewModel.chats[index].user.id })
                    }
                } else {
                    if !viewModel.suggestedChats.contains(where: { $0.user.id == viewModel.chats[index].user.id }) {
                        viewModel.suggestedChats.insert(viewModel.chats[index], at: 0)
                    }
                    viewModel.chats.remove(at: index)
                }
            }
            viewModel.dayArr = []
        }
    }
    func getString(forInt: Int) -> String? {
        for tuple in viewModel.dayArr {
            if tuple.0 == forInt {
                return tuple.1
            }
        }
        return nil
    }
    func encryptionView() -> some View {
        VStack {
            Spacer()
            ZStack {
                Color.white.opacity(0.01).ignoresSafeArea()
                    .onTapGesture { if show_encyption { withAnimation(.easeInOut) { show_encyption = false } } }
                ZStack {
                    VStack{
                        ZStack{
                            HStack {
                                Text("Encrypted").font(.system(size: 26)).bold()
                                    .foregroundColor(colorScheme == .dark ? Color(red: 0.5, green: 0.6, blue: 1.0) : .indigo)
                                Spacer()
                            }
                            HStack{
                                Spacer()
                                Toggle("", isOn: $encyption_val).tint(.green)
                            }.padding(.trailing, 5)
                        }.padding(.horizontal, 8).padding(.top, 8)
                        HStack(alignment: .center){
                            VStack(alignment: .leading){
                                Text("-Messages are end-to-end encrypted by default.").font(.system(size: 15))
                                Spacer()
                                Text("-Changes you make will reflect for the other user.").font(.system(size: 15))
                                Spacer()
                                Text("-This feature only allows your iCloud devices along with the recipiant's to view chats.").font(.system(size: 15))
                                Spacer()
                                Text("-Having iCloud Keychain disabled will prevent you from viewing chats on other iCloud devices.")
                                    .font(.system(size: 15))
                                Spacer()
                                Text("-Disabling this feature maintains 256-bit Advanced Encryption for your chats and enables access on any logged-in device.").font(.system(size: 15))
                            }
                        }
                        .padding(.horizontal, 4)
                        .onTapGesture { if show_encyption { withAnimation(.easeInOut) { show_encyption = false } } }
                        Spacer()
                        if let i = viewModel.currentChat {
                            Button {
                                if encyption_val != viewModel.chats[i].convo.encrypted {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    viewModel.setEncyption(value: encyption_val)
                                    viewModel.chats[i].convo.encrypted = encyption_val
                                    withAnimation(.easeInOut) { show_encyption = false }
                                }
                            } label: {
                                Text("Save")
                                    .fontWeight(.heavy)
                                    .blur(radius: (encyption_val != viewModel.chats[i].convo.encrypted) ? 0 : 2)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                                    .background(colorScheme == .dark ? Color(red: 0.5, green: 0.6, blue: 1.0) : .indigo)
                                    .cornerRadius(12)
                                    .padding()
                            }
                        }
                    }
                }
                .background(colorScheme == .dark ? Color(.darkGray).opacity(0.9) : Color(.lightGray).opacity(0.9))
                .cornerRadius(12)
                .frame(width: widthOrHeight(width: true) * 0.8, height: 410)
            }
            Spacer()
        }
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
