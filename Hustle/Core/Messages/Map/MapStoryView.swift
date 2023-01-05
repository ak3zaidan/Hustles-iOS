import SwiftUI
import CoreLocation
import Kingfisher
import Firebase
import AVFoundation

struct MapMemoryView: View {
    @EnvironmentObject var locModel: LocationsViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: MessageViewModel
    @State var showStorySheet = false
    @State var storyCopied = false
    @FocusState private var focusField: FocusedField?
    @FocusState private var bottomFocusField: FocusedField?
    @State var caption = ""
    @State var showKeyboard = false
    @State var point: CGFloat = 0.0
    @State var infinite = false
    @State var editSingle = false
    @State var showSend: Bool = false
    @State var fetchingPlace = false
    @State var currentStoryIndex: Int = 0
    @State var pause: Bool = false
    @State var play: Bool = false
    @State var audioOn: Bool = false
    @State var audioOff: Bool = false
    @State var makeNil: Bool = false
    @State var videoID: Bool = false
    @State var isMuted = false
    @State var isPlaying = true
    @State var viewsUserID: String = ""
    @State var storyID: String = ""
    @State var currentLabel: String = ""
    @State var currentPlaceLabel: String = ""
    @State var showStats: Bool = false
    @Binding var memories: [LocationMap]
    @Binding var isDragging: Bool
    @Binding var closingNow: Bool
    @Binding var disableDrag: Bool
    @Binding var disableTopGesture: Bool
    @Binding var SwipeUpAction: Bool
    let currentMapPlaceName: String
    let isStory: Bool
    let isMap: Bool
    let close: (Int) -> Void
    
    var body: some View {
        ZStack(alignment: .top){
            Color.gray.opacity(0.001).ignoresSafeArea()
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
            ImageVideoMap(image: isStory ? memories[currentStoryIndex].story?.imageURL : memories[currentStoryIndex].memory?.image, video: isStory ? memories[currentStoryIndex].story?.videoURL : memories[currentStoryIndex].memory?.video, data: $memories[currentStoryIndex], play: $play, pause: $pause, audioOn: $audioOn, audioOff: $audioOff, makeNil: $makeNil, isPlaying: $isPlaying, isMuted: $isMuted)
                .id(videoID).offset(y: isMap ? 0.0 : (bottomFocusField == .one ? 25.0 : 0.0))
                .frame(maxWidth: showStats ? (widthOrHeight(width: false) * 0.15) : .infinity)
                .frame(maxHeight: showStats ? (widthOrHeight(width: false) * 0.25) : .infinity)
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
                    if (!caption.isEmpty || showKeyboard) && !isDragging && editSingle {
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
                    } else if isStory && !showStats {
                        if let text = memories[currentStoryIndex].story?.text, !text.isEmpty {
                            
                            let position = memories[currentStoryIndex].story?.textPos ?? 0.5
                            let finalPos = (widthOrHeight(width: false) - 105.0) * position
                            
                            VStack {
                                Text(text)
                                    .padding(.vertical, isMap ? 6 : 0)
                                    .padding(.bottom, isMap ? 0 : 1)
                                    .padding(.horizontal, 10)
                                    .font(.body).foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: widthOrHeight(width: true))
                                    .background {
                                        TransparentBlurView(removeAllFilters: true)
                                            .blur(radius: 9, opaque: true).background(.black.opacity(0.4))
                                    }
                                    .offset(y: finalPos)
                                Spacer()
                            }
                            .ignoresSafeArea()
                            .opacity(isDragging ? 0.0 : 1.0).animation(.easeInOut(duration: 0.2), value: isDragging)
                        }
                    } else if showStats {
                        let updated = popRoot.updatedView.first(where: { $0.0 == storyID })
                        let views = updated?.1 ?? (memories[currentStoryIndex].story?.views ?? []).count
                        let reactions = updated?.2 ?? countViewsContainsReaction(views: memories[currentStoryIndex].story?.views ?? [])
                        VStack {
                            Spacer()
                            HStack(spacing: 14){
                                HStack(spacing: 2){
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 16))
                                    Text("\(views)")
                                        .fontWeight(.light)
                                        .font(.subheadline)
                                }
                                HStack(spacing: 2){
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 16))
                                    Text("\(reactions)")
                                        .fontWeight(.light)
                                        .font(.subheadline)
                                }
                            }
                            .foregroundStyle(.white)
                        }
                        .padding(.bottom).transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                })
                .onChange(of: currentStoryIndex, { _, _ in
                    if let id = memories[currentStoryIndex].story?.id {
                        storyID = id
                    }
                    caption = ""
                    if isVideo() {
                        videoID.toggle()
                        play.toggle()
                        withAnimation(.easeInOut(duration: 0.1)){
                            isPlaying = true
                        }
                    }
                    if isStory {
                        setStoryTitle()
                    } else {
                        setTitle()
                    }
                })
                .overlay(content: {
                    if !editSingle && !isDragging && !showStats {
                        HStack(spacing: 3){
                            Rectangle().foregroundStyle(.yellow).opacity(0.001)
                                .onTapGesture(perform: {
                                    if currentStoryIndex > 0 {
                                        if isVideo() {
                                            pause.toggle()
                                            withAnimation(.easeInOut(duration: 0.1)){
                                                isPlaying = false
                                            }
                                        }
                                        currentStoryIndex -= 1
                                    }
                                })
                            Rectangle().foregroundStyle(.yellow).opacity(0.001)
                                .onTapGesture(perform: {
                                    if currentStoryIndex < (memories.count - 1) {
                                        if isVideo() {
                                            pause.toggle()
                                            withAnimation(.easeInOut(duration: 0.1)){
                                                isPlaying = false
                                            }
                                        }
                                        currentStoryIndex += 1
                                    } else {
                                        disableDrag = false
                                        if isVideo() {
                                            makeNil.toggle()
                                        }
                                        close(1)
                                    }
                                })
                        }
                    }
                })
                .padding(.bottom, 80)

            if isStory {
                if let posterUID = memories[currentStoryIndex].story?.uid, memories[currentStoryIndex].story?.id != nil {
                    
                    if posterUID != (auth.currentUser?.id ?? "Not") {
                        VStack {
                            Spacer()
                            StoryBottomBar(focusField: $bottomFocusField, storyID: $storyID, posterID: posterUID, currentID: auth.currentUser?.id ?? "", myMessages: auth.currentUser?.myMessages ?? [], storyViews: memories[currentStoryIndex].story?.views ?? [], disableDrag: $disableDrag, isMap: isMap, canOpenChat: true, bigger: false) {
                                viewModel.userMapID = posterUID
                                viewModel.userMap = nil
                                close(3)
                            }.KeyboardAwarePadding()
                        }
                        .padding(.bottom, bottomFocusField == .one ? 6 : 25)
                        .opacity(isDragging ? 0.0 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isDragging)
                        .ignoresSafeArea()
                    }
                }
            }
            if !showStats {
                overlayMemory()
                    .opacity(isDragging ? 0.0 : 1.0).animation(.easeInOut(duration: 0.2), value: isDragging)
                    .offset(y: isMap ? 0.0 : (bottomFocusField == .one ? 25.0 : 0.0))
            }
            if isStory {
                if let posterUID = memories[currentStoryIndex].story?.uid, memories[currentStoryIndex].story?.id != nil && posterUID == (auth.currentUser?.id ?? "Not") {
                    StoryStatsView(showStats: $showStats, storyID: $storyID, disableDrag: $disableDrag, contentURL: memories[currentStoryIndex].story?.imageURL ?? memories[currentStoryIndex].story?.videoURL ?? "", isVideo: isVideo(), lat: memories[currentStoryIndex].story?.lat, long: memories[currentStoryIndex].story?.long, views: memories[currentStoryIndex].story?.views ?? [], following: auth.currentUser?.following ?? [], isMap: isMap, cid: auth.currentUser?.id ?? "", disableNav: !isMap, canOpenProfile: true, canOpenChat: true, externalUpload: false, bigger: false) { uid in
                        makeNil.toggle()
                        viewModel.userMapID = uid
                        viewModel.userMap = nil
                        close(2)
                    } openChat: { uid in
                        makeNil.toggle()
                        viewModel.userMapID = uid
                        viewModel.userMap = nil
                        close(3)
                    } stopVideo: { stop in
                        if isVideo() {
                            if stop {
                                pause.toggle()
                            } else {
                                play.toggle()
                            }
                        }
                    } upload: {
                        
                    }
                    .padding(.bottom, 30)
                    .opacity(isDragging ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
                    .ignoresSafeArea()
                }
                if showStats {
                    VStack {
                        HStack {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                if let id = memories[currentStoryIndex].story?.id {
                                    GlobeService().deleteStory(storyID: id)
                                    
                                    popRoot.alertImage = "checkmark"
                                    popRoot.alertReason = "Story Deleted"
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        popRoot.showAlert = true
                                    }
                                }
                                withAnimation(.easeInOut(duration: 0.15)){
                                    showStats = false
                                }
                                disableDrag = false
                            }, label: {
                                ZStack {
                                    Rectangle()
                                        .foregroundStyle(.gray).opacity(0.001)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                        .font(.title3)
                                }
                            })
                            Spacer()
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.15)){
                                    showStats = false
                                }
                                disableDrag = false
                            }, label: {
                                ZStack {
                                    Rectangle()
                                        .foregroundStyle(.gray).opacity(0.001)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "xmark")
                                        .foregroundStyle(.white)
                                        .font(.title3).fontWeight(.semibold)
                                }
                            })
                        }.padding(.horizontal).transition(.move(edge: .top))
                        Spacer()
                    }
                }
            }
        }
        .onChange(of: SwipeUpAction, { _, _ in
            if let pUID = memories[currentStoryIndex].story?.uid, pUID == (auth.currentUser?.id ?? "Not") {
                withAnimation(.easeInOut(duration: 0.2)){
                    showStats = true
                    disableDrag = true
                }
            }
        })
        .onChange(of: showStats, { _, _ in
            if isVideo() && !isMuted {
                if showStats {
                    audioOff.toggle()
                } else {
                    audioOn.toggle()
                }
            }
            if !showStats {
                disableDrag = false
            }
        })
        .onChange(of: closingNow, { _, _ in
            makeNil.toggle()
        })
        .onChange(of: isDragging, { _, _ in
            if isVideo() {
                if isDragging {
                    pause.toggle()
                    withAnimation(.easeInOut(duration: 0.1)){
                        isPlaying = false
                    }
                } else {
                    play.toggle()
                    withAnimation(.easeInOut(duration: 0.1)){
                        isPlaying = true
                    }
                }
            }
        })
        .overlay(content: {
            if let memory = memories[currentStoryIndex].memory, showSend {
                SendMemoryView(data: [memory], caption: $caption, position: point, infinite: infinite) {
                    withAnimation(.easeInOut(duration: 0.15)){
                        showSend = false
                    }
                    if !editSingle {
                        disableDrag = false
                    }
                    if isVideo() {
                        if !self.isMuted {
                            audioOn.toggle()
                        }
                        if self.isPlaying {
                            play.toggle()
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
                        if let latTemp = memories[currentStoryIndex].memory?.lat, let longTemp = memories[currentStoryIndex].memory?.long {
                            lat = Double(latTemp)
                            long = Double(longTemp)
                        }
                        
                        let postID = "\(UUID())"
                        GlobeService().uploadStory(caption: caption, captionPos: pos, link: nil, imageLink: memories[currentStoryIndex].memory?.image, videoLink: memories[currentStoryIndex].memory?.video, id: postID, uid: user.id ?? "", username: user.username, userphoto: user.profileImageUrl, long: long, lat: lat, muted: false, infinite: infinite == true ? true : nil)
                        
                        if let x = profile.users.firstIndex(where: { $0.user.id == user.id }) {
                            let new = Story(id: postID, uid: user.id ?? "", username: user.username, profilephoto: user.profileImageUrl, long: long, lat: lat, text: caption.isEmpty ? nil : caption, textPos: pos, imageURL: memories[currentStoryIndex].memory?.image, videoURL: memories[currentStoryIndex].memory?.video, timestamp: Timestamp(), link: nil, geoHash: "")
                            
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
        .onAppear {
            if let id = memories[currentStoryIndex].story?.id {
                storyID = id
            }
            if isVideo() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    play.toggle()
                    withAnimation(.easeInOut(duration: 0.1)){
                        isPlaying = true
                    }
                }
            }
            if isStory {
                setStoryTitle()
            } else {
                setTitle()
            }
        }
    }
    func isVideo() -> Bool {
        if memories[currentStoryIndex].memory?.video != nil || memories[currentStoryIndex].story?.videoURL != nil {
            return true
        }
        return false
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
                .padding(.horizontal, 10)
                .frame(minHeight: 28)
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
    func setStoryTitle() {
        if let sid = memories[currentStoryIndex].story?.id, memories[currentStoryIndex].infoString == nil || (memories[currentStoryIndex].infoString ?? "").isEmpty {
            let createdDate = (memories[currentStoryIndex].story?.timestamp ?? Timestamp()).dateValue()
            let currentDate = Date()
            let timeInterval = currentDate.timeIntervalSince(createdDate)
            
            let oneMinute: TimeInterval = 60
            let oneHour: TimeInterval = 3600
            let oneDay: TimeInterval = 86400
            let oneWeek: TimeInterval = 604800
            let oneMonth: TimeInterval = 2592000
            
            var finalStr = ""
            if timeInterval < oneMinute {
                finalStr = "Just Now"
            } else if timeInterval < oneHour {
                let minutes = Int(timeInterval / oneMinute)
                finalStr = "\(minutes)m ago"
            } else if timeInterval < oneDay {
                let hours = Int(timeInterval / oneHour)
                finalStr = "\(hours)h ago"
            } else if timeInterval < oneWeek {
                let days = Int(timeInterval / oneDay)
                finalStr = "\(days) \(days == 1 ? "day" : "days") ago"
            } else if timeInterval < oneMonth {
                let weeks = Int(timeInterval / oneWeek)
                finalStr = "\(weeks) \(weeks == 1 ? "week" : "weeks") ago"
            } else {
                let months = Int(timeInterval / oneMonth)
                finalStr = "\(months) \(months == 1 ? "month" : "months") ago"
            }
            memories[currentStoryIndex].infoString = finalStr
            currentLabel = finalStr
            if let lat = memories[currentStoryIndex].story?.lat, let long = memories[currentStoryIndex].story?.long {
                setPlaceName(place: CLLocationCoordinate2D(latitude: lat, longitude: long)) { loc_str in
                    if let loc_str {
                        if let index = locModel.stories.firstIndex(where: { $0.story?.id == sid }) {
                            locModel.stories[index].infoString = finalStr + " - " + loc_str
                            locModel.stories[index].placeString = loc_str
                        }
                        if let index = memories.firstIndex(where: { $0.story?.id == sid }) {
                            memories[index].infoString = finalStr + " - " + loc_str
                            memories[index].placeString = loc_str
                            if index == currentStoryIndex {
                                currentPlaceLabel = loc_str
                                currentLabel = finalStr + " - " + loc_str
                            }
                        }
                    }
                }
            }
        } else {
            currentLabel = memories[currentStoryIndex].infoString ?? ""
        }
    }
    func setTitle() {
        if memories[currentStoryIndex].placeString == nil {
            if let memID = memories[currentStoryIndex].memory?.id, let lat = memories[currentStoryIndex].memory?.lat, let long = memories[currentStoryIndex].memory?.long {
                
                setPlaceName(place: CLLocationCoordinate2D(latitude: lat, longitude: long)) { loc_str in
                    if let loc_str {
                        if let index = locModel.memories.firstIndex(where: { $0.memory?.id == memID }) {
                            locModel.memories[index].placeString = loc_str
                        }
                        if let index = memories.firstIndex(where: { $0.memory?.id == memID }) {
                            memories[index].placeString = loc_str
                            if index == currentStoryIndex {
                                currentPlaceLabel = loc_str
                            }
                        }
                    }
                }
            }
        } else {
            currentPlaceLabel = memories[currentStoryIndex].placeString ?? ""
        }
        if memories[currentStoryIndex].infoString == nil || (memories[currentStoryIndex].infoString ?? "").isEmpty {
            let date = (memories[currentStoryIndex].memory?.createdAt ?? Timestamp()).dateValue()
            let calendar = Calendar.current
            let today = Date()
            var finalString: String

            let components = calendar.dateComponents([.day, .year], from: date, to: today)
            let yearsAgo = components.year ?? 0
            let days = components.day ?? 0

            if yearsAgo >= 1 && yearsAgo <= 20 && days == 0 {
                finalString = "\(yearsAgo) Years Ago Today"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM, yyyy"
                finalString = "Flashback \(dateFormatter.string(from: date))"
            }
            
            memories[currentStoryIndex].infoString = finalString
            currentLabel = finalString
            if let id = memories[currentStoryIndex].memory?.id, let index = locModel.memories.firstIndex(where: { $0.memory?.id == id }) {
                locModel.memories[index].infoString = finalString
            }
        } else {
            currentLabel = memories[currentStoryIndex].infoString ?? ""
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
                        disableDrag = false
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
                            if let image = memories[currentStoryIndex].memory?.image {
                                downloadAndSaveImage(url: image)
                                popRoot.alertReason = "Image Saved"
                            } else if let video = memories[currentStoryIndex].memory?.video {
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
                        if isVideo() {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if isMuted {
                                    audioOn.toggle()
                                } else {
                                    audioOff.toggle()
                                }
                                withAnimation(.easeInOut(duration: 0.1)){
                                    isMuted.toggle()
                                }
                            } label: {
                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundColor(.white).bold().font(.system(size: 21))
                                    .frame(width: 45, height: 45)
                                    .background(.black.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if isPlaying {
                                    pause.toggle()
                                } else {
                                    play.toggle()
                                }
                                withAnimation(.easeInOut(duration: 0.1)){
                                    isPlaying.toggle()
                                }
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
            } else if isStory {
                VStack(spacing: 15){
                    HStack(spacing: 4){
                        ForEach(0..<memories.count, id: \.self) { i in
                            Rectangle()
                                .frame(height: 1.5).foregroundStyle(.white)
                                .opacity((i <= currentStoryIndex) ? 1.0 : 0.4)
                        }
                    }
                    let isVid = isVideo()
                    HStack(spacing: isVid ? 8 : 12){
                        if let uid = memories[currentStoryIndex].story?.uid {
                            if isMap {
                                Button(action: {
                                    makeNil.toggle()
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    viewModel.userMapID = uid
                                    close(2)
                                }, label: {
                                    HStack(spacing: 10){
                                        ZStack {
                                            personView(size: 45)
                                            KFImage(URL(string: memories[currentStoryIndex].story?.profilephoto ?? ""))
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 45, height: 45)
                                                .clipShape(Circle())
                                                .shadow(color: .gray, radius: 2)
                                        }
                                        VStack(alignment: .leading, spacing: 5){
                                            Text("@\(memories[currentStoryIndex].story?.username ?? "----")").font(.subheadline).fontWeight(.heavy)
                                                .shadow(color: .gray, radius: 3).lineLimit(1)
                                            Text(currentLabel).font(.caption)
                                                .fontWeight(.semibold).shadow(color: .gray, radius: 2).lineLimit(1).truncationMode(.tail)
                                        }.foregroundStyle(.white)
                                    }
                                })
                            } else {
                                HStack(spacing: 5){
                                    ZStack {
                                        personView(size: 45)
                                        KFImage(URL(string: memories[currentStoryIndex].story?.profilephoto ?? ""))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                            .shadow(color: .gray, radius: 2)
                                    }
                                    VStack(alignment: .leading, spacing: 5){
                                        Text("@\(memories[currentStoryIndex].story?.username ?? "----")").font(.subheadline).fontWeight(.heavy)
                                            .shadow(color: .gray, radius: 3).lineLimit(1)
                                        Text(currentLabel).font(.caption)
                                            .fontWeight(.semibold).lineLimit(1).truncationMode(.tail)
                                    }.foregroundStyle(.white)
                                }
                            }
                        } else {
                            HStack(spacing: 5){
                                ZStack {
                                    personView(size: 45)
                                    KFImage(URL(string: memories[currentStoryIndex].story?.profilephoto ?? ""))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 45, height: 45)
                                        .clipShape(Circle())
                                        .shadow(color: .gray, radius: 2)
                                }
                                VStack(alignment: .leading, spacing: 5){
                                    Text("@\(memories[currentStoryIndex].story?.username ?? "----")").font(.subheadline).fontWeight(.heavy)
                                        .shadow(color: .gray, radius: 3).lineLimit(1)
                                    Text(currentLabel).font(.caption)
                                        .fontWeight(.semibold).lineLimit(1).truncationMode(.tail)
                                }.foregroundStyle(.white)
                            }
                        }
                        Spacer()
                        if isVid {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.1)){
                                    isMuted.toggle()
                                }
                            } label: {
                                ZStack {
                                    Rectangle()
                                        .foregroundStyle(.gray).opacity(0.001)
                                        .frame(width: 30, height: 40)
                                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.1.fill")
                                        .contentTransition(.symbolEffect(.replace))
                                        .font(.title2).bold().foregroundStyle(.white)
                                }
                            }
                        }
                        Menu(content: {
                            Text("\(currentPlaceLabel.isEmpty ? currentMapPlaceName : currentPlaceLabel)\n\(formatFirebaseTimestampExtended(memories[currentStoryIndex].story?.timestamp ?? Timestamp()))")
                            Divider()
                            if (memories[currentStoryIndex].story?.uid == auth.currentUser?.id) {
                                Button(role: .destructive, action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if let id = memories[currentStoryIndex].story?.id {
                                        GlobeService().deleteStory(storyID: id)
                                        
                                        popRoot.alertImage = "checkmark"
                                        popRoot.alertReason = "Story Deleted"
                                        withAnimation(.easeInOut(duration: 0.2)){
                                            popRoot.showAlert = true
                                        }
                                    }
                                }, label: {
                                    Label("Delete", systemImage: "trash")
                                })
                            } else {
                                Button(role: .destructive, action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    popRoot.alertImage = "checkmark"
                                    popRoot.alertReason = "Story Reported"
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        popRoot.showAlert = true
                                    }
                                }, label: {
                                    Label("Report", systemImage: "flag.fill")
                                })
                            }
                            Button(role: .cancel, action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if let id = memories[currentStoryIndex].story?.id {
                                    UIPasteboard.general.string = "https://hustle.page/story/\(id)/"
                                }
                                popRoot.alertImage = "checkmark"
                                popRoot.alertReason = "Story Link Copied"
                                withAnimation(.easeInOut(duration: 0.2)){
                                    popRoot.showAlert = true
                                }
                            }, label: {
                                Label("Copy Story Link", systemImage: "link")
                            })
                            if let url = memories[currentStoryIndex].story?.link, let url = URL(string: url) {
                                Link(destination: url) {
                                    Label("Open Link", systemImage: "link")
                                }
                            }
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .foregroundStyle(.gray).opacity(0.001)
                                    .frame(width: 30, height: 40)
                                Image(systemName: "ellipsis.circle").font(.title2).bold().foregroundStyle(.white)
                            }
                        })
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            if isVideo() {
                                makeNil.toggle()
                            }
                            close(1)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label:{
                            ZStack {
                                Rectangle().foregroundStyle(.gray).opacity(0.001)
                                    .frame(width: 30, height: 40)
                                Image(systemName: "xmark").font(.title3).bold().foregroundStyle(.white)
                            }
                        })
                    }
                }.padding(.top, 16).padding(.horizontal, 12)
            } else {
                VStack(spacing: 15){
                    HStack(spacing: 4){
                        ForEach(0..<memories.count, id: \.self) { i in
                            Rectangle()
                                .frame(height: 1.5).foregroundStyle(.white)
                                .opacity((i <= currentStoryIndex) ? 1.0 : 0.4)
                        }
                    }
                    let isVid = isVideo()
                    HStack(spacing: isVid ? 8 : 12){
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            if isVideo() {
                                makeNil.toggle()
                            }
                            close(1)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label:{
                            ZStack {
                                Rectangle().foregroundStyle(.gray).opacity(0.001)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "xmark").font(.title3).bold().foregroundStyle(.white)
                            }
                        })
                        VStack(alignment: .leading, spacing: 3){
                            Text(currentLabel).font(.subheadline).bold()
                                .shadow(color: .gray, radius: 3).lineLimit(1)
                            Text(formatFirebaseTimestamp(memories[currentStoryIndex].memory?.createdAt ?? Timestamp())).font(.caption).lineLimit(1)
                        }.foregroundStyle(.white)
                        Spacer()
                        if isVid {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.1)){
                                    isMuted.toggle()
                                }
                            } label: {
                                ZStack {
                                    Rectangle()
                                        .foregroundStyle(.gray).opacity(0.001)
                                        .frame(width: 30, height: 40)
                                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.1.fill")
                                        .contentTransition(.symbolEffect(.replace))
                                        .font(.title2).bold().foregroundStyle(.white)
                                }
                            }
                        }
                        Menu(content: {
                            Text("\(currentPlaceLabel.isEmpty ? currentMapPlaceName : currentPlaceLabel)\n\(formatFirebaseTimestampExtended(memories[currentStoryIndex].memory?.createdAt ?? Timestamp()))")
                            Divider()
                            Button(role: .destructive, action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if let id = memories[currentStoryIndex].memory?.id {
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
                                    .frame(width: 30, height: 40)
                                Image(systemName: "ellipsis").font(.title2).bold().foregroundStyle(.white)
                            }
                        })
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)){
                                editSingle = true
                            }
                            disableDrag = true
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .foregroundStyle(.gray).opacity(0.001)
                                    .frame(width: 30, height: 40)
                                Image(systemName: "pencil").font(.title2).bold().foregroundStyle(.white)
                            }
                        })
                    }
                }
                .padding(.top, 16).padding(.horizontal, 12)
            }
            Spacer()
            if !isStory {
                let place = memories[currentStoryIndex].placeString ?? currentMapPlaceName
                if !place.isEmpty {
                    HStack {
                        Spacer()
                        Text(place)
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
                        if let id = memories[currentStoryIndex].memory?.id, let uid = auth.currentUser?.id {
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
                        if (memories[currentStoryIndex].infoString ?? "") != "Recents" && caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            caption = (memories[currentStoryIndex].infoString ?? "Memory")
                            point = widthOrHeight(width: false) * 0.4
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showStorySheet = true
                    }, label:{
                        HStack(spacing: 8){
                            Spacer()
                            ZStack {
                                personView(size: 38)
                                if let image = auth.currentUser?.profileImageUrl {
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
                        if isVideo() {
                            audioOff.toggle()
                            pause.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
                        withAnimation(.easeInOut(duration: 0.1)){
                            showSend = true
                        }
                        if (memories[currentStoryIndex].infoString ?? "") != "Recents" && caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            caption = (memories[currentStoryIndex].infoString ?? "")
                            point = widthOrHeight(width: false) * 0.45
                        }
                        disableDrag = true
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
            }
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
    func setPlaceName(place: CLLocationCoordinate2D, completion: @escaping(String?) -> Void) {
        let location = CLLocation(latitude: place.latitude, longitude: place.longitude)
        if !fetchingPlace {
            fetchingPlace = true
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    fetchingPlace = false
                }
                if error != nil {
                    completion(nil)
                    return
                }
                guard let placemark = placemarks?.first else {
                    completion(nil)
                    return
                }

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
                        completion("\(city), \(state)")
                    } else {
                        completion("\(city), \(country)\(flag)")
                    }
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
}

func formatFirebaseTimestampExtended(_ timestamp: Timestamp) -> String {
    let date = timestamp.dateValue()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d"
    var dateString = dateFormatter.string(from: date)
    let day = Calendar.current.component(.day, from: date)
    dateString += daySuffix(from: day)
    dateFormatter.dateFormat = ", 'at' h:mm a"
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

struct ImageVideoMap: View {
    @Environment(\.scenePhase) var scenePhase
    private let screenSize = UIScreen.main.bounds
    @State var videoPlayer: AVPlayer? = nil
    let image: String?
    let video: URL?
    @Binding var data: LocationMap
    @Binding var pause: Bool
    @Binding var play: Bool
    @Binding var audioOn: Bool
    @Binding var audioOff: Bool
    @Binding var makeNil: Bool
    @Binding var isPlaying: Bool
    @Binding var isMuted: Bool
    
    init(image: String?, video: String?, data: Binding<LocationMap>, play: Binding<Bool>, pause: Binding<Bool>, audioOn: Binding<Bool>, audioOff: Binding<Bool>, makeNil: Binding<Bool>, isPlaying: Binding<Bool>, isMuted: Binding<Bool>) {
        self.image = image
        if let video, let url = URL(string: video) {
            self.video = url
            videoPlayer = AVPlayer(url: url)
        } else {
            self.video = nil
        }
        self._data = data
        self._play = play
        self._pause = pause
        self._audioOn = audioOn
        self._audioOff = audioOff
        self._makeNil = makeNil
        self._isPlaying = isPlaying
        self._isMuted = isMuted
    }
    
    var body: some View {
        GeometryReader {
            let size = $0.size

            if let imageURL = image {
                KFImage(URL(string: imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20).stroke(.gray, lineWidth: 1.0)
                    }
                    .background(content: {
                        ProgressView().scaleEffect(1.2)
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else if data.preview != nil || videoPlayer != nil {
                let image = data.preview != nil ? Image(uiImage: data.preview!) : Image(systemName: "")
                
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .overlay {
                        if let player = videoPlayer {
                            ZStack {
                                ProgressView().scaleEffect(1.5)
                                CustomVideoPlayer(player: player)
                                    .transition(.identity)
                                    .onAppear {
                                        player.isMuted = isMuted
                                        player.play()
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
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.gray).opacity(0.2)
                    .overlay(content: {
                        ProgressView().scaleEffect(1.2)
                    })
                    .onAppear {
                        if let url = video {
                            extractImageAt(f_url: url, time: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) { thumbnail in
                                self.data.preview = thumbnail
                            }
                        }
                    }
            }
        }
        .onDisappear(perform: {
            videoPlayer?.pause()
            videoPlayer = nil
        })
        .onChange(of: play, { _, _ in
            videoPlayer?.play()
        })
        .onChange(of: pause, { _, _ in
            videoPlayer?.pause()
        })
        .onChange(of: audioOn, { _, _ in
            videoPlayer?.isMuted = false
        })
        .onChange(of: audioOff, { _, _ in
            videoPlayer?.isMuted = true
        })
        .onChange(of: makeNil, { _, _ in
            videoPlayer?.pause()
            videoPlayer?.isMuted = true
            videoPlayer = nil
            isPlaying = false
            isMuted = true
        })
        .onChange(of: isMuted, { _, _ in
            videoPlayer?.isMuted = isMuted
        })
        .onChange(of: scenePhase) { _, newPhase in
            if videoPlayer != nil {
                if newPhase == .inactive {
                    videoPlayer?.pause()
                    isPlaying = false
                } else if newPhase == .active {
                    videoPlayer?.play()
                    isPlaying = true
                } else if newPhase == .background {
                    videoPlayer?.pause()
                    isPlaying = false
                }
            }
        }
    }
}
