import SwiftUI
import Kingfisher

struct passBy: Identifiable {
    var id: String
    var photo: String
}

struct GridWrapperView: View {
    var photos: [passBy]
    var coordinator: UICoordinator
    @Binding var replying: replyToGroup?

    init(photos: [passBy], replying: Binding<replyToGroup?>) {
        self.photos = photos
        self.coordinator = UICoordinator(photos: photos)
        self._replying = replying
    }
    
    var body: some View {
        VStack {
            Home31()
                .environment(coordinator)
                .allowsHitTesting(coordinator.selectedItem == nil)
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
    }
}

struct singleHomeAnimator: View {
    @Environment(UICoordinator.self) private var coordinator
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if let item = coordinator.items.first(where: { $0.title == "Main" }) {
                GridImageView(item)
                    .id(item.id)
                    .onTapGesture {
                        coordinator.isSingle = true
                        coordinator.selectedItem = item
                    }
            } else {
                ZStack(alignment: .center){
                    Circle()
                        .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray))
                        .frame(width: 90, height: 90)
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.white).font(.title3)
                }
                .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
            }
        }.frame(minWidth: 90)
    }

    @ViewBuilder
    func GridImageView(_ item: Item) -> some View {
        GeometryReader {
            let size = $0.size
            
            Circle()
                .fill(.clear)
                .anchorPreference(key: HeroKey.self, value: .bounds, transform: { anchor in
                    return [item.id + "SOURCE": anchor]
                })
            
            if let previewImage = item.previewImage {
                KFImage(URL(string: previewImage))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(Circle())
                    .shadow(color: .gray, radius: 3)
                    .opacity(coordinator.selectedItem?.id == item.id ? 0 : 1)
            }
        }
        .frame(width: 90, height: 90)
        .contentShape(.circle)
    }
}

struct Home31: View {
    @Environment(UICoordinator.self) private var coordinator
    @State private var showForward: Bool = false
    @State private var forwardString = ""
    @State private var forwardDataType: Int = 1
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(spacing: 3), count: 3), spacing: 3) {
            ForEach(coordinator.items) { item in
                if item.title != "Main" {
                    GridImageView(item)
                        .id(item.id)
                        .onTapGesture {
                            coordinator.isSingle = false
                            coordinator.selectedItem = item
                        }
                        .contextMenu {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if let url = item.previewImage {
                                    UIPasteboard.general.string = url
                                }
                            } label: {
                                Label("Copy", systemImage: "link")
                            }
                            Button {
                                if let url = item.previewImage {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    forwardString = url
                                    forwardDataType = 1
                                    showForward = true
                                }
                            } label: {
                                Label("Share", systemImage: "paperplane")
                            }
                        } preview: {
                            KFImage(URL(string: item.previewImage ?? ""))
                                .resizable()
                        }
                }
            }
        }
        .sheet(isPresented: $showForward, content: {
            ForwardContentView(sendLink: $forwardString, whichData: $forwardDataType)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
                .onDisappear {
                    showForward = false
                }
        })
    }

    @ViewBuilder
    func GridImageView(_ item: Item) -> some View {
        GeometryReader {
            let size = $0.size
            
            Rectangle()
                .fill(.clear)
                .anchorPreference(key: HeroKey.self, value: .bounds, transform: { anchor in
                    return [item.id + "SOURCE": anchor]
                })
            
            if let previewImage = item.previewImage {
                KFImage(URL(string: previewImage))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .opacity(coordinator.selectedItem?.id == item.id ? 0 : 1)
            }
        }
        .frame(height: 130)
        .contentShape(.rect)
    }
}

struct HeroLayer: View {
    @Environment(UICoordinator.self) private var coordinator
    var item: Item
    var sAnchor: Anchor<CGRect>
    var dAnchor: Anchor<CGRect>
    var body: some View {
        GeometryReader { proxy in
            let sRect = proxy[sAnchor]
            let dRect = proxy[dAnchor]
            let animateView = coordinator.animateView
            
            let viewSize: CGSize = .init(
                width: animateView ? dRect.width : sRect.width,
                height: animateView ? dRect.height : sRect.height
            )
            let viewPosition: CGSize = .init(
                width: animateView ? dRect.minX : sRect.minX,
                height: animateView ? dRect.minY : sRect.minY
            )
            
            if let image = item.image, !coordinator.showDetailView {
                KFImage(URL(string: image))
                    .resizable()
                    .aspectRatio(contentMode: animateView ? .fit : .fill)
                    .frame(width: viewSize.width, height: viewSize.height)
                    .clipped()
                    .offset(viewPosition)
                    .transition(.identity)
            }
        }
    }
}

struct Detail: View {
    @EnvironmentObject var viewModel: GroupChatViewModel
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var serverModel: GroupViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var dismiss
    @Environment(UICoordinator.self) private var coordinator
    @State var showOptions: Bool = true
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    
    @State private var showPost: Bool = false
    @State var initialContent: uploadContent? = nil
    @State var place: myLoc? = nil
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State var savedPhotos: [String] = []
    
    @State private var showForward: Bool = false
    @State private var forwardString = ""
    @State private var forwardDataType: Int = 1
    @Binding var replying: replyToGroup?
    @Binding var replying2: replyTo?
    
    @State var dayOfWeek: String = "Friday"
    @State var timeFinal: String = "10:33 PM"
    @State private var stopShowing: Bool = false
    let which: Int
    
    var body: some View {
        ZStack {
            GeometryReader {
                let size = $0.size
                
                ZStack {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0) {
                            ForEach(coordinator.items) { item in
                                if (coordinator.isSingle && item.title == "Main") || (!coordinator.isSingle && item.title != "Main") {
                                    ImageView(item, size: size)
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .scrollPosition(id: .init(get: {
                        return coordinator.detailScrollPosition
                    }, set: {
                        coordinator.detailScrollPosition = $0
                    }))
                    .onChange(of: coordinator.detailScrollPosition, { oldValue, newValue in
                        coordinator.didDetailPageChanged()
                    })
                    .background {
                        if let selectedItem = coordinator.selectedItem {
                            Rectangle()
                                .fill(.clear)
                                .anchorPreference(key: HeroKey.self, value: .bounds, transform: { anchor in
                                    return [selectedItem.id + "DEST": anchor]
                                })
                        }
                    }
                    .offset(coordinator.offset)
                    .scaleEffect(scale)
                    
                    Rectangle()
                        .foregroundStyle(.clear)
                        .frame(width: 160)
                        .contentShape(.rect)
                        .onTapGesture(count: 2) {
                            if scale == 1 {
                                lastScale = 3.0
                                withAnimation(.easeInOut(duration: 0.2)){
                                    scale = 3.0
                                }
                            } else {
                                lastScale = 1
                                withAnimation(.easeInOut(duration: 0.2)){
                                    scale = 1
                                }
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showOptions.toggle()
                            }
                        }
                        .gesture (
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let translation = value.translation
                                    coordinator.offset = translation
                                    let heightProgress = max(min(translation.height / 200, 1), 0)
                                    coordinator.dragProgress = heightProgress
                                }.onEnded { value in
                                    let translation = value.translation
                                    let velocity = value.velocity
                                    let height = translation.height + (velocity.height / 5)
                                    
                                    if height > (size.height * 0.35) {
                                        stopShowing = true
                                        coordinator.toggleView(show: false)
                                    } else if !stopShowing {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            coordinator.offset = .zero
                                            coordinator.dragProgress = 0
                                        }
                                    }
                                }
                        )
                        .gesture(makeMagnificationGesture(size: size))
                }
            }
            .ignoresSafeArea()
            .opacity(coordinator.showDetailView ? 1 : 0)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showOptions.toggle()
                }
            }
            
            if showOptions {
                VStack {
                    NavigationBar()
                    Spacer()
                    if coordinator.selectedItem?.title ?? "" != "Main" {
                        VStack(spacing: 0){
                            BottomIndicatorView()
                            optionsView()
                        }
                        .background {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .ignoresSafeArea()
                        }
                        .offset(y: coordinator.showDetailView ? (140 * coordinator.dragProgress) : 140)
                        .animation(.easeInOut(duration: 0.15), value: coordinator.showDetailView)
                    }
                }
            }
        }
        .onChange(of: coordinator.selectedItem, { _, newValue in
            if which == 1 {
                if let new = newValue, let index = messageModel.currentChat, let timestamp = messageModel.chats[index].messages?.first(where: { $0.id == new.title })?.timestamp {
                    let date = timestamp.dateValue()
                    timeFinal = "\(date.formatted(.dateTime.hour().minute()))"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE"
                    dayOfWeek = dateFormatter.string(from: date)
                }
            } else if which == 2 {
                if let new = newValue, let index = viewModel.currentChat, let timestamp = viewModel.chats[index].messages?.first(where: { $0.id == new.title })?.timestamp {
                    let date = timestamp.dateValue()
                    timeFinal = "\(date.formatted(.dateTime.hour().minute()))"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE"
                    dayOfWeek = dateFormatter.string(from: date)
                }
            } else {
                if let new = newValue, let index = serverModel.currentGroup, let pos = serverModel.groups[index].1.messages?.firstIndex(where: { $0.messages.contains(where: { $0.id == new.title }) }), let timestamp = serverModel.groups[index].1.messages?[pos].messages.first(where: { $0.id == new.title })?.timestamp {
                    let date = timestamp.dateValue()
                    timeFinal = "\(date.formatted(.dateTime.hour().minute()))"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE"
                    dayOfWeek = dateFormatter.string(from: date)
                }
            }
        })
        .onAppear {
            coordinator.toggleView(show: true)
            if which == 1 {
                if let new = coordinator.selectedItem, let index = messageModel.currentChat, let timestamp = messageModel.chats[index].messages?.first(where: { $0.id == new.title })?.timestamp {
                    let date = timestamp.dateValue()
                    timeFinal = "\(date.formatted(.dateTime.hour().minute()))"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE"
                    dayOfWeek = dateFormatter.string(from: date)
                }
            } else if which == 2 {
                if let new = coordinator.selectedItem, let index = viewModel.currentChat, let timestamp = viewModel.chats[index].messages?.first(where: { $0.id == new.title })?.timestamp {
                    let date = timestamp.dateValue()
                    timeFinal = "\(date.formatted(.dateTime.hour().minute()))"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE"
                    dayOfWeek = dateFormatter.string(from: date)
                }
            } else {
                if let new = coordinator.selectedItem, let index = serverModel.currentGroup, let pos = serverModel.groups[index].1.messages?.firstIndex(where: { $0.messages.contains(where: { $0.id == new.title }) }), let timestamp = serverModel.groups[index].1.messages?[pos].messages.first(where: { $0.id == new.title })?.timestamp {
                    let date = timestamp.dateValue()
                    timeFinal = "\(date.formatted(.dateTime.hour().minute()))"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE"
                    dayOfWeek = dateFormatter.string(from: date)
                }
            }
        }
        .fullScreenCover(isPresented: $showPost, content: {
            NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent)
                .onDisappear {
                    place = nil
                }
        })
        .sheet(isPresented: $showForward, content: {
            ForwardContentView(sendLink: $forwardString, whichData: $forwardDataType)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
                .onDisappear {
                    showForward = false
                }
        })
    }
    
    private func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value

                if abs(1 - delta) > 0.01 {
                    scale *= delta
                }
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation {
                        scale = 1
                    }
                }
            }
    }
    
    @ViewBuilder
    func optionsView() -> some View {
        HStack(alignment: .top, spacing: 0){
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let image = coordinator.selectedItem?.image {
                    downloadAndSaveImage(url: image)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        savedPhotos.append(image)
                    }
                }
            }, label: {
                if savedPhotos.contains(coordinator.selectedItem?.image ?? "") {
                    VStack(spacing: 5){
                        Image(systemName: "checkmark.icloud.fill").foregroundStyle(.blue)
                        Text("Saved")
                    }.transition(.move(edge: .top))
                } else {
                    VStack(spacing: 2){
                        Image(systemName: "square.and.arrow.down")
                        Text("Save").font(.caption)
                    }
                }
            }).frame(width: 50, height: 40).offset(y: -13)
            Spacer()
            Button(action: {
                initialContent = uploadContent(isImage: true, imageURL: coordinator.selectedItem?.image)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPost = true
            }, label: {
                VStack(spacing: 2){
                    Image(systemName: "plus.app")
                    Text("Post").font(.caption)
                }.frame(height: 40)
            }).offset(y: -13)
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let image = coordinator.selectedItem?.image {
                    forwardString = image
                    forwardDataType = 1
                    showForward = true
                }
            }, label: {
                VStack(spacing: 2){
                    Image(systemName: "paperplane")
                    Text("Forward").font(.caption)
                }.frame(height: 40)
            }).offset(y: -13)
            Spacer()
            Button(action: {
                if which == 1 {
                    if let curr = coordinator.selectedItem {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if let index = messageModel.currentChat, let message = messageModel.chats[index].messages?.first(where: { $0.id == curr.title }) {
                            
                            let isOneMain: Bool = (messageModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? true : false
                            
                            let didRec: Bool = (isOneMain && message.uid_one_did_recieve || !isOneMain && !message.uid_one_did_recieve) ? true : false
                            
                            self.replying2 = replyTo(messageID: curr.title, selfReply: !didRec)
                            dismiss.wrappedValue.dismiss()
                        }
                    }
                } else if which == 3 {
                    if let curr = coordinator.selectedItem {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if let index = serverModel.currentGroup, let pos = serverModel.groups[index].1.messages?.firstIndex(where: { $0.messages.contains(where: { $0.id == curr.title }) }), let message = serverModel.groups[index].1.messages?[pos].messages.first(where: { $0.id == curr.title }){
                            
                            let isSelf: Bool = ((auth.currentUser?.id ?? "") == message.uid)

                            self.replying = replyToGroup(messageID: message.id ?? "", selfReply: isSelf, username: message.username)
                            dismiss.wrappedValue.dismiss()
                        }
                    }
                } else {
                    if let curr = coordinator.selectedItem {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if let index = viewModel.currentChat, let message = viewModel.chats[index].messages?.first(where: { $0.id == curr.title }) {

                            let myPrefix = String((auth.currentUser?.id ?? "").prefix(6))
                            let messagePrefix = String((message.id ?? "").prefix(6))
                            let isSelf: Bool = myPrefix == messagePrefix
                            var username = auth.currentUser?.username ?? ""

                            if !isSelf {
                                if let user = viewModel.chats[index].users?.first(where: { ($0.id ?? "").hasPrefix(messagePrefix) })?.username {
                                    username = user
                                }
                            }
                            self.replying = replyToGroup(messageID: curr.title, selfReply: isSelf, username: username)
                            dismiss.wrappedValue.dismiss()
                        }
                    }
                }
            }, label: {
                VStack(spacing: 2){
                    Image(systemName: "arrow.uturn.backward")
                    Text("Reply").font(.caption)
                }.frame(height: 40)
            }).offset(y: -13)
            Spacer()
        }
        .frame(height: 45)
        .padding(.bottom)
    }

    @ViewBuilder
    func NavigationBar() -> some View {
        ZStack {
            HStack {
                Button(action: {
                    coordinator.toggleView(show: false)
                }, label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left").font(.title3)
                        Text("Back")
                    }.foregroundStyle(.blue)
                })
                Spacer()
                if coordinator.selectedItem?.title ?? "" != "Main" {
                    Menu {
                        if let curr = coordinator.selectedItem {
                            if which == 1 {
                                if let index = messageModel.currentChat, let message = messageModel.chats[index].messages?.first(where: { $0.id == curr.title }) {
                                    
                                    let isOneMain: Bool = (messageModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? true : false
                                    
                                    let didRec: Bool = (isOneMain && message.uid_one_did_recieve || !isOneMain && !message.uid_one_did_recieve) ? true : false
                                    
                                    if !didRec {
                                        Button(role: .destructive) {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            messageModel.deleteMessageID(id: curr.title)
                                        } label: {
                                            Label("Delete Message", systemImage: "trash")
                                        }
                                    }
                                }
                            } else if which == 2 {
                                if let index = viewModel.currentChat, let pos = viewModel.chats[index].messages?.firstIndex(where: { $0.id == curr.title }), curr.title.hasPrefix((auth.currentUser?.id ?? "").prefix(6)) {
                                    Button(role: .destructive) {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        viewModel.chats[index].messages?.remove(at: pos)
                                        viewModel.chats[index].lastM = viewModel.chats[index].messages?.first
                                        viewModel.setDate()
                                        if let docID = viewModel.chats[index].id {
                                            GroupChatService().deleteOld(convoID: docID, messageId: curr.title)
                                        }
                                        if let url = viewModel.chats[index].messages?[pos].videoURL {
                                            ImageUploader.deleteImage(fileLocation: url) { _ in }
                                        }
                                        if let url = viewModel.chats[index].messages?[pos].audioURL {
                                            ImageUploader.deleteImage(fileLocation: url) { _ in }
                                        }
                                        if let url = viewModel.chats[index].messages?[pos].file {
                                            ImageUploader.deleteImage(fileLocation: url) { _ in }
                                        }
                                        if let url = viewModel.chats[index].messages?[pos].imageUrl {
                                            ImageUploader.deleteImage(fileLocation: url) { _ in }
                                        }
                                    } label: {
                                        Label("Delete Message", systemImage: "trash")
                                    }
                                }
                            } else {
                                if let index = serverModel.currentGroup, let pos = serverModel.groups[index].1.messages?.firstIndex(where: { $0.messages.contains(where: { $0.id == curr.title }) }), let tweet = serverModel.groups[index].1.messages?[pos].messages.first(where: { $0.id == curr.title }), tweet.uid == auth.currentUser?.id {
                                    
                                    Button(role: .destructive) {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        serverModel.deleteMessage(messageId: tweet.id ?? "", image: tweet.image, privateG: true)
                                        if let url = tweet.audioURL {
                                            ImageUploader.deleteImage(fileLocation: url) { _ in }
                                        }
                                        if let url = tweet.videoURL {
                                            ImageUploader.deleteImage(fileLocation: url) { _ in }
                                        }
                                        if let url = tweet.fileURL {
                                            ImageUploader.deleteImage(fileLocation: url) { _ in }
                                        }
                                    } label: {
                                        Label("Delete Message", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        Button(role: .cancel) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if let image = coordinator.selectedItem?.image {
                                UIPasteboard.general.string = image
                            }
                        } label: {
                            Label("Copy", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle").font(.title2).foregroundStyle(.blue)
                    }
                }
            }
            if coordinator.selectedItem?.title ?? "" != "Main" {
                VStack(spacing: 3){
                    Text(dayOfWeek).font(.subheadline)
                    Text(timeFinal).font(.caption)
                }
            }
        }
        .padding(.top, 5)
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .offset(y: coordinator.showDetailView ? (-170 * coordinator.dragProgress) : -170)
        .animation(.easeInOut(duration: 0.15), value: coordinator.showDetailView)
    }
    
    @ViewBuilder
    func ImageView(_ item: Item, size: CGSize) -> some View {
        if let image = item.image {
            KFImage(URL(string: image))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.width, height: size.height)
                .clipped()
                .contentShape(.rect)
        }
    }
    
    @ViewBuilder
    func BottomIndicatorView() -> some View {
        HStack(alignment: .top){
            GeometryReader {
                let size = $0.size
                
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 5) {
                        ForEach(coordinator.items) { item in
                            if let image = item.previewImage, item.title != "Main" {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(.rect(cornerRadius: 10))
                                    .scaleEffect(0.97)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    .scrollTargetLayout()
                }
                .safeAreaPadding(.horizontal, (size.width - 50) / 2)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary, lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .allowsHitTesting(false)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: .init(get: {
                    return coordinator.detailIndicatorPosition
                }, set: {
                    coordinator.detailIndicatorPosition = $0
                }))
                .scrollIndicators(.hidden)
                .onChange(of: coordinator.detailIndicatorPosition) { oldValue, newValue in
                    coordinator.didDetailIndicatorPageChanged()
                }
                .offset(y: -5)
            }
        }
        .frame(height: 65)
        .padding(.bottom, 6)
    }
}

@Observable
class UICoordinator {
    var items: [Item] = []
    var selectedItem: Item?
    var animateView: Bool = false
    var showDetailView: Bool = false
    var isSingle: Bool = false
    var detailScrollPosition: String?
    var detailIndicatorPosition: String?
    var offset: CGSize = .zero
    var dragProgress: CGFloat = 0
    
    init(photos: [passBy]){
        self.items = photos.compactMap({ Item(title: $0.id, image: $0.photo, isImage: true, previewImage: $0.photo) })
    }
    
    func didDetailPageChanged() {
        if let updatedItem = items.first(where: { $0.id == detailScrollPosition }) {
            selectedItem = updatedItem
            withAnimation(.easeInOut(duration: 0.1)) {
                detailIndicatorPosition = updatedItem.id
            }
        }
    }
    
    func didDetailIndicatorPageChanged() {
        if let updatedItem = items.first(where: { $0.id == detailIndicatorPosition }) {
            selectedItem = updatedItem
            detailScrollPosition = updatedItem.id
        }
    }
    
    func toggleView(show: Bool) {
        if show {
            detailScrollPosition = selectedItem?.id
            detailIndicatorPosition = selectedItem?.id
            withAnimation(.easeInOut(duration: 0.2), completionCriteria: .removed) {
                animateView = true
            } completion: {
                self.showDetailView = true
            }
        } else {
            showDetailView = false
            withAnimation(.easeInOut(duration: 0.2), completionCriteria: .removed) {
                animateView = false
                offset = .zero
            } completion: {
                self.resetAnimationProperties()
            }
        }
    }
    
    func resetAnimationProperties() {
        selectedItem = nil
        detailScrollPosition = nil
        offset = .zero
        dragProgress = 0
        detailIndicatorPosition = nil
    }
}

struct HeroKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String : Anchor<CGRect>], nextValue: () -> [String : Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

struct Item: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var image: String?
    var video: URL?
    var isImage: Bool
    var previewImage: String?
    var appeared: Bool = false
}

extension View {
    @ViewBuilder
    func didFrameChange(result: @escaping (CGRect, CGRect) -> ()) -> some View {
        self
            .overlay {
                GeometryReader {
                    let frame = $0.frame(in: .scrollView(axis: .vertical))
                    let bounds = $0.bounds(of: .scrollView(axis: .vertical)) ?? .zero
                    
                    Color.clear
                        .preference(key: FrameKey.self, value: .init(frame: frame, bounds: bounds))
                        .onPreferenceChange(FrameKey.self, perform: { value in
                            result(value.frame, value.bounds)
                        })
                }
            }
    }
}

struct ViewFrame: Equatable {
    var frame: CGRect = .zero
    var bounds: CGRect = .zero
}

struct FrameKey: PreferenceKey {
    static var defaultValue: ViewFrame = .init()
    static func reduce(value: inout ViewFrame, nextValue: () -> ViewFrame) {
        value = nextValue()
    }
}
