import SwiftUI
import Kingfisher
import Combine
import Firebase

struct GroupChatView: View {
    @FocusState var isFocused: Bool
    @State var replying: replyToGroup? = nil
    @State var editing: Editing? = nil
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: GroupChatViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profileModel: ProfileViewModel
    @EnvironmentObject var messagaModel: MessageViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.presentationMode) var presentationMode
    @State private var timeBetween = false
    @State var appeared: Bool = false
    @State var showScrollDown: Bool = false
    @State var isCollapsed: Bool = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var showFilePicker: Bool = false
    @State var showCameraPicker: Bool = false
    @State var showLibraryPicker: Bool = false
    @State var showMemoryPicker: Bool = false
    @State var addAudio: Bool = false
    @State var showAudioRoom: Bool = false
    @State var muted: Bool = false
    let groupID: String
    @State var startDate = "Chat Since"
    @State var showSettings = false
    @State var currentAudio: String = ""
    @State var showUser: Bool = false
    @State var selectedUser: User? = nil
    @State private var offset: Double = 0

    @State var searchText: String = ""
    @State var searchLoading: Bool = false
    @State var searchChat: Bool = false
    @FocusState var searchBarFocused: Bool
    
    @State var viewOption = true
    @State var showNewMapMessage = false
    @State var captionBind: String = ""
    @State var disableTopGesture = false
    
    @Namespace private var animation
    @State var isExpanded: Bool = false
    @State var showStoryProfile = false
    @State var storyProfileID: String = ""
    @State var addPadding: Bool = false
    @State var matchedStocks = [String]()
    
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    private let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    private let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    
    @Binding var navUserId: String
    @Binding var navToUser: Bool
    @Binding var navToProfile: Bool

    var body: some View {
        ZStack {
            ZStack(alignment: .top){
                if viewOption {
                    VStack(spacing: 0){
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
                                                
                                                if let messages = viewModel.chats[index].messages {
                                                    ForEach(Array(messages.enumerated()), id: \.element.id) { i, message in
                                                        if let text = message.text, !text.isEmpty && message.normal != nil {
                                                            if text.contains("left") || text == "You created a group" || text.contains("Chat created on") || text.contains("started chatting on") {
                                                                HStack {
                                                                    Spacer()
                                                                    Text(text)
                                                                        .font(.subheadline)
                                                                        .padding(.horizontal, 12).padding(.vertical, 5)
                                                                        .background(.gray.opacity(0.2))
                                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                                        .rotationEffect(.degrees(180.0))
                                                                        .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                    Spacer()
                                                                }.padding(.vertical, 10)
                                                            } else {
                                                                let split = text.components(separatedBy: " ")
                                                                let first = split.first ?? ""
                                                                let last = split.last ?? ""
                                                                let who = (first == (auth.currentUser?.username ?? "")) ? "You added \(last)" : "\(first) added \(last)"
                                                                
                                                                HStack {
                                                                    Spacer()
                                                                    Text(who)
                                                                        .font(.subheadline)
                                                                        .padding(.horizontal, 12).padding(.vertical, 5)
                                                                        .background(.gray.opacity(0.2))
                                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                                        .rotationEffect(.degrees(180.0))
                                                                        .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                    Spacer()
                                                                }.padding(.vertical, 10)
                                                            }
                                                        } else if String((message.id ?? "").prefix(6)) == String((Auth.auth().currentUser?.uid ?? "").prefix(6)) {
                                                            MyGroupChatBubble(message: message, replying: $replying, timePosition: (!(message.text ?? "").isEmpty || message.file != nil || message.audioURL != nil || viewModel.audioMessages.first(where: { $0.0 == message.id }) != nil), currentAudio: $currentAudio, editing: $editing, showUser: $showUser, selectedUser: $selectedUser, viewOption: $viewOption, isExpanded: $isExpanded, animation: animation, addPadding: $addPadding)
                                                                .rotationEffect(.degrees(180.0))
                                                                .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                .id(message.id)
                                                                .overlay(GeometryReader { proxy in
                                                                    Color.clear
                                                                        .onChange(of: offset, { _, _ in
                                                                            if let vid_id = message.videoURL, popRoot.currentSound.isEmpty {
                                                                                let frame = proxy.frame(in: .global)
                                                                                let bottomDistance = frame.minY - geometry.frame(in: .global).minY
                                                                                let topDistance = geometry.frame(in: .global).maxY - frame.maxY
                                                                                let diff = bottomDistance - topDistance
                                                                                
                                                                                if (bottomDistance < 0.0 && abs(bottomDistance) >= (frame.height / 2.0)) || (topDistance < 0.0 && abs(topDistance) >= (frame.height / 2.0)) {
                                                                                    if currentAudio == vid_id + (message.id ?? "") {
                                                                                        currentAudio = ""
                                                                                    }
                                                                                } else if abs(diff) < 140 && abs(diff) > -140 {
                                                                                    currentAudio = vid_id + (message.id ?? "")
                                                                                }
                                                                            }
                                                                        })
                                                                })
                                                        } else {
                                                            GroupChatBubble(message: message, replying: $replying, timePosition: (!(message.text ?? "").isEmpty || message.file != nil || message.audioURL != nil), currentAudio: $currentAudio, showUser: $showUser, selectedUser: $selectedUser, viewOption: $viewOption, isExpanded: $isExpanded, animation: animation, seenAllStories: storiesLeftToView(messageID: message.id), addPadding: $addPadding) { uid in
                                                                navUserId = uid
                                                                presentationMode.wrappedValue.dismiss()
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                                                    navToProfile = true
                                                                }
                                                            }
                                                            .rotationEffect(.degrees(180.0))
                                                            .scaleEffect(x: -1, y: 1, anchor: .center)
                                                            .id(message.id)
                                                            .overlay(GeometryReader { proxy in
                                                                Color.clear
                                                                    .onChange(of: offset, { _, _ in
                                                                        if let vid_id = message.videoURL, popRoot.currentSound.isEmpty {
                                                                            let frame = proxy.frame(in: .global)
                                                                            let bottomDistance = frame.minY - geometry.frame(in: .global).minY
                                                                            let topDistance = geometry.frame(in: .global).maxY - frame.maxY
                                                                            let diff = bottomDistance - topDistance
                                                                            
                                                                            if (bottomDistance < 0.0 && abs(bottomDistance) >= (frame.height / 2.0)) || (topDistance < 0.0 && abs(topDistance) >= (frame.height / 2.0)) {
                                                                                if currentAudio == vid_id + (message.id ?? "") {
                                                                                    currentAudio = ""
                                                                                }
                                                                            } else if abs(diff) < 140 && abs(diff) > -140 {
                                                                                currentAudio = vid_id + (message.id ?? "")
                                                                            }
                                                                        }
                                                                    })
                                                            })
                                                        }
                                                        if let dateStr = getString(forInt: i) {
                                                            HStack {
                                                                Spacer()
                                                                Text(dateStr)
                                                                    .font(.subheadline)
                                                                    .padding(.horizontal, 12).padding(.vertical, 5)
                                                                    .background(.gray.opacity(0.2))
                                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                                    .rotationEffect(.degrees(180.0))
                                                                    .scaleEffect(x: -1, y: 1, anchor: .center)
                                                                Spacer()
                                                            }.padding(.vertical, 10)
                                                        }
                                                        if let newPos = viewModel.newIndex, newPos == i {
                                                            NewChatLine()
                                                                .rotationEffect(.degrees(180.0))
                                                                .scaleEffect(x: -1, y: 1, anchor: .center)
                                                        }
                                                    }
                                                    Color.clear.frame(height: 110)
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
                                                }.frame(width: 35, height: 35)
                                            }
                                            .padding(.bottom, isKeyboardVisible ? (80.0 + keyboardHeight) : (105.0 + keyboardHeight)).transition(.scale)
                                            .padding(.bottom, (editing != nil || replying != nil) ? 40.0 : 0.0)
                                        }
                                    }
                                }
                            }.ignoresSafeArea()
                        }
                    }.transition(.move(edge: .top))
                } else if let index = viewModel.currentChat {
                    SwiftfulMapAppApp(disableTopGesture: $disableTopGesture, option: .constant(3), chatUsers: viewModel.chats[index].users ?? [], close: { num in
                        if num == 9 {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            withAnimation(.easeIn(duration: 0.15)){
                                viewOption = true
                            }
                        }
                    })
                    .transition(.move(edge: .bottom)).ignoresSafeArea(.keyboard)
                }
                
                if let index = viewModel.currentChat, viewModel.chats[index].messages == nil {
                    VStack {
                        Spacer()
                        LottieView(loopMode: .loop, name: "loaderMessage")
                            .scaleEffect(0.5)
                            .frame(width: 50, height: 50)
                        Spacer()
                    }
                }
                if !disableTopGesture {
                    viewHeader().ignoresSafeArea().transition(.move(edge: .top))
                }
            }
        }
        .overlay(content: {
            if isExpanded {
                if profileModel.isStoryRow {
                    MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: profileModel.mid, isHome: false, canOpenChat: popRoot.tab == 5, canOpenProfile: true, openChat: { uid in
                        navUserId = uid
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                            navToUser = true
                        }
                    }, openProfile: { uid in
                        navUserId = uid
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                            navToProfile = true
                        }
                    })
                    .ignoresSafeArea()
                    .onAppear(perform: { currentAudio = "" })
                    .onDisappear { addPadding = false }
                } else {
                    MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: profileModel.mid, isHome: false, canOpenChat: popRoot.tab == 5, canOpenProfile: true, openChat: { uid in
                        navUserId = uid
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                            navToUser = true
                        }
                    }, openProfile: { uid in
                        navUserId = uid
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                            navToProfile = true
                        }
                    })
                    .transition(.scale).ignoresSafeArea()
                    .onAppear(perform: { currentAudio = "" })
                    .onDisappear { addPadding = false }
                }
            }
        })
        .ignoresSafeArea(edges: addPadding ? .all : [])
        .navigationDestination(isPresented: $showUser) {
            ProfileView(showSettings: false, showMessaging: true, uid: selectedUser?.id ?? "", photo: selectedUser?.profileImageUrl ?? "", user: selectedUser, expand: false, isMain: false).enableFullSwipePop(true)
        }
        .fullScreenCover(isPresented: $showSettings, content: {
            FullSwipeNavigationStack {
                GroupChatSettings(allMessages: viewModel.chats[viewModel.currentChat ?? 0].messages ?? [], replying: $replying, showSearch: $searchChat, viewOption: $viewOption, groupPhoto: viewModel.chats[viewModel.currentChat ?? 0].photo) {
                    leaveView()
                }
            }
        })
        .onChange(of: searchChat, { _, new in
            if new {
                searchBarFocused = true
            }
        })
        .onChange(of: replying) { _, _ in
            if replying != nil {
                isFocused = true
            }
        }
        .onChange(of: editing) { _, _ in
            if editing != nil {
                isFocused = true
            }
        }
        .sheet(isPresented: $showAudioRoom, content: {
            if #available(iOS 16.4, *) {
                audioView().presentationCornerRadius(30)
            } else {
                audioView()
            }
        })
        .overlay(alignment: .bottom, content: {
            if !isExpanded && viewOption {
                HStack {
                    Spacer()
                    GroupChatField(showFilePicker: $showFilePicker, showCameraPicker: $showCameraPicker, showLibraryPicker: $showLibraryPicker, isFocused: $isFocused, replying: $replying, addAudio: $addAudio, editing: $editing, currentAudio: $currentAudio, searchText: $searchText, showSearch: $searchChat, showMemoryPicker: $showMemoryPicker, captionBind: $captionBind, matchedStocks: $matchedStocks)
                }
                .padding(.top, 5)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .animation(.easeInOut(duration: 0.2), value: matchedStocks)
            }
        })
        .overlay {
            if !searchChat && viewOption && !isExpanded {
                LiquidMenuButtons(isCollapsed: $isCollapsed, showFilePicker: $showFilePicker, showCameraPicker: $showCameraPicker, showLibraryPicker: $showLibraryPicker, sendElo: .constant(false), addAudio: $addAudio, isChat: false, showMemoryPicker: $showMemoryPicker, captionBind: $captionBind)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.startSingle(id: groupID)
            addKeyboardObservers()
            
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                timeBetween = true
            }
            viewModel.timeRemaining = 7.0
        }
        .onReceive(timer) { _ in
            if appeared && scenePhase == .active && !showSettings {
                viewModel.timeRemaining -= 1
                if viewModel.timeRemaining == 0 {
                    viewModel.getMessagesNew(initialFetch: false)
                    viewModel.timeRemaining = 5.0
                }
            }
        }
        .onDisappear {
            removeKeyboardObservers()
            appeared = false
            leaveView()
        }
        .onChange(of: popRoot.tap) { _, _ in
            if popRoot.tap == 5 {
                leaveView()
                popRoot.tap = 0
            }
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
    func storiesLeftToView(messageID: String?) -> Bool {
        if let index = viewModel.currentChat, let uid = auth.currentUser?.id, let messageID {
            let uid_prefix = String((messageID).prefix(6))
            if let foundUID = viewModel.chats[index].users?.first(where: { ($0.id ?? "").hasPrefix(uid_prefix)} )?.id {
                if foundUID == uid {
                    return false
                }
                if let stories = profileModel.users.first(where: { $0.user.id == foundUID })?.stories {
                    for i in 0..<stories.count {
                        if let sid = stories[i].id {
                            if !messagaModel.viewedStories.contains(where: { $0.0 == sid }) && !(stories[i].views ?? []).contains(where: { $0.contains(uid) }) {
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
    func viewHeader() -> some View {
        VStack(spacing: 20){
            HStack(spacing: 0){
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundStyle(.gray).opacity(0.001).frame(width: 40, height: 40)
                        Image(systemName: "chevron.backward").font(.system(size: 22)).bold()
                    }
                }
                
                if let index = viewModel.currentChat, index < viewModel.chats.count {
                    Button {
                        showSettings = true
                    } label: {
                        HStack(spacing: 12){
                            if let image = self.viewModel.chats[index].photo {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .scaledToFill()
                                    .clipShape(Circle())
                                    .frame(width: 45, height: 45)
                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                            } else {
                                ZStack(alignment: .center){
                                    Circle()
                                        .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray))
                                        .frame(width: 45, height: 45)
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.white).font(.headline)
                                }
                            }
                            let users = viewModel.chats[index].users ?? []
                            let usernamesString = users.map { $0.username }.joined(separator: ", ")
                            VStack(alignment: .leading, spacing: 3){
                                if let title = viewModel.chats[index].groupName, !title.isEmpty {
                                    Text(title)
                                        .font(.headline).bold()
                                        .lineLimit(1).truncationMode(.tail)
                                    Text(usernamesString)
                                        .font(.caption)
                                        .lineLimit(1).truncationMode(.tail)
                                } else {
                                    Text(usernamesString)
                                        .font(.headline).bold()
                                        .lineLimit(1).truncationMode(.tail)
                                    Text(startDate)
                                        .font(.caption)
                                        .lineLimit(1).truncationMode(.tail)
                                }
                            }
                            .onAppear {
                                let date = viewModel.chats[index].timestamp.dateValue()
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "MMMM, yyyy"
                                self.startDate = "Chat since \(dateFormatter.string(from: date))"
                            }
                        }
                    }
                    .onChange(of: viewModel.chats[index].lastM) { _, newValue in
                        if let last = newValue, !viewOption {
                            if String((last.id ?? "").prefix(6)) != String((Auth.auth().currentUser?.uid ?? "").prefix(6)) {
                                withAnimation(.easeIn(duration: 0.3)){
                                    showNewMapMessage = true
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showAudioRoom = true
                } label: {
                    Image(systemName: "waveform").font(.system(size: 22)).fontWeight(.semibold)
                }.padding(.trailing, 5)
            }
            .padding(.horizontal)
            .padding(.top, top_Inset())
            .padding(.bottom, 5)
            .background {
                if colorScheme == .dark {
                    TransparentBlurView(removeAllFilters: true)
                        .blur(radius: 20, opaque: true)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.12).opacity(0.8))
                        .overlay(alignment: .bottom){
                            Divider().overlay {
                                Color.white.opacity(0.3)
                            }
                        }
                } else {
                    TransparentBlurView(removeAllFilters: true)
                        .blur(radius: 20, opaque: true)
                        .background(Color(red: 0.92, green: 0.92, blue: 0.92).opacity(0.65))
                        .overlay(alignment: .bottom){
                            Divider().overlay {
                                Color.black.opacity(0.65)
                            }
                        }
                }
            }
            .overlay {
                if searchChat {
                    searchHeader()
                }
            }
            if (!showScrollDown && !searchChat) || !viewOption {
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
                    .focused($searchBarFocused)
                    .onSubmit {
                        searchBarFocused = false
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
                    searchBarFocused = false
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
    func leaveView(){
        if let index = viewModel.currentChat {
            if let m_id = viewModel.chats[index].messages?.first?.id, let uid = Auth.auth().currentUser?.uid {
                if !m_id.hasPrefix(uid.prefix(6)) {
                    if viewModel.chats[index].lastM?.seen == nil {
                        viewModel.chats[index].lastM?.seen = true
                        viewModel.chats[index].messages?[0].seen = true
                        if let docID = viewModel.chats[index].id {
                            GroupChatService().messageSeen(docID: docID, textId: m_id)
                        }
                    }
                    if let groupID = viewModel.chats[index].id {
                        LastSeenModel().setLastSeen(id: groupID, messageID: m_id)
                    }
                }
            }
            viewModel.newIndex = nil
            viewModel.currentChat = nil
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
    func audioView() -> some View {
        VStack(spacing: 0){
            HStack {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showAudioRoom = false
                }, label: {
                    ZStack {
                        Circle().foregroundStyle(.gray)
                        Image(systemName: "chevron.down").foregroundStyle(.white)
                    }.frame(width: 30, height: 30)
                })
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showAudioRoom = false
                }, label: {
                    ZStack {
                        Circle().foregroundStyle(.gray)
                        Image(systemName: "person.crop.circle.fill.badge.plus").foregroundStyle(.white)
                    }.frame(width: 30, height: 30)
                })
                
            }.padding(.horizontal, 15)
            HStack {
                Spacer()
                ZStack {
                    Circle().foregroundStyle(.white).frame(width: 70, height: 70)
                    Image("roomA")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 105, height: 105)
                }
                Spacer()
            }
            Text("Voice Chat").font(.title3).bold().padding(.top, 2)
            Text("No one's here yet!").font(.system(size: 13)).padding(.top, 8).opacity(0.8)
            Text("Click Join when your ready to talk.").font(.system(size: 13)).padding(.top, 2).opacity(0.8).padding(.bottom, 15)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 25).foregroundStyle(colorScheme == .dark ? .gray : .gray.opacity(0.5)).opacity(0.75)
                HStack {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        muted.toggle()
                    }, label: {
                        if muted {
                            ZStack {
                                Circle().foregroundStyle(Color(UIColor.lightGray))
                                Image(systemName: "mic.slash.fill").foregroundStyle(.white).font(.title3)
                            }
                        } else {
                            ZStack {
                                Circle().foregroundStyle(.white)
                                Image(systemName: "mic.fill").foregroundStyle(.black).font(.title3)
                            }
                        }
                    })
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showAudioRoom = false
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 45).foregroundStyle(.green)
                            Text("Join Call").font(.headline).bold().foregroundStyle(.white)
                        }
                    })
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showAudioRoom = false
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(Color(UIColor.lightGray))
                            Image(systemName: "message.fill").foregroundStyle(.white).font(.title3)
                        }
                    })
                }.padding(7)
            }.frame(height: 65).padding(.horizontal).padding(.bottom, 12)
        }
        .padding(.top, 10)
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(CGFloat(320))])
    }
}
