import SwiftUI
import Firebase
import UniformTypeIdentifiers
import Kingfisher
import AudioToolbox

struct GroupChatField: View {
    let generator = UINotificationFeedbackGenerator()
    @EnvironmentObject var viewModel: GroupChatViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var showFilePicker: Bool
    @Binding var showCameraPicker: Bool
    @Binding var showLibraryPicker: Bool
    @FocusState.Binding var isFocused: Bool
    @Binding var replying: replyToGroup?
    @Binding var addAudio: Bool
    
    @State var fileData: Data? = nil
    @State var pathExtension: String = ""
    @State var selectedImage: UIImage? = nil
    @State var messageImage: Image? = nil
    @EnvironmentObject var stockModel: StockViewModel
    @EnvironmentObject var recorder: AudioRecorderG
    @State private var recordingTimer: Timer?
    @State private var currentTimeR = 0
    @State private var audioTooLong = false
    @State var selectedVideoURL: URL?
    @State private var playing = true
    @State var bounceSend = false
    @State var muted = false
    @State private var currentTime: Double = 0.0
    @State private var totalLength: Double = 1.0
    @State var captionID: String = ""
    @Binding var editing: Editing?
    @Binding var currentAudio: String
    @Binding var searchText: String
    @Binding var showSearch: Bool
    @State var occurences = [String]()
    @State var occurIndex = 0
    @Binding var showMemoryPicker: Bool
    @State var memoryImage: String? = nil
    @State var memoryVideo: URL? = nil
    @Binding var captionBind: String
    @Binding var matchedStocks: [String]
    
    var body: some View {
        VStack {
            if messageImage != nil || fileData != nil || !recorder.recordings.isEmpty || selectedVideoURL != nil || memoryVideo != nil || memoryImage != nil {
                HStack(alignment: .bottom, spacing: 15){
                    Spacer()
                    if fileData != nil {
                        HStack(spacing: 10){
                            VStack(alignment: .leading){
                                Text("File attached").font(.system(size: 18))
                                    .bold().foregroundStyle(colorScheme == .dark ? .white : .black)
                                Text("Type: \(pathExtension)").font(.system(size: 15))
                                    .foregroundStyle(.gray)
                            }
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)){
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
                    } else if let image = messageImage {
                        ZStack(alignment: .topTrailing){
                            ZStack(alignment: .bottomLeading){
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                if let image = selectedImage {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                                    } label: {
                                        ZStack {
                                            Circle().foregroundColor(.gray)
                                            Image(systemName: "square.and.arrow.down").resizable().frame(width: 17, height: 17)
                                                .foregroundColor(.white).offset(y: -2)
                                        }
                                    }.frame(width: 25, height: 25).padding(.bottom, 5).padding(.leading, 5)
                                }
                            }
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)){
                                    selectedImage = nil
                                    messageImage = nil
                                }
                            } label: {
                                ZStack {
                                    Circle().foregroundColor(.gray)
                                    Image(systemName: "xmark").resizable().frame(width: 14, height: 14)
                                        .foregroundColor(.white)
                                }
                            }.frame(width: 25, height: 25).padding(.top, 5).padding(.trailing, 5)
                        }
                    } else if let image = memoryImage {
                        ZStack(alignment: .topTrailing){
                            KFImage(URL(string: image))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)){
                                    memoryImage = nil
                                }
                            } label: {
                                ZStack {
                                    Circle().foregroundColor(.gray)
                                    Image(systemName: "xmark").resizable().frame(width: 14, height: 14)
                                        .foregroundColor(.white)
                                }
                            }.frame(width: 25, height: 25).padding(.top, 5).padding(.trailing, 5)
                        }
                    } else if let url = selectedVideoURL ?? memoryVideo {
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
                                            withAnimation(.easeInOut(duration: 0.2)){
                                                memoryVideo = nil
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
                            .frame(maxWidth: 200, maxHeight: 200, alignment: .trailing)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if let first = recorder.recordings.first {
                        MessageAudioPView(audioUrl: first.fileURL, empty: $recorder.recordings, currentAudio: $currentAudio, onClose: {
                            deleteRecording()
                        })
                    }
                }.padding(.trailing, 10).padding(.bottom, 2)
            }
            
            if showSearch {
                searchBarView()
            } else if isFocused && !matchedStocks.isEmpty {
                stockPicker()
                    .overlay(alignment: .bottom, content: {
                        Divider()
                    })
                    .padding(.bottom, 5)
                    .transition(.move(edge: .bottom))
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
                        withAnimation(.easeIn(duration: 0.1)){
                            replying = nil
                        }
                    }, label: {
                        Image(systemName: "xmark.circle.fill").font(.headline).foregroundStyle(colorScheme == .dark ? .white : .gray)
                    }).padding(.trailing)
                }
                .contentShape(Rectangle())
                .frame(height: 36)
                .overlay(alignment: .bottom, content: {
                    Divider()
                })
                .padding(.bottom, 5)
                .transition(.move(edge: .bottom))
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
                .contentShape(Rectangle())
                .frame(height: 40)
                .overlay(alignment: .bottom, content: {
                    Divider()
                })
                .padding(.bottom, 5)
                .transition(.move(edge: .bottom))
                .onTapGesture {
                    viewModel.scrollToReply = edit.messageID
                }
            }
            
            if !showSearch {
                HStack(alignment: .bottom, spacing: 10){
                    Spacer()
                    if let index = viewModel.currentChat {
                        ZStack(alignment: .leading){
                            if captionBind.isEmpty {
                                Text("Message")
                                    .opacity(0.5)
                                    .offset(x: 15)
                                    .foregroundColor(.gray)
                                    .font(.system(size: 17))
                            }
                            TextField("", text: $captionBind, axis: .vertical)
                                .tint(.blue)
                                .lineLimit(5)
                                .padding(.leading)
                                .focused($isFocused)
                                .padding(.trailing, 4)
                                .frame(minHeight: 40)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20).stroke(.gray, lineWidth: 1)
                                }
                        }
                        .frame(width: widthOrHeight(width: true) * 0.72)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .background(colorScheme == .dark ? .black : Color("gray"))
                        .cornerRadius(20)
                        .onChange(of: captionBind) { _, new in
                            handleTextChange(newValue: new)
                            getStock()
                        }
                        .onAppear {
                            withAnimation {
                                self.captionBind = viewModel.chats[index].chatText ?? ""
                            }
                            self.captionID = viewModel.chats[index].id ?? ""
                        }
                        .onDisappear {
                            if index < viewModel.chats.count && captionID == (viewModel.chats[index].id ?? "") {
                                DispatchQueue.main.async {
                                    viewModel.chats[index].chatText = self.captionBind
                                }
                            }
                        }
                        
                        if editing != nil {
                            Button {
                                updateMessage()
                            } label: {
                                ZStack {
                                    Circle().foregroundColor(Color.gray).opacity(0.3)
                                    Image(systemName: "pencil")
                                        .symbolEffect(.bounce, value: bounceSend)
                                        .font(.system(size: 24))
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                }.frame(width: 40, height: 40)
                            }
                            .padding(.bottom, 1)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.1)){
                                    bounceSend.toggle()
                                }
                            }
                        } else if !captionBind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil || !recorder.recordings.isEmpty || selectedVideoURL != nil || fileData != nil || memoryVideo != nil || memoryImage != nil {
                            Button {
                                sendMessageNow()
                            } label: {
                                ZStack {
                                    Circle().foregroundColor(Color.orange).opacity(0.7)
                                    Image(systemName: "paperplane.fill")
                                        .symbolEffect(.bounce, value: bounceSend)
                                        .font(.system(size: 20))
                                        .offset(x: -1).offset(y: 1)
                                        .rotationEffect(.degrees(45.0))
                                        .foregroundColor(colorScheme == .dark ? .black : .white)
                                }.frame(width: 40, height: 40)
                            }
                            .padding(.bottom, 1)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.1)){
                                    bounceSend.toggle()
                                }
                            }
                        } else {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                addAudio.toggle()
                            } label: {
                                ZStack {
                                    Circle().foregroundColor(Color.gray).opacity(0.3)
                                    
                                    Image(systemName: "mic.fill")
                                        .symbolEffect(.bounce, value: bounceSend)
                                        .font(.system(size: 24)).scaleEffect(y: 0.85)
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    
                                }.frame(width: 40, height: 40)
                            }
                            .padding(.bottom, 1)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.1)){
                                    bounceSend.toggle()
                                }
                            }
                        }
                    }
                }
                .padding(.trailing, 8).padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showMemoryPicker, content: {
            MemoryPickerSheetView(photoOnly: false, maxSelect: 1) { allData in
                allData.forEach { element in
                    if element.isImage {
                        self.memoryImage = element.urlString
                    } else if let url = URL(string: element.urlString){
                        self.memoryVideo = url
                    }
                }
            }
        })
        .sheet(isPresented: $addAudio, content: {
            if #available(iOS 16.4, *){
                audioView()
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.large])
                    .presentationCornerRadius(40)
            } else {
                audioView()
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.large])
            }
        })
        .fullScreenCover(isPresented: $showCameraPicker, content: {
            UploadHustleCamera(selectedImage: $selectedImage, hustleImage: $messageImage, selectedVideoURL: $selectedVideoURL, isImagePickerPresented: $showCameraPicker)
        })
        .fullScreenCover(isPresented: $showLibraryPicker, content: {
            HustlePickerView(selectedImage: $selectedImage, hustleImage: $messageImage, selectedVideoURL: $selectedVideoURL, isImagePickerPresented: $showLibraryPicker, canAddVid: true)
        })
        .onChange(of: editing) { old, new in
            if let newVal = new {
                if old == nil {
                    if captionBind.isEmpty {
                        captionBind = newVal.originalText
                    }
                } else {
                    captionBind = newVal.originalText
                }
            }
        }
        .onChange(of: memoryImage) { _, _ in
            if memoryImage != nil {
                deleteRecording()
                messageImage = nil
                selectedImage = nil
                fileData = nil
                memoryVideo = nil
                selectedVideoURL = nil
            }
        }
        .onChange(of: memoryVideo) { _, _ in
            if memoryVideo != nil {
                deleteRecording()
                messageImage = nil
                selectedImage = nil
                fileData = nil
                memoryImage = nil
                selectedVideoURL = nil
            }
        }
        .onChange(of: selectedImage) { _, _ in
            if selectedImage != nil {
                selectedVideoURL = nil
                deleteRecording()
                fileData = nil
                memoryImage = nil
                memoryVideo = nil
            }
        }
        .onChange(of: selectedVideoURL) { _, _ in
            if selectedVideoURL != nil {
                deleteRecording()
                messageImage = nil
                selectedImage = nil
                fileData = nil
                memoryImage = nil
                memoryVideo = nil
            }
        }
        .onChange(of: recorder.recordings) { _, _ in
            if !recorder.recordings.isEmpty {
                messageImage = nil
                selectedImage = nil
                fileData = nil
                selectedVideoURL = nil
                memoryImage = nil
                memoryVideo = nil
            }
        }
        .onChange(of: fileData) { _, _ in
            if fileData != nil {
                messageImage = nil
                selectedImage = nil
                selectedVideoURL = nil
                deleteRecording()
                memoryImage = nil
                memoryVideo = nil
            }
        }
        .onChange(of: showSearch, { _, new in
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
            
            if let index = viewModel.currentChat {
                let messages = viewModel.chats[index].messages ?? []
                
                messages.forEach { element in
                    if let id = element.id, (element.text ?? "").lowercased().contains(searchText.lowercased()) {
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
    }
    @ViewBuilder
    func searchBarView() -> some View {
        HStack(spacing: 5){
            let count = occurences.isEmpty ? 0 : (occurIndex + 1)
            Text("\(count) of \(occurences.count) matches").font(.system(size: 17)).fontWeight(.regular)
            Spacer()
            Button(action: {
                if occurIndex > 0 && !occurences.isEmpty {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    occurIndex -= 1
                    viewModel.scrollToReplyNow = occurences[occurIndex]
                }
            }, label: {
                ZStack {
                    Rectangle().frame(width: 40, height: 40).foregroundStyle(.gray).opacity(0.001)
                    Image(systemName: "chevron.down").font(.title3).bold()
                        .foregroundStyle(occurIndex > 0 && !occurences.isEmpty ? (colorScheme == .dark ? .white : .black) : .gray)
                }
            })
            Button(action: {
                if occurIndex < (occurences.count - 1) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    occurIndex += 1
                    viewModel.scrollToReplyNow = occurences[occurIndex]
                }
            }, label: {
                ZStack {
                    Rectangle().frame(width: 40, height: 40).foregroundStyle(.gray).opacity(0.001)
                    Image(systemName: "chevron.up").font(.title3).bold()
                        .foregroundStyle(occurIndex < (occurences.count - 1) ? (colorScheme == .dark ? .white : .black) : .gray)
                }
            })
        }
        .padding(.horizontal).frame(height: 45).transition(.move(edge: .bottom))
    }
    func updateMessage() {
        if let index = viewModel.currentChat, let edit = editing, !captionBind.isEmpty {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if edit.originalText != captionBind {
                GroupChatService().editMessage(newText: captionBind, docID: viewModel.chats[index].id ?? "", textID: edit.messageID)
                if let pos = viewModel.chats[index].messages?.firstIndex(where: { $0.id == edit.messageID }) {
                    viewModel.chats[index].messages?[pos].text = captionBind
                    if pos == 0 {
                        viewModel.chats[index].lastM?.text = captionBind
                    }
                }
                viewModel.editedMessage = captionBind
                viewModel.editedMessageID = edit.messageID
            }
            captionBind = ""
            withAnimation(.easeIn(duration: 0.1)){
                editing = nil
            }
        }
    }
    func sendMessageNow(){
        if let index = viewModel.currentChat {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            let uid = Auth.auth().currentUser?.uid ?? ""
            let uid_prefix = String(uid.prefix(6))
            
            var replyFrom, replyText, replyImage, replyFile, replyVideo, replyAudio: String?
            
            if let rep = replying, let temp = viewModel.chats[index].messages?.first(where: {$0.id == rep.messageID}) {
                replyFrom = rep.selfReply ? auth.currentUser?.username ?? "You Replied" : rep.username
                if let text = temp.text, !text.isEmpty {
                    replyText = text
                } else if let pic = temp.imageUrl {
                    replyImage = pic
                } else if let file_temp = temp.file {
                    replyFile = file_temp
                } else if let video_temp = temp.videoURL {
                    replyVideo = video_temp
                } else if let audio_temp = temp.audioURL {
                    replyAudio = audio_temp
                } else if let lat = temp.lat, let long = temp.long {
                    let name = temp.name ?? "Location"
                    replyText = "https://hustle.page/location/lat=\(lat),long=\(long),name=\(name.trimmingCharacters(in: .whitespacesAndNewlines))"
                } else if let pinmap = temp.pinmap {
                    replyText = pinmap
                }
            }
            
            let id = uid_prefix + String("\(UUID())".prefix(10))
            let text = captionBind
            let sImage = selectedImage
            let fData = fileData
            let sVidU = selectedVideoURL
            let audFirst = recorder.recordings.first
            
            captionBind = ""
            selectedImage = nil
            messageImage = nil
            fileData = nil
            selectedVideoURL = nil
            replying = nil
            deleteRecording()
            
            var new = GroupMessage(id: id, seen: nil, text: text.isEmpty ? nil : text, imageUrl: nil, audioURL: nil, videoURL: nil, file: nil, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyFile: replyFile, replyAudio: replyAudio, replyVideo: replyVideo, countSmile: nil, countCry: nil, countThumb: nil, countBless: nil, countHeart: nil, countQuestion: nil, timestamp: Timestamp(date: Date()))

            if popRoot.hiddenMessage != "" && text.contains("send group link") {
                new.text = popRoot.hiddenMessage
                withAnimation(.bouncy(duration: 0.3)){
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    } else {
                        viewModel.chats[index].messages = [new]
                    }
                }
                viewModel.newIndex? += 1
                GroupChatService().sendMessage(docID: viewModel.chats[index].id ?? "", text: popRoot.hiddenMessage, imageUrl: nil, messageID: id, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                AudioServicesPlaySystemSound(1004)
                viewModel.chats[index].lastM = new
                viewModel.setDate()
            } else if let audio = audFirst {
                AudioServicesPlaySystemSound(1004)
                viewModel.audioMessages.append((id, audio.fileURL))
                
                viewModel.chats[index].lastM = new
                withAnimation(.bouncy(duration: 0.3)){
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    } else {
                        viewModel.chats[index].messages = [new]
                    }
                }
                viewModel.newIndex? += 1
                viewModel.setDate()
                
                let groupID = viewModel.chats[index].id
                ImageUploader.uploadAudioToFirebaseStorage(localURL: audio.fileURL) { tempAudio in
                    if let final = tempAudio {
                        if let x = viewModel.chats.firstIndex(where: { $0.id == groupID }) {
                            if let y = viewModel.chats[x].messages?.firstIndex(where: { $0.id == id }) {
                                DispatchQueue.main.async {
                                    viewModel.chats[x].messages?[y].audioURL = final
                                }
                            }
                        }
                        GroupChatService().sendMessage(docID: viewModel.chats[index].id ?? "", text: text, imageUrl: nil, messageID: id, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile, videoURL: nil, audioURL: tempAudio, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                    }
                }
            } else if let vid = sVidU {
                AudioServicesPlaySystemSound(1004)
                new.videoURL = vid.absoluteString
                
                viewModel.chats[index].lastM = new
                withAnimation(.bouncy(duration: 0.3)){
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    } else {
                        viewModel.chats[index].messages = [new]
                    }
                }
                viewModel.newIndex? += 1
                viewModel.setDate()
                
                let groupID = viewModel.chats[index].id
                ImageUploader.uploadVideoToFirebaseStorage(localVideoURL: vid) { tempVideo in
                    if let final = tempVideo {
                        if let x = viewModel.chats.firstIndex(where: { $0.id == groupID }) {
                            if let y = viewModel.chats[x].messages?.firstIndex(where: { $0.id == id }) {
                                DispatchQueue.main.async {
                                    viewModel.chats[x].messages?[y].videoURL = final
                                }
                            }
                        }
                        GroupChatService().sendMessage(docID: viewModel.chats[index].id ?? "", text: text, imageUrl: nil, messageID: id, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile, videoURL: tempVideo, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                    }
                }
            } else if let vid = memoryVideo {
                AudioServicesPlaySystemSound(1004)
                new.videoURL = vid.absoluteString
                
                viewModel.chats[index].lastM = new
                withAnimation(.bouncy(duration: 0.3)){
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    } else {
                        viewModel.chats[index].messages = [new]
                    }
                }
                viewModel.newIndex? += 1
                viewModel.setDate()
                
                GroupChatService().sendMessage(docID: viewModel.chats[index].id ?? "", text: text, imageUrl: nil, messageID: id, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile, videoURL: vid.absoluteString, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
            } else if let image = sImage {
                AudioServicesPlaySystemSound(1004)
                viewModel.imageMessages.append((id, Image(uiImage: image)))
                
                viewModel.chats[index].lastM = new
                withAnimation(.bouncy(duration: 0.3)){
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    } else {
                        viewModel.chats[index].messages = [new]
                    }
                }
                viewModel.newIndex? += 1
                viewModel.setDate()
                
                let groupID = viewModel.chats[index].id
                ImageUploader.uploadImage(image: image, location: "groupChats", compression: 0.25) { loc, _ in
                    if !loc.isEmpty {
                        if let x = viewModel.chats.firstIndex(where: { $0.id == groupID }) {
                            if let y = viewModel.chats[x].messages?.firstIndex(where: { $0.id == id }) {
                                DispatchQueue.main.async {
                                    viewModel.chats[x].messages?[y].imageUrl = loc
                                }
                            }
                        }
                        GroupChatService().sendMessage(docID: viewModel.chats[index].id ?? "", text: text, imageUrl: loc, messageID: id, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                    }
                }
            } else if let image = memoryImage {
                AudioServicesPlaySystemSound(1004)
                new.imageUrl = image
                
                viewModel.chats[index].lastM = new
                withAnimation(.bouncy(duration: 0.3)){
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    } else {
                        viewModel.chats[index].messages = [new]
                    }
                }
                viewModel.newIndex? += 1
                viewModel.setDate()
                
                GroupChatService().sendMessage(docID: viewModel.chats[index].id ?? "", text: text, imageUrl: image, messageID: id, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
            } else if let file = fData {
                AudioServicesPlaySystemSound(1004)
                new.async = true
                
                viewModel.chats[index].lastM = new
                withAnimation(.bouncy(duration: 0.3)){
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    } else {
                        viewModel.chats[index].messages = [new]
                    }
                }
                viewModel.newIndex? += 1
                viewModel.setDate()
                
                let groupID = viewModel.chats[index].id
                ImageUploader.uploadFile(data: file, location: "groupChats", fileExtension: pathExtension) { loc in
                    if !loc.isEmpty {
                        if let x = viewModel.chats.firstIndex(where: { $0.id == groupID }) {
                            if let y = viewModel.chats[x].messages?.firstIndex(where: { $0.id == id }) {
                                DispatchQueue.main.async {
                                    viewModel.chats[x].messages?[y].file = loc
                                }
                            }
                        }
                        GroupChatService().sendMessage(docID: viewModel.chats[index].id ?? "", text: text, imageUrl: nil, messageID: id, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile, videoURL: nil, audioURL: nil, fileURL: loc, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                    }
                }
            } else if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AudioServicesPlaySystemSound(1004)
                viewModel.chats[index].lastM = new
                GroupChatService().sendMessage(docID: viewModel.chats[index].id ?? "", text: text, imageUrl: nil, messageID: id, replyFrom: replyFrom, replyText: replyText, replyImage: replyImage, replyVideo: replyVideo, replyAudio: replyAudio, replyFile: replyFile, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
                withAnimation(.bouncy(duration: 0.3)){
                    if viewModel.chats[index].messages != nil {
                        viewModel.chats[index].messages?.insert(new, at: 0)
                    } else {
                        viewModel.chats[index].messages = [new]
                    }
                }
                viewModel.newIndex? += 1
                viewModel.setDate()
            }
            memoryImage = nil
            memoryVideo = nil
        }
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
                            Text("stock").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                        }.padding(.trailing, 8).frame(height: 40).padding(.top, 5)
                    }
                    Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray).padding(.leading, 55)
                }
            }.padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .frame(height: matchedStocks.count > 3 ? 160.0 : (CGFloat(matchedStocks.count) * 50.0))
    }
    func replaceStock(new: String){
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        captionBind = replaceLastWord(originalString: captionBind, newWord: ("$" + new.uppercased()))
        matchedStocks = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            matchedStocks = []
        }
    }
    func getStock(){
        let temp = stockModel.coins.map { String($0.symbol) } + stockModel.companyData.map { String($0.1) }
        let possible = Array(Set(temp))
        
        if let last = captionBind.last, last == "$" {
            matchedStocks = possible
            return
        } else if let last = captionBind.last, last == " " {
            matchedStocks = []
        } else {
            let words = captionBind.components(separatedBy: " ")
            
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
    func handleTextChange(newValue: String) {
        if newValue == "send group lin" {
            captionBind = ""
        } else if newValue.contains("send group link") && newValue.count > 15 {
            captionBind = newValue.replacingOccurrences(of: "send group link", with: "")
        } else if newValue == "send invite link" && !popRoot.hiddenMessage.isEmpty {
            popRoot.hiddenMessage = popRoot.hiddenMessage.replacingOccurrences(of: "priv!@#$%^&*()", with: "pub!@#$%^&*()")
            captionBind = "send group link"
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
                            addAudio = false
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
                                addAudio = false
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
                        if let url = auth.currentUser?.profileImageUrl {
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
        recorder.recording = false
        recordingTimer?.invalidate()
        recorder.stopRecording()
        recorder.recordings = []
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
}
