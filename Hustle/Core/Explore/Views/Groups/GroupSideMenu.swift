import SwiftUI
import Kingfisher
import Firebase

struct tempUser: Identifiable, Equatable, Hashable {
    var id: String
    var username: String
    var photo: String?
}

struct UserActiveView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    let user: tempUser

    var body: some View {
        HStack(spacing: 8){
            NavigationLink {
                ProfileView(showSettings: false, showMessaging: true, uid: user.id, photo: user.photo ?? "", user: nil, expand: true, isMain: false)
                    .dynamicTypeSize(.large)
            } label: {
                if let image = user.photo {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                } else {
                    ZStack(alignment: .center){
                        Image(systemName: "circle.fill")
                            .resizable()
                            .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                            .frame(width: 38, height: 38)
                        Image(systemName: "questionmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 13, height: 16)
                    }
                }
                Circle().frame(width: 10, height: 10).foregroundColor(.green)
                Text(user.username).font(.system(size: 18)).bold()
            }
            Spacer()
        }
    }
}


struct GroupSideMenu: View {
    @EnvironmentObject var viewModel: GroupViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var explore: ExploreViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @Binding var show: Bool
    @Environment(\.colorScheme) var colorScheme
    let colors: [Color] = [.blue, .red, .green, .purple, .pink, .yellow, .indigo, .mint, .teal]
    @State var pickedC: [String : Color ] = [:]
    @State private var offset = CGSize.zero
    @State var deleteSquare: Bool = false
    @State var createSquare: Bool = false
    @State var activeUsers = [tempUser]()
    @State private var showAudioRoom = false
    @State private var showInvite = false
    @State private var muted = false
    @State private var joinCall = false
    @Binding var replying: replyToGroup?
    @State private var noNeed = ""
    @State private var showLeave = false
    let showSearch: Bool
    @Binding var showEditMenu: Bool
    @EnvironmentObject var messageModel: MessageViewModel
    @Binding var showSearchSheet: Bool
    @Binding var allPhotos: [(String, String)]
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.001)
                .onTapGesture {
                    withAnimation(.easeInOut){
                        show = false
                    }
                }
            HStack(spacing: 0){
                Spacer()
                ZStack {
                    Color.gray.opacity(0.001)
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 25).frame(width: 6, height: 45).foregroundColor(colorScheme == .dark ? .white : .gray).offset(x: -2)
                        Spacer()
                    }
                }.frame(width: 15)
                ZStack {
                    if colorScheme == .dark {
                        Color(red: 66 / 255.0, green: 69 / 255.0, blue: 73 / 255.0)
                    } else {
                        Color.black
                        Color.white.opacity(0.75)
                    }
                    VStack(spacing: 0){
                        if let index = viewModel.currentGroup {
                            ZStack {
                                KFImage(URL(string: viewModel.groups[index].1.imageUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .clipped()
                                    .ignoresSafeArea()
                                Text(viewModel.groups[index].1.title).font(.title2).bold()
                                    .padding(.horizontal, 14).padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .offset(y: 15)
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        if viewModel.groups[index].1.publicstatus || !viewModel.groups[index].1.members.contains(auth.currentUser?.id ?? "") {
                                            popRoot.hiddenMessage = "\(viewModel.groups[index].1.id)pub!@#$%^&*()\(viewModel.groups[index].1.title)"
                                            UIPasteboard.general.string = "send group link"
                                            popRoot.alertReason = "Group link copied"
                                        } else {
                                            popRoot.hiddenMessage = "\(viewModel.groups[index].1.id)priv!@#$%^&*()\(viewModel.groups[index].1.title)"
                                            UIPasteboard.general.string = "send invite link"
                                            popRoot.alertReason = "Invite link copied"
                                        }
                                        popRoot.alertImage = "link"
                                        withAnimation {
                                            popRoot.showAlert = true
                                        }
                                    }
                            }
                        } else {
                            ZStack { }.frame(height: 150)
                        }
                        
                        VStack(spacing: 12){
                            HStack {
                                if let index = viewModel.currentGroup {
                                    Text("\(viewModel.groups[index].0)").font(.title3)
                                    Spacer()
                                    if viewModel.groups[index].1.leaders.contains(auth.currentUser?.id ?? "") {
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showEditMenu = true
                                            viewModel.usersMenu()
                                        } label: {
                                            ZStack {
                                                Color.gray.opacity(0.001).frame(width: 30, height: 20)
                                                Image(systemName: "ellipsis").font(.title3)
                                                    .foregroundStyle(colorScheme == .dark ? .white : Color(UIColor.darkGray))
                                            }
                                        }
                                    } else {
                                        Menu {
                                            if !viewModel.groups[index].1.members.contains(auth.currentUser?.id ?? ""){
                                                if viewModel.requested.contains(viewModel.groups[index].1.id) {
                                                    Button {
                                                    } label: {
                                                        Label("Requested", systemImage: "checkmark.message")
                                                    }
                                                } else if viewModel.groups[index].1.publicstatus {
                                                    Button {
                                                        viewModel.groups[index].1.members.append(auth.currentUser?.id ?? "")
                                                        viewModel.joinGroup()
                                                        
                                                        if let x1 = explore.exploreGroups.firstIndex(where: { $0.id == viewModel.groups[index].1.id }) {
                                                            let temp = explore.exploreGroups.remove(at: x1)
                                                            explore.joinedGroups.append(temp)
                                                        }
                                                    } label: {
                                                        Label("Join Group", systemImage: "person.2.badge.key.fill")
                                                    }
                                                } else {
                                                    Button {
                                                        viewModel.requested.append(viewModel.groups[index].1.id)
                                                        if let leader = viewModel.groups[index].1.leaders.first {
                                                            viewModel.requestJoin(leader: leader, possible: messageModel.chats)
                                                        }
                                                    } label: {
                                                        Label("Request to Join", systemImage: "person.fill.questionmark")
                                                    }
                                                }
                                            } else {
                                                Button(role: .destructive) {
                                                    viewModel.leaveGroup(userId: auth.currentUser?.id ?? "")
                                                    
                                                    let id = viewModel.groups[index].1.id
                                                    if let all = auth.currentUser?.pinnedChats, all.contains(id) {
                                                        auth.currentUser?.pinnedChats?.removeAll(where: { $0 == id })
                                                        UserService().removeChatPin(id: id)
                                                    }
                                                } label: {
                                                    Label("Leave Group", systemImage: "trash")
                                                }
                                            }
                                        } label: {
                                            ZStack {
                                                Color.gray.opacity(0.001).frame(width: 30, height: 20)
                                                Image(systemName: "ellipsis").font(.title3)
                                                    .foregroundStyle(colorScheme == .dark ? .white : Color(UIColor.darkGray))
                                            }
                                        }
                                    }
                                }
                            }
                            if let index = viewModel.currentGroup, index < viewModel.groups.count && (viewModel.groups[index].1.publicstatus || viewModel.groups[index].1.members.contains(auth.currentUser?.id ?? "")) {
                                HStack(spacing: 8){
                                    Button {
                                        viewModel.usersMenu()
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        allPhotos = []
                                        viewModel.groups[index].1.messages?.forEach({ square in
                                            square.messages.forEach { message in
                                                if let image = message.image, !image.isEmpty {
                                                    allPhotos.append((message.id ?? "", image))
                                                }
                                            }
                                        })
                                        showSearchSheet.toggle()
                                        withAnimation(.easeInOut){
                                            show = false
                                        }
                                    } label: {
                                        TextField("", text: $noNeed)
                                            .disabled(true)
                                            .padding(8)
                                            .padding(.horizontal, 24)
                                            .background(colorScheme == .dark ? Color.black.opacity(0.7) : Color.black.opacity(0.12))
                                            .cornerRadius(25)
                                            .overlay(
                                                HStack(spacing: 5){
                                                    Image(systemName: "magnifyingglass")
                                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                                    Text("Search").font(.subheadline)
                                                    Spacer()
                                                }.padding(.leading, 8)
                                            )
                                    }
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showInvite.toggle()
                                    } label: {
                                        ZStack {
                                            Circle().frame(width: 36, height: 36)
                                                .foregroundStyle(.black).opacity(colorScheme == .dark ? 0.7 : 0.12)
                                            Image(systemName: "person.fill.badge.plus").font(.title3)
                                        }
                                    }
                                }
                            }
                        }.padding(.top, 20).padding(.horizontal, 15)
                        
                        Divider().overlay(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                            .padding(.top, 10)

                        if let index = viewModel.currentGroup, index < viewModel.groups.count && (viewModel.groups[index].1.publicstatus || viewModel.groups[index].1.members.contains(auth.currentUser?.id ?? "")) {
                            ScrollView {
                                VStack {
                                    HStack {
                                        Text("Squares - \((viewModel.groups[index].1.squares?.count ?? 0) + 4)").bold().font(.system(size: 18))
                                        
                                        Spacer()
                                        if let id = auth.currentUser?.id, let id2 = viewModel.groups[index].1.leaders.first, id == id2 {
                                            Button {
                                                createSquare.toggle()
                                            } label: {
                                                ZStack {
                                                    Circle().frame(width: 36, height: 36)
                                                        .foregroundStyle(.black).opacity(colorScheme == .dark ? 0.7 : 0.12)
                                                    Image(systemName: "plus").font(.title3)
                                                }
                                            }
                                        }
                                    }.padding(.top, 30)
                                    VStack(alignment: .leading, spacing: 5){
                                        if let rules = viewModel.groups[index].1.rules, !rules.isEmpty {
                                            Button {
                                                setSeen(switchingTo: "Rules")
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                viewModel.groups[index].0 = "Rules"
                                                withAnimation(.easeInOut){
                                                    show = false
                                                }
                                                replying = nil
                                            } label: {
                                                HStack {
                                                    ColorsCard(gradientColors: [pickedC["Rules"] ?? .orange, .black], size: 45)
                                                    Text("-Rules").font(.system(size: 18))
                                                    Spacer()
                                                }.background(viewModel.groups[index].0 == "Rules" ? Color(UIColor.lightGray) : .clear).cornerRadius(15)
                                            }
                                        }
                                        Button {
                                            setSeen(switchingTo: "Info/Description")
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            viewModel.groups[index].0 = "Info/Description"
                                            withAnimation(.easeInOut){
                                                show = false
                                            }
                                            replying = nil
                                        } label: {
                                            HStack {
                                                ColorsCard(gradientColors: [pickedC["Info/Description"] ?? .orange, .black], size: 45)
                                                Text("-Info/Description").font(.system(size: 18)).lineLimit(1)
                                                Spacer()
                                            }.background(viewModel.groups[index].0 == "Info/Description" ? Color(UIColor.lightGray) : .clear).cornerRadius(15)
                                        }
                                        if let id = auth.currentUser?.id, viewModel.groups[index].1.leaders.contains(id) || viewModel.groups[index].1.members.contains(id) {
                                            Button {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                showAudioRoom.toggle()
                                                replying = nil
                                            } label: {
                                                HStack {
                                                    ZStack {
                                                        ColorsCard(gradientColors: [pickedC["Main"] ?? .orange, .black], size: 45).opacity(0.0)
                                                        Image(systemName: "speaker.wave.2.fill").font(.system(size: 18))
                                                    }
                                                    Text("-Voice Chat").lineLimit(1).font(.system(size: 18))
                                                    Spacer()
                                                }
                                            }
                                        }
                                        Button {
                                            setSeen(switchingTo: "Main")
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            viewModel.groups[index].0 = "Main"
                                            withAnimation(.easeInOut){
                                                show = false
                                            }
                                        } label: {
                                            HStack {
                                                ColorsCard(gradientColors: [pickedC["Main"] ?? .orange, .black], size: 45)
                                                Text("-Main").font(.system(size: 18)).lineLimit(1)
                                                Spacer()
                                            }.background(viewModel.groups[index].0 == "Main" ? Color(UIColor.lightGray) : .clear).cornerRadius(15)
                                        }
                                        if let allSquares = viewModel.groups[index].1.squares {
                                            ForEach(allSquares, id: \.self) { square in
                                                Button {
                                                    setSeen(switchingTo: square)
                                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                    viewModel.groups[index].0 = square
                                                    withAnimation(.easeInOut){
                                                        show = false
                                                    }
                                                    if let messages = viewModel.groups[index].1.messages?.first(where: { $0.id == square }) {
                                                        if messages.messages.isEmpty {
                                                            viewModel.beginGroupConvo(groupId: viewModel.groups[index].1.id, devGroup: false, blocked: auth.currentUser?.blockedUsers ?? [], square: viewModel.groups[index].0)
                                                        }
                                                    } else {
                                                        viewModel.beginGroupConvo(groupId: viewModel.groups[index].1.id, devGroup: false, blocked: auth.currentUser?.blockedUsers ?? [], square: viewModel.groups[index].0)
                                                    }
                                                } label: {
                                                    HStack {
                                                        ColorsCard(gradientColors: [pickedC[square] ?? .orange, .black], size: 45)
                                                        Text("-\(square)").font(.system(size: 18))
                                                        Spacer()
                                                    }.background(viewModel.groups[index].0 == square ? Color(UIColor.lightGray) : .clear).cornerRadius(15)
                                                }
                                            }
                                        }
                                        if let sub = viewModel.subContainers.firstIndex(where: { $0.0 == viewModel.groups[index].1.id }) {
                                            let allSub = viewModel.subContainers[sub].1
                                            ForEach(Array(allSub.enumerated()), id: \.element.id) { (y, subSquare) in
                                                Button {
                                                    withAnimation {
                                                        viewModel.subContainers[sub].1[y].show.toggle()
                                                    }
                                                } label: {
                                                    HStack(spacing: 8){
                                                        if subSquare.show {
                                                            Image(systemName: "chevron.down")
                                                        } else {
                                                            Image(systemName: "chevron.right")
                                                        }
                                                        Text(subSquare.name)
                                                        Spacer()
                                                    }
                                                }.font(.system(size: 16)).offset(x: -5).padding(.top, 18)
                                                if subSquare.show {
                                                    ForEach(subSquare.sub, id: \.self) { square in
                                                        Button {
                                                            setSeen(switchingTo: square)
                                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                            viewModel.groups[index].0 = square
                                                            withAnimation(.easeInOut){
                                                                show = false
                                                            }
                                                            if let messages = viewModel.groups[index].1.messages?.first(where: { $0.id == square }) {
                                                                if messages.messages.isEmpty {
                                                                    viewModel.beginGroupConvo(groupId: viewModel.groups[index].1.id, devGroup: false, blocked: auth.currentUser?.blockedUsers ?? [], square: viewModel.groups[index].0)
                                                                }
                                                            } else {
                                                                viewModel.beginGroupConvo(groupId: viewModel.groups[index].1.id, devGroup: false, blocked: auth.currentUser?.blockedUsers ?? [], square: viewModel.groups[index].0)
                                                            }
                                                        } label: {
                                                            HStack {
                                                                ColorsCard(gradientColors: [pickedC[square] ?? .orange, .black], size: 45)
                                                                Text("-\(square)").font(.system(size: 18))
                                                                Spacer()
                                                            }.background(viewModel.groups[index].0 == square ? Color(UIColor.lightGray) : .clear).cornerRadius(15)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }.padding(.trailing, 8)
                                    
                                    HStack {
                                        Text("Online - \(activeUsers.count)").bold().font(.system(size: 18))
                                        Spacer()
                                    }.padding(.top, 25)
                                    VStack(alignment: .leading, spacing: 5){
                                        ForEach(activeUsers) { element in
                                            UserActiveView(user: element)
                                        }
                                    }.padding(.leading, 7)
                                    
                                    if viewModel.groups[index].1.publicstatus && !viewModel.groups[index].1.members.contains(auth.currentUser?.id ?? "") {
                                        HStack {
                                            Spacer()
                                            Button {
                                                viewModel.groups[index].1.members.append(auth.currentUser?.id ?? "")
                                                viewModel.joinGroup()
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                if let x1 = explore.exploreGroups.firstIndex(where: { $0.id == viewModel.groups[index].1.id }) {
                                                    let temp = explore.exploreGroups.remove(at: x1)
                                                    explore.joinedGroups.append(temp)
                                                }
                                            } label: {
                                                VStack {
                                                    LottieView(loopMode: .loop, name: "joinGroup")
                                                        .scaleEffect(0.8)
                                                        .frame(width: 50, height: 50)
                                                    Text("Join Group").font(.headline).bold()
                                                }
                                            }
                                            Spacer()
                                        }.padding(.vertical, 20)
                                    }
                                }.padding(.leading, 20).padding(.trailing, 15)
                            }
                        } else if let index = viewModel.currentGroup, !viewModel.groups[index].1.members.contains(auth.currentUser?.id ?? "") {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    if viewModel.requested.contains(viewModel.groups[index].1.id) {
                                        VStack {
                                            LottieView(loopMode: .playOnce, name: "requestedG")
                                                .scaleEffect(0.05)
                                                .frame(width: 50, height: 50)
                                            Text("Requested").font(.headline).bold()
                                        }
                                    } else {
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            viewModel.requested.append(viewModel.groups[index].1.id)
                                            if let leader = viewModel.groups[index].1.leaders.first {
                                                viewModel.requestJoin(leader: leader, possible: messageModel.chats)
                                            }
                                        } label: {
                                            VStack {
                                                LottieView(loopMode: .loop, name: "joinGroup")
                                                    .scaleEffect(0.8)
                                                    .frame(width: 50, height: 50)
                                                Text("Request Join").font(.headline).bold()
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }.padding(.bottom, 80)
                        }
                    }
                }.frame(width: widthOrHeight(width: true) * 0.65, height: widthOrHeight(width: false)).ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 12){
                        if let allMine = explore.userGroup, !allMine.isEmpty {
                            ForEach(allMine){ single in
                                HStack {
                                    Spacer()
                                    Button {
                                        viewModel.start(group: single, uid: auth.currentUser?.id ?? "", blocked: auth.currentUser?.blockedUsers ?? [])
                                    } label: {
                                        ZStack {
                                            Circle().foregroundStyle(.gray).opacity(0.4).frame(width: 50, height: 50)
                                            if let index = viewModel.currentGroup {
                                                KFImage(URL(string: single.imageUrl))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(RoundedRectangle(cornerRadius: viewModel.groups[index].1.id == single.id ? 12 : 30 ))
                                                    .animation(.easeInOut, value: viewModel.currentGroup)
                                            } else {
                                                KFImage(URL(string: single.imageUrl))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(RoundedRectangle(cornerRadius: 30 ))
                                            }
                                        }
                                    }
                                    if let index = viewModel.currentGroup {
                                        UnevenRoundedRectangle(topLeadingRadius: 30, bottomLeadingRadius: 30)
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                            .frame(width: 8, height: viewModel.groups[index].1.id == single.id ? 50 : 9)
                                            .animation(.easeInOut, value: viewModel.currentGroup)
                                    } else {
                                        UnevenRoundedRectangle(topLeadingRadius: 30, bottomLeadingRadius: 30)
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                            .frame(width: 8, height: 9)
                                    }
                                }
                            }
                        }
                        if let arr = auth.currentUser?.pinnedGroups, arr.count > 0 {
                            ForEach(explore.joinedGroups){ group in
                                HStack {
                                    Spacer()
                                    Button {
                                        viewModel.start(group: group, uid: auth.currentUser?.id ?? "", blocked: auth.currentUser?.blockedUsers ?? [])
                                    } label: {
                                        ZStack {
                                            Circle().foregroundStyle(.gray).opacity(0.4).frame(width: 50, height: 50)
                                            if let index = viewModel.currentGroup {
                                                KFImage(URL(string: group.imageUrl))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(RoundedRectangle(cornerRadius: viewModel.groups[index].1.id == group.id ? 12 : 30 ))
                                                    .animation(.easeInOut, value: viewModel.currentGroup)
                                            } else {
                                                KFImage(URL(string: group.imageUrl))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(RoundedRectangle(cornerRadius: 30 ))
                                            }
                                        }
                                    }
                                    if let index = viewModel.currentGroup {
                                        UnevenRoundedRectangle(topLeadingRadius: 30, bottomLeadingRadius: 30)
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                            .frame(width: 8, height: viewModel.groups[index].1.id == group.id ? 50 : 9)
                                            .animation(.easeInOut, value: viewModel.currentGroup)
                                    } else {
                                        UnevenRoundedRectangle(topLeadingRadius: 30, bottomLeadingRadius: 30)
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                            .frame(width: 8, height: 9)
                                    }
                                }
                            }
                        }
                        if auth.currentUser?.elo ?? 0 < 600 && auth.currentUser?.groupIdentifier != nil {
                            ZStack {
                                Circle().foregroundStyle(.gray).opacity(0.4).frame(width: 55, height: 55)
                                Image(systemName: "lock").foregroundStyle(.green).font(.headline)
                            }
                        } else {
                            NavigationLink {
                                CreateGroupView()
                            } label: {
                                ZStack {
                                    Circle().foregroundStyle(.gray).opacity(0.4).frame(width: 55, height: 55)
                                    Image(systemName: "lock.open").foregroundStyle(.green).font(.headline)
                                }
                            }
                        }
                        if showSearch {
                            NavigationLink {
                                SearchGroupsView()
                            } label: {
                                ZStack {
                                    Circle().foregroundStyle(.gray).opacity(0.4).frame(width: 55, height: 55)
                                    Image(systemName: "magnifyingglass").foregroundStyle(.green).font(.headline)
                                }
                            }
                        }
                    }.padding(.top, top_Inset())
                }.frame(width: 80).background(colorScheme == .dark ? Color(.systemGray4) : Color(UIColor.lightGray))
            }
            .offset(x: offset.width)
            .gesture (
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.width > 0 {
                            offset = gesture.translation
                        }
                    }.onEnded { _ in
                        withAnimation{
                            modifyState()
                        }
                    }
                
            )
        }
        .sheet(isPresented: $showAudioRoom, content: {
            if #available(iOS 16.4, *) {
                audioView().presentationCornerRadius(30)
            } else {
                audioView()
            }
        })
        .sheet(isPresented: $showInvite) {
            InviteFriendsSheet()
        }
        .alert("Do you want to DELETE this square?", isPresented: $deleteSquare) {
            Button("Confirm", role: .destructive) {
                if let index = viewModel.currentGroup {
                    ExploreService().removeSquare(groupId: viewModel.groups[index].1.id, square: viewModel.groups[index].0)
                    if var squares = viewModel.groups[index].1.squares {
                        squares.removeAll(where: { $0 == viewModel.groups[index].0 })
                        viewModel.groups[index].1.squares = squares
                    }
                    viewModel.groups[index].0 = "Main"
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $createSquare, content: {
            CreateSquare()
        })
        .fullScreenCover(isPresented: $joinCall, content: {
//            ScrollingVideoCallView()
        })
        .onAppear {
            if let index = viewModel.currentGroup {
                viewModel.groups[index].1.messages?.forEach({ element in
                    element.messages.forEach { text in
                        if isWithinLastHour(timestamp: text.timestamp) && !activeUsers.contains(where: { $0.id == text.uid }){
                            activeUsers.append(tempUser(id: text.uid, username: text.username, photo: text.profilephoto))
                        }
                    }
                })
                if let user = auth.currentUser, !activeUsers.contains(where: { $0.username == user.username }) {
                    activeUsers.append(tempUser(id: user.id ?? "", username: user.username, photo: user.profileImageUrl))
                }
                if let all = viewModel.groups[index].1.squares {
                    all.forEach { element in
                        pickedC[element] = colors.randomElement() ?? .orange
                    }
                }
            }
            pickedC["Info/Description"] = colors.randomElement() ?? .orange
            pickedC["Main"] = colors.randomElement() ?? .orange
            pickedC["Rules"] = colors.randomElement() ?? .orange
        }
    }
    func setSeen(switchingTo: String){
        if let index = viewModel.currentGroup, viewModel.groups[index].0 != switchingTo {
            viewModel.newIndex = nil
            let square = viewModel.groups[index].0
            if let first = viewModel.groups[index].1.messages?.first(where: { $0.id == square })?.messages.first {
                if let mid = first.id, first.uid != (auth.currentUser?.id ?? "") {
                    let fullID = viewModel.groups[index].1.id + square
                    LastSeenModel().setLastSeen(id: fullID, messageID: mid)
                }
            }
        }
    }
    func optionButton(option: String) -> some View {
        ZStack{
            Capsule().fill(Color.orange)
            Text(option).font(.subheadline).foregroundColor(.white)
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
                if let id = auth.currentUser?.id, let index = viewModel.currentGroup, viewModel.groups[index].1.publicstatus || viewModel.groups[index].1.leaders.contains(id){
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showAudioRoom = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15){
                            showInvite = true
                        }
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(.gray)
                            Image(systemName: "person.crop.circle.fill.badge.plus").foregroundStyle(.white)
                        }.frame(width: 30, height: 30)
                    })
                }
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15){
                            joinCall = true
                        }
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
                        if let index = viewModel.currentGroup {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                                viewModel.groups[index].0 = "Main"
                                withAnimation(.easeInOut){
                                    show = false
                                }
                            }
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
    func modifyState(){
        switch offset.width {
        case 50...500:
            withAnimation(.easeInOut){
                show = false
            }
            offset = .zero
        default:
            offset = .zero
        }
    }
    func isWithinLastHour(timestamp: Timestamp) -> Bool {
        let currentTime = Date()
        let timeDifference = currentTime.timeIntervalSince(timestamp.dateValue())
        return timeDifference <= 3600
    }
    func calculateHeight() -> CGFloat {
        let height = Double(activeUsers.count) * 40.0
        let max = widthOrHeight(width: false) * 0.2
        if height > max {
            return max
        } else {
            return height
        }
    }
}

struct ColorsCard: View {
    @State var rotation: CGFloat = 0.0
    var gradientColors: [Color]
    let size: CGFloat
    
    init(gradientColors: [Color], size: CGFloat) {
        self.gradientColors = gradientColors
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: size, height: size)
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .top,
                    endPoint: .bottom))
                .rotationEffect(.degrees(rotation))
                .mask {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(lineWidth: 3)
                        .frame(width: size / 2, height: size / 2)
                }
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
