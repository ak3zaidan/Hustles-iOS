import SwiftUI
import Combine
import Kingfisher
import Firebase
import AVKit
import CoreLocation

struct DetailsMultipleViewMemory: View {
    @Binding var videoFile: animatableMemory
    @Binding var isExpanded: Bool
    var animationID: Namespace.ID
    @GestureState private var isDragging = false
    @Binding var showBackground: Bool
    @State var opacity: CGFloat = 1.0
    @State var showStorySheet = false
    @State var storyCopied = false
    @FocusState private var focusField: FocusedField?
    @State var caption = ""
    @State var showKeyboard = false
    @State var point: CGFloat = 0.0
    @State var infinite = false
    @State var all: [animatableMemory]
    let highlightStr: String
    @State var editSingle = false
    @Binding var currentStoryIndex: Int
    @Binding var currentStoryId: String?
    @State var isMuted = false
    @State var isPlaying = true
    @Binding var placeName: String
    let userProfilePhoto: String?
    let updatePlaceName: (CLLocationCoordinate2D) -> Void
    
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: MessageViewModel
    @State var showSend: Bool = false
    
    var body: some View {
        ZStack {
            if showBackground {
                Color.black.ignoresSafeArea().opacity(opacity)
                    .onTapGesture { loc in
                        if editSingle {
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
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation {
                                    showKeyboard = true
                                }
                                focusField = .one
                            }
                        }
                    }
            }
            CardViewMemory(videoFile: $videoFile, isExpanded: $isExpanded, animationID: animationID, isDetailsView: true, isNormal: true, isDetail: true)
                .onTapGesture { loc in
                    if editSingle {
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
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation {
                                showKeyboard = true
                            }
                            focusField = .one
                        }
                    }
                }
                .overlay(content: {
                    if (!caption.isEmpty || showKeyboard) && isExpanded && videoFile.offset == .zero && editSingle {
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                keyboardImage()
                                    .offset(y: focusField == .one ? 0.0 : -point)
                                    .gesture (
                                        DragGesture()
                                            .onChanged { gesture in
                                                let screenH = geo.size.height
                                                let max = screenH * 0.88
                                                let min = screenH * 0.03
                                                let val = abs(gesture.location.y)
                                                if val > min && val < max && val > 0.0 {
                                                    point = abs(val)
                                                }
                                            }
                                    )
                            }.KeyboardAwarePadding()
                        }.ignoresSafeArea()
                    }
                })
                .onChange(of: currentStoryIndex, { _, _ in
                    caption = ""
                    if !videoFile.isImage {
                        videoFile.playVideo = true
                        videoFile.player?.play()
                    }
                })
                .overlay(content: {
                    if !editSingle && isExpanded && videoFile.offset == .zero {
                        HStack(spacing: 3){
                            Rectangle().foregroundStyle(.yellow).opacity(0.001)
                                .onTapGesture(perform: {
                                    if currentStoryIndex > 0 {
                                        if !videoFile.isImage {
                                            videoFile.playVideo = false
                                            videoFile.player?.pause()
                                        }
                                        currentStoryIndex -= 1
                                        currentStoryId = all[currentStoryIndex].id
                                    }
                                })
                            Rectangle().foregroundStyle(.yellow).opacity(0.001)
                                .onTapGesture(perform: {
                                    if currentStoryIndex < (all.count - 1) {
                                        if !videoFile.isImage {
                                            videoFile.playVideo = false
                                            videoFile.player?.pause()
                                        }
                                        currentStoryIndex += 1
                                        currentStoryId = all[currentStoryIndex].id
                                    } else {
                                        if !videoFile.isImage {
                                            videoFile.player?.pause()
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                videoFile.player?.seek(to: .zero)
                                                videoFile.playVideo = false
                                            }
                                        }
                                        withAnimation(.easeInOut(duration: 0.2)){
                                            showBackground = false
                                            currentStoryIndex = 0
                                            currentStoryId = ""
                                        }
                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.7)) {
                                            videoFile.offset = .zero
                                            isExpanded = false
                                        }
                                    }
                                })
                        }
                    }
                })
                .padding(.bottom, 80)
                .overlay(content: {
                    if isExpanded && videoFile.offset == .zero {
                        overlayMemory()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: videoFile.offset)
                    }
                })
        }
        .overlay(content: {
            if showSend {
                SendMemoryView(data: [videoFile.memory], caption: $caption, position: point, infinite: infinite) {
                    withAnimation(.easeInOut(duration: 0.15)){
                        showSend = false
                    }
                    if videoFile.player != nil {
                        videoFile.player?.isMuted = self.isMuted
                        if self.isPlaying {
                            videoFile.player?.play()
                        } else {
                            videoFile.player?.pause()
                        }
                    }
                }
                .transition(.move(edge: .trailing))
            }
        })
        .sheet(isPresented: $showStorySheet, content: {
            VStack(spacing: 20){
                HStack {
                    ZStack {
                        personView(size: 45)
                        if let image = userProfilePhoto {
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 45, height: 45)
                                .clipShape(Circle())
                        }
                    }
                    VStack(alignment: .leading){
                        Text("My Story - Public")
                            .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                            .font(.title3)
                        Text("Story will be visible on Map").font(.system(size: 13)).foregroundStyle(.gray)
                    }
                    Spacer()
                    Circle()
                        .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                        .frame(width: 24, height: 24)
                        .padding(12)
                        .overlay {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white).bold()
                                .font(.caption)
                        }
                }
                Button(action: {
                    if let user = auth.currentUser {
                        showStorySheet = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        popRoot.alertImage = "checkmark"
                        popRoot.alertReason = "Story Posted"
                        withAnimation(.easeInOut(duration: 0.2)){
                            popRoot.showAlert = true
                        }
                        
                        let size = widthOrHeight(width: false)
                        let pos = (size - point) / size
                        
                        var lat: Double? = nil
                        var long: Double? = nil
                        if let latTemp = videoFile.memory.lat, let longTemp = videoFile.memory.long {
                            lat = Double(latTemp)
                            long = Double(longTemp)
                        }
                        
                        let postID = "\(UUID())"
                        GlobeService().uploadStory(caption: caption, captionPos: pos, link: nil, imageLink: videoFile.memory.image, videoLink: videoFile.memory.video, id: postID, uid: user.id ?? "", username: user.username, userphoto: user.profileImageUrl, long: long, lat: lat, muted: false, infinite: infinite == true ? true : nil)
                        
                        if let x = profile.users.firstIndex(where: { $0.user.id == user.id }) {
                            let new = Story(id: postID, uid: user.id ?? "", username: user.username, profilephoto: user.profileImageUrl, long: long, lat: lat, text: caption.isEmpty ? nil : caption, textPos: pos, imageURL: videoFile.memory.image, videoURL: videoFile.memory.video, timestamp: Timestamp(), link: nil, geoHash: "")
                            
                            if profile.users[x].stories != nil {
                                profile.users[x].stories?.append(new)
                            }
                        }
                    } else {
                        popRoot.alertImage = "wifi.exclamationmark"
                        popRoot.alertReason = "An error occured!"
                        withAnimation(.easeInOut(duration: 0.2)){
                            popRoot.showAlert = true
                        }
                    }
                }, label:{
                    HStack(spacing: 8){
                        Spacer()
                        Text("Post").font(.title3).bold()
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45.0)).font(.title3)
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .frame(height: 45)
                    .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .clipShape(Capsule())
                })
            }
            .padding(.horizontal)
            .presentationDetents([.height(140.0)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30.0)
        })
        .gesture(
            DragGesture()
                .updating($isDragging, body: { _, dragState, _ in
                    dragState = true
                }).onChanged({ value in
                    var translation = value.translation
                    translation = isDragging && isExpanded ? translation : .zero
                    videoFile.offset = translation
                    
                    let ratio = min(1.0, abs(value.translation.height) / 300.0)
                    self.opacity = 1.0 - ratio
                }).onEnded({ value in
                    if value.translation.height > 120 || abs(value.translation.width) > 100 {
                        if !videoFile.isImage {
                            videoFile.player?.pause()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                videoFile.player?.seek(to: .zero)
                                videoFile.playVideo = false
                            }
                        }
                        withAnimation(.easeInOut(duration: 0.1)){
                            showBackground = false
                            currentStoryIndex = 0
                            currentStoryId = ""
                        }
                        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.7)) {
                            videoFile.offset = .zero
                            isExpanded = false
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.25)) {
                            videoFile.offset = .zero
                            self.opacity = 1.0
                        }
                    }
                })
        )
        .onAppear {
            if !videoFile.isImage {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    withAnimation(.easeInOut) {
                        videoFile.playVideo = true
                        videoFile.player?.play()
                    }
                }
            }
        }
    }
    @ViewBuilder
    func keyboardImage() -> some View {
        VStack {
            TextField("", text: $caption, axis: .vertical)
                .focused($focusField, equals: .one)
                .tint(.white).foregroundStyle(.white)
                .lineLimit(10)
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
    @ViewBuilder
    func overlayMemory() -> some View {
        VStack {
            if editSingle {
                HStack(alignment: .top){
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        withAnimation(.easeInOut(duration: 0.2)){
                            editSingle = false
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label:{
                        Image(systemName: "xmark").font(.title2).bold().foregroundStyle(.white)
                    })
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
                            Text("T")
                                .foregroundColor(showKeyboard ? .yellow : .white).bold().font(.system(size: 23))
                                .frame(width: 45, height: 45)
                                .background(.black.opacity(0.15))
                                .clipShape(Circle())
                        }
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if let image = videoFile.memory.image {
                                downloadAndSaveImage(url: image)
                                popRoot.alertReason = "Image Saved"
                            } else if let video = videoFile.memory.video {
                                saveVideoToCameraRoll(urlStr: video)
                                popRoot.alertReason = "Video Saved"
                            }
                            popRoot.alertImage = "link"
                            withAnimation(.easeInOut(duration: 0.2)){
                                popRoot.showAlert = true
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.down.fill")
                                .foregroundColor(.white).bold().font(.system(size: 23))
                                .frame(width: 45, height: 45)
                                .background(.black.opacity(0.15))
                                .clipShape(Circle())
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
                            Image(systemName: infinite ? "infinity" : "timer")
                                .foregroundColor(.white).font(.system(size: 23))
                                .frame(width: 45, height: 45)
                                .background(.black.opacity(0.15))
                                .clipShape(Circle())
                        }
                        if !videoFile.isImage {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                videoFile.player?.isMuted.toggle()
                                isMuted = videoFile.player?.isMuted ?? false
                            } label: {
                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundColor(.white).bold().font(.system(size: 21))
                                    .frame(width: 45, height: 45)
                                    .background(.black.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if isPlaying {
                                    videoFile.player?.pause()
                                } else {
                                    videoFile.player?.play()
                                }
                                isPlaying.toggle()
                            } label: {
                                Image(systemName: isPlaying ? "pause" : "play.fill")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundColor(.white).bold().font(.system(size: 23))
                                    .frame(width: 45, height: 45)
                                    .background(.black.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }.padding(.leading, 24).padding(.trailing, 15).padding(.top, 24)
            } else {
                VStack(spacing: 15){
                    HStack(spacing: 4){
                        ForEach(0..<all.count, id: \.self) { i in
                            Rectangle()
                                .frame(height: 1).foregroundStyle(.white)
                                .opacity((i <= currentStoryIndex) ? 1.0 : 0.4)
                        }
                    }
                    HStack(spacing: 10){
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            if !videoFile.isImage {
                                videoFile.player?.pause()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    videoFile.player?.seek(to: .zero)
                                    videoFile.playVideo = false
                                }
                            }
                            withAnimation(.easeInOut(duration: 0.2)){
                                showBackground = false
                                currentStoryIndex = 0
                                currentStoryId = ""
                            }
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.7)) {
                                videoFile.offset = .zero
                                isExpanded = false
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label:{
                            ZStack {
                                Rectangle().foregroundStyle(.gray).opacity(0.001)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "chevron.left").font(.title3).bold().foregroundStyle(.white)
                            }
                        })
                        VStack(alignment: .leading, spacing: 3){
                            Text(highlightStr).font(.subheadline).bold()
                                .shadow(color: .gray, radius: 3)
                            Text(formatFirebaseTimestamp(videoFile.memory.createdAt)).font(.caption)
                        }.foregroundStyle(.white)
                        Spacer()
                        Menu(content: {
                            Text("\(placeName)\n\(formatFirebaseTimestampExtended(videoFile.memory.createdAt))")
                            Divider()
                            Button(role: .destructive, action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if let id = videoFile.memory.id {
                                    UserService().deleteMemory(memID: id)
                                    
                                    popRoot.alertImage = "checkmark"
                                    popRoot.alertReason = "Memory Deleted"
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        popRoot.showAlert = true
                                    }
                                }
                            }, label: {
                                Label("Delete", systemImage: "trash")
                            })
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .foregroundStyle(.gray).opacity(0.001)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "ellipsis").font(.title2).bold().foregroundStyle(.white)
                            }
                        })
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)){
                                editSingle.toggle()
                            }
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .foregroundStyle(.gray).opacity(0.001)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "pencil").font(.title2).bold().foregroundStyle(.white)
                            }
                        })
                    }
                }
                .padding(.top, 16).padding(.horizontal, 12)
            }
            Spacer()
            if !placeName.isEmpty {
                HStack {
                    Spacer()
                    Text(placeName)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .font(.subheadline).foregroundStyle(.white)
                        .background(.black.opacity(0.15))
                        .clipShape(Capsule())
                    Spacer()
                }.padding(.bottom, 20)
            }
            HStack(spacing: 10){
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)){
                        storyCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                        withAnimation(.easeInOut(duration: 0.3)){
                            storyCopied = false
                        }
                    }
                    if let id = videoFile.memory.id, let uid = auth.currentUser?.id {
                        UIPasteboard.general.string = "https://hustle.page/memory/\(uid)/\(id)/"
                        
                        popRoot.alertImage = "link"
                        popRoot.alertReason = "Memory Link Copied"
                        withAnimation(.easeInOut(duration: 0.2)){
                            popRoot.showAlert = true
                        }
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label:{
                    Image(systemName: "link").font(.title2).bold().foregroundStyle(.white)
                        .symbolEffect(.bounce, value: storyCopied)
                        .frame(width: 60, height: 50)
                        .background(.gray.opacity(0.3))
                        .clipShape(Capsule())
                })
                Button(action: {
                    if highlightStr != "Recents" && caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        caption = highlightStr
                        point = widthOrHeight(width: false) * 0.4
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showStorySheet = true
                }, label:{
                    HStack(spacing: 8){
                        Spacer()
                        ZStack {
                            personView(size: 38)
                            if let image = userProfilePhoto {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 38, height: 38)
                                    .clipShape(Circle())
                            }
                        }
                        Text("Story").font(.title3).fontWeight(.semibold).foregroundStyle(.white)
                        Spacer()
                    }
                    .frame(height: 50)
                    .background(.gray.opacity(0.3))
                    .clipShape(Capsule())
                })
                Button(action: {
                    if videoFile.player != nil {
                        videoFile.player?.isMuted = true
                        videoFile.player?.pause()
                    }
                    if highlightStr != "Recents" && caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        caption = highlightStr
                        point = widthOrHeight(width: false) * 0.4
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                    withAnimation(.easeInOut(duration: 0.15)){
                        showSend = true
                    }
                }, label:{
                    HStack(spacing: 8){
                        Spacer()
                        Text("Send").font(.title3).fontWeight(.semibold).lineLimit(1)
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45.0)).font(.title3)
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .frame(height: 50)
                    .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .clipShape(Capsule())
                })
                Spacer()
            }.padding(.horizontal, 10)
        }.padding(.bottom, 25)
    }
    func formatFirebaseTimestamp(_ timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        let formattedDate = dateFormatter.string(from: date)
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let daySuffix = daySuffix(from: day)
        
        let range = formattedDate.range(of: ",")!
        let dayRange = formattedDate.startIndex..<range.lowerBound
        let result = formattedDate.replacingCharacters(in: dayRange, with: "\(formattedDate[dayRange])\(daySuffix)")
        
        return result
    }
    func formatFirebaseTimestampExtended(_ timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        var dateString = dateFormatter.string(from: date)
        let day = Calendar.current.component(.day, from: date)
        dateString += daySuffix(from: day)
        dateFormatter.dateFormat = ", yyyy 'at' h:mm a"
        dateString += dateFormatter.string(from: date)
        return dateString
    }
    func daySuffix(from day: Int) -> String {
        switch day {
        case 1, 21, 31:
            return "st"
        case 2, 22:
            return "nd"
        case 3, 23:
            return "rd"
        default:
            return "th"
        }
    }
}

struct DetailsViewMemory: View {
    @EnvironmentObject var popRoot: PopToRoot
    @Binding var videoFile: animatableMemory
    @Binding var isExpanded: Bool
    var animationID: Namespace.ID
    @GestureState private var isDragging = false
    @Binding var showBackground: Bool
    @State var opacity: CGFloat = 1.0
    @State var showStorySheet = false
    @State var storyCopied = false
    @FocusState private var focusField: FocusedField?
    @State var caption = ""
    @State var showKeyboard = false
    @State var point: CGFloat = 0.0
    @State var infinite = false
    
    @State var isMuted = false
    @State var isPlaying = true
    
    let profilePhoto: String?
    @Binding var placeName: String
    
    @EnvironmentObject var message: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @State var showSend: Bool = false
    
    var body: some View {
        ZStack {
            if showBackground {
                Color.black.ignoresSafeArea().opacity(opacity)
                    .onTapGesture { loc in
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
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation {
                                showKeyboard = true
                            }
                            focusField = .one
                        }
                    }
            }
            CardViewMemory(videoFile: $videoFile, isExpanded: $isExpanded, animationID: animationID, isDetailsView: true, isNormal: true, isDetail: true)
                .onTapGesture { loc in
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
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation {
                            showKeyboard = true
                        }
                        focusField = .one
                    }
                }
                .overlay(content: {
                    if (!caption.isEmpty || showKeyboard) && isExpanded && videoFile.offset == .zero {
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                keyboardImage()
                                    .offset(y: focusField == .one ? 0.0 : -point)
                                    .gesture (
                                        DragGesture()
                                            .onChanged { gesture in
                                                let screenH = geo.size.height
                                                let max = screenH * 0.88
                                                let min = screenH * 0.03
                                                let val = abs(gesture.location.y)
                                                if val > min && val < max && val > 0.0 {
                                                    point = abs(val)
                                                }
                                            }
                                    )
                            }.KeyboardAwarePadding()
                        }.ignoresSafeArea()
                    }
                })
                .padding(.bottom, 80)
                .overlay(content: {
                    if isExpanded && videoFile.offset == .zero {
                        overlayMemory()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: videoFile.offset)
                    }
                })
        }
        .overlay(content: {
            if showSend {
                SendMemoryView(data: [videoFile.memory], caption: $caption, position: point, infinite: infinite) {
                    withAnimation(.easeInOut(duration: 0.15)){
                        showSend = false
                    }
                    if videoFile.player != nil {
                        videoFile.player?.isMuted = self.isMuted
                        if self.isPlaying {
                            videoFile.player?.play()
                        } else {
                            videoFile.player?.pause()
                        }
                    }
                }.transition(.move(edge: .trailing))
            }
        })
        .sheet(isPresented: $showStorySheet, content: {
            VStack(spacing: 20){
                HStack {
                    ZStack {
                        personView(size: 45)
                        if let image = profilePhoto {
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 45, height: 45)
                                .clipShape(Circle())
                        }
                    }
                    VStack(alignment: .leading){
                        Text("My Story - Public")
                            .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                            .font(.title3)
                        Text("Story will be visible on Map").font(.system(size: 13)).foregroundStyle(.gray)
                    }
                    Spacer()
                    Circle()
                        .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                        .frame(width: 24, height: 24)
                        .padding(12)
                        .overlay {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white).bold()
                                .font(.caption)
                        }
                }
                Button(action: {
                    if let user = auth.currentUser {
                        showStorySheet = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        popRoot.alertImage = "checkmark"
                        popRoot.alertReason = "Story Posted"
                        withAnimation(.easeInOut(duration: 0.2)){
                            popRoot.showAlert = true
                        }
                        
                        let size = widthOrHeight(width: false)
                        let pos = (size - point) / size
                        
                        var lat: Double? = nil
                        var long: Double? = nil
                        if let latTemp = videoFile.memory.lat, let longTemp = videoFile.memory.long {
                            lat = Double(latTemp)
                            long = Double(longTemp)
                        }
                        
                        let postID = "\(UUID())"
                        GlobeService().uploadStory(caption: caption, captionPos: pos, link: nil, imageLink: videoFile.memory.image, videoLink: videoFile.memory.video, id: postID, uid: user.id ?? "", username: user.username, userphoto: user.profileImageUrl, long: long, lat: lat, muted: false, infinite: infinite == true ? true : nil)
                        
                        if let x = profile.users.firstIndex(where: { $0.user.id == user.id }) {
                            let new = Story(id: postID, uid: user.id ?? "", username: user.username, profilephoto: user.profileImageUrl, long: long, lat: lat, text: caption.isEmpty ? nil : caption, textPos: pos, imageURL: videoFile.memory.image, videoURL: videoFile.memory.video, timestamp: Timestamp(), link: nil, geoHash: "")
                            
                            if profile.users[x].stories != nil {
                                profile.users[x].stories?.append(new)
                            }
                        }
                    } else {
                        popRoot.alertImage = "wifi.exclamationmark"
                        popRoot.alertReason = "An error occured!"
                        withAnimation(.easeInOut(duration: 0.2)){
                            popRoot.showAlert = true
                        }
                    }
                }, label:{
                    HStack(spacing: 8){
                        Spacer()
                        Text("Post").font(.title3).bold()
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45.0)).font(.title3)
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .frame(height: 45)
                    .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .clipShape(Capsule())
                })
            }
            .padding(.horizontal)
            .presentationDetents([.height(140.0)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30.0)
        })
        .gesture(
            DragGesture()
                .updating($isDragging, body: { _, dragState, _ in
                    dragState = true
                }).onChanged({ value in
                    var translation = value.translation
                    translation = isDragging && isExpanded ? translation : .zero
                    videoFile.offset = translation
                    
                    if focusField == .one {
                        withAnimation {
                            showKeyboard = false
                            focusField = .two
                        }
                    }
                    
                    let ratio = min(1.0, abs(value.translation.height) / 300.0)
                    self.opacity = 1.0 - ratio
                }).onEnded({ value in
                    if value.translation.height > 120 || abs(value.translation.width) > 100 {
                        if !videoFile.isImage {
                            videoFile.player?.pause()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                videoFile.player?.seek(to: .zero)
                                videoFile.playVideo = false
                            }
                        }
                        withAnimation(.easeInOut(duration: 0.1)){
                            showBackground = false
                        }
                        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.7)) {
                            videoFile.offset = .zero
                            isExpanded = false
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.25)) {
                            videoFile.offset = .zero
                            self.opacity = 1.0
                        }
                    }
                })
        )
        .onAppear {
            if !videoFile.isImage {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    withAnimation(.easeInOut) {
                        videoFile.playVideo = true
                        videoFile.player?.play()
                    }
                }
            }
        }
    }
    @ViewBuilder
    func keyboardImage() -> some View {
        VStack {
            TextField("", text: $caption, axis: .vertical)
                .focused($focusField, equals: .one)
                .tint(.white).foregroundStyle(.white)
                .lineLimit(10)
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
    @ViewBuilder
    func overlayMemory() -> some View {
        VStack {
            ZStack(alignment: .top){
                if !placeName.isEmpty {
                    HStack {
                        Spacer()
                        Text(placeName)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .font(.subheadline).foregroundStyle(.white)
                            .background(.black.opacity(0.15))
                            .clipShape(Capsule())
                        Spacer()
                    }
                }
                HStack(alignment: .top){
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if !videoFile.isImage {
                            videoFile.player?.pause()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                videoFile.player?.seek(to: .zero)
                                videoFile.playVideo = false
                            }
                        }
                        withAnimation(.easeInOut(duration: 0.2)){
                            showBackground = false
                        }
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.7)) {
                            videoFile.offset = .zero
                            isExpanded = false
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label:{
                        Image(systemName: "xmark")
                            .font(.title2).bold().foregroundStyle(.white)
                            .frame(width: 45, height: 45)
                            .background(.black.opacity(0.001))
                    })
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
                            Text("T")
                                .foregroundColor(showKeyboard ? .yellow : .white).bold().font(.system(size: 23))
                                .frame(width: 45, height: 45)
                                .background(.black.opacity(0.15))
                                .clipShape(Circle())
                        }
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if let image = videoFile.memory.image {
                                downloadAndSaveImage(url: image)
                                popRoot.alertReason = "Image Saved"
                            } else if let video = videoFile.memory.video {
                                saveVideoToCameraRoll(urlStr: video)
                                popRoot.alertReason = "Video Saved"
                            }
                            popRoot.alertImage = "link"
                            withAnimation(.easeInOut(duration: 0.2)){
                                popRoot.showAlert = true
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.down.fill")
                                .foregroundColor(.white).bold().font(.system(size: 23))
                                .frame(width: 45, height: 45)
                                .background(.black.opacity(0.15))
                                .clipShape(Circle())
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
                            Image(systemName: infinite ? "infinity" : "timer")
                                .foregroundColor(.white).font(.system(size: 23))
                                .frame(width: 45, height: 45)
                                .background(.black.opacity(0.15))
                                .clipShape(Circle())
                        }
                        if !videoFile.isImage {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                videoFile.player?.isMuted.toggle()
                                isMuted = videoFile.player?.isMuted ?? false
                            } label: {
                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundColor(.white).bold().font(.system(size: 21))
                                    .frame(width: 45, height: 45)
                                    .background(.black.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if isPlaying {
                                    videoFile.player?.pause()
                                } else {
                                    videoFile.player?.play()
                                }
                                isPlaying.toggle()
                            } label: {
                                Image(systemName: isPlaying ? "pause" : "play.fill")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundColor(.white).bold().font(.system(size: 23))
                                    .frame(width: 45, height: 45)
                                    .background(.black.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }.padding(.leading, 24).padding(.trailing, 15)
            }.padding(.top, 24)
            Spacer()
            HStack(spacing: 10){
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)){
                        storyCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                        withAnimation(.easeInOut(duration: 0.3)){
                            storyCopied = false
                        }
                    }
                    if let id = videoFile.memory.id, let uid = auth.currentUser?.id {
                        UIPasteboard.general.string = "https://hustle.page/memory/\(uid)/\(id)/"
                        
                        popRoot.alertImage = "link"
                        popRoot.alertReason = "Memory Link Copied"
                        withAnimation(.easeInOut(duration: 0.2)){
                            popRoot.showAlert = true
                        }
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label:{
                    Image(systemName: "link").font(.title2).bold().foregroundStyle(.white)
                        .symbolEffect(.bounce, value: storyCopied)
                        .frame(width: 60, height: 50)
                        .background(.gray.opacity(0.3))
                        .clipShape(Capsule())
                })
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showStorySheet = true
                }, label:{
                    HStack(spacing: 8){
                        Spacer()
                        ZStack {
                            personView(size: 38)
                            if let image = profilePhoto {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 38, height: 38)
                                    .clipShape(Circle())
                            }
                        }
                        Text("Story").font(.title3).fontWeight(.semibold).foregroundStyle(.white)
                        Spacer()
                    }
                    .frame(height: 50)
                    .background(.gray.opacity(0.3))
                    .clipShape(Capsule())
                })
                Button(action: {
                    if videoFile.player != nil {
                        videoFile.player?.isMuted = true
                        videoFile.player?.pause()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    message.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                    if caption.isEmpty {
                        point = widthOrHeight(width: false) * 0.4
                    }
                    withAnimation(.easeInOut(duration: 0.15)){
                        showSend = true
                    }
                }, label:{
                    HStack(spacing: 8){
                        Spacer()
                        Text("Send").font(.title3).fontWeight(.semibold).lineLimit(1)
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45.0)).font(.title3)
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .frame(height: 50)
                    .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .clipShape(Capsule())
                })
                Spacer()
            }.padding(.horizontal, 10)
        }.padding(.bottom, 25)
    }
}

struct CardViewMemory: View {
    @Environment(\.scenePhase) var scenePhase
    private let screenSize = UIScreen.main.bounds
    @Binding var videoFile: animatableMemory
    @Binding var isExpanded: Bool
    var animationID: Namespace.ID
    let isNormal: Bool
    let isDetail: Bool
    var isDetailsView: Bool = false
    
    init(videoFile: Binding<animatableMemory>,
         isExpanded: Binding<Bool>,
         animationID: Namespace.ID,
         isDetailsView: Bool = false, isNormal: Bool, isDetail: Bool) {
        
        self._videoFile = videoFile
        self._isExpanded = isExpanded
        self.isDetailsView = isDetailsView
        self.animationID = animationID
        self.isNormal = isNormal
        self.isDetail = isDetail
    }
    
    var body: some View {
        GeometryReader {
            let size = $0.size

            if let imageURL = videoFile.memory.image {
                KFImage(URL(string: imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: isDetail ? 20 : (isNormal ? 0 : 10)))
                    .overlay {
                        RoundedRectangle(cornerRadius: isDetail ? 20 : (isNormal ? 0 : 10)).stroke(.gray, lineWidth: 1.0)
                    }
                    .background(content: {
                        RoundedRectangle(cornerRadius: isDetail ? 20 : (isNormal ? 0 : 10))
                            .foregroundColor(.gray).opacity(0.2)
                            .overlay(content: {
                                ProgressView().scaleEffect(1.2)
                            })
                    })
                    .clipShape(RoundedRectangle(cornerRadius: isDetail ? 20 : (isNormal ? 0 : 10), style: .continuous))
                    .scaleEffect(scale)
            } else if let thumbnail = videoFile.thumbnail, let player = videoFile.player {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .opacity(videoFile.playVideo ? 0 : 1)
                    .frame(width: size.width, height: size.height)
                    .overlay {
                        if videoFile.playVideo && isDetailsView {
                            CustomVideoPlayer(player: player)
                                .transition(.identity)
                                .onAppear {
                                    player.isMuted = false
                                    NotificationCenter.default.addObserver (
                                        forName: .AVPlayerItemDidPlayToEndTime,
                                        object: player.currentItem,
                                        queue: .main
                                    ) { _ in
                                        player.seek(to: .zero)
                                        player.play()
                                    }
                                    player.actionAtItemEnd = .none
                                }
                        } else if !isExpanded {
                            VStack(alignment: .leading){
                                Spacer()
                                HStack {
                                    Text(formatDuration(player.currentItem?.duration))
                                        .foregroundStyle(.white)
                                        .font(.subheadline).fontWeight(.medium)
                                    Spacer()
                                }
                            }.padding(10)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: isDetail ? 20 : (isNormal ? 0 : 10), style: .continuous))
                    .scaleEffect(scale)
            } else {
                RoundedRectangle(cornerRadius: isDetail ? 20 : (isNormal ? 0 : 10))
                    .foregroundColor(.gray).opacity(0.2)
                    .overlay(content: {
                        ProgressView().scaleEffect(1.2)
                    })
                    .onAppear {
                        if let f_url = videoFile.memory.video, let url = URL(string: f_url) {
                            extractImageAt(f_url: url, time: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) { thumbnail in
                                videoFile.thumbnail = thumbnail
                            }
                        }
                    }
            }
        }
        .matchedGeometryEffect(id: videoFile.id, in: animationID)
        .offset(videoFile.offset)
        .offset(y: videoFile.offset.height * -0.4)
        .onChange(of: scenePhase) { _, newPhase in
            if videoFile.playVideo && videoFile.player != nil {
                if newPhase == .inactive {
                    videoFile.player?.pause()
                } else if newPhase == .active {
                    videoFile.player?.play()
                } else if newPhase == .background {
                    videoFile.player?.pause()
                }
            }
        }
    }
    private var scale: CGFloat {
        var yOffset = videoFile.offset.height
        yOffset = yOffset < 0 ? 0 : yOffset
        var progress = yOffset / screenSize.height
        progress = 1 - (progress > 0.4 ? 0.4 : progress)
        return (isExpanded ? progress : 1)
    }
}

func formatDuration(_ duration: CMTime?) -> String {
    if let duration = duration {
        let totalSeconds = CMTimeGetSeconds(duration)
        guard !totalSeconds.isNaN else {
            return "0:00"
        }
        
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    return "0:00"
}

struct MemoriesView: View {
    @EnvironmentObject var message: MessageViewModel
    @EnvironmentObject var viewModel: PopToRoot
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @State var testDataHighlights = [MemoryHighLight]()
    
    @Environment(\.colorScheme) var colorScheme
    @State var limitQuery: Bool = false
    @State var scrollViewSize: CGSize = .zero
    @State var wholeSize: CGSize = .zero
    @State var isScrolling: Bool = false
    @State var currentPresentedID: String = ""
    @State var currentPresentedName: String = ""
    @State private var offset: Double = 0
    
    @State var savedMemIds = [String]()
    @State var selectedMemories = [Memory]()
    @State var tooManySelected: Bool = false
    @State var selectingMemories: Bool = false
    @State var isPressingDown = false
    @State var PressDownID: String = ""
    @State var started = false
    
    //animate up
    @State private var isExpanded: Bool = false
    @State private var isHighlightExpanded: Bool = false
    @Namespace private var namespace
    @State private var expandedID: String?
    @State private var expandedHightlightID: String?
    @State var currentStoryIndex: Int = 0
    
    @State var showBack = false
    @State var showStorySheet = false
    @State var savedToggle = false
    @State var deletedToggle = false
    @State var confirmDelete = false
    @State var currentHightlightGroup = [animatableMemory]()
    @State var currentText = "Flashback from Jul 21"
    @State var usedAlready = [String]()
    
    @State var currentPlaceName = ""
    @State var emptyString = ""
    @State var fetchingPlace = false
    @State var fetchedPlaces: [(CLLocationCoordinate2D, String)] = []
    
    @State var showCamera = false
    @State var showSend: Bool = false
    @State var sendMems = [Memory]()
    @State var postedStories = [String]()
    
    //indicator
    @State private var scrollPosition: CGPoint = .zero
    @State private var startOffset: CGFloat = 0
    @State private var indicatorOffset: CGFloat = 0
    private let indicatorHeight: CGFloat = 60
    @State var isDragging = false
    @State var scrollTo = ""
    
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    let detector: CurrentValueSubject<CGFloat, Never>
    let publisher: AnyPublisher<CGFloat, Never>
    let close: () -> Void
    
    init(close: @escaping () -> Void = {}) {
        self.close = close
        let detector = CurrentValueSubject<CGFloat, Never>(0)
        self.publisher = detector
            .debounce(for: .seconds(1.2), scheduler: DispatchQueue.main)
            .dropFirst()
            .eraseToAnyPublisher()
        self.detector = detector
    }
    
    var body: some View {
        ZStack(alignment: .top){
            GeometryReader { geo in
                let iHeight = geo.size.height - 160
                ZStack(alignment: .topTrailing) {
                    ScrollViewReader(content: { proxy in
                        ChildSizeReader(size: $wholeSize) {
                            ScrollView {
                                if viewModel.allMemories.isEmpty && testDataHighlights.isEmpty {
                                    Color.clear.frame(height: 200)
                                    if viewModel.noMoreMemories {
                                        VStack {
                                            Image("memory")
                                                .resizable()
                                                .frame(width: 100, height: 100)
                                            Text("Your memories will appear here!")
                                                .font(.headline)
                                        }
                                    } else {
                                        VStack {
                                            Text("Fetching Memories..")
                                                .font(.headline)
                                            LottieView(loopMode: .loop, name: "placeLoader")
                                                .frame(width: 85, height: 85)
                                                .scaleEffect(0.7)
                                        }
                                    }
                                }
                                ZStack(alignment: .top){
                                    let totalElements = max(2, getBackgroundCount())
                                    LazyVStack(spacing: 0){
                                        Color.clear.frame(height: 50)
                                        ForEach(1...totalElements, id: \.self) { item in
                                            Rectangle()
                                                .foregroundStyle(.clear)
                                                .frame(height: 210).id("scroll\(item)")
                                        }
                                    }
                                    ChildSizeReader(size: $scrollViewSize) {
                                        LazyVStack(spacing: 10){
                                            Color.clear.frame(height: 50)
                                            if !testDataHighlights.isEmpty {
                                                ScrollView(.horizontal) {
                                                    LazyHStack(spacing: 5){
                                                        ForEach($testDataHighlights) { $element in
                                                            if element.allMemories.contains(where: { $0.id == expandedHightlightID }) && isHighlightExpanded {
                                                                Rectangle()
                                                                    .foregroundColor(.clear)
                                                                    .frame(width: 190, height: 240)
                                                            } else {
                                                                CardViewMemory(videoFile: $element.allMemories.first(where: { $0.id == expandedHightlightID }) ?? $element.allMemories.first ?? $element.firstMemory, isExpanded: $isHighlightExpanded, animationID: namespace, isNormal: false, isDetail: false)
                                                                    .frame(width: 190, height: 240)
                                                                    .contentShape(Rectangle())
                                                                    .padding(.leading, element.id == (testDataHighlights.first?.id ?? "") ? 8 : 0)
                                                                    .padding(.trailing, element.id == (testDataHighlights.last?.id ?? "") ? 8 : 0)
                                                                    .onTapGesture {
                                                                        if let lat = element.firstMemory.memory.lat, let long = element.firstMemory.memory.long {
                                                                            setPlaceName(place: CLLocationCoordinate2D(latitude: lat, longitude: long))
                                                                        }
                                                                        currentText = element.highlightSentence
                                                                        currentHightlightGroup = element.allMemories
                                                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.8)) {
                                                                            expandedHightlightID = element.allMemories.first(where: { $0.id == expandedHightlightID })?.id ?? element.allMemories.first?.id
                                                                            isHighlightExpanded = true
                                                                        }
                                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                                                            withAnimation(.easeInOut(duration: 0.2)){
                                                                                showBack = true
                                                                            }
                                                                        }
                                                                    }
                                                                    .overlay {
                                                                        VStack {
                                                                            Spacer()
                                                                            Text(element.highlightSentence)
                                                                                .font(.system(size: 16)).fontWeight(.heavy)
                                                                                .foregroundStyle(.white)
                                                                            Button {
                                                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                                                if element.highlightSentence != "Recents" {
                                                                                    emptyString = element.highlightSentence
                                                                                }
                                                                                message.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                                                                                self.sendMems = element.allMemories.compactMap({ $0.memory })
                                                                                withAnimation(.easeInOut(duration: 0.15)){
                                                                                    showSend = true
                                                                                }
                                                                            } label: {
                                                                                ZStack {
                                                                                    Rectangle()
                                                                                        .frame(width: 40, height: 40)
                                                                                        .opacity(0.001).foregroundStyle(.gray)
                                                                                    Image(systemName: "paperplane.fill")
                                                                                        .font(.title2)
                                                                                        .foregroundStyle(.white)
                                                                                        .rotationEffect(.degrees(45.0))
                                                                                }
                                                                            }
                                                                        }.padding(.vertical, 10)
                                                                    }
                                                            }
                                                        }
                                                    }
                                                }
                                                .scrollIndicators(.hidden)
                                                .padding(.bottom, 15)
                                            }
                                            ForEach($viewModel.allMemories) { $item in
                                                HStack {
                                                    Text(item.date).font(.title3).bold()
                                                        .id(item.id)
                                                    Spacer()
                                                    if selectingMemories {
                                                        let allMemories = item.allMemories.compactMap { $0.memory }
                                                        let allMemoriesSet = Set(allMemories)
                                                        let selectedMemoriesSet = Set(selectedMemories)
                                                        let allSelected = allMemoriesSet.isSubset(of: selectedMemoriesSet)
                                                        
                                                        Button {
                                                            if allSelected {
                                                                withAnimation(.easeInOut(duration: 0.15)){
                                                                    selectedMemories.removeAll { allMemoriesSet.contains($0) }
                                                                }
                                                            } else {
                                                                withAnimation(.easeInOut(duration: 0.15)){
                                                                    let newSelectedMemories = selectedMemoriesSet.union(allMemoriesSet)
                                                                    selectedMemories = Array(newSelectedMemories)
                                                                }
                                                            }
                                                        } label: {
                                                            Text(allSelected ? "Unselect All" : "Select All")
                                                                .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                                                                .font(.subheadline).bold()
                                                        }
                                                        .transition(.scale)
                                                    }
                                                }
                                                .padding(.horizontal)
                                                .overlay(GeometryReader { proxy in
                                                    Color.clear
                                                        .onChange(of: offset, { _, _ in
                                                            let frame = proxy.frame(in: .global)
                                                            let leadingDistance = frame.minY - geo.frame(in: .global).minY
                                                            if leadingDistance <= 70 && leadingDistance >= 50 {
                                                                currentPresentedID = item.id
                                                                currentPresentedName = reformatDateString(item.date)
                                                            }
                                                        })
                                                })
                                                LazyVGrid(columns: Array(repeating: GridItem(spacing: 19), count: 3), spacing: 3) {
                                                    ForEach($item.allMemories) { $object in
                                                        if expandedID == object.memory.id && isExpanded {
                                                            Rectangle()
                                                                .foregroundColor(.clear)
                                                                .frame(width: 190, height: 240)
                                                        } else {
                                                            CardViewMemory(videoFile: $object, isExpanded: $isExpanded, animationID: namespace, isNormal: true, isDetail: false)
                                                                .frame(width: (geo.size.width / 3.0) + 3, height: 210)
                                                                .contentShape(Rectangle())
                                                                .id("\(item.id)\(object.memory.id ?? "")")
                                                                .onTapGesture { _ in
                                                                    if selectingMemories {
                                                                        withAnimation(.easeInOut(duration: 0.1)){
                                                                            if let idx = selectedMemories.firstIndex(where: { $0.id == object.memory.id }) {
                                                                                selectedMemories.remove(at: idx)
                                                                            } else {
                                                                                if selectedMemories.count == 10 {
                                                                                    tooManySelected = true
                                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                                                                                        withAnimation(.easeInOut(duration: 0.1)){
                                                                                            tooManySelected = false
                                                                                        }
                                                                                    }
                                                                                } else {
                                                                                    selectedMemories.append(object.memory)
                                                                                }
                                                                            }
                                                                        }
                                                                    } else {
                                                                        if let lat = object.memory.lat, let long = object.memory.long {
                                                                            setPlaceName(place: CLLocationCoordinate2D(latitude: lat, longitude: long))
                                                                        }
                                                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.8)) {
                                                                            expandedID = object.id
                                                                            isExpanded = true
                                                                        }
                                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                                                            withAnimation(.easeInOut(duration: 0.2)){
                                                                                showBack = true
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                .onLongPressGesture(minimumDuration: .infinity) {
                                                                    
                                                                } onPressingChanged: { starting in
                                                                    if starting {
                                                                        started = true
                                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                                                            if started {
                                                                                withAnimation(.easeInOut(duration: 0.1)){
                                                                                    PressDownID = object.memory.id ?? ""
                                                                                    isPressingDown = true
                                                                                }
                                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4){
                                                                                    if isPressingDown {
                                                                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                                                        withAnimation(.easeInOut(duration: 0.1)){
                                                                                            selectingMemories.toggle()
                                                                                            if selectingMemories && selectedMemories.count < 10 {
                                                                                                selectedMemories.append(object.memory)
                                                                                            }
                                                                                            isPressingDown = false
                                                                                            PressDownID = ""
                                                                                        }
                                                                                    } else {
                                                                                        isPressingDown = false
                                                                                        PressDownID = ""
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    } else {
                                                                        started = false
                                                                        if isPressingDown {
                                                                            withAnimation(.easeInOut(duration: 0.1)){
                                                                                PressDownID = ""
                                                                                isPressingDown = false
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                .overlay {
                                                                    if object.id == (item.allMemories.last?.id ?? "NA") {
                                                                        GeometryReader { proxy in
                                                                            Color.clear
                                                                                .onChange(of: offset, { _, _ in
                                                                                    let frame = proxy.frame(in: .global)
                                                                                    let leadingDistance = frame.minY - geo.frame(in: .global).minY
                                                                                    if leadingDistance <= 250 && leadingDistance >= 200 {
                                                                                        currentPresentedID = item.id
                                                                                        currentPresentedName = reformatDateString(item.date)
                                                                                    }
                                                                                })
                                                                        }
                                                                    }
                                                                }
                                                                .overlay(alignment: .bottomTrailing){
                                                                    if selectingMemories {
                                                                        if selectedMemories.contains(where: { $0.id == object.memory.id }) {
                                                                            Circle()
                                                                                .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                                                                                .frame(width: 20, height: 20)
                                                                                .padding(12)
                                                                                .overlay {
                                                                                    Image(systemName: "checkmark")
                                                                                        .foregroundStyle(.white).bold()
                                                                                        .font(.caption)
                                                                                }
                                                                        } else {
                                                                            Circle()
                                                                                .stroke(.white, lineWidth: 1.0)
                                                                                .frame(width: 20, height: 20)
                                                                                .padding(12)
                                                                        }
                                                                    }
                                                                }
                                                                .scaleEffect(PressDownID == object.memory.id ? 0.9 : 1.0)
                                                        }
                                                    }
                                                }.padding(.bottom, 20)
                                            }
                                            if !viewModel.noMoreMemories && !viewModel.allMemories.isEmpty {
                                                LazyVGrid(columns: Array(repeating: GridItem(spacing: 19), count: 3), spacing: 3) {
                                                    ForEach(0..<8, id: \.self) { _ in
                                                        Rectangle()
                                                            .foregroundStyle(.gray).opacity(0.4)
                                                            .frame(width: (geo.size.width / 3.0) + 3, height: 210)
                                                    }
                                                }.shimmering()
                                            }
                                            Color.clear.frame(height: 100)
                                        }
                                        .offset { rect in
                                            if !isDragging {
                                                let rectWidth: CGFloat = rect.height
                                                let viewWidth: CGFloat = geo.size.height + (startOffset / 2)
                                                let totalScrollRange: CGFloat = rectWidth
                                                let currentScrollOffset: CGFloat = scrollPosition.y * -1
                                                let scrollProgress: CGFloat = (CGFloat(100) * currentScrollOffset) / (totalScrollRange - viewWidth)
                                                let indicatorFrontX: CGFloat = ( scrollProgress * (iHeight-indicatorHeight) / 100 )
                                                indicatorOffset = min(max(0, indicatorFrontX), iHeight)
                                            }
                                        }
                                        .background (
                                            GeometryReader { geometry in
                                                Color.clear
                                                    .preference(
                                                        key: ScrollOffsetPreferenceKey.self,
                                                        value: geometry.frame(in: .named("scroll")).origin
                                                    )
                                            }
                                        )
                                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                            detector.send(value.y)
                                            offset = Double(value.y)
                                            
                                            if !isScrolling {
                                                withAnimation(.easeInOut(duration: 0.2)){
                                                    isScrolling = true
                                                }
                                            }
                                            self.scrollPosition = value
                                            
                                            if value.y > (scrollViewSize.height - wholeSize.height) - 350 && limitQuery && !viewModel.noMoreMemories {
                                                limitQuery = false
                                                fetchData()
                                            }
                                        }
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                            .coordinateSpace(name: "scroll")
                            .onChange(of: scrollTo) { _, newValue in
                                let totalElements = getBackgroundCount()
                                if let num = newValue.last, let number = Int(String(num)) {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    let isTop: Bool = (number < (totalElements / 2))
                                    withAnimation(.easeInOut(duration: 0.05)){
                                        proxy.scrollTo(newValue, anchor: isTop ? .top : .center)
                                    }
                                }
                            }
                        }
                    })
                    if showIndicator() {
                        indicator(iHeight: iHeight)
                    }
                }
            }
            .offset { rect in
                if startOffset != rect.minY {
                    startOffset = rect.minY
                }
            }
            .onReceive(publisher) { _ in
                withAnimation(.easeInOut(duration: 0.2)){
                    isScrolling = false
                    isDragging = false
                }
            }
            headerView()
            if selectingMemories && !selectedMemories.isEmpty {
                VStack {
                    Spacer()
                    bottomSendView()
                }.transition(.move(edge: .bottom))
            }
            if !selectingMemories {
                VStack {
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showCamera = true
                    }, label: {
                        HStack(spacing: 8){
                            Text("Create").font(.headline)
                            Image(systemName: "camera").font(.subheadline).fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                        .clipShape(Capsule())
                        .shadow(color: .gray, radius: 4)
                    })
                }.padding(.bottom, 70).transition(.move(edge: .bottom)).opacity(isDragging ? 0.0 : 1.0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showCamera) {
            MessageCamera(initialSend: .constant(nil), showMemories: true)
                .navigationBarBackButtonHidden(true)
                .enableFullSwipePop(true)
        }
        .overlay(content: {
            if showSend {
                let position = widthOrHeight(width: false) / 2.0
                SendMemoryView(data: sendMems, caption: $emptyString, position: CGFloat(position), infinite: false) {
                    withAnimation(.easeInOut(duration: 0.15)){
                        showSend = false
                    }
                }.transition(.move(edge: .trailing))
            }
        })
        .overlay {
            if let expandedID, isExpanded {
                DetailsViewMemory(videoFile: $viewModel.allMemories.indexAnim(expandedID), isExpanded: $isExpanded, animationID: namespace, showBackground: $showBack, profilePhoto: auth.currentUser?.profileImageUrl, placeName: $currentPlaceName)
                    .transition(.asymmetric(insertion: .identity, removal: .offset(y: 5)))
            }
        }
        .overlay {
            if isHighlightExpanded && expandedHightlightID != nil {
                DetailsMultipleViewMemory(videoFile: $currentHightlightGroup[currentStoryIndex], isExpanded: $isHighlightExpanded, animationID: namespace, showBackground: $showBack, all: currentHightlightGroup, highlightStr: currentText, currentStoryIndex: $currentStoryIndex, currentStoryId: $expandedHightlightID, placeName: $currentPlaceName, userProfilePhoto: auth.currentUser?.profileImageUrl, updatePlaceName: { coords in
                    setPlaceName(place: coords)
                })
                .transition(.asymmetric(insertion: .identity, removal: .offset(y: 5)))
            }
        }
        .onChange(of: isHighlightExpanded, { _, newValue in
            if !newValue {
                for i in 0..<currentHightlightGroup.count {
                    self.currentHightlightGroup[i].player?.pause()
                    self.currentHightlightGroup[i].playVideo = false
                }
            }
        })
        .alert("Confirm Deletion", isPresented: $confirmDelete) {
            Button("Confirm", role: .destructive) {
                self.selectedMemories.forEach { element in
                    if let id = element.id {
                        UserService().deleteMemory(memID: id)
                        withAnimation(.easeInOut(duration: 0.2)){
                            if let idx = viewModel.allMemories.firstIndex(where: { $0.allMemories.contains(where: { $0.memory.id == id }) }) {
                                viewModel.allMemories[idx].allMemories.removeAll(where: { $0.memory.id == id })
                            }
                        }
                    }
                }
                withAnimation(.easeInOut(duration: 0.2)){
                    self.selectedMemories = []
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.1)){
                isScrolling = false
            }
            if currentPresentedName.isEmpty {
                currentPresentedName = reformatDateString(viewModel.allMemories.first?.date ?? "May 2021")
            }
            if viewModel.allMemories.isEmpty || (viewModel.allMemories.count == 1 && (viewModel.allMemories.first?.date ?? "") == "Recents"){
                fetchData()
            } else {
                getHighlights()
                limitQuery = true
            }
        }
        .onReceive(timer, perform: { _ in
            if !isExpanded && !showSend && !isHighlightExpanded && !showCamera {
                for i in 0..<self.testDataHighlights.count {
                    var possible = [Int]()
                    for j in 0..<self.testDataHighlights[i].allMemories.count {
                        if testDataHighlights[i].allMemories[j].player == nil && testDataHighlights[i].allMemories[j].id != testDataHighlights[i].firstMemory.id {
                            possible.append(j)
                        }
                    }
                    if let random = possible.randomElement() {
                        let move = self.testDataHighlights[i].allMemories[random]
                        self.testDataHighlights[i].allMemories.remove(at: random)
                        self.testDataHighlights[i].allMemories.insert(move, at: 0)
                        self.testDataHighlights[i].firstMemory = move
                    }
                }
            }
        })
        .onChange(of: selectingMemories) { _, _ in
            if !selectingMemories {
                selectedMemories = []
            }
        }
        .sheet(isPresented: $showStorySheet, content: {
            VStack(spacing: 20){
                HStack {
                    ZStack {
                        personView(size: 45)
                        if let image = auth.currentUser?.profileImageUrl {
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 45, height: 45)
                                .clipShape(Circle())
                        }
                    }
                    VStack(alignment: .leading){
                        Text("My Story - Public")
                            .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                            .font(.title3)
                        Text("Story will be visible on Map").font(.system(size: 13)).foregroundStyle(.gray)
                    }
                    Spacer()
                    Circle()
                        .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                        .frame(width: 24, height: 24)
                        .padding(12)
                        .overlay {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white).bold()
                                .font(.caption)
                        }
                }
                Button(action: {
                    showStorySheet = false
                    if let user = auth.currentUser {
                        var atleastOne = false
                        self.selectedMemories.forEach { possible in
                            if !self.postedStories.contains(possible.id ?? "NA") {
                                atleastOne = true
                                postedStories.append(possible.id ?? "")
                                
                                var lat: Double? = nil
                                var long: Double? = nil
                                if let latTemp = possible.lat, let longTemp = possible.long {
                                    lat = Double(latTemp)
                                    long = Double(longTemp)
                                }
                                
                                let postID = "\(UUID())"
                                GlobeService().uploadStory(caption: "", captionPos: 0.0, link: nil, imageLink: possible.image, videoLink: possible.video, id: postID, uid: user.id ?? "", username: user.username, userphoto: user.profileImageUrl, long: long, lat: lat, muted: false, infinite: nil)
                                
                                if let x = profile.users.firstIndex(where: { $0.user.id == user.id }) {
                                    let new = Story(id: postID, uid: user.id ?? "", username: user.username, profilephoto: user.profileImageUrl, long: long, lat: lat, text: nil, textPos: 0.0, imageURL: possible.image, videoURL: possible.video, timestamp: Timestamp(), link: nil, geoHash: "")
                                    
                                    if profile.users[x].stories != nil {
                                        profile.users[x].stories?.append(new)
                                    }
                                }
                            }
                        }
                        if atleastOne {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            viewModel.alertImage = "checkmark"
                            viewModel.alertReason = "Story Posted"
                            withAnimation(.easeInOut(duration: 0.2)){
                                viewModel.showAlert = true
                            }
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            viewModel.alertImage = "exclamationmark"
                            viewModel.alertReason = "Stories already posted."
                            withAnimation(.easeInOut(duration: 0.2)){
                                viewModel.showAlert = true
                            }
                        }
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        viewModel.alertImage = "wifi.exclamationmark"
                        viewModel.alertReason = "An error occured!"
                        withAnimation(.easeInOut(duration: 0.2)){
                            viewModel.showAlert = true
                        }
                    }
                }, label:{
                    HStack(spacing: 8){
                        Spacer()
                        Text("Post").font(.title3).bold()
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45.0)).font(.title3)
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .frame(height: 45)
                    .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .clipShape(Capsule())
                })
            }
            .padding(.horizontal)
            .presentationDetents([.height(140.0)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30.0)
        })
    }
    func getBackgroundCount() -> Int {
        var total = 0
        if !testDataHighlights.isEmpty {
            total += 265
        }
        viewModel.allMemories.forEach { element in
            total += 15
            let totalRows = Int(ceil(Double(element.allMemories.count) / 3.0))
            total += (totalRows * 210) + (totalRows * 3)
            total += 20
        }
        let totalBoxes = Int(ceil(Double(total) / 210.0))
        return totalBoxes
    }
    func showIndicator() -> Bool {
        let totalMemoryCount = viewModel.allMemories.reduce(0) { (total, memoryMonth) in
            total + memoryMonth.allMemories.count
        }
        return viewModel.allMemories.count >= 5 || totalMemoryCount > 15
    }
    func setPlaceName(place: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: place.latitude, longitude: place.longitude)
        for loc in self.fetchedPlaces {
            let existingLocation = CLLocation(latitude: loc.0.latitude, longitude: loc.0.longitude)
            if location.distance(from: existingLocation) < 2218.0 {
                currentPlaceName = loc.1
                return
            }
        }
        if !fetchingPlace {
            fetchingPlace = true
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    fetchingPlace = false
                }
                if error != nil { return }
                guard let placemark = placemarks?.first else { return }

                let city = placemark.locality
                let state = placemark.administrativeArea
                let country = placemark.country
              
                var flag: String = ""
                if let code = placemark.isoCountryCode {
                    flag = countryFlag(code)
                }
                if let city = city, var country = country {
                    if country == "Israel" {
                        country = "Palestine"
                        flag = "🇵🇸"
                    }
                    if let state = state, !state.isEmpty {
                        currentPlaceName = "\(city), \(state)"
                    } else {
                        currentPlaceName = "\(city), \(country)\(flag)"
                    }
                    self.fetchedPlaces.append((place, currentPlaceName))
                }
            }
        }
    }
    func fetchData(){
        var last: Timestamp? = nil
        if let check = viewModel.allMemories.last {
            last = check.allMemories.last?.memory.createdAt
        }
        
        UserService().getMemories(after: last) { memories in
            if memories.count < 28 {
                viewModel.noMoreMemories = true
            }
            limitQuery = true
            if memories.isEmpty {
                return
            }
            var tupiles: [(String, Memory)] = []
            memories.forEach { element in
                tupiles.append((formatFirebaseTimestampToMonthYear(element.createdAt), element))
            }
            tupiles.forEach { element in
                var new = animatableMemory(isImage: element.1.image != nil, memory: element.1)
                if let video = element.1.video, let url = URL(string: video) {
                    new.player = AVPlayer(url: url)
                }
                
                if let idxAdd = viewModel.allMemories.firstIndex(where: { $0.date == element.0 }) {
                    viewModel.allMemories[idxAdd].allMemories.append(new)
                } else {
                    let newMonth = MemoryMonths(date: element.0, allMemories: [new])
                    viewModel.allMemories.append(newMonth)
                }
            }
            getHighlights()
        }
    }
    func getHighlights() {
        if !viewModel.triedToFetchAsyncHighlights {
            let oldestFetched = viewModel.allMemories.last?.allMemories.last?.memory.createdAt ?? Timestamp()
            viewModel.triedToFetchAsyncHighlights = true
            for i in 1..<8 {
                var hStr = "\(i) Years Ago Today."
                if i == 1 {
                    hStr = "\(i) Year Ago Today."
                }
                if !testDataHighlights.contains(where: { $0.highlightSentence == hStr }) {
                    if let both = calculateStartEndTimestamps(yearsAgo: i) {
                        if oldestFetched.dateValue() < both.start.dateValue() {
                            var inBounds: [animatableMemory] = []
                            for i in 0..<viewModel.allMemories.count {
                                if let lastCheck = viewModel.allMemories[i].allMemories.last?.memory.createdAt.dateValue() {
                                    if lastCheck > both.end.dateValue() {
                                        continue
                                    }
                                    viewModel.allMemories[i].allMemories.forEach { element in
                                        let timeCreate = element.memory.createdAt.dateValue()
                                        if timeCreate >= both.start.dateValue() && timeCreate <= both.end.dateValue() {
                                            var tempNew = element
                                            tempNew.id = UUID().uuidString
                                            inBounds.append(tempNew)
                                        }
                                    }
                                }
                            }
                            if let first = inBounds.first {
                                var hStr = "\(i) Years Ago Today."
                                if i == 1 {
                                    hStr = "\(i) Year Ago Today."
                                }
                                self.testDataHighlights.append(MemoryHighLight(firstMemory: first, allMemories: inBounds, highlightSentence: hStr))
                            }
                        } else {
                            UserService().getHighlightMemories(start: both.start, end: both.end) { memories in
                                if let first = memories.first {
                                    var firstAnimate = animatableMemory(isImage: first.image != nil, memory: first)
                                    if let video = first.video, let url = URL(string: video) {
                                        firstAnimate.player = AVPlayer(url: url)
                                    }
                                    
                                    var animateArray = [animatableMemory]()
                                    memories.forEach { element in
                                        var new = animatableMemory(isImage: element.image != nil, memory: element)
                                        if let video = element.video, let url = URL(string: video) {
                                            new.player = AVPlayer(url: url)
                                        }
                                        animateArray.append(new)
                                    }
                                    var hStr = "\(i) Years Ago Today."
                                    if i == 1 {
                                        hStr = "\(i) Year Ago Today."
                                    }
                                    self.testDataHighlights.append(MemoryHighLight(firstMemory: firstAnimate, allMemories: animateArray, highlightSentence: hStr))
                                }
                            }
                        }
                    }
                }
            }
        }
        if testDataHighlights.count < 6 {
            viewModel.allMemories.reversed().forEach { element in
                if !usedAlready.contains(element.id) && testDataHighlights.count < 5 {
                    usedAlready.append(element.id)
                    var indexToAccessArray = [Int]()
                    if element.allMemories.count >= 3 {
                        let indexes = Array(0..<element.allMemories.count)
                        let shuffledIndexes = indexes.shuffled()
                        indexToAccessArray = Array(shuffledIndexes.prefix(3))
                        
                        var newAnim = [animatableMemory]()
                        indexToAccessArray.forEach { idx in
                            var tempNew = element.allMemories[idx]
                            tempNew.id = UUID().uuidString
                            newAnim.append(tempNew)
                        }
                        if let first = newAnim.first {
                            testDataHighlights.append(MemoryHighLight(firstMemory: first, allMemories: newAnim, highlightSentence: "\(Bool.random() ? "Flashback" : "Random") \(formatFirebaseTimestampToMonthYear(first.memory.createdAt))"))
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    func bottomSendView() -> some View {
        HStack(spacing: 20){
            Button(action: {
                deletedToggle.toggle()
                confirmDelete = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }, label: {
                ZStack {
                    Rectangle()
                        .frame(width: 40, height: 40)
                        .opacity(0.001).foregroundStyle(.gray)
                    VStack(spacing: 4){
                        Image(systemName: "trash").foregroundStyle(.red)
                            .symbolEffect(.bounce, value: deletedToggle)
                            .font(.system(size: 25)).frame(height: 32)
                        Text("Delete").font(.caption).foregroundStyle(.gray)
                    }
                }
            })
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                savedToggle.toggle()
                viewModel.alertReason = "Memories Saved"
                viewModel.alertImage = "square.and.arrow.down"
                withAnimation(.easeInOut(duration: 0.2)){
                    viewModel.showAlert = true
                }
                self.selectedMemories.forEach { element in
                    if let image = element.image {
                        downloadAndSaveImage(url: image)
                    } else if let video = element.video, let url = URL(string: video) {
                        downloadVideoFromURL(url)
                    }
                }
            }, label: {
                ZStack {
                    Rectangle()
                        .frame(width: 40, height: 40)
                        .opacity(0.001).foregroundStyle(.gray)
                    VStack(spacing: 4){
                        Image(systemName: "square.and.arrow.down")
                            .font(.title).foregroundStyle(colorScheme == .dark ? .white : .black)
                            .frame(height: 32)
                            .symbolEffect(.bounce, value: savedToggle)
                        Text("Save").font(.caption).foregroundStyle(.gray)
                    }
                }
            })
            if selectedMemories.count <= 10 {
                Button(action: {
                    showStorySheet = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Rectangle()
                            .frame(width: 40, height: 40)
                            .opacity(0.001).foregroundStyle(.gray)
                        VStack(spacing: 4){
                            Image(systemName: "globe")
                                .font(.title).foregroundStyle(colorScheme == .dark ? .white : .black)
                                .frame(height: 32)
                                .symbolEffect(.bounce, value: showStorySheet)
                            Text("+Story").font(.caption).foregroundStyle(.gray)
                        }
                    }
                })
            }
            if let id = selectedMemories.first?.id, selectedMemories.count == 1 {
                Button(action: {
                    if let pos = viewModel.allMemories.firstIndex(where: { $0.allMemories.contains(where: { $0.memory.id == id }) }) {
                        if let newID = viewModel.allMemories[pos].allMemories.first(where: { $0.memory.id == id })?.id {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.8)) {
                                expandedID = newID
                                isExpanded = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                withAnimation(.easeInOut(duration: 0.2)){
                                    showBack = true
                                }
                            }
                        }
                    }
                }, label: {
                    ZStack {
                        Rectangle()
                            .frame(width: 40, height: 40)
                            .opacity(0.001).foregroundStyle(.gray)
                        VStack(spacing: 4){
                            Image(systemName: "pencil")
                                .font(.title).foregroundStyle(colorScheme == .dark ? .white : .black)
                                .frame(height: 32)
                            Text("Edit").font(.caption).foregroundStyle(.gray)
                        }
                    }
                }).transition(.scale)
            }
            Spacer()
            if selectedMemories.count <= 10 {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    sendMems = selectedMemories
                    message.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                    withAnimation(.easeInOut(duration: 0.15)){
                        showSend = true
                    }
                }, label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title2).rotationEffect(.degrees(45.0))
                        .frame(width: 70, height: 35)
                        .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                        .clipShape(Capsule())
                })
            }
        }
        .padding(.bottom, 20).padding(.horizontal, 20)
        .frame(height: 90)
        .background(.ultraThickMaterial)
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .top){
            Divider().overlay(Color.gray)
        }
    }
    @ViewBuilder
    func headerView() -> some View {
        ZStack {
            HStack {
                if !selectingMemories {
                    Button {
                        close()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        ZStack {
                            Rectangle()
                                .frame(width: 40, height: 40)
                                .opacity(0.001).foregroundStyle(.gray)
                            Image(systemName: "xmark")
                                .font(.title3).bold()
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                    }.transition(.scale)
                } else {
                    Text("\(selectedMemories.count)/10")
                        .font(.headline)
                        .scaleEffect(tooManySelected ? 1.3 : 1.0)
                        .foregroundStyle(tooManySelected ? .red : (colorScheme == .dark ? .white : .black))
                }
                Spacer()
            }
            HStack {
                Spacer()
                Text(selectingMemories ? "Select.." : "Memories")
                    .font(.title2).bold()
                Spacer()
            }
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)){
                        selectingMemories.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    ZStack {
                        Rectangle()
                            .frame(width: 40, height: 40)
                            .opacity(0.001).foregroundStyle(.gray)
                        if selectingMemories {
                            Text("Cancel")
                                .font(.subheadline).bold()
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        } else {
                            Image(systemName: "checkmark.circle")
                                .font(.title).fontWeight(.semibold)
                                .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                                .transition(.scale)
                        }
                    }
                }
            }
        }
        .padding(.horizontal).padding(.bottom, 5)
        .background {
            TransparentBlurView(removeAllFilters: true)
                .blur(radius: 16, opaque: true)
                .background(colorScheme == .dark ? .black.opacity(0.7) : .white.opacity(0.7)).ignoresSafeArea()
        }
        .overlay(alignment: .bottom){
            if abs(self.offset) > 50.0 {
                Divider().overlay(Color.gray)
            }
        }
    }
    @ViewBuilder
    func indicator(iHeight: CGFloat) -> some View {
        HStack {
            Spacer()
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 2, height: iHeight)
                HStack(spacing: isDragging ? 60 : 5){
                    if isScrolling {
                        Text(currentPresentedName)
                            .font(.subheadline).bold()
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .foregroundStyle(.white)
                            .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                            .clipShape(Capsule())
                            .shadow(color: .gray, radius: 3)
                            .transition(.move(edge: .trailing))
                            .scaleEffect(isDragging ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: currentPresentedName)
                    }
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: 6, height: indicatorHeight)
                        .foregroundColor(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                }
                .background(.gray.opacity(0.001))
                .offset(x: 2, y: indicatorOffset - 5)
                .gesture(
                    DragGesture()
                        .onChanged({ value in
                            if !isDragging {
                                withAnimation(.easeInOut(duration: 0.2)){
                                    isDragging = true
                                }
                            }
                            if value.location.y >= 0.0 && value.location.y <= (iHeight - 30.0) {
                                let ratio = min(1, max(0, value.location.y / iHeight))
                                let backElements = getBackgroundCount()
                                let pickedIndex = Int(ratio * CGFloat(backElements))
                                scrollTo = "scroll\(pickedIndex)"
                                indicatorOffset = value.location.y
                            }
                        })
                        .onEnded({ value in
                            withAnimation(.easeInOut(duration: 0.2)){
                                isDragging = false
                            }
                        })
                )
            }
        }
        .padding(.top, 65)
        .opacity(isScrolling ? 1.0 : 0.0).padding(.trailing, 12)
    }
}

func extractImageAt(f_url: URL, time: CMTime, size: CGSize, completion: @escaping (UIImage) -> ()) {
    DispatchQueue.global(qos: .userInteractive).async {
        let asset = AVAsset(url: f_url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = size
        
        Task {
            do {
                let cgImage = try await generator.image(at: time).image
                guard let colorCorrectedImage = cgImage.copy(colorSpace: CGColorSpaceCreateDeviceRGB()) else {return}
                let thumbnail = UIImage(cgImage: colorCorrectedImage)
                await MainActor.run(body: {
                    completion(thumbnail)
                })
            } catch _ {
                print("Failed to Fetch Thumbnail")
            }
        }
    }
}

func calculateStartEndTimestamps(yearsAgo: Int) -> (start: Timestamp, end: Timestamp)? {
    let calendar = Calendar.current
    let now = Date()
    
    guard let yearsAgoDate = calendar.date(byAdding: .year, value: -yearsAgo, to: now) else {
        return nil
    }
    
    let startOfDay = calendar.startOfDay(for: yearsAgoDate)
    
    var components = DateComponents()
    components.day = 1
    components.second = -1
    guard let endOfDay = calendar.date(byAdding: components, to: startOfDay) else {
        return nil
    }
    
    let startTimestamp = Timestamp(date: startOfDay)
    let endTimestamp = Timestamp(date: endOfDay)
    
    return (start: startTimestamp, end: endTimestamp)
}

struct CustomVideoPlayer: UIViewControllerRepresentable {
    var player: AVPlayer
    func makeUIViewController(context: Context) -> some AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .clear
        controller.allowsVideoFrameAnalysis = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        uiViewController.player = player
    }
}

extension Binding where Value == [MemoryMonths] {
    func indexAnim(_ id: String) -> Binding<animatableMemory> {
        for monthIndex in self.wrappedValue.indices {
            if let memoryIndex = self.wrappedValue[monthIndex].allMemories.firstIndex(where: { $0.id == id }) {
                return Binding<animatableMemory>(
                    get: {
                        self.wrappedValue[monthIndex].allMemories[memoryIndex]
                    },
                    set: { newValue in
                        self.wrappedValue[monthIndex].allMemories[memoryIndex] = newValue
                    }
                )
            }
        }
        return Binding<animatableMemory>(
            get: {
                animatableMemory(isImage: true, memory: Memory(lat: 0.0, long: 0.0, createdAt: Timestamp()))
            },
            set: { _ in }
        )
    }
}

func extractLatLong(from string: String) -> (latitude: CGFloat, longitude: CGFloat)? {
    let components = string.split(separator: ",")

    guard components.count == 2,
          let lat = Double(components[0].trimmingCharacters(in: .whitespaces)),
          let long = Double(components[1].trimmingCharacters(in: .whitespaces)) else {
        return nil
    }

    return (latitude: CGFloat(lat), longitude: CGFloat(long))
}

extension View {
    @ViewBuilder
    func offset(completion: @escaping (CGRect)->()) -> some View {
        self
            .overlay {
                GeometryReader { geo in
                    let rect = geo.frame(in: .named("offset-namespace"))
                    Color.clear
                        .preference(key: OffsetKeyS.self, value: rect)
                        .onPreferenceChange(OffsetKeyS.self) { value in
                            completion(value)
                        }
                }
            }
    }
}
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}
struct OffsetKeyS: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
