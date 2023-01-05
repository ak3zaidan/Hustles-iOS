import SwiftUI
import Kingfisher

struct PinnedGroupView: View {
    @State private var seen: Bool = false
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var viewModel: GroupChatViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressingDown: Bool = false
    @State private var showMessage: Bool = false
    @State private var started: Bool = false
    @State var userPhotos: [String] = []
    @State var index: Int = 0
    
    @Binding var delete: Bool
    @Binding var group: GroupConvo
    @Binding var navigate: Bool
    @Binding var navGChat: String?
    @Binding var updatePin: Bool
    
    init(delete: Binding<Bool>, group: Binding<GroupConvo>, navigate: Binding<Bool>, navGChat: Binding<String?>, updatePin: Binding<Bool>) {
        self._delete = delete
        self._group = group
        self._navigate = navigate
        self._navGChat = navGChat
        self._updatePin = updatePin
        
        if let users = group.wrappedValue.users {
            let usersWithImageUrl = users.filter { $0.profileImageUrl != nil }
            for user in usersWithImageUrl {
                if let imageUrl = user.profileImageUrl, userPhotos.count < 3 {
                    userPhotos.append(imageUrl)
                }
            }
            if userPhotos.count < 3 {
                let usersWithoutImageUrl = users.filter { $0.profileImageUrl == nil }
                for user in usersWithoutImageUrl {
                    if let first = user.fullname.first, userPhotos.count < 3 {
                        userPhotos.append(String(first).uppercased())
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 8){
                ZStack {
                    Circle()
                        .fill(Color.gray.gradient).opacity(0.6)
                        .frame(width: 90, height: 90)
                    if userPhotos.isEmpty {
                        Image(systemName: "person.3.fill").font(.title3).foregroundStyle(.white)
                            .shimmering()
                    }
                    galleryUsers()
                }
                .shadow(color: .gray, radius: 4)
                .jiggle(isEnabled: delete)
                .overlay(alignment: .topLeading){
                    if delete {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                auth.currentUser?.pinnedChats?.removeAll(where: { $0 == group.id })
                            }
                            UserService().removeChatPin(id: group.id ?? "")
                        }, label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.gray)
                                .background(Color.white)
                                .clipShape(Circle())
                                .font(.title)
                        })
                    }
                }
                if let title = group.groupName, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 14))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .fontWeight(seen ? .bold : .regular)
                        .foregroundStyle(seen ? .blue : .gray)
                        .frame(maxWidth: 130)
                } else {
                    let users = group.users ?? []
                    let usernamesString = users.map { $0.username }.joined(separator: ", ")
                    Text(usernamesString)
                        .font(.system(size: 14))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .fontWeight(seen ? .bold : .regular)
                        .foregroundStyle(seen ? .blue : .gray)
                        .frame(maxWidth: 130)
                }
            }
            
            if !delete && showMessage {
                if index == 2 || index == 5 || index == 8 || (group.lastM?.text ?? "").count < 11 {
                    Text(group.lastM?.text ?? "")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .lineLimit(2)
                        .padding(4)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(minWidth: 50)
                        .background {
                            ZStack(alignment: .top){
                                Triangle()
                                    .frame(width: 15, height: 12)
                                    .offset(y: -10)
                                RoundedRectangle(cornerRadius: 10)
                            }
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                        }
                        .shadow(color: .gray, radius: colorScheme == .dark ? 4 : 7)
                        .frame(maxWidth: widthOrHeight(width: true) * 0.4)
                        .offset(y: 18)
                        .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .top)))
                } else if index == 1 || index == 4 || index == 9 {
                    Text(group.lastM?.text ?? "")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .lineLimit(2)
                        .padding(4)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(minWidth: 50)
                        .background {
                            ZStack(alignment: .bottom){
                                Triangle()
                                    .frame(width: 15, height: 12)
                                    .offset(y: 10)
                                    .rotationEffect(.degrees(45))
                                    .offset(x: (group.lastM?.text ?? "").count > 15 ? -20 : 0)
                                RoundedRectangle(cornerRadius: 10)
                            }
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                        }
                        .shadow(color: .gray, radius: colorScheme == .dark ? 4 : 7)
                        .frame(maxWidth: widthOrHeight(width: true) * 0.4)
                        .offset(y: -26)
                        .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .bottom)))
                } else {
                    Text(group.lastM?.text ?? "")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .lineLimit(2)
                        .padding(4)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(minWidth: 50)
                        .background {
                            ZStack(alignment: .bottom){
                                Triangle()
                                    .frame(width: 15, height: 12)
                                    .offset(y: 10)
                                    .rotationEffect(.degrees(-45))
                                    .offset(x: (group.lastM?.text ?? "").count > 15 ? 20 : 0)
                                RoundedRectangle(cornerRadius: 10)
                            }
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                        }
                        .shadow(color: .gray, radius: colorScheme == .dark ? 4 : 7)
                        .frame(maxWidth: widthOrHeight(width: true) * 0.4)
                        .offset(y: -26)
                        .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onChange(of: auth.currentUser?.pinnedChats, { _, _ in
            if let pos = auth.currentUser?.pinnedChats?.firstIndex(where: { $0 == group.id }) {
                self.index = pos + 1
            }
        })
        .onAppear(perform: {
            setUp()
        })
        .onChange(of: updatePin, { _, _ in
            setUp()
        })
        .onChange(of: group.users, { _, _ in
            putImages()
        })
        .onChange(of: group.lastM, { _, _ in
            if (group.lastM?.seen ?? false) == false {
                seen = true
                if !(group.lastM?.text ?? "").isEmpty {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showMessage = true
                    }
                }
            }
        })
        .scaleEffect(isPressingDown ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: started)
        .transition(.scale.combined(with: .blurReplace))
        .onLongPressGesture(minimumDuration: .infinity) {
            
        } onPressingChanged: { starting in
            if starting {
                started = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05){
                    if started {
                        withAnimation {
                            isPressingDown = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){
                            if isPressingDown {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                delete.toggle()
                                withAnimation {
                                    isPressingDown = false
                                }
                            }
                        }
                    } else if !delete {
                        navGChat = group.id ?? ""
                        navigate = true
                    }
                }
            } else {
                started = false
                if isPressingDown {
                    withAnimation {
                        self.isPressingDown = false
                    }
                }
            }
        }
    }
    @ViewBuilder
    func galleryUsers() -> some View {
        ZStack {
            if userPhotos.count == 3 {
                if userPhotos[0].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 48, height: 48)
                        .overlay(content: {
                            Text(userPhotos[0]).font(.system(size: 22)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: -13, y: -13)
                } else {
                    KFImage(URL(string: userPhotos[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .contentShape(Circle())
                        .offset(x: -13, y: -13)
                }
                if userPhotos[1].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 32, height: 32)
                        .overlay(content: {
                            Text(userPhotos[1]).font(.system(size: 19)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: 23, y: 12)
                } else {
                    KFImage(URL(string: userPhotos[1]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .contentShape(Circle())
                        .offset(x: 23, y: 12)
                }
                if userPhotos[2].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 27, height: 27)
                        .overlay(content: {
                            Text(userPhotos[2]).font(.system(size: 15)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: -5, y: 28)
                } else {
                    KFImage(URL(string: userPhotos[2]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 27, height: 27)
                        .clipShape(Circle())
                        .contentShape(Circle())
                        .offset(x: -5, y: 28)
                }
            } else if userPhotos.count == 2 {
                if userPhotos[0].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 49, height: 49)
                        .overlay(content: {
                            Text(userPhotos[0]).font(.system(size: 22)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: -12, y: -12)
                } else {
                    KFImage(URL(string: userPhotos[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 49, height: 49)
                        .clipShape(Circle())
                        .contentShape(Circle())
                        .offset(x: -12, y: -12)
                }
                if userPhotos[1].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 31, height: 31)
                        .overlay(content: {
                            Text(userPhotos[1]).font(.system(size: 20)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                        .offset(x: 18, y: 18)
                } else {
                    KFImage(URL(string: userPhotos[1]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 31, height: 31)
                        .clipShape(Circle())
                        .contentShape(Circle())
                        .offset(x: 18, y: 18)
                }
            } else if userPhotos.count == 1 {
                if userPhotos[0].count == 1 {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: 90, height: 90)
                        .overlay(content: {
                            Text(userPhotos[0]).font(.system(size: 30)).foregroundStyle(.white).fontWeight(.semibold)
                        })
                } else {
                    KFImage(URL(string: userPhotos[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
            }
        }
    }
    func setUp() {
        if let pos = auth.currentUser?.pinnedChats?.firstIndex(where: { $0 == group.id }) {
            self.index = pos + 1
        }
        
        let uid_prefix = String((auth.currentUser?.id ?? "").prefix(6))
        if (group.lastM?.seen ?? false) == false && !(group.lastM?.id ?? "NA").hasPrefix(uid_prefix) {
            seen = true
            if !(group.lastM?.text ?? "").isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showMessage = true
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMessage = false
                }
            }
        } else {
            seen = false
        }
        
        putImages()
    }
    func putImages() {
        if userPhotos.count < 3 {
            if let users = group.users {
                let usersWithImageUrl = users.filter { $0.profileImageUrl != nil }
                for user in usersWithImageUrl {
                    if let imageUrl = user.profileImageUrl, userPhotos.count < 3 {
                        userPhotos.append(imageUrl)
                    }
                }
                if userPhotos.count < 3 {
                    let usersWithoutImageUrl = users.filter { $0.profileImageUrl == nil }
                    for user in usersWithoutImageUrl {
                        if let first = user.fullname.first, userPhotos.count < 3 {
                            userPhotos.append(String(first).uppercased())
                        }
                    }
                }
            }
            if userPhotos.count < 3 {
                if let users = viewModel.chats.first(where: { $0.id == group.id })?.users {
                    let usersWithImageUrl = users.filter { $0.profileImageUrl != nil }
                    for user in usersWithImageUrl {
                        if let imageUrl = user.profileImageUrl, userPhotos.count < 3 {
                            userPhotos.append(imageUrl)
                        }
                    }
                    if userPhotos.count < 3 {
                        let usersWithoutImageUrl = users.filter { $0.profileImageUrl == nil }
                        for user in usersWithoutImageUrl {
                            if let first = user.fullname.first, userPhotos.count < 3 {
                                userPhotos.append(String(first).uppercased())
                            }
                        }
                    }
                }
            }
        }
    }
}
