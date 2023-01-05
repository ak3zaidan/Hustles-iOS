import SwiftUI
import Kingfisher
import AVFoundation
import Firebase
import CoreLocation

struct MessageStoriesView: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var auth: AuthViewModel
    @FocusState private var bottomFocusField: FocusedField?
    @State var storyID: String = ""
    @State var storyTitleDict: [String: String] = [:]
    @State var index = 0
    @State var offset: CGSize = .zero
    @GestureState private var isDragging = false
    @State var showBackground = false
    @State var showStats: Bool = false
    @State var disableDrag: Bool = false
    @State var fetchingPlace: Bool = false
    @State var hideEverything: Bool = false
    @Binding var isExpanded: Bool
    @State var isMuted = false
    @State var isPlaying = true
    @State var player: AVPlayer? = nil
    @State var showMenu = false
    @State var showMenuAnim = false
    @State var menuTitle: String = ""
    let animation: Namespace.ID
    let mid: String
    let isHome: Bool
    let canOpenChat: Bool
    let canOpenProfile: Bool
    let openChat: (String) -> Void
    let openProfile: (String) -> Void
    
    var body: some View {
        ZStack(alignment: .top){
            Color.black.opacity(showBackground ? 1.0 : 0.0).ignoresSafeArea()
            Color.blue.opacity(showBackground ? 0.06 : 0.0).ignoresSafeArea()
            
            ZStack {
                ZStack(alignment: .top){
                    GeometryReader {
                        let size = $0.size
                        
                        ZStack {
                            if let image = viewModel.selectedStories[index].imageURL {
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
                            } else if player != nil || popRoot.previewStory[viewModel.selectedStories[index].videoURL ?? ""] != nil {
                                let image = popRoot.previewStory[viewModel.selectedStories[index].videoURL ?? ""] ?? Image(systemName: "")
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundColor(.gray).opacity(0.2)
                                    .overlay(content: {
                                        ProgressView().scaleEffect(1.2)
                                    })
                                
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width, height: size.height)
                                    .overlay {
                                        if let player = player {
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
                                        if let urlS = viewModel.selectedStories[index].videoURL, let url = URL(string: urlS) {
                                            extractImageAt(f_url: url, time: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) { thumbnail in
                                                self.popRoot.previewStory[urlS] = Image(uiImage: thumbnail)
                                            }
                                        }
                                    }
                            }
                        }
                        .overlay(content: {
                            if showStats {
                                let updated = popRoot.updatedView.first(where: { $0.0 == storyID })
                                let views = updated?.1 ?? (viewModel.selectedStories[index].views ?? []).count
                                let reactions = updated?.2 ?? countViewsContainsReaction(views: viewModel.selectedStories[index].views ?? [])
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
                    }
                    .frame(maxWidth: showStats ? (widthOrHeight(width: false) * 0.15) : .infinity)
                    .frame(maxHeight: showStats ? (widthOrHeight(width: false) * 0.25) : .infinity)

                    if !showStats {
                        HStack {
                            Color.gray.opacity(0.001)
                                .onTapGesture {
                                    if bottomFocusField == .one {
                                        bottomFocusField = .two
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    } else {
                                        if index > 0 {
                                            if isVideo() {
                                                player?.pause()
                                                withAnimation(.easeInOut(duration: 0.1)){
                                                    isPlaying = false
                                                }
                                            }
                                            index -= 1
                                            indexChanged()
                                        }
                                    }
                                }
                            Color.gray.opacity(0.001)
                                .onTapGesture {
                                    if bottomFocusField == .one {
                                        bottomFocusField = .two
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    } else {
                                        if (index + 1) < viewModel.selectedStories.count {
                                            if isVideo() {
                                                player?.pause()
                                                withAnimation(.easeInOut(duration: 0.1)){
                                                    isPlaying = false
                                                }
                                            }
                                            index += 1
                                            indexChanged()
                                        } else {
                                            if isVideo() {
                                                player?.pause()
                                            }
                                            player = nil
                                            closeView()
                                        }
                                    }
                                }
                        }
                    } else {
                        VStack {
                            HStack {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    if let id = viewModel.selectedStories[index].id {
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
                .matchedGeometryEffect(id: mid, in: animation)
                .padding(.bottom, isHome ? (48.0 + bottom_Inset()) : 48.0)
                .padding(.top, top_Inset()).padding(.bottom, isHome ? 0.0 : bottom_Inset())
                .ignoresSafeArea(.keyboard)
                
                if !showStats && !hideEverything {
                    overlayStory().padding(.top, top_Inset())
                }
                
                if let text = viewModel.selectedStories[index].text, !text.isEmpty && !hideEverything {
                    
                    let position = viewModel.selectedStories[index].textPos ?? 0.5
                    let finalPos = (widthOrHeight(width: false) - 105.0) * position
                    
                    VStack {
                        Text(text)
                            .padding(.vertical, 6)
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
                }
                
                let posterUID = viewModel.selectedStories[index].uid
                
                if viewModel.selectedStories[index].id != nil && posterUID != (auth.currentUser?.id ?? "Not") && !hideEverything {
                    VStack {
                        Spacer()
                        StoryBottomBar(focusField: $bottomFocusField, storyID: $storyID, posterID: posterUID, currentID: auth.currentUser?.id ?? "", myMessages: auth.currentUser?.myMessages ?? [], storyViews: viewModel.selectedStories[index].views ?? [], disableDrag: $disableDrag, isMap: true, canOpenChat: canOpenChat, bigger: false) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            if isVideo() {
                                player?.pause()
                            }
                            player = nil
                            openChat(posterUID)
                            closeView()
                        }.KeyboardAwarePadding()
                    }
                    .padding(.bottom, bottomFocusField == .one ? 6 : 25)
                    .ignoresSafeArea()
                }
                
                if viewModel.selectedStories[index].id != nil && posterUID == (auth.currentUser?.id ?? "Not") && !hideEverything {
                    StoryStatsView(showStats: $showStats, storyID: $storyID, disableDrag: .constant(false), contentURL: viewModel.selectedStories[index].imageURL ?? viewModel.selectedStories[index].videoURL ?? "", isVideo: isVideo(), lat: viewModel.selectedStories[index].lat, long: viewModel.selectedStories[index].long, views: viewModel.selectedStories[index].views ?? [], following: auth.currentUser?.following ?? [], isMap: true, cid: auth.currentUser?.id ?? "", disableNav: false, canOpenProfile: canOpenProfile, canOpenChat: canOpenChat, externalUpload: false, bigger: false) { uid in
                        if canOpenProfile {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            if isVideo() {
                                player?.pause()
                            }
                            player = nil
                            openProfile(uid)
                            closeView()
                        }
                    } openChat: { uid in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if isVideo() {
                            player?.pause()
                        }
                        player = nil
                        openChat(uid)
                        closeView()
                    } stopVideo: { stop in
                        if isVideo() {
                            if stop {
                                player?.pause()
                            } else {
                                player?.play()
                            }
                        }
                    } upload: {
                        
                    }
                    .padding(.bottom, 30)
                    .opacity(offset == .zero ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.1), value: offset)
                }
            }
            .scaleEffect(scale)
            .offset(y: offset.height)
            .offset(y: offset.height * -0.6)

            if showMenu {
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
                    let isOwner = viewModel.selectedStories[index].uid == auth.currentUser?.id
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        closeTopMenu()
                        if isOwner {
                            if let id = viewModel.selectedStories[index].id {
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
                        if let id = viewModel.selectedStories[index].id {
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
                        if let urlStr = viewModel.selectedStories[index].link, let url = URL(string: urlStr) {
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
        .ignoresSafeArea()
        .onAppear(perform: {
            storyID = viewModel.selectedStories[index].id ?? ""
            withAnimation(.easeInOut(duration: 0.1)){
                showBackground = true
            }
            if let video = viewModel.selectedStories[index].videoURL, let url = URL(string: video) {
                player = AVPlayer(url: url)
            }
            setStoryTitle()
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
                            translation = isDragging && isExpanded ? translation : .zero
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
                                if viewModel.selectedStories[index].uid == (auth.currentUser?.id ?? "Not") {
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
    func closeTopMenu() {
        withAnimation(.easeInOut(duration: 0.15)){
            showMenuAnim = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            showMenu = false
        }
    }
    func indexChanged(){
        player = nil
        
        if let id = viewModel.selectedStories[index].id {
            storyID = id
        }
        if let video = viewModel.selectedStories[index].videoURL, let url = URL(string: video) {
            player = AVPlayer(url: url)
            player?.play()
            withAnimation(.easeInOut(duration: 0.1)){
                isPlaying = true
            }
        }
        setStoryTitle()
    }
    func closeView(){
        player?.seek(to: .zero)
        hideEverything = true
        withAnimation(.easeInOut(duration: 0.05)){
            showBackground = false
        }
        withAnimation(.easeInOut(duration: 0.2)){
            offset = .zero
            isExpanded = false
        }
    }
    private var scale: CGFloat {
        var yOffset = offset.height
        yOffset = yOffset < 0 ? 0 : yOffset
        var progress = min(1.0, yOffset / widthOrHeight(width: false))
        progress = 1 - (progress * 0.15)
        return (isExpanded ? progress : 1)
    }
    func isVideo() -> Bool {
        return viewModel.selectedStories[index].videoURL != nil
    }
    func setStoryTitle() {
        if let sid = viewModel.selectedStories[index].id {
            let createdDate = viewModel.selectedStories[index].timestamp.dateValue()
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
            storyTitleDict[sid] = finalStr
            if let lat = viewModel.selectedStories[index].lat, let long = viewModel.selectedStories[index].long {
                setPlaceName(place: CLLocationCoordinate2D(latitude: lat, longitude: long)) { loc_str in
                    if let loc_str {
                        storyTitleDict[sid] = finalStr + " - " + loc_str
                    }
                }
            }
        }
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
    @ViewBuilder
    func overlayStory() -> some View {
        VStack(spacing: 15){
            HStack(spacing: 4){
                ForEach(0..<viewModel.selectedStories.count, id: \.self) { i in
                    Rectangle()
                        .frame(height: 1.5).foregroundStyle(.white)
                        .opacity((i <= index) ? 1.0 : 0.4)
                }
            }
            let isVid = isVideo()
            HStack(spacing: isVid ? 8 : 12){
                let uid = viewModel.selectedStories[index].uid
            
                Button(action: {
                    if canOpenProfile {
                        if isVideo() {
                            player?.pause()
                        }
                        player = nil
                        openProfile(uid)
                        closeView()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }, label: {
                    HStack(spacing: 10){
                        ZStack {
                            personView(size: 45)
                            if let image = viewModel.selectedStories[index].profilephoto {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                                    .shadow(color: .gray, radius: 2)
                            }
                        }
                        VStack(alignment: .leading, spacing: 5){
                            Text("@\(viewModel.selectedStories[index].username)")
                                .font(.subheadline).fontWeight(.heavy)
                                .shadow(color: .gray, radius: 3).lineLimit(1)
                            Text(storyTitleDict[storyID] ?? "").font(.caption)
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
                    menuTitle = formatFirebaseTimestampExtended(viewModel.selectedStories[index].timestamp)
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
