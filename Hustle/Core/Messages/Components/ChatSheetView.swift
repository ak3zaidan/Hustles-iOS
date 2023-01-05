import SwiftUI
import Firebase
import Kingfisher

struct ChatSheetView: View {
    @State var newGroupName: String = ""
    @State var chatOrGroup: Bool = true
    @State var allU = [userSend]()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var groupModel: GroupChatViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Binding var navigateNow: Bool
    @Binding var navigateNowGroup: Bool
    @Binding var selectedUser: String?
    
    var body: some View {
        ZStack {
            VStack {
                pickView()
                if !chatOrGroup || allU.count > 1 {
                    groupPart()
                }
                HStack {
                    TextField("", text: $viewModel.searchText)
                        .padding(.leading, 44)
                        .padding(.trailing)
                        .tint(.blue)
                        .autocorrectionDisabled(true)
                        .padding(.vertical, 7)
                        .background(.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .onSubmit {
                            if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                viewModel.UserSearch(userId: auth.currentUser?.id ?? "")
                                viewModel.submitted = true
                            }
                        }
                        .overlay {
                            HStack {
                                Text("To:").font(.headline).foregroundStyle(.gray)
                                Spacer()
                                if viewModel.loading {
                                    ProgressView()
                                }
                            }.padding(.horizontal)
                        }
                        .onChange(of: viewModel.searchText) { _, _ in
                            viewModel.noUsersFound = false
                            viewModel.UserSearchBestFit()
                            viewModel.submitted = false
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
                        if !viewModel.matchedUsers.isEmpty {
                            HStack {
                                Text("Results").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                Spacer()
                            }.padding(.top).padding(.horizontal, 12)
                            VStack(spacing: 8){
                                ForEach(viewModel.matchedUsers){ user in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)){
                                            if allU.contains(where: { $0.username == user.username }) {
                                                allU.removeAll(where: { $0.username == user.username })
                                            } else {
                                                allU.insert(userSend(id: user.id ?? "", username: user.username), at: 0)
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
                            .padding(.horizontal, 12)
                        }
                        
                        let eight = viewModel.chats.filter { $0.user.dev == nil }.prefix(8)
                        if !eight.isEmpty {
                            HStack {
                                Text("Best Friends").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                Spacer()
                            }.padding(.top, 6).padding(.horizontal, 12)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(eight){ chat in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)){
                                            if allU.contains(where: { $0.username == chat.user.username }) {
                                                allU.removeAll(where: { $0.username == chat.user.username })
                                            } else {
                                                allU.insert(userSend(id: chat.user.id ?? "", username: chat.user.username), at: 0)
                                            }
                                        }
                                    } label: {
                                        userViewOneX(user: chat.user, selected: allU.contains(where: { $0.username == chat.user.username }))
                                    }
                                }
                            }.padding(.horizontal, 12)
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
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.15)){
                                                if allU.contains(where: { $0.username == chat.user.username }) {
                                                    allU.removeAll(where: { $0.username == chat.user.username })
                                                } else {
                                                    allU.insert(userSend(id: chat.user.id ?? "", username: chat.user.username), at: 0)
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
                        if !viewModel.following.isEmpty {
                            HStack {
                                Text("Following").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                Spacer()
                            }.padding(.top).padding(.horizontal, 12)
                            VStack(spacing: 8){
                                ForEach(viewModel.following){ user in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)){
                                            if allU.contains(where: { $0.username == user.username }) {
                                                allU.removeAll(where: { $0.username == user.username })
                                            } else {
                                                allU.insert(userSend(id: user.id ?? "", username: user.username), at: 0)
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
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)){
                                            if allU.contains(where: { $0.username == user.username }) {
                                                allU.removeAll(where: { $0.username == user.username })
                                            } else {
                                                allU.insert(userSend(id: user.id ?? "", username: user.username), at: 0)
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
                            .padding(.horizontal, 12)
                        }
                        Color.clear.frame(height: !allU.isEmpty ? 155 : 85)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            }.ignoresSafeArea().padding(.top)
            VStack {
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let first = allU.first, chatOrGroup && allU.count == 1 {
                        selectedUser = first.id
                        presentationMode.wrappedValue.dismiss()
                        navigateNow = true
                    } else if allU.count > 1 {
                        let newGroupID = UUID().uuidString
                        let all_uids = allU.map({ $0.id })
                        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newGroupName
                        
                        let prefix = String((auth.currentUser?.id ?? "").prefix(6))
                        let tempMessage = GroupMessage(id: "\(prefix)\(UUID().uuidString)", seen: false, text: "You created a group", normal: true, timestamp: Timestamp())
                        
                        let newGroup = GroupConvo(id: newGroupID, groupName: name, allUsersUID: all_uids, timestamp: Timestamp(), lastM: tempMessage, messages: [tempMessage])
                        
                        DispatchQueue.main.async {
                            groupModel.chats.append(newGroup)
                            
                            GroupChatService().makeGC(name: name, allU: all_uids, groupChatID: newGroupID, fullname: auth.currentUser?.username ?? "")
                            
                            selectedUser = newGroupID
                            presentationMode.wrappedValue.dismiss()
                            navigateNowGroup = true
                        }
                    }
                }, label: {
                    Text("Chat").foregroundStyle(.white).font(.headline).bold()
                        .padding(.vertical, 10).padding(.horizontal, 70)
                        .background(allU.isEmpty ? .gray : Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                        .clipShape(Capsule())
                }).padding(.bottom)
            }
        }
        .presentationDetents([.large])
        .onChange(of: allU) { _, _ in
            if allU.count > 1 {
                if chatOrGroup {
                    withAnimation {
                        chatOrGroup = false
                    }
                }
            } else {
                if !chatOrGroup {
                    withAnimation {
                        chatOrGroup = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func TagView(_ tag: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)){
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
    func groupPart() -> some View {
        HStack {
            Spacer()
            TextField("", text: $newGroupName)
                .font(.title3).bold()
                .tint(.blue)
                .submitLabel(.done)
                .frame(width: 200)
                .padding(.leading, 47)
                .background {
                    if newGroupName.isEmpty {
                        Text("New Group Name")
                            .font(.title3)
                    }
                }
            Spacer()
        }
        .padding(.top)
    }
    func pickView() -> some View {
        VStack {
            HStack(spacing: 80){
                Button(action: {
                    withAnimation {
                        chatOrGroup = true
                    }
                }, label: {
                    HStack(spacing: 5){
                        Image(systemName: "message").font(.headline)
                        Text("New Chat")
                    }.font(.title3).foregroundStyle(chatOrGroup ? (colorScheme == .dark ? .white : .black) : .gray)
                })
                Button(action: {
                    withAnimation {
                        chatOrGroup = false
                    }
                }, label: {
                    HStack(spacing: 5){
                        Image(systemName: "person.2").font(.headline)
                        Text("New Group")
                    }.font(.title3).foregroundStyle(!chatOrGroup ? (colorScheme == .dark ? .white : .black) : .gray)
                })
            }
            ZStack {
                Divider().overlay(.gray).frame(height: 1)
                HStack {
                    if !chatOrGroup {
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: widthOrHeight(width: true) * 0.5, height: 2)
                        .animation(.easeInOut(duration: 0.3), value: chatOrGroup)
                    if chatOrGroup {
                        Spacer()
                    }
                }
            }
        }
    }
}

struct CallSheetView: View {
    @State var newGroupName: String = ""
    @State var chatOrGroup: Bool = true
    @State var allU: userSend? = nil
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        ZStack {
            VStack {
                pickView()
                HStack {
                    TextField("", text: $viewModel.searchText)
                        .padding(.leading, 44)
                        .padding(.trailing)
                        .tint(.blue)
                        .autocorrectionDisabled(true)
                        .padding(.vertical, 7)
                        .background(.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .onSubmit {
                            if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                viewModel.UserSearch(userId: auth.currentUser?.id ?? "")
                                viewModel.submitted = true
                            }
                        }
                        .overlay {
                            HStack {
                                Text("To:").font(.headline).foregroundStyle(.gray)
                                Spacer()
                                if viewModel.loading {
                                    ProgressView()
                                } else if let user = allU {
                                    TagView(user.username)
                                }
                            }.padding(.leading).padding(.trailing, 1)
                        }
                        .onChange(of: viewModel.searchText) { _, _ in
                            viewModel.noUsersFound = false
                            viewModel.UserSearchBestFit()
                            viewModel.submitted = false
                        }
                }.padding(.horizontal).padding(.top)
                ScrollView {
                    LazyVStack {
                        if !viewModel.matchedUsers.isEmpty {
                            HStack {
                                Text("Results").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                Spacer()
                            }.padding(.top)
                            VStack(spacing: 8){
                                ForEach(viewModel.matchedUsers){ user in
                                    Button {
                                        if let temp = allU, temp.username == user.username {
                                            allU = nil
                                        } else {
                                            allU = userSend(id: user.id ?? "", username: user.username)
                                        }
                                    } label: {
                                        userViewThreeX(user: user, selected: allU?.username ?? "" == user.username)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                            .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .cornerRadius(8, corners: .allCorners)
                        }
                        
                        let eight = viewModel.chats.filter { $0.user.dev == nil }.prefix(8)
                        if !eight.isEmpty {
                            HStack {
                                Text("Best Friends").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                Spacer()
                            }.padding(.top, 6)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(eight){ chat in
                                    Button {
                                        if let temp = allU, temp.username == chat.user.username {
                                            allU = nil
                                        } else {
                                            allU = userSend(id: chat.user.id ?? "", username: chat.user.username)
                                        }
                                    } label: {
                                        userViewOneX(user: chat.user, selected: allU?.username ?? "" == chat.user.username)
                                    }
                                }
                            }
                        }
                        let all = viewModel.chats.filter { $0.user.dev == nil }
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
                                            if let temp = allU, temp.username == chat.user.username {
                                                allU = nil
                                            } else {
                                                allU = userSend(id: chat.user.id ?? "", username: chat.user.username)
                                            }
                                        } label: {
                                            userViewTwoX(user: chat.user, selected: allU?.username ?? "" == chat.user.username)
                                        }
                                    }
                                    Color.clear.frame(width: 10)
                                }
                            }.frame(height: 130).offset(x: -5).scrollIndicators(.hidden)
                        }
                        if !viewModel.following.isEmpty {
                            HStack {
                                Text("Following").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                Spacer()
                            }.padding(.top)
                            VStack(spacing: 8){
                                ForEach(viewModel.following){ user in
                                    Button {
                                        if let temp = allU, temp.username == user.username {
                                            allU = nil
                                        } else {
                                            allU = userSend(id: user.id ?? "", username: user.username)
                                        }
                                    } label: {
                                        userViewThreeX(user: user, selected: allU?.username ?? "" == user.username)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                            .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .cornerRadius(8, corners: .allCorners)
                        }
                        if !viewModel.mutualFriends.isEmpty {
                            HStack {
                                Text("Mutual Friends").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                                Spacer()
                            }.padding(.top)
                            VStack(spacing: 8){
                                let all = viewModel.mutualFriends.filter { $0.dev == nil && $0.id != auth.currentUser?.id }
                                ForEach(all){ user in
                                    Button {
                                        if let temp = allU, temp.username == user.username {
                                            allU = nil
                                        } else {
                                            allU = userSend(id: user.id ?? "", username: user.username)
                                        }
                                    } label: {
                                        userViewThreeX(user: user, selected: allU?.username ?? "" == user.username)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                            .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .cornerRadius(8, corners: .allCorners)
                        }
                        Color.clear.frame(height: 85)
                    }.padding(.horizontal, 12)
                }
                .scrollDismissesKeyboard(.immediately)
            }.ignoresSafeArea().padding(.top)
            VStack {
                Spacer()
                Button(action: {
//                    if let user = allU {
//                        
//                    }
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Start Call").foregroundStyle(.white).font(.headline).bold()
                        .padding(.vertical, 10).padding(.horizontal, 70)
                        .background(allU == nil ? .gray : Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                        .clipShape(Capsule())
                }).padding(.bottom)
            }
        }
        .presentationDetents([.large])
    }
    
    @ViewBuilder
    func TagView(_ tag: String) -> some View {
        Button {
            withAnimation {
                allU = nil
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
    func pickView() -> some View {
        VStack {
            HStack(spacing: 80){
                Button(action: {
                    withAnimation {
                        chatOrGroup = true
                    }
                }, label: {
                    HStack(spacing: 5){
                        Image(systemName: "phone").font(.headline)
                        Text("Audio Call")
                    }.font(.title3).foregroundStyle(chatOrGroup ? (colorScheme == .dark ? .white : .black) : .gray)
                })
                Button(action: {
                    withAnimation {
                        chatOrGroup = false
                    }
                }, label: {
                    HStack(spacing: 5){
                        Image(systemName: "video").font(.headline)
                        Text("Facetime")
                    }.font(.title3).foregroundStyle(!chatOrGroup ? (colorScheme == .dark ? .white : .black) : .gray)
                })
            }
            ZStack {
                Divider().overlay(.gray).frame(height: 1)
                HStack {
                    if !chatOrGroup {
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: widthOrHeight(width: true) * 0.5, height: 2)
                        .animation(.easeInOut(duration: 0.3), value: chatOrGroup)
                    if chatOrGroup {
                        Spacer()
                    }
                }
            }
        }
    }
}
