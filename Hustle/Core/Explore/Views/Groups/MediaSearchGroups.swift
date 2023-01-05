import SwiftUI
import Lottie
import Kingfisher

struct linkInfo: Identifiable, Hashable {
    let id: String
    let link: URL
    let username: String
    let channel: String
    let color: Color
}

struct MediaSearchGroups: View {
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: GroupViewModel
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @State var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    @State var selection: Int = 0
    @State var showAddFriends: Bool = false
    let randColors: [Color] = [.blue, .red, .green, .purple, .pink, .yellow, .indigo, .mint, .teal]
    @State var photos = [String]()
    @State var links = [linkInfo]()
    @State var sortedUsers = [User]()
    var coordinator: UICoordinator
    @Binding var replying: replyToGroup?
    @State var photosEmpty: Bool = true
    @Binding var show: Bool
    
    init(allPhotos: [(String, String)], replying: Binding<replyToGroup?>, show: Binding<Bool>) {
        var photos: [passBy] = []
        allPhotos.forEach { element in
            photos.append(passBy(id: element.0, photo: element.1))
        }
        if !photos.isEmpty {
            self._photosEmpty = State(initialValue: false)
        }
        self.coordinator = UICoordinator(photos: photos)
        self._replying = replying
        self._show = show
    }
    
    var body: some View {
        VStack {
            HStack {
                ZStack {
                    TextField("Search \(selection == 0 ? "Members" : selection == 1 ? "Media" : "Links")...", text: $searchText)
                        .tint(.blue)
                        .autocorrectionDisabled(true)
                        .padding(8)
                        .padding(.horizontal, 24)
                        .background(.gray.opacity(0.2))
                        .cornerRadius(25)
                        .overlay(
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(colorScheme == .dark ? .white : Color(UIColor.darkGray))
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                        )
                    HStack {
                        Spacer()
                        Button(action: {
                            searchText = ""
                        }, label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(colorScheme == .dark ? .white : Color(UIColor.darkGray))
                        }).padding(.trailing, 10)
                    }
                }
                .padding(.leading, 15).padding(.trailing, 8)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    show = false
                } label: {
                    Text("Done").foregroundStyle(.blue).font(.title3).bold()
                }.padding(.trailing, 15)
            }
            .onChange(of: searchText) { _, _ in
                if let index = viewModel.currentGroup, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if let users = viewModel.groups[index].1.users {
                        if sortedUsers.isEmpty {
                            sortedUsers = users
                        }
                        sortUsers()
                    }
                    if !links.isEmpty { sortLinks() }
                }
            }
            
            ZStack {
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selection = 0
                    } label: {
                        Text("Members")
                            .font(.body)
                            .foregroundStyle(selection == 0 ? Color(red: 0.5, green: 0.6, blue: 1.0) : Color.gray)
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selection = 1
                    } label: {
                        Text("Media")
                            .foregroundStyle(selection == 1 ? Color(red: 0.5, green: 0.6, blue: 1.0) : Color.gray)
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selection = 2
                    } label: {
                        Text("Links")
                            .foregroundStyle(selection == 2 ? Color(red: 0.5, green: 0.6, blue: 1.0) : Color.gray)
                    }
                }
            }
            .padding(.top)
            .padding(.horizontal, 30)
            ZStack {
                Divider().overlay(Color.gray)
                HStack {
                    if selection == 2 || selection == 1 {
                        Spacer()
                    }
                    Rectangle()
                        .foregroundStyle(Color(red: 0.5, green: 0.6, blue: 1.0))
                        .frame(width: widthOrHeight(width: true) * 0.33, height: 3).animation(.easeInOut, value: selection)
                    if selection == 0 || selection == 1 {
                        Spacer()
                    }
                }
            }
            TabView(selection: $selection) {
                ScrollView {
                    LazyVStack(spacing: 30){
                        if let id = auth.currentUser?.id, let index = viewModel.currentGroup, viewModel.groups[index].1.publicstatus || viewModel.groups[index].1.leaders.contains(id){
                            ZStack {
                                Button(action: {
                                    showAddFriends.toggle()
                                }, label: {
                                    HStack {
                                        Image(systemName: "person.crop.circle.fill.badge.plus").foregroundStyle(Color(red: 0.5, green: 0.6, blue: 1.0)).scaleEffect(1.2)
                                        
                                        Text("Invite Friends").bold().font(.headline).padding(.leading, 5)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }.padding(.horizontal)
                                })
                            }
                            .font(.headline)
                            .frame(height: 45)
                            .background(Color(UIColor.lightGray).opacity(0.2))
                            .cornerRadius(10, corners: .allCorners)
                            .padding(.top)
                            .padding(.horizontal)
                        }
                        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(spacing: 8){
                                HStack {
                                    Text("Results").font(.body).bold()
                                    Spacer()
                                }
                                VStack(spacing: 10){
                                    ForEach(sortedUsers) { user in
                                        NavigationLink {
                                            ProfileView(showSettings: false, showMessaging: true, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: true, isMain: false).enableFullSwipePop(true)
                                        } label: {
                                            HStack {
                                                HStack(spacing: 10){
                                                    if let image = user.profileImageUrl {
                                                        ZStack {
                                                            personView(size: 46)
                                                            KFImage(URL(string: image))
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                                .frame(width: 46, height: 46)
                                                                .clipShape(Circle())
                                                        }
                                                    } else {
                                                        personView(size: 46)
                                                    }
                                                    Text("@\(user.username)").font(.subheadline).bold().foregroundStyle(colorScheme == .dark ? .white : .black)
                                                }
                                                if let index = viewModel.currentGroup, (user.id ?? "") == viewModel.groups[index].1.leaders.first {
                                                    Image("g_owner")
                                                        .resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 22)
                                                }
                                                Spacer()
                                                if let index = viewModel.currentGroup, viewModel.groups[index].1.leaders.contains(user.id ?? "NA"){
                                                    Text("Leader").font(.caption).foregroundStyle(.white)
                                                }
                                            }
                                        }
                                        if user != sortedUsers.last {
                                            Divider().overlay(colorScheme == .dark ? Color.white : Color.gray)
                                        }
                                    }
                                }
                                .padding(.horizontal).padding(.vertical, 8)
                                .background(Color(UIColor.lightGray).opacity(0.2))
                                .cornerRadius(10, corners: .allCorners)
                            }.padding(.horizontal)
                        } else {
                            VStack(spacing: 8){
                                HStack {
                                    if let index = viewModel.currentGroup {
                                        Text("Leaders - \(viewModel.groups[index].1.leaders.count)").font(.body).bold()
                                    } else {
                                        Text("Leaders").font(.body).bold()
                                    }
                                    Spacer()
                                }
                                if let index = viewModel.currentGroup, let users = viewModel.groups[index].1.users {
                                    VStack(spacing: 10){
                                        let final = users.filter { user in
                                                    return viewModel.groups[index].1.leaders.contains(user.id ?? "")
                                                }
                                        ForEach(final) { user in
                                            NavigationLink {
                                                ProfileView(showSettings: false, showMessaging: true, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: true, isMain: false).enableFullSwipePop(true)
                                            } label: {
                                                HStack {
                                                    HStack(spacing: 10){
                                                        if let image = user.profileImageUrl {
                                                            ZStack {
                                                                personView(size: 46)
                                                                KFImage(URL(string: image))
                                                                    .resizable()
                                                                    .aspectRatio(contentMode: .fill)
                                                                    .frame(width: 46, height: 46)
                                                                    .clipShape(Circle())
                                                            }
                                                        } else {
                                                            personView(size: 46)
                                                        }
                                                        Text("@\(user.username)").font(.subheadline).bold().foregroundStyle(colorScheme == .dark ? .white : .black)
                                                    }
                                                    if (user.id ?? "") == viewModel.groups[index].1.leaders.first {
                                                        Image("g_owner")
                                                            .resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 22)
                                                    }
                                                    Spacer()
                                                }
                                            }
                                            if user != final.last {
                                                Divider().overlay(colorScheme == .dark ? Color.white : Color.gray)
                                            }
                                        }
                                    }
                                    .padding(.horizontal).padding(.vertical, 8)
                                    .background(Color(UIColor.lightGray).opacity(0.2))
                                    .cornerRadius(10, corners: .allCorners)
                                }
                            }.padding(.horizontal)
                            VStack(spacing: 8){
                                HStack {
                                    if let index = viewModel.currentGroup {
                                        Text("Members - \(max(0, viewModel.groups[index].1.members.count - viewModel.groups[index].1.leaders.count))").font(.body).bold()
                                    } else {
                                        Text("Members").font(.body).bold()
                                    }
                                    Spacer()
                                }
                                if let index = viewModel.currentGroup, let users = viewModel.groups[index].1.users {
                                    let final = users.filter { user in
                                                return !viewModel.groups[index].1.leaders.contains(user.id ?? "")
                                            }
                                    if !final.isEmpty {
                                        VStack(spacing: 10){
                                            ForEach(final) { user in
                                                NavigationLink {
                                                    ProfileView(showSettings: false, showMessaging: true, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: true, isMain: false).enableFullSwipePop(true)
                                                } label: {
                                                    HStack(spacing: 10){
                                                        if let image = user.profileImageUrl {
                                                            ZStack {
                                                                personView(size: 46)
                                                                KFImage(URL(string: image))
                                                                    .resizable()
                                                                    .aspectRatio(contentMode: .fill)
                                                                    .frame(width: 46, height: 46)
                                                                    .clipShape(Circle())
                                                            }
                                                        } else {
                                                            personView(size: 46)
                                                        }
                                                        Text("@\(user.username)").font(.subheadline).bold().foregroundStyle(colorScheme == .dark ? .white : .black)
                                                        Spacer()
                                                    }
                                                }
                                                if user != final.last {
                                                    Divider().overlay(colorScheme == .dark ? Color.white : Color.gray)
                                                }
                                            }
                                        }
                                        .padding(.horizontal).padding(.vertical, 8)
                                        .background(Color(UIColor.lightGray).opacity(0.2))
                                        .cornerRadius(10, corners: .allCorners)
                                    }
                                }
                            }.padding(.horizontal)
                        }
                        Spacer()
                    }
                }
                .tag(0)
                .scrollDismissesKeyboard(.immediately)
                .listRowInsets(EdgeInsets()).listStyle(PlainListStyle())
                
                VStack {
                    if photosEmpty {
                        LottieView(loopMode: .playOnce, name: "nofound").scaleEffect(0.3).offset(y: -90)
                    } else {
                        ScrollView {
                            Home31()
                                .environment(coordinator)
                                .allowsHitTesting(coordinator.selectedItem == nil)
                        }.scrollDismissesKeyboard(.immediately)
                    }
                }.tag(1)
                
                VStack {
                    if links.isEmpty {
                        LottieView(loopMode: .playOnce, name: "nofound").scaleEffect(0.3).offset(y: -90)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(links){ item in
                                    SingleGroupLinkView(user: item.username, link: item.link, channel: item.channel, color: item.color).dynamicTypeSize(.large)
                                }
                            }.padding(.horizontal)
                        }
                        .scrollDismissesKeyboard(.immediately)
                    }
                }.tag(2)
            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .overlay {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
                .opacity(coordinator.animateView ? 1 - coordinator.dragProgress : 0)
        }
        .overlay {
            if coordinator.selectedItem != nil {
                Detail(replying: $replying, replying2: .constant(nil), which: 3)
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
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAddFriends) {
            InviteFriendsSheet()
        }
        .onAppear {
            fetchData()
        }
    }
    func fetchData(){
        if let index = viewModel.currentGroup {
            viewModel.groups[index].1.messages?.forEach({ square in
                square.messages.forEach { message in
                    if !message.caption.isEmpty {
                        if let all = getAllUrl(text: message.caption), !all.isEmpty {
                            links += all.compactMap { singleURL in
                                linkInfo(id: UUID().uuidString, link: singleURL, username: message.username, channel: square.id, color: randColors.randomElement() ?? .orange)
                            }
                        }
                    }
                }
            })
        }
    }
    func sortUsers() {
        let lowercasedQuery = searchText.lowercased()
        sortedUsers.sort { (user1, user2) -> Bool in
            let lowercasedUser1 = user1.username.lowercased()
            let lowercasedUser2 = user2.username.lowercased()
            
            if lowercasedUser1.contains(lowercasedQuery) && !lowercasedUser2.contains(lowercasedQuery) {
                return true
            } else if !lowercasedUser1.contains(lowercasedQuery) && lowercasedUser2.contains(lowercasedQuery) {
                return false
            } else {
                return lowercasedUser1 < lowercasedUser2
            }
        }
    }
    func sortLinks() {
        let lowercasedQuery = searchText.lowercased()
        
        links.sort { (link1, link2) -> Bool in
            let score1 = calculateMatchScore(link: link1, query: lowercasedQuery)
            let score2 = calculateMatchScore(link: link2, query: lowercasedQuery)
            
            return score1 > score2
        }
    }
    func calculateMatchScore(link: linkInfo, query: String) -> Int {
        let channelScore = link.channel.lowercased().contains(query) ? 3 : 0
        let usernameScore = link.username.lowercased().contains(query) ? 2 : 0
        let linkScore = link.link.absoluteString.lowercased().contains(query) ? 1 : 0
        
        return channelScore + usernameScore + linkScore
    }
}

struct SingleGroupLinkView: View {
    let user: String
    let link: URL
    let channel: String
    let color: Color
    
    var body: some View {
        Link(destination: link, label: {
            VStack(spacing: 0){
                ZStack {
                    Rectangle().cornerRadius(12, corners: [.topLeft, .topRight]).foregroundStyle(Color(UIColor.lightGray)).opacity(0.2)
                    Image(systemName: "Link").font(.title).foregroundStyle(Color(red: 0.5, green: 0.6, blue: 1.0))
                    MainGroupLink(url: link)
                }.frame(height: widthOrHeight(width: true) * 0.4)
                VStack(spacing: 3){
                    Spacer()
                    HStack {
                        Text(link.absoluteString).lineLimit(1).font(.subheadline).foregroundStyle(.blue)
                        Spacer()
                    }.padding(.leading, 5)
                    HStack {
                        Text("@\(user)").font(.subheadline).lineLimit(1)
                        Spacer()
                    }.padding(.leading, 5)
                    HStack(spacing: 5){
                        ColorsCard(gradientColors: [color, .black], size: 20)
                        Text(channel).font(.subheadline).lineLimit(1)
                        Spacer()
                    }.padding(.leading, 3)
                    Spacer()
                }
                .frame(height: 75)
                .background(Color(UIColor.lightGray).opacity(0.55))
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(width: widthOrHeight(width: true) * 0.43)
        })
    }
}

struct SearchBarGroup: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    let fill: String
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        ZStack {
            TextField("Search \(fill)...", text: $text)
                .tint(.blue)
                .focused($focusedField, equals: .one)
                .autocorrectionDisabled(true)
                .padding(8)
                .padding(.horizontal, 24)
                .background(.gray.opacity(0.2))
                .cornerRadius(25)
                .overlay(
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(colorScheme == .dark ? .white : Color(UIColor.darkGray))
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                )
                .onAppear {
                    focusedField = .one
                }
            
            HStack {
                Spacer()
                Button(action: {
                    text = ""
                }, label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(colorScheme == .dark ? .white : Color(UIColor.darkGray))
                }).padding(.trailing, 10)
            }
        }.padding(.horizontal, 15)
    }
}
