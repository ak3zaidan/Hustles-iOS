import SwiftUI
import Firebase
import Kingfisher

struct GroupChatSettings: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showTitle: Bool = false
    @State private var showSettings: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var editName: Bool = false
    @State private var offset: Double = 0
    @State private var size: Double = 1.0
    @State private var opacity: Double = 1.0
    @State private var newName: String = ""
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: GroupChatViewModel
    @EnvironmentObject var viewModel1: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @Namespace private var namespace
    @State private var selectedImage: UIImage?
    @State private var newImage: Image?
    @State private var text1: String = "Recieved from ..."
    @State private var date1: String = "1d"
    @State var showAudioRoom: Bool = false
    @State var muted: Bool = false
    @State var showAddUser: Bool = false
    
    var coordinator: UICoordinator
    @Binding var replying: replyToGroup?
    @Binding var showSearch: Bool
    @Binding var viewOption: Bool
    let onClose: () -> Void
    
    @State var allU = [User]()
    @State private var showCamera: Bool = false
    @State var initialSend: messageSendType? = nil
    
    init(allMessages: [GroupMessage], replying: Binding<replyToGroup?>, showSearch: Binding<Bool>, viewOption: Binding<Bool>, groupPhoto: String?, onClose: @escaping () -> Void) {
        
        var photos: [passBy] = []
        allMessages.forEach { element in
            if let photo = element.imageUrl, !photo.isEmpty {
                photos.append(passBy(id: element.id ?? "", photo: photo))
            }
        }
        if let image = groupPhoto, !image.isEmpty {
            photos.append(passBy(id: "Main", photo: image))
        }
        
        self.coordinator = UICoordinator(photos: photos)
        self._replying = replying
        self._showSearch = showSearch
        self._viewOption = viewOption
        self.onClose = onClose
    }
    
    var body: some View {
        VStack(spacing: 5){
            header()
            ScrollView {
                LazyVStack(spacing: 13){
                    HStack {
                        Spacer()
                        if let index = viewModel.currentChat, let photo = viewModel.chats[index].photo, !photo.isEmpty {
                            ZStack {
                                singleHomeAnimator()
                                    .environment(coordinator)
                                    .allowsHitTesting(coordinator.selectedItem == nil)
                                Button(action: {
                                    showImagePicker = true
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }, label: {
                                    Image(systemName: "plus")
                                        .foregroundStyle(.white)
                                        .padding(6)
                                        .background(.blue)
                                        .clipShape(Circle())
                                }).offset(x: 33, y: 33)
                            }
                            .opacity(opacity)
                            .scaleEffect(size, anchor: .bottom)
                        } else {
                            Button(action: {
                                showImagePicker = true
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }, label: {
                                ZStack(alignment: .center){
                                    Circle()
                                        .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray))
                                        .frame(width: 90, height: 90)
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.white).font(.title3)
                                }
                                .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                .overlay {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "plus")
                                                .foregroundStyle(.white)
                                                .padding(6)
                                                .background(.blue)
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                                .opacity(opacity)
                                .scaleEffect(size, anchor: .bottom)
                            })
                        }
                        Spacer()
                    }.padding(.top, 5)
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                editName = true
                            }
                        }, label: {
                            if let index = viewModel.currentChat, let name = viewModel.chats[index].groupName, !name.isEmpty {
                                Text(name).font(.title2).bold()
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            } else {
                                HStack(spacing: 4){
                                    Image(systemName: "pencil").foregroundStyle(.blue).font(.headline)
                                    Text("Add Group Name").font(.title2).bold()
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                }
                            }
                        })
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Image(systemName: "message").foregroundStyle(.blue)
                        Text(text1).foregroundStyle(.gray)
                        Text(date1).foregroundStyle(.gray)
                        Spacer()
                    }
                    .font(.caption)
                    .onAppear {
                        if let index = viewModel.currentChat, let first = viewModel.chats[index].lastM {
                            let myUID = String((auth.currentUser?.id ?? "").prefix(6))
                            if (first.id ?? "").hasPrefix(myUID) {
                                text1 = "You sent a chat"
                            } else {
                                if let username = viewModel.chats[index].users?.first(where: { ($0.id ?? "").hasPrefix(first.id ?? "") }) {
                                    text1 = "Received from \(username)"
                                }
                            }
                            let mytime = first.timestamp
                            let dateString = mytime.dateValue().formatted(.dateTime.month().day().year().hour().minute())
                            let dateFormatter = DateFormatter()
                            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                            dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
                            if let date = dateFormatter.date(from:dateString){
                                if Calendar.current.isDateInToday(date){date1 = mytime.dateValue().formatted(.dateTime.hour().minute())}
                                else if Calendar.current.isDateInYesterday(date) {date1 = "Yesterday"}
                                else{
                                    if let dayBetween  = Calendar.current.dateComponents([.day], from: mytime.dateValue(), to: Date()).day{
                                        date1 = String(dayBetween + 1) + "d"
                                    }
                                }
                            }
                        }
                    }
                    HStack(spacing: 35){
                        Spacer()
                        Button(action: {
                            if let index = viewModel.currentChat {
                                if let title = viewModel.chats[index].groupName, !title.isEmpty {
                                    initialSend = messageSendType(id: viewModel.chats[index].id ?? "", title: title, type: 2)
                                } else if let title = viewModel.chats[index].users?.map({ $0.username }).joined(separator: ", ") {
                                    initialSend = messageSendType(id: viewModel.chats[index].id ?? "", title: title, type: 2)
                                }
                            }
                            showCamera = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label: {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(colorScheme == .dark ? .black : .white)
                                .clipShape(Capsule())
                                .shadow(color: colorScheme == .dark ? .white : .black, radius: 6)
                        })
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Image(systemName: "message.fill")
                                .font(.title2)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(colorScheme == .dark ? .black : .white)
                                .clipShape(Capsule())
                                .shadow(color: colorScheme == .dark ? .white : .black, radius: 6)
                        })
                        Button(action: {
                            viewOption = true
                            showSearch = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(colorScheme == .dark ? .black : .white)
                                .clipShape(Capsule())
                                .shadow(color: colorScheme == .dark ? .white : .black, radius: 6)
                        })
                        Button(action: {
                            showAudioRoom = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label: {
                            Image(systemName: "waveform")
                                .font(.title2)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(colorScheme == .dark ? .black : .white)
                                .clipShape(Capsule())
                                .shadow(color: colorScheme == .dark ? .white : .black, radius: 6)
                        })
                        Spacer()
                    }.padding(.top, 14)
                    
                    VStack(spacing: 8){
                        HStack {
                            Text("Group Members").font(.headline).bold()
                            Spacer()
                            Button {
                                showAddUser = true
                                viewModel1.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack(spacing: 4){
                                    Image(systemName: "plus").foregroundStyle(.blue)
                                    Text("Add")
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(.gray.opacity(0.3))
                                .clipShape(Capsule())
                            }
                        }
                        if let index = viewModel.currentChat, let users = viewModel.chats[index].users, !users.isEmpty{
                            VStack(spacing: 10){
                                ForEach(users) { user in
                                    NavigationLink {
                                        ProfileView(showSettings: false, showMessaging: true, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: nil, expand: false, isMain: false).enableFullSwipePop(true)
                                    } label: {
                                        gcUserRow(user: user)
                                    }
                                    if user != users.last {
                                        Divider().overlay(colorScheme == .dark ? Color.white : Color.gray)
                                    }
                                }
                            }
                            .padding(.horizontal).padding(.vertical, 8)
                            .background(.gray.opacity(0.25))
                            .cornerRadius(10, corners: .allCorners)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .frame(height: 90)
                                    .shadow(color: colorScheme == .dark ? .white : .black.opacity(0.4), radius: 6)
                                HStack {
                                    Spacer()
                                    Text("group members will appear here")
                                        .font(.caption).foregroundStyle(.gray)
                                    Spacer()
                                }
                            }
                        }
                    }.padding()
                    VStack(spacing: 8){
                        HStack {
                            Spacer()
                            Text("Chat attachments").font(.headline).bold()
                            Spacer()
                        }
                        if coordinator.items.isEmpty {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .frame(height: 90)
                                    .shadow(color: colorScheme == .dark ? .white : .black.opacity(0.4), radius: 6)
                                HStack {
                                    Spacer()
                                    Text("chat photos and media will appear here")
                                        .font(.caption).foregroundStyle(.gray)
                                    Spacer()
                                }
                            }.padding(.horizontal)
                        } else {
                            Home31()
                                .padding(.vertical, 15)
                                .environment(coordinator)
                                .allowsHitTesting(coordinator.selectedItem == nil)
                        }
                    }
                }
                .background(GeometryReader {
                    Color.clear.preference(key: ViewOffsetKey.self,
                                           value: -$0.frame(in: .named("scroll")).origin.y)
                })
                .onPreferenceChange(ViewOffsetKey.self) { value in
                    offset = value
                    if offset > 30 {
                        withAnimation {
                            showTitle = true
                        }
                    } else {
                        showTitle = false
                    }
                    getSize()
                    getOpac()
                }
                Color.clear.frame(height: 70)
            }
            .scrollIndicators(.hidden)
        }
        .overlay {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
                .opacity(coordinator.animateView ? 1 - coordinator.dragProgress : 0)
        }
        .overlay {
            if coordinator.selectedItem != nil {
                Detail(replying: $replying, replying2: .constant(nil), which: 2)
                    .environment(coordinator)
                    .allowsHitTesting(coordinator.showDetailView)
            }
        }
        .overlayPreferenceValue(HeroKey.self) { value in
            if let selectedItem = coordinator.selectedItem,
               let sAnchor = value[selectedItem.id + "SOURCE"],
               let dAnchor = value[selectedItem.id + "DEST"] {
                HeroLayer(
                    item: selectedItem,
                    sAnchor: sAnchor,
                    dAnchor: dAnchor
                )
                .environment(coordinator)
            }
        }
        .fullScreenCover(isPresented: $showCamera, content: {
            MessageCamera(initialSend: $initialSend, showMemories: true)
        })
        .sheet(isPresented: $showAddUser, content: {
            ZStack {
                VStack {
                    HStack {
                        Spacer()
                        Text("Add to Group").font(.title2).bold()
                        Spacer()
                    }.padding(.top, 5)
                    HStack {
                        TextField("", text: $viewModel1.searchText)
                            .padding(.leading, 44)
                            .padding(.trailing)
                            .tint(.blue)
                            .autocorrectionDisabled(true)
                            .padding(.vertical, 7)
                            .background(.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .onSubmit {
                                if !viewModel1.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    viewModel1.UserSearch(userId: auth.currentUser?.id ?? "")
                                    viewModel1.submitted = true
                                }
                            }
                            .overlay {
                                HStack {
                                    Text("To:").font(.headline).foregroundStyle(.gray)
                                    Spacer()
                                    if viewModel1.loading {
                                        ProgressView()
                                    }
                                }.padding(.horizontal)
                            }
                            .onChange(of: viewModel1.searchText) { _, _ in
                                viewModel1.noUsersFound = false
                                viewModel1.UserSearchBestFit()
                                viewModel1.submitted = false
                            }
                    }.padding(.horizontal).padding(.top)
                    if !allU.isEmpty {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 8){
                                ForEach(allU) { element in
                                    TagView(element.username).transition(.scale.combined(with: .opacity))
                                }
                            }.padding(.horizontal).padding(.top, 5)
                        }.frame(height: 40).scrollIndicators(.hidden)
                    }
                    ScrollView {
                        LazyVStack {
                            if !viewModel1.matchedUsers.isEmpty {
                                HStack {
                                    Text("Results").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                    Spacer()
                                }.padding(.top)
                                VStack(spacing: 8){
                                    ForEach(viewModel1.matchedUsers){ user in
                                        Button {
                                            withAnimation(.easeIn(duration: 0.15)){
                                                if allU.contains(where: { $0.username == user.username }) {
                                                    allU.removeAll(where: { $0.username == user.username })
                                                } else {
                                                    allU.insert(user, at: 0)
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
                            }
                            
                            let eight = viewModel1.chats.filter { $0.user.dev == nil }.prefix(8)
                            if !eight.isEmpty {
                                HStack {
                                    Text("Best Friends").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                    Spacer()
                                }.padding(.top, 6)
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(eight){ chat in
                                        Button {
                                            withAnimation(.easeIn(duration: 0.15)){
                                                if allU.contains(where: { $0.username == chat.user.username }) {
                                                    allU.removeAll(where: { $0.username == chat.user.username })
                                                } else {
                                                    allU.insert(chat.user, at: 0)
                                                }
                                            }
                                        } label: {
                                            userViewOneX(user: chat.user, selected: allU.contains(where: { $0.username == chat.user.username }))
                                        }
                                    }
                                }
                            }
                            let all = viewModel1.chats.filter { $0.user.dev == nil }
                            if !all.isEmpty {
                                HStack {
                                    Text("Recents").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                    Spacer()
                                }.padding(.top)
                                ScrollView(.horizontal) {
                                    HStack(spacing: 8) {
                                        Color.clear.frame(width: 1)
                                        ForEach(all){ chat in
                                            Button {
                                                withAnimation(.easeIn(duration: 0.15)){
                                                    if allU.contains(where: { $0.username == chat.user.username }) {
                                                        allU.removeAll(where: { $0.username == chat.user.username })
                                                    } else {
                                                        allU.insert(chat.user, at: 0)
                                                    }
                                                }
                                            } label: {
                                                userViewTwoX(user: chat.user, selected: allU.contains(where: { $0.username == chat.user.username }))
                                            }
                                        }
                                        Color.clear.frame(width: 10)
                                    }
                                }.frame(height: 130).offset(x: -5).scrollIndicators(.hidden)
                            }
                            if !viewModel1.following.isEmpty {
                                HStack {
                                    Text("Following").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                    Spacer()
                                }.padding(.top)
                                VStack(spacing: 8){
                                    ForEach(viewModel1.following){ user in
                                        Button {
                                            withAnimation(.easeIn(duration: 0.15)){
                                                if allU.contains(where: { $0.username == user.username }) {
                                                    allU.removeAll(where: { $0.username == user.username })
                                                } else {
                                                    allU.insert(user, at: 0)
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
                            }
                            if !viewModel1.mutualFriends.isEmpty {
                                HStack {
                                    Text("Mutual Friends").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                    Spacer()
                                }.padding(.top)
                                VStack(spacing: 8){
                                    let all = viewModel1.mutualFriends.filter { $0.dev == nil && $0.id != auth.currentUser?.id }
                                    ForEach(all){ user in
                                        Button {
                                            withAnimation(.easeIn(duration: 0.15)){
                                                if allU.contains(where: { $0.username == user.username }) {
                                                    allU.removeAll(where: { $0.username == user.username })
                                                } else {
                                                    allU.insert(user, at: 0)
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
                            }
                            Color.clear.frame(height: !allU.isEmpty ? 155 : 85)
                        }.padding(.horizontal, 12)
                    }
                    .scrollDismissesKeyboard(.immediately)
                }.ignoresSafeArea().padding(.top)
                VStack {
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if let index = viewModel.currentChat, let docID = viewModel.chats[index].id {
                            allU.forEach { element in
                                if let id = element.id, !viewModel.chats[index].allUsersUID.contains(id) {
                                    DispatchQueue.main.async {
                                        viewModel.chats[index].allUsersUID.append(id)
                                        if let curr_users = viewModel.chats[index].users {
                                            viewModel.chats[index].users = curr_users + [element]
                                        } else {
                                            viewModel.chats[index].users = [element]
                                        }
                                    }
                                    if let x = viewModel.user_colors.firstIndex(where: { $0.0 == docID }) {
                                        viewModel.user_colors[x].1[String(id.prefix(6))] = [.blue, .green, .yellow, .purple, .orange, .indigo, .brown, .pink, .teal, .mint, .cyan, .gray].randomElement()
                                    }
                                    GroupChatService().addUserToGroup(docID: docID, userID: id)
                                    
                                    let prefix = (auth.currentUser?.id ?? "").prefix(6)
                                    let m_id = prefix + UUID().uuidString.prefix(7)
                                    let username = auth.currentUser?.username ?? ""
                                    GroupChatService().sendMessage(docID: docID, text: "\(username) \(element.username)", imageUrl: nil, messageID: String(m_id), replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: nil, audioURL: nil, fileURL: nil, exception: true, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                                    
                                    let new = GroupMessage(id: String(m_id), text: "\(username) \(element.username)", normal: true, timestamp: Timestamp())
                                    
                                    DispatchQueue.main.async {
                                        viewModel.chats[index].lastM = new
                                        viewModel.chats[index].messages?.insert(new, at: 0)
                                    }
                                }
                            }
                        }
                        showAddUser = false
                    }, label: {
                        Text("Add").foregroundStyle(.white).font(.headline).bold()
                            .padding(.vertical, 10).padding(.horizontal, 70)
                            .background(allU.isEmpty ? .gray : Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                            .clipShape(Capsule())
                    }).padding(.bottom)
                }
            }
            .presentationDetents([.large])
        })
        .sheet(isPresented: $showAudioRoom, content: {
            if #available(iOS 16.4, *) {
                audioView().presentationCornerRadius(30)
            } else {
                audioView()
            }
        })
        .sheet(isPresented: $showImagePicker, onDismiss: loadImage){
            ImagePicker(selectedImage: $selectedImage).tint(colorScheme == .dark ? .white : .black)
        }
        .padding(.top, top_Inset())
        .overlay(content: {
            if showSettings || editName {
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 10, opaque: true)
                    .background(colorScheme == .light ? .black.opacity(0.5) : .white.opacity(0.5))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSettings = false
                            editName = false
                        }
                    }
            }
        })
        .overlay(content: {
            if editName {
                VStack {
                    HStack(spacing: 20){
                        Spacer()
                        VStack(spacing: 20){
                            Text("Edit Group Name").font(.title3).bold()
                            
                            TextField("Name Group", text: $newName)
                                .tint(.blue)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal, 6)
                                .padding(9)
                                .background(.gray.opacity(0.25))
                                .clipShape(Capsule())
                            
                            Button {
                                if !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        editName = false
                                    }
                                    if let index = viewModel.currentChat {
                                        viewModel.chats[index].groupName = newName
                                        GroupChatService().editGroupName(groupID: viewModel.chats[index].id ?? "", newName: newName)
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    newName = ""
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Save").font(.title3).bold()
                                        .foregroundStyle(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .background(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                                .clipShape(Capsule())
                            }
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    editName = false
                                }
                            } label: {
                                Text("Cancel").font(.title3).bold()
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            }
                        }.padding(.vertical)
                        Spacer()
                    }
                    .background(colorScheme == .dark ? Color(UIColor.darkGray) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 25)
                    Spacer()
                }
                .padding(.top, 140)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        })
        .overlay(content: {
            if showSettings {
                VStack(spacing: 10){
                    Spacer()
                    VStack(spacing: 10){
                        HStack {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if let index = viewModel.currentChat, let id = viewModel.chats[index].id {
                                    let username = auth.currentUser?.username ?? ""
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                                        GroupChatService().leaveGroup(docID: id, username: username)
                                        viewModel.chats.removeAll(where: { $0.id == id })
                                    }
                                    if let all = auth.currentUser?.pinnedChats, all.contains(id) {
                                        auth.currentUser?.pinnedChats?.removeAll(where: { $0 == id })
                                        UserService().removeChatPin(id: id)
                                    }
                                }
                                onClose()
                            }, label: {
                                Text("Leave Group")
                                    .font(.headline).bold()
                                    .foregroundStyle(.red)
                            })
                            Spacer()
                        }
                        Divider().overlay(.gray)
                        HStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showSettings = false
                                }
                                viewModel1.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showAddUser = true
                            }, label: {
                                Text("Add Members to Group")
                                    .font(.headline).bold()
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            })
                            Spacer()
                        }
                        Divider().overlay(.gray)
                        HStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showSettings = false
                                    editName = true
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }, label: {
                                Text("Edit Group Name")
                                    .font(.headline).bold()
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            })
                            Spacer()
                        }
                        Divider().overlay(.gray)
                        HStack {
                            Button(action: {
                                
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }, label: {
                                Text("Mute group")
                                    .font(.headline).bold()
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            })
                            Spacer()
                        }
                        Divider().overlay(.gray)
                        HStack {
                            Button(action: {
                                if let ix = viewModel.currentChat, let uid = auth.currentUser?.id, let docID = viewModel.chats[ix].id {
                                    let arr = viewModel.chats[ix].sharingLocationUIDS ?? []
                                    if arr.contains(uid) {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        viewModel.chats[ix].sharingLocationUIDS?.removeAll(where: { $0 == uid })
                                        GroupChatService().shareLocation(docID: docID, shouldShare: false)
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        if arr.isEmpty {
                                            viewModel.chats[ix].sharingLocationUIDS = [uid]
                                        } else {
                                            viewModel.chats[ix].sharingLocationUIDS?.append(uid)
                                        }
                                        GroupChatService().shareLocation(docID: docID, shouldShare: true)
                                    }
                                } else {
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                }
                            }, label: {
                                if let ix = viewModel.currentChat, let arr = viewModel.chats[ix].sharingLocationUIDS {
                                    if arr.contains(auth.currentUser?.id ?? "NA") {
                                        Text("Stop Sharing Live Location")
                                            .font(.headline).bold().foregroundStyle(.red)
                                    } else {
                                        Text("Share Live Location")
                                            .font(.headline).bold().foregroundStyle(.green)
                                    }
                                } else {
                                    Text("Share Live Location")
                                        .font(.headline).bold().foregroundStyle(.green)
                                }
                            })
                            Spacer()
                        }
                    }
                    .padding(12)
                    .background(colorScheme == .dark ? Color(UIColor.darkGray) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSettings = false
                        }
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .frame(height: 40)
                                .foregroundStyle(colorScheme == .dark ? Color(UIColor.darkGray) : .white)
                            Text("Done")
                                .font(.headline).bold()
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                    })
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 50)
                .padding(.horizontal, 20)
            }
        })
        .ignoresSafeArea()
    }
    func loadImage() {
        guard let selectedImage = selectedImage else { return }
        newImage = Image(uiImage: selectedImage)
        
        if let index = viewModel.currentChat {
            ImageUploader.uploadImage(image: selectedImage, location: "groupChatPhotos", compression: 0.25) { new, _ in
                if !new.isEmpty {
                    viewModel.chats[index].photo = new
                    GroupChatService().editGroupPhoto(groupID: viewModel.chats[index].id ?? "", newP: new)
                }
            }
        }
    }
    func header() -> some View {
        ZStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    ZStack {
                        Rectangle().frame(width: 60, height: 40)
                            .foregroundStyle(.gray).opacity(0.001)
                        Image(systemName: "chevron.down")
                            .font(.title2).bold()
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                })
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettings = true
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Rectangle().frame(width: 60, height: 40)
                            .foregroundStyle(.gray).opacity(0.001)
                        Image(systemName: "ellipsis")
                            .font(.title2).bold()
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                })
            }
            if showTitle {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            editName = true
                        }
                    }, label: {
                        if let index = viewModel.currentChat, let name = viewModel.chats[index].groupName, !name.isEmpty {
                            Text(name).font(.title2).bold()
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        } else {
                            HStack(spacing: 4){
                                Image(systemName: "pencil").foregroundStyle(.blue).font(.headline)
                                Text("Add Group Name").font(.title2).bold()
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            }
                        }
                    })
                    Spacer()
                }.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    func getSize(){
        let offset = offset + 104.0
        if offset <= 0 {
            size = 1.0
        } else {
            let ratio = 1 - min(1.0, (offset / 90.0))
            self.size = ratio * 1.0
        }
    }
    func getOpac(){
        let offset = offset + 104.0
        if offset <= 0 {
            opacity = 1.0
        } else {
            let ratio = 1 - min(1.0, (offset / 90.0))
            self.opacity = ratio * 1.0
        }
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
                    viewModel1.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                        showAddUser = true
                    }
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                            presentationMode.wrappedValue.dismiss()
                        }
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
    @ViewBuilder
    func TagView(_ tag: String) -> some View {
        Button {
            withAnimation(.easeIn(duration: 0.15)){
                allU.removeAll(where: { $0.username == tag })
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "xmark").font(.subheadline)
                Text(tag).font(.callout).fontWeight(.semibold)
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 35)
            .padding(.horizontal, 7)
            .background {
                Capsule().fill(Color.gray.gradient).opacity(0.3)
            }
        }
    }
}
