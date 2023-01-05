import SwiftUI
import Firebase
import UIKit
import AVFoundation
import Kingfisher

struct GroupView: View, KeyboardReadable {
    @State private var tag = ""
    @State private var target = ""
    @State private var keyBoardVisible = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: GroupViewModel
    @EnvironmentObject var explore: ExploreViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var stockModel: StockViewModel
    @EnvironmentObject var profileModel: ProfileViewModel
    @EnvironmentObject var messageModel: MessageViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.scenePhase) var scenePhase
    var group: GroupX
    var imageName: String
    var title: String
    var remTab: Bool
    let showSearch: Bool
    @State var showSettings: Bool = false
    @State var messageText: String = ""
    @State var messageTextError: String = ""
    @State var fieldWidth: Int = 0
    let generator = UINotificationFeedbackGenerator()
    @State private var canROne = true
    @State private var canOne = true
    @State private var offset: Double = 0
    @State var scrollViewSize: CGSize = .zero
    @State var wholeSize: CGSize = .zero
    @State private var showToast = false
    @State private var showLeave = false
    @State private var showKick = false
    @State private var showPromote = false
    @State private var showEdit = false
    @State private var selectedUser = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var copied: Bool = false
    @State private var offsetY: CGFloat = 0
    @State private var showSquareMenu = false
    @State private var atTop = true
    @State private var shouldScroll = false
    @State private var showSearchSheet = false
    @FocusState var isFocused: Bool
    @State var replying: replyToGroup? = nil
    @State private var showMediaPanel = false
    @State private var matchedHastags = [String]()
    @State private var matchedStocks = [String]()
    let randColors: [Color] = [.orange, .red, .green, .blue, .purple]

    @State private var selectedImage: UIImage? = nil
    @State private var groupImage: Image? = nil
    @State var memoryImage: String? = nil
    @State var selectedVideoURL: URL? = nil
    @State private var whichToggle: Int = 1
    @State private var mediaAlert = false
    @State private var playing = true
    @State var addImage: Bool = false
    @State private var showCamera = false
    @State private var showAudioSheet = false
    @EnvironmentObject var recorder: AudioRecorderG
    @State private var recordingTimer: Timer?
    @State private var currentTimeR = 0
    @State private var audioTooLong = false
    @State var muted = false
    @State private var currentTime: Double = 0.0
    @State private var totalLength: Double = 1.0
    @State var fileData: Data? = nil
    @State var pathExtension: String = ""
    @State var showFilePicker: Bool = false
    @State var currentAudio: String = ""
    @State var editing: Editing? = nil
    @State var showAddPoll: Bool = false
    
    @State var showUser: Bool = false
    @State var selectedUserPoll: User? = nil
    
    @State var searchText: String = ""
    @State var searchLoading: Bool = false
    @State var searchChat: Bool = false
    @FocusState var searchBarFocused: Bool
    @State var occurences = [String]()
    @State var occurIndex = 0
    @State var allPhotos: [(String, String)] = []
    @State var showMemories: Bool = false
    @State var showTextCorrection = false
    @State var showAI = false
    @Namespace var animation
    @State var isExpanded: Bool = false
    @State var commonNavID: String = ""
    @State var navToUser: Bool = false
    @State var navToChat: Bool = false
    @State var addPadding: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0){
                VStack(spacing: 0){
                    if !title.isEmpty {
                        HeaderView()
                    } else {
                        HStack(spacing: 10){
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if remTab {
                                    withAnimation {
                                        self.popRoot.hideTabBar = false
                                    }
                                }
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                ZStack {
                                    Circle().frame(width: 40, height: 40).foregroundStyle(.gray).opacity(0.001)
                                    Image(systemName: "chevron.left").font(.title2).bold()
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                }
                            }.padding(.top, 50)
                            if let index = viewModel.currentGroup, index < viewModel.groups.count {
                                Text(viewModel.groups[index].1.title).font(.title).bold().padding(.top, 50)
                            }
                            Spacer()
                            if let index = viewModel.currentGroup, let id = authViewModel.currentUser?.id, index < viewModel.groups.count && (viewModel.groups[index].1.publicstatus || viewModel.groups[index].1.members.contains(id) || viewModel.groups[index].1.leaders.contains(id)) {
                                Menu {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        viewModel.usersMenu()
                                        allPhotos = []
                                        viewModel.groups[index].1.messages?.forEach({ square in
                                            square.messages.forEach { message in
                                                if let image = message.image, !image.isEmpty {
                                                    allPhotos.append((message.id ?? "", image))
                                                }
                                            }
                                        })
                                        showSearchSheet.toggle()
                                    } label: {
                                        Label("Search Media", systemImage: "photo.stack.fill")
                                    }
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(.easeIn(duration: 0.1)){
                                            searchChat = true
                                        }
                                        searchBarFocused = true
                                    } label: {
                                        Label("Search Messages", systemImage: "magnifyingglass")
                                    }
                                } label: {
                                    ZStack {
                                        Circle().frame(width: 40, height: 40)
                                            .foregroundStyle(.black).opacity(colorScheme == .dark ? 0.2 : 0.1)
                                        Image(systemName: "magnifyingglass").font(.headline)
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    }
                                }.padding(.top, 50)
                            }
                            Button {
                                viewModel.fillSubContainers()
                                withAnimation(.easeInOut){
                                    showSquareMenu.toggle()
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                ZStack {
                                    Circle().frame(width: 40, height: 40)
                                        .foregroundStyle(.black).opacity(colorScheme == .dark ? 0.2 : 0.1)
                                    
                                    ColorsCard(gradientColors: [colorScheme == .dark ? Color(UIColor.lightGray) : .black, .orange], size: 40).rotationEffect(.degrees(45))
                                        .scaleEffect(0.8)
                                }
                            }.padding(.top, 50)
                        }
                        .padding(.horizontal)
                        .frame(height: 110)
                        .background {
                            Color(UIColor.darkGray).opacity(colorScheme == .dark ? 0.7 : 0.6)
                        }
                        .overlay {
                            if searchChat {
                                searchHeader()
                            }
                        }
                    }
                    if let index = viewModel.currentGroup, (index < viewModel.groups.count && title.isEmpty) || (index < viewModel.groupsDev.count && !title.isEmpty) {
                        if !title.isEmpty || (viewModel.groups[index].1.publicstatus) || (!viewModel.groups[index].1.publicstatus && (viewModel.groups[index].1.members.contains(authViewModel.currentUser?.id ?? ""))) {
                            ZStack(alignment: .top){
                                GeometryReader { geometry in
                                    ScrollViewReader { scrollProxy in
                                        ChildSizeReader(size: $wholeSize) {
                                            ScrollView {
                                                ChildSizeReader(size: $scrollViewSize) {
                                                    LazyVStack(alignment: .leading){
                                                        Color.clear.frame(height: 1).id("GoTo")
                                                            .onAppear { withAnimation { atTop = true } }
                                                            .onDisappear { withAnimation { atTop = false } }
                                                        if !title.isEmpty {
                                                            if let mes = viewModel.groupsDev[index].messages {
                                                                if mes.isEmpty {
                                                                    HStack {
                                                                        Spacer()
                                                                        VStack(spacing: 18){
                                                                            Text("Be the first to chat...")
                                                                                .gradientForeground(colors: [.blue, .purple])
                                                                                .font(.headline).bold()
                                                                            LottieView(loopMode: .playOnce, name: "nofound")
                                                                                .scaleEffect(0.3)
                                                                                .frame(width: 100, height: 100)
                                                                        }
                                                                        Spacer()
                                                                    }.padding(.top, 70)
                                                                } else {
                                                                    ForEach(mes) { tweet in
                                                                        GroupMessageView(tweet: tweet, isPriv: false, canDelete: ((authViewModel.currentUser?.id ?? "NA") == tweet.uid), replying: $replying, currentAudio: $currentAudio, editing: $editing, showUser: $showUser, selectedUser: $selectedUserPoll, isExpanded: $isExpanded, animation: animation, seenAllStories: storiesLeftToView(otherUID: tweet.uid), addPadding: $addPadding)
                                                                            .id(tweet.id)
                                                                            .padding(.bottom, 16)
                                                                            .overlay(GeometryReader { proxy in
                                                                                Color.clear
                                                                                    .onChange(of: offset, { _, _ in
                                                                                        if let vid_id = tweet.videoURL, popRoot.currentSound.isEmpty {
                                                                                            let frame = proxy.frame(in: .global)
                                                                                            let bottomDistance = frame.minY - geometry.frame(in: .global).minY
                                                                                            let topDistance = geometry.frame(in: .global).maxY - frame.maxY
                                                                                            let diff = bottomDistance - topDistance
                                                                                            
                                                                                            if (bottomDistance < 0.0 && abs(bottomDistance) >= (frame.height / 2.0)) || (topDistance < 0.0 && abs(topDistance) >= (frame.height / 2.0)) {
                                                                                                if currentAudio == vid_id + (tweet.id ?? "") {
                                                                                                    currentAudio = ""
                                                                                                }
                                                                                            } else if abs(diff) < 140 && abs(diff) > -140 {
                                                                                                currentAudio = vid_id + (tweet.id ?? "")
                                                                                            }
                                                                                        }
                                                                                    })
                                                                            })
                                                                    }
                                                                }
                                                            } else {
                                                                VStack {
                                                                    ForEach(0..<7){ i in
                                                                        LoadingFeed(lesson: "")
                                                                    }
                                                                }.shimmering()
                                                            }
                                                        } else {
                                                            let currentSquare = viewModel.groups[index].0
                                                            if currentSquare == "Rules" {
                                                                if let str = viewModel.groups[index].1.rules, !str.isEmpty {
                                                                    HStack {
                                                                        LinkedText(str, tip: false, isMess: nil).padding(5).background(.ultraThinMaterial).cornerRadius(10)
                                                                    }.padding(10)
                                                                } else {
                                                                    HStack{
                                                                        Spacer()
                                                                        VStack(spacing: 18){
                                                                            Text("No rules yet...")
                                                                                .gradientForeground(colors: [.blue, .purple])
                                                                                .font(.headline).bold()
                                                                            LottieView(loopMode: .playOnce, name: "nofound")
                                                                                .scaleEffect(0.3)
                                                                                .frame(width: 100, height: 100)
                                                                        }
                                                                        Spacer()
                                                                    }.padding(.top, 70)
                                                                }
                                                            } else if currentSquare == "Info/Description" {
                                                                if !viewModel.groups[index].1.desc.isEmpty {
                                                                    HStack {
                                                                        LinkedText(viewModel.groups[index].1.desc, tip: false, isMess: nil).padding(5).background(.ultraThinMaterial).cornerRadius(10)
                                                                    }.padding(10)
                                                                } else {
                                                                    HStack {
                                                                        Spacer()
                                                                        VStack(spacing: 18){
                                                                            Text("No info yet...")
                                                                                .gradientForeground(colors: [.blue, .purple])
                                                                                .font(.headline).bold()
                                                                            LottieView(loopMode: .playOnce, name: "nofound")
                                                                                .scaleEffect(0.3)
                                                                                .frame(width: 100, height: 100)
                                                                        }
                                                                        Spacer()
                                                                    }.padding(.top, 70)
                                                                }
                                                            } else if let mes = viewModel.groups[index].1.messages?.first(where: { $0.id == currentSquare })?.messages {
                                                                if mes.isEmpty {
                                                                    HStack {
                                                                        Spacer()
                                                                        VStack(spacing: 18){
                                                                            Text("Be the first to chat...")
                                                                                .gradientForeground(colors: [.blue, .purple])
                                                                                .font(.headline).bold()
                                                                            LottieView(loopMode: .playOnce, name: "nofound")
                                                                                .scaleEffect(0.3)
                                                                                .frame(width: 100, height: 100)
                                                                        }
                                                                        Spacer()
                                                                    }.padding(.top, 70)
                                                                } else {
                                                                    ForEach(mes) { tweet in
                                                                        let id = authViewModel.currentUser?.id ?? "NA"
                                                                        
                                                                        GroupMessageView(tweet: tweet, isPriv: true, canDelete: (viewModel.groups[index].1.leaders.contains(id) || tweet.uid == id), replying: $replying, currentAudio: $currentAudio, editing: $editing, showUser: $showUser, selectedUser: $selectedUserPoll, isExpanded: $isExpanded, animation: animation, seenAllStories: storiesLeftToView(otherUID: tweet.uid), addPadding: $addPadding)
                                                                            .id(tweet.id)
                                                                            .padding(.bottom, 16)
                                                                            .overlay(GeometryReader { proxy in
                                                                                Color.clear
                                                                                    .onChange(of: offset, { _, _ in
                                                                                        if let vid_id = tweet.videoURL, popRoot.currentSound.isEmpty {
                                                                                            let frame = proxy.frame(in: .global)
                                                                                            let bottomDistance = frame.minY - geometry.frame(in: .global).minY
                                                                                            let topDistance = geometry.frame(in: .global).maxY - frame.maxY
                                                                                            let diff = bottomDistance - topDistance
                                                                                            
                                                                                            if (bottomDistance < 0.0 && abs(bottomDistance) >= (frame.height / 2.0)) || (topDistance < 0.0 && abs(topDistance) >= (frame.height / 2.0)) {
                                                                                                if currentAudio == vid_id + (tweet.id ?? "") {
                                                                                                    currentAudio = ""
                                                                                                }
                                                                                            } else if abs(diff) < 140 && abs(diff) > -140 {
                                                                                                currentAudio = vid_id + (tweet.id ?? "")
                                                                                            }
                                                                                        }
                                                                                    })
                                                                            })
                                                                        if let newPos = viewModel.newIndex, newPos == tweet.id {
                                                                            NewChatLine()
                                                                        }
                                                                    }
                                                                }
                                                            } else {
                                                                VStack {
                                                                    ForEach(0..<7){ i in
                                                                        LoadingFeed(lesson: "")
                                                                    }
                                                                }.shimmering()
                                                            }
                                                        }
                                                        if offset > 100 {
                                                            HStack{
                                                                Spacer()
                                                                ProgressView().padding(.bottom, 30)
                                                                Spacer()
                                                            }
                                                        }
                                                    }
                                                    .padding(.top, 12)
                                                    .background(GeometryReader {
                                                        Color.clear.preference(key: ViewOffsetKey.self,
                                                                               value: -$0.frame(in: .named("scroll")).origin.y)
                                                    })
                                                    .onPreferenceChange(ViewOffsetKey.self) { value in
                                                        offsetY = -value
                                                        offset = value
                                                        if value > 200 && canOne {
                                                            if value > (scrollViewSize.height - wholeSize.height) - 300{
                                                                canOne = false
                                                                if let index = viewModel.currentGroup {
                                                                    if title.isEmpty {
                                                                        viewModel.beginGroupConvoMore(groupId: viewModel.groups[index].1.id, devGroup: (title == "") ? false : true, blocked: authViewModel.currentUser?.blockedUsers ?? [], square: viewModel.groups[index].0)
                                                                    } else {
                                                                        viewModel.beginGroupConvoMore(groupId: title, devGroup: (title == "") ? false : true, blocked: authViewModel.currentUser?.blockedUsers ?? [], square: "")
                                                                    }
                                                                }
                                                                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                                                    canOne = true
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .id("SCROLLVIEW")
                                                    .background {
                                                        ScrollDetector { _ in
                                                        } onDraggingEnd: { offset, velocity in
                                                            if !title.isEmpty {
                                                                let headerHeight = (widthOrHeight(width: false) * 0.3) + top_Inset()
                                                                let minimumHeaderHeight = 65 + top_Inset()
                                                                let targetEnd = offset + (velocity * 45)
                                                                if targetEnd < (headerHeight - minimumHeaderHeight) && targetEnd > 0 {
                                                                    withAnimation(.interactiveSpring(response: 0.55, dampingFraction: 0.65, blendDuration: 0.65)) {
                                                                        scrollProxy.scrollTo("SCROLLVIEW", anchor: .top)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .scrollDismissesKeyboard(.immediately)
                                            .refreshable { }.coordinateSpace(name: "scroll")
                                            .onChange(of: viewModel.scrollToReply) { _, new in
                                                if !new.isEmpty {
                                                    withAnimation(.linear(duration: 0.2)){
                                                        scrollProxy.scrollTo(new, anchor: .center)
                                                    }
                                                }
                                            }
                                            .onChange(of: viewModel.scrollToReplyNow) { _, new in
                                                if !new.isEmpty {
                                                    withAnimation(.linear(duration: 0.1)){
                                                        scrollProxy.scrollTo(new, anchor: .center)
                                                    }
                                                }
                                            }
                                            .onChange(of: shouldScroll) { _, _ in
                                                if shouldScroll {
                                                    withAnimation {
                                                        scrollProxy.scrollTo("GoTo")
                                                    }
                                                    shouldScroll = false
                                                }
                                            }
                                        }
                                    }
                                }
                                if (offset <= -70) {
                                    HStack{
                                        Spacer()
                                        Loader(flip: false)
                                        Spacer()
                                    }.padding(.top)
                                }
                                if !atTop && !keyBoardVisible {
                                    VStack {
                                        Spacer()
                                        Button {
                                            shouldScroll = true
                                            withAnimation { atTop = true }
                                        } label: {
                                            ZStack {
                                                Circle().foregroundStyle(.indigo)
                                                Image(systemName: "chevron.up").font(.title3).foregroundStyle(.white)
                                            }.frame(width: 38, height: 38)
                                        }
                                    }.transition(.move(edge: .bottom).combined(with: .opacity)).padding(.bottom, 20)
                                }
                                
                                if !searchChat {
                                    ZStack(alignment: .bottom){
                                        
                                        if messageText.contains("@") && tag.isEmpty && (groupImage != nil || selectedVideoURL != nil || !recorder.recordings.isEmpty || memoryImage != nil) {
                                            VStack {
                                                Spacer()
                                                HStack(spacing: 5){
                                                    Spacer()
                                                    Text("Media Attached").font(.system(size: 18)).padding(.trailing)
                                                    Button {
                                                        withAnimation(.easeIn(duration: 0.12)){
                                                            selectedImage = nil
                                                            groupImage = nil
                                                            selectedVideoURL = nil
                                                            fileData = nil
                                                            memoryImage = nil
                                                        }
                                                        deleteRecording()
                                                    } label: {
                                                        Image(systemName: "xmark")
                                                            .resizable()
                                                            .frame(width: 17, height:17)
                                                            .foregroundColor(.blue)
                                                    }.padding(.trailing, 10)
                                                }.padding(.vertical, 10).background(.ultraThinMaterial.opacity(0.9))
                                            }.transition(.move(edge: .bottom).combined(with: .opacity))
                                        } else if let image = groupImage {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    ZStack(alignment: .topTrailing){
                                                        image.resizable()
                                                            .scaledToFill().frame(width: 120, height: 120).cornerRadius(5)
                                                        Button {
                                                            selectedImage = nil
                                                            withAnimation(.easeIn(duration: 0.12)){
                                                                groupImage = nil
                                                            }
                                                        } label: {
                                                            ZStack{
                                                                Circle().foregroundColor(Color(UIColor.darkGray))
                                                                Image(systemName: "xmark")
                                                                    .resizable().frame(width: 16, height: 16)
                                                                    .foregroundColor(.white)
                                                            }
                                                        }
                                                        .frame(width: 25, height: 25).padding(.top, 5).padding(.trailing, 5)
                                                    }.padding(.bottom, 8).padding(.leading, 8)
                                                    Spacer()
                                                }
                                            }.transition(.scale.combined(with: .opacity))
                                        } else if let image = memoryImage {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    ZStack(alignment: .topTrailing){
                                                        KFImage(URL(string: image))
                                                            .resizable().scaledToFill()
                                                            .frame(width: 120, height: 120)
                                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                                            .contentShape(Rectangle())
                                                        Button {
                                                            withAnimation(.easeIn(duration: 0.12)){
                                                                memoryImage = nil
                                                            }
                                                        } label: {
                                                            ZStack{
                                                                Circle().foregroundColor(Color(UIColor.darkGray))
                                                                Image(systemName: "xmark")
                                                                    .resizable().frame(width: 16, height: 16)
                                                                    .foregroundColor(.white)
                                                            }
                                                        }
                                                        .frame(width: 25, height: 25).padding(.top, 5).padding(.trailing, 5)
                                                    }.padding(.bottom, 8).padding(.leading, 8)
                                                    Spacer()
                                                }
                                            }.transition(.scale.combined(with: .opacity))
                                        } else if let url = selectedVideoURL {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    HustleVideoPlayer(url: url, muted: $muted, currentTime: $currentTime, totalLength: $totalLength, playVid: .constant(false), pauseVid: .constant(false), togglePlay: $playing, shouldPlayAppear: true)
                                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                                        .disabled(true)
                                                        .overlay {
                                                            VStack {
                                                                HStack {
                                                                    Button(action: {
                                                                        muted.toggle()
                                                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                                    }, label: {
                                                                        ZStack {
                                                                            Circle().foregroundStyle(.ultraThickMaterial)
                                                                            if muted {
                                                                                Image(systemName: "speaker.slash.fill").foregroundStyle(.white).font(.subheadline)
                                                                            } else {
                                                                                Image(systemName: "speaker.wave.2").foregroundStyle(.white).font(.subheadline)
                                                                            }
                                                                        }.frame(width: 30, height: 30)
                                                                    })
                                                                    Spacer()
                                                                    Button(action: {
                                                                        playing.toggle()
                                                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                                    }, label: {
                                                                        ZStack {
                                                                            Circle().foregroundStyle(.ultraThickMaterial)
                                                                            if playing {
                                                                                Image(systemName: "pause").foregroundStyle(.white).font(.subheadline)
                                                                            } else {
                                                                                Image(systemName: "play.fill").foregroundStyle(.white).font(.subheadline)
                                                                            }
                                                                        }.frame(width: 30, height: 30)
                                                                    })
                                                                }
                                                                Spacer()
                                                                HStack {
                                                                    Spacer()
                                                                    Button(action: {
                                                                        withAnimation(.easeIn(duration: 0.12)){
                                                                            selectedVideoURL = nil
                                                                        }
                                                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                                    }, label: {
                                                                        ZStack{
                                                                            Circle().foregroundStyle(.ultraThickMaterial)
                                                                            Image(systemName: "xmark")
                                                                                .font(.subheadline)
                                                                                .foregroundColor(.white)
                                                                        }.frame(width: 30, height: 30)
                                                                    })
                                                                }
                                                            }.padding(10)
                                                        }
                                                        .frame(maxWidth: 200, maxHeight: 200, alignment: .leading)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                    Spacer()
                                                }.padding(.bottom, 5).padding(.leading, 5)
                                            }.transition(.scale.combined(with: .opacity))
                                        } else if let first = recorder.recordings.first {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    MessageAudioPView(audioUrl: first.fileURL, empty: $recorder.recordings, currentAudio: $currentAudio, onClose: {
                                                        deleteRecording()
                                                    })
                                                    Spacer()
                                                }.padding(.bottom, 5).padding(.leading, 5)
                                            }
                                        } else if fileData != nil {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    HStack(spacing: 10){
                                                        VStack(alignment: .leading){
                                                            Text("File attached").font(.system(size: 18))
                                                                .bold().foregroundStyle(colorScheme == .dark ? .white : .black)
                                                            Text("Type: \(pathExtension)").font(.system(size: 15))
                                                                .foregroundStyle(.gray)
                                                        }
                                                        Button {
                                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                            withAnimation(.easeIn(duration: 0.12)){
                                                                fileData = nil
                                                            }
                                                            pathExtension = ""
                                                        } label: {
                                                            Image(systemName: "xmark.circle") .foregroundStyle(.gray).font(.system(size: 18))
                                                        }
                                                    }
                                                    .padding(.horizontal, 9)
                                                    .frame(height: 65)
                                                    .background(.ultraThinMaterial)
                                                    .cornerRadius(20, corners: .allCorners)
                                                    Spacer()
                                                }.padding(.bottom, 5).padding(.leading, 5)
                                            }.transition(.scale.combined(with: .opacity))
                                        }
                                        
                                        if showMediaPanel {
                                            TransparentBlurView(removeAllFilters: true)
                                                .blur(radius: 2, opaque: true)
                                                .background(colorScheme == .dark ? .black.opacity(0.6) : .white.opacity(0.8))
                                                .onTapGesture {
                                                    withAnimation(.easeIn(duration: 0.12)){
                                                        showMediaPanel = false
                                                    }
                                                }
                                            HStack(alignment: .bottom){
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .foregroundStyle(colorScheme == .dark ? Color(red: 66 / 255.0, green: 69 / 255.0, blue: 73 / 255.0) : Color(UIColor.lightGray))
                                                    VStack(spacing: 12){
                                                        Button {
                                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                            if groupImage != nil || selectedVideoURL != nil || !recorder.recordings.isEmpty || memoryImage != nil {
                                                                whichToggle = 4
                                                                mediaAlert.toggle()
                                                            } else {
                                                                showFilePicker.toggle()
                                                                showMediaPanel = false
                                                            }
                                                        } label: {
                                                            HStack {
                                                                Text("Files")
                                                                Spacer()
                                                                Image(systemName: "paperclip")
                                                            }
                                                        }.padding(.horizontal, 10)
                                                        Divider().overlay(colorScheme == .dark ? .white.opacity(0.6) : .gray)
                                                        Button {
                                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                            showAddPoll = true
                                                            showMediaPanel = false
                                                        } label: {
                                                            HStack {
                                                                Text("Poll")
                                                                Spacer()
                                                                Image(systemName: "chart.bar.fill")
                                                            }
                                                        }.padding(.horizontal, 10)
                                                        Divider().overlay(colorScheme == .dark ? .white.opacity(0.6) : .gray)
                                                        Button {
                                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                            if groupImage != nil || selectedVideoURL != nil || fileData != nil || memoryImage != nil {
                                                                whichToggle = 3
                                                                mediaAlert.toggle()
                                                            } else {
                                                                showAudioSheet.toggle()
                                                                showMediaPanel = false
                                                            }
                                                        } label: {
                                                            HStack {
                                                                Text("Audio")
                                                                Spacer()
                                                                Image(systemName: "speaker.wave.2.fill")
                                                            }
                                                        }.padding(.horizontal, 10)
                                                        Divider().overlay(colorScheme == .dark ? .white.opacity(0.6) : .gray)
                                                        Button {
                                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                            if groupImage != nil || selectedVideoURL != nil || !recorder.recordings.isEmpty || fileData != nil {
                                                                whichToggle = 5
                                                                mediaAlert.toggle()
                                                            } else {
                                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                                showMemories = true
                                                                showMediaPanel = false
                                                            }
                                                        } label: {
                                                            HStack {
                                                                Text("Memories")
                                                                    .gradientForeground(colors: [.blue, .purple])
                                                                Spacer()
                                                                Image("memory")
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(width: 25, height: 25)
                                                                    .scaleEffect(1.35)
                                                            }
                                                        }.padding(.horizontal, 10)
                                                        Divider().overlay(colorScheme == .dark ? .white.opacity(0.6) : .gray)
                                                        Button {
                                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                            if groupImage != nil || selectedVideoURL != nil || !recorder.recordings.isEmpty || fileData != nil || memoryImage != nil {
                                                                whichToggle = 2
                                                                mediaAlert.toggle()
                                                            } else {
                                                                if keyBoardVisible {
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                                                        showCamera.toggle()
                                                                    }
                                                                } else {
                                                                    showCamera.toggle()
                                                                }
                                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                                showMediaPanel = false
                                                            }
                                                        } label: {
                                                            HStack {
                                                                Text("Camera")
                                                                Spacer()
                                                                Image(systemName: "camera.fill")
                                                            }
                                                        }.padding(.horizontal, 10)
                                                        Divider().overlay(colorScheme == .dark ? .white.opacity(0.6) : .gray)
                                                        Button {
                                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                            if groupImage != nil || selectedVideoURL != nil || !recorder.recordings.isEmpty || fileData != nil || memoryImage != nil {
                                                                whichToggle = 1
                                                                mediaAlert.toggle()
                                                            } else {
                                                                if selectedVideoURL != nil && playing {
                                                                    playing = false
                                                                }
                                                                addImage.toggle()
                                                                showMediaPanel = false
                                                            }
                                                        } label: {
                                                            HStack {
                                                                Text("Photos")
                                                                Spacer()
                                                                Image(systemName: "photo")
                                                            }
                                                        }.padding(.horizontal, 10)
                                                    }
                                                    .font(.system(size: 17))
                                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                                }
                                                .padding(.bottom, 10).padding(.leading, 10)
                                                .frame(width: 250, height: 275)
                                                Spacer()
                                            }
                                            .transition(.scale.combined(with: .opacity))
                                        } else if keyBoardVisible && !matchedHastags.isEmpty && !(messageText.contains("@") && tag.isEmpty) {
                                            VStack {
                                                Spacer()
                                                hashtags()
                                            }
                                        } else if keyBoardVisible && !matchedStocks.isEmpty && !(messageText.contains("@") && tag.isEmpty) {
                                            VStack {
                                                Spacer()
                                                stockPicker()
                                            }
                                        }
                                    }
                                }
                            }
                            .onChange(of: offset) { _, newVal in
                                if offset <= -80 {
                                    if title.isEmpty {
                                        let currentS = viewModel.groups[index].0
                                        if currentS != "Info/Description" && currentS != "Rules" && canROne {
                                            viewModel.beginGroupConvo(groupId: viewModel.groups[index].1.id, devGroup: false, blocked: authViewModel.currentUser?.blockedUsers ?? [], square: currentS)
                                            generator.notificationOccurred(.success)
                                            canROne = false
                                            Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { _ in
                                                canROne = true
                                            }
                                        }
                                    } else if canROne {
                                        viewModel.beginGroupConvo(groupId: title, devGroup: true, blocked: authViewModel.currentUser?.blockedUsers ?? [], square: "")
                                        generator.notificationOccurred(.success)
                                        canROne = false
                                        Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { _ in
                                            canROne = true
                                        }
                                    }
                                }
                            }
                        } else {
                            VStack(alignment: .center){
                                Spacer()
                                LottieView(loopMode: .loop, name: "lock")
                                    .frame(width: 130, height: 130)
                                Text("This content is hidden")
                                    .font(.subheadline)
                                    .padding(.top)
                                Spacer()
                            }
                        }
                    }
                }
                .ignoresSafeArea(.all, edges: .top)
                if showToast {
                    ToastView(message: "Only members can message")
                        .padding(.bottom)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation{
                                    showToast = false
                                }
                            }
                        }
                }
                if let index = viewModel.currentGroup, (index < viewModel.groups.count && title.isEmpty) || (index < viewModel.groupsDev.count && !title.isEmpty) {
                    if !title.isEmpty || (title.isEmpty && viewModel.groups[index].1.members.contains(authViewModel.currentUser?.id ?? "")) {
                        
                        if searchChat {
                            searchBarView()
                        } else if keyBoardVisible && messageText.contains("@") && tag.isEmpty {
                            TaggedUserView(text: $messageText, target: $target, commentID: nil, newsID: nil, newsRepID: nil, questionID: nil, groupID: title.isEmpty ? viewModel.groups[index].1.id : title, selectedtag: $tag)
                        } else if let reps = replying {
                            HStack(spacing: 14){
                                Text("@ ON").padding(.leading).font(.headline).bold().foregroundStyle(.indigo)
                                HStack(spacing: 2){
                                    Text("Replying to").font(.subheadline).foregroundStyle(colorScheme == .dark ? .white : .gray)
                                    Text(reps.selfReply ? "Yourself" : "\(reps.username)").font(.subheadline)
                                        .foregroundStyle(.blue).bold()
                                }
                                Spacer()
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.easeInOut(duration: 0.1)){
                                        replying = nil
                                    }
                                }, label: {
                                    Image(systemName: "xmark.circle.fill").font(.headline).foregroundStyle(colorScheme == .dark ? .white : .gray)
                                }).padding(.trailing)
                            }
                            .frame(height: 36).background(.ultraThinMaterial).transition(.move(edge: .bottom))
                            .onTapGesture {
                                viewModel.scrollToReply = reps.messageID
                            }
                        } else if let edit = editing {
                            HStack(spacing: 14){
                                Image(systemName: "pencil").font(.headline).foregroundStyle(colorScheme == .dark ? .white : .gray).padding(.leading)
                                Text("Editing Message").font(.subheadline).foregroundStyle(colorScheme == .dark ? .white : .gray)
                                Spacer()
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.easeIn(duration: 0.1)){
                                        editing = nil
                                    }
                                }, label: {
                                    Image(systemName: "xmark.circle.fill").font(.headline).foregroundStyle(colorScheme == .dark ? .white : .gray)
                                }).padding(.trailing)
                            }
                            .frame(height: 40).background(.ultraThinMaterial).transition(.move(edge: .bottom))
                            .onTapGesture {
                                viewModel.scrollToReply = edit.messageID
                            }
                        }
                        
                        if !searchChat {
                            Divider().overlay(colorScheme == .dark ? Color(UIColor.lightGray) : .gray).padding(.bottom, 8)
                            
                            HStack(alignment: .bottom, spacing: 10){
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    AudioServicesPlaySystemSound(1306)
                                    if showAI {
                                        showTextCorrection = true
                                    } else {
                                        if title.isEmpty {
                                            withAnimation(.easeIn(duration: 0.12)){
                                                showMediaPanel.toggle()
                                            }
                                        } else {
                                            addImage.toggle()
                                        }
                                    }
                                } label: {
                                    ZStack {
                                        Circle().frame(width: 40, height: 40).foregroundColor(Color.gray).opacity(0.3)
                                        if showAI {
                                            LottieView(loopMode: .loop, name: "finite")
                                                .scaleEffect(0.051)
                                                .frame(width: 25, height: 14).transition(.scale)
                                        } else {
                                            Image(systemName: "plus")
                                                .resizable().frame(width: 22, height: 22)
                                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                                .rotationEffect(.degrees(showMediaPanel ? 45.0 : 0.0))
                                                .transition(.scale)
                                        }
                                    }
                                }
                                
                                TextField("Message \(title.isEmpty ? viewModel.groups[index].0 : title)", text: $messageText, axis: .vertical)
                                    .focused($isFocused)
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 10)
                                    .frame(minHeight: 40)
                                    .lineLimit(5)
                                    .background(content: {
                                        RoundedRectangle(cornerRadius: 20).foregroundStyle(.gray).opacity(0.3)
                                    })
                                    .foregroundColor((messageTextError == "") ? colorScheme == .dark ? .white : .black : Color.red)
                                    .onChange(of: messageText) { _, _ in
                                        if messageText.count > 30, !showAI && !showMediaPanel {
                                            withAnimation(.easeInOut(duration: 0.1)){
                                                showAI = true
                                            }
                                        } else if showAI && messageText.count <= 30 {
                                            withAnimation(.easeInOut(duration: 0.1)){
                                                showAI = false
                                            }
                                        }
                                    }
                                
                                if !viewModel.uploaded || (title.isEmpty && authViewModel.currentUser?.elo ?? 0 >= 600) || (title.isEmpty && !viewModel.groups[index].1.publicstatus) || (title.isEmpty && viewModel.groups[index].1.leaders.contains(authViewModel.currentUser?.id ?? "")){
                                    if editing != nil {
                                        Button {
                                            updateMessage()
                                        } label: {
                                            ZStack {
                                                Circle().foregroundColor(Color.gray).opacity(0.3)
                                                Image(systemName: "pencil")
                                                    .font(.system(size: 24))
                                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                            }.frame(width: 40, height: 40)
                                        }
                                    } else if !title.isEmpty {
                                        Button {
                                            sendContent(index: index)
                                        } label: {
                                            ZStack {
                                                Circle().frame(width: 40, height: 40).foregroundColor(Color.orange)
                                                Image(systemName: "paperplane.fill")
                                                    .resizable().frame(width: 24, height: 24)
                                                    .rotationEffect(.degrees(45.0))
                                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                                    .offset(x: -3)
                                            }
                                        }.disabled((messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !messageTextError.isEmpty) && selectedImage == nil)
                                    } else if (!messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && messageTextError.isEmpty) || selectedImage != nil || !recorder.recordings.isEmpty || selectedVideoURL != nil || fileData != nil || memoryImage != nil {
                                        Button {
                                            sendContent(index: index)
                                        } label: {
                                            ZStack {
                                                Circle().frame(width: 40, height: 40).foregroundColor(Color.orange)
                                                Image(systemName: "paperplane.fill")
                                                    .resizable().frame(width: 24, height: 24)
                                                    .rotationEffect(.degrees(45.0))
                                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                                    .offset(x: -3)
                                            }
                                        }
                                        .disabled(viewModel.groups[index].0 == "Rules" || viewModel.groups[index].0 == "Info/Description")
                                    } else {
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            if groupImage != nil || selectedVideoURL != nil {
                                                whichToggle = 3
                                                mediaAlert.toggle()
                                            } else {
                                                showAudioSheet.toggle()
                                            }
                                        } label: {
                                            ZStack {
                                                Circle().frame(width: 40, height: 40).foregroundColor(Color.gray)
                                                    .opacity(0.3)
                                                Image(systemName: "mic.fill")
                                                    .font(.system(size: 24)).scaleEffect(y: 0.85)
                                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                            }
                                        }
                                    }
                                } else {
                                    uploadedView()
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                            .padding(.bottom, addPadding ? bottom_Inset() : 0.0)
                        }
                    } else {
                        cantSend()
                    }
                }
            }
        }
        .overlay {
            if isExpanded {
                if profileModel.isStoryRow {
                    MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: profileModel.mid, isHome: false, canOpenChat: false, canOpenProfile: true, openChat: { _ in
                    }, openProfile: { uid in
                        if let user = profileModel.users.first(where: { $0.user.id == uid })?.user {
                            selectedUserPoll = user
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
                                showUser = true
                            }
                        }
                    })
                    .ignoresSafeArea()
                    .onAppear(perform: { currentAudio = "" })
                    .onDisappear { addPadding = false }
                } else {
                    MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: profileModel.mid, isHome: false, canOpenChat: false, canOpenProfile: true, openChat: { _ in
                    }, openProfile: { uid in
                        if let user = profileModel.users.first(where: { $0.user.id == uid })?.user {
                            selectedUserPoll = user
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
                                showUser = true
                            }
                        }
                    })
                    .transition(.scale).ignoresSafeArea()
                    .onAppear(perform: { currentAudio = "" })
                    .onDisappear { addPadding = false }
                }
            }
        }
        .ignoresSafeArea(edges: addPadding ? .all : [])
        .sheet(isPresented: $showTextCorrection, content: {
            RecommendTextView(oldText: $messageText)
        })
        .sheet(isPresented: $showMemories, content: {
            MemoryPickerSheetView(photoOnly: false, maxSelect: 1) { allData in
                allData.forEach { element in
                    if element.isImage {
                        self.memoryImage = element.urlString
                    } else if let url = URL(string: element.urlString){
                        selectedVideoURL = url
                    }
                }
            }
        })
        .navigationDestination(isPresented: $showUser) {
            ProfileView(showSettings: false, showMessaging: true, uid: selectedUserPoll?.id ?? "", photo: selectedUserPoll?.profileImageUrl ?? "", user: selectedUserPoll, expand: false, isMain: false).enableFullSwipePop(true)
        }
        .sheet(isPresented: $showAddPoll, content: {
            ChatPollView(isDevGroup: !title.isEmpty)
        })
        .onDisappear {
            if !navToChat {
                withAnimation {
                    self.popRoot.hideTabBar = false
                }
            }
            if let index = viewModel.currentGroup, title.isEmpty && index < viewModel.groups.count {
                let square = viewModel.groups[index].0
                if let first = viewModel.groups[index].1.messages?.first(where: { $0.id == square })?.messages.first {
                    if let mid = first.id, first.uid != (authViewModel.currentUser?.id ?? "") {
                        let fullID = viewModel.groups[index].1.id + square
                        LastSeenModel().setLastSeen(id: fullID, messageID: mid)
                    }
                }
            }
            viewModel.newIndex = nil
            viewModel.currentGroup = nil
        }
        .fullScreenCover(isPresented: $showCamera, content: {
            UploadHustleCamera(selectedImage: $selectedImage, hustleImage: $groupImage, selectedVideoURL: $selectedVideoURL, isImagePickerPresented: $showCamera)
        })
        .fullScreenCover(isPresented: $addImage, content: {
            HustlePickerView(selectedImage: $selectedImage, hustleImage: $groupImage, selectedVideoURL: $selectedVideoURL, isImagePickerPresented: $addImage, canAddVid: title.isEmpty)
        })
        .alert("Only 1 media file can be attached, would you like to replace it?", isPresented: $mediaAlert) {
            Button("Replace", role: .destructive) {
                groupImage = nil
                selectedImage = nil
                selectedVideoURL = nil
                fileData = nil
                memoryImage = nil
                deleteRecording()
                if whichToggle == 1 {
                    if selectedVideoURL != nil && playing {
                        playing = false
                    }
                    addImage.toggle()
                } else if whichToggle == 2 {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    showCamera.toggle()
                } else if whichToggle == 3 {
                    showAudioSheet.toggle()
                } else if whichToggle == 4 {
                    showFilePicker.toggle()
                } else {
                    showMemories = true
                }
                showMediaPanel = false
            }
            Button("Cancel", role: .cancel) {
                withAnimation(.easeIn(duration: 0.12)){
                    showMediaPanel = false
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [UTType.data]) { result in
            do {
                let url = try result.get()
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                if let fileData = try? Data(contentsOf: url) {
                    let fileExtension = url.pathExtension
                    self.fileData = fileData
                    self.pathExtension = fileExtension
                }
            } catch {
                print("E")
            }
        }
        .fullScreenCover(isPresented: $showSearchSheet, content: {
            FullSwipeNavigationStack {
                MediaSearchGroups(allPhotos: allPhotos, replying: $replying, show: $showSearchSheet)
            }
        })
        .blur(radius: showSquareMenu ? 4 : 0)
        .overlay(content: {
            if showSquareMenu {
                GroupSideMenu(show: $showSquareMenu, replying: $replying, showSearch: showSearch, showEditMenu: $showSettings, showSearchSheet: $showSearchSheet, allPhotos: $allPhotos).transition(AnyTransition.move(edge: .trailing))
            }
        })
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
            if !showSearchSheet {
                keyBoardVisible = newIsKeyboardVisible
            }
        }
        .onChange(of: tag) { _, _ in
            if !tag.isEmpty {
                if let range = messageText.range(of: "@") {
                    let final = messageText.replacingCharacters(in: range, with: "@\(tag) ")
                    messageText = removeSecondOccurrence(of: target, in: final)
                    target = ""
                }
            }
        }
        .onChange(of: searchChat, { _, new in
            if !new {
                searchText = ""
                occurences = []
            }
        })
        .onChange(of: searchText, { _, _ in
            var temp = [String]()
            var currID: String? = nil
            
            if !occurences.isEmpty && occurIndex < occurences.count && occurIndex != 0 {
                currID = occurences[occurIndex]
            }
            
            if let index = viewModel.currentGroup, let messages = viewModel.groups[index].1.messages?.first(where: { $0.id == viewModel.groups[index].0 })?.messages {
                
                messages.forEach { element in
                    if let id = element.id, element.caption.lowercased().contains(searchText.lowercased()) {
                        temp.append(id)
                    }
                }
  
                if let id = currID {
                    if let newIndex = temp.firstIndex(where: { $0 == id }) {
                        occurIndex = newIndex
                    }
                } else if !temp.isEmpty {
                    occurIndex = 0
                    viewModel.scrollToReplyNow = temp[occurIndex]
                }
                
                self.occurences = temp
            }
        })
        .onAppear {
            if popRoot.tab == 3 {
                withAnimation {
                    self.popRoot.hideTabBar = true
                }
            }
            viewModel.refreshTime = 15
            if !title.isEmpty {
                viewModel.startGroupDev(groupId: title, uid: authViewModel.currentUser?.id ?? "", blocked: authViewModel.currentUser?.blockedUsers ?? [])
            } else {
                viewModel.start(group: group, uid: authViewModel.currentUser?.id ?? "", blocked: authViewModel.currentUser?.blockedUsers ?? [])
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: replying) { _, _ in
            if replying != nil {
                isFocused = true
            }
        }
        .onChange(of: editing) { _, _ in
            if editing != nil {
                isFocused = true
            }
        }
        .onChange(of: messageText) { _, _ in
            if !tag.isEmpty && !messageText.contains("@\(tag)") {
                tag = ""
            }
            if title.isEmpty {
                getHash()
                getStock()
            }
            messageTextError = inputChecker().myInputChecker(withString: messageText, withLowerSize: 1, withUpperSize: 1000, needsLower: false)
        }
        .onReceive(timer) { _ in
            if scenePhase == .active && !showSearchSheet {
                if (viewModel.refreshTime) > 0 {
                    viewModel.refreshTime -= 1
                } else {
                    viewModel.refreshTime = 15
                    if let index = viewModel.currentGroup {
                        if title.isEmpty {
                            viewModel.beginGroupConvoNew(groupId: viewModel.groups[index].1.id, devGroup: title.isEmpty ? false : true, userId: authViewModel.currentUser?.id ?? "", blocked: authViewModel.currentUser?.blockedUsers ?? [], square: viewModel.groups[index].0, initialFetch: false)
                        } else {
                            viewModel.beginGroupConvoNew(groupId: title, devGroup: title.isEmpty ? false : true, userId: authViewModel.currentUser?.id ?? "", blocked: authViewModel.currentUser?.blockedUsers ?? [], square: "", initialFetch: false)
                        }
                    }
                }
            }
            if viewModel.timeRemaining > 0 && viewModel.uploaded {
                withAnimation(.easeInOut){
                    viewModel.timeRemaining -= 1
                }
            } else if viewModel.uploaded {
                viewModel.uploaded = false
                viewModel.timeRemaining = 20
            }
        }
        .sheet(isPresented: $showAudioSheet, content: {
            audioView()
                .presentationDragIndicator(.hidden)
                .presentationDetents([.large])
                .presentationCornerRadius(40)
        })
        .sheet(isPresented: $showSettings) {
            VStack(alignment: .leading){
                if let index = viewModel.currentGroup {
                    HStack{
                        if viewModel.groups[index].1.leaders.contains(authViewModel.currentUser?.id ?? ""){
                            Button{
                                showEdit.toggle()
                            } label: {
                                HStack(spacing: 4){
                                    Image(systemName: "pencil").foregroundColor(.blue).font(.subheadline)
                                    Text("Edit Channel").foregroundColor(.blue).font(.subheadline)
                                }
                            }
                            .fullScreenCover(isPresented: $showEdit) {
                                EditGroupView(userId: authViewModel.currentUser?.id ?? "")
                            }
                        } else if viewModel.groups[index].1.members.contains(authViewModel.currentUser?.id ?? "") {
                            Button {
                                showLeave.toggle()
                            } label: {
                                optionButton(option: "Leave").frame(width: 65, height: 20)
                            }
                        }
                        Spacer()
                        Button {
                            copied = true
                            if viewModel.groups[index].1.publicstatus {
                                popRoot.hiddenMessage = "\(viewModel.groups[index].1.id)pub!@#$%^&*()\(viewModel.groups[index].1.title)"
                                UIPasteboard.general.string = "send group link"
                            } else {
                                popRoot.hiddenMessage = "\(viewModel.groups[index].1.id)priv!@#$%^&*()\(viewModel.groups[index].1.title)"
                                UIPasteboard.general.string = "send invite link"
                            }
                        } label: {
                            HStack(spacing: 2){
                                Text((viewModel.groups[index].1.publicstatus) ? "Group Link" : "Invite Link")
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                                Image(systemName: "square.on.square")
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                                    .scaleEffect(y: 0.7)
                            }
                        }
                        .alert("Confirm you want to leave \(viewModel.groups[index].1.title)", isPresented: $showLeave) {
                            Button("Confirm", role: .destructive) {
                                viewModel.leaveGroup(userId: authViewModel.currentUser?.id ?? "")
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal)
                    ScrollView {
                        HStack{
                            Text("Leaders").font(.title3).bold()
                            Spacer()
                        }
                        if let users = viewModel.groups[index].1.users {
                            ForEach(users){ user in
                                if viewModel.groups[index].1.leaders.contains(user.id ?? ""){
                                    HStack {
                                        UserRowViewSec(user: user, showFullName: false, showMessaging: true)
                                        if (user.id ?? "") == viewModel.groups[index].1.leaders.first {
                                            Image("g_owner")
                                                .resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 22)
                                        }
                                        Spacer()
                                        if (authViewModel.currentUser?.id ?? "") == viewModel.groups[index].1.leaders.first && (user.id ?? "") != viewModel.groups[index].1.leaders.first{
                                            Button {
                                                viewModel.demote(user: user.id ?? "")
                                            } label: {
                                                Text("demote").font(.caption).bold().foregroundColor(.red)
                                            }.padding(.trailing)
                                        }
                                    }
                                    .padding(.bottom, 6)
                                }
                            }.padding(.top, 8)
                        }
                        HStack{
                            Text("Members").font(.title3).bold().padding(.top)
                            Spacer()
                        }
                        if let users = viewModel.groups[index].1.users {
                            ForEach(users){ user in
                                if !viewModel.groups[index].1.leaders.contains(user.id ?? "") {
                                    HStack {
                                        UserRowViewSec(user: user, showFullName: false, showMessaging: true)
                                        Spacer()
                                        if viewModel.groups[index].1.leaders.contains(authViewModel.currentUser?.id ?? ""){
                                            Button {
                                                selectedUser = user.id ?? ""
                                                showPromote.toggle()
                                            } label: {
                                                Text("promote leader").font(.caption).bold().foregroundColor(.blue)
                                            }
                                            .padding(.trailing, 35)
                                            if !viewModel.groups[index].1.publicstatus {
                                                Button {
                                                    selectedUser = user.id ?? ""
                                                    showKick.toggle()
                                                } label: {
                                                    Text("kick").font(.caption).bold().foregroundColor(.red)
                                                }.padding(.trailing)
                                            }
                                        }
                                    }
                                    .padding(.bottom, 6)
                                    .alert(isPresented: $showKick) {
                                        SwiftUI.Alert(
                                            title: Text(""),
                                            message: Text("Are you sure you want to kick this user?"),
                                            primaryButton: .default(Text("Confirm"), action: {
                                                viewModel.kick(user: selectedUser)
                                            }),
                                            secondaryButton: .cancel(Text("Cancel"), action: {})
                                        )
                                    }
                                    .alert("Confirm promotion, this user will be able to modify this group", isPresented: $showPromote) {
                                        Button("Confirm", role: .destructive) {
                                            viewModel.promote(user: selectedUser)
                                        }
                                        Button("Cancel", role: .cancel) {}
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.leading)
                    if copied {
                        HStack{
                            Spacer()
                            ToastView(message: "Copied to clipboard")
                                .padding(.bottom)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        withAnimation{
                                            copied = false
                                        }
                                    }
                                }
                            Spacer()
                        }
                    }
                }
            }
            .dynamicTypeSize(.large)
            .presentationDetents([.fraction(0.8), .large])
        }
    }
    func storiesLeftToView(otherUID: String?) -> Bool {
        if let uid = authViewModel.currentUser?.id, let otherUID {
            if otherUID == uid {
                return false
            }
            if let stories = profileModel.users.first(where: { $0.user.id == otherUID })?.stories {
                
                for i in 0..<stories.count {
                    if let sid = stories[i].id {
                        if !messageModel.viewedStories.contains(where: { $0.0 == sid }) && !(stories[i].views ?? []).contains(where: { $0.contains(uid) }) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    @ViewBuilder
    func searchBarView() -> some View {
        HStack(spacing: 5){
            let count = occurences.isEmpty ? 0 : (occurIndex + 1)
            Text("\(count) of \(occurences.count) matches").font(.system(size: 17)).fontWeight(.regular)
            Spacer()
            Button(action: {
                if occurIndex < (occurences.count - 1) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    occurIndex += 1
                    viewModel.scrollToReplyNow = occurences[occurIndex]
                }
            }, label: {
                ZStack {
                    Rectangle().frame(width: 40, height: 40).foregroundStyle(.gray).opacity(0.001)
                    Image(systemName: "chevron.down").font(.title3).bold()
                        .foregroundStyle(occurIndex < (occurences.count - 1) ? (colorScheme == .dark ? .white : .black) : .gray)
                }
            })
            Button(action: {
                if occurIndex > 0 && !occurences.isEmpty {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    occurIndex -= 1
                    viewModel.scrollToReplyNow = occurences[occurIndex]
                }
            }, label: {
                ZStack {
                    Rectangle().frame(width: 40, height: 40).foregroundStyle(.gray).opacity(0.001)
                    Image(systemName: "chevron.up").font(.title3).bold()
                        .foregroundStyle(occurIndex > 0 && !occurences.isEmpty ? (colorScheme == .dark ? .white : .black) : .gray)
                }
            })
        }
        .padding(.horizontal).frame(height: 45).background(.ultraThickMaterial).transition(.move(edge: .bottom))
    }
    @ViewBuilder
    func searchHeader() -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10){
                TextField("Search Chat", text: $searchText)
                    .tint(.blue)
                    .autocorrectionDisabled(true)
                    .padding(8)
                    .padding(.horizontal, 24)
                    .background(.gray.opacity(0.25))
                    .cornerRadius(12)
                    .focused($searchBarFocused)
                    .onSubmit {
                        searchBarFocused = false
                        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            searchLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                                searchLoading = false
                            }
                        }
                    }
                    .overlay (
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            Spacer()
                            if searchLoading {
                                ProgressView().padding(.trailing, 10)
                            } else if !searchText.isEmpty {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    searchText = ""
                                }, label: {
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.001)
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.gray).font(.headline).bold()
                                    }.frame(width: 40, height: 40)
                                })
                            }
                        }.padding(.leading, 8)
                    )
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    searchBarFocused = false
                    searchText = ""
                    withAnimation(.easeInOut(duration: 0.2)){
                        searchChat = false
                    }
                }, label: {
                    Text("Cancel").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).fontWeight(.semibold)
                })
            }.padding(.bottom, 8)
        }
        .ignoresSafeArea()
        .padding(.horizontal, 12)
        .background(.ultraThickMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    func updateMessage() {
        if let index = viewModel.currentGroup, let edit = editing, !messageText.isEmpty {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if edit.originalText != messageText {
                if let pos1 = viewModel.groups[index].1.messages?.firstIndex(where: {$0.id == viewModel.groups[index].0}) {
                    if let pos2 = viewModel.groups[index].1.messages?[pos1].messages.firstIndex(where: { $0.id == edit.messageID }) {
                        viewModel.groups[index].1.messages?[pos1].messages[pos2].caption = messageText
                        if let editID = viewModel.groups[index].1.messages?[pos1].messages[pos2].id, let checkID = viewModel.groups[index].1.lastM?.id, editID == checkID {
                            viewModel.groups[index].1.lastM?.caption = messageText
                        }
                    }
                }
                ExploreService().editMessage(newText: messageText, groupId: viewModel.groups[index].1.id, textID: edit.messageID, square: viewModel.groups[index].0)
                viewModel.editedMessage = messageText
                viewModel.editedMessageID = edit.messageID
            }
            messageText = ""
            withAnimation(.easeIn(duration: 0.1)){
                editing = nil
            }
        }
    }
    func audioView() -> some View {
        ZStack {
            VStack {
                ZStack {
                    HStack {
                        Button(action: {
                            withAnimation {
                                cancelRecording()
                            }
                            showAudioSheet = false
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label: {
                            Text("Cancel").font(.headline)
                                .foregroundStyle(colorScheme == .dark ? .white : .black).opacity(0.9)
                        })
                        Spacer()
                        if recorder.recordings.first != nil || recorder.recording {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if recorder.recording {
                                    withAnimation {
                                        pauseRecording()
                                    }
                                }
                                showAudioSheet = false
                            }, label: {
                                Text("Done")
                                    .font(.system(size: 15))
                                    .foregroundStyle(colorScheme == .dark ? .black : .white).bold()
                                    .padding(.horizontal, 13).padding(.vertical, 8)
                                    .background {
                                        Capsule().foregroundStyle(colorScheme == .dark ? .white : .black).opacity(0.7)
                                    }
                            })
                        }
                    }
                    if recorder.recordings.first != nil || recorder.recording {
                        HStack(spacing: 4){
                            Spacer()
                            Circle().frame(width: 10)
                                .foregroundStyle(recorder.recording ? .red : .gray)
                                .animation(.easeInOut, value: currentTimeR)
                                .opacity(recorder.recording ? (Int(currentTimeR) % 2 == 0 ? 1 : 0) : 1.0)
                            Text(recorder.recording ? "Recording" : "Paused")
                                .font(.system(size: 20)).bold()
                            Spacer()
                        }
                    }
                }
                VStack(spacing: 10){
                    ZStack {
                        Circle().foregroundColor(Color(UIColor.lightGray))
                            .opacity(colorScheme == .dark ? 1.0 : 0.6)
                        Circle().foregroundColor(.blue).opacity(0.1)
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(Color(UIColor.darkGray))
                            .opacity(0.8)
                        if let url = authViewModel.currentUser?.profileImageUrl {
                            KFImage(URL(string: url))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        }
                    }.frame(width: 120, height: 120).padding(.top, 90)
                    if currentTimeR > 0 {
                        Text(currentTimeR.description).font(.subheadline).foregroundStyle(.gray)
                    }
                }
                if !(recorder.recordings.first != nil || recorder.recording) {
                    VStack(spacing: 4){
                        Text("What's happening?").font(.headline).foregroundStyle(.gray)
                        Text("Hit record").font(.headline).foregroundStyle(.gray).opacity(0.7)
                    }.padding(.top, 65)
                }
                Spacer()
            }.padding()
            if recorder.recordings.first != nil || recorder.recording {
                VStack {
                    Spacer()
                    HStack(spacing: 2){
                        ForEach(recorder.soundSamples, id: \.self) { level in
                            BarView(isRecording: true, value: recorder.recording ? normalizeSoundLevel(level: Float(level.sample)) : 2.0, sample: nil)
                        }
                    }.offset(y: 60)
                    Spacer()
                }
            }
            VStack {
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if recorder.recording {
                        withAnimation {
                            pauseRecording()
                        }
                    } else {
                        if currentTimeR < 120 {
                            withAnimation {
                                startRecording()
                            }
                        } else {
                            audioTooLong = true
                        }
                    }
                }, label: {
                    ZStack {
                        if recorder.recording {
                            Circle().stroke(.purple, lineWidth: 2)
                            Image(systemName: "pause").foregroundStyle(.purple)
                                .font(.system(size: 30)).bold()
                        } else {
                            Circle().foregroundStyle(.purple)
                            Circle().stroke(.white, lineWidth: 3)
                                .frame(width: 70, height: 70)
                            Image(systemName: "mic.fill").foregroundStyle(.white)
                                .font(.system(size: 30)).scaleEffect(y: 0.8)
                        }
                    }
                })
                .frame(width: 80, height: 80)
                .alert("Recording has reached max length", isPresented: $audioTooLong) {
                    Button("Okay", role: .cancel) { }
                }
            }.padding(.bottom, 60)
        }
    }
    func deleteRecording() {
        currentTimeR = 0
        DispatchQueue.main.async {
            self.recorder.recording = false
            self.recorder.recordings = []
        }
        recordingTimer?.invalidate()
        recorder.stopRecording()
    }
    func cancelRecording() {
        recordingTimer?.invalidate()
        recorder.recording = false
        recorder.stopRecording()
    }
    func pauseRecording() {
        recordingTimer?.invalidate()
        recorder.stopRecording()
        recorder.recording = false
        guard let tempUrl = UserDefaults.standard.string(forKey: "tempUrl") else { return }
        if let url = URL(string: tempUrl) {
            let newRecording = Recording(fileURL: url)
            recorder.recordings.append(newRecording)
            Task {
                await recorder.mergeAudios()
            }
        }
    }
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        var level = max(2.0, CGFloat(level) + 50)
        if level > 2.0 {
            level *= 1.1
        }
        return CGFloat(level)
    }
    private func startRecording() {
        recorder.recording = true
        recorder.startRecording()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            withAnimation {
                currentTimeR += 1
                if currentTimeR >= 120 {
                    pauseRecording()
                }
            }
        })
    }
    func uploadedView() -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 5)
                .frame(width: 40, height: 40)
            Circle()
                .trim(from: 0.0, to: CGFloat((20.0 - viewModel.timeRemaining) / 20.0))
                .stroke(getGradient(), lineWidth: 5)
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
            Text("\(Int(viewModel.timeRemaining))")
                .font(.system(size: 14))
                .bold()
                .foregroundColor(.primary)
        }
    }
    func sendContent(index: Int){
        if let user = authViewModel.currentUser {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.uploadMessage(caption: messageText, image: selectedImage, devGroup: title.isEmpty ? false : true, user: user, replyFrom: replying?.username, replyID: replying?.messageID, videoURL: selectedVideoURL, audioURL: recorder.recordings.first?.fileURL, fileData: fileData, pathE: pathExtension, memoryImage: memoryImage)
            if !tag.isEmpty {
                popRoot.alertImage = "tag.fill"
                popRoot.alertReason = "Tagged user notified"
                withAnimation {
                    popRoot.showAlert = true
                }
                
                viewModel.tagUserGroup(myUsername: user.username, otherUsername: tag, message: messageText, groupName: !title.isEmpty ? title : viewModel.groups[index].1.title)
                tag = ""
            }
            
            messageText = ""
            withAnimation(.easeInOut(duration: 0.1)){
                selectedImage = nil
                groupImage = nil
                selectedVideoURL = nil
                fileData = nil
                memoryImage = nil
            }
            deleteRecording()
            pathExtension = ""
            
            if !title.isEmpty {
                viewModel.uploaded = true
            } else if (user.elo < 600 && !viewModel.groups[index].1.leaders.contains(user.id ?? "") && viewModel.groups[index].1.publicstatus) {
                viewModel.uploaded = true
            }
        }
        replying = nil
    }
    func cantSend() -> some View {
        Button {
            showToast = true
        } label: {
            VStack{
                Divider().padding(.bottom, 8)
                HStack(spacing: 10){
                    ZStack {
                        Circle().frame(width: 40, height: 40).foregroundColor(Color.gray).opacity(0.3)
                        Image(systemName: "plus").resizable().frame(width: 22, height: 22)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                    TextField("Join Group...", text: .constant(""))
                        .disabled(true)
                        .padding(.vertical, 7)
                        .padding(.leading, 10)
                        .frame(minHeight: 40)
                        .background(content: {
                            RoundedRectangle(cornerRadius: 20).foregroundStyle(.gray).opacity(0.3)
                        })
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.bottom, 10)
            }
        }
    }
    func hashtags() -> some View {
        ScrollView {
            LazyVStack(spacing: 10){
                ForEach(0..<matchedHastags.count, id: \.self){ i in
                    if !matchedHastags[i].hasPrefix(":") {
                        Button {
                            replaceHash(new: matchedHastags[i])
                        } label: {
                            HStack(spacing: 10) {
                                ColorsCard(gradientColors: [randColors.randomElement() ?? .orange, .black], size: 45)
                                Text(matchedHastags[i]).font(.headline).bold()
                                Spacer()
                                if matchedHastags[i] == "Rules" {
                                    Text("IMPORTANT").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                                } else if matchedHastags[i] == "Main" {
                                    Text("welcome").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                                } else if matchedHastags[i] == "Info/Description" {
                                    Text("IMPORTANT").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                                } else {
                                    Text("square").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                                }
                            }.padding(.leading, 5).padding(.trailing, 12).frame(height: 40).padding(.top, 5)
                        }
                        Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray).padding(.leading, 55)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(height: matchedHastags.count > 3 ? 160.0 : (CGFloat(matchedHastags.count) * 50.0))
        .background(colorScheme == .dark ? Color(red: 66 / 255.0, green: 69 / 255.0, blue: 73 / 255.0) : Color(UIColor.lightGray))
        .animation(.easeOut, value: matchedHastags)
    }
    func stockPicker() -> some View {
        ScrollView {
            LazyVStack(spacing: 10){
                ForEach(0..<matchedStocks.count, id: \.self){ i in
                    Button {
                        replaceStock(new: matchedStocks[i])
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.up.and.down.and.sparkles").font(.headline).foregroundStyle(.green)
                            Text(matchedStocks[i].uppercased()).font(.headline).bold()
                            Spacer()
                            Text("Stock").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                        }.padding(.leading, 5).padding(.trailing, 12).frame(height: 40).padding(.top, 5)
                    }
                    Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray).padding(.leading, 55)
                }
            }.padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .frame(height: matchedStocks.count > 3 ? 160.0 : (CGFloat(matchedStocks.count) * 50.0))
        .background(colorScheme == .dark ? Color(red: 66 / 255.0, green: 69 / 255.0, blue: 73 / 255.0) : Color(UIColor.lightGray))
        .animation(.easeOut, value: matchedStocks)
    }
    func replaceStock(new: String){
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        messageText = replaceLastWord(originalString: messageText, newWord: ("$" + new.uppercased()))
        matchedStocks = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            matchedStocks = []
        }
    }
    func getStock(){
        let temp = stockModel.coins.map { String($0.symbol) } + stockModel.companyData.map { String($0.1) }
        let possible = Array(Set(temp))
        
        if let last = messageText.last, last == "$" {
            matchedStocks = possible
            return
        } else if let last = messageText.last, last == " " {
            matchedStocks = []
        } else {
            let words = messageText.components(separatedBy: " ")

            if var lastWord = words.last {
                if lastWord.hasPrefix("$") {
                    lastWord.removeFirst()
                    let query = lastWord.lowercased()
                    matchedStocks = possible.filter({ str in
                        str.lowercased().contains(query)
                    })
                } else {
                    matchedStocks = []
                }
            } else {
                matchedStocks = []
            }
        }
    }
    func replaceHash(new: String){
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        messageText = replaceLastWord(originalString: messageText, newWord: ("#" + new))
        matchedHastags = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            matchedHastags = []
        }
    }
    func getHash(){
        if let index = viewModel.currentGroup {
            let basic = ["Rules", "Main", "Info/Description"]
            var possible = basic + (viewModel.groups[index].1.squares ?? [])
            
            if let sub = viewModel.subContainers.first(where: { $0.0 == viewModel.groups[index].1.id }) {
                sub.1.forEach { element in
                    possible.append(contentsOf: element.sub)
                }
            }
            
            if let last = messageText.last, last == "#" {
                matchedHastags = possible
                return
            } else if let last = messageText.last, last == " " {
                matchedHastags = []
            } else {
                let words = messageText.components(separatedBy: " ")

                if var lastWord = words.last {
                    if lastWord.hasPrefix("#") {
                        lastWord.removeFirst()
                        let query = lastWord.lowercased()
                        matchedHastags = possible.filter({ str in
                            str.lowercased().contains(query)
                        })
                    } else {
                        matchedHastags = []
                    }
                } else {
                    matchedHastags = []
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
    private func getGradient() -> LinearGradient {
          return LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .topTrailing, endPoint: .bottomLeading)
    }
    @ViewBuilder
    func HeaderView() -> some View {
        let headerHeight = (widthOrHeight(width: false) * 0.25) + top_Inset()
        let minimumHeaderHeight = 65 + top_Inset()
        let progress = max(min(-offsetY / (headerHeight - minimumHeaderHeight), 1), 0)
        ZStack{
            GeometryReader { _ in
                ZStack {
                    Rectangle().fill(Color.gray.opacity(0.7).gradient)
                    VStack(spacing: 15) {
                        GeometryReader {
                            let rect = $0.frame(in: .global)
                            let halfScaledHeight = (rect.height * 0.3) * 0.5
                            let midY = rect.midY
                            let bottomPadding: CGFloat = 15
                            let resizedOffsetY = (midY - (minimumHeaderHeight - halfScaledHeight - bottomPadding))
                            
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: rect.width, height: rect.height)
                                .scaleEffect(title == "Services" ? (1 - (progress * 0.7)) * 0.7 : 1 - (progress * 0.7), anchor: .leading)
                                .offset(x: -(rect.minX - 15) * progress, y: -resizedOffsetY * progress)
                                .offset(x: title == "Services" ? 24 : 0)
                                .padding(.leading, progress == 1 ? 10 : 0)
                        }
                        .frame(width: headerHeight * 0.5, height: headerHeight * 0.5)
                        
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .moveText(progress, headerHeight, minimumHeaderHeight)
                    }
                    .padding(.top, top_Inset())
                    .padding(.bottom, 15)
                }
                .frame(height: (headerHeight + offsetY) < minimumHeaderHeight ? minimumHeaderHeight : (headerHeight + offsetY), alignment: .bottom)
            }
            .frame(height: progress <= 0 ? headerHeight : (headerHeight + offsetY) < minimumHeaderHeight ? minimumHeaderHeight : (headerHeight + offsetY))
            HStack(alignment: .top){
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if remTab {
                        withAnimation {
                            self.popRoot.hideTabBar = false
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark").resizable()
                }.frame(width: 25, height:25)
            }
            .offset(y: -40 + (progress * (60)))
            .padding(.trailing, 30)
        }
    }
}

fileprivate extension View {
    func moveText(_ progress: CGFloat, _ headerHeight: CGFloat, _ minimumHeaderHeight: CGFloat) -> some View {
        self
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    let rect = proxy.frame(in: .global)
                    let midY = rect.midY
                    let halfScaledTextHeight = (rect.height * 0.85) / 2
                    let profileImageHeight = (headerHeight * 0.5)
                    let scaledImageHeight = profileImageHeight * 0.3
                    let halfScaledImageHeight = scaledImageHeight / 2
                    let vStackSpacing: CGFloat = 4.5
                    let resizedOffsetY = (midY - (minimumHeaderHeight - halfScaledTextHeight - vStackSpacing - halfScaledImageHeight))
                    
                    self
                        .scaleEffect(1 - (progress * 0.15))
                        .offset(y: -resizedOffsetY * progress)
                }
            }
    }
}

func replaceLastWord(originalString: String, newWord: String) -> String {
    var words = originalString.components(separatedBy: " ")

    guard !words.isEmpty else {
        return originalString
    }

    words[words.count - 1] = newWord
    let resultString = words.joined(separator: " ")
    
    return resultString
}
