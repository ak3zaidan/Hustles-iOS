import SwiftUI
import AVFoundation
import Kingfisher
import Firebase
import CoreLocation

struct CubeTopStory: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @FocusState private var bottomFocusField: FocusedField?
    @Environment(\.scenePhase) var scenePhase
    @GestureState private var isDragging = false
    @State var offset: CGSize = .zero
    @State var switchedToStartLast = false
    @State var small: CGFloat = 0.0
    @State var big: CGFloat = 0.0
    @State var opacity = 0.0
    @State private var progress: CGFloat = .zero
    
    @State var isMuted = false
    @State var isPlaying = true
    @State var player: AVPlayer? = nil
    @State var showMenu = false
    @State var showMenuAnim = false
    @State var menuTitle: String = ""
    @State var showStats: Bool = false
    @State var disableDrag: Bool = false
    @State var hideEverything: Bool = false
    @State var storyID: String = ""
    @State var preventClose: Bool = true
    @State var closing: Bool = false
    @State var clickedToChangeSelection: String = ""
   
    @Binding var selection: String
    @Binding var storiesUidOrder: [String]
    @Binding var isMainExpanded: Bool
    @Binding var showProfile: Bool
    @Binding var showChat: Bool
    @Binding var profileUID: String
    @Binding var showNewTweetView: Bool
    @Binding var initialContent: uploadContent?
    @Binding var tempMid: String
    let animation: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .top){
            ZStack {
                Color.black.ignoresSafeArea()
                Color.blue.opacity(0.06).ignoresSafeArea()
            }.opacity(opacity)
            
            ZStack {
                TabView(selection: $selection){
                    ForEach(realOrder(), id: \.self) { story in
                        if let idx = viewModel.users.firstIndex(where: { $0.user.id == story }) {
                            if let stories = viewModel.users[idx].stories, !stories.isEmpty {
                                
                                let tempIndex = viewModel.users[idx].storyIndex
                                
                                GeometryReader { g in
                                    ZStack(alignment: .top){
                                        singleStory(stories: stories, uid: story, index: tempIndex, idx: idx)
                                        
                                        if showStats {
                                            VStack {
                                                HStack {
                                                    Button(action: {
                                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                        if let id = stories[tempIndex].id {
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
                                    .frame(width: g.frame(in: .global).width, height: g.frame(in: .global).height)
                                    .rect { tabProgress(tabID: story, rect: $0, size: g.size) }
                                    .rotation3DEffect(
                                        .init(degrees: isDragging || closing ? 0.0 : getAngle(xOffset: g.frame(in: .global).minX)),
                                        axis: (x: 0.0, y: 1.0, z: 0.0),
                                        anchor: g.frame(in: .global).minX > 0 ? .leading : .trailing,
                                        perspective: 2.5
                                    )
                                }
                                .tag(story)
                                .scaleEffect(scale, anchor: .trailing)
                                .offset(y: offset.height)
                                .offset(y: offset.height * -0.6)
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .matchedGeometryEffect(id: tempMid, in: animation)
            .transition(.scale)
            
            if showMenu {
                menuView()
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: {
            withAnimation(.easeInOut(duration: 0.2)){
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                preventClose = false
            }
            
            if let profile = viewModel.users.first(where: { $0.user.id == selection }) {
                if let stories = profile.stories {
                    let storyIndex = profile.storyIndex
                    
                    if storyIndex < stories.count {
                        storyID = stories[storyIndex].id ?? ""
                        
                        if let video = stories[storyIndex].videoURL, let url = URL(string: video) {
                            player = AVPlayer(url: url)
                            player?.play()
                            player?.isMuted = isMuted
                            
                            NotificationCenter.default.addObserver (
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: player?.currentItem,
                                queue: .main
                            ) { _ in
                                player?.seek(to: .zero)
                                player?.play()
                            }
                            player?.actionAtItemEnd = .none
                        }
                    }
                }
            }
            
            setStoryTitle()
        })
        .onChange(of: selection, { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if clickedToChangeSelection != selection {
                    indexChanged()
                } else {
                    clickedToChangeSelection = ""
                }
                let temp = realOrder()
                if selection != tempMid && selection != temp.first && selection != temp.last {
                    tempMid = selection
                }
            }
        })
        .onChange(of: showStats, { _, _ in
            if isVideo() && !isMuted {
                if showStats {
                    player?.isMuted = true
                } else {
                    player?.isMuted = false
                }
            }
        })
        .onChange(of: scenePhase) { _, newPhase in
            if player != nil {
                if newPhase == .inactive {
                    player?.pause()
                    isPlaying = false
                } else if newPhase == .active {
                    player?.play()
                    isPlaying = true
                } else if newPhase == .background {
                    player?.pause()
                    isPlaying = false
                }
            }
        }
        .onChange(of: isDragging, { _, _ in
            if isVideo() {
                if isDragging {
                    player?.pause()
                    withAnimation(.easeInOut(duration: 0.1)){
                        isPlaying = false
                    }
                } else {
                    player?.play()
                    withAnimation(.easeInOut(duration: 0.1)){
                        isPlaying = true
                    }
                }
            }
        })
        .simultaneousGesture(
            DragGesture()
                .updating($isDragging, body: { _, dragState, _ in
                    dragState = true
                }).onChanged({ value in
                    if showMenu {
                        withAnimation(.easeInOut(duration: 0.15)){
                            showMenu = false
                        }
                    }
                    if !disableDrag && value.translation.height > 0 {
                        if showStats {
                            if value.translation.height > 30 {
                                withAnimation(.easeInOut(duration: 0.2)){
                                    showStats = false
                                }
                            }
                        } else {
                            var translation = value.translation
                            translation = isDragging && isMainExpanded ? translation : .zero
                            offset = translation
                        }
                    }
                }).onEnded({ value in
                    if !disableDrag {
                        if value.translation.height > 120 {
                            if isVideo() {
                                player?.pause()
                            }
                            player = nil
                            closeView()
                        } else {
                            withAnimation(.easeOut(duration: 0.25)) {
                                offset = .zero
                            }
                            if value.translation.height < -30 {
                                if selection == (auth.currentUser?.id ?? "Not") {
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        showStats = true
                                    }
                                }
                            }
                        }
                    }
                })
        )
    }
    func realOrder() -> [String] {
        if let id = auth.currentUser?.id, let stories = viewModel.users.first(where: { $0.user.id == id })?.stories, !stories.isEmpty {
            return [id] + storiesUidOrder
        }
        
        return storiesUidOrder
    }
    func singleStory(stories: [Story], uid: String, index: Int, idx: Int) -> some View {
        ZStack(alignment: .top){
            ZStack(alignment: .top){
                GeometryReader {
                    let size = $0.size
                    
                    ZStack(alignment: .top){
                        if let image = stories[index].imageURL {
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .background(content: {
                                    RoundedRectangle(cornerRadius: 20)
                                        .foregroundColor(.gray).opacity(0.2)
                                        .overlay(content: {
                                            ProgressView().scaleEffect(1.2)
                                        })
                                })
                                .contentShape(Rectangle())
                        } else if player != nil || popRoot.previewStory[stories[index].videoURL ?? ""] != nil {
                            let videoS = stories[index].videoURL ?? ""
                            let image = popRoot.previewStory[videoS] ?? Image(systemName: "")
                            
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(.gray).opacity(0.2)
                                .overlay(content: {
                                    ProgressView().scaleEffect(1.2)
                                })
                            
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: size.width, height: size.height)
                                .overlay(content: {
                                    ProgressView().scaleEffect(1.5)
                                })
                                .overlay {
                                    if let player = player, selection == uid && isCurrent(expected: videoS) {
                                        CustomVideoPlayer(player: player).transition(.identity)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(.gray).opacity(0.2)
                                .overlay(content: {
                                    ProgressView().scaleEffect(1.2)
                                })
                        }
                    }
                    .overlay(content: {
                        if showStats {
                            let updated = popRoot.updatedView.first(where: { $0.0 == storyID })
                            let views = updated?.1 ?? (stories[index].views ?? []).count
                            let reactions = updated?.2 ?? countViewsContainsReaction(views: stories[index].views ?? [])
                            VStack {
                                Spacer()
                                HStack(spacing: 14){
                                    HStack(spacing: 2){
                                        Image(systemName: "eye.fill")
                                            .font(.system(size: 16))
                                        Text("\(views)")
                                            .fontWeight(.light).font(.subheadline)
                                    }
                                    HStack(spacing: 2){
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 16))
                                        Text("\(reactions)")
                                            .fontWeight(.light).font(.subheadline)
                                    }
                                }.foregroundStyle(.white)
                            }.padding(.bottom).transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            HStack(spacing: 0){
                                Color.gray.opacity(0.001)
                                    .onTapGesture {
                                        if bottomFocusField == .one {
                                            bottomFocusField = .two
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        } else {
                                            let tempArr = realOrder()
                                            
                                            if let index = tempArr.firstIndex(where: { $0 == selection }) {
                                                if isVideo() {
                                                    player?.pause()
                                                    withAnimation(.easeInOut(duration: 0.1)){
                                                        isPlaying = false
                                                    }
                                                }
                                                
                                                if let profile = viewModel.users.first(where: { $0.user.id == selection }) {
                                                    let storyIndex = profile.storyIndex
                                                    
                                                    if storyIndex > 0 {
                                                        viewModel.users[idx].storyIndex -= 1
                                                        indexChanged()
                                                    } else if index > 0 {
                                                        switchedToStartLast = index == 1
                                                        clickedToChangeSelection = tempArr[index - 1]
                                                        withAnimation(.easeInOut(duration: 0.25)){
                                                            selection = tempArr[index - 1]
                                                        }
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                            indexChanged()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                Color.gray.opacity(0.001)
                                    .onTapGesture {
                                        if bottomFocusField == .one {
                                            bottomFocusField = .two
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        } else {
                                            let tempArr = realOrder()
                                            
                                            if let index = tempArr.firstIndex(where: { $0 == selection }) {
                                                if isVideo() {
                                                    player?.pause()
                                                    withAnimation(.easeInOut(duration: 0.1)){
                                                        isPlaying = false
                                                    }
                                                }
                                                
                                                if let profile = viewModel.users.first(where: { $0.user.id == selection }) {
                                                    if let stories = profile.stories {
                                                        let storyIndex = profile.storyIndex
                                                        
                                                        if (storyIndex + 1) < stories.count {
                                                            viewModel.users[idx].storyIndex += 1
                                                            indexChanged()
                                                        } else if (index + 1) < tempArr.count {
                                                            switchedToStartLast = (index + 2) == tempArr.count
                                                            clickedToChangeSelection = tempArr[index + 1]
                                                            withAnimation(.easeInOut(duration: 0.25)){
                                                                selection = tempArr[index + 1]
                                                            }
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                                indexChanged()
                                                            }
                                                        } else {
                                                            closeView()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                            }
                        }
                    })
                }
                .frame(maxWidth: showStats ? (widthOrHeight(width: false) * 0.15) : .infinity)
                .frame(maxHeight: showStats ? (widthOrHeight(width: false) * 0.25) : .infinity)
            }
            .padding(.bottom, bottom_Inset() + 14.0)
            .ignoresSafeArea(.keyboard)
            .overlay(content: {
                if let text = stories[index].text, !text.isEmpty && !hideEverything {
                    
                    let position = stories[index].textPos ?? 0.5
                    let finalPos = (widthOrHeight(width: false) - 105.0) * position
                    
                    VStack {
                        Text(text)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .font(.body).foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .frame(width: widthOrHeight(width: true))
                            .background(.ultraThinMaterial)
                            .offset(y: finalPos)
                        Spacer()
                    }.scaleEffect(scale)
                }
            })
            .overlay(alignment: .bottom){
                if stories[index].id != nil && uid != (auth.currentUser?.id ?? "Not") && !hideEverything {
                    StoryBottomBar(focusField: $bottomFocusField, storyID: $storyID, posterID: uid, currentID: auth.currentUser?.id ?? "", myMessages: auth.currentUser?.myMessages ?? [], storyViews: stories[index].views ?? [], disableDrag: $disableDrag, isMap: true, canOpenChat: true, bigger: true) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if isVideo() {
                            player?.pause()
                        }
                        player = nil
                        profileUID = uid
                        closeView()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showChat = true
                        }
                    }.KeyboardAwarePadding().ignoresSafeArea().offset(y: bottomFocusField == .one ? 28 : 10)
                }
                
                if stories[index].id != nil && uid == (auth.currentUser?.id ?? "Not") && !hideEverything {
                    StoryStatsView(showStats: $showStats, storyID: $storyID, disableDrag: .constant(false), contentURL: stories[index].imageURL ?? stories[index].videoURL ?? "", isVideo: isVideo(), lat: stories[index].lat, long: stories[index].long, views: stories[index].views ?? [], following: auth.currentUser?.following ?? [], isMap: true, cid: auth.currentUser?.id ?? "", disableNav: false, canOpenProfile: true, canOpenChat: true, externalUpload: true, bigger: true) { temp_uid in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if isVideo() {
                            player?.pause()
                        }
                        player = nil
                        profileUID = temp_uid
                        closeView()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showProfile = true
                        }
                    } openChat: { temp_uid in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if isVideo() {
                            player?.pause()
                        }
                        player = nil
                        profileUID = temp_uid
                        closeView()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showChat = true
                        }
                    } stopVideo: { stop in
                        if isVideo() {
                            if stop {
                                player?.pause()
                            } else {
                                player?.play()
                            }
                        }
                    } upload: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        if let profile = viewModel.users.first(where: { $0.user.id == selection }) {
                            if let stories = profile.stories {
                                let storyIndex = profile.storyIndex
                                
                                if storyIndex < stories.count {
                                    if let video = stories[storyIndex].videoURL {
                                        if let url = URL(string: video) {
                                            initialContent = uploadContent(isImage: false, videoURL: url)
                                        }
                                    } else if let image = stories[storyIndex].imageURL {
                                        initialContent = uploadContent(isImage: true, imageURL: image)
                                    }
                                }
                            }
                        }
                        
                        if initialContent != nil {
                            closeView()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                showNewTweetView = true
                            }
                        }
                    }
                    .opacity(offset == .zero || scale > 0.99 ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.1), value: offset)
                }
            }
            
            if !showStats && !hideEverything {
                overlayStory(posterUID: uid, sid: stories[index].id ?? "", index: index, totalCount: stories.count, username: stories[index].username, photo: stories[index].profilephoto, timestamp: stories[index].timestamp)
            }
        }
    }
    func isCurrent(expected: String) -> Bool {
        if let currentItem = player?.currentItem, let asset = currentItem.asset as? AVURLAsset {
            return asset.url.absoluteString == expected
        }
        return false
    }
    func indexChanged() {
        player?.seek(to: .zero)
        player?.pause()
        player = nil
        
        if let profile = viewModel.users.first(where: { $0.user.id == selection }) {
            if let stories = profile.stories {
                let storyIndex = profile.storyIndex

                if storyIndex < stories.count {
                    storyID = stories[storyIndex].id ?? ""
                    
                    if let video = stories[storyIndex].videoURL, let url = URL(string: video) {
                        player = AVPlayer(url: url)
                        player?.play()
                        player?.isMuted = isMuted
                        
                        NotificationCenter.default.addObserver (
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player?.currentItem,
                            queue: .main
                        ) { _ in
                            player?.seek(to: .zero)
                            player?.play()
                        }
                        player?.actionAtItemEnd = .none
                        
                        withAnimation(.easeInOut(duration: 0.1)){
                            isPlaying = true
                        }
                        
                        if self.popRoot.previewStory[video] == nil {
                            extractImageAt(f_url: url, time: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) { thumbnail in
                                self.popRoot.previewStory[video] = Image(uiImage: thumbnail)
                            }
                        }
                    }
                }
            }
        }

        setStoryTitle()
    }
    func closeView() {
        player?.seek(to: .zero)
        player?.pause()
        player = nil
        withAnimation(.easeInOut(duration: 0.15)){
            opacity = 0.0
            closing = true
        }
        if selection != tempMid {
            tempMid = selection
        }
        withAnimation(.easeInOut(duration: 0.15)){
            isMainExpanded = false
        }
    }
    func isVideo() -> Bool {
        if let profile = viewModel.users.first(where: { $0.user.id == selection }) {
            if let stories = profile.stories {
                let storyIndex = profile.storyIndex

                if storyIndex < stories.count && stories[storyIndex].videoURL != nil {
                    return true
                }
            }
        }
        
        return false
    }
    func setStoryTitle() {
        if let profile = viewModel.users.first(where: { $0.user.id == selection }), let stories = profile.stories {
            let storyIndex = profile.storyIndex
            
            if let sid = stories[storyIndex].id {
                let createdDate = stories[storyIndex].timestamp.dateValue()
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
                
                let existingTitle = popRoot.storyTitles[sid] ?? ""
                
                if !existingTitle.contains("-") {
                    popRoot.storyTitles[sid] = finalStr
                }
                
                if let lat = stories[storyIndex].lat, let long = stories[storyIndex].long {
                    setPlaceName(place: CLLocationCoordinate2D(latitude: lat, longitude: long)) { loc_str in
                        if let loc_str, !loc_str.isEmpty {
                            popRoot.storyTitles[sid] = finalStr + " - " + loc_str
                        }
                    }
                }
            }
        }
    }
    func setPlaceName(place: CLLocationCoordinate2D, completion: @escaping(String?) -> Void) {
        let location = CLLocation(latitude: place.latitude, longitude: place.longitude)

        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
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
    }
    private var scale: CGFloat {
        var yOffset = offset.height
        yOffset = yOffset < 0 ? 0 : yOffset
        var progress = min(1.0, yOffset / widthOrHeight(width: false))
        progress = 1 - (progress * 0.15)
        return (isMainExpanded ? progress : 1)
    }
    func getAngle(xOffset: CGFloat) -> Double {
        let tempAngle = xOffset / (UIScreen.main.bounds.width / 2)
        let rotationDegree: CGFloat = 25
        return Double(tempAngle * rotationDegree)
    }
    func tabProgress(tabID: String, rect: CGRect, size: CGSize) {
        if !switchedToStartLast {
            let tempArr = realOrder()
            if !preventClose {
                if let index = tempArr.firstIndex(where: { $0 == tabID }), let last = tempArr.last, tabID == selection && last == tabID {
                    
                    let offsetX = rect.minX - (size.width * CGFloat(index))
                    progress = -offsetX / size.width
                    let temp: CGFloat = progress - CGFloat(index)
                    
                    if (temp + 0.005) >= 0.0 {
                        self.opacity = 1.0 - min(1.0, ((temp + 0.005) / 0.08))
                    } else {
                        self.opacity = 1.0
                    }
                    if temp >= 0.0 {
                        self.big = temp
                        if small > big {
                            closeView()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.small = temp
                        }
                    }
                } else if let index = tempArr.firstIndex(where: { $0 == tabID }), let first = tempArr.first, tabID == selection && first == tabID {
                    
                    let offsetX = rect.minX - (size.width * CGFloat(index))
                    progress = -offsetX / size.width
                    let temp: CGFloat = progress - CGFloat(index)
                    
                    if temp <= 0.0 {
                        let absTemp = abs(temp)
                        self.opacity = 1.0 - min(1.0, (absTemp / 0.75))
                        
                        self.big = absTemp
                        if small > (big + 0.065) {
                            closeView()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.small = absTemp
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                switchedToStartLast = false
            }
        }
    }
    func closeTopMenu() {
        withAnimation(.easeInOut(duration: 0.15)){
            showMenuAnim = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            showMenu = false
        }
    }
    func menuView() -> some View {
        ZStack(alignment: .top){
            TransparentBlurView(removeAllFilters: true)
                .blur(radius: 2, opaque: true)
                .background(.black.opacity(0.6))
                .ignoresSafeArea()
                .opacity(showMenuAnim ? 1.0 : 0.0)
                .onTapGesture {
                    closeTopMenu()
                }
            
            VStack(spacing: 10){
                if !menuTitle.isEmpty {
                    Text(menuTitle)
                        .foregroundStyle(.white).opacity(0.8)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Divider().overlay(.white.opacity(0.6))
                }
                let isOwner = selection == auth.currentUser?.id
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    closeTopMenu()
                    if isOwner {
                        if let profile = viewModel.users.first(where: { $0.user.id == selection }),
                           let stories = profile.stories,
                           let id = stories[profile.storyIndex].id {
                            GlobeService().deleteStory(storyID: id)
                            
                            popRoot.alertImage = "checkmark"
                            popRoot.alertReason = "Story Deleted"
                            withAnimation(.easeInOut(duration: 0.2)){
                                popRoot.showAlert = true
                            }
                        }
                    } else {
                        popRoot.alertImage = "checkmark"
                        popRoot.alertReason = "Story Reported"
                        withAnimation(.easeInOut(duration: 0.2)){
                            popRoot.showAlert = true
                        }
                    }
                } label: {
                    HStack {
                        Text(isOwner ? "Delete" : "Report")
                        Spacer()
                        Image(systemName: isOwner ? "trash" : "flag")
                    }.foregroundStyle(.red)
                }
                Divider().overlay(.white.opacity(0.6))
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    closeTopMenu()
                    if let profile = viewModel.users.first(where: { $0.user.id == selection }),
                       let stories = profile.stories,
                       let id = stories[profile.storyIndex].id {
                        UIPasteboard.general.string = "https://hustle.page/story/\(id)/"
                    }
                    popRoot.alertImage = "checkmark"
                    popRoot.alertReason = "Story Link Copied"
                    withAnimation(.easeInOut(duration: 0.2)){
                        popRoot.showAlert = true
                    }
                } label: {
                    HStack {
                        Text("Copy Link")
                        Spacer()
                        Image(systemName: "link")
                    }
                }
                Divider().overlay(.white.opacity(0.6))
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    closeTopMenu()
                    if let profile = viewModel.users.first(where: { $0.user.id == selection }),
                       let stories = profile.stories,
                       let urlStr = stories[profile.storyIndex].link, 
                       let url = URL(string: urlStr) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text("Open Link")
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                    }.foregroundStyle(.blue)
                }
            }
            .font(.system(size: 17))
            .foregroundStyle(.white)
            .frame(width: 170)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color(red: 66 / 255.0, green: 69 / 255.0, blue: 73 / 255.0))
            .overlay(content: {
                RoundedRectangle(cornerRadius: 15).stroke(.white, lineWidth: 1.0).opacity(0.7)
            })
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(radius: 1)
            .padding(.top, 90 + top_Inset())
            .offset(x: 65)
            .transition(.scale(scale: 0.1, anchor: .topTrailing).combined(with: .opacity))
            .opacity(showMenuAnim ? 1.0 : 0.0).scaleEffect(showMenuAnim ? 1.0 : 0.0)
            .offset(x: showMenuAnim ? 0.0 : 60.0, y: showMenuAnim ? 0.0 : -55.0)
        }
    }
    @ViewBuilder
    func overlayStory(posterUID: String, sid: String, index: Int, totalCount: Int, username: String, photo: String?, timestamp: Timestamp) -> some View {
        VStack(spacing: 15){
            HStack(spacing: 4){
                ForEach(0..<totalCount, id: \.self) { i in
                    Rectangle()
                        .frame(height: 1.5).foregroundStyle(.white)
                        .opacity((i <= index) ? 1.0 : 0.4)
                }
            }
            let isVid = isVideo()
            HStack(spacing: isVid ? 8 : 12){
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if isVideo() {
                        player?.pause()
                    }
                    player = nil

                    profileUID = posterUID
                    closeView()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showProfile = true
                    }
                }, label: {
                    HStack(spacing: 10){
                        ZStack {
                            personView(size: 45)
                            if let photo {
                                KFImage(URL(string: photo))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                                    .shadow(color: .gray, radius: 2)
                            }
                        }
                        VStack(alignment: .leading, spacing: 5){
                            Text("@\(username)")
                                .font(.subheadline).fontWeight(.heavy)
                                .shadow(color: .gray, radius: 3).lineLimit(1)
                            Text(popRoot.storyTitles[sid] ?? "").font(.caption)
                                .fontWeight(.semibold).shadow(color: .gray, radius: 2).lineLimit(1).truncationMode(.tail)
                        }.foregroundStyle(.white)
                    }
                })
                
                Spacer()
                if isVid {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        player?.isMuted = !isMuted
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
                Button(action: {
                    menuTitle = formatFirebaseTimestampExtended(timestamp)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showMenuAnim = true
                    withAnimation(.easeInOut(duration: 0.15)){
                        showMenu = true
                    }
                }, label: {
                    ZStack {
                        Rectangle()
                            .foregroundStyle(.gray).opacity(0.001)
                            .frame(width: 30, height: 40)
                        Image(systemName: "ellipsis.circle").font(.title2).bold()
                            .symbolEffect(.bounce, value: showMenu)
                            .foregroundStyle(showMenu ? .blue : .white)
                    }
                })
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    if isVideo() {
                        player?.pause()
                    }
                    player = nil
                    closeView()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label:{
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001)
                            .frame(width: 30, height: 40)
                        Image(systemName: "xmark").font(.title3).bold().foregroundStyle(.white)
                    }
                })
            }
            Spacer()
        }.padding(.top, 16).padding(.horizontal, 12)
    }
}
