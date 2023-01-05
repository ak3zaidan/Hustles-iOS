import SwiftUI
import Combine
import Photos
import Firebase
import AVFoundation

struct VideoPreviewMessage: View {
    var url: URL
    @Binding var showPreview: Bool
    @State var muted = false
    @State var savedPhoto = false
    @State var caption = ""
    @State var point: CGFloat = 0.0
    @State var showKeyboard = false
    @State var pauseVideo = false
    @State var playVideo = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @FocusState var focusField: FocusedField?
    @FocusState private var focusFieldSec: FocusedField?
    @EnvironmentObject var auth: AuthViewModel
    let manager = GlobeLocationManager()
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var groupChats: GroupChatViewModel
    @EnvironmentObject var groupViewModel: GroupViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var globe: GlobeViewModel
    @State private var currentTime: Double = 0.0
    @State private var totalLength: Double = 1.0
    @State private var random: CGFloat = 0.0
    @State var addToStory = false
    @State var sendNow = false
    @State var infinite = false
    @Binding var initialSend: messageSendType?
    
    @State private var closeNow = false
    @State var viewOffset: CGFloat = 0.0
    @State var dismissOpacity: CGFloat = 0.0
    let isMain: Bool
    @State private var savedMemory = false
    @State var preSavedUrlString: String? = nil
    
    @Binding var memoryVideo: URL?
    
    var body: some View {
        ZStack {
            ZStack {
                Color.black.ignoresSafeArea()
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded { loc in
                                if focusField == .one {
                                    focusField = .two
                                    withAnimation {
                                        showKeyboard = false
                                    }
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                } else {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if point == 0.0 {
                                        point = widthOrHeight(width: false) * 0.4
                                    }
                                    withAnimation {
                                        showKeyboard = true
                                    }
                                    focusField = .one
                                }
                            }
                    )
                
                MainVideoPlayer(url: url, muted: $muted, currentTime: $currentTime, totalLength: $totalLength, canClose: false, offSetY: $random, playVid: $playVideo, pauseVid: $pauseVideo, shouldPlayAppear: true)
                    .offset(y: isMain ? 0 :  -(top_Inset() / 2))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(content: {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(.gray, lineWidth: 1.0).opacity(isMain ? 0.0 : 0.5)
                    })
                    .disabled(true)
                    .ignoresSafeArea(.keyboard)
                    .padding(.bottom, isMain ? bottom_Inset() : 0)
                    .highPriorityGesture (
                        TapGesture()
                            .onEnded { loc in
                                if focusField == .one {
                                    focusField = .two
                                    withAnimation {
                                        showKeyboard = false
                                    }
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                } else {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if point == 0.0 {
                                        point = widthOrHeight(width: false) * 0.4
                                    }
                                    withAnimation {
                                        showKeyboard = true
                                    }
                                    focusField = .one
                                }
                            }
                    )
                    .offset(y: viewOffset)
                    .gesture(DragGesture()
                        .onChanged({ val in
                            if !isMain {
                                if (val.translation.height > 0.0 && val.translation.height < 90.0) || (viewOffset >= 0.0 && viewOffset < 90.0) {
                                    viewOffset = val.translation.height
                                    
                                    dismissOpacity = viewOffset / 130.0
                                    
                                    if viewOffset > 80.0 {
                                        if !closeNow {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            closeNow = true
                                        }
                                    } else if closeNow {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        closeNow = false
                                    }
                                }
                            }
                        })
                        .onEnded({ val in
                            if !isMain {
                                if val.translation.height > 80.0 {
                                    withAnimation(.easeIn(duration: 0.15)){
                                        showPreview = false
                                        memoryVideo = nil
                                    }
                                } else {
                                    closeNow = false
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        dismissOpacity = 0.0
                                        viewOffset = 0.0
                                    }
                                }
                            }
                        })
                    )
                    .padding(.bottom, isMain ? bottom_Inset() : 0)
                
                if !caption.isEmpty || showKeyboard {
                    VStack {
                        Spacer()
                        keyboardImage()
                            .offset(y: focusField == .one ? 0.0 : -point)
                            .gesture (
                                DragGesture()
                                    .onChanged { gesture in
                                        let screenH = widthOrHeight(width: false)
                                        let max = screenH * 0.85
                                        let min = screenH * 0.18
                                        let val = abs(gesture.location.y)
                                        if val > min && val < max {
                                            point = val
                                        }
                                    }
                            )
                    }.KeyboardAwarePadding().ignoresSafeArea()
                }
                
                VStack {
                    HStack(alignment: .top){
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeIn(duration: 0.15)){
                                showPreview = false
                                memoryVideo = nil
                            }
                        } label: {
                            ZStack {
                                Circle().frame(width: 47, height: 47)
                                    .foregroundStyle(viewOffset > 80.0 ? Color.white : Color.black.opacity(0.7))
                                Image(systemName: "xmark")
                                    .foregroundColor(viewOffset > 80.0 ? .black : .white)
                            }
                        }
                        Spacer()
                        Text("Dismiss")
                            .padding(.top, 10)
                            .font(.title3).bold().foregroundStyle(.white)
                            .opacity(viewOffset > 80.0 ? 1.0 : dismissOpacity)
                        Spacer()
                        VStack(spacing: 20){
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if focusField == .one {
                                    focusField = .two
                                    withAnimation {
                                        showKeyboard = false
                                    }
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                } else {
                                    if point == 0.0 {
                                        point = widthOrHeight(width: false) * 0.4
                                    }
                                    withAnimation {
                                        showKeyboard = true
                                    }
                                    focusField = .one
                                }
                            } label: {
                                ZStack {
                                    Circle().frame(width: 47, height: 47)
                                        .foregroundStyle(focusField == .one ? .yellow.opacity(0.6) : Color.black.opacity(0.7))
                                    Text("T")
                                        .foregroundColor(.white).bold().font(.system(size: 23))
                                }
                            }
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                muted.toggle()
                            } label: {
                                ZStack {
                                    Circle().frame(width: 47, height: 47).foregroundStyle(Color.black.opacity(0.7))
                                    Image(systemName: muted ? "speaker.slash" : "speaker.wave.2")
                                        .foregroundColor(.white).font(.system(size: 23))
                                }
                            }
                            Menu {
                                Section("Time Limit") { }
                                Divider()
                                Button {
                                    infinite = true
                                } label: {
                                    Label("Infinite", systemImage: "infinity")
                                }
                                Button(role: .destructive) {
                                    infinite = false
                                } label: {
                                    Label("48 Hours", systemImage: "timer")
                                }
                            } label: {
                                ZStack {
                                    Circle().frame(width: 47, height: 47).foregroundStyle(Color.black.opacity(0.7))
                                    Image(systemName: infinite ? "infinity" : "timer")
                                        .foregroundColor(.white).font(.system(size: 23))
                                }
                            }
                            Spacer()
                        }
                        .opacity(viewOffset == 0.0 ? 1.0 : 0.0)
                        .animation(.easeIn, value: viewOffset)
                    }.padding(.horizontal, 20).padding(.top, 80)
                    Spacer()
                    ZStack(alignment: .top){
                        Rectangle().cornerRadius(30, corners: [.topLeft, .topRight]).foregroundStyle(.ultraThinMaterial)
                        HStack(spacing: 5){
                            if memoryVideo != nil {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        savedPhoto = true
                                    }
                                    PHPhotoLibrary.shared().performChanges({
                                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.url)
                                    }) { saved, error in }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }, label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                        Image(systemName: savedPhoto ? "checkmark.icloud" : "square.and.arrow.down")
                                            .contentTransition(.symbolEffect(.replace))
                                            .foregroundStyle(savedPhoto ? .blue : .white)
                                            .font(.system(size: 20)).bold()
                                            .offset(y: savedPhoto ? 0 : -3)
                                    }
                                }).frame(width: 45)
                            } else {
                                Menu {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)){
                                            savedPhoto = true
                                        }
                                        PHPhotoLibrary.shared().performChanges({
                                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.url)
                                        }) { saved, error in }
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }, label: {
                                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                                    })
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        withAnimation(.easeInOut(duration: 0.2)){
                                            savedPhoto = true
                                        }
                                        if !savedMemory {
                                            savedMemory = true
                                            ImageUploader.uploadVideoToFB(localVideoURL: self.url) { opLoc in
                                                if let video = opLoc {
                                                    preSavedUrlString = video
                                                    popRoot.alertReason = "Memory Saved"
                                                    popRoot.alertImage = "checkmark"
                                                    withAnimation(.easeInOut(duration: 0.2)){
                                                        popRoot.showAlert = true
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
                                                } else {
                                                    popRoot.alertReason = "Memory Save Error!"
                                                    popRoot.alertImage = "exclamationmark.bubble.fill"
                                                    withAnimation(.easeInOut(duration: 0.2)){
                                                        popRoot.showAlert = true
                                                    }
                                                }
                                            }
                                        } else {
                                            popRoot.alertReason = "Memory Saved"
                                            popRoot.alertImage = "checkmark"
                                            withAnimation(.easeInOut(duration: 0.2)){
                                                popRoot.showAlert = true
                                            }
                                        }
                                    }, label: {
                                        Label("Save to Memories", image: "memory")
                                    })
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                        Image(systemName: savedPhoto ? "checkmark.icloud" : "square.and.arrow.down")
                                            .contentTransition(.symbolEffect(.replace))
                                            .foregroundStyle(savedPhoto ? .blue : .white)
                                            .font(.system(size: 20)).bold()
                                            .offset(y: savedPhoto ? 0 : -3)
                                    }
                                }.frame(width: 45)
                            }
                            if let pre = initialSend {
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    sendNow = true
                                    pauseVideo.toggle()
                                    viewModel.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 50)
                                            .stroke(Color(UIColor.lightGray), lineWidth: 1)
                                        Text("+ More Friends")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 12)).bold()
                                    }
                                }.frame(width: 95)
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    sendContent(pre: pre)
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 50)
                                            .stroke(.blue, lineWidth: 1)
                                        HStack {
                                            Text(pre.title).font(.headline).bold()
                                            Image(systemName: "paperplane")
                                                .rotationEffect(.degrees(45.0))
                                                .font(.system(size: 22)).bold()
                                        }.foregroundStyle(.white)
                                    }
                                }
                            } else {
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    addToStory.toggle()
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 50)
                                            .foregroundStyle(addToStory ? Color.green.opacity(0.6) : Color(UIColor.lightGray))
                                        Text("Add Story")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 18)).bold()
                                    }
                                }
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    sendNow = true
                                    pauseVideo.toggle()
                                    viewModel.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 50).foregroundStyle(.blue.opacity(0.6))
                                        HStack {
                                            Text("Send To")
                                                .font(.system(size: 18)).bold()
                                            Image(systemName: "arrowtriangle.right.fill")
                                                .font(.system(size: 16)).bold()
                                        }.foregroundStyle(.white)
                                    }
                                }
                            }
                        }.frame(height: 40).padding(6).padding(.horizontal)
                    }
                    .frame(height: 95)
                    .opacity(viewOffset == 0.0 ? 1.0 : 0.0)
                    .animation(.easeIn, value: viewOffset)
                }.ignoresSafeArea()
            }
        }
        .background(.black).ignoresSafeArea(.keyboard)
        .overlay(content: {
            if sendNow {
                SendToPeopleSec(showThisView: $sendNow, video: url, caption: caption, addToStory: $addToStory, position: point, muted: muted, infinite: infinite, initialSend: $initialSend, isMain: isMain, preSavedUrlString: preSavedUrlString ?? memoryVideo?.absoluteString)
                    .transition(.move(edge: .trailing))
            }
        })
        .onChange(of: sendNow) { _, _ in
            if !sendNow {
                playVideo.toggle()
            }
        }
    }
    func sendContent(pre: messageSendType) {
        if isMain {
            viewModel.navigateOut.toggle()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
        if let final = memoryVideo?.absoluteString ?? preSavedUrlString, !final.isEmpty {
            sendMainContent(final: final, pre: pre)
        } else {
            ImageUploader.uploadVideoToFirebaseStorage(localVideoURL: url) { link in
                if let final = link, !final.isEmpty {
                    sendMainContent(final: final, pre: pre)
                } else {
                    popRoot.chatSentError = true
                    popRoot.chatAlertID = UUID().uuidString
                    withAnimation {
                        popRoot.chatSentAlert = true
                    }
                }
            }
        }
    }
    func sendMainContent(final: String, pre: messageSendType) {
        popRoot.chatSentError = false
        popRoot.chatAlertID = UUID().uuidString
        withAnimation {
            popRoot.chatSentAlert = true
        }
        if pre.type == 1 {
            let uid = Auth.auth().currentUser?.uid ?? ""
            let uid_prefix = String(uid.prefix(5))
            let id = uid_prefix + String("\(UUID())".prefix(15))
            
            if let index = viewModel.chats.firstIndex(where: { $0.id == pre.id }) {
                if viewModel.chats[index].user.id != "lQTwtFUrOMXem7UXesJbDMLbV902" {
                    let new = Message(id: id, uid_one_did_recieve: (viewModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? false : true, seen_by_reciever: false, text: caption.isEmpty ? nil : caption, imageUrl: nil, timestamp: Timestamp(), sentAImage: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: final)
                    
                    viewModel.sendStory(i: index, myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: viewModel.chats[index].user.id ?? "", caption: caption, imageUrl: nil, videoUrl: final, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: nil)
                    
                    viewModel.chats[index].lastM = new
                    
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    }
                }
            }
        } else if pre.type == 2 {
            let id = String((auth.currentUser?.id ?? "").prefix(6)) + String("\(UUID())".prefix(10))
            
            let new = GroupMessage(id: id, seen: nil, text: caption.isEmpty ? nil : caption, imageUrl: nil, audioURL: nil, videoURL: final, file: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyFile: nil, replyAudio: nil, replyVideo: nil, countSmile: nil, countCry: nil, countThumb: nil, countBless: nil, countHeart: nil, countQuestion: nil, timestamp: Timestamp())
            
            if let index = groupChats.chats.firstIndex(where: { $0.id == pre.id }) {
                GroupChatService().sendMessage(docID: pre.id, text: caption, imageUrl: nil, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: final, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                
                groupChats.chats[index].lastM = new

                groupChats.chats[index].messages?.insert(new, at: 0)
            }
        } else {
            groupViewModel.uploadStoryVideo(caption: caption, video: final, groupID: pre.id, username: auth.currentUser?.username ?? "", profileP: auth.currentUser?.profileImageUrl)
        }
    }
    func keyboardImage() -> some View {
        VStack {
            TextField("", text: $caption, axis: .vertical)
                .focused($focusField, equals: .one)
                .tint(.white)
                .lineLimit(5)
                .submitLabel(.done)
                .padding(.vertical, 6)
                .padding(.horizontal)
                .frame(minHeight: 35)
                .onSubmit {
                    withAnimation {
                        showKeyboard = false
                        focusField = .two
                    }
                }
                .onChange(of: caption) { _, _ in
                    if caption.contains("\n") {
                        caption.removeAll(where: { $0.isNewline })
                        focusField = .two
                        withAnimation {
                            showKeyboard = false
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    if caption.count > 300 {
                        caption = String(caption.prefix(300))
                    }
                }
        }
        .frame(width: widthOrHeight(width: true))
        .background {
            TransparentBlurView(removeAllFilters: true)
                .blur(radius: 9, opaque: true).background(.black.opacity(0.4))
        }
    }
}
