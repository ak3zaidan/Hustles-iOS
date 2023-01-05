import SwiftUI
import Lottie
import Firebase
import Kingfisher

struct MessagesMediaSearch: View {
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @State var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State var selection: Int = 0
    @State var photos = [String]()
    @State var links = [linkInfo]()
    @State var files = [linkInfo]()
    @State var sortedUsers = [User]()
    let randColors: [Color] = [.blue, .red, .green, .purple, .pink, .yellow, .indigo, .mint, .teal]
    var coordinator: UICoordinator
    @Binding var replying: replyTo?
    @State var photosEmpty: Bool = true
    
    init(allMessages: [Message], replying: Binding<replyTo?>) {
        var photos: [passBy] = []
        allMessages.forEach { element in
            if let photo = element.imageUrl, !photo.isEmpty {
                photos.append(passBy(id: element.id ?? "", photo: photo))
            }
        }
        if !photos.isEmpty {
            self._photosEmpty = State(initialValue: false)
        }
        self.coordinator = UICoordinator(photos: photos)
        self._replying = replying
    }
    
    var body: some View {
        VStack {
            HStack {
                ZStack {
                    TextField("Search \(selection == 0 ? "Media" : selection == 1 ? "Files" : "Links")...", text: $searchText)
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
                .onChange(of: searchText) { _, _ in
                    if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if !links.isEmpty { sortLinks() }
                        if !files.isEmpty { sortFiles() }
                    }
                }
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Text("Done").foregroundStyle(.blue).font(.title3).bold()
                }.padding(.trailing, 15)
            }
            
            ZStack {
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selection = 0
                    } label: {
                        Text("Media")
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
                        Text("Files")
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
                }.tag(0)
                
                VStack {
                    if files.isEmpty {
                        LottieView(loopMode: .playOnce, name: "nofound").scaleEffect(0.3).offset(y: -90)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(files){ item in
                                    SingleGroupLinkView(user: item.username, link: item.link, channel: item.channel, color: item.color).dynamicTypeSize(.large)
                                }
                            }.padding(.horizontal)
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
                        }.scrollDismissesKeyboard(.immediately)
                    }
                }.tag(2)
            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .onAppear {
            fetchData()
        }
        .overlay {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
                .opacity(coordinator.animateView ? 1 - coordinator.dragProgress : 0)
        }
        .overlay {
            if coordinator.selectedItem != nil {
                Detail(replying: .constant(nil), replying2: $replying, which: 1)
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
    }
    func fetchData(){
        if let index = messageModel.currentChat, let all = messageModel.chats[index].messages {
            all.forEach { message in
                let time = formatFirebaseT(message.timestamp)
                var temp_user = "You sent"
                if let id = auth.currentUser?.id, !(message.id ?? "").contains(String(id.prefix(5))) {
                    temp_user = messageModel.chats[index].user.username
                }
                if let text = message.text, !text.isEmpty {
                    if let all_links = getAllUrl(text: text), !all_links.isEmpty {
                        links += all_links.compactMap { singleURL in
                            return linkInfo(id: UUID().uuidString, link: singleURL, username: temp_user, channel: time, color: randColors.randomElement() ?? .orange)
                        }
                    }
                }
                if let file = message.file, let url = URL(string: file) {
                    files.append(linkInfo(id: UUID().uuidString, link: url, username: temp_user, channel: time, color: randColors.randomElement() ?? .orange))
                }
                if let file = message.replyFile, let url = URL(string: file) {
                    files.append(linkInfo(id: UUID().uuidString, link: url, username: temp_user, channel: time, color: randColors.randomElement() ?? .orange))
                }
            }
        }
    }
    func sortFiles() {
        let lowercasedQuery = searchText.lowercased()
        
        files.sort { (link1, link2) -> Bool in
            let score1 = calculateMatchScore(link: link1, query: lowercasedQuery)
            let score2 = calculateMatchScore(link: link2, query: lowercasedQuery)
            
            return score1 > score2
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
    func formatFirebaseT(_ timestamp: Timestamp) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let date = timestamp.dateValue()
        let formattedDateString = dateFormatter.string(from: date)
        
        return formattedDateString
    }

}
