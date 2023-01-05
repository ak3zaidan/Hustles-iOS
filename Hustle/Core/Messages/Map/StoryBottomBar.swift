import SwiftUI
import Firebase

struct StoryBottomBar: View {
    @EnvironmentObject var viewModel: MessageViewModel
    @Namespace private var animation
    @Environment(\.colorScheme) var colorScheme
    @State var bounceReply = false
    @State var bounceLike = false
    @State var isLiked = false
    @State var showSend = false
    @State var bounceSend = false
    @State var showAdditionalEmojies = false
    @State var text = ""
    @State var selectedEmoji = ""
    @State var heartStatus = false
    @State var thumbUpStatus = false
    @State var thumbDownStatus = false
    @State var fireStatus = false
    @State var smilingStatus = false
    @State var cryingStatus = false
    @State var hearthFaceStatus = false
    @State var showEmojiSent = false
    @State var showReplySent = false
    @State var showForward: Bool = false
    @State var preventDefaults: Bool = false
    @State var sendLink: String = ""
    @State var showBackgroundMessage = 0
    @State var tempText = ""
    @FocusState.Binding var focusField: FocusedField?
    @Binding var storyID: String
    let posterID: String
    let currentID: String
    let myMessages: [String]
    let storyViews: [String]
    @Binding var disableDrag: Bool
    let isMap: Bool
    let canOpenChat: Bool
    let bigger: Bool
    let openChat: () -> Void

    var body: some View {
        ZStack(alignment: .bottom){
            VStack(spacing: 25){
                if showAdditionalEmojies {
                    VStack(spacing: 5){
                        Text("Send reaction as a message")
                            .font(.caption).foregroundStyle(.white)
                            .opacity(0.7)
                        HStack(spacing: 15){
                            CustomEmoji(emoji: "❤️", status: heartStatus) {
                                thumbUpStatus = false
                                thumbDownStatus = false
                                fireStatus = false
                                smilingStatus = false
                                cryingStatus = false
                                hearthFaceStatus = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                heartStatus.toggle()
                                if heartStatus {
                                    let asset = getAssetFromEmoji(emoji: "❤️")
                                    viewStory(emoji: asset, forStoryId: storyID)
                                    sendMessage(text: asset, isEmoji: true)
                                } else {
                                    unreact()
                                }
                                withAnimation(.easeInOut(duration: 0.15)){
                                    if heartStatus {
                                        selectedEmoji = "❤️"
                                    } else {
                                        selectedEmoji = ""
                                    }
                                }
                            }
                            CustomEmoji(emoji: "👍", status: thumbUpStatus) {
                                heartStatus = false
                                thumbDownStatus = false
                                fireStatus = false
                                smilingStatus = false
                                cryingStatus = false
                                hearthFaceStatus = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                thumbUpStatus.toggle()
                                if thumbUpStatus {
                                    let asset = getAssetFromEmoji(emoji: "👍")
                                    viewStory(emoji: asset, forStoryId: storyID)
                                    sendMessage(text: asset, isEmoji: true)
                                } else {
                                    unreact()
                                }
                                withAnimation(.easeInOut(duration: 0.15)){
                                    if thumbUpStatus {
                                        selectedEmoji = "👍"
                                    } else {
                                        selectedEmoji = ""
                                    }
                                }
                            }
                            CustomEmoji(emoji: "👎", status: thumbDownStatus) {
                                heartStatus = false
                                thumbUpStatus = false
                                fireStatus = false
                                smilingStatus = false
                                cryingStatus = false
                                hearthFaceStatus = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                thumbDownStatus.toggle()
                                if thumbDownStatus {
                                    let asset = "thumbDownE"
                                    viewStory(emoji: asset, forStoryId: storyID)
                                    sendMessage(text: asset, isEmoji: true)
                                } else {
                                    unreact()
                                }
                                withAnimation(.easeInOut(duration: 0.15)){
                                    if thumbDownStatus {
                                        selectedEmoji = "👎"
                                    } else {
                                        selectedEmoji = ""
                                    }
                                }
                            }
                            CustomEmoji(emoji: "🔥", status: fireStatus) {
                                heartStatus = false
                                thumbUpStatus = false
                                thumbDownStatus = false
                                smilingStatus = false
                                cryingStatus = false
                                hearthFaceStatus = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                fireStatus.toggle()
                                if fireStatus {
                                    let asset = getAssetFromEmoji(emoji: "🔥")
                                    viewStory(emoji: asset, forStoryId: storyID)
                                    sendMessage(text: asset, isEmoji: true)
                                } else {
                                    unreact()
                                }
                                withAnimation(.easeInOut(duration: 0.15)){
                                    if fireStatus {
                                        selectedEmoji = "🔥"
                                    } else {
                                        selectedEmoji = ""
                                    }
                                }
                            }
                            CustomEmoji(emoji: "😂", status: smilingStatus) {
                                heartStatus = false
                                thumbUpStatus = false
                                thumbDownStatus = false
                                fireStatus = false
                                cryingStatus = false
                                hearthFaceStatus = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                smilingStatus.toggle()
                                if smilingStatus {
                                    let asset = getAssetFromEmoji(emoji: "😂")
                                    viewStory(emoji: asset, forStoryId: storyID)
                                    sendMessage(text: asset, isEmoji: true)
                                } else {
                                    unreact()
                                }
                                withAnimation(.easeInOut(duration: 0.15)){
                                    if smilingStatus {
                                        selectedEmoji = "😂"
                                    } else {
                                        selectedEmoji = ""
                                    }
                                }
                            }
                            CustomEmoji(emoji: "😭", status: cryingStatus) {
                                heartStatus = false
                                thumbUpStatus = false
                                thumbDownStatus = false
                                fireStatus = false
                                smilingStatus = false
                                hearthFaceStatus = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                cryingStatus.toggle()
                                if cryingStatus {
                                    let asset = getAssetFromEmoji(emoji: "😭")
                                    viewStory(emoji: asset, forStoryId: storyID)
                                    sendMessage(text: asset, isEmoji: true)
                                } else {
                                    unreact()
                                }
                                withAnimation(.easeInOut(duration: 0.15)){
                                    if cryingStatus {
                                        selectedEmoji = "😭"
                                    } else {
                                        selectedEmoji = ""
                                    }
                                }
                            }
                            CustomEmoji(emoji: "🥰", status: hearthFaceStatus) {
                                heartStatus = false
                                thumbUpStatus = false
                                thumbDownStatus = false
                                fireStatus = false
                                smilingStatus = false
                                cryingStatus = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                hearthFaceStatus.toggle()
                                if hearthFaceStatus {
                                    let asset = getAssetFromEmoji(emoji: "🥰")
                                    viewStory(emoji: asset, forStoryId: storyID)
                                    sendMessage(text: asset, isEmoji: true)
                                } else {
                                    unreact()
                                }
                                withAnimation(.easeInOut(duration: 0.15)){
                                    if hearthFaceStatus {
                                        selectedEmoji = "🥰"
                                    } else {
                                        selectedEmoji = ""
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if showEmojiSent || showReplySent {
                    let sWidth = widthOrHeight(width: true)
                    HStack(spacing: 15){
                        if !isMap && !canOpenChat {
                            Spacer()
                        }
                        if !selectedEmoji.isEmpty && showEmojiSent {
                            LottieView(loopMode: .loop, name: getAssetFromEmoji(emoji: selectedEmoji))
                                .scaleEffect(getScaleFromEmoji(emoji: selectedEmoji))
                                .frame(width: 30, height: 50)
                                .clipShape(Rectangle())
                                .contentShape(Rectangle())
                                .rotationEffect(.degrees(selectedEmoji == "👎" ? 180.0 : 0.0))
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)){
                                        showEmojiSent = false
                                        showReplySent = false
                                    }
                                }
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white).frame(width: 30, height: 50)
                                .font(.title3).foregroundStyle(.white)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)){
                                        showEmojiSent = false
                                        showReplySent = false
                                    }
                                }
                        }
                        Text("Reply Sent.")
                            .font(.body).foregroundStyle(.white)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)){
                                    showEmojiSent = false
                                    showReplySent = false
                                }
                            }
                        Spacer()
                        if isMap && canOpenChat {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                openChat()
                                showEmojiSent = false
                                showReplySent = false
                            } label: {
                                Text("View in Chat")
                                    .font(.body).fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .frame(width: isMap ? (sWidth * 0.8) : (sWidth * 0.5))
                    .padding(.horizontal)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                HStack(alignment: .bottom, spacing: 10){
                    TextField("", text: $text, axis: .vertical)
                        .padding(.horizontal, 15).padding(.vertical, 4)
                        .submitLabel(.done)
                        .onSubmit {
                            focusField = .two
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .tint(.purple)
                        .foregroundStyle(.white)
                        .focused($focusField, equals: .one)
                        .frame(minHeight: 40)
                        .lineLimit(5)
                        .background(alignment: .leading, content: {
                            if showBackgroundMessage == 1 {
                                ZStack(alignment: .leading){
                                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    Text(tempText)
                                        .foregroundStyle(.white)
                                        .lineLimit(5)
                                        .multilineTextAlignment(.leading)
                                        .padding(.horizontal, 15).padding(.vertical, 4)
                                }
                                .matchedGeometryEffect(id: "topM", in: animation)
                            }
                        })
                        .background(content: {
                            if text.isEmpty {
                                HStack {
                                    Text("Reply to Story...")
                                        .opacity(0.7).font(.body)
                                        .foregroundStyle(.white)
                                    Spacer()
                                }.padding(.leading, 15)
                            }
                        })
                        .background(.ultraThinMaterial)
                        .overlay(content: {
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(.gray, lineWidth: 1.0)
                        })
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    
                    if showSend {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            tempText = text
                            withAnimation(.easeInOut(duration: 0.2)){
                                showAdditionalEmojies = false
                                showBackgroundMessage = 1
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                focusField = .two
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                withAnimation(.easeInOut(duration: 1.5)){
                                    showBackgroundMessage = 2
                                    text = ""
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showBackgroundMessage = 0
                                withAnimation(.easeInOut(duration: 0.2)){
                                    showReplySent = true
                                }
                                sendMessage(text: tempText, isEmoji: false)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                                withAnimation(.easeInOut(duration: 0.2)){
                                    showReplySent = false
                                }
                            }
                        }, label:{
                            ZStack {
                                Circle().fill(.orange.gradient)
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 20))
                                    .offset(x: -1).offset(y: 1)
                                    .rotationEffect(.degrees(45.0))
                                    .foregroundColor(.black)
                                    .symbolEffect(.bounce, value: bounceSend)
                            }.frame(width: 40, height: 40)
                        })
                        .transition(.slide.combined(with: .blurReplace))
                        .disabled(showBackgroundMessage != 0)
                    } else {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)){
                                bounceReply.toggle()
                            }
                            sendLink = "https://hustle.page/story/\(storyID)/"
                            showForward = true
                        }, label:{
                            ZStack {
                                Rectangle()
                                    .frame(width: 30, height: 40)
                                    .foregroundStyle(.gray).opacity(0.001)
                                Image(systemName: "arrowshape.turn.up.right")
                                    .foregroundStyle(.white).font(.title2)
                                    .symbolEffect(.bounce, value: bounceReply)
                                    .symbolEffect(.bounce, value: bounceSend)
                            }
                        }).transition(.scale)
                        ZStack {
                            Rectangle()
                                .frame(width: 30, height: 40)
                                .foregroundStyle(.gray).opacity(0.001)
                            
                            CustomButton(systemImage: "heart.fill", status: isLiked) {
                                isLiked.toggle()
                                withAnimation(.easeInOut(duration: 0.2)){
                                    bounceLike.toggle()
                                }
                                if isLiked {
                                    viewStory(emoji: getAssetFromEmoji(emoji: "❤️"), forStoryId: storyID)
                                } else {
                                    unreact()
                                }
                                thumbUpStatus = false
                                thumbDownStatus = false
                                fireStatus = false
                                smilingStatus = false
                                cryingStatus = false
                                hearthFaceStatus = false
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }.transition(.scale)
                    }
                }.padding(.horizontal, 12).padding(.bottom, 6)
            }
            
            if showBackgroundMessage == 2 {
                ZStack {
                    Text(tempText)
                        .foregroundStyle(.white)
                        .lineLimit(5)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background {
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .matchedGeometryEffect(id: "topM", in: animation)
                .offset(y: -widthOrHeight(width: false) * 1.5)
            }
        }
        .onChange(of: storyID, { oldVal, _ in
            setDefaults()
            viewStory(emoji: "", forStoryId: oldVal)
        })
        .onAppear(perform: {
            setDefaults()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewStory(emoji: "", forStoryId: storyID)
            }
        })
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink, bigger: bigger ? true : nil)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.6), .large])
        })
        .onChange(of: selectedEmoji, { _, newValue in
            if preventDefaults {
                preventDefaults = false
            } else if !newValue.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.15)){
                        showAdditionalEmojies = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.2)){
                            showEmojiSent = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 0.15)){
                            showEmojiSent = false
                        }
                    }
                    focusField = .two
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        })
        .onChange(of: focusField, { _, newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.15)){
                    showAdditionalEmojies = newValue == .one
                }
            }
            disableDrag = newValue == .one
        })
        .onChange(of: text) { _, _ in
            if text.contains("\n") {
                text.removeAll(where: { $0.isNewline })
                focusField = .two
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } else {
                withAnimation(.easeInOut(duration: 0.15)){
                    let temp = showSend
                    showSend = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    if temp != showSend {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            bounceSend.toggle()
                        }
                    }
                }
            }
        }
    }
    func setDefaults() {
        selectedEmoji = ""
        isLiked = false
        heartStatus = false
        thumbUpStatus = false
        thumbDownStatus = false
        fireStatus = false
        smilingStatus = false
        cryingStatus = false
        hearthFaceStatus = false
        
        var preEmoji = ""
        if let index = viewModel.viewedStories.firstIndex(where: { $0.0 == storyID }), !viewModel.viewedStories[index].1.isEmpty {
            preEmoji = viewModel.viewedStories[index].1
        } else if let current = storyViews.first(where: { $0.contains(currentID) }), let emoji = extractEmoji(from: current) {
            preEmoji = emoji
        }
        if !preEmoji.isEmpty {
            switch preEmoji {
            case "heartE":
                selectedEmoji = "❤️"
                preventDefaults = true
                isLiked = true
                heartStatus = true
            case "thumbUpE":
                selectedEmoji = "👍"
                preventDefaults = true
                thumbUpStatus = true
            case "thumbDownE":
                selectedEmoji = "👎"
                preventDefaults = true
                thumbDownStatus = true
            case "fireE":
                selectedEmoji = "🔥"
                preventDefaults = true
                fireStatus = true
            case "laughingE":
                selectedEmoji = "😂"
                preventDefaults = true
                smilingStatus = true
            case "cryingE":
                selectedEmoji = "😭"
                preventDefaults = true
                cryingStatus = true
            case "faceHeartE":
                selectedEmoji = "🥰"
                preventDefaults = true
                hearthFaceStatus = true
            default:
                return
            }
        }
    }
    func sendMessage(text: String, isEmoji: Bool) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        
        let uid_prefix = String(currentID.prefix(5))
        let id = uid_prefix + String("\(UUID())".prefix(15))
        let messageText = "https://hustle.page/story/\(storyID)/\(text)/"
        
        if let index = viewModel.chats.firstIndex(where: { $0.user.id == posterID }) {
            if isEmoji {
                if let first = viewModel.chats[index].messages?.first?.text, let val = extractTextEmojiFromStoryURL(urlStr: first) {
                    if let checkEmoji = val.emoji, val.storyID == storyID {
                        if checkEmoji == text {
                            return
                        } else {
                            viewModel.chats[index].messages?[0].text = messageText
                            return
                        }
                    }
                }
            }
            
            let new = Message(id: id, uid_one_did_recieve: (viewModel.chats[index].convo.uid_one == currentID) ? false : true, seen_by_reciever: false, text: messageText, imageUrl: nil, timestamp: Timestamp(), sentAImage: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, pinmap: nil)
            
            viewModel.sendStory(i: index, myMessArr: myMessages, otherUserUid: posterID, caption: messageText, imageUrl: nil, videoUrl: nil, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: nil)
            
            viewModel.chats[index].lastM = new
            
            viewModel.chats[index].messages?.insert(new, at: 0)
            
            if let indexSec = viewModel.currentChat, indexSec == index {
                if viewModel.chats[index].messages == nil {
                    viewModel.chats[index].messages = [new]
                }
                viewModel.setDate()
            }
        } else {
            viewModel.sendStorySec(otherUserUid: posterID, caption: messageText, imageUrl: nil, videoUrl: nil, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: nil)
        }
    }
    func unreact() {
        if let index = viewModel.viewedStories.firstIndex(where: { $0.0 == storyID }) {
            if !viewModel.viewedStories[index].1.isEmpty {
                GlobeService().removeStoryView(storyID: storyID, viewName: "\(currentID)/\(viewModel.viewedStories[index].1)")
                GlobeService().addStoryView(storyID: storyID, emoji: "")
                viewModel.viewedStories[index].1 = ""
            }
        } else if let current = storyViews.first(where: { $0.contains(currentID) }) {
            if extractEmoji(from: current) != nil {
                viewModel.viewedStories.append((storyID, ""))
                GlobeService().removeStoryView(storyID: storyID, viewName: current)
                GlobeService().addStoryView(storyID: storyID, emoji: "")
            }
        }
    }
    func viewStory(emoji: String, forStoryId: String) {
        if emoji.isEmpty {
            if !viewModel.viewedStories.contains(where: { $0.0 == forStoryId }) {
                if !storyViews.contains(where: { $0.contains(currentID) }) {
                    viewModel.viewedStories.append((forStoryId, ""))
                    GlobeService().addStoryView(storyID: forStoryId, emoji: "")
                }
            }
        } else {
            if let index = viewModel.viewedStories.firstIndex(where: { $0.0 == forStoryId }) {
                if viewModel.viewedStories[index].1.isEmpty {
                    GlobeService().removeStoryView(storyID: forStoryId, viewName: currentID)
                    GlobeService().addStoryView(storyID: forStoryId, emoji: emoji)
                    viewModel.viewedStories[index].1 = emoji
                } else if viewModel.viewedStories[index].1 != emoji {
                    GlobeService().removeStoryView(storyID: forStoryId, viewName: "\(currentID)/\(viewModel.viewedStories[index].1)")
                    GlobeService().addStoryView(storyID: forStoryId, emoji: emoji)
                    viewModel.viewedStories[index].1 = emoji
                }
            } else if let current = storyViews.first(where: { $0.contains(currentID) }) {
                if let emojiOld = extractEmoji(from: current) {
                    if emojiOld != emoji {
                        viewModel.viewedStories.append((forStoryId, emoji))
                        GlobeService().removeStoryView(storyID: forStoryId, viewName: current)
                        GlobeService().addStoryView(storyID: forStoryId, emoji: emoji)
                    }
                } else {
                    viewModel.viewedStories.append((forStoryId, emoji))
                    GlobeService().removeStoryView(storyID: forStoryId, viewName: currentID)
                    GlobeService().addStoryView(storyID: forStoryId, emoji: emoji)
                }
            } else {
                viewModel.viewedStories.append((forStoryId, emoji))
                GlobeService().addStoryView(storyID: forStoryId, emoji: emoji)
            }
        }
    }
    @ViewBuilder
    func CustomButton(systemImage: String, status: Bool, onTap: @escaping () -> ()) -> some View {
        Button(action: onTap) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .symbolEffect(.bounce, value: bounceLike)
                .symbolEffect(.bounce, value: bounceSend)
                .foregroundColor(isLiked ? .red : .white).font(.title2)
                .particleEffectLike (
                    systemImage: systemImage,
                    font: .body,
                    status: status,
                    activeTint: .red,
                    inActiveTint: .red,
                    direction: true
                )
        }
    }
    @ViewBuilder
    func CustomEmoji(emoji: String, status: Bool, onTap: @escaping () -> ()) -> some View {
        ZStack {
            if emoji == selectedEmoji {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 20, height: 20).scaleEffect(2.2)
                    .offset(x: -0.5, y: -2).transition(.scale)
            }
            Button(action: onTap) {
                ZStack {
                    LottieView(loopMode: .loop, name: getAssetFromEmoji(emoji: emoji))
                        .scaleEffect(getScaleFromEmoji(emoji: emoji))
                        .frame(width: 30, height: 50)
                        .clipShape(Rectangle())
                        .contentShape(Rectangle())
                        .rotationEffect(.degrees(emoji == "👎" ? 180.0 : 0.0))
                    Circle()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.gray).opacity(0.001)
                        .particleEffectLike (
                            systemImage: "party.popper.fill",
                            font: .body,
                            status: status,
                            activeTint: .red,
                            inActiveTint: .red,
                            direction: true
                        )
                }
            }
        }
    }
}

func extractTextEmojiFromStoryURL(urlStr: String) -> (storyID: String, text: String?, emoji: String?)? {
    let baseURL = "https://hustle.page/story/"

    guard urlStr.hasPrefix(baseURL) else {
        return nil
    }
    let remainingString = String(urlStr.dropFirst(baseURL.count))
    guard let firstSlashIndex = remainingString.firstIndex(of: "/") else {
        return nil
    }
    
    let storyID = String(remainingString[..<firstSlashIndex])
    var text = String(remainingString[remainingString.index(after: firstSlashIndex)...])
    
    if text.hasSuffix("/") {
        text.removeLast()
    }
    if text.trimmingCharacters(in: .whitespaces).isEmpty {
        return nil
    }
    
    if isValidAssetName(assetName: text){
        return (storyID, nil, text)
    }
    
    return (storyID, text, nil)
}

func isValidAssetName(assetName: String) -> Bool {
    let validAssetNames = [
        "heartE",
        "thumbUpE",
        "thumbDownE",
        "fireE",
        "laughingE",
        "cryingE",
        "faceHeartE"
    ]
    
    return validAssetNames.contains(assetName)
}

func getAssetFromEmoji(emoji: String) -> String {
    if emoji == "❤️" {
        return "heartE"
    } else if emoji == "👍" || emoji ==  "👎" {
        return "thumbUpE"
    } else if emoji == "🔥" {
        return "fireE"
    } else if emoji == "😂" {
        return "laughingE"
    } else if emoji == "😭" {
        return "cryingE"
    } else if emoji == "🥰" {
        return "faceHeartE"
    }
    return ""
}

func getEmojiFromAsset(assetName: String) -> String {
    switch assetName {
    case "heartE":
        return "❤️"
    case "thumbUpE":
        return "👍"
    case "thumbDownE":
        return "👎"
    case "fireE":
        return "🔥"
    case "laughingE":
        return "😂"
    case "cryingE":
        return "😭"
    case "faceHeartE":
        return "🥰"
    default:
        return ""
    }
}

func getScaleFromEmoji(emoji: String) -> Double {
    if emoji == "❤️" {
        return 0.04
    } else if emoji == "👍" || emoji ==  "👎" {
        return 0.07
    } else if emoji == "🔥" {
        return 0.06
    } else if emoji == "😂" {
        return 0.03
    } else if emoji == "😭" {
        return 0.065
    } else if emoji == "🥰" {
        return 0.135
    }
    return 1.0
}

func extractEmoji(from input: String) -> String? {
    let components = input.components(separatedBy: "/")

    if components.count > 1 {
        return components[1]
    } else {
        return nil
    }
}

func extractUidAndEmoji(from input: String) -> (String?, String?)? {
    let components = input.components(separatedBy: "/")

    if components.count > 1 {
        return (components[0], components[1])
    } else if components.count == 1 {
        return (components[0], nil)
    } else {
        return nil
    }
}
