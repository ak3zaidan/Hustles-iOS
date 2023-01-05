import SwiftUI
import Kingfisher
import Photos
import Firebase
import AVFoundation

struct MessageBubble: View {
    @State var message: Message
    let is_uid_one: Bool
    @Binding var replying: replyTo?
    @Binding var currentAudio: String
    let recieved: Bool
    @Binding var editing: Editing?
    @Binding var searching: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @State var time: Bool = false
    @State private var showTime = false
    @EnvironmentObject var imageModel: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var explore: ExploreViewModel
    @EnvironmentObject var profileModel: ProfileViewModel
    @State private var topCorner: Bool = false
    @State private var bottomCorner: Bool = false
    @State private var showSheet: Bool = false
    @State private var isPressingDown: Bool = false
    @State private var isNotifying: Bool = false
    @State private var started: Bool = false
    @State var location: Int = 0
    @State var glow = 0.0
    @State var glow2 = 0.0
    @State var size: CGFloat = 0
    @State var opacity: CGFloat = 0
    @State var gestureOffset: CGFloat = 0
    @State private var replyOnRelease: Bool = false
    @State private var showForward: Bool = false
    @State private var forwardString = ""
    @State private var forwardDataType: Int = 1
    @State var showTranscription: Bool = false
    @State var transcribing: Bool = false
    @Binding var viewOption: Bool
    
    @Binding var isExpanded: Bool
    let animation: Namespace.ID
    @Binding var addPadding: Bool
    
    var body: some View {
        VStack(alignment: recieved ? .leading : .trailing, spacing: 1){
            VStack(alignment: recieved ? .leading : .trailing, spacing: 1){
                if let from = message.replyFrom {
                    HStack(alignment: .bottom, spacing: 5){
                        if !recieved {
                            Spacer()
                            messageRepView(from: from, text: message.replyText, image: message.replyImage, elo: message.replyELO, file: message.replyFile)
                                .padding(.bottom, 5)
                        }
                        HStack(alignment: .top, spacing: 0){
                            if recieved {
                                Rectangle().frame(width: 2).foregroundStyle(.gray)
                                Rectangle().frame(width: 20, height: 2).foregroundStyle(.gray)
                            } else {
                                Rectangle().frame(width: 20, height: 2).foregroundStyle(.gray)
                                Rectangle().frame(width: 2).foregroundStyle(.gray)
                            }
                        }.frame(height: 15)
                        if recieved {
                            messageRepView(from: from, text: message.replyText, image: message.replyImage, elo: message.replyELO, file: message.replyFile)
                                .padding(.bottom, 5)
                            Spacer()
                        }
                    }
                    .padding(.top, 9)
                    .onTapGesture { }
                }
                VStack(spacing: 1) {
                    HStack {
                        if !recieved {
                            Spacer()
                            if location == 1 {
                                if let emoji = message.emoji, !emoji.isEmpty {
                                    emojiChatView(emoji: emoji)
                                }
                            }
                        }
                        
                        ZStack(alignment: .bottomTrailing){
                            if let image = message.imageUrl {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 330)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .contentShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(content: {
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.6), lineWidth: 1.0)
                                    })
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        popRoot.image = image
                                        popRoot.showImage = true
                                    }
                                if message.text == nil {
                                    Text("\(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))").font(.subheadline).foregroundStyle(.white).bold().padding(10)
                                }
                            } else if let image = getImage(forStringId: message.id ?? "") {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 330)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .contentShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(content: {
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.6), lineWidth: 1.0)
                                    })
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        popRoot.realImage = image
                                        popRoot.showImageMessage = true
                                    }
                                if message.text == nil {
                                    Text("\(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))").font(.subheadline).foregroundStyle(.white).bold().padding(10)
                                }
                            }
                        }
                        if recieved {
                            VStack(spacing: 10){
                                if let emoji = message.emoji, !emoji.isEmpty && location == 1 {
                                    emojiChatView(emoji: emoji).padding(.leading, 1)
                                    if let url = message.imageUrl {
                                        SaveImageButton(url: url, video: false).offset(x: 6).padding(.leading, 1)
                                    }
                                } else {
                                    if let url = message.imageUrl {
                                        SaveImageButton(url: url, video: false).padding(.leading, 5)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                    if let audio = message.audioURL, let audio_url = URL(string: audio) {
                        VStack(alignment: recieved ? .leading : .trailing, spacing: 5){
                            HStack {
                                if !recieved {
                                    Spacer()
                                    if let emoji = message.emoji, !emoji.isEmpty && location == 5 {
                                        emojiChatView(emoji: emoji)
                                    }
                                }
                                MessageVoiceStreamView(audioUrl: audio_url, messageID: message.id ?? "", isGroup: false, currentAudio: $currentAudio)
                                if recieved {
                                    if let emoji = message.emoji, !emoji.isEmpty && location == 5 {
                                        emojiChatView(emoji: emoji)
                                    }
                                    Spacer()
                                }
                            }
                            HStack {
                                if !recieved {
                                    Spacer()
                                }
                                VStack(spacing: 5){
                                    if transcribing {
                                        HStack(spacing: 8){
                                            Text("Transcribing").font(.subheadline)
                                            ProgressView().scaleEffect(0.8)
                                        }
                                    } else {
                                        Button(action: {
                                            if showTranscription {
                                                withAnimation(.easeInOut) {
                                                    showTranscription = false
                                                }
                                            } else if popRoot.transcriptions.first(where: { $0.0 == audio })?.1 == nil {
                                                transcribing = true
                                                if let audio_str = message.audioURL, let url = popRoot.audioFiles.first(where: { $0.0 == audio_str })?.1 {
                                                    transcribeAudio(url: url) { op_str in
                                                        transcribing = false
                                                        if let final = op_str, !final.isEmpty {
                                                            DispatchQueue.main.async {
                                                                popRoot.transcriptions.append((audio, final))
                                                            }
                                                            withAnimation(.easeInOut) {
                                                                showTranscription = true
                                                            }
                                                        } else {
                                                            withAnimation(.easeInOut) {
                                                                showTranscription = false
                                                            }
                                                        }
                                                    }
                                                } else if let audio_str = message.audioURL {
                                                    downloadAudioGetLocalURL(url_str: audio_str) { url_op in
                                                        if let url = url_op {
                                                            transcribeAudio(url: url) { op_str in
                                                                transcribing = false
                                                                if let final = op_str, !final.isEmpty {
                                                                    DispatchQueue.main.async {
                                                                        popRoot.transcriptions.append((audio, final))
                                                                    }
                                                                    withAnimation(.easeInOut) {
                                                                        showTranscription = true
                                                                    }
                                                                } else {
                                                                    withAnimation(.easeInOut) {
                                                                        showTranscription = false
                                                                    }
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
                                                withAnimation(.easeInOut) {
                                                    showTranscription = true
                                                }
                                                transcribing = false
                                            }
                                        }, label: {
                                            HStack(spacing: 3){
                                                Text("Show Transcript")
                                                Image(systemName: showTranscription ? "chevron.up" : "chevron.down")
                                            }.font(.subheadline)
                                        })
                                    }
                                    if let extracted = popRoot.transcriptions.first(where: { $0.0 == message.audioURL })?.1, showTranscription {
                                        Text(extracted)
                                            .font(.body).multilineTextAlignment(.leading)
                                            .transition(.scale.combined(with: .identity))
                                    }
                                }
                                .padding(10)
                                .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .frame(maxWidth: widthOrHeight(width: true) * 0.75, alignment: recieved ? .leading : .trailing)
                                if recieved {
                                    Spacer()
                                }
                            }
                        }
                    } else if let audio = imageModel.audioMessages.first(where: { $0.0 == message.id }) {
                        HStack {
                            if !recieved {
                                Spacer()
                                if let emoji = message.emoji, !emoji.isEmpty && location == 5 {
                                    emojiChatView(emoji: emoji)
                                }
                            }
                            MessageVoiceStreamViewThird(audioUrl: audio.1, messageID: message.id ?? "", isGroup: false, currentAudio: $currentAudio)
                            if recieved {
                                if let emoji = message.emoji, !emoji.isEmpty && location == 5 {
                                    emojiChatView(emoji: emoji)
                                }
                                Spacer()
                            }
                        }
                    }
                    if let text = message.text {
                        let all = checkForPostUrls(text: text)
                        if !all.isEmpty {
                            HStack {
                                if !recieved {
                                    Spacer()
                                }
                                ForEach(all, id: \.self) { element in
                                    if element.contains("yelp") {
                                        if let idx = imageModel.currentChat, let userPhoto = imageModel.chats[idx].user.profileImageUrl {
                                            YelpRowView(placeID: element, isChat: true, isGroup: false, otherPhoto: userPhoto)
                                        } else {
                                            YelpRowView(placeID: element, isChat: true, isGroup: false, otherPhoto: nil)
                                        }
                                    }
                                }
                                if recieved {
                                    Spacer()
                                }
                            }
                        }
                    }
                    if let vid = message.videoURL, let vid_url = URL(string: vid) {
                        HStack {
                            if !recieved {
                                Spacer()
                                if let emoji = message.emoji, !emoji.isEmpty && location == 4 {
                                    emojiChatView(emoji: emoji)
                                }
                            }
                            ZStack(alignment: .topTrailing){
                                MessageVideoPlayer(url: vid_url, width: 240.0, height: 350.0, cornerRadius: 15.0, viewID: message.id, currentAudio: $currentAudio)
                                if message.text == nil {
                                    Text("\(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))").font(.subheadline).foregroundStyle(.white).bold().padding(10)
                                }
                            }
                            if recieved {
                                VStack(spacing: 20){
                                    if let emoji = message.emoji, !emoji.isEmpty && location == 4 {
                                        emojiChatView(emoji: emoji).padding(.leading, 1)
                                        SaveImageButton(url: vid, video: true).offset(x: 6).padding(.leading, 1)
                                    } else {
                                        SaveImageButton(url: vid, video: true).padding(.leading, 10)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    if message.elo != nil {
                        HStack {
                            if !recieved {
                                Spacer()
                                if location == 2 {
                                    if let emoji = message.emoji, !emoji.isEmpty {
                                        emojiChatView(emoji: emoji)
                                    }
                                }
                            }
                            SendEloBubble(time: $time, message: message, displayTime: false, recieved: recieved)
                                .onChange(of: time) { _, _ in
                                    showTime = time
                                }
                                .onChange(of: showTime) { _, _ in
                                    time = showTime
                                }
                            if recieved {
                                if location == 2 {
                                    if let emoji = message.emoji, !emoji.isEmpty {
                                        emojiChatView(emoji: emoji)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    if let lat = message.lat, let long = message.long {
                        HStack {
                            if !recieved {
                                Spacer()
                            }
                            MessageMapView(leading: !recieved, long: long, lat: lat, name: message.name ?? "Location")
                                .overlay(alignment: recieved ? .topLeading : .topTrailing){
                                    if let emoji = message.emoji, !emoji.isEmpty && location == 6 {
                                        emojiChatViewSec(emoji: emoji).padding(10)
                                    }
                                }
                            if recieved {
                                Spacer()
                            }
                        }
                    }
                    if let pin = message.pinmap {
                        HStack {
                            if !recieved {
                                Spacer()
                            }
                            let info = getInfo()
                            
                            PinChatRowView(pinStr: pin, personName: info.0, personImage: info.1, timestamp: message.timestamp, currentLoc: info.2, isChat: true) {
                                imageModel.GoToPin = pin
                                withAnimation(.easeIn(duration: 0.15)){
                                    viewOption = false
                                }
                            }
                            .overlay {
                                if let emoji = message.emoji, !emoji.isEmpty && (message.text ?? "").isEmpty {
                                    HStack {
                                        if emoji == "questionmark" {
                                            Image(systemName: "questionmark")
                                                .font(.subheadline).padding(8)
                                                .foregroundStyle(colorScheme == .dark ? .black : .white)
                                                .background(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                                                .clipShape(Circle())
                                                .overlay {
                                                    Circle()
                                                        .stroke(Color.red, lineWidth: 1)
                                                }
                                        } else {
                                            Text(emoji)
                                                .font(.subheadline).padding(8)
                                                .background(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                                                .clipShape(Circle())
                                                .overlay {
                                                    Circle()
                                                        .stroke(Color.red, lineWidth: 1)
                                                }
                                        }
                                    }.offset(x: 20, y: -30)
                                }
                            }
                            
                            if recieved {
                                Spacer()
                            }
                        }
                    }
                    if let text = message.text, !text.isEmpty {
                        HStack {
                            if let result = extractTextEmojiFromStoryURL(urlStr: text), result.emoji != nil || result.text != nil {
                                if !recieved {
                                    Spacer()
                                }
                                if let story = message.stories?.first(where: { ($0.id ?? "") == result.storyID }) {
                                    StorySendView(currentTweet: story, leading: !recieved, currentAudio: $currentAudio, text: result.text, emoji: result.emoji, reaction: message.emoji, isExpanded: $isExpanded, animation: animation, addPadding: $addPadding, parentID: message.id ?? UUID().uuidString)
                                } else {
                                    StoryErrorView()
                                        .onAppear {
                                            updateStory(storyID: result.storyID)
                                        }
                                }
                                if recieved {
                                    Spacer()
                                }
                            } else {
                                if !recieved {
                                    Spacer()
                                    if let emoji = message.emoji, !emoji.isEmpty {
                                        emojiChatView(emoji: emoji)
                                    }
                                } else if showTime {
                                    Text("\(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 5)
                                }
                                if text.containsOnlyEmoji && text.count < 20 {
                                    Text(text)
                                        .font(.system(size: 48))
                                        .multilineTextAlignment(recieved ? .leading : .trailing)
                                        .onTapGesture {
                                            showTime.toggle()
                                        }
                                } else {
                                    LinkedText(text, tip: false, isMess: true)
                                        .padding(.horizontal)
                                        .padding(.vertical, 7)
                                        .background(recieved ? Color(UIColor.gray).gradient.opacity(0.6) : Color(UIColor.orange).gradient.opacity(colorScheme == .dark ? 0.3 : 0.7))
                                        .cornerRadius(18, corners: (topCorner && bottomCorner) ? [recieved ? [.topRight, .bottomRight] : [.topLeft, .bottomLeft]] : topCorner ? [recieved ? [.topRight, .bottomLeft, .bottomRight] : [.topLeft, .bottomLeft, .bottomRight]] : bottomCorner ? [recieved ? [.bottomRight, .topLeft, .topRight] : [.bottomLeft, .topLeft, .topRight]] : [.allCorners])
                                        .cornerRadius(5, corners: (topCorner && bottomCorner) ? [recieved ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight]] : topCorner ? [recieved ? .topLeft : .topRight] : bottomCorner ? [recieved ? .bottomLeft : .bottomRight] : [])
                                        .disabled(true)
                                        .onTapGesture {
                                            showTime.toggle()
                                        }
                                }
                                if recieved {
                                    if let emoji = message.emoji, !emoji.isEmpty {
                                        emojiChatView(emoji: emoji)
                                    }
                                    Spacer()
                                } else if showTime {
                                    VStack(spacing: 5) {
                                        Text("\(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 5)
                                    }
                                }
                            }
                        }
                        .brightness(glow2)
                        if let url = checkForFirstUrl(text: text){
                            HStack {
                                if !recieved {
                                    Spacer()
                                }
                                MainPreviewLink(url: url, message: true)
                                if recieved {
                                    Spacer()
                                }
                            }.onTapGesture(perform: {})
                        }
                    }
                    if let url = URL(string: message.file ?? "") {
                        HStack {
                            if !recieved {
                                Spacer()
                            }
                            MainPreviewLink(url: url, message: false)
                                .overlay(alignment: .topTrailing) {
                                    if let emoji = message.emoji, !emoji.isEmpty && location == 3 {
                                        emojiChatViewSec(emoji: emoji).padding(10)
                                    }
                                }
                            if recieved {
                                Spacer()
                            }
                        }.onTapGesture(perform: {})
                    } else if message.async != nil {
                        HStack {
                            if !recieved {
                                Spacer()
                            }
                            ZStack {
                                ProgressView()
                                    .padding(.horizontal)
                                    .padding(.vertical, 7)
                                    .background(Color(UIColor.orange).gradient.opacity(colorScheme == .dark ? 0.3 : 0.7))
                                    .cornerRadius(18, corners: (topCorner && bottomCorner) ? [recieved ? [.topRight, .bottomRight] : [.topLeft, .bottomLeft]] : topCorner ? [recieved ? [.topRight, .bottomLeft, .bottomRight] : [.topLeft, .bottomLeft, .bottomRight]] : bottomCorner ? [recieved ? [.bottomRight, .topLeft, .topRight] : [.bottomLeft, .topLeft, .topRight]] : [.allCorners])
                                    .cornerRadius(5, corners: (topCorner && bottomCorner) ? [recieved ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight]] : topCorner ? [recieved ? .topLeft : .topRight] : bottomCorner ? [recieved ? .bottomLeft : .bottomRight] : [])
                                
                                if let index = imageModel.currentChat, let file = imageModel.chats[index].messages?.first(where: { $0.id == message.id })?.file, let url = URL(string: file) {
                                    MainPreviewLink(url: url, message: true)
                                        .overlay(alignment: .topTrailing) {
                                            if let emoji = message.emoji, !emoji.isEmpty && location == 3 {
                                                emojiChatViewSec(emoji: emoji).padding(10)
                                            }
                                        }
                                }
                            }
                            if recieved {
                                Spacer()
                            }
                        }.onTapGesture(perform: {})
                    }
                }.frame(maxWidth: widthOrHeight(width: true) * 0.85, alignment: recieved ? .leading : .trailing)
            }
            .brightness(glow)
            .frame(maxWidth: .infinity, alignment: recieved ? .leading : .trailing)
            .padding(recieved ? .leading : .trailing)
            .padding(.vertical, (message.elo != nil || message.imageUrl != nil || getImage(forStringId: message.id ?? "") != nil) ? 3.5 : 0)
            .overlay {
                HStack {
                    Image(systemName: "arrowshape.turn.up.backward.fill")
                        .foregroundStyle(.gray).font(.title).offset(x: -gestureOffset)
                        .opacity(opacity).scaleEffect(size)
                    Spacer()
                }.padding(.trailing)
            }
            .offset(x: gestureOffset)
            .scaleEffect(isPressingDown ? 1.2 : 1.0, anchor: recieved ? .leading : .trailing)
            .padding(.vertical, isPressingDown ? 8 : 0)
            .scaleEffect(isNotifying ? 1.6 : 1.0, anchor: recieved ? .leading : .trailing)
            .padding(.vertical, isNotifying ? 20 : 0)
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
            .onAppear {                
                getCorners()
                getPosition()
            }
            .onChange(of: imageModel.chats) { _, _ in
                getCorners()
            }
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
                                
                                if message.text != nil && !recieved {
                                    Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                    HStack(spacing: 14){
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showSheet = false
                                            runEdit()
                                        } label: {
                                            Image(systemName: "pencil")
                                            Text("Edit Message").padding(.leading, 4)
                                        }.foregroundStyle(.blue)
                                        Spacer()
                                    }.opacity(0.9).fontWeight(.semibold).font(.headline)
                                }
                                
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
                                if let image = message.imageUrl ?? imageModel.replyImages.first(where: { $0.0 == message.id })?.1 {
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
                                
                                if !recieved {
                                    Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                    HStack(spacing: 14){
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showSheet = false
                                            imageModel.deleteMessageID(id: message.id)
                                        } label: {
                                            Image(systemName: "trash.fill")
                                            Text("Delete Message").padding(.leading, 4)
                                        }.foregroundStyle(.red)
                                        Spacer()
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
            if let text = message.text {
                if let coordinates = extractCoordinates(from: text), message.lat == nil {
                    HStack {
                        if !recieved {
                            Spacer()
                        }
                        MessageMapView(leading: !recieved, long: coordinates.long, lat: coordinates.lat, name: coordinates.name)
                            .frame(maxWidth: widthOrHeight(width: true) * 0.75)
                            .overlay(alignment: recieved ? .topLeading : .topTrailing){
                                if let emoji = message.emoji, !emoji.isEmpty && location == 6 {
                                    emojiChatViewSec(emoji: emoji).padding(10)
                                }
                            }
                        if recieved {
                            Spacer()
                        }
                    }
                    .padding(recieved ? .leading : .trailing)
                }
                let allStocks = extractWordsStartingWithDollar(input: text)
                if !allStocks.isEmpty {
                    HStack {
                        if !recieved {
                            Spacer()
                        }
                        cards(cards: allStocks, left: recieved)
                        if recieved {
                            Spacer()
                        }
                    }
                    .frame(maxWidth: widthOrHeight(width: true) * 0.8)
                    .padding(recieved ? .leading : .trailing)
                }
                let all = checkForPostUrls(text: text)
                if !all.isEmpty {
                    HStack {
                        if !recieved {
                            Spacer()
                        }
                        ForEach(all, id: \.self) { element in
                            if element.contains("post") {
                                PostPartView(fullURL: element, leading: !recieved, currentAudio: $currentAudio)
                            } else if element.contains("profile") {
                                ProfilePartView(fullURL: element)
                            } else if element.contains("story") {
                                let result = extractTextEmojiFromStoryURL(urlStr: element)
                                if result == nil || (result?.emoji == nil && result?.text == nil) {
                                    let sid = extractStoryID(from: element)
                                    if let story = message.stories?.first(where: { ($0.id ?? "NA") == (sid ?? "") }) {
                                        StorySendView(currentTweet: story, leading: !recieved, currentAudio: $currentAudio, text: nil, emoji: nil, reaction: nil, isExpanded: $isExpanded, animation: animation, addPadding: $addPadding, parentID: message.id ?? UUID().uuidString)
                                    } else {
                                        StoryErrorView()
                                            .onAppear {
                                                if let tempId = sid {
                                                    updateStory(storyID: tempId)
                                                }
                                            }
                                    }
                                }
                            } else if element.contains("news") {
                                let current: News? = explore.news.first(where: { $0.id == (extractNewsVariable(from: element) ?? "NA") })
                                NewsSendView(fullURL: element, leading: !recieved, currentNews: current, isGroup: false)
                            } else if element.contains("memory") {
                                ChatMemoryView(url: element, leading: !recieved)
                            }
                        }
                        if recieved {
                            Spacer()
                        }
                    }.padding(recieved ? .leading : .trailing)
                }
            }
        }
        .onChange(of: imageModel.scrollToReply, { _, new in
            if new == (message.id ?? "Not Equal") {
                imageModel.scrollToReply = ""
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
        .onChange(of: imageModel.scrollToReplyNow, { _, new in
            if new == (message.id ?? "Not Equal") {
                imageModel.scrollToReplyNow = ""
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
        .onChange(of: imageModel.editedMessageID, { _, new in
            if new == (message.id ?? "Not Equal") {
                withAnimation(.easeInOut(duration: 0.1)) {
                    message.text = imageModel.editedMessage
                }
                imageModel.editedMessage = ""
                imageModel.editedMessageID = ""
                withAnimation {
                    glow = 0.4
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        glow = 0.0
                    }
                }
            }
        })
        .background {
            if let index = imageModel.currentChat {
                Color.clear.frame(width: 1, height: 1)
                    .onChange(of: imageModel.chats[index].lastN) { _, new in
                        if new == message.id {
                            runNotify()
                        }
                    }
            }
        }
    }
    func updateStory(storyID: String) {
        if !(message.gotStories ?? []).contains(storyID) {
            if message.gotStories == nil {
                message.gotStories = [storyID]
            } else {
                message.gotStories?.append(storyID)
            }
            if let index = imageModel.currentChat {
                if let pos = imageModel.chats[index].messages?.firstIndex(where: { $0.id == message.id }) {
                    if imageModel.chats[index].messages?[pos].gotStories == nil {
                        imageModel.chats[index].messages?[pos].gotStories = [storyID]
                    } else {
                        imageModel.chats[index].messages?[pos].gotStories?.append(storyID)
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
                    if let index = imageModel.currentChat {
                        if let pos = imageModel.chats[index].messages?.firstIndex(where: { $0.id == message.id }) {
                            
                            if imageModel.chats[index].messages?[pos].stories == nil {
                                imageModel.chats[index].messages?[pos].stories = [newstory]
                            } else {
                                imageModel.chats[index].messages?[pos].stories?.append(newstory)
                            }
                        }
                    }
                }
            }
        }
    }
    func runNotify(){
        withAnimation(.easeIn(duration: 0.35)){
            isNotifying = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4){
            if isNotifying {
                withAnimation {
                    isNotifying = false
                }
            }
        }
    }
    func getInfo() -> (String, String, CLLocationCoordinate2D?) {
        var name = ""
        var image = ""
        var coord: CLLocationCoordinate2D? = nil
                
        if recieved {
            if let index = imageModel.currentChat {
                name = "@\(imageModel.chats[index].user.username)"
                image = imageModel.chats[index].user.profileImageUrl ?? ""
                if let first = imageModel.chats[index].user.fullname.first, image.isEmpty {
                    image = String(first)
                }
            }
        } else {
            if let user = auth.currentUser {
                name = "@\(user.username)"
                image = user.profileImageUrl ?? ""
                if let first = user.fullname.first, image.isEmpty {
                    image = String(first)
                }
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
                
        if auth.currentUser?.username != message.replyFrom {
            if let index = imageModel.currentChat {
                name = "@\(imageModel.chats[index].user.username)"
                image = imageModel.chats[index].user.profileImageUrl ?? ""
                if let first = imageModel.chats[index].user.fullname.first, image.isEmpty {
                    image = String(first)
                }
            }
        } else {
            if let user = auth.currentUser {
                name = "@\(user.username)"
                image = user.profileImageUrl ?? ""
                if let first = user.fullname.first, image.isEmpty {
                    image = String(first)
                }
            }
        }
        if let loc = globe.currentLocation {
            coord = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.long)
        } else if let locstr = auth.currentUser?.currentLocation, let loc = extractLatLong(from: locstr) {
            coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        }
        
        return (name, image, coord)
    }
    func messageRepView(from: String, text: String?, image: String?, elo: String?, file: String?) -> some View {
        HStack(alignment: .bottom, spacing: 5){
            if recieved {
                Text(from).font(.subheadline).bold().foregroundStyle(.purple)
            }
            if let chatStr = text, !chatStr.isEmpty {
                if let place = extractCoordinates(from: chatStr) {
                    HStack(spacing: 6){
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if let index = imageModel.currentChat {
                                if let id = imageModel.chats[index].messages?.first(where: { $0.lat == place.lat && $0.long == place.long })?.id {
                                    imageModel.scrollToReply = id
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
                    }
                    .padding(8)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.gray, lineWidth: 1.0)
                    }
                    .overlay(alignment: recieved ? .trailing : .leading){
                        Text("Map").font(.caption).foregroundStyle(.gray).offset(x: recieved ? 30 : -30)
                    }
                } else if extractLatLongName(from: chatStr) != nil {
                    let info = getInfoReply()
                    PinChatRowView(pinStr: chatStr, personName: info.0, personImage: info.1, timestamp: message.timestamp, currentLoc: info.2, isChat: true) {
                        imageModel.GoToPin = chatStr
                        withAnimation(.easeIn(duration: 0.15)){
                            viewOption = false
                        }
                    }
                } else {
                    Text(chatStr)
                        .font(.caption)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(from != auth.currentUser?.username ? Color(UIColor.gray).gradient.opacity(0.6) : Color(UIColor.orange).gradient.opacity(colorScheme == .dark ? 0.3 : 0.7))
                        .cornerRadius(25, corners: .allCorners)
                }
            } else if let photo = image ?? imageModel.replyImages.first(where: { $0.0 == message.id })?.1 {
                KFImage(URL(string: photo))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .contentShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(content: {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.6), lineWidth: 1.0)
                    })
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        popRoot.image = photo
                        popRoot.showImage = true
                    }
            } else if let video = message.replyVideo, let url = URL(string: video) {
                smallDisabledVideo(url: url)
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.white)
                            .font(.headline)
                            .padding(10)
                            .background(.gray)
                            .clipShape(Circle())
                    }
            } else if let audio = message.replyAudio, let url = URL(string: audio) {
                MessageVoiceStreamView(audioUrl: url, messageID: message.id ?? "", isGroup: false, currentAudio: $currentAudio)
            } else if let eloStr = elo {
                SendEloBubbleSec(amount: eloStr)
            } else if let fileURL = file, let f_url = URL(string: fileURL) {
                MainGroupLink(url: f_url)
            } else if let type = imageModel.fileMessages.first(where: { $0.0 == message.id })?.1 {
                VStack(alignment: .leading){
                    Text("File attached").font(.system(size: 18))
                        .bold().foregroundStyle(colorScheme == .dark ? .white : .black)
                    Text("Type: \(type)").font(.system(size: 15))
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal, 9).frame(height: 65)
                .background(.ultraThinMaterial).cornerRadius(20, corners: .allCorners)
            }
            
            if !recieved {
                Text(from).font(.subheadline).bold().foregroundStyle(.purple)
            }
        }
    }
    func getPosition(){
        let m = message
        if !(m.text ?? "").isEmpty {
            location = 0
        } else if !(m.imageUrl ?? "").isEmpty || getImage(forStringId: message.id ?? "") != nil {
            location = 1
        } else if !(m.elo ?? "").isEmpty {
            location = 2
        } else if !(m.file ?? "").isEmpty || message.async != nil {
            location = 3
        } else if m.videoURL != nil {
            location = 4
        } else if m.audioURL != nil || imageModel.audioMessages.first(where: { $0.0 == message.id }) != nil {
            location = 5
        } else if m.lat != nil && m.long != nil {
            location = 6
        }
    }
    func runReply(){
        showSheet = false
        withAnimation(.easeIn(duration: 0.1)){
            searching = false
            editing = nil
            replying = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            withAnimation(.easeIn(duration: 0.1)){
                replying = replyTo(messageID: message.id ?? "", selfReply: !recieved)
            }
        }
    }
    func runEdit(){
        if let id = message.id, let text = message.text {
            showSheet = false
            withAnimation(.easeIn(duration: 0.1)){
                editing = nil
                replying = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                withAnimation(.easeIn(duration: 0.1)) {
                    editing = Editing(messageID: id, originalText: text)
                }
            }
        }
    }
    func emojiChatView(emoji: String) -> some View {
        HStack(spacing: 3){
            if recieved {
                Circle().foregroundStyle(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray))
                    .frame(width: 10, height: 10)
            }
            if emoji == "questionmark" {
                Image(systemName: "questionmark").font(.headline).padding(8).foregroundStyle(colorScheme == .dark ? .white : .black).background(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray)).clipShape(Circle())
            } else {
                Text(emoji).font(.subheadline).padding(5).background(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray)).clipShape(Circle())
            }
            if !recieved {
                Circle().foregroundStyle(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray))
                    .frame(width: 10, height: 10)
            }
        }.padding(.horizontal, 1)
    }
    func emojiChatViewSec(emoji: String) -> some View {
        HStack {
            if emoji == "questionmark" {
                Image(systemName: "questionmark").font(.headline).padding(12).foregroundStyle(colorScheme == .dark ? .white : .black).background(.ultraThickMaterial).clipShape(Circle())
            } else {
                Text(emoji).font(.subheadline).padding(8).background(.ultraThickMaterial).clipShape(Circle())
            }
        }
    }
    func emojiView(emoji: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.bouncy(duration: 0.5)){
                showSheet = false
            }
            withAnimation(.bouncy) {
                message.emoji = emoji
            }
            imageModel.addReaction(id: message.id ?? "", emoji: emoji)
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
    func getImage(forStringId stringId: String) -> Image? {
        for tuple in imageModel.imageMessages {
            if tuple.1 == stringId {
                return tuple.0
            }
        }
        return nil
    }
    func getCorners(){
        if let index = imageModel.currentChat, let loc = imageModel.chats[index].messages?.firstIndex(where: { $0.id == message.id }), message.replyFrom == nil {
            if loc > 0 {
                if let prev = imageModel.chats[index].messages?[loc - 1] {
                    if recieved {
                        if ((is_uid_one && prev.uid_one_did_recieve) || (!is_uid_one && !prev.uid_one_did_recieve)) && !imageModel.dayArr.contains(where: { $0.0 == (loc - 1) }) {
                            self.bottomCorner = true
                        } else {
                            self.bottomCorner = false
                        }
                    } else {
                        if ((is_uid_one && !prev.uid_one_did_recieve) || (!is_uid_one && prev.uid_one_did_recieve)) && !imageModel.dayArr.contains(where: { $0.0 == (loc - 1) }) {
                            self.bottomCorner = true//here 3
                        } else {
                            self.bottomCorner = false
                        }
                    }
                }
                if (imageModel.chats[index].messages?.count ?? 0) > loc + 1 {
                    if let next = imageModel.chats[index].messages?[loc + 1] {
                        if recieved {
                            if ((is_uid_one && next.uid_one_did_recieve) || (!is_uid_one && !next.uid_one_did_recieve)) && !imageModel.dayArr.contains(where: { $0.0 == (loc) }){
                                self.topCorner = true
                            } else {
                                self.topCorner = false
                            }
                        } else {
                            if ((is_uid_one && !next.uid_one_did_recieve) || (!is_uid_one && next.uid_one_did_recieve)) && !imageModel.dayArr.contains(where: { $0.0 == (loc) }) {
                                self.topCorner = true
                            } else {
                                self.topCorner = false
                            }
                        }
                    }
                }
            } else if (imageModel.chats[index].messages?.count ?? 1) > 1, let mNext = imageModel.chats[index].messages?[1] {
                if recieved {
                    if ((is_uid_one && mNext.uid_one_did_recieve) || (!is_uid_one && !mNext.uid_one_did_recieve)) && !imageModel.dayArr.contains(where: { $0.0 == 0 }){
                        self.topCorner = true
                    } else {
                        self.topCorner = false
                    }
                } else {
                    if ((is_uid_one && !mNext.uid_one_did_recieve) || (!is_uid_one && mNext.uid_one_did_recieve)) && !imageModel.dayArr.contains(where: { $0.0 == 0 }){
                        self.topCorner = true
                    } else {
                        self.topCorner = false
                    }
                }
            }
        }
    }
}

func downloadAndSaveImage(url: String) {
    guard let imageURL = URL(string: url) else { return }
    URLSession.shared.dataTask(with: imageURL) { data, _, error in
        guard let data = data, let image = UIImage(data: data) else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { _, _ in }
            }
        }
    }.resume()
}

func saveUIImage(image: UIImage) {
    PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { _, _ in }
        }
    }
}

func downloadVideoFromURL(_ videoURL: URL) {
    PHPhotoLibrary.requestAuthorization { status in
        guard status == .authorized else {
            return
        }
        guard let videoData = try? Data(contentsOf: videoURL) else {
            return
        }

        PHPhotoLibrary.shared().performChanges {
            let options = PHAssetResourceCreationOptions()
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .video, data: videoData, options: options)
        } completionHandler: { _, _ in }
    }
}

extension String {
    var isSingleEmoji: Bool { count == 1 && containsEmoji }

    var containsEmoji: Bool { contains { $0.isEmoji } }

    var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }

    var emojiString: String { emojis.map { String($0) }.reduce("", +) }

    var emojis: [Character] { filter { $0.isEmoji } }

    var emojiScalars: [UnicodeScalar] { filter { $0.isEmoji }.flatMap { $0.unicodeScalars } }
}

extension Character {
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}
