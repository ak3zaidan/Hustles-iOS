import SwiftUI
import Kingfisher
import Firebase

struct MessagesHomeView: View, KeyboardReadable {
    @EnvironmentObject var groupChatModel: GroupChatViewModel
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var exploreModel: ExploreViewModel
    @EnvironmentObject var serverModel: GroupViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @State var appeared: Bool = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeRemaining = 10.0
    @Environment(\.scenePhase) var scenePhase
    @State private var keyboardV = false
    @State private var showAI = false
    @State private var showSearch = false
    @State private var isEnabled: Bool = true
    @State private var goUp: Bool = false
    @State private var isCollapsed: Bool = false
    @State private var leaveID: String = ""
    @State private var showLeave: Bool = false
    @State private var leaveGroupID: String = ""
    @State private var showLeaveGroup: Bool = false
    @State private var loadedEnough: Bool = false
    @State private var showMesLoader: Bool = false
    
    enum FocusedField {
        case one, two
    }
    @FocusState private var focusField: FocusedField?
    @State var showPinDelete: Bool = false
    
    @State var navigate1: Bool = false
    @State var navChat: Chats? = nil
    @State var navigate2: Bool = false
    @State var navGChat: String? = nil
    @State var navigate3: Bool = false
    @State var navServer: GroupX? = nil
    @State var navToProfile: Bool = false
    
    @State var updateChatRowView: Bool = false
    @State var updateGroupRowView: Bool = false
    @State var updateServerRowView: Bool = false
    
    @Binding var disableSwipe: Bool
    @Binding var isExpanded: Bool
    let animation: Namespace.ID
    @Binding var messageOrder: [String]
    let showNotifs: () -> Void
    let showMainCamera: () -> Void
    
    var body: some View {
        ZStack(alignment: .top){
            LinearGradient(colors: [.orange.opacity(0.8), .clear], startPoint: .top, endPoint: .bottom)
                .padding(.top, 105)
                .frame(height: 275)
            
            LottieView(loopMode: .loop, name: "loaderMessage")
                .scaleEffect(0.5)
                .frame(width: 50,height: 50)
                .padding(.top, 115)
            
            ScrollViewReader { proxy in
                List {
                    viewOptions()
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .id("top")
                        .onChange(of: goUp, { _, _ in
                            withAnimation(.easeInOut(duration: 0.15)){
                                proxy.scrollTo("top", anchor: .bottom)
                            }
                        })
                    
                    if let all = auth.currentUser?.pinnedChats, !all.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(spacing: 3), count: 3), alignment: .center, spacing: 22) {
                            ForEach(all, id: \.self) { element in
                                if viewModel.chats.contains(where: { $0.convo.id == element }) {
                                    PinnedChatView(delete: $showPinDelete, chat: updatedPinConvo(did: element), navigate: $navigate1, navChat: $navChat, updatePin: $updateChatRowView).buttonStyle(.plain)
                                } else if groupChatModel.chats.contains(where: { $0.id == element }) {
                                    PinnedGroupView(delete: $showPinDelete, group: updatedPinGroup(did: element), navigate: $navigate2, navGChat: $navGChat, updatePin: $updateGroupRowView).buttonStyle(.plain)
                                } else if let server = exploreModel.joinedGroups.first(where: { $0.id == element }) ?? exploreModel.userGroup?.first(where: { $0.id == element }) {
                                    PinnedChannelView(delete: $showPinDelete, server: server, navigate: $navigate3, navServer: $navServer) { id in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            auth.currentUser?.pinnedChats?.removeAll(where: { $0 == id })
                                        }
                                    }.buttonStyle(.plain)
                                } else {
                                    PinnedChatLoader()
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .padding(.horizontal, 5).padding(.vertical, 10)
                        .onDisappear {
                            showPinDelete = false
                        }
                    }
                    
                    if viewModel.selection != 2 && viewModel.selection != 5 && !viewModel.suggestedChats.isEmpty {
                        suggest
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .padding(.top, 10)
                    }
                    
                    if viewModel.selection == 5 {
                        callsView()
                    } else if viewModel.selection == 4 {
                        requestsView()
                    } else {
                        ForEach(messageOrder, id: \.self){ did in
                            if !(auth.currentUser?.pinnedChats ?? []).contains(did) {
                                if let chat = viewModel.chats.first(where: { $0.convo.id == did }) {
                                    if viewModel.selection == 1 || viewModel.selection == 3 {
                                        
                                        let isUidOne = (chat.convo.uid_one == auth.currentUser?.id ?? "")

                                        TitleRow(user: chat.user, message: lastChatMessage(did: did), is_uid_one: isUidOne, isExpanded: $isExpanded, animation: animation, convoID: chat.id, bubbleColor: chat.color, seenAllStories: storiesLeftToView(otherUID: chat.user.id), updateRowView: $updateChatRowView)
                                            .contentShape(Rectangle())
                                            .padding(.leading, 8).padding(.trailing, 8)
                                            .padding(.bottom, 6).padding(.top, 3)
                                            .listRowInsets(EdgeInsets())
                                            .background {
                                                NavigationLink("") {
                                                    MessagesView(exception: false, user: chat.user, uid: chat.user.id ?? "", tabException: true, canCall: true)
                                                        .enableFullSwipePop(isEnabled)
                                                }.opacity(0)
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive, action: {
                                                    if let index = viewModel.chats.firstIndex(where: { $0 == chat }){
                                                        viewModel.deleteConvo(docID: viewModel.chats[index].convo.id ?? "")
                                                        auth.currentUser?.myMessages.removeAll(where: { $0 ==  viewModel.chats[index].convo.id ?? ""})
                                                        viewModel.chats.remove(at: index)
                                                    }
                                                }, label: {
                                                    Image(systemName: "trash")
                                                }).tint(.red)
                                            }
                                            .swipeActions(edge: .trailing) {
                                                Button(action: {
                                                    
                                                }, label: {
                                                    Image(systemName: "bell")
                                                }).tint(.orange)
                                            }
                                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                                Button(action: {
                                                    viewModel.initialSend = messageSendType(id: chat.id, title: chat.user.username, type: 1)
                                                    showMainCamera()
                                                }, label: {
                                                    Image(systemName: "camera")
                                                }).tint(.blue)
                                            }
                                            .swipeActions(edge: .leading) {
                                                Button(action: {
                                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                    if let id = chat.convo.id {
                                                        withAnimation(.easeInOut(duration: 0.2)) {
                                                            if auth.currentUser?.pinnedChats != nil {
                                                                auth.currentUser?.pinnedChats?.append(id)
                                                            } else {
                                                                auth.currentUser?.pinnedChats = [id]
                                                            }
                                                        }
                                                        UserService().addChatPin(id: id)
                                                    }
                                                }, label: {
                                                    Image(systemName: "pin")
                                                }).tint(.green)
                                            }
                                    }
                                } else if let id = groupChatModel.chats.first(where: { $0.id == did })?.id {
                                    if viewModel.selection == 1 || viewModel.selection == 3 {
                                        GroupChatRowView(group: updatedBindingGroup(did: did), updateRowView: $updateGroupRowView)
                                            .contentShape(Rectangle())
                                            .padding(.leading, 8).padding(.trailing, 8)
                                            .padding(.bottom, 6).padding(.top, 3)
                                            .listRowInsets(EdgeInsets())
                                            .background {
                                                NavigationLink("") {
                                                    GroupChatView(groupID: id, navUserId: $viewModel.userMapID, navToUser: $viewModel.navigateUserMap, navToProfile: $navToProfile)
                                                        .enableFullSwipePop(isEnabled)
                                                }.opacity(0)
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive, action: {
                                                    leaveID = id
                                                    showLeave = true
                                                }, label: {
                                                    Image(systemName: "trash")
                                                }).tint(.red)
                                            }
                                            .swipeActions(edge: .trailing) {
                                                Button(action: {
                                                    
                                                }, label: {
                                                    Image(systemName: "bell")
                                                }).tint(.orange)
                                            }
                                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                                Button(action: {
                                                    if let chat = groupChatModel.chats.first(where: { $0.id == did }) {
                                                        if let title = chat.groupName, !title.isEmpty {
                                                            viewModel.initialSend = messageSendType(id: chat.id ?? "", title: title, type: 2)
                                                        } else {
                                                            let title = chat.users?.map { $0.username }.joined(separator: ", ") ?? ""
                                                            viewModel.initialSend = messageSendType(id: chat.id ?? "", title: title, type: 2)
                                                        }
                                                    }
                                                    showMainCamera()
                                                }, label: {
                                                    Image(systemName: "camera")
                                                }).tint(.blue)
                                            }
                                            .swipeActions(edge: .leading) {
                                                Button(action: {
                                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        if auth.currentUser?.pinnedChats != nil {
                                                            auth.currentUser?.pinnedChats?.append(id)
                                                        } else {
                                                            auth.currentUser?.pinnedChats = [id]
                                                        }
                                                    }
                                                    UserService().addChatPin(id: id)
                                                }, label: {
                                                    Image(systemName: "pin")
                                                }).tint(.green)
                                            }
                                    }
                                } else if let group = serverModel.groups.first(where: { $0.1.id == did })?.1 ?? exploreModel.joinedGroups.first(where: { $0.id == did }) ?? exploreModel.userGroup?.first(where: { $0.id == did }){
                                    if viewModel.selection == 2 || viewModel.selection == 3 {
                                        GroupTitleRow(group: group, uid: auth.currentUser?.id ?? "", updateRowView: $updateServerRowView)
                                            .contentShape(Rectangle())
                                            .padding(.leading, 8).padding(.trailing, 8)
                                            .padding(.bottom, 6).padding(.top, 3)
                                            .listRowInsets(EdgeInsets())
                                            .background {
                                                NavigationLink("") {
                                                    GroupView(group: group, imageName: "", title: "", remTab: true, showSearch: true)
                                                }.opacity(0)
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive, action: {
                                                    leaveGroupID = group.id
                                                    showLeaveGroup = true
                                                }, label: {
                                                    Image(systemName: "trash")
                                                }).tint(.red)
                                            }
                                            .swipeActions(edge: .trailing) {
                                                Button(action: {
                                                    
                                                }, label: {
                                                    Image(systemName: "bell")
                                                }).tint(.orange)
                                            }
                                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                                Button(action: {
                                                    viewModel.initialSend = messageSendType(id: group.id, title: group.title, type: 3)
                                                    
                                                    showMainCamera()
                                                }, label: {
                                                    Image(systemName: "camera")
                                                }).tint(.blue)
                                            }
                                            .swipeActions(edge: .leading) {
                                                Button(action: {
                                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        if auth.currentUser?.pinnedChats != nil {
                                                            auth.currentUser?.pinnedChats?.append(group.id)
                                                        } else {
                                                            auth.currentUser?.pinnedChats = [group.id]
                                                        }
                                                    }
                                                    UserService().addChatPin(id: group.id)
                                                }, label: {
                                                    Image(systemName: "pin")
                                                }).tint(.green)
                                            }
                                    }
                                }
                            }
                        }
                    }
                    Color.clear.frame(height: viewModel.suggestedChats.isEmpty ? 145 : (viewModel.selection == 1 || viewModel.selection == 3 || viewModel.selection == 4) ? 210 : 145)   .listRowSeparator(.hidden)
                }
                .contentMargins(.top, 95)
                .listStyle(.plain)
                .refreshable {
                    if let id = auth.currentUser?.id, viewModel.canRefresh && !id.isEmpty {
                        viewModel.canRefresh = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                            self.updateChatRowView.toggle()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                            self.updateGroupRowView.toggle()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){
                            self.updateServerRowView.toggle()
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            self.viewModel.canRefresh = true
                        }
                        UserService().fetchUser(withUid: id) { user in
                            if let idSec = user.id, id == idSec {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    auth.currentUser = user
                                }
                                viewModel.refreshConvos(pointers: user.myMessages)
                                groupChatModel.refreshConvos(pointers: user.groupChats ?? [])
                            }
                        }
                    }
                }
            }.scrollDismissesKeyboard(.immediately)
            
            VStack {
                headerView()
                Spacer()
            }
            
            PlusButtonView(isCollapsed: $isCollapsed, navToProfile: $navToProfile)
            
            if showSearch {
                searchView()
            }
        }
        .navigationDestination(isPresented: $navigate3) {
            if let server = navServer {
                GroupView(group: server, imageName: "", title: "", remTab: true, showSearch: true)
            }
        }
        .navigationDestination(isPresented: $navigate2) {
            GroupChatView(groupID: navGChat ?? "", navUserId: $viewModel.userMapID, navToUser: $viewModel.navigateUserMap, navToProfile: $navToProfile)
                .enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $groupChatModel.navigateMapGroup) {
            GroupChatView(groupID: groupChatModel.newMapGroupId, navUserId: $viewModel.userMapID, navToUser: $viewModel.navigateUserMap, navToProfile: $navToProfile)
                .enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $navigate1) {
            MessagesView(exception: false, user: navChat?.user, uid: navChat?.user.id ?? "", tabException: true, canCall: true).enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $viewModel.navigateStoryProfile) {
            ProfileView(showSettings: false, showMessaging: true, uid: viewModel.userMapID, photo: "", user: nil, expand: false, isMain: false)
                .onAppear {
                    disableSwipe = true
                }
                .onDisappear {
                    disableSwipe = false
                    profile.currentUser = nil
                }
        }
        .navigationDestination(isPresented: $navToProfile) {
            ProfileView(showSettings: false, showMessaging: true, uid: viewModel.userMapID, photo: "", user: nil, expand: false, isMain: false)
                .onAppear {
                    disableSwipe = true
                }
                .onDisappear {
                    disableSwipe = false
                    profile.currentUser = nil
                }
        }
        .navigationDestination(isPresented: $viewModel.navigateUserMap) {
            MessagesView(exception: false, user: viewModel.userMap, uid: viewModel.userMap?.id ?? viewModel.userMapID, tabException: true, canCall: true).enableFullSwipePop(true)
        }
        .alert("Are you sure you want to leave this chat?", isPresented: $showLeave) {
            Button("Leave", role: .destructive) {
                if !leaveID.isEmpty {
                    groupChatModel.chats.removeAll(where: { $0.id == leaveID })
                    GroupChatService().leaveGroup(docID: leaveID, username: auth.currentUser?.username ?? "")
                    leaveID = ""
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Are you sure you want to leave this group?", isPresented: $showLeaveGroup) {
            Button("Leave", role: .destructive) {
                if !leaveGroupID.isEmpty {
                    exploreModel.joinedGroups.removeAll(where: { $0.id == leaveGroupID })
                    ExploreService().leaveGroup(groupId: leaveGroupID)
                    leaveGroupID = ""
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showAI, content: {
            BaseAIView()
        })
        .onChange(of: viewModel.chats, { _, _ in
            reOrder()
            updateChatRowView.toggle()
        })
        .onChange(of: groupChatModel.chats, { _, _ in
            reOrder()
            updateGroupRowView.toggle()
        })
        .onChange(of: serverModel.groups.compactMap({ $0.1 }), {
            reOrder()
            updateServerRowView.toggle()
        })
        .onChange(of: exploreModel.joinedGroups, {
            reOrder()
            updateServerRowView.toggle()
        })
        .onChange(of: exploreModel.userGroup, {
            reOrder()
            updateServerRowView.toggle()
        })
        .onChange(of: viewModel.getStoriesQueue, { _, _ in
            let temp = viewModel.getStoriesQueue
            viewModel.getStoriesQueue = []
            temp.forEach { uid in
                if let user = viewModel.chats.first(where: { $0.user.id == uid })?.user {
                    if (auth.currentUser?.following ?? []).contains(uid) || user.followers > 50 {
                        profile.updateStoriesUser(user: user)
                    }
                }
            }
        })
        .onDisappear { appeared = false }
        .onAppear {
            if !disableSwipe {
                profile.currentUser = nil
            }
            if viewModel.gotConversations {
                refreshStories()
            }
            appeared = true
            timeRemaining = 10.0
            reOrder()
            
            if ((viewModel.chats.isEmpty && !(auth.currentUser?.myMessages ?? []).isEmpty) || (groupChatModel.chats.isEmpty && !(auth.currentUser?.groupChats ?? []).isEmpty)) || auth.currentUser == nil {
                withAnimation {
                    showMesLoader = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0){
                    withAnimation {
                        showMesLoader = false
                    }
                }
            }
            
            viewModel.fetchConvos(pointers: auth.currentUser?.myMessages ?? [])
            groupChatModel.getAll(pointers: auth.currentUser?.groupChats ?? [], byPass: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0){
                withAnimation {
                    loadedEnough = true
                }
            }
            
            if let pointers = auth.currentUser?.myMessages, !pointers.isEmpty && viewModel.chats.isEmpty && !viewModel.gotConversations {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0){
                    if let pointersSec = auth.currentUser?.myMessages, !pointersSec.isEmpty && viewModel.chats.isEmpty && !viewModel.gotConversations {
                        viewModel.currentlyFetchingData = false
                        viewModel.fetchConvos(pointers: pointersSec)
                    }
                }
            }
            if let pointers = auth.currentUser?.groupChats, !pointers.isEmpty && groupChatModel.chats.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0){
                    if let pSec = auth.currentUser?.groupChats, !pSec.isEmpty && groupChatModel.chats.isEmpty {
                        groupChatModel.getAll(pointers: pSec, byPass: false)
                    }
                }
            }
            if let all = auth.currentUser?.groupIdentifier, !all.isEmpty && (exploreModel.userGroup ?? []).isEmpty {
                exploreModel.getUserGroupCover(userGroupId: all)
            }
            if !(auth.currentUser?.pinnedGroups.isEmpty ?? false) && exploreModel.joinedGroups.isEmpty {
                exploreModel.getUserJoinedGroupCovers(groupIds: auth.currentUser?.pinnedGroups ?? [])
            }
        }
        .onReceive(keyboardPublisher) { new in
            keyboardV = new
        }
        .onChange(of: auth.currentUser?.id, { _, _ in
            viewModel.currentlyFetchingData = false
            viewModel.gotConversations = false
            
            if ((viewModel.chats.isEmpty && !(auth.currentUser?.myMessages ?? []).isEmpty) || (groupChatModel.chats.isEmpty && !(auth.currentUser?.groupChats ?? []).isEmpty)) {
                withAnimation {
                    showMesLoader = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0){
                    withAnimation {
                        showMesLoader = false
                    }
                }
            }
            
            viewModel.fetchConvos(pointers: auth.currentUser?.myMessages ?? [])
            groupChatModel.getAll(pointers: auth.currentUser?.groupChats ?? [], byPass: false)
            if let all = auth.currentUser?.groupIdentifier, !all.isEmpty && (exploreModel.userGroup ?? []).isEmpty {
                exploreModel.getUserGroupCover(userGroupId: all)
            }
            if !(auth.currentUser?.pinnedGroups.isEmpty ?? false) && exploreModel.joinedGroups.isEmpty {
                exploreModel.getUserJoinedGroupCovers(groupIds: auth.currentUser?.pinnedGroups ?? [])
            }
        })
        .onChange(of: popRoot.tap, { _, _ in
            if popRoot.tap == 5 {
                if appeared {
                    goUp.toggle()
                    popRoot.tap = 0
                } else if showSearch {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    focusField = .two
                    appeared = true
                    viewModel.searchText = ""
                    viewModel.submitted = false
                    viewModel.noUsersFound = false
                    withAnimation(.easeInOut){
                        showSearch = false
                    }
                    popRoot.tap = 0
                }
            }
        })
        .onReceive(timer) { _ in
            if appeared && scenePhase == .active {
                timeRemaining -= 1
                if timeRemaining == 0 {
                    timeRemaining = 10.0
                    viewModel.refreshFirstMessages()
                    groupChatModel.refreshFirst()
                }
            }
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
    }
    @ViewBuilder
    func viewOptions() -> some View {
        VStack {
            let width = widthOrHeight(width: true) * 0.19
            HStack(spacing: 0){
                Button {
                    if viewModel.selection != 1 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    viewModel.selection = 1
                } label: {
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001).frame(width: width, height: 20)
                        Text("Chats").foregroundStyle(viewModel.selection == 1 ? .blue : .gray)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }.buttonStyle(.plain)
                Button {
                    if viewModel.selection != 2 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    viewModel.selection = 2
                } label: {
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001).frame(width: width, height: 20)
                        Text("Groups").foregroundStyle(viewModel.selection == 2 ? .blue : .gray)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }.buttonStyle(.plain)
                Button {
                    if viewModel.selection != 3 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    viewModel.selection = 3
                } label: {
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001).frame(width: width, height: 20)
                        Text("All").foregroundStyle(viewModel.selection == 3 ? .blue : .gray)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }.buttonStyle(.plain)
                Button {
                    if viewModel.selection != 4 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    viewModel.selection = 4
                } label: {
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001).frame(width: width, height: 20)
                        Text("Requests").foregroundStyle(viewModel.selection == 4 ? .blue : .gray)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }.buttonStyle(.plain)
                Button {
                    if viewModel.selection != 5 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    viewModel.selection = 5
                } label: {
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001).frame(width: width, height: 20)
                        Text("Calls").foregroundStyle(viewModel.selection == 5 ? .blue : .gray)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }.buttonStyle(.plain)
            }
            .padding(.top, 14).font(.system(size: 17))
            Divider().overlay(Color.gray).padding(.top, 4).padding(.bottom, 5)
        }
    }
    func reOrder(){
        let messages = viewModel.chats
        let gcs = groupChatModel.chats
        let groups = exploreModel.joinedGroups
        let groupsSec = exploreModel.userGroup ?? []
        let noDate = Timestamp(date: Calendar.current.date(byAdding: .year, value: -2, to: Date())!)
        
        var tempOrder: [(String?, Timestamp)] = []
        
        messages.forEach { element in
            tempOrder.append((element.convo.id, element.lastM?.timestamp ?? noDate))
        }
        gcs.forEach { element in
            tempOrder.append((element.id, element.lastM?.timestamp ?? noDate))
        }
        groups.forEach { element in
            if let found = serverModel.groups.first(where: { $0.1.id == element.id })?.1.messages {
                let newest = found.flatMap({ $0.messages }).sorted { tweet1, tweet2 in
                    return tweet1.timestamp.dateValue() > tweet2.timestamp.dateValue()
                }.first?.timestamp ?? element.lastM?.timestamp ?? noDate
                
                tempOrder.append((element.id, newest))
            } else {
                tempOrder.append((element.id, element.lastM?.timestamp ?? noDate))
            }
        }
        groupsSec.forEach { element in
            if let found = serverModel.groups.first(where: { $0.1.id == element.id })?.1.messages {
                let newest = found.flatMap({ $0.messages }).sorted { tweet1, tweet2 in
                    return tweet1.timestamp.dateValue() > tweet2.timestamp.dateValue()
                }.first?.timestamp ?? element.lastM?.timestamp ?? noDate
                
                tempOrder.append((element.id, newest))
            } else {
                tempOrder.append((element.id, element.lastM?.timestamp ?? noDate))
            }
        }
        
        withAnimation(.easeInOut(duration: 0.1)){
            self.messageOrder = tempOrder.sorted(by: { $0.1.dateValue() > $1.1.dateValue() }).compactMap({ $0.0 })
        }
    }
    @ViewBuilder
    func requestsView() -> some View {
        VStack(spacing: 6){
            if viewModel.requests.isEmpty {
//                LottieView(loopMode: .playOnce, name: "nofound")
//                    .frame(width: 150, height: 150)
//                    .padding(.top, 100)
//                    .scaleEffect(0.3)
            } else {
                ForEach(viewModel.requests){ chat in
                    NavigationLink {
                        MessagesView(exception: false, user: chat.user, uid: chat.user.id ?? "", tabException: true, canCall: true)
                            .enableFullSwipePop(isEnabled)
                    } label: {
                        SwipeView {
                            let isUidOne = (chat.convo.uid_one == auth.currentUser?.id ?? "")
                            let message = chat.lastM ?? Message(uid_one_did_recieve: false, seen_by_reciever: true, timestamp: Timestamp())
                            let received = (isUidOne && message.uid_one_did_recieve) || (!isUidOne && !message.uid_one_did_recieve)
                            let seen = received ? message.seen_by_reciever : true
                            
//                            TitleRow(user: chat.user, message: message, is_uid_one: isUidOne, isExpanded: $isExpanded, animation: animation, convoID: chat.id, bubbleColor: chat.color, seenAllStories: storiesLeftToView(otherUID: chat.user.id), seen: seen, received: received, updateRowView: $updateChatRowView)
//                                .contentShape(Rectangle())
                        } trailingActions: { context in
                            SwipeAction {
                                context.state.wrappedValue = .closed
                            } label: { _ in
                                Image(systemName: "trash").foregroundStyle(.white).font(.title3)
                            } background: { _ in
                                Color.red
                            }.allowSwipeToTrigger()
                        }.padding(.horizontal)
                    }
                }
            }
        }
    }
    @ViewBuilder
    func callsView() -> some View {
        VStack(spacing: 6){
            if viewModel.calls.isEmpty {
//                LottieView(loopMode: .playOnce, name: "nofound")
//                    .frame(width: 150, height: 150)
//                    .padding(.top, 100)
//                    .scaleEffect(0.3)
            } else {
                HStack {
                    Text("Recent Calls").font(.title3).bold()
                    Spacer()
                }.padding(.leading).padding(.top, 20)
                VStack {
                    ForEach(0..<7, id: \.self) { i in
                        CallRowView(call: callInfo(id: "", uid: "", photo: "", outgoing: true, name: "jacky thomas", missed: true, timestamp: Timestamp()))
                    }
                }
                .background(.gray.opacity(0.4))
                .cornerRadius(10, corners: .allCorners)
                .padding(.horizontal)
            }
        }
    }
    func refreshStories() {
        let users = viewModel.chats.compactMap({ $0.user })
        users.forEach { user in
            if let uid = user.id {
                if (auth.currentUser?.following ?? []).contains(uid) || user.followers > 50 {
                    profile.updateStoriesUser(user: user)
                }
            }
        }
    }
    func updatedPinGroup(did: String) -> Binding<GroupConvo> {
        if let index = groupChatModel.chats.firstIndex(where: { $0.id == did }) {
            return Binding(
                get: { groupChatModel.chats[index] },
                set: { groupChatModel.chats[index] = $0 }
            )
        }

        return .constant(GroupConvo(allUsersUID: [], timestamp: Timestamp()))
    }
    func updatedPinConvo(did: String) -> Binding<Chats> {
        if let index = viewModel.chats.firstIndex(where: { $0.convo.id == did }) {
            return Binding(
                get: { viewModel.chats[index] },
                set: { viewModel.chats[index] = $0 }
            )
        }
        
        return .constant(Chats(id: UUID().uuidString, user: User(username: "", fullname: "", email: "", zipCode: "", following: [], badges: [], elo: 0, followers: 0, completedjobs: 0, verifiedTips: 0, pinnedGroups: [], jobPointer: [], shopPointer: [], alertsShown: "", likedHustles: [], dev: nil, timestamp: Timestamp(), verified: nil, publicKey: "", myMessages: [], userCountry: ""), convo: Convo(uid_one: "", uid_two: "", uid_one_active: false, uid_two_active: false, encrypted: false)))
    }
    func lastChatMessage(did: String) -> Binding<Message> {
        let defaultM = Message(uid_one_did_recieve: false, seen_by_reciever: true, timestamp: Timestamp())

        if let index = viewModel.chats.firstIndex(where: { $0.convo.id == did }) {
            return Binding(
                get: { viewModel.chats[index].lastM ?? defaultM },
                set: { viewModel.chats[index].lastM = $0 }
            )
        }
        
        return .constant(defaultM)
    }
    func updatedBindingGroup(did: String) -> Binding<GroupConvo> {
        let defaultM = GroupConvo(allUsersUID: [], timestamp: Timestamp())

        if let index = groupChatModel.chats.firstIndex(where: { $0.id == did }) {
            return Binding(
                get: { groupChatModel.chats[index] },
                set: { groupChatModel.chats[index] = $0 }
            )
        }
        
        return .constant(defaultM)
    }
    func storiesLeftToView(otherUID: String?) -> Bool {
        if let uid = auth.currentUser?.id, let otherUID {
            if otherUID == uid {
                return false
            }
            if let stories = profile.users.first(where: { $0.user.id == otherUID })?.stories {
                
                for i in 0..<stories.count {
                    if let sid = stories[i].id {
                        if !viewModel.viewedStories.contains(where: { $0.0 == sid }) && !(stories[i].views ?? []).contains(where: { $0.contains(uid) }) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    func searchView() -> some View {
        VStack(spacing: 12){
            HStack(spacing: 10){
                TextField("Search", text: $viewModel.searchText)
                    .tint(.blue)
                    .autocorrectionDisabled(true)
                    .padding(8)
                    .padding(.horizontal, 24)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($focusField, equals: .one)
                    .onSubmit {
                        focusField = .two
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
                    focusField = .two
                    appeared = true
                    viewModel.searchText = ""
                    viewModel.submitted = false
                    viewModel.noUsersFound = false
                    withAnimation(.easeInOut){
                        showSearch = false
                    }
                }, label: {
                    Text("Cancel").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                })
            }
            .padding(.top, top_Inset())
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
                                NavigationLink {
                                    MessagesView(exception: false, user: user, uid: user.id ?? "", tabException: true, canCall: true)
                                        .enableFullSwipePop(isEnabled)
                                } label: {
                                    userViewThree(user: user)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .cornerRadius(8, corners: .allCorners)
                        .padding(.horizontal, 12)
                    }
                    let eight = viewModel.chats.filter { $0.user.dev == nil }.prefix(8)
                    if !eight.isEmpty {
                        HStack {
                            Text("Best Friends").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                            Spacer()
                        }.padding(.top).padding(.horizontal, 12)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(eight){ chat in
                                NavigationLink {
                                    MessagesView(exception: false, user: chat.user, uid: chat.user.id ?? "", tabException: true, canCall: true)
                                        .enableFullSwipePop(isEnabled)
                                } label: {
                                    userViewOne(user: chat.user)
                                }
                            }
                        }.padding(.horizontal, 12)
                    }
                    if !(exploreModel.userGroup ?? []).isEmpty || (!exploreModel.joinedGroups.isEmpty) {
                        HStack {
                            Text("My Channels").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                            Spacer()
                        }.padding(.top, 6).padding(.horizontal, 12)
                        ScrollView(.horizontal) {
                            HStack(spacing: 8){
                                let userG = exploreModel.userGroup ?? []
                                let all = userG + exploreModel.joinedGroups
                                Color.clear.frame(width: 13)
                                ForEach(all){ gr in
                                    NavigationLink {
                                        GroupView(group: gr, imageName: "", title: "", remTab: true, showSearch: true)
                                    } label: {
                                        groupView(group: gr)
                                    }
                                }
                                Color.clear.frame(width: 1)
                            }.padding(.vertical, 2)
                        }.scrollIndicators(.hidden)
                    }
                    if !groupChatModel.chats.isEmpty {
                        HStack {
                            Text("Group Chats").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                            Spacer()
                        }.padding(.top).padding(.horizontal, 12)
                        VStack(spacing: 8){
                            ForEach(groupChatModel.chats){ chat in
                                NavigationLink {
                                    GroupChatView(groupID: chat.id ?? "", navUserId: $viewModel.userMapID, navToUser: $viewModel.navigateUserMap, navToProfile: $navToProfile).enableFullSwipePop(isEnabled)
                                } label: {
                                    if let title = chat.groupName {
                                        groupViewThreeSearch(title: title, photo: chat.photo)
                                    } else if let all_u = chat.users?.compactMap({ $0 }) {
                                        groupViewThreeSearch(title: all_u.map { $0.username }.joined(separator: ", "), photo: chat.photo)
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
                                Color.clear.frame(width: 13)
                                ForEach(all){ chat in
                                    NavigationLink {
                                        MessagesView(exception: false, user: chat.user, uid: chat.user.id ?? "", tabException: true, canCall: true)
                                            .enableFullSwipePop(isEnabled)
                                    } label: {
                                        userViewTwo(user: chat.user)
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
                                NavigationLink {
                                    MessagesView(exception: false, user: user, uid: user.id ?? "", tabException: true, canCall: true)
                                        .enableFullSwipePop(isEnabled)
                                } label: {
                                    userViewThree(user: user)
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
                                NavigationLink {
                                    MessagesView(exception: false, user: user, uid: user.id ?? "", tabException: true, canCall: true)
                                        .enableFullSwipePop(isEnabled)
                                } label: {
                                    userViewThree(user: user)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .cornerRadius(8, corners: .allCorners)
                        .padding(.horizontal, 12)
                    }
                }
                Color.clear.frame(height: 85)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(colorScheme == .dark ? .black : .white)
    }
    func headerView() -> some View {
        VStack {
            Spacer()
            ZStack {
                HStack(spacing: 20){
                    Button {
                        viewModel.searchText = ""
                        viewModel.submitted = false
                        viewModel.noUsersFound = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if let user = auth.currentUser, let id = user.id, !viewModel.gotNotifications {
                            if let prof = profile.users.first(where: { $0.user.id ?? "" == id }) {
                                viewModel.getNotifications(profile: prof)
                            } else {
                                viewModel.getNotifications(profile: Profile(user: user, tweets: [], listJobs: [], likedTweets: [], forSale: [], questions: []))
                            }
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showNotifs()
                    } label: {
                        ZStack {
                            Circle().foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                            Image(systemName: "globe").bold().foregroundStyle(.white)
                        }.frame(width: 38, height: 38)
                    }
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation {
                            showSearch = true
                        }
                        appeared = false
                        focusField = .one
                        viewModel.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(.gray).opacity(0.4)
                            Image(systemName: "magnifyingglass").bold()
                        }.frame(width: 38, height: 38)
                    })
                    
                    Spacer()
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showAI.toggle()
                    }, label: {
                        ZStack {
                            Rectangle().foregroundStyle(.gray).opacity(0.001)
                            AICircle(width: 30)
                        }.frame(width: 30, height: 30)
                    })
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showMainCamera()
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(.gray).opacity(0.001)
                            Image(systemName: "camera")
                                .resizable().scaledToFit()
                                .foregroundStyle(.blue)
                        }.frame(width: 34, height: 34)
                    })
                }
                HStack {
                    Spacer()
                    Text("Chats").font(.title).bold()
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
        .frame(height: 105)
        .background {
            TransparentBlurView(removeAllFilters: true)
                .blur(radius: 7, opaque: true)
                .background(colorScheme == .dark ? .black.opacity(0.6) : .white.opacity(0.8))
        }
        .overlay(alignment: .bottom){
            if (!loadedEnough && ((viewModel.chats.isEmpty && !(auth.currentUser?.myMessages ?? []).isEmpty) || (groupChatModel.chats.isEmpty && !(auth.currentUser?.groupChats ?? []).isEmpty))) || showMesLoader {
                MessagesLoader()
            }
        }
    }
    var suggest: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Text("For you").font(.subheadline)
                    .gradientForeground(colors: [.green, .blue])
                    .padding(.horizontal, 10).bold()
                ForEach(viewModel.suggestedChats) { element in
                    NavigationLink {
                        MessagesView(exception: false, user: element.user, uid: element.user.id ?? "", tabException: true, canCall: true).enableFullSwipePop(isEnabled)
                    } label: {
                        HStack {
                            personView(size: 45)
                                .overlay(alignment: .bottomTrailing){
                                    if let silent = element.user.silent {
                                        if silent == 2 {
                                            Image(systemName: "moon.fill").foregroundStyle(.yellow).font(.headline)
                                        } else if silent == 3 {
                                            Image(systemName: "slash.circle.fill").foregroundStyle(.red).font(.headline)
                                        }
                                    }
                                }
                            VStack(alignment: .leading, spacing: 0){
                                HStack {
                                    Text(element.user.fullname).font(.headline).bold()
                                    Button(action: {
                                        withAnimation {
                                            viewModel.suggestedChats.removeAll(where: { $0.id == element.id })
                                        }
                                    }, label: {
                                        Image(systemName: "xmark").font(.caption).foregroundStyle(.white)
                                            .padding(6).background(.gray).clipShape(Circle())
                                    })
                                }
                                Text("@\(element.user.username)").font(.subheadline).foregroundStyle(.gray)
                            }
                        }
                        .padding(13)
                        .background(.gray.opacity(0.2))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1).opacity(0.7)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
        }.scrollIndicators(.hidden)
    }
}

struct MessagesLoader: View {
    @State private var isAnimating = false

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.orange, .clear, .orange]),
            startPoint: isAnimating ? .leading : .trailing,
            endPoint: isAnimating ? .trailing : .leading
        )
        .frame(height: 2.5)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating.toggle()
            }
        }
    }
}
