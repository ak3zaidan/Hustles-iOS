import Foundation
import Kingfisher
import SwiftUI
import Firebase
import AVFoundation
import AudioToolbox
import CoreLocation

struct GroupChatBubble: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var groupViewModel: ExploreViewModel
    @EnvironmentObject var viewModel: GroupChatViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var profileModel: ProfileViewModel
    @State var message: GroupMessage
    @Binding var replying: replyToGroup?
    @State var timePosition: Bool
    @State var dateFinal: String = "7:05 PM"
    @State private var showSheet: Bool = false
    @State private var isPressingDown: Bool = false
    @State private var started: Bool = false
    @State var size: CGFloat = 0
    @State var opacity: CGFloat = 0
    @State var gestureOffset: CGFloat = 0
    @State private var replyOnRelease: Bool = false
    @State private var showGroup = false
    @State private var showLoad = false
    @State var replyColor: Color = .green
    @State private var imageSaved = false
    @State var glow = 0.0
    @State var glow2 = 0.0
    @State var isFirst: Bool = false
    @State var isLast: Bool = false
    @State var myColor: Color = .orange
    @State private var showForward: Bool = false
    @State private var forwardString = ""
    @State private var forwardDataType: Int = 1
    @Binding var currentAudio: String
    @Binding var showUser: Bool
    @Binding var selectedUser: User?
    @State var showTranscription: Bool = false
    @State var transcribing: Bool = false
    @Binding var viewOption: Bool
    @Binding var isExpanded: Bool
    let animation: Namespace.ID
    let seenAllStories: Bool
    @Binding var addPadding: Bool
    let openUser: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2){
            if let text = message.text {
                if let coordinates = extractCoordinates(from: text), message.lat == nil {
                    HStack {
                        MessageMapView(leading: false, long: coordinates.long, lat: coordinates.lat, name: coordinates.name).frame(maxWidth: widthOrHeight(width: true) * 0.7, alignment: .leading)
                        Spacer()
                    }.padding(.leading, 35)
                }
                
                let allStocks = extractWordsStartingWithDollar(input: text)
                if !allStocks.isEmpty {
                    HStack {
                        cards(cards: allStocks, left: false)
                            .frame(maxWidth: widthOrHeight(width: true) * 0.75, alignment: .leading)
                        Spacer()
                    }.padding(.leading, 35)
                }
                if let url = checkForFirstUrl(text: text){
                    HStack {
                        MainPreviewLink(url: url, message: true)
                            .frame(maxWidth: widthOrHeight(width: true) * 0.7, alignment: .leading)
                        Spacer()
                    }.padding(.leading, 35)
                }
                let all = checkForPostUrls(text: text)
                if !all.isEmpty {
                    HStack {
                        ForEach(all, id: \.self) { element in
                            if element.contains("post") {
                                PostPartView(fullURL: element, leading: false, currentAudio: $currentAudio)
                            } else if element.contains("profile") {
                                ProfilePartView(fullURL: element)
                            } else if element.contains("story"), let sid = extractStoryID(from: element) {
                                if let story = message.stories?.first(where: { $0.id == sid }) {
                                    StorySendView(currentTweet: story, leading: false, currentAudio: $currentAudio, text: nil, emoji: nil, reaction: nil, isExpanded: $isExpanded, animation: animation, addPadding: $addPadding, parentID: message.id ?? UUID().uuidString)
                                } else {
                                    StoryErrorView()
                                        .onAppear {
                                            updateStory(storyID: sid)
                                        }
                                }
                            } else if element.contains("news") {
                                let current: News? = groupViewModel.news.first(where: { $0.id == (extractNewsVariable(from: element) ?? "NA") })
                                NewsSendView(fullURL: element, leading: false, currentNews: current, isGroup: false)
                            } else if element.contains("memory") {
                                ChatMemoryView(url: element, leading: false)
                            }
                        }
                        Spacer()
                    }.padding(.leading, 35)
                }
            }
            VStack(alignment: .leading, spacing: 2){
                HStack(alignment: .bottom, spacing: 1){
                    if isFirst {
                        ZStack {
                            let uid_prefix = (message.id ?? "").prefix(6)
                            if let index = viewModel.currentChat, let user = viewModel.chats[index].allUsersUID.first(where: { $0.hasPrefix(uid_prefix) }) {

                                let op_user = viewModel.chats[index].users?.first(where: { $0.id == user })
                                let firstLetter = String((op_user?.fullname ?? "A").first ?? Character("?"))
                                
                                if hasStories() {
                                    ZStack {
                                        StoryRingView(size: 30, active: seenAllStories, strokeSize: 1.2)
                                            .scaleEffect(1.3)
                                        
                                        let mid = (message.id ?? "") + "UpStory"
                                        let size = isExpanded && profileModel.mid == mid ? 200.0 : 27.0
                                        GeometryReader { _ in
                                            ZStack {
                                                animateProfilePhoto(myColor: myColor, image: op_user?.profileImageUrl, size: size, letter: firstLetter)
                                            }.opacity(isExpanded && profileModel.mid == mid ? 0.0 : 1.0)
                                        }
                                        .matchedGeometryEffect(id: mid, in: animation, anchor: .topLeading)
                                        .frame(width: 27.0, height: 27.0)
                                        .onTapGesture {
                                            addPadding = true
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            setupStory()
                                            profileModel.mid = mid
                                            profileModel.isStoryRow = false
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    isExpanded = true
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    Button {
                                        openUser(user)
                                    } label: {
                                        ZStack {
                                            if let first = (op_user?.fullname ?? "").first {
                                                Circle()
                                                    .fill(myColor.gradient)
                                                    .brightness(colorScheme == .dark ? 0.0 : -0.5)
                                                    .frame(width: 30, height: 30)
                                                Text(String(first).uppercased())
                                                    .foregroundColor(.white).font(.headline).bold()
                                            } else {
                                                Circle()
                                                    .fill(myColor.gradient)
                                                    .frame(width: 30, height: 30)
                                                    .brightness(colorScheme == .dark ? 0.0 : -0.5)
                                                Image(systemName: "person.fill")
                                                    .resizable()
                                                    .frame(width: 15, height: 15)
                                                    .foregroundStyle(.white)
                                            }
                                            if let photo = op_user?.profileImageUrl {
                                                KFImage(URL(string: photo))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width:30, height: 30)
                                                    .clipShape(Circle())
                                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                            }
                                        }
                                    }
                                }
                            } else {
                                if hasStories() {
                                    StoryRingView(size: 30, active: seenAllStories, strokeSize: 1.5)
                                        .scaleEffect(1.42)
                                    
                                    let mid = (message.id ?? "") + "UpStory"
                                    let size = isExpanded && profileModel.mid == mid ? 200.0 : 30.0
                                    GeometryReader { _ in
                                        ZStack {
                                            animateProfilePhoto(myColor: myColor, image: nil, size: size, letter: "?")
                                        }.opacity(isExpanded && profileModel.mid == mid ? 0.0 : 1.0)
                                    }
                                    .matchedGeometryEffect(id: mid, in: animation, anchor: .topLeading)
                                    .frame(width: 30.0, height: 30.0)
                                    .onTapGesture {
                                        addPadding = true
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        setupStory()
                                        profileModel.mid = mid
                                        profileModel.isStoryRow = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                isExpanded = true
                                            }
                                        }
                                    }
                                } else {
                                    ZStack {
                                        Circle()
                                            .frame(width: 30, height: 30)
                                            .foregroundStyle(myColor)
                                            .brightness(colorScheme == .dark ? 0.0 : -0.5)
                                        Image(systemName: "person.fill")
                                            .resizable().frame(width: 15, height: 15)
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                        
                        firstMessage()
                    } else {
                        notFirst().padding(.leading, 35)
                    }
                    Spacer()
                }.padding(.leading, 5)
                if (message.countSmile != nil) || (message.countCry != nil) || (message.countThumb != nil) || (message.countBless != nil) || (message.countHeart != nil) || (message.countQuestion != nil) {
                    allEmojies()
                }
            }
            .brightness(glow)
            .overlay {
                HStack {
                    Image(systemName: "arrowshape.turn.up.backward.fill")
                        .foregroundStyle(.gray).font(.title).offset(x: -gestureOffset)
                        .opacity(opacity).scaleEffect(size)
                    Spacer()
                }.padding(.trailing)
            }
            .offset(x: gestureOffset)
            .scaleEffect(isPressingDown ? 1.2 : 1.0, anchor: .leading)
            .padding(.vertical, isPressingDown ? 8 : 0)
            .highPriorityGesture (
                DragGesture()
                    .onChanged({ value in
                        if value.translation.width > 0 {
                            let maxDrag = 100.0
                            let ratio = value.translation.width / maxDrag
                            let finalRatio = ratio > 1 ? 1 : ratio
                            gestureOffset = value.translation.width > 100.0 ? 100.0 : value.translation.width
                            size = finalRatio * 1.0
                            opacity = finalRatio * 1.0
                            if finalRatio > 0.8 {
                                if !replyOnRelease {
                                    replyOnRelease = true
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            } else {
                                replyOnRelease = false
                            }
                        }
                    })
                    .onEnded({ value in
                        withAnimation {
                            gestureOffset = 0
                            size = 0
                            opacity = 0
                            if replyOnRelease {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                                    runReply()
                                }
                            }
                        }
                    })
            )
            .onLongPressGesture(minimumDuration: .infinity) {
                
            } onPressingChanged: { starting in
                if starting {
                    started = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05){
                        if started && gestureOffset == 0 {
                            withAnimation {
                                isPressingDown = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){
                                if isPressingDown {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    showSheet = true
                                    withAnimation {
                                        isPressingDown = false
                                    }
                                }
                            }
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
        .onChange(of: viewModel.scrollToReply, { _, new in
            if new == (message.id ?? "Not Equal") {
                viewModel.scrollToReply = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        glow = 0.4
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            glow = 0.0
                        }
                    }
                }
            }
        })
        .onChange(of: viewModel.scrollToReplyNow, { _, new in
            if new == (message.id ?? "Not Equal") {
                viewModel.scrollToReplyNow = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation {
                        glow2 = 0.5
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            glow2 = 0.0
                        }
                    }
                }
            }
        })
        .padding(.top, isLast ? 9 : 0)
        .onChange(of: viewModel.chats) { _, _ in
            getCorners()
        }
        .onAppear(perform: {
            getCorners()
            self.dateFinal = setTime(from: message.timestamp)
            
            if let id = message.id, let index = viewModel.currentChat {
                let uid_prefix = String((id).prefix(6))
                if let user = viewModel.chats[index].users?.first(where: {($0.id ?? "").hasPrefix(uid_prefix)}) {
                    profileModel.updateStoriesUser(user: user)
                } else if let uid = viewModel.chats[index].allUsersUID.first(where: { $0.hasPrefix(uid_prefix) }) {
                    if (auth.currentUser?.following ?? []).contains(uid) {
                        UserService().fetchSafeUser(withUid: uid) { user in
                            if let user {
                                profileModel.updateStoriesUser(user: user)
                            }
                        }
                    }
                }
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
        .sheet(isPresented: $showSheet) {
            ScrollView {
                VStack(spacing: 18){
                    HStack {
                        emojiView(emoji: "😂")
                        Spacer()
                        emojiView(emoji: "😭")
                        Spacer()
                        emojiView(emoji: "👍")
                        Spacer()
                        emojiView(emoji: "🙏")
                        Spacer()
                        emojiView(emoji: "❤️")
                        Spacer()
                        emojiView(emoji: "questionmark")
                    }.lineLimit(1).minimumScaleFactor(0.4)
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).foregroundStyle(Color.gray.opacity(0.1))
                        VStack(spacing: 14){
                            HStack(spacing: 14){
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    runReply()
                                } label: {
                                    Image(systemName: "arrow.turn.up.left")
                                    Text("Reply").padding(.leading, 4)
                                    Spacer()
                                }
                            }.opacity(0.9).fontWeight(.semibold).font(.headline)
  
                            if let text = message.text {
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        UIPasteboard.general.string = text
                                    } label: {
                                        Image(systemName: "doc.on.doc.fill")
                                        Text("Copy Text").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                            }
                            if let image = message.imageUrl {
                                if let id = message.id, !popRoot.savedMemories.contains(id) {
                                    Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                    HStack(spacing: 14){
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showSheet = false
                                            withAnimation {
                                                popRoot.savedMemories.append(id)
                                            }
                                            let newID = UUID().uuidString
                                            var lat: CGFloat? = nil
                                            var long: CGFloat? = nil
                                            if let current = globe.currentLocation {
                                                lat = CGFloat(current.lat)
                                                long = CGFloat(current.long)
                                            } else if let current = auth.currentUser?.currentLocation, let place = extractLatLong(from: current) {
                                                lat = place.latitude
                                                long = place.longitude
                                            }
                                            UserService().saveMemories(docID: newID, imageURL: image, videoURL: nil, lat: lat, long: long)
                                            let new = animatableMemory(isImage: true, memory: Memory(id: newID, image: image, lat: lat, long: long, createdAt: Timestamp()))
                                            if let idx = popRoot.allMemories.firstIndex(where: { $0.date == "Recents" }) {
                                                popRoot.allMemories[idx].allMemories.insert(new, at: 0)
                                            } else {
                                                let newMonth = MemoryMonths(date: "Recents", allMemories: [new])
                                                popRoot.allMemories.insert(newMonth, at: 0)
                                            }
                                        } label: {
                                            Image("memory")
                                                .resizable()
                                                .frame(width: 25, height: 25)
                                                .scaledToFit()
                                                .scaleEffect(1.2)
                                            Text("Save to Memories")
                                                .gradientForeground(colors: [.blue, .purple])
                                            Spacer()
                                        }
                                    }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                }
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        UIPasteboard.general.string = image
                                    } label: {
                                        Image(systemName: "link")
                                        Text("Copy Image Link").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        downloadAndSaveImage(url: image)
                                        popRoot.alertReason = "Image Saved"
                                        popRoot.alertImage = "square.and.arrow.down.fill"
                                        withAnimation {
                                            popRoot.showAlert = true
                                        }
                                    } label: {
                                        Image(systemName: "square.and.arrow.down.fill")
                                        Text("Save Image").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        if !image.isEmpty {
                                            forwardString = image
                                            forwardDataType = 1
                                            showForward = true
                                        }
                                    } label: {
                                        Image(systemName: "paperplane.fill")
                                        Text("Forward Image").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                            }
                            if let video = message.videoURL {
                                if let id = message.id, let url = URL(string: video), !popRoot.savedMemories.contains(id) {
                                    Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                    HStack(spacing: 14){
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showSheet = false
                                            withAnimation {
                                                popRoot.savedMemories.append(id)
                                            }
                                            let newID = UUID().uuidString
                                            var lat: CGFloat? = nil
                                            var long: CGFloat? = nil
                                            if let current = globe.currentLocation {
                                                lat = CGFloat(current.lat)
                                                long = CGFloat(current.long)
                                            } else if let current = auth.currentUser?.currentLocation, let place = extractLatLong(from: current) {
                                                lat = place.latitude
                                                long = place.longitude
                                            }
                                            UserService().saveMemories(docID: newID, imageURL: nil, videoURL: video, lat: lat, long: long)
                                            let new = animatableMemory(isImage: false, player: AVPlayer(url: url), memory: Memory(id: newID, video: video, lat: lat, long: long, createdAt: Timestamp()))
                                            if let idx = popRoot.allMemories.firstIndex(where: { $0.date == "Recents" }) {
                                                popRoot.allMemories[idx].allMemories.insert(new, at: 0)
                                            } else {
                                                let newMonth = MemoryMonths(date: "Recents", allMemories: [new])
                                                popRoot.allMemories.insert(newMonth, at: 0)
                                            }
                                        } label: {
                                            Image("memory")
                                                .resizable()
                                                .frame(width: 25, height: 25)
                                                .scaledToFit()
                                                .scaleEffect(1.2)
                                            Text("Save to Memories")
                                                .gradientForeground(colors: [.blue, .purple])
                                            Spacer()
                                        }
                                    }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                }
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        UIPasteboard.general.string = video
                                    } label: {
                                        Image(systemName: "link")
                                        Text("Copy Video Link").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        if let url = URL(string: video) {
                                            downloadVideoFromURL(url)
                                        }
                                        popRoot.alertReason = "Video Saved"
                                        popRoot.alertImage = "square.and.arrow.down.fill"
                                        withAnimation {
                                            popRoot.showAlert = true
                                        }
                                    } label: {
                                        Image(systemName: "square.and.arrow.down.fill")
                                        Text("Save Video").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        if !video.isEmpty {
                                            forwardString = video
                                            forwardDataType = 2
                                            showForward = true
                                        }
                                    } label: {
                                        Image(systemName: "paperplane.fill")
                                        Text("Forward Video").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                            }
                            if let audio = message.audioURL {
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        UIPasteboard.general.string = audio
                                    } label: {
                                        Image(systemName: "link")
                                        Text("Copy Audio Link").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        if let url = URL(string: audio) {
                                            downloadAudio(from: url)
                                        }
                                        popRoot.alertReason = "Audio Saved"
                                        popRoot.alertImage = "square.and.arrow.down.fill"
                                        withAnimation {
                                            popRoot.showAlert = true
                                        }
                                    } label: {
                                        Image(systemName: "square.and.arrow.down.fill")
                                        Text("Save Audio to Documents").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        if !audio.isEmpty {
                                            forwardString = audio
                                            forwardDataType = 3
                                            showForward = true
                                        }
                                    } label: {
                                        Image(systemName: "paperplane.fill")
                                        Text("Forward Audio").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                            }
                            if let file = message.file {
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        UIPasteboard.general.string = file
                                    } label: {
                                        Image(systemName: "link")
                                        Text("Copy File Link").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                            }
                            
                            if let text = message.text, let all = getAllUrl(text: text) {
                                if !all.isEmpty {
                                    Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                    ForEach(0..<all.count, id: \.self) { i in
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showSheet = false
                                            UIPasteboard.general.string = all[i].absoluteString
                                        } label: {
                                            HStack(spacing: 14){
                                                Image(systemName: "link")
                                                Text("Copy Link \(i + 1)").padding(.leading, 4)
                                                Spacer()
                                                Text(all[i].absoluteString).lineLimit(1).font(.caption).foregroundStyle(.blue)
                                            }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                        }
                                        Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                        Link(destination: all[i]) {
                                            HStack(spacing: 14){
                                                Image(systemName: "square.and.arrow.up.fill")
                                                Text("Open Link \(i + 1)").padding(.leading, 4).padding(.trailing, 30)
                                                Spacer()
                                                Text(all[i].absoluteString).lineLimit(1).font(.caption).foregroundStyle(.blue)
                                            }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                        }
                                        if i < (all.count - 1) {
                                            Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }.padding()
                    }
                }
                .padding(.top, 8)
                .padding()
            }
            .scrollIndicators(.hidden)
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(280), .height(400)])
        }
    }
    func updateStory(storyID: String) {
        if !(message.gotStories ?? []).contains(storyID) {
            if message.gotStories == nil {
                message.gotStories = [storyID]
            } else {
                message.gotStories?.append(storyID)
            }
            if let index = viewModel.currentChat {
                if let pos = viewModel.chats[index].messages?.firstIndex(where: { $0.id == message.id }) {
                    if viewModel.chats[index].messages?[pos].gotStories == nil {
                        viewModel.chats[index].messages?[pos].gotStories = [storyID]
                    } else {
                        viewModel.chats[index].messages?[pos].gotStories?.append(storyID)
                    }
                }
            }
            GlobeService().getSingleStory(id: storyID) { story in
                if let newstory = story {
                    if message.stories == nil {
                        message.stories = [newstory]
                    } else {
                        message.stories?.append(newstory)
                    }
                    if let index = viewModel.currentChat {
                        if let pos = viewModel.chats[index].messages?.firstIndex(where: { $0.id == message.id }) {
                            if viewModel.chats[index].messages?[pos].stories == nil {
                                viewModel.chats[index].messages?[pos].stories = [newstory]
                            } else {
                                viewModel.chats[index].messages?[pos].stories?.append(newstory)
                            }
                        }
                    }
                }
            }
        }
    }
    func hasStories() -> Bool {
        if let id = message.id, let index = viewModel.currentChat {
            let uid_prefix = String((id).prefix(6))
            if let foundUID = viewModel.chats[index].users?.first(where: { ($0.id ?? "").hasPrefix(uid_prefix)} )?.id {
                return !(profileModel.users.first(where: { $0.user.id == foundUID })?.stories ?? []).isEmpty
            }
        }
        return false
    }
    func setupStory() {
        if let id = message.id, let index = viewModel.currentChat {
            
            let uid_prefix = String((id).prefix(6))
            
            if let foundUID = viewModel.chats[index].users?.first(where: {($0.id ?? "").hasPrefix(uid_prefix)})?.id {
                
                if let stories = profileModel.users.first(where: { $0.user.id == foundUID })?.stories {
                    profileModel.selectedStories = stories
                }
            }
        }
    }
    func getCorners() {
        if let index = viewModel.currentChat, let messages = viewModel.chats[index].messages {
            let uid_prefix = String((message.id ?? "").prefix(6))
            
            let g_id = viewModel.chats[index].id ?? ""
            let dict = viewModel.user_colors.first(where: { $0.0 == g_id })?.1 ?? [:]
            self.myColor = dict[uid_prefix] ?? Color.orange
            
            if let i = messages.firstIndex(where: { $0.id == message.id }) {
                self.isFirst = (i == 0) || (getString(forInt: i - 1) != nil) || (i > 0 && (!(messages[i - 1].id ?? "").hasPrefix(uid_prefix) || messages[i - 1].normal != nil))
                
                self.isLast = (i < (messages.count - 1) && !(messages[i + 1].id ?? "").hasPrefix(uid_prefix) && messages[i + 1].normal == nil) || getString(forInt: i) != nil || (i == (messages.count - 1)) || (i < (messages.count - 1) && (messages[i + 1].id ?? "").hasPrefix(uid_prefix) && messages[i + 1].normal != nil)
            }
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
    func firstMessage() -> some View {
        mainContent()
            .padding(.bottom, timePosition ? (message.text == nil && message.file != nil ? 22 : 15) : 0)
            .frame(minWidth: 80)
            .overlay(content: {
                if timePosition {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(dateFinal).font(.caption)
                        }
                    }.padding(.bottom, 5).padding(.trailing, 10)
                }
            })
            .background(.gray.gradient.opacity(0.4))
            .brightness(glow2)
            .clipShape(ChatBubbleShape(direction: .left))
            .frame(maxWidth: widthOrHeight(width: true) * 0.75, alignment: .leading)
    }
    func notFirst() -> some View {
        mainContent()
            .padding(.bottom, timePosition ? (message.text == nil && message.file != nil ? 22 : 15) : 0)
            .frame(minWidth: 80)
            .overlay(content: {
                if timePosition {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Text(dateFinal).font(.caption)
                        }
                    }.padding(.bottom, 5).padding(.trailing, 10)
                }
            })
            .background(.gray.gradient.opacity(0.4))
            .brightness(glow2)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: widthOrHeight(width: true) * 0.75, alignment: .leading)
    }
    func getInfo() -> (String, String, CLLocationCoordinate2D?) {
        var name = ""
        var image = ""
        var coord: CLLocationCoordinate2D? = nil
        
        if let id = message.id, let index = viewModel.currentChat, let user = viewModel.chats[index].users?.first(where: { ($0.id ?? "").hasPrefix(id.prefix(6)) }) {
            name = "@\(user.username)"
            image = user.profileImageUrl ?? ""
            if let first = user.fullname.first, image.isEmpty {
                image = String(first)
            }
        }
        if let loc = globe.currentLocation {
            coord = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.long)
        } else if let locstr = auth.currentUser?.currentLocation, let loc = extractLatLong(from: locstr) {
            coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        }
        
        return (name, image, coord)
    }
    func getInfoReply() -> (String, String, CLLocationCoordinate2D?) {
        var name = ""
        var image = ""
        var coord: CLLocationCoordinate2D? = nil
        
        if let from = message.replyFrom, from != (auth.currentUser?.username ?? "") {
            if let index = viewModel.currentChat, let user = viewModel.chats[index].users?.first(where: { $0.username == from }) {
                name = "@\(user.username)"
                image = user.profileImageUrl ?? ""
                if let first = user.fullname.first, image.isEmpty {
                    image = String(first)
                }
            } else if let user = auth.currentUser {
                name = "@\(user.username)"
                image = user.profileImageUrl ?? ""
                if let first = user.fullname.first, image.isEmpty {
                    image = String(first)
                }
            }
        } else if let user = auth.currentUser {
            name = "@\(user.username)"
            image = user.profileImageUrl ?? ""
            if let first = user.fullname.first, image.isEmpty {
                image = String(first)
            }
        }
        if let loc = globe.currentLocation {
            coord = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.long)
        } else if let locstr = auth.currentUser?.currentLocation, let loc = extractLatLong(from: locstr) {
            coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        }
        
        return (name, image, coord)
    }
    func mainContent() -> some View {
        VStack(alignment: .leading, spacing: 5){
            if isLast {
                if let id = message.id, let index = viewModel.currentChat, let user = viewModel.chats[index].users?.first(where: { ($0.id ?? "").hasPrefix(id.prefix(6)) }) {
                    Button {
                        openUser(user.id ?? "")
                    } label: {
                        Text(user.username)
                            .foregroundStyle(myColor)
                            .brightness(colorScheme == .dark ? 0.0 : -0.5).bold().font(.headline)
                            .padding(.top, 6).padding(.horizontal, 10)
                    }
                } else {
                    Color.clear.frame(width: 5, height: 5)
                }
            } else {
                Color.clear.frame(width: 5, height: 5)
            }
            if let reply = message.replyFrom, !reply.isEmpty {
                replyView(from: reply).padding(.leading, isFirst ? 4 : 0).padding(5)
            }
            if let url = URL(string: message.file ?? "") {
                ZStack {
                    ProgressView().padding().frame(alignment: .center)
                    MainPreviewLink(url: url, message: true)
                        .padding(.leading, isFirst ? 4 : 0)
                        .padding(.horizontal, 5).padding(.bottom, (message.text ?? "").isEmpty ? 5 : 0)
                }
            }
            if let vid = message.videoURL, let vid_url = URL(string: vid) {
                ZStack(alignment: .topTrailing){
                    MessageVideoPlayer(url: vid_url, width: 240.0, height: 350.0, cornerRadius: 16.0, viewID: message.id, currentAudio: $currentAudio)
                    if !timePosition {
                        Text(dateFinal).font(.subheadline).foregroundStyle(.white).bold().padding(10)
                    }
                }
                .padding(.leading, isFirst ? 4 : 0)
                .padding(.horizontal, 5).padding(.bottom, (message.text ?? "").isEmpty ? 5 : 0)
            }
            if let lat = message.lat, let long = message.long {
                ZStack(alignment: .topTrailing){
                    MessageMapView(leading: false, long: long, lat: lat, name: message.name ?? "Location")
                    if !timePosition {
                        Text(dateFinal).font(.subheadline).foregroundStyle(.white).bold().padding(10)
                    }
                }
                .padding(.leading, isFirst ? 4 : 0)
                .padding(.horizontal, 5).padding(.bottom, (message.text ?? "").isEmpty ? 5 : 0)
            }
            if let pin = message.pinmap {
                let info = getInfo()
                ZStack {
                    PinChatRowView(pinStr: pin, personName: info.0, personImage: info.1, timestamp: message.timestamp, currentLoc: info.2, isChat: false) {
                        viewModel.GoToPin = pin
                        withAnimation(.easeIn(duration: 0.15)){
                            viewOption = false
                        }
                    }
                }
                .padding(.leading, isFirst ? 4 : 0)
                .padding(.horizontal, 5).padding(.bottom, (message.text ?? "").isEmpty ? 5 : 0)
            }
            if let image = message.imageUrl {
                ZStack(alignment: .bottomTrailing){
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: 330)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .contentShape(Rectangle()) 
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            popRoot.image = image
                            popRoot.showImage = true
                        }
                        .overlay {
                            VStack {
                                HStack(alignment: .top){
                                    Spacer()
                                    SaveImageButton(url: image, video: false)
                                }
                                Spacer()
                            }.padding(8)
                        }
                    if !timePosition {
                        Text(dateFinal).font(.subheadline).foregroundStyle(.white).bold().padding(10)
                    }
                }
                .padding(.leading, isFirst ? 4 : 0)
                .padding(.horizontal, 5).padding(.bottom, (message.text ?? "").isEmpty ? 5 : 0)
            }
            if let audio = message.audioURL, let audio_url = URL(string: audio) {
                VStack(spacing: 10){
                    MessageVoiceStreamViewSec(audioUrl: audio_url, messageID: message.id ?? "", currentAudio: $currentAudio)
                    if transcribing {
                        HStack(spacing: 8){
                            Text("Transcribing")
                            ProgressView().scaleEffect(0.8)
                        }
                    } else if let extracted = popRoot.transcriptions.first(where: { $0.0 == message.audioURL })?.1, showTranscription {
                        Text(extracted).font(.subheadline).multilineTextAlignment(.leading)
                    } else {
                        Button {
                            if popRoot.transcriptions.first(where: { $0.0 == audio })?.1 == nil {
                                transcribing = true
                                if let audio_str = message.audioURL, let url = popRoot.audioFiles.first(where: { $0.0 == audio_str })?.1 {
                                    transcribeAudio(url: url) { op_str in
                                        transcribing = false
                                        if let final = op_str, !final.isEmpty {
                                            showTranscription = true
                                            DispatchQueue.main.async {
                                                popRoot.transcriptions.append((audio, final))
                                            }
                                        } else {
                                            showTranscription = false
                                        }
                                    }
                                } else if let url = viewModel.audioMessages.first(where: { $0.0 == message.id })?.1 {
                                    transcribeAudio(url: url) { op_str in
                                        transcribing = false
                                        if let final = op_str, !final.isEmpty {
                                            showTranscription = true
                                            DispatchQueue.main.async {
                                                popRoot.transcriptions.append((audio, final))
                                            }
                                        } else {
                                            showTranscription = false
                                        }
                                    }
                                } else if let audio_str = message.audioURL {
                                    downloadAudioGetLocalURL(url_str: audio_str) { url_op in
                                        if let url = url_op {
                                            transcribeAudio(url: url) { op_str in
                                                transcribing = false
                                                if let final = op_str, !final.isEmpty {
                                                    showTranscription = true
                                                    DispatchQueue.main.async {
                                                        popRoot.transcriptions.append((audio, final))
                                                    }
                                                } else {
                                                    showTranscription = false
                                                }
                                            }
                                            DispatchQueue.main.async {
                                                self.popRoot.audioFiles.append((audio_str, url))
                                            }
                                        } else {
                                            transcribing = false
                                        }
                                    }
                                }
                            } else {
                                showTranscription = true
                                transcribing = false
                            }
                        } label: {
                            Text("Show Transcript").font(.subheadline).bold()
                        }
                    }
                }.padding(.horizontal, 10).padding(.bottom, 10)
            }
            if let text = message.text, !text.isEmpty {
                let all = checkForPostUrls(text: text)
                if !all.isEmpty {
                    ForEach(all, id: \.self) { element in
                        if element.contains("yelp") {
                            if let idx = viewModel.currentChat, let userPhoto = viewModel.chats[idx].photo ?? viewModel.chats[idx].users?.first?.profileImageUrl {
                                YelpRowView(placeID: element, isChat: false, isGroup: true, otherPhoto: userPhoto)
                                    .padding(.leading, isFirst ? 4 : 0)
                                    .padding(.horizontal, 5)
                            } else {
                                YelpRowView(placeID: element, isChat: false, isGroup: true, otherPhoto: nil)
                                    .padding(.leading, isFirst ? 4 : 0)
                                    .padding(.horizontal, 5)
                            }
                        }
                    }
                }
                
                if text.contains("pub!@#$%^&*()") {
                    visitGroup(text: text).padding(10)
                } else if let c1 = message.choice1, let c2 = message.choice2, let index = viewModel.currentChat {
                    PollRowViewChat(question: message.text ?? "", choice1: c1, choice2: c2, choice3: message.choice3, choice4: message.choice4, count1: message.count1 ?? 0, count2: message.count2 ?? 0, count3: message.count3 ?? 0, count4: message.count4 ?? 0, messageID: message.id ?? "", groupID: viewModel.chats[index].id ?? "", isGC: true, isDevGroup: false, squareName: "", whoVoted: message.voted ?? [], timestamp: message.timestamp, showUser: $showUser, selectedUser: $selectedUser).padding(.bottom, 6)
                } else {
                    LinkedText(text, tip: false, isMess: true)
                        .disabled(true)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                        .frame(alignment: .leading).multilineTextAlignment(.leading)
                }
            }
        }
    }
    func replyView(from: String) -> some View {
        VStack(spacing: 5){
            HStack {
                Text(from).font(.subheadline)
                    .foregroundStyle(replyColor).bold()
                    .brightness(colorScheme == .dark ? 0.0 : -0.5)
                Spacer()
            }.padding(.leading, 10).padding(.top, 8)
            if let text = message.replyText, !text.isEmpty {
                if text.contains("pub!@#$%^&*()") {
                    visitGroup(text: text).padding(.leading, 10).padding(.bottom, 8)
                } else if let place = extractCoordinates(from: text) {
                    HStack(spacing: 6){
                        Text("Map").font(.caption).foregroundStyle(.gray)
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if let index = viewModel.currentChat {
                                if let id = viewModel.chats[index].messages?.first(where: { $0.lat == place.lat && $0.long == place.long })?.id {
                                    viewModel.scrollToReply = id
                                }
                            }
                        }, label: {
                            Image(systemName: "arrow.up")
                                .frame(width: 18, height: 18)
                                .font(.headline)
                                .padding(8)
                                .background(.gray.opacity(0.2))
                                .clipShape(Circle())
                        })
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            forwardString = "https://hustle.page/location/lat=\(place.lat),long=\(place.long),name=\(place.name.trimmingCharacters(in: .whitespacesAndNewlines))"
                            forwardDataType = 4
                            showForward = true
                        }, label: {
                            Image(systemName: "paperplane")
                                .frame(width: 18, height: 18)
                                .font(.headline)
                                .padding(8)
                                .background(.gray.opacity(0.2))
                                .clipShape(Circle())
                        })
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            openMaps(lat: place.lat, long: place.long, name: place.name)
                        }, label: {
                            Image(systemName: "mappin.and.ellipse")
                                .frame(width: 18, height: 18)
                                .font(.headline)
                                .padding(8).foregroundStyle(.blue)
                                .background(.gray.opacity(0.2))
                                .clipShape(Circle())
                        })
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            popRoot.alertReason = "Location copied"
                            popRoot.alertImage = "link"
                            withAnimation {
                                popRoot.showAlert = true
                            }
                            UIPasteboard.general.string = "https://hustle.page/location/lat=\(place.lat),long=\(place.long),name=\(place.name.trimmingCharacters(in: .whitespacesAndNewlines))"
                        }, label: {
                            Image(systemName: "link")
                                .frame(width: 18, height: 18)
                                .font(.headline)
                                .padding(8).foregroundStyle(.blue)
                                .background(.gray.opacity(0.2))
                                .clipShape(Circle())
                        })
                    }.padding(.leading, 10).padding(.bottom, 8)
                } else if extractLatLongName(from: text) != nil {
                    HStack {
                        let info = getInfoReply()
                        PinChatRowView(pinStr: text, personName: info.0, personImage: info.1, timestamp: message.timestamp, currentLoc: info.2, isChat: false) {
                            viewModel.GoToPin = text
                            withAnimation(.easeIn(duration: 0.15)){
                                viewOption = false
                            }
                        }
                    }.padding(.leading, 5)
                } else {
                    HStack {
                        Text(text).font(.subheadline)
                        Spacer()
                    }.padding(.leading, 10).padding(.bottom, 8)
                }
            } else if let image = message.replyImage, !image.isEmpty {
                HStack {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            popRoot.image = image
                            popRoot.showImage = true
                        }
                    Spacer()
                }.padding(.leading, 10).padding(.bottom, 8)
            } else if let video = message.replyVideo, let v_url = URL(string: video) {
                smallDisabledVideo(url: v_url)
            } else if let audio = message.replyAudio, let audio_url = URL(string: audio) {
                HStack {
                    MessageVoiceStreamViewSec(audioUrl: audio_url, messageID: message.id ?? "", currentAudio: $currentAudio)
                    Spacer()
                }.padding(.leading, 10).padding(.bottom, 8)
            } else if let file = message.replyFile, let f_url = URL(string: file) {
                HStack {
                    smallLink(url: f_url)
                    Spacer()
                }.padding(.leading, 10).padding(.bottom, 8)
            }
        }
        .background(colorScheme == .dark ? Color.black.opacity(0.6) : Color.gray)
        .padding(.leading, 5)
        .overlay {
            ZStack {
                HStack {
                    Rectangle().foregroundStyle(replyColor)
                        .brightness(colorScheme == .dark ? 0.0 : -0.5)
                        .frame(width: 5)
                    Spacer()
                }
                if let video = message.replyVideo, URL(string: video) != nil {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.white)
                        .font(.headline)
                        .padding(10)
                        .background(.gray)
                        .clipShape(Circle())
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .onAppear {
            if let index = viewModel.currentChat, let user = viewModel.chats[index].users?.first(where: { $0.username == from })?.id {
                let dict = viewModel.user_colors.first(where: { $0.0 == viewModel.chats[index].id ?? "" })?.1 ?? [:]
                self.replyColor = dict[String(user.prefix(6))] ?? Color.orange
            }
        }
    }
    func visitGroup(text: String) -> some View {
        HStack(spacing: 30){
            Text("View: \(text.components(separatedBy: "pub!@#$%^&*()").last ?? "")")
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .font(.system(size: 15))
            
            Button {
                groupViewModel.fetchGroupForMessages(id: message.text?.components(separatedBy: "pub!@#$%^&*()").first ?? "")
                showLoad = true
            } label: {
                if showLoad {
                    ProgressView().padding(.trailing, 10)
                } else {
                    ZStack(alignment: .center){
                        Capsule()
                            .frame(width: 45, height: 25)
                            .foregroundColor(.blue)
                        Text("Go")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.system(size: 15).bold())
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showGroup) {
            if let first = groupViewModel.groupFromMessage.first {
                NavigationStack {
                    GroupView(group: first, imageName: "", title: "", remTab: false, showSearch: false)
                }
            }
        }
        .onChange(of: groupViewModel.groupFromMessageSet) { _, _ in
            showLoad = false
            if groupViewModel.groupFromMessage.first != nil {
                showGroup = true
                popRoot.displayingGroup = true
            } else {
                showGroup = false
            }
        }
        .onChange(of: showGroup) { _, _ in
            if !showGroup { popRoot.displayingGroup = false }
        }
    }
    func setTime(from timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
    func runReply(){
        if let id = message.id, let index = viewModel.currentChat {
            showSheet = false
            replying = nil
            
            let prefix = id.prefix(6)
            if let user = viewModel.chats[index].users?.first(where: { ($0.id ?? "").hasPrefix(prefix) })?.username {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                    withAnimation(.easeIn(duration: 0.1)){
                        replying = replyToGroup(messageID: id, selfReply: false, username: user)
                    }
                }
            }
        }
    }
    func allEmojies() -> some View {
        HStack(spacing: 3){
            if let count = message.countSmile {
                Button {
                    if !viewModel.reactionAdded.contains(where: { $0.0 == (message.id ?? "") && $0.1 == "countSmile" }) {
                        addReaction(emoji: "😂")
                    }
                } label: {
                    emojiChatView(emoji: "countSmile", count: count)
                }
            }
            if let count = message.countCry {
                Button {
                    if !viewModel.reactionAdded.contains(where: { $0.0 == (message.id ?? "") && $0.1 == "countCry" }) {
                        addReaction(emoji: "😭")
                    }
                } label: {
                    emojiChatView(emoji: "countCry", count: count)
                }
            }
            if let count = message.countThumb {
                Button {
                    if !viewModel.reactionAdded.contains(where: { $0.0 == (message.id ?? "") && $0.1 == "countThumb" }) {
                        addReaction(emoji: "👍")
                    }
                } label: {
                    emojiChatView(emoji: "countThumb", count: count)
                }
            }
            if let count = message.countBless {
                Button {
                    if !viewModel.reactionAdded.contains(where: { $0.0 == (message.id ?? "") && $0.1 == "countBless" }) {
                        addReaction(emoji: "🙏")
                    }
                } label: {
                    emojiChatView(emoji: "countBless", count: count)
                }
            }
            if let count = message.countHeart {
                Button {
                    if !viewModel.reactionAdded.contains(where: { $0.0 == (message.id ?? "") && $0.1 == "countHeart" }) {
                        addReaction(emoji: "❤️")
                    }
                } label: {
                    emojiChatView(emoji: "countHeart", count: count)
                }
            }
            if let count = message.countQuestion {
                Button {
                    if !viewModel.reactionAdded.contains(where: { $0.0 == (message.id ?? "") && $0.1 == "countQuestion" }) {
                        addReaction(emoji: "countQuestion")
                    }
                } label: {
                    emojiChatView(emoji: "countQuestion", count: count)
                }
            }
            Spacer()
        }.padding(.leading, 40)
    }
    func emojiChatView(emoji: String, count: Int) -> some View {
        HStack(spacing: 5) {
            if emoji == "countSmile" {
                Text("😂").font(.subheadline)
            } else if emoji == "countCry" {
                Text("😭").font(.subheadline)
            } else if emoji == "countThumb" {
                Text("👍").font(.subheadline)
            } else if emoji == "countBless" {
                Text("🙏").font(.subheadline)
            } else if emoji == "countHeart" {
                Text("❤️").font(.subheadline)
            } else {
                Image(systemName: "questionmark").font(.subheadline).foregroundStyle(colorScheme == .dark ? .white : .black)
            }
            if count > 1 {
                Text("\(count)").font(.caption)
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 4).background(colorScheme == .dark ? Color.gray : Color(UIColor.lightGray)).clipShape(Capsule())
    }
    func emojiView(emoji: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.bouncy(duration: 0.5)){
                showSheet = false
            }
            addReaction(emoji: emoji)
        } label: {
            ZStack {
                Circle().foregroundStyle(Color.gray.opacity(0.15))
                if emoji == "questionmark" {
                    Image(systemName: "questionmark").font(.title).foregroundStyle(colorScheme == .dark ? .white : .black)
                } else {
                    Text(emoji).font(.title)
                }
            }.frame(width: 50, height: 50)
        }
    }
    func addReaction(emoji: String){
        AudioServicesPlaySystemSound(1306)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let index = viewModel.currentChat, let docID = viewModel.chats[index].id, let id = message.id {

            if let x = viewModel.chats[index].messages?.firstIndex(where: { $0.id == id }) {
                var toSend = ""
                if emoji == "😂" {
                    toSend = "countSmile"
                    viewModel.chats[index].messages?[x].countSmile = (viewModel.chats[index].messages?[x].countSmile ?? 0) + 1
                    withAnimation {
                        message.countSmile = (message.countSmile ?? 0) + 1
                    }
                } else if emoji == "😭" {
                    toSend = "countCry"
                    viewModel.chats[index].messages?[x].countCry = (viewModel.chats[index].messages?[x].countCry ?? 0) + 1
                    withAnimation {
                        message.countCry = (message.countCry ?? 0) + 1
                    }
                } else if emoji == "👍" {
                    toSend = "countThumb"
                    viewModel.chats[index].messages?[x].countThumb = (viewModel.chats[index].messages?[x].countThumb ?? 0) + 1
                    withAnimation {
                        message.countThumb = (message.countThumb ?? 0) + 1
                    }
                } else if emoji == "🙏" {
                    toSend = "countBless"
                    viewModel.chats[index].messages?[x].countBless = (viewModel.chats[index].messages?[x].countBless ?? 0) + 1
                    withAnimation {
                        message.countBless = (message.countBless ?? 0) + 1
                    }
                } else if emoji == "❤️" {
                    toSend = "countHeart"
                    viewModel.chats[index].messages?[x].countHeart = (viewModel.chats[index].messages?[x].countHeart ?? 0) + 1
                    withAnimation {
                        message.countHeart = (message.countHeart ?? 0) + 1
                    }
                } else {
                    toSend = "countQuestion"
                    viewModel.chats[index].messages?[x].countQuestion = (viewModel.chats[index].messages?[x].countQuestion ?? 0) + 1
                    withAnimation {
                        message.countQuestion = (message.countQuestion ?? 0) + 1
                    }
                }
                viewModel.reactionAdded.append((id, toSend))
                GroupChatService().addReaction(groupID: docID, textID: id, emoji: toSend)
            }
        }
    }
}

struct animateProfilePhoto: View {
    @Environment(\.colorScheme) var colorScheme
    let myColor: Color
    let image: String?
    let size: CGFloat
    let letter: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(myColor.gradient).brightness(colorScheme == .dark ? 0.0 : -0.5)
                .frame(width: size, height: size)
            Text(letter.uppercased())
                .foregroundColor(.white).font(.headline).bold()

            if let image {
                KFImage(URL(string: image))
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size).clipShape(Circle())
                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
            }
        }
    }
}

struct ChatBubbleShape: Shape {
    enum Direction {
        case left
        case right
    }
    
    let direction: Direction
    
    func path(in rect: CGRect) -> Path {
        return (direction == .left) ? getLeftBubblePath(in: rect) : getRightBubblePath(in: rect)
    }
    
    private func getLeftBubblePath(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let path = Path { p in
            p.move(to: CGPoint(x: 25, y: height))
            p.addLine(to: CGPoint(x: width - 20, y: height))
            p.addCurve(to: CGPoint(x: width, y: height - 20),
                       control1: CGPoint(x: width - 8, y: height),
                       control2: CGPoint(x: width, y: height - 8))
            p.addLine(to: CGPoint(x: width, y: 20))
            p.addCurve(to: CGPoint(x: width - 20, y: 0),
                       control1: CGPoint(x: width, y: 8),
                       control2: CGPoint(x: width - 8, y: 0))
            p.addLine(to: CGPoint(x: 21, y: 0))
            p.addCurve(to: CGPoint(x: 4, y: 20),
                       control1: CGPoint(x: 12, y: 0),
                       control2: CGPoint(x: 4, y: 8))
            p.addLine(to: CGPoint(x: 4, y: height - 10))
            p.addCurve(to: CGPoint(x: -15, y: height - 5),
                       control1: CGPoint(x: 4, y: height - 1),
                       control2: CGPoint(x: 0, y: height))
            p.addLine(to: CGPoint(x: -0.05, y: height - 0.01))
            p.addCurve(to: CGPoint(x: 11.0, y: height - 4.0),
                       control1: CGPoint(x: 4.0, y: height + 0.5),
                       control2: CGPoint(x: 8, y: height - 1))
            p.addCurve(to: CGPoint(x: 25, y: height),
                       control1: CGPoint(x: 16, y: height),
                       control2: CGPoint(x: 20, y: height))
            
        }
        return path
    }
    
    private func getRightBubblePath(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let path = Path { p in
            p.move(to: CGPoint(x: 25, y: height))
            p.addLine(to: CGPoint(x:  20, y: height))
            p.addCurve(to: CGPoint(x: 0, y: height - 20),
                       control1: CGPoint(x: 8, y: height),
                       control2: CGPoint(x: 0, y: height - 8))
            p.addLine(to: CGPoint(x: 0, y: 20))
            p.addCurve(to: CGPoint(x: 20, y: 0),
                       control1: CGPoint(x: 0, y: 8),
                       control2: CGPoint(x: 8, y: 0))
            p.addLine(to: CGPoint(x: width - 21, y: 0))
            p.addCurve(to: CGPoint(x: width - 4, y: 20),
                       control1: CGPoint(x: width - 12, y: 0),
                       control2: CGPoint(x: width - 4, y: 8))
            p.addLine(to: CGPoint(x: width - 4, y: height - 11))
            p.addCurve(to: CGPoint(x: width, y: height),
                       control1: CGPoint(x: width - 4, y: height - 1),
                       control2: CGPoint(x: width, y: height))
            p.addLine(to: CGPoint(x: width + 0.05, y: height - 0.01))
            p.addCurve(to: CGPoint(x: width - 11, y: height - 4),
                       control1: CGPoint(x: width - 4, y: height + 0.5),
                       control2: CGPoint(x: width - 8, y: height - 1))
            p.addCurve(to: CGPoint(x: width - 25, y: height),
                       control1: CGPoint(x: width - 16, y: height),
                       control2: CGPoint(x: width - 20, y: height))
            
        }
        return path
    }
}

struct smallDisabledVideo: View {
    @EnvironmentObject var popRoot: PopToRoot
    let url: URL
    @State var player: AVPlayer? = nil
    @State var isplaying = false
    @State var muted = true
    @State var value: Float = 0.0
    @State var currentTime: Double = 0.0
    @State var totalLength: Double = 1.0
    @State var appeared = false
    
    var body: some View {
        ZStack {
            if let vid = player {
                VidPlayer(player: vid)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
            }
        }
        .onTapGesture {
            popRoot.currentAudio = url.absoluteString
            popRoot.playID = url.absoluteString
            withAnimation {
                popRoot.player = player
            }
            player?.play()
            muted = false
            self.player?.isMuted = false
        }
        .onChange(of: popRoot.player) { _, _ in
            if popRoot.player == nil {
                muted = true
                self.player?.isMuted = true
                self.player?.pause()
                self.isplaying = false
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            appeared = true
            if player == nil {
                player = AVPlayer(url: url)
            }
            
            muted = true
            self.player?.isMuted = true
            
            self.player?.pause()
            self.isplaying = false
   
            self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: 1), queue: .main) { (_) in
                self.value = self.getSliderValue()
                
                if self.value == 1.0 {
                    self.player?.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                    self.player?.play()
                }
                if let total = self.player?.currentItem?.duration.seconds, totalLength == 1.0 && total > 0.0 {
                    totalLength = total
                }
            }
        }
        .onDisappear {
            appeared = false
            popRoot.currentAudio = ""
            self.player?.pause()
            self.isplaying = false
        }
    }
    func getSliderValue() -> Float {
        if let player = player {
            if let total = player.currentItem?.duration.seconds, player.currentTime().seconds > 0.0, total > 0.0 {
                currentTime = player.currentTime().seconds
                return Float(currentTime / total)
            } else {
                return 0.0
            }
        } else {
            return 0.0
        }
    }
}
