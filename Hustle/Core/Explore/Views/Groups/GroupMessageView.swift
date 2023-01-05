import SwiftUI
import Kingfisher
import Firebase
import AVFoundation

struct GroupMessageView: View {
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var viewModel: GroupViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var explore: ExploreViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profileModel: ProfileViewModel
    @State var dateFinal: String = ""
    @State var showDelete: Bool = false
    @State var showDeleteSec: Bool = false
    @State var tweet: Tweet
    let isPriv: Bool
    let canDelete: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var showSheet: Bool = false
    @State private var isPressingDown: Bool = false
    @State private var started: Bool = false
    @Binding var replying: replyToGroup?
    @State var size: CGFloat = 0
    @State var opacity: CGFloat = 0
    @State var gestureOffset: CGFloat = 0
    @State private var replyOnRelease: Bool = false
    @State var glow = 0.0
    @State var glow2 = 0.0
    @State private var showForward: Bool = false
    @State private var forwardString = ""
    @State private var forwardDataType: Int = 1
    @Binding var currentAudio: String
    @Binding var editing: Editing?
    
    @Binding var showUser: Bool
    @Binding var selectedUser: User?
    @State var showTranscription: Bool = false
    @State var transcribing: Bool = false
    
    @Binding var isExpanded: Bool
    let animation: Namespace.ID
    let seenAllStories: Bool
    @Binding var addPadding: Bool

    var body: some View {
        ZStack {
            Color.gray.opacity(0.001)
                .onTapGesture { }
            HStack {
                VStack(alignment: .leading){
                    if let from = tweet.replyFrom {
                        HStack(alignment: .bottom, spacing: 5){
                            HStack(alignment: .top, spacing: 0){
                                Rectangle().frame(width: 2).foregroundStyle(.gray)
                                Rectangle().frame(width: 20, height: 2).foregroundStyle(.gray)
                            }.frame(height: 15)
                            
                            messageRepView(from: from, text: tweet.replyText, image: tweet.replyImage)
                                .padding(.bottom, 5)
                            Spacer()
                        }.padding(.leading, 20)
                    }
                    HStack(alignment: .top, spacing: 8) {
                        if hasStories() {
                            ZStack {
                                StoryRingView(size: 43.0, active: seenAllStories, strokeSize: 1.7)
                                    .scaleEffect(1.24)
                                
                                let mid = (tweet.id ?? "") + "UpStory"
                                let size = isExpanded && profileModel.mid == mid ? 200 : 43.0
                                GeometryReader { _ in
                                    ZStack {
                                        if let first = tweet.username.first {
                                            personLetterViewColor(size: size, letter: String(first), color: Color.gray)
                                        } else {
                                            personView(size: 43)
                                        }
                                        if let image = tweet.profilephoto {
                                            KFImage(URL(string: image))
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .scaledToFill()
                                                .clipShape(Circle())
                                                .frame(width: size, height: size)
                                        }
                                    }.opacity(isExpanded && profileModel.mid == mid ? 0.0 : 1.0)
                                }
                                .matchedGeometryEffect(id: mid, in: animation, anchor: .topLeading)
                                .frame(width: 43.0, height: 43.0)
                                .onTapGesture {
                                    addPadding = true
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                            NavigationLink {
                                ProfileView(showSettings: false, showMessaging: true, uid: tweet.uid, photo: tweet.profilephoto ?? "", user: nil, expand: true, isMain: false)
                                    .dynamicTypeSize(.large)
                            } label: {
                                ZStack {
                                    personView(size: 43)
                                    if let image = tweet.profilephoto {
                                        KFImage(URL(string: image))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 43, height: 43)
                                            .clipShape(Circle())
                                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 4){
                            HStack(spacing: 10){
                                NavigationLink {
                                    ProfileView(showSettings: false, showMessaging: true, uid: tweet.uid, photo: tweet.profilephoto ?? "", user: nil, expand: true, isMain: false)
                                        .dynamicTypeSize(.large)
                                } label: {
                                    Text("@\(tweet.username)")
                                        .foregroundColor(.blue).bold()
                                }
                                Text(dateFinal)
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                    .onAppear {
                                        self.dateFinal = getMessageTime(date: tweet.timestamp.dateValue())

                                        if let user = profileModel.users.first(where: { $0.user.id == tweet.uid })?.user {
                                            profileModel.updateStoriesUser(user: user)
                                        } else if (auth.currentUser?.following ?? []).contains(tweet.uid) {
                                            UserService().fetchSafeUser(withUid: tweet.uid) { user in
                                                if let user {
                                                    profileModel.updateStoriesUser(user: user)
                                                }
                                            }
                                        }
                                    }
                            }
                            if !tweet.caption.isEmpty {
                                if tweet.caption.containsOnlyEmoji && tweet.caption.count < 20 {
                                    Text(tweet.caption)
                                        .font(.system(size: 40))
                                        .multilineTextAlignment(.leading)
                                        .background {
                                            RoundedRectangle(cornerRadius: 8)
                                                .foregroundStyle(.yellow).opacity(glow2 == 0 ? 0.0 : 0.2)
                                        }
                                } else if let c1 = tweet.choice1, let c2 = tweet.choice2, let index = viewModel.currentGroup {
                                    
                                    let square: String = isPriv ? viewModel.groups[index].0 : ""
                                    let gid: String = isPriv ? viewModel.groups[index].1.id : viewModel.groupsDev[index].id
                                    
                                    PollRowViewChat(question: tweet.caption, choice1: c1, choice2: c2, choice3: tweet.choice3, choice4: tweet.choice4, count1: tweet.count1 ?? 0, count2: tweet.count2 ?? 0, count3: tweet.count3 ?? 0, count4: tweet.count4 ?? 0, messageID: tweet.id ?? "", groupID: gid, isGC: false, isDevGroup: !isPriv, squareName: square, whoVoted: tweet.voted ?? [], timestamp: tweet.timestamp, showUser: $showUser, selectedUser: $selectedUser)
                                        .padding(.top, 5)
                                } else {
                                    if isPriv {
                                        if let index = viewModel.currentGroup {
                                            let all = viewModel.groups[index].1.squares ?? []
                                            
                                            let newA = all.filter { element in
                                                return !element.hasPrefix(":")
                                            }
                                            
                                            let more = viewModel.subContainers.first(where: { $0.0 == viewModel.groups[index].1.id })?.1 ?? []
                                            
                                            let final = newA + more.flatMap({ $0.sub })
                                            
                                            LinkedTextG(tweet.caption, allP: ["Info/Description", "Main", "Rules"] + final)
                                                .background {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .foregroundStyle(.yellow).opacity(glow2 == 0 ? 0.0 : 0.2)
                                                }
                                        } else {
                                            LinkedTextG(tweet.caption, allP: ["Info/Description", "Main", "Rules"])
                                        }
                                    } else {
                                        LinkedText(tweet.caption, tip: false, isMess: nil)
                                            .font(.subheadline).multilineTextAlignment(.leading)
                                            .disabled(true)
                                    }
                                }
                            }
                            if let tweetImage = tweet.image, !tweetImage.isEmpty {
                                HStack(spacing: 15){
                                    KFImage(URL(string: tweetImage))
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
                                            if !popRoot.displayingGroup {
                                                popRoot.image = tweetImage
                                                popRoot.showImage = true
                                            }
                                        }
                                    if !canDelete {
                                        SaveImageButton(url: tweetImage, video: false)
                                    }
                                    Spacer()
                                }.padding(.trailing, 5).padding(.vertical, 3)
                            } else if let image = viewModel.imageMessages.first(where: { $0.0 == tweet.id })?.1 {
                                HStack {
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
                                            if !popRoot.displayingGroup {
                                                popRoot.realImage = image
                                                popRoot.showImageMessage = true
                                            }
                                        }
                                    Spacer()
                                }.padding(.trailing, 5).padding(.vertical, 3)
                            } else if let vid = tweet.videoURL, let vid_url = URL(string: vid) {
                                HStack(spacing: 15){
                                    MessageVideoPlayer(url: vid_url, width: 240.0, height: 350.0, cornerRadius: 16.0, viewID: tweet.id, currentAudio: $currentAudio)
                                    if !canDelete {
                                        SaveImageButton(url: vid, video: true)
                                    }
                                    Spacer()
                                }.padding(.trailing, 5).padding(.vertical, 3)
                            } else if let audio = tweet.audioURL, let audio_url = URL(string: audio) {
                                VStack(alignment: .leading, spacing: 5){
                                    HStack {
                                        MessageVoiceStreamView(audioUrl: audio_url, messageID: tweet.id ?? "", isGroup: true, currentAudio: $currentAudio)
                                        Spacer()
                                    }
                                    HStack {
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
                                                        if let audio_str = tweet.audioURL, let url = popRoot.audioFiles.first(where: { $0.0 == audio_str })?.1 {
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
                                                        } else if let audio_str = tweet.audioURL {
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
                                            if let extracted = popRoot.transcriptions.first(where: { $0.0 == tweet.audioURL })?.1, showTranscription {
                                                Text(extracted)
                                                    .font(.body).multilineTextAlignment(.leading)
                                                    .transition(.scale.combined(with: .identity))
                                            }
                                        }
                                        .padding(10)
                                        .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.4))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .frame(maxWidth: widthOrHeight(width: true) * 0.75, alignment: .leading)
                                        Spacer()
                                    }
                                }.padding(.trailing, 5).padding(.vertical, 3)
                            } else if let audio = viewModel.audioMessages.first(where: { $0.0 == tweet.id })?.1 {
                                HStack {
                                    MessageVoiceStreamViewThird(audioUrl: audio, messageID: tweet.id ?? "", isGroup: true, currentAudio: $currentAudio)
                                    Spacer()
                                }
                            } else if let file = tweet.fileURL, let file_url = URL(string: file) {
                                HStack {
                                    MainPreviewLink(url: file_url, message: false)
                                    Spacer()
                                }.padding(.trailing, 5).padding(.vertical, 3)
                            } else if tweet.async != nil {
                                HStack {
                                    ZStack {
                                        ProgressView()
                                        if let index = viewModel.currentGroup, let squarePos = viewModel.groups[index].1.messages?.firstIndex(where: { $0.id == viewModel.groups[index].0 }), let file = viewModel.groups[index].1.messages?[squarePos].messages.first(where: { $0.id == tweet.id })?.fileURL, let url = URL(string: file) {
                                            MainPreviewLink(url: url, message: true)
                                        }
                                    }
                                    Spacer()
                                }.padding(.trailing, 5).padding(.vertical, 3)
                            }
                  
                            let allStocks = extractWordsStartingWithDollar(input: tweet.caption)
                            if !allStocks.isEmpty {
                                HStack {
                                    cards(cards: allStocks, left: true)
                                    Spacer()
                                }
                            }
                            
                            let all = checkForPostUrls(text: tweet.caption)
                            if !all.isEmpty {
                                HStack {
                                    ForEach(all, id: \.self) { element in
                                        if element.contains("post") {
                                            PostPartView(fullURL: element, leading: false, currentAudio: $currentAudio)
                                        } else if element.contains("profile") {
                                            ProfilePartView(fullURL: element)
                                        } else if element.contains("story"), let sid = extractStoryID(from: element) {
                                            if let story = tweet.stories?.first(where: { $0.id == sid }) {
                                                StorySendView(currentTweet: story, leading: false, currentAudio: $currentAudio, text: nil, emoji: nil, reaction: nil, isExpanded: $isExpanded, animation: animation, addPadding: $addPadding, parentID: tweet.id ?? UUID().uuidString)
                                            } else {
                                                StoryErrorView()
                                                    .onAppear {
                                                        updateStory(storyID: sid)
                                                    }
                                            }
                                        } else if element.contains("news") {
                                            let current: News? = explore.news.first(where: { $0.id == (extractNewsVariable(from: element) ?? "NA") })
                                            NewsSendView(fullURL: element, leading: false, currentNews: current, isGroup: true)
                                        } else if element.contains("memory") {
                                            ChatMemoryView(url: element, leading: false)
                                        } else if element.contains("yelp") {
                                            YelpRowView(placeID: element, isChat: false, isGroup: false, otherPhoto: nil)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            
                            if isPriv && !tweet.caption.isEmpty {
                                if let url = checkForFirstUrl(text: tweet.caption){
                                    MainPreviewLink(url: url, message: false).padding(.top, 3)
                                }
                            }
                            if (tweet.countSmile != nil) || (tweet.countCry != nil) || (tweet.countThumb != nil) || (tweet.countBless != nil) || (tweet.countHeart != nil) || (tweet.countQuestion != nil) {
                                HStack(spacing: 3){
                                    if let count = tweet.countSmile {
                                        Button {
                                            if !viewModel.reactionAdded.contains(where: { $0.0 == (tweet.id ?? "") && $0.1 == "countSmile" }) {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                viewModel.addReaction(id: tweet.id ?? "", emoji: "countSmile", devGroup: !isPriv)
                                            }
                                        } label: {
                                            emojiChatView(emoji: "countSmile", count: count)
                                        }
                                    }
                                    if let count = tweet.countCry {
                                        Button {
                                            if !viewModel.reactionAdded.contains(where: { $0.0 == (tweet.id ?? "") && $0.1 == "countCry" }) {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                viewModel.addReaction(id: tweet.id ?? "", emoji: "countCry", devGroup: !isPriv)
                                            }
                                        } label: {
                                            emojiChatView(emoji: "countCry", count: count)
                                        }
                                    }
                                    if let count = tweet.countThumb {
                                        Button {
                                            if !viewModel.reactionAdded.contains(where: { $0.0 == (tweet.id ?? "") && $0.1 == "countThumb" }) {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                viewModel.addReaction(id: tweet.id ?? "", emoji: "countThumb", devGroup: !isPriv)
                                            }
                                        } label: {
                                            emojiChatView(emoji: "countThumb", count: count)
                                        }
                                    }
                                    if let count = tweet.countBless {
                                        Button {
                                            if !viewModel.reactionAdded.contains(where: { $0.0 == (tweet.id ?? "") && $0.1 == "countBless" }) {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                viewModel.addReaction(id: tweet.id ?? "", emoji: "countBless", devGroup: !isPriv)
                                            }
                                        } label: {
                                            emojiChatView(emoji: "countBless", count: count)
                                        }
                                    }
                                    if let count = tweet.countHeart {
                                        Button {
                                            if !viewModel.reactionAdded.contains(where: { $0.0 == (tweet.id ?? "") && $0.1 == "countHeart" }) {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                viewModel.addReaction(id: tweet.id ?? "", emoji: "countHeart", devGroup: !isPriv)
                                            }
                                        } label: {
                                            emojiChatView(emoji: "countHeart", count: count)
                                        }
                                    }
                                    if let count = tweet.countQuestion {
                                        Button {
                                            if !viewModel.reactionAdded.contains(where: { $0.0 == (tweet.id ?? "") && $0.1 == "countQuestion" }) {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                viewModel.addReaction(id: tweet.id ?? "", emoji: "countQuestion", devGroup: !isPriv)
                                            }
                                        } label: {
                                            emojiChatView(emoji: "countQuestion", count: count)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }.padding(.horizontal)
                Spacer()
            }
            HStack {
                Image(systemName: "arrowshape.turn.up.backward.fill")
                    .foregroundStyle(.gray).font(.title).offset(x: -gestureOffset)
                    .opacity(opacity).scaleEffect(size)
                Spacer()
            }.padding(.trailing)
        }
        .brightness(glow) .brightness(glow2)
        .offset(x: gestureOffset)
        .onTapGesture { }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
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
        .sheet(isPresented: $showForward, content: {
            ForwardContentView(sendLink: $forwardString, whichData: $forwardDataType)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
                .onDisappear {
                    showForward = false
                }
        })
        .onChange(of: viewModel.scrollToReply, { _, new in
            if new == (tweet.id ?? "Not Equal") {
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
            if new == (tweet.id ?? "Not Equal") {
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
        .onChange(of: viewModel.editedMessageID, { _, new in
            if new == (tweet.id ?? "Not Equal") {
                withAnimation(.easeInOut(duration: 0.1)) {
                    tweet.caption = viewModel.editedMessage
                }
                viewModel.editedMessage = ""
                viewModel.editedMessageID = ""
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
        .sheet(isPresented: $showSheet) {
            ScrollView {
                VStack(spacing: 18){
                    HStack {
                        emojiView(emoji: "countSmile")
                        Spacer()
                        emojiView(emoji: "countCry")
                        Spacer()
                        emojiView(emoji: "countThumb")
                        Spacer()
                        emojiView(emoji: "countBless")
                        Spacer()
                        emojiView(emoji: "countHeart")
                        Spacer()
                        emojiView(emoji: "countQuestion")
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
                            
                            if !tweet.caption.isEmpty && canDelete {
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
                            
                            if !tweet.caption.isEmpty {
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        UIPasteboard.general.string = tweet.caption
                                    } label: {
                                        Image(systemName: "doc.on.doc.fill")
                                        Text("Copy Text").padding(.leading, 4)
                                        Spacer()
                                    }
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                            }
                            if let image = tweet.image {
                                if let id = tweet.id, !popRoot.savedMemories.contains(id) {
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
                            if let video = tweet.videoURL {
                                if let id = tweet.id, let url = URL(string: video), !popRoot.savedMemories.contains(id) {
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
                            if let audio = tweet.audioURL {
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
                            if let file = tweet.fileURL {
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
                            
                            if canDelete || ((auth.currentUser?.dev?.contains("(DWK@)2))&DNWIDN:")) != nil) {
                                Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                HStack(spacing: 14){
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showSheet = false
                                        viewModel.deleteMessage(messageId: tweet.id ?? "", image: tweet.image, privateG: isPriv)
                                        if let url = tweet.audioURL {
                                            if containsFirebasePrefix(url) {
                                                ImageUploader.deleteImage(fileLocation: url) { _ in }
                                            } else if isPriv {
                                                if let index = viewModel.currentGroup, index < viewModel.groupsDev.count {
                                                    if let url = viewModel.groupsDev[index].messages?.first(where: { $0.id == tweet.id })?.audioURL, containsFirebasePrefix(url) {
                                                        ImageUploader.deleteImage(fileLocation: url) { _ in }
                                                    }
                                                }
                                            } else if let index = viewModel.currentGroup, index < viewModel.groups.count {
                                                if let idx2 = viewModel.groups[index].1.messages?.firstIndex(where: { $0.id == viewModel.groups[index].0 }) {
                                                    if let url = viewModel.groups[index].1.messages?[idx2].messages.first(where: { $0.id == tweet.id })?.audioURL, containsFirebasePrefix(url) {
                                                        ImageUploader.deleteImage(fileLocation: url) { _ in }
                                                    }
                                                }
                                            }
                                        }
                                        if let url = tweet.videoURL {
                                            if containsFirebasePrefix(url) {
                                                print("deleting1 : \(url)")
                                                ImageUploader.deleteImage(fileLocation: url) { _ in }
                                            } else if isPriv {
                                                if let index = viewModel.currentGroup, index < viewModel.groupsDev.count {
                                                    if let url = viewModel.groupsDev[index].messages?.first(where: { $0.id == tweet.id })?.videoURL, containsFirebasePrefix(url) {
                                                        print("deleting2 : \(url)")
                                                        ImageUploader.deleteImage(fileLocation: url) { _ in }
                                                    }
                                                }
                                            } else if let index = viewModel.currentGroup, index < viewModel.groups.count {
                                                if let idx2 = viewModel.groups[index].1.messages?.firstIndex(where: { $0.id == viewModel.groups[index].0 }) {
                                                    if let url = viewModel.groups[index].1.messages?[idx2].messages.first(where: { $0.id == tweet.id })?.videoURL, containsFirebasePrefix(url) {
                                                        print("deleting3 : \(url)")
                                                        ImageUploader.deleteImage(fileLocation: url) { _ in }
                                                    }
                                                }
                                            }
                                        }
                                        if let url = tweet.fileURL {
                                            if containsFirebasePrefix(url) {
                                                ImageUploader.deleteImage(fileLocation: url) { _ in }
                                            } else if isPriv {
                                                if let index = viewModel.currentGroup, index < viewModel.groupsDev.count {
                                                    if let url = viewModel.groupsDev[index].messages?.first(where: { $0.id == tweet.id })?.fileURL, containsFirebasePrefix(url) {
                                                        ImageUploader.deleteImage(fileLocation: url) { _ in }
                                                    }
                                                }
                                            } else if let index = viewModel.currentGroup, index < viewModel.groups.count {
                                                if let idx2 = viewModel.groups[index].1.messages?.firstIndex(where: { $0.id == viewModel.groups[index].0 }) {
                                                    if let url = viewModel.groups[index].1.messages?[idx2].messages.first(where: { $0.id == tweet.id })?.fileURL, containsFirebasePrefix(url) {
                                                        ImageUploader.deleteImage(fileLocation: url) { _ in }
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "trash.fill")
                                        Text("Delete Message").padding(.leading, 4)
                                    }.foregroundStyle(.red)
                                    Spacer()
                                }.opacity(0.9).fontWeight(.semibold).font(.headline)
                            }
                            
                            if let all = getAllUrl(text: tweet.caption) {
                                if !all.isEmpty {
                                    Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray)
                                    ForEach(0..<all.count, id: \.self) { i in
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            withAnimation(.bouncy(duration: 0.5)){
                                                showSheet = false
                                            }
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
        if !(tweet.gotStories ?? []).contains(storyID) {
            if tweet.gotStories == nil {
                tweet.gotStories = [storyID]
            } else {
                tweet.gotStories?.append(storyID)
            }
            if isPriv {
                if let index = viewModel.currentGroup, index < viewModel.groupsDev.count {
                    if let pos = viewModel.groupsDev[index].messages?.firstIndex(where: { $0.id == tweet.id }) {
                        if viewModel.groupsDev[index].messages?[pos].gotStories == nil {
                            viewModel.groupsDev[index].messages?[pos].gotStories = [storyID]
                        } else {
                            viewModel.groupsDev[index].messages?[pos].gotStories?.append(storyID)
                        }
                    }
                }
            } else if let index = viewModel.currentGroup, index < viewModel.groups.count {
                if let idx2 = viewModel.groups[index].1.messages?.firstIndex(where: { $0.id == viewModel.groups[index].0 }) {
                    if let pos = viewModel.groups[index].1.messages?[idx2].messages.firstIndex(where: { $0.id == tweet.id }) {
                        if viewModel.groups[index].1.messages?[idx2].messages[pos].gotStories == nil {
                            viewModel.groups[index].1.messages?[idx2].messages[pos].gotStories = [storyID]
                        } else {
                            viewModel.groups[index].1.messages?[idx2].messages[pos].gotStories?.append(storyID)
                        }
                    }
                }
            }
            GlobeService().getSingleStory(id: storyID) { story in
                if let newstory = story {
                    if tweet.stories == nil {
                        tweet.stories = [newstory]
                    } else {
                        tweet.stories?.append(newstory)
                    }
                    if isPriv {
                        if let index = viewModel.currentGroup, index < viewModel.groupsDev.count {
                            if let pos = viewModel.groupsDev[index].messages?.firstIndex(where: { $0.id == tweet.id }) {
                                if viewModel.groupsDev[index].messages?[pos].stories == nil {
                                    viewModel.groupsDev[index].messages?[pos].stories = [newstory]
                                } else {
                                    viewModel.groupsDev[index].messages?[pos].stories?.append(newstory)
                                }
                            }
                        }
                    } else if let index = viewModel.currentGroup, index < viewModel.groups.count {
                        if let idx2 = viewModel.groups[index].1.messages?.firstIndex(where: { $0.id == viewModel.groups[index].0 }) {
                            if let pos = viewModel.groups[index].1.messages?[idx2].messages.firstIndex(where: { $0.id == tweet.id }) {
                                if viewModel.groups[index].1.messages?[idx2].messages[pos].stories == nil {
                                    viewModel.groups[index].1.messages?[idx2].messages[pos].stories = [newstory]
                                } else {
                                    viewModel.groups[index].1.messages?[idx2].messages[pos].stories?.append(newstory)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    func hasStories() -> Bool {
        return !(profileModel.users.first(where: { $0.user.id == tweet.uid })?.stories ?? []).isEmpty
    }
    func setupStory() {
        if let stories = profileModel.users.first(where: { $0.user.id == tweet.uid })?.stories {
            profileModel.selectedStories = stories
        }
    }
    func runReply(){
        showSheet = false
        replying = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            withAnimation(.easeInOut(duration: 0.1)){
                replying = replyToGroup(messageID: tweet.id ?? "", selfReply: auth.currentUser?.id == tweet.uid, username: tweet.username)
            }
        }
    }
    func runEdit(){
        if let id = tweet.id {
            showSheet = false
            withAnimation(.easeIn(duration: 0.1)){
                editing = nil
                replying = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                withAnimation(.easeIn(duration: 0.1)) {
                    editing = Editing(messageID: id, originalText: tweet.caption)
                }
            }
        }
    }
    func messageRepView(from: String, text: String?, image: String?) -> some View {
        HStack(alignment: .bottom, spacing: 5){
            Text(from).font(.subheadline).bold()
                .foregroundStyle(.purple)
            if let chatStr = text, !chatStr.isEmpty {
                Text(chatStr).font(.caption).padding(.bottom, 2).lineLimit(1)
            } else if let photo = image {
                KFImage(URL(string: photo))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .contentShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(content: {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.6), lineWidth: 1.0)
                    })
                    .onTapGesture {
                        popRoot.image = photo
                        popRoot.showImage = true
                    }
            } else if let file = tweet.replyFile, let url = URL(string: file) {
                MainGroupLink(url: url)
            } else if let video = tweet.replyVideo, let url = URL(string: video) {
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
            } else if let audio = tweet.replyAudio, let url = URL(string: audio) {
                MessageVoiceStreamView(audioUrl: url, messageID: tweet.id ?? "", isGroup: true, currentAudio: $currentAudio)
            }
        }
    }
    func emojiChatView(emoji: String, count: Int) -> some View {
        HStack(spacing: 6) {
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
        .padding(.horizontal, 4).frame(height: 35)
        .background(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.2))
        .cornerRadius(8, corners: .allCorners)
        .overlay {
            RoundedRectangle(cornerRadius: 8).stroke(.blue, lineWidth: 1)
        }
    }
    func emojiView(emoji: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.bouncy(duration: 0.5)){
                showSheet = false
            }
            if !viewModel.reactionAdded.contains(where: { $0.0 == (tweet.id ?? "") && $0.1 == emoji }) {
                viewModel.addReaction(id: tweet.id ?? "", emoji: emoji, devGroup: !isPriv)
            }
            withAnimation(.easeInOut(duration: 0.1)) {
                if emoji == "countSmile" {
                    tweet.countSmile = (tweet.countSmile ?? 0) + 1
                } else if emoji == "countCry" {
                    tweet.countCry = (tweet.countCry ?? 0) + 1
                } else if emoji == "countThumb" {
                    tweet.countThumb = (tweet.countThumb ?? 0) + 1
                } else if emoji == "countBless" {
                    tweet.countBless = (tweet.countBless ?? 0) + 1
                } else if emoji == "countHeart" {
                    tweet.countHeart = (tweet.countHeart ?? 0) + 1
                } else {
                    tweet.countQuestion = (tweet.countQuestion ?? 0) + 1
                }
            }
        } label: {
            ZStack {
                Circle().foregroundStyle(Color.gray.opacity(0.15))

                if emoji == "countSmile" {
                    Text("😂").font(.title)
                } else if emoji == "countCry" {
                    Text("😭").font(.title)
                } else if emoji == "countThumb" {
                    Text("👍").font(.title)
                } else if emoji == "countBless" {
                    Text("🙏").font(.title)
                } else if emoji == "countHeart" {
                    Text("❤️").font(.title)
                } else {
                    Image(systemName: "questionmark").font(.title).foregroundStyle(colorScheme == .dark ? .white : .black)
                }
            }.frame(width: 50, height: 50)
        }
    }
}

func containsFirebasePrefix(_ input: String) -> Bool {
    let prefixes = ["gs://", "http://", "https://"]
    
    for prefix in prefixes {
        if input.hasPrefix(prefix) {
            return true
        }
    }
    
    return false
}
