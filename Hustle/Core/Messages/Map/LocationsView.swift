import SwiftUI
import MapKit
import Kingfisher
import Firebase

enum mapOption {
    case stories
    case pins
    case memories
    case places
}

struct chatPins: Identifiable {
    let id: String = UUID().uuidString
    let coordinates: CLLocationCoordinate2D
    let name: String
    var uploaderID: String
    var uploaderPhoto: String?
    var timeDistance: String?
}

struct reusableLocation: Identifiable {
    let id: String = UUID().uuidString
    let coordinates: CLLocationCoordinate2D
    let name: String
    let time: String
    let isDay: Bool
    let type: Int   //1 city, 2 state, 3 country, 4 continent
}

struct ItemX: Identifiable {
    var id: String = UUID().uuidString
    var title: String
}

struct SwiftfulMapAppApp: View {
    @Binding var disableTopGesture: Bool
    @Binding var option: Int
    let chatUsers: [User]
    let close: (Int) -> Void
    
    var body: some View {
        VStack {
            LocationsView(option: $option, disableTopGesture: $disableTopGesture, chatUsers: chatUsers){ num in
                close(num)
            }
        }
    }
}

struct LocationsView: View, KeyboardReadable {
    @State var storiesForPlace: [LocationMap] = []
    @State var resuableLocs = [reusableLocation]()
    @State var fetchingPlace: Bool = false
    @State var pins: [chatPins] = []
    @Environment(\.dismiss) var presentation
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var vm: LocationsViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var gcModel: GroupChatViewModel
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var profileModel: ProfileViewModel
    @State var groupLocations: [groupLocation] = []
    @State var storyGroups: [groupLocation] = []
    @State var memoryGroups: [groupLocation] = []
    @State var businessGroups: [groupBusiness] = []
    @State var isDragging: Bool = true
    @State var dragEnded: Bool = true
    @State var offset = 0.0
    @State var color: Color = .gray
    @State var lastOffset = 0.0
    @State var scaleImage = "shoe.fill"
    @State var lastCameraPosition: CLLocationCoordinate2D? = nil
    @State var lastCameraSpan: MKCoordinateSpan? = nil
    @State var scalePin: Bool = false
    @State var showPins: Bool = false
    @State var showTempLabel: Bool = false
    @State var storiesFoundForLocation: Bool = false
    @State var showSettings: Bool = false
    @State var selectedOffset: CGFloat = 0.0
    @State var showEnableLocationAccess: Bool = false
    
    @State var currentPlaceName: String = "---------"
    @State var timeString: String = "2:45PM"
    @State var isDayOrNight: Bool = true
    @State var showStories: Bool = false
    @State var centerStoryID: String = ""
    @State var newPin: CLLocationCoordinate2D? = nil
    @State var showNewPin: Bool = false
    @State var tapCount: Int = 0
    @State var newPinText: String = ""
    @State var showChangeName: Bool = false
    @State var pinAddress: String = ""
    @State var newPinDriveTime: String = ""
    @FocusState var focusedField: FocusedField?
    @FocusState var focusField: FocusedField?
    @State var showMenu: Bool = false
    @State var MenuPosition: CGPoint = .zero
    @State var pinAddresses: [(CLLocationCoordinate2D, String)] = []
    @State var showNewChat: Bool = false
    @State var newChatUsers: [User] = []
    @State var selectedUsers: [User] = []
    @State private var showForward = false
    @State var sendLink: String = ""
    @State private var showSearchUsers = false
    
    @State var showUserSheet = false
    @State var userForSheet: User? = nil
    @State var userForSheetUsername: String? = nil
    @State var searchMapText: String = ""
    
    //story display vars
    @State var animateFromPoint: CGPoint = .zero
    @State var animateToPoint: CGPoint = .zero
    @State var showStoryOverlay: Bool = false
    @State private var offset2: CGSize = CGSize(width: 0.0, height: 0.001)
    @State private var startOfDragLocation: CGPoint = .zero
    @State private var circleSize: CGFloat = .zero
    @State var backOpac = 0.0
    @State var isDraggingOverlay: Bool = false
    @State var upData = [LocationMap]()
    @State var closeOverlay: Bool = false
    @State var disableDrag = false
    @State var showingStories = false
    @State var SwipeUpAction: Bool = false
    
    //quick action messages
    var itemHeight: CGFloat = 40.0
    @State var frame: CGFloat = 40.0
    @State var itemsN: [ItemX] = [
        ItemX(title: "On my way!"),
        ItemX(title: "Leaving now!"),
        ItemX(title: "Send the address."),
        ItemX(title: "Just left."),
        ItemX(title: "Driving."),
    ]
    @State var status: [String : Bool] = ["On my way!" : false, "Leaving now!" : false, "Send the address." : false, "Just left." : false, "Driving." : false]
    @Namespace var namespace
    @State var sentMessage = ""
    @State var tempTop = ""
    
    //places
    @State var keyBoardVisible = true
    @State var showSearch: Bool = false
    @State var showPlacesSheet: Bool = false
    @State var showTagSheet: Bool = false
    @State var showSingleSheet: Bool = false
    @State var showMultiSheet: Bool = false
    @State var showPlaces: Bool = false
    @State var centerPlaceID: String = ""
    @State var didSelectThroughSheet: Bool = false
    @State var didSelectThroughTagSheet: Bool = false
    @State var sheetDetent: PresentationDetent = .fraction(0.999)
    @State var tagDetent: PresentationDetent = .medium
    @State var searchText: String = ""
    @FocusState var searchField: FocusedField?
    @State var movedCameraInitially = false
    @State var alreadyShowedWarning = false
    let tags = ["Restaurants", "Cafes", "Parks", "Ice Cream"]
    let photos = ["Restaurants": "fork.knife", "Cafes": "cup.and.saucer.fill", "Parks": "photo", "Ice Cream": "birthday.cake.fill"]
    
    //memories
    @State var showMemories: Bool = false
    @State var centerMemoryID: String = ""
    
    //top right pull down menu
    @State var displayOption: mapOption = mapOption.stories
    @State var showPullDownMenu: Bool = false
    @State var showVPNError = false
    @State var showAIPlace = false
    
    @Binding var option: Int
    @Binding var disableTopGesture: Bool
    let chatUsers: [User]
    let close: (Int) -> Void
    
    var body: some View {
        ZStack {
            mapLayer.ignoresSafeArea()
            mapOptions.transition(.move(edge: .bottom)).ignoresSafeArea(.keyboard)
            header.ignoresSafeArea(.keyboard).padding(.top, top_Inset())
            if showMenu {
                pinMenu()
            }
            sliderLayer
            if showSearch {
                VStack {
                    Spacer()
                    textSearch()
                }.KeyboardAwarePadding().padding(.bottom, 8).ignoresSafeArea()
            }
            if !sentMessage.isEmpty {
                HStack {
                    Spacer()
                    Text(sentMessage).font(.subheadline).bold()
                        .foregroundStyle(.white).padding(12)
                        .background(.blue.gradient)
                        .clipShape(ChatBubbleShape(direction: .right))
                        .frame(height: itemHeight)
                        .matchedGeometryEffect(id: sentMessage, in: namespace)
                }
                .padding(.trailing, 10)
                .offset(y: -widthOrHeight(width: false))
            }
        }
        .sheet(isPresented: $showUserSheet, content: {
            ProfileSheetView(uid: userForSheet?.id ?? "", photo: "", user: userForSheet, username: $userForSheetUsername)
        })
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .fraction(0.999)])
        })
        .sheet(isPresented: $showAIPlace, content: {
            RecommendPlaceView()
        })
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
            keyBoardVisible = newIsKeyboardVisible
            if !keyBoardVisible {
                withAnimation(.easeInOut(duration: 0.2)){
                    showSearch = false
                }
            }
        }
        .onChange(of: option, { _, newValue in
            if newValue != 3 {
                showPlacesSheet = false
                showTagSheet = false
                showSingleSheet = false
                showMultiSheet = false
                showSettings = false
            } else {
                mainInit()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                    withAnimation(.easeInOut(duration: 0.15)){
                        dragEnded = false
                        isDragging = false
                    }
                }
            }
        })
        .sheet(isPresented: $showPlacesSheet, content: {
            VStack {
                HStack(spacing: 8){
                    TextField("Search places...", text: $searchText)
                        .padding(.horizontal, 10).padding(.leading, 25)
                        .frame(height: 38)
                        .background(.gray.opacity(colorScheme == .dark ? 0.3 : 0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(alignment: .leading){
                            Image(systemName: "magnifyingglass")
                                .font(.subheadline).bold().padding(.leading, 8)
                        }
                        .disabled(true)
                        .overlay {
                            Color.gray.opacity(0.001)
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    showPlacesSheet = false
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        showSearch = true
                                    }
                                    searchField = .one
                                }
                        }
                    Button(action: {
                        if searchText.isEmpty {
                            showPlacesSheet = false
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        } else {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            searchText = ""
                        }
                    }, label: {
                        ZStack {
                            Circle()
                                .frame(width: 38, height: 38)
                                .foregroundStyle(.gray.opacity(colorScheme == .dark ? 0.3 : 0.13))
                            Image(systemName: "xmark")
                                .font(.subheadline).bold()
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                    })
                }
                .padding(.horizontal, 12).padding(.bottom, 3)
                ScrollView {
                    LazyVStack(spacing: 10){
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 5){
                                Color.clear.frame(width: 2)
                                ForEach(tags, id: \.self) { tag in
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        vm.selectedTag = tag
                                        showPlacesSheet = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            showTagSheet = true
                                        }
                                        if let loc = getUserLocation() {
                                            vm.loadRestraunts(currentLoc: loc, query: tag)
                                        } else if let center = lastCameraPosition, let span = lastCameraSpan {
                                            if span.latitudeDelta < 0.5 && span.longitudeDelta < 0.5 {
                                                vm.loadRestraunts(currentLoc: center, query: tag)
                                            }
                                        }
                                    }, label: {
                                        HStack(spacing: 3){
                                            Image(systemName: photos[tag] ?? "fork.knife").font(.caption)
                                            Text(tag).font(.subheadline).bold()
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 7)
                                        .background(Color.blue.gradient)
                                        .clipShape(Capsule())
                                    })
                                }
                                Color.clear.frame(width: 2)
                            }
                        }
                        .scrollIndicators(.hidden)
                        .frame(height: 40)
                        
                        if vm.allRestaurants.isEmpty {
                            LottieView(loopMode: .loop, name: "placeLoader")
                                .frame(width: 85, height: 85)
                                .scaleEffect(0.7)
                                .padding(.top, 100)
                        } else {
                            ForEach(vm.allRestaurants) { place in
                                Button {
                                    didSelectThroughTagSheet = false
                                    didSelectThroughSheet = true
                                    vm.selectedBus = place
                                    showPlacesSheet = false
                                    vm.selectedTag = place.tag
                                    vm.showNextPlace(location: place, lat: 0.0008, long: 0.0008)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        showSingleSheet = true
                                    }
                                } label: {
                                    SinglePlaceRowView(place: place)
                                }
                            }
                        }
                    }
                }.scrollIndicators(.hidden)
            }
            .padding(.top)
            .presentationDetents([.height(63.0), .fraction(0.999)], selection: $sheetDetent)
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.999)))
        })
        .sheet(isPresented: $showTagSheet, content: {
            TagSheetView(show: $showTagSheet, close: { str in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let id = str {
                    didSelectThroughTagSheet = true
                    openSingle(str: id)
                } else {
                    showTagSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showPlacesSheet = true
                    }
                }
            })
            .environmentObject(vm)
            .presentationDetents([.height(63.0), .medium, .fraction(0.999)], selection: $tagDetent)
            .presentationCornerRadius(40)
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.999)))
            .onDisappear {
                tagSheetDismissed()
            }
        })
        .overlay(content: {
            if showStoryOverlay {
                GeometryReader { proxy in
                    let h = proxy.size.height
                    ZStack {
                        VStack {
                            MapMemoryView(memories: $upData, isDragging: $isDraggingOverlay, closingNow: $closeOverlay, disableDrag: $disableDrag, disableTopGesture: $disableTopGesture, SwipeUpAction: $SwipeUpAction, currentMapPlaceName: currentPlaceName, isStory: showingStories, isMap: chatUsers.isEmpty) { num in
                                withAnimation(.easeInOut(duration: 0.1)){
                                    disableTopGesture = false
                                }
                                withAnimation(.easeInOut(duration: num == 1 ? 0.35 : 0.1)){
                                    circleSize = 0.0
                                    backOpac = 0.0
                                    animateToPoint.x -= offset2.width
                                    animateToPoint.y -= offset2.height
                                    animateFromPoint = animateToPoint
                                }
                                let initialDelay: TimeInterval = (num == 1) ? 0.35 : 0.1
                                let postCloseDelay: TimeInterval = 0.35

                                DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
                                    showStoryOverlay = false
                                    offset2 = CGSize(width: 0.0, height: 0.001)
 
                                    switch num {
                                    case 2:
                                        close(2)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + postCloseDelay) {
                                            messageModel.navigateStoryProfile = true
                                        }
                                    case 3:
                                        close(2)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + postCloseDelay) {
                                            messageModel.navigateUserMap = true
                                        }
                                    default:
                                        break
                                    }
                                }
                            }
                            .frame(width: widthOrHeight(width: true))
                        }
                        .padding(.top, chatUsers.isEmpty ? top_Inset() : 0.0)
                        .padding(.bottom, chatUsers.isEmpty ? 0.0 : top_Inset())
                        .frame(width: widthOrHeight(width: true), height: widthOrHeight(width: false))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        Color.black.padding(-h)
                    }
                    .mask(alignment: .topLeading) {
                        if offset2 == .zero {
                            Rectangle().ignoresSafeArea()
                        } else {
                            Circle()
                                .position(animateFromPoint)
                                .frame(width: circleSize, height: circleSize)
                        }
                    }
                    .offset(offset2)
                    .background(content: {
                        Color.black.opacity(backOpac).ignoresSafeArea()
                    })
                    .simultaneousGesture(
                         !disableDrag ? DragGesture()
                             .onChanged { value in
                                 if value.translation.height >= 0 {
                                     isDraggingOverlay = true
                                     if startOfDragLocation != value.startLocation {
                                         startOfDragLocation = value.startLocation
                                     }
                                     offset2 = value.translation
                                     let newH = h * 1.5
                                     circleSize = max(100, newH - (newH * (value.translation.height / 200.0)))
                                     backOpac = max(0.0, min(1.0, 1.0 - (value.translation.height / 400.0)))
                                 }
                             }
                             .onEnded { value in
                                 isDraggingOverlay = false
                                 if value.translation.height > 140.0 {
                                     closeOverlay.toggle()
                                     withAnimation(.easeInOut(duration: 0.35)) {
                                         disableTopGesture = false
                                         circleSize = 0.0
                                         backOpac = 0.0
                                         animateToPoint.x -= offset2.width
                                         animateToPoint.y -= offset2.height
                                         animateFromPoint = animateToPoint
                                     }
                                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                         showStoryOverlay = false
                                         offset2 = CGSize(width: 0.0, height: 0.001)
                                     }
                                 } else {
                                     withAnimation(.easeIn(duration: 0.15)) {
                                         circleSize = h + h
                                         offset2 = CGSize(width: 0, height: 0.001)
                                     }
                                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                         offset = .zero
                                     }
                                     if showingStories {
                                         if value.translation.height < -40 {
                                             SwipeUpAction.toggle()
                                         }
                                     }
                                 }
                             } : nil
                     )
                }
            }
        })
        .onChange(of: vm.runVPNError, { _, _ in
            if isVPNConnected() {
                withAnimation(.easeInOut(duration: 0.2)){
                    showVPNError = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)){
                    showVPNError = false
                }
            }
        })
        .sheet(isPresented: $showSettings, content: {
            SilentEditView()
        })
        .sheet(isPresented: $showMultiSheet, content: {
            MultiSheetView(show: $showMultiSheet, near: "Located in \(currentPlaceName).", close: { id in
                openSingle(str: id)
            })
            .environmentObject(vm)
            .presentationDetents([.medium, .fraction(0.999)])
            .presentationCornerRadius(40)
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.999)))
        })
        .sheet(isPresented: $showSingleSheet, content: {
            if let selection = vm.selectedBus {
                SinglePlaceSheetView(show: $showSingleSheet, place: selection) {
                    addPin(place: selection.coordinates, name: selection.business.name ?? "", show: true)
                }
                .presentationDragIndicator(.visible)
                .presentationDetents([.height(250.0), .fraction(0.999)])
                .presentationCornerRadius(40)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.999)))
                .onAppear {
                    if let id = selection.business.id, selection.business.hours == nil && selection.business.photos == nil && selection.triedToFetchDetails == nil {
                        vm.getRestaurantDetails(id: id)
                    }
                    
                    if selection.timeDistance == nil {
                        if let start = getUserLocation() {
                            calculateDrivingTime(from: start, to: selection.coordinates) { time in
                                if let timeStr = time, !timeStr.isEmpty {
                                    vm.selectedBus?.timeDistance = timeStr
                                    if let idx = vm.allRestaurants.firstIndex(where: { $0.business.id == selection.business.id }) {
                                        vm.allRestaurants[idx].timeDistance = timeStr
                                    }
                                }
                            }
                        }
                    }
                }
                .onDisappear {
                    singleSheetDismissed()
                }
            }
        })
        .overlay {
            if showEnableLocationAccess || showChangeName || showNewChat || showVPNError {
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 2, opaque: true)
                    .background(colorScheme == .dark ? .black.opacity(0.3) : .white.opacity(0.3))
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.1)){
                            showChangeName = false
                            showNewChat = false
                            showEnableLocationAccess = false
                            showVPNError = false
                        }
                    }
            }
        }
        .overlay(content: {
            if showSearchUsers {
                searchUsersMapView().transition(.move(edge: .bottom).combined(with: .opacity))
            }
        })
        .overlay {
            if showEnableLocationAccess {
                enableLocation()
                    .onAppear {
                        alreadyShowedWarning = true
                    }
            } else if showChangeName {
                editPinName().offset(y: chatUsers.isEmpty ? -150 : -10)
            } else if showNewChat {
                newGroupMenu()
            } else if showVPNError {
                vpnAlert()
            }
        }
        .onChange(of: vm.multiBusiness) { _, new in
            if new.isEmpty {
                showMultiSheet = false
            }
        }
        .onChange(of: vm.selectedTag) { _, _ in
            businessGroups = []
        }
        .onChange(of: vm.searchingNav) { _, _ in
            vm.setPlaceMemPosition(animate: true, isMemory: false)
        }
        .onDisappear(perform: {
            vm.selectedPin = nil
            vm.mapGroup = nil
            vm.mapLocation = nil
        })
        .onAppear(perform: {
            mainInit()
        })
    }
    func mainInit() {
        initPeople()
        initPins()
        
        if !chatUsers.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                withAnimation(.easeInOut(duration: 0.15)){
                    dragEnded = false
                    isDragging = false
                }
            }
        }
        
        if globe.currentLocation == nil {
            GlobeLocationManager().requestLocation() { place in
                if !place.0.isEmpty && !place.1.isEmpty {
                    globe.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                    addCurrentUser()
                    if !movedCameraInitially {
                        movedCameraInitially = true
                        withAnimation(.easeInOut(duration: 0.1)) {
                            vm.mapCameraPosition = .region(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: place.2, longitude: place.3),
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)))
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.1)){
                        showEnableLocationAccess = true
                    }
                }
            }
        }

        if let pin = extractLatLongName(from: messageModel.GoToPin.isEmpty ? gcModel.GoToPin : messageModel.GoToPin) {
            let pinCoords = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            showPins = true
            setPinAddress(coords: pinCoords)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            withAnimation(.easeInOut(duration: 0.1)) {
                showPullDownMenu = false
                if let element = self.pins.first(where: { $0.name == pin.name && $0.coordinates.latitude == pin.latitude && $0.coordinates.longitude == pin.longitude }) {
                    vm.selectedPin = element
                } else {
                    self.pins.append(chatPins(coordinates: pinCoords, name: pin.name, uploaderID: auth.currentUser?.id ?? "", uploaderPhoto: auth.currentUser?.profileImageUrl))
                    if let last = self.pins.last {
                        vm.selectedPin = last
                    }
                }
                vm.mapGroup = nil
                vm.mapLocation = nil
                newPin = nil
                showNewPin = false
                showMenu = false
                vm.mapCameraPosition = .region(MKCoordinateRegion(
                    center: pinCoords,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
            }
            messageModel.GoToPin = ""
            gcModel.GoToPin = ""
            movedCameraInitially = true
        } else if !chatUsers.isEmpty {
            vm.mapLocation = nil
            vm.mapGroup = nil
            vm.selectedPin = nil
            vm.selectedBus = nil
            vm.selectedTag = "Restaurants"
            movedCameraInitially = true
            vm.setMapPosition(animate: true, isStory: false)
        } else if showStories {
            movedCameraInitially = true
            vm.setMapPosition(animate: true, isStory: true)
        } else if showPlaces || showMemories {
            movedCameraInitially = true
            vm.setPlaceMemPosition(animate: true, isMemory: showMemories)
        } else if let loc = getUserLocation() {
            movedCameraInitially = true
            withAnimation(.easeInOut(duration: 0.1)) {
                vm.mapCameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
            }
        } else {
            if !alreadyShowedWarning {
                alreadyShowedWarning = true
                withAnimation(.easeInOut(duration: 0.1)){
                    showEnableLocationAccess = true
                }
            }
            if vm.locations.count > 1 {
                movedCameraInitially = true
            }
            vm.setMapPosition(animate: true, isStory: false)
        }
        
        updateUserLocations()
    }
    func matchScore(for text: String, user: User?) -> Int {
        guard let user = user else { return 0 }
        
        let fullName = user.fullname.lowercased()
        let username = user.username.lowercased()
        let searchText = text.lowercased()
        
        var score = 0
        
        if fullName.contains(searchText) {
            score += 10
        }
        if username.contains(searchText) {
            score += 5
        }
        
        return score
    }
    @ViewBuilder
    func searchUsersMapView() -> some View {
        VStack(spacing: 12){
            HStack(spacing: 10){
                TextField("Search", text: $searchMapText)
                    .tint(.blue)
                    .autocorrectionDisabled(true)
                    .padding(8)
                    .padding(.horizontal, 24)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($focusField, equals: .one)
                    .onSubmit {
                        focusField = .two
                    }
                    .onChange(of: searchMapText) { _, newValue in
                        vm.locations.sort { loc1, loc2 in
                            let score1 = matchScore(for: newValue, user: loc1.user)
                            let score2 = matchScore(for: newValue, user: loc2.user)
                            return score1 > score2
                        }
                    }
                    .overlay (
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            Spacer()
                            if !searchMapText.isEmpty {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    searchMapText = ""
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
                    focusField = .two
                    searchMapText = ""
                    withAnimation(.easeInOut){
                        showSearchUsers = false
                    }
                }, label: {
                    Text("Cancel").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                })
            }
            .padding(.top, top_Inset())
            .padding(.horizontal, 12)
            ScrollView {
                LazyVStack {
                    HStack {
                        Text("Find on the Map").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline).bold()
                        Spacer()
                    }.padding(.top).padding(.horizontal, 12)
                    VStack(spacing: 8){
                        let all = vm.locations.filter { $0.user != nil }.filter { $0.user?.id != auth.currentUser?.id }
                        
                        if !all.isEmpty {
                            ForEach(all){ loc in
                                Button {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    focusField = .two
                                    searchMapText = ""
                                    withAnimation(.easeInOut){
                                        showSearchUsers = false
                                    }
                                    sentMessage = ""
                                    itemsN = [
                                        ItemX(title: "On my way!"),
                                        ItemX(title: "Leaving now!"),
                                        ItemX(title: "Send the address."),
                                        ItemX(title: "Just left."),
                                        ItemX(title: "Driving."),
                                    ]
                                    status = ["On my way!" : false, "Leaving now!" : false, "Send the address." : false, "Just left." : false, "Driving." : false]
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        showPullDownMenu = false
                                        newPin = nil
                                        showNewPin = false
                                        showMenu = false
                                    }
                                    vm.showNextLocation(location: loc, lat: 0.002, long: 0.002)
                                } label: {
                                    mapViewSearchRowUser(name: loc.user?.fullname ?? "", photo: loc.user?.profileImageUrl, info: loc.infoString)
                                        .onAppear(perform: {
                                            if loc.infoString == nil {
                                                if let idx = vm.locations.firstIndex(where: { $0.id == loc.id }) {
                                                    let timeFmt = formatTime(date: loc.user?.lastSeen?.dateValue())
                                                    vm.locations[idx].infoString = timeFmt.0
                                                }
                                            }
                                        })
                                }
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("No friends yet...").font(.headline).fontWeight(.semibold)
                                Spacer()
                            }.padding(.vertical)
                        }
                    }
                    .padding(.vertical, 5)
                    .background(.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .cornerRadius(8, corners: .allCorners)
                    .padding(.horizontal, 12)
                }
                Color.clear.frame(height: 85)
            }.scrollDismissesKeyboard(.immediately)
        }.background(colorScheme == .dark ? .black : .white)
    }
    func addCurrentUser() {
        if !vm.locations.contains(where: { ($0.user?.id ?? "") == (auth.currentUser?.id ?? "") }) {
            if let user = auth.currentUser {
                if let coord = getUserLocation() {
                    vm.locations.append(LocationMap(coordinates: coord, user: user, lastUpdated: Date()))
                }
            }
        }
    }
    func initPeople() {
        if (vm.locations.first?.id ?? "") != "skip" {
            vm.locations.insert(LocationMap(id: "skip", coordinates: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)), at: 0)
        }

        addCurrentUser()
        
        if chatUsers.isEmpty {
            vm.tempRemoveLocations.forEach { element in
                if let id = element.user?.id, !vm.locations.contains(where: { ($0.user?.id ?? "") == id }) {
                    vm.locations.append(element)
                }
            }
            vm.tempRemoveLocations = []
            var UIDS = Set<String>()
            messageModel.chats.forEach { element in
                UIDS.insert(element.user.id ?? "")
                if (element.user.silent ?? 0) != 4 {
                    if !vm.locations.contains(where: { ($0.user?.id ?? "") == (element.user.id ?? "") }) {
                        if (((element.convo.uid_one_sharing_location ?? false) && (element.convo.uid_two == (auth.currentUser?.id ?? ""))) || ((element.convo.uid_two_sharing_location ?? false) && (element.convo.uid_one == (auth.currentUser?.id ?? "")))) || ((auth.currentUser?.following ?? []).contains((element.user.id ?? "NA")) && element.user.following.contains(auth.currentUser?.id ?? "NA")) {
                            if let locStr = element.user.currentLocation, let loc = extractLatLong(from: locStr) {
                                let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                                vm.locations.append(LocationMap(coordinates: coord, user: element.user, lastUpdated: Date()))
                            }
                        }
                    }
                }
            }
            gcModel.chats.forEach { element in
                let users = element.users ?? []
                users.forEach { user in
                    UIDS.insert(user.id ?? "")
                    if (user.silent ?? 0) != 4 {
                        if !vm.locations.contains(where: { ($0.user?.id ?? "") == (user.id ?? "") }) {
                            if (element.sharingLocationUIDS ?? []).contains(user.id ?? "") || ((auth.currentUser?.following ?? []).contains(user.id ?? "NA") && user.following.contains(auth.currentUser?.id ?? "NA")) {
                                if let locStr = user.currentLocation, let loc = extractLatLong(from: locStr) {
                                    let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                                    vm.locations.append(LocationMap(coordinates: coord, user: user, lastUpdated: Date()))
                                }
                            }
                        }
                    }
                }
            }
            var allFollowing = auth.currentUser?.following ?? []
            allFollowing.removeAll(where: { UIDS.contains($0) })
            allFollowing.forEach { element in
                if !vm.locations.contains(where: { ($0.user?.id ?? "") == element }) {
                    if let user = popRoot.randomUsers.first(where: { $0.id == element }) ?? messageModel.searchUsers.first(where: { $0.id == element }) ?? messageModel.following.first(where: { $0.id == element }) {
                        if (user.silent ?? 0) != 4 && user.following.contains(auth.currentUser?.id ?? "NA") {
                            if let locStr = user.currentLocation, let loc = extractLatLong(from: locStr) {
                                let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                                vm.locations.append(LocationMap(coordinates: coord, user: user, lastUpdated: Date()))
                            }
                        }
                    } else {
                        UserService().fetchSafeUser(withUid: element) { op_user in
                            if let user = op_user, (user.silent ?? 0) != 4 && !vm.locations.contains(where: { ($0.user?.id ?? "") == element }) {
                                if user.following.contains(auth.currentUser?.id ?? "NA") {
                                    if let locStr = user.currentLocation, let loc = extractLatLong(from: locStr) {
                                        let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                                        vm.locations.append(LocationMap(coordinates: coord, user: user, lastUpdated: Date()))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            vm.tempRemoveLocations = vm.locations
            
            vm.locations = []
            
            if (vm.tempRemoveLocations.first?.id ?? "") == "skip" {
                vm.locations.insert(vm.tempRemoveLocations.remove(at: 0), at: 0)
            }
            if let index = vm.tempRemoveLocations.firstIndex(where: { ($0.user?.id ?? "") == (auth.currentUser?.id ?? "") }) {
                vm.locations.append(vm.tempRemoveLocations.remove(at: index))
            }
            chatUsers.forEach { user in
                if !vm.locations.contains(where: { ($0.user?.id ?? "") == (user.id ?? "") }) && (user.silent ?? 0) != 4 {
                    if let index = vm.tempRemoveLocations.firstIndex(where: { ($0.user?.id ?? "") == (user.id ?? "") }) {
                        vm.locations.append(vm.tempRemoveLocations.remove(at: index))
                    } else if let locStr = user.currentLocation, let loc = extractLatLong(from: locStr) {
                        let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                        vm.locations.append(LocationMap(coordinates: coord, user: user, lastUpdated: Date()))
                    }
                }
            }
        }
    }
    func initStories() {
        if vm.stories.count > 1 {
            return
        }
        if let user = auth.currentUser {
            
            if (vm.stories.first?.id ?? "") != "skip" {
                vm.stories.insert(LocationMap(id: "skip", coordinates: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)), at: 0)
            }
            
            if let stories = profileModel.users.first(where: { $0.user.id == user.id })?.stories {
                stories.forEach { element in
                    if let lat = element.lat, let long = element.long {
                        vm.stories.append(LocationMap(coordinates: CLLocationCoordinate2D(latitude: lat, longitude: long), story: element))
                    } else if let userLoc = getUserLocation() {
                        vm.stories.append(LocationMap(coordinates: userLoc, story: element))
                    }
                }
                vm.setMapPosition(animate: true, isStory: true)
            } else {
                profileModel.fetchStoriesUser(user: user) { stories in
                    stories.forEach { element in
                        if let lat = element.lat, let long = element.long {
                            vm.stories.append(LocationMap(coordinates: CLLocationCoordinate2D(latitude: lat, longitude: long), story: element))
                        } else if let userLoc = getUserLocation() {
                            vm.stories.append(LocationMap(coordinates: userLoc, story: element))
                        }
                    }
                    vm.setMapPosition(animate: true, isStory: true)
                }
            }
        }
    }
    func getUserLocation() -> CLLocationCoordinate2D? {
        var coords: CLLocationCoordinate2D? = nil
        if let loc = globe.currentLocation {
            coords = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.long)
        } else if let locStr = auth.currentUser?.currentLocation, let loc = extractLatLong(from: locStr) {
            coords = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        }
        return coords
    }
    func initPins() {
        if let index = messageModel.currentChat {
            let allPins = messageModel.chats[index].convo.chatPins ?? []
            allPins.forEach { element in
                if let pin = extractLatLongName(from: element) {
                    self.pins.append(chatPins(coordinates: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude), name: pin.name, uploaderID: auth.currentUser?.id ?? "", uploaderPhoto: auth.currentUser?.profileImageUrl))
                }
            }
        } else if let index = gcModel.currentChat {
            let allPins = gcModel.chats[index].chatPins ?? []
            allPins.forEach { element in
                if let pin = extractLatLongName(from: element) {
                    self.pins.append(chatPins(coordinates: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude), name: pin.name, uploaderID: auth.currentUser?.id ?? "", uploaderPhoto: gcModel.chats[index].photo ?? auth.currentUser?.profileImageUrl))
                }
            }
        } else if let pins = auth.currentUser?.mapPins {
            pins.forEach { element in
                if let pin = extractLatLongName(from: element) {
                    self.pins.append(chatPins(coordinates: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude), name: pin.name, uploaderID: auth.currentUser?.id ?? "", uploaderPhoto: auth.currentUser?.profileImageUrl))
                }
            }
        }
    }
    func initMemories() {
        if !vm.fetchedMemories {
            
            if (vm.memories.first?.id ?? "") != "skip" {
                vm.memories.insert(LocationMap(id: "skip", coordinates: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)), at: 0)
            }
            
            UserService().getMemoriesMap { mems, bool in
                vm.fetchedMemories = bool
                
                mems.forEach { element in
                    if !vm.memories.contains(where: { $0.memory?.id == element.id }) {
                        if let lat = element.lat, let long = element.long {
                            vm.memories.append(LocationMap(coordinates: CLLocationCoordinate2D(latitude: lat, longitude: long), memory: element))
                        }
                    }
                }
                vm.setPlaceMemPosition(animate: true, isMemory: true)
            }
        }
    }
    func updateUserLocations() {
        var UIDS = Set<String>()
        (vm.locations + vm.tempRemoveLocations).forEach { element in
            if let id = element.user?.id, let date = element.lastUpdated, !id.isEmpty && id != (auth.currentUser?.id ?? "") {
                if isAtLeast5MinutesOld(date: date) {
                    UIDS.insert(id)
                }
            }
        }
        
        UIDS.forEach { uid in
            UserService().fetchSafeUser(withUid: uid) { op_user in
                if let user = op_user {
                    let isGhost = (user.silent ?? 0) == 4
                    
                    if let index = vm.locations.firstIndex(where: { $0.user?.id ?? "" == uid }) {
                        if isGhost {
                            vm.locations.remove(at: index)
                        } else {
                            vm.locations[index].user = user
                            vm.locations[index].lastUpdated = Date()
                            if let placeStr = user.currentLocation, let coord = extractLatLong(from: placeStr) {
                                vm.locations[index].coordinates = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
                            }
                        }
                    }
                    if let index = vm.tempRemoveLocations.firstIndex(where: { $0.user?.id ?? "" == uid }) {
                        if isGhost {
                            vm.tempRemoveLocations.remove(at: index)
                        } else {
                            vm.tempRemoveLocations[index].user = user
                            vm.tempRemoveLocations[index].lastUpdated = Date()
                            if let placeStr = user.currentLocation, let coord = extractLatLong(from: placeStr) {
                                vm.tempRemoveLocations[index].coordinates = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
                            }
                        }
                    }
                    if let index = messageModel.chats.firstIndex(where: { $0.user.id == user.id }) {
                        messageModel.chats[index].user = user
                    }
                    if let index = profileModel.users.firstIndex(where: { $0.user.id == user.id }) {
                        profileModel.users[index].user = user
                    }
                }
            }
        }
    }
    func addPin(place: CLLocationCoordinate2D, name: String, show: Bool) {
        let pinName = "\(place.latitude),\(place.longitude),\(name)"
        var addPin: Bool = false
        if let index = messageModel.currentChat {
            if (messageModel.chats[index].convo.chatPins ?? []).contains(pinName) {
                popRoot.alertReason = "Pin Already Added"
                popRoot.alertImage = "exclamationmark.triangle.fill"
                withAnimation(.easeInOut(duration: 0.2)){
                    popRoot.showAlert = true
                }
            } else {
                addPin = true
                
                if messageModel.chats[index].convo.chatPins == nil {
                    messageModel.chats[index].convo.chatPins = [pinName]
                } else {
                    messageModel.chats[index].convo.chatPins?.append(pinName)
                }
                
                if let docID = messageModel.chats[index].convo.id {
                    MessageService().addPinForChat(docID: docID, name: name, lat: place.latitude, long: place.longitude)
                    let uid = auth.currentUser?.id ?? ""
                    let uid_prefix = String(uid.prefix(5))
                    let id = uid_prefix + String("\(UUID())".prefix(15))
                    
                    let new = Message(id: id, uid_one_did_recieve: (messageModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? false : true, seen_by_reciever: false, text: nil, imageUrl: nil, timestamp: Timestamp(), sentAImage: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, pinmap: pinName)
                    
                    messageModel.sendStory(i: index, myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: messageModel.chats[index].user.id ?? "", caption: "", imageUrl: nil, videoUrl: nil, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: pinName)
                    
                    messageModel.chats[index].lastM = new
                    
                    if messageModel.chats[index].messages == nil {
                        messageModel.chats[index].messages = [new]
                    } else {
                        messageModel.chats[index].messages?.insert(new, at: 0)
                    }
                }
            }
        } else if let index = gcModel.currentChat {
            if (gcModel.chats[index].chatPins ?? []).contains(pinName) {
                popRoot.alertReason = "Pin Already Added"
                popRoot.alertImage = "exclamationmark.triangle.fill"
                withAnimation(.easeInOut(duration: 0.2)){
                    popRoot.showAlert = true
                }
            } else {
                addPin = true
                
                if gcModel.chats[index].chatPins == nil {
                    gcModel.chats[index].chatPins = [pinName]
                } else {
                    gcModel.chats[index].chatPins?.append(pinName)
                }

                if let docID = gcModel.chats[index].id {
                    GroupChatService().addPinForChat(docID: docID, name: name, lat: place.latitude, long: place.longitude)
                    
                    let id = String((auth.currentUser?.id ?? "").prefix(6)) + String("\(UUID())".prefix(10))
                    let new = GroupMessage(id: id, seen: nil, text: nil, imageUrl: nil, audioURL: nil, videoURL: nil, file: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyFile: nil, replyAudio: nil, replyVideo: nil, countSmile: nil, countCry: nil, countThumb: nil, countBless: nil, countHeart: nil, countQuestion: nil, timestamp: Timestamp(), pinmap: pinName)
                    
                    GroupChatService().sendMessage(docID: docID, text: "", imageUrl: nil, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: nil, long: nil, name: nil, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: pinName)
                    
                    gcModel.chats[index].lastM = new

                    if gcModel.chats[index].messages == nil {
                        gcModel.chats[index].messages = [new]
                    } else {
                        gcModel.chats[index].messages?.insert(new, at: 0)
                    }
                }
            }
        } else {
            if (auth.currentUser?.mapPins ?? []).contains(pinName) {
                popRoot.alertReason = "Pin Already Added"
                popRoot.alertImage = "exclamationmark.triangle.fill"
                withAnimation(.easeInOut(duration: 0.2)){
                    popRoot.showAlert = true
                }
            } else {
                addPin = true
                UserService().addPinForUser(name: name, lat: place.latitude, long: place.longitude)
                if auth.currentUser?.mapPins == nil {
                    auth.currentUser?.mapPins = [pinName]
                } else {
                    auth.currentUser?.mapPins?.append(pinName)
                }
            }
        }
        
        self.pins.append(chatPins(coordinates: place, name: name, uploaderID: auth.currentUser?.id ?? "", uploaderPhoto: auth.currentUser?.profileImageUrl))
        
        if addPin && show {
            showPins = true
            setPinAddress(coords: place)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            withAnimation(.easeInOut(duration: 0.1)) {
                vm.mapGroup = nil
                vm.mapLocation = nil
                vm.selectedBus = nil
                newPin = nil
                showNewPin = false
                showMenu = false
                showPullDownMenu = false
                showSingleSheet = false
                
                if let last = self.pins.last {
                    vm.selectedPin = last
                }
                vm.mapCameraPosition = .region(MKCoordinateRegion(
                    center: place,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
            }
        }
    }
    @ViewBuilder
    func textSearch() -> some View {
        TextField("", text: $searchText)
            .submitLabel(.search)
            .padding(.horizontal, 10).padding(.leading, 25).padding(.trailing, 45).tint(.purple)
            .frame(height: 42)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(content: {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(style: StrokeStyle()).opacity(0.3)
            })
            .focused($searchField, equals: .one)
            .overlay {
                HStack(spacing: 8){
                    Image(systemName: "magnifyingglass")
                        .font(.headline).bold().padding(.leading, 8)
                    if searchText.isEmpty {
                        Text("Search places...").font(.headline)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        searchField = .two
                        performSearch()
                    }, label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .bottomLeading, endPoint: .topTrailing))
                            .clipShape(Capsule())
                    }).padding(.trailing, 7)
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal)
            .onChange(of: searchText) { _, _ in
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    vm.orderPlaces(query: searchText)
                }
            }
            .onSubmit {
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    performSearch()
                }
            }
            .transition(.scale.combined(with: .opacity))
    }
    func performSearch() {
        showPlacesSheet = false
        showSingleSheet = false
        showMultiSheet = false
        vm.selectedTag = searchText
        withAnimation(.easeInOut(duration: 0.2)){
            showSearch = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showTagSheet = true
        }
        if let loc = getUserLocation() {
            vm.loadRestraunts(currentLoc: loc, query: searchText)
        } else if let center = lastCameraPosition, let span = lastCameraSpan {
            if span.latitudeDelta < 0.5 && span.longitudeDelta < 0.5 {
                vm.loadRestraunts(currentLoc: center, query: searchText)
            }
        }
    }
    func openSingle(str: String) {
        if let location = vm.allRestaurants.first(where: { $0.business.id == str }) {
            showMultiSheet = false
            showTagSheet = false
            didSelectThroughSheet = false
            showPlacesSheet = false
            withAnimation(.easeInOut(duration: 0.1)) {
                showPullDownMenu = false
                newPin = nil
                showNewPin = false
                showMenu = false
            }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            vm.showNextPlace(location: location, lat: 0.0008, long: 0.0008)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showSingleSheet = true
            }
        }
    }
    func singleSheetDismissed() {
        vm.selectedBus = nil
        if showPlaces {
            if didSelectThroughSheet {
                didSelectThroughSheet = false
                showPlacesSheet = true
                sheetDetent = .fraction(0.999)
            } else if didSelectThroughTagSheet {
                didSelectThroughTagSheet = false
                tagSheetDismissed()
            }
            vm.setPlaceMemPosition(animate: true, isMemory: showMemories)
        }
    }
    func tagSheetDismissed() {
        if vm.selectedBus == nil {
            if !vm.allRestaurants.contains(where: { $0.tag == vm.selectedTag }) {
                withAnimation(.easeInOut(duration: 0.2)){
                    vm.selectedTag = "Restaurants"
                }
            }
            vm.setPlaceMemPosition(animate: true, isMemory: showMemories)
        }
    }
    private var mapLayer: some View {
        MapReader { mapProxy in
            let allTagMatches = vm.allMatches()
            Map(position: $vm.mapCameraPosition) {
                if let location = self.newPin, showNewPin {
                    Annotation("New Pin", coordinate: location) {
                        CustomPin(image: auth.currentUser?.profileImageUrl ?? "")
                            .onTapGesture {
                                tapCount -= 1
                            }
                    }
                }
                if option == 3 || !chatUsers.isEmpty {
                    if showPlaces {
                        ForEach(allTagMatches) { location in
                            if !businessGroups.contains(where: { $0.allLocs.contains(where: { $0.id == location.business.id }) }) && location.business.id != "skip" {
                                Annotation(location.business.name ?? "", coordinate: location.coordinates) {
                                    BusinessMapAnnotation(photos: (location.business.photos ?? []) + [location.business.image_url ?? ""], id: location.business.id ?? "", currentID: $centerPlaceID, businessCount: 1)
                                        .onTapGesture {
                                            tapCount -= 1
                                            didSelectThroughSheet = false
                                            didSelectThroughTagSheet = false
                                            showPlacesSheet = false
                                            showTagSheet = false
                                            showMultiSheet = false
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                showPullDownMenu = false
                                                newPin = nil
                                                showNewPin = false
                                                showMenu = false
                                            }
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            vm.showNextPlace(location: location, lat: 0.0008, long: 0.0008)
                                            showSingleSheet = true
                                        }
                                }
                            }
                        }
                        ForEach(businessGroups) { location in
                            Annotation(location.name, coordinate: location.coordinates) {
                                BusinessMapAnnotation(photos: location.photos, id: location.id, currentID: $centerPlaceID, businessCount: location.allLocs.count)
                                    .onTapGesture {
                                        tapCount -= 1
                                        if let last = self.lastCameraSpan {
                                            showPlacesSheet = false
                                            showTagSheet = false
                                            showSingleSheet = false
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                showPullDownMenu = false
                                                newPin = nil
                                                showNewPin = false
                                                showMenu = false
                                            }
                                            let long = abs(last.longitudeDelta)
                                            let lat = abs(last.latitudeDelta)
                                            vm.setPlaceRegion(group: location, oldLat: lat, oldLong: long) { open in
                                                if open {
                                                    vm.multiBusiness = location.allLocs.compactMap({ $0.id })
                                                    showMultiSheet = true
                                                }
                                            }
                                        }
                                    }
                            }
                        }
                    } else if showMemories {
                        ForEach(vm.memories) { location in
                            if !memoryGroups.contains(where: { $0.allLocs.contains(where: { $0.id == location.id }) }) && location.id != "skip" {
                                Annotation("", coordinate: location.coordinates) {
                                    StoryMapAnnotation(item: nil, single: location, currentID: $centerMemoryID)
                                        .environmentObject(vm)
                                        .onTapGesture {
                                            upData = [location]
                                            
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            tapCount -= 1
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                newPin = nil
                                                showNewPin = false
                                                showMenu = false
                                            }
                                            if let point = mapProxy.convert(location.coordinates, to: .local) {
                                                animateFromPoint = point
                                            } else {
                                                animateFromPoint = CGPoint(x: widthOrHeight(width: true) / 2.0, y: widthOrHeight(width: false) / 2.0)
                                            }
                                            animateFromPoint.y -= 40
                                            animateToPoint = animateFromPoint
                                            showingStories = false
                                            withAnimation(.easeInOut(duration: 0.05)){
                                                showStoryOverlay = true
                                                disableTopGesture = true
                                            }
                                            withAnimation(.easeInOut(duration: 0.45)){
                                                circleSize = widthOrHeight(width: false) * 2.0
                                                backOpac = 1.0
                                                animateFromPoint = CGPoint(x: widthOrHeight(width: true) / 2.0, y: widthOrHeight(width: false) / 2.0)
                                            }
                                        }
                                }
                            }
                        }
                        ForEach(memoryGroups) { location in
                            Annotation("", coordinate: location.coordinates) {
                                ZStack {
                                    StoryMapAnnotation(item: location, single: nil, currentID: $centerMemoryID)
                                        .environmentObject(vm)
                                        .onTapGesture {
                                            tapCount -= 1
                                            if let last = self.lastCameraSpan {
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                withAnimation(.easeInOut(duration: 0.1)) {
                                                    newPin = nil
                                                    showNewPin = false
                                                    showMenu = false
                                                }
                                                let long = abs(last.longitudeDelta)
                                                let lat = abs(last.latitudeDelta)
                                                vm.setStoryRegion(group: location, oldLat: lat, oldLong: long) { bool in
                                                    if bool {
                                                        upData = location.allLocs.sorted(by: { ($0.memory?.createdAt ?? Timestamp()).dateValue() > ($1.memory?.createdAt ?? Timestamp()).dateValue() })
                                                        
                                                        if let point = mapProxy.convert(location.coordinates, to: .local) {
                                                            animateFromPoint = point
                                                        } else {
                                                            animateFromPoint = CGPoint(x: widthOrHeight(width: true) / 2.0, y: widthOrHeight(width: false) / 2.0)
                                                        }
                                                        animateFromPoint.y -= 40
                                                        animateToPoint = animateFromPoint
                                                        showingStories = false
                                                        withAnimation(.easeInOut(duration: 0.05)){
                                                            showStoryOverlay = true
                                                            disableTopGesture = true
                                                        }
                                                        withAnimation(.easeInOut(duration: 0.45)){
                                                            circleSize = widthOrHeight(width: false) * 2.0
                                                            backOpac = 1.0
                                                            animateFromPoint = CGPoint(x: widthOrHeight(width: true) / 2.0, y: widthOrHeight(width: false) / 2.0)
                                                        }
                                                    } else if showPullDownMenu {
                                                        withAnimation(.easeInOut(duration: 0.1)){
                                                            showPullDownMenu = false
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    
                                }
                            }
                        }
                    } else if showStories {
                        ForEach(vm.stories) { location in
                            if !storyGroups.contains(where: { $0.allLocs.contains(where: { $0.id == location.id }) }) && location.id != "skip" {
                                Annotation("", coordinate: location.coordinates) {
                                    StoryMapAnnotation(item: nil, single: location, currentID: $centerStoryID)
                                        .environmentObject(vm)
                                        .onTapGesture {
                                            upData = [location]
                                            
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            tapCount -= 1
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                newPin = nil
                                                showNewPin = false
                                                showMenu = false
                                            }
                                            if let point = mapProxy.convert(location.coordinates, to: .local) {
                                                animateFromPoint = point
                                            } else {
                                                animateFromPoint = CGPoint(x: widthOrHeight(width: true) / 2.0, y: widthOrHeight(width: false) / 2.0)
                                            }
                                            animateFromPoint.y -= 40
                                            animateToPoint = animateFromPoint
                                            showingStories = true
                                            withAnimation(.easeInOut(duration: 0.05)){
                                                showStoryOverlay = true
                                                disableTopGesture = true
                                            }
                                            withAnimation(.easeInOut(duration: 0.45)){
                                                circleSize = widthOrHeight(width: false) * 2.0
                                                backOpac = 1.0
                                                animateFromPoint = CGPoint(x: widthOrHeight(width: true) / 2.0, y: widthOrHeight(width: false) / 2.0)
                                            }
                                        }
                                }
                            }
                        }
                        ForEach(storyGroups) { location in
                            Annotation("", coordinate: location.coordinates) {
                                ZStack {
                                    StoryMapAnnotation(item: location, single: nil, currentID: $centerStoryID)
                                        .environmentObject(vm)
                                        .onTapGesture {
                                            tapCount -= 1
                                            if let last = self.lastCameraSpan {
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                withAnimation(.easeInOut(duration: 0.1)) {
                                                    newPin = nil
                                                    showNewPin = false
                                                    showMenu = false
                                                }
                                                let long = abs(last.longitudeDelta)
                                                let lat = abs(last.latitudeDelta)
                                                vm.setStoryRegion(group: location, oldLat: lat, oldLong: long) { bool in
                                                    if bool {
                                                        upData = location.allLocs.sorted(by: { ($0.story?.timestamp ?? Timestamp()).dateValue() > ($1.story?.timestamp ?? Timestamp()).dateValue() })
                                                        
                                                        if let point = mapProxy.convert(location.coordinates, to: .local) {
                                                            animateFromPoint = point
                                                        } else {
                                                            animateFromPoint = CGPoint(x: widthOrHeight(width: true) / 2.0, y: widthOrHeight(width: false) / 2.0)
                                                        }
                                                        animateFromPoint.y -= 40
                                                        animateToPoint = animateFromPoint
                                                        showingStories = true
                                                        withAnimation(.easeInOut(duration: 0.05)){
                                                            showStoryOverlay = true
                                                            disableTopGesture = true
                                                        }
                                                        withAnimation(.easeInOut(duration: 0.45)){
                                                            circleSize = widthOrHeight(width: false) * 2.0
                                                            backOpac = 1.0
                                                            animateFromPoint = CGPoint(x: widthOrHeight(width: true) / 2.0, y: widthOrHeight(width: false) / 2.0)
                                                        }
                                                    } else if showPullDownMenu {
                                                        withAnimation(.easeInOut(duration: 0.1)){
                                                            showPullDownMenu = false
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    
                                }
                            }
                        }
                    } else {
                        ForEach(vm.locations) { location in
                            if !groupLocations.contains(where: { $0.allLocs.contains(where: { $0.id == location.id }) }) && location.id != "skip" {
                                Annotation("", coordinate: location.coordinates) {
                                    let cuid = auth.currentUser?.id ?? ""
                                    let isGhost = (location.user?.id ?? "NA") == cuid && (auth.currentUser?.silent ?? 0) == 4
                                    LocationMapAnnotationView(item: location, CUID: cuid, isGhost: isGhost)
                                        .environmentObject(vm)
                                        .scaleEffect(vm.mapLocation?.id == location.id ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: vm.mapLocation?.id)
                                        .onTapGesture {
                                            tapCount -= 1
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                showPullDownMenu = false
                                                newPin = nil
                                                showNewPin = false
                                                showMenu = false
                                            }
                                            sentMessage = ""
                                            itemsN = [
                                                ItemX(title: "On my way!"),
                                                ItemX(title: "Leaving now!"),
                                                ItemX(title: "Send the address."),
                                                ItemX(title: "Just left."),
                                                ItemX(title: "Driving."),
                                            ]
                                            status = ["On my way!" : false, "Leaving now!" : false, "Send the address." : false, "Just left." : false, "Driving." : false]
                                            vm.showNextLocation(location: location, lat: 0.002, long: 0.002)
                                        }
                                }
                            }
                        }
                        ForEach($groupLocations) { $location in
                            Annotation("", coordinate: location.coordinates) {
                                LocationGroupAnnotationView(item: $location)
                                    .environmentObject(vm)
                                    .scaleEffect(vm.mapGroup?.id == location.id ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: vm.mapGroup?.id)
                                    .onTapGesture {
                                        tapCount -= 1
                                        if let last = self.lastCameraSpan {
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                showPullDownMenu = false
                                                newPin = nil
                                                showNewPin = false
                                                showMenu = false
                                            }
                                            let long = abs(last.longitudeDelta)
                                            let lat = abs(last.latitudeDelta)
                                            vm.setMapRegion(group: location, oldLat: lat, oldLong: long)
                                        }
                                    }
                            }
                        }
                    }
                    
                    if showPins {
                        ForEach(pins) { pin in
                            Annotation(pin.name, coordinate: pin.coordinates) {
                                CustomPin(image: pin.uploaderPhoto ?? "")
                                    .scaleEffect(vm.selectedPin?.id == pin.id ? 1.2 : self.scalePin ? 0.6 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: vm.selectedPin?.id)
                                    .animation(.easeInOut(duration: 0.2), value: scalePin)
                                    .onTapGesture {
                                        tapCount -= 1
                                        setPinAddress(coords: pin.coordinates)
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            showPullDownMenu = false
                                            vm.selectedPin = pin
                                            vm.mapGroup = nil
                                            vm.mapLocation = nil
                                            newPin = nil
                                            showNewPin = false
                                            showMenu = false
                                            vm.mapCameraPosition = .region(MKCoordinateRegion(
                                                center: pin.coordinates,
                                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
            }
            .onTapGesture(perform: { screenCoord in
                let screenWidth = widthOrHeight(width: true)
                let screenHeight = widthOrHeight(width: false)
                
                if screenCoord.x > 75.0 && screenCoord.x < (screenWidth - 75.0) && screenCoord.y > 165.0 && screenCoord.y < (screenHeight - 165.0) {
                    tapCount += 1
                    if tapCount == 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            if tapCount == 1 {
                                if let lastSpan = self.lastCameraSpan, lastSpan.latitudeDelta < 0.5 {
                                    if let loc = mapProxy.convert(screenCoord, from: .local) {
                                        self.showMenu = false
                                        withAnimation(.easeIn(duration: 0.15)){
                                            newPin = nil
                                            showNewPin = false
                                        }
                                        self.newPin = loc
                                        
                                        self.MenuPosition = CGPoint(x: screenCoord.x, y: screenCoord.y)
                                        withAnimation(.easeIn(duration: 0.1)){
                                            self.showMenu = true
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                            tapCount = 0
                        }
                    }
                }
            })
            .onMapCameraChange(frequency: .continuous) { context in
                self.lastCameraPosition = context.region.center
                self.lastCameraSpan = context.region.span
                if focusedField == .one {
                    focusedField = .two
                }
                if showMenu {
                    withAnimation(.easeIn(duration: 0.2)){
                        self.showMenu = false
                    }
                }
                if showPullDownMenu {
                    withAnimation(.easeInOut(duration: 0.15)){
                        showPullDownMenu = false
                    }
                }
                if showTagSheet {
                    tagDetent = .height(63.0)
                }
                
                if showPlaces {
                    let widthCenter = widthOrHeight(width: true) / 2.0
                    let heightCenter = widthOrHeight(width: false) / 2.0
                    var centerMost: String? = nil
                    var minDist = 500.0
                    
                    var locationPoints: [(location: Business, point: CGPoint)] = []
                    var groupPoints: [(locationID: String, point: CGPoint)] = []
                    for i in allTagMatches.indices {
                        if allTagMatches[i].business.id != "skip" {
                            if let point = mapProxy.convert(allTagMatches[i].coordinates, to: .local) {
                                locationPoints.append((allTagMatches[i].business, point))
                                if !businessGroups.contains(where: { $0.allLocs.contains(where: { $0.id == allTagMatches[i].business.id }) }) {
                                    let x = abs(point.x)
                                    let y = abs(point.y)
                                    let diffX = abs(widthCenter - x)
                                    let diffY = abs(heightCenter - y)
                                    let totalDiff = diffX + diffY
                                    if totalDiff < minDist && diffX < 50.0 && diffY < 50.0 {
                                        minDist = totalDiff
                                        centerMost = allTagMatches[i].business.id ?? ""
                                    }
                                }
                            }
                        }
                    }
                    for i in businessGroups.indices {
                        if let point = mapProxy.convert(businessGroups[i].coordinates, to: .local) {
                            let x = abs(point.x)
                            let y = abs(point.y)
                            groupPoints.append((businessGroups[i].id, point))
                                                            
                            let diffX = abs(widthCenter - x)
                            let diffY = abs(heightCenter - y)
                            let totalDiff = diffX + diffY
                            if totalDiff < minDist && diffX < 50.0 && diffY < 50.0 {
                                minDist = totalDiff
                                centerMost = businessGroups[i].id
                            }
                        }
                    }
                    if !vm.preventCenter {
                        if let id = centerMost {
                            if id != self.centerPlaceID {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            self.centerPlaceID = id
                        } else {
                            self.centerPlaceID = ""
                        }
                    }
                    if option == 3 {
                        groupPlacesByProximity(locationPoints: locationPoints, groupPoints: groupPoints)
                    }
                } else if showMemories {
                    let widthCenter = widthOrHeight(width: true) / 2.0
                    let heightCenter = widthOrHeight(width: false) / 2.0
                    var centerMost: String? = nil
                    var minDist = 500.0
                    
                    var locationPoints: [(location: LocationMap, point: CGPoint)] = []
                    var groupPoints: [(locationID: String, point: CGPoint)] = []
                    for i in vm.memories.indices {
                        if vm.memories[i].id != "skip" {
                            if let point = mapProxy.convert(vm.memories[i].coordinates, to: .local) {
                                locationPoints.append((vm.memories[i], point))
                                if !memoryGroups.contains(where: { $0.allLocs.contains(where: { $0.id == vm.memories[i].id }) }) {
                                    let x = abs(point.x)
                                    let y = abs(point.y)
                                    let diffX = abs(widthCenter - x)
                                    let diffY = abs(heightCenter - y)
                                    let totalDiff = diffX + diffY
                                    if totalDiff < minDist && diffX < 50.0 && diffY < 50.0 {
                                        minDist = totalDiff
                                        centerMost = vm.memories[i].id
                                    }
                                }
                            }
                        }
                    }
                    for i in memoryGroups.indices {
                        if let point = mapProxy.convert(memoryGroups[i].coordinates, to: .local) {
                            let x = abs(point.x)
                            let y = abs(point.y)
                            groupPoints.append((memoryGroups[i].id, point))
                                                            
                            let diffX = abs(widthCenter - x)
                            let diffY = abs(heightCenter - y)
                            let totalDiff = diffX + diffY
                            if totalDiff < minDist && diffX < 50.0 && diffY < 50.0 {
                                minDist = totalDiff
                                centerMost = memoryGroups[i].id
                            }
                        }
                    }
                    if !vm.preventCenter {
                        if let id = centerMost {
                            if id != self.centerMemoryID {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            self.centerMemoryID = id
                        } else {
                            self.centerMemoryID = ""
                        }
                    }
                    if option == 3 {
                        groupMemoriesByProximity(locationPoints: locationPoints, groupPoints: groupPoints)
                    }
                } else if showStories {
                    let widthCenter = widthOrHeight(width: true) / 2.0
                    let heightCenter = widthOrHeight(width: false) / 2.0
                    var centerMost: String? = nil
                    var minDist = 500.0
                    
                    var locationPoints: [(location: LocationMap, point: CGPoint)] = []
                    var groupPoints: [(locationID: String, point: CGPoint)] = []
                    for i in vm.stories.indices {
                        if vm.stories[i].id != "skip" {
                            if let point = mapProxy.convert(vm.stories[i].coordinates, to: .local) {
                                locationPoints.append((vm.stories[i], point))
                                if !storyGroups.contains(where: { $0.allLocs.contains(where: { $0.id == vm.stories[i].id }) }) {
                                    let x = abs(point.x)
                                    let y = abs(point.y)
                                    let diffX = abs(widthCenter - x)
                                    let diffY = abs(heightCenter - y)
                                    let totalDiff = diffX + diffY
                                    if totalDiff < minDist && diffX < 50.0 && diffY < 50.0 {
                                        minDist = totalDiff
                                        centerMost = vm.stories[i].id
                                    }
                                }
                            }
                        }
                    }
                    for i in storyGroups.indices {
                        if let point = mapProxy.convert(storyGroups[i].coordinates, to: .local) {
                            let x = abs(point.x)
                            let y = abs(point.y)
                            groupPoints.append((storyGroups[i].id, point))
                                                            
                            let diffX = abs(widthCenter - x)
                            let diffY = abs(heightCenter - y)
                            let totalDiff = diffX + diffY
                            if totalDiff < minDist && diffX < 50.0 && diffY < 50.0 {
                                minDist = totalDiff
                                centerMost = storyGroups[i].id
                            }
                        }
                    }
                    if !vm.preventCenter {
                        if let id = centerMost {
                            if id != self.centerStoryID {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            self.centerStoryID = id
                        } else {
                            self.centerStoryID = ""
                        }
                    }
                    if option == 3 {
                        groupStoriesByProximity(locationPoints: locationPoints, groupPoints: groupPoints)
                    }
                } else {
                    let scale1 = context.region.span.latitudeDelta
                    let bottomHeight = 100.0
                    let topHeight = chatUsers.isEmpty ? 45.0 : 140.0
            
                    let showBattery = scale1 < 0.15
                    withAnimation(.easeIn(duration: 0.3)){
                        self.scalePin = scale1 > 2.0
                    }
                    var locationPoints: [(location: LocationMap, point: CGPoint)] = []
                    var groupPoints: [(locationID: String, point: CGPoint)] = []
                    for i in vm.locations.indices {
                        if vm.locations[i].id != "skip" {
                            if let point = mapProxy.convert(vm.locations[i].coordinates, to: .local) {
                                let x = abs(point.x)
                                let y = abs(point.y)
                                locationPoints.append((vm.locations[i], point))
                                
                                withAnimation(.easeIn(duration: 0.3)){
                                    vm.locations[i].shouldShowName = x > 45 && x < (widthOrHeight(width: true) - 45) && y > topHeight && y < (widthOrHeight(width: false) - 45 - bottomHeight)
                                    
                                    vm.locations[i].shouldShowBattery = showBattery
                                }
                            }
                        } else {
                            withAnimation(.easeIn(duration: 0.3)){
                                vm.locations[i].shouldShowName = false
                                vm.locations[i].shouldShowBattery = showBattery
                            }
                        }
                    }
                    for i in groupLocations.indices {
                        if let point = mapProxy.convert(groupLocations[i].coordinates, to: .local) {
                            withAnimation(.easeIn(duration: 0.3)){
                                let x = abs(point.x)
                                let y = abs(point.y)
                                groupPoints.append((groupLocations[i].id, point))
                                groupLocations[i].shouldShowName = x > 45 && x < (widthOrHeight(width: true) - 45) && y > topHeight && y < (widthOrHeight(width: false) - 45 - bottomHeight)
                            }
                        } else {
                            withAnimation(.easeIn(duration: 0.3)){
                                groupLocations[i].shouldShowName = false
                            }
                        }
                    }
                    if option == 3 {
                        groupLocationsByProximity(locationPoints: locationPoints, groupPoints: groupPoints)
                    }
                }
                updateRegion()
            }
        }
    }
    func showLabelTemp() {
        withAnimation(.easeInOut(duration: 0.2)){
            if showStories || showPlaces || showPins || showPlaces {
                showTempLabel.toggle()
            } else {
                showTempLabel = false
            }
        }
        if showTempLabel {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if showTempLabel {
                    withAnimation(.easeInOut(duration: 0.2)){
                        showTempLabel = false
                    }
                }
            }
        }
    }
    func storiesButClicked(isHeader: Bool) {
        initStories()
        showPlacesSheet = false
        showTagSheet = false
        showSingleSheet = false
        showMultiSheet = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.1)){
            showMemories = false
            showPlaces = false
            showStories.toggle()
        }
        if showStories {
            showPins = false
            vm.setMapPosition(animate: true, isStory: showStories)
        } else {
            if let loc = getUserLocation() {
                withAnimation(.easeIn(duration: 0.1)){
                    vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                }
            } else {
                vm.setMapPosition(animate: true, isStory: false)
            }
        }
        centerStoryID = ""
        withAnimation(.easeInOut(duration: 0.1)) {
            vm.selectedPin = nil
            vm.mapGroup = nil
            vm.mapLocation = nil
            newPin = nil
            showNewPin = false
            showMenu = false
            showPullDownMenu = false
        }
        if isHeader && !showPullDownMenu {
            showLabelTemp()
        }
        displayOption = mapOption.stories
    }
    func pinsButClicked(isHeader: Bool) {
        showPlacesSheet = false
        showTagSheet = false
        showSingleSheet = false
        showMultiSheet = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeIn(duration: 0.2)){
            showPins.toggle()
            showPullDownMenu = false
        }
        if !showPins {
            withAnimation(.easeInOut(duration: 0.1)) {
                newPin = nil
                showNewPin = false
                showMenu = false
            }
        } else if !self.pins.isEmpty {
            showStories = false
            showMemories = false
            let all = self.pins.compactMap({ $0.coordinates })
            vm.setPinPosition(coords: all)
        }
        if isHeader && !showPullDownMenu {
            showLabelTemp()
        }
        displayOption = mapOption.pins
    }
    func memoriesButClicked(isHeader: Bool) {
        initMemories()
        showPlacesSheet = false
        showTagSheet = false
        showSingleSheet = false
        showMultiSheet = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.1)){
            showPlaces = false
            showStories = false
            showMenu = false
            vm.selectedPin = nil
            vm.mapGroup = nil
            vm.mapLocation = nil
            newPin = nil
            showNewPin = false
            showMemories.toggle()
            showPullDownMenu = false
        }
        if showMemories {
            showPins = false
            vm.setPlaceMemPosition(animate: true, isMemory: true)
        } else {
            if let loc = getUserLocation() {
                withAnimation(.easeIn(duration: 0.1)){
                    vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                }
            } else {
                vm.setMapPosition(animate: true, isStory: showStories)
            }
        }
        centerMemoryID = ""
        if isHeader && !showPullDownMenu {
            showLabelTemp()
        }
        displayOption = mapOption.memories
    }
    func placesButClicked(isHeader: Bool) {
        withAnimation(.easeInOut(duration: 0.1)) {
            showStories = false
            showMemories = false
            showMenu = false
            showPlaces.toggle()
            showPlacesSheet = showPlaces
            showPullDownMenu = false
            vm.selectedPin = nil
            vm.mapGroup = nil
            vm.mapLocation = nil
            newPin = nil
            showNewPin = false
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if showPlaces {
            vm.setPlaceMemPosition(animate: true, isMemory: false)
        } else {
            showPlacesSheet = false
            showTagSheet = false
            showSingleSheet = false
            showMultiSheet = false
            if let loc = getUserLocation() {
                withAnimation(.easeIn(duration: 0.1)){
                    vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                }
            } else {
                vm.setMapPosition(animate: true, isStory: showStories)
            }
        }
        if vm.allRestaurants.count < 5 {
            if let coord = getUserLocation() {
                vm.loadRestraunts(currentLoc: coord, query: "Restaurants")
            } else if !alreadyShowedWarning {
                alreadyShowedWarning = true
                withAnimation(.easeInOut(duration: 0.2)){
                    showEnableLocationAccess = true
                }
            } else if let center = lastCameraPosition, let span = lastCameraSpan {
                if span.latitudeDelta < 0.5 && span.longitudeDelta < 0.5 {
                    vm.loadRestraunts(currentLoc: center, query: "Restaurants")
                }
            }
        }
        centerPlaceID = ""
        if isHeader && !showPullDownMenu {
            showLabelTemp()
        }
        displayOption = mapOption.places
    }
    func updateRegion() {
        if let center = lastCameraPosition, let span = lastCameraSpan {
            let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
            var type = 1
            var proximityThreshold = 2218.0
            if span.latitudeDelta < 0.6 {
            } else if span.latitudeDelta < 8.0 {
                type = 2
                proximityThreshold = 221868.0
            } else if span.latitudeDelta < 24.0 {
                type = 3
                proximityThreshold = 443736.0
            } else {
                type = 4
                proximityThreshold = 543736.0
            }
            if type == 4 {
                let continent = getContinent(center: center)
                if let first = self.resuableLocs.first(where: { $0.type == 4 && $0.name == continent }) {
                    withAnimation(.easeInOut(duration: 0.25)){
                        self.currentPlaceName = first.name
                        self.timeString = first.time
                        self.isDayOrNight = first.isDay
                    }
                    getStoriesForRegion(type: type)
                    return
                }
            }
            for loc in self.resuableLocs {
                if loc.type == type {
                    let existingLocation = CLLocation(latitude: loc.coordinates.latitude, longitude: loc.coordinates.longitude)
                    if location.distance(from: existingLocation) < proximityThreshold {
                        withAnimation(.easeInOut(duration: 0.25)){
                            self.currentPlaceName = loc.name
                            self.timeString = loc.time
                            self.isDayOrNight = loc.isDay
                        }
                        getStoriesForRegion(type: type)
                        return
                    }
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
                    
                    var placeName: String? = nil
                    var type = 1
                    if span.latitudeDelta < 0.6 {
                        placeName = placemark.locality
                    } else if span.latitudeDelta < 8.0 {
                        if let state = placemark.administrativeArea {
                            if let full = statesDictionary[state] {
                                placeName = full
                            } else {
                                placeName = state
                            }
                            type = 2
                        } else {
                            placeName = placemark.locality
                        }
                    } else if span.latitudeDelta < 24.0 {
                        type = 3
                        if var country = placemark.country {
                            var flag: String? = nil
                            if let code = placemark.isoCountryCode {
                                flag = " " + countryFlag(code)
                            }
                            if country == "Israel" {
                                country = "Palestine"
                                flag = "🇵🇸"
                            }
                            placeName = country + (flag ?? "")
                        }
                    } else {
                        type = 4
                        placeName = self.getContinent(center: center)
                    }
                    
                    if let placeName = placeName {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "hh:mm a"
                        dateFormatter.timeZone = placemark.timeZone
                        let currentTime = dateFormatter.string(from: Date())
                        let isDayOrNight = isDayOrNightFunc(timeString: currentTime) ?? true
                        
                        let new = reusableLocation(coordinates: center, name: placeName, time: currentTime, isDay: isDayOrNight, type: type)
                        self.resuableLocs.append(new)
                        
                        withAnimation(.easeInOut(duration: 0.25)){
                            self.currentPlaceName = placeName
                            self.timeString = currentTime
                            self.isDayOrNight = isDayOrNight
                        }
                    }
                    getStoriesForRegion(type: type)
                }
            }
        }
    }
    func getStoriesForRegion(type: Int) {
        if type == 4 {
            withAnimation(.easeInOut(duration: 0.3)){
                storiesFoundForLocation = false
            }
            storiesForPlace = []
            return
        }
        if let coords = lastCameraPosition {
            var final = [LocationMap]()
            var meterThreshold = 10000.0
            if type == 2 {
                meterThreshold = 320000.0
            } else if type == 3 {
                meterThreshold = 900000.0
            }
            let p1 = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
            vm.regionStories.forEach { element in
                let p2 = CLLocation(latitude: element.coordinates.latitude, longitude: element.coordinates.longitude)
                if p1.distance(from: p2) < meterThreshold {
                    final.append(element)
                }
            }
            if !final.isEmpty {
                withAnimation(.easeInOut(duration: 0.3)){
                    storiesFoundForLocation = true
                }
                storiesForPlace = final
            } else {
                withAnimation(.easeInOut(duration: 0.3)){
                    storiesFoundForLocation = false
                }
                storiesForPlace = []
                let index = coords.h3CellIndex(resolution: 1)
                let hex = String(index, radix: 16, uppercase: true)
                let neighbors = coords.h3Neighbors(resolution: 1, ringLevel: 1)
                var arr = [String]()
                for item in neighbors {
                    arr.append(String(item, radix: 16, uppercase: true))
                }
                globe.getMapRegionStories(place: hex, neighbors: arr) { stories in
                    stories.forEach { element in
                        if !vm.regionStories.contains(where: { $0.story?.id == element.id }) {
                            var storyCoord = coords
                            if let lat = element.lat, let long = element.long {
                                storyCoord = CLLocationCoordinate2D(latitude: lat, longitude: long)
                            }
                            vm.regionStories.append(LocationMap(coordinates: storyCoord, story: element))
                        }
                    }
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)){
                storiesFoundForLocation = false
            }
            storiesForPlace = []
        }
    }
    func getContinent(center: CLLocationCoordinate2D) -> String? {
        let latitude = center.latitude
        let longitude = center.longitude
        
        let continents: [String: (ClosedRange<Double>, ClosedRange<Double>)] = [
            "Africa": ((-30.0...40.0), (-30.0...60.0)),
            "Asia": ((20.0...80.0), (0.0...160.0)),
            "Europe": ((40.0...80.0), (-30.0...50.0)),
            "North America": ((0.0...90.0), (-180.0...0.0)),
            "Oceania": ((-60.0...20.0), (120.0...180.0)),
            "South America": ((-70.0...20.0), (-140.0...0.0))
        ]
        
        for (continent, (latRange, lonRange)) in continents {
            if latRange.contains(latitude) && lonRange.contains(longitude) {
                return continent
            }
        }
        return nil
    }
    private var header: some View {
        ZStack(alignment: .top){
            if chatUsers.isEmpty {
                VStack {
                    LinearGradient(colors: [colorScheme == .dark ? .gray.opacity(0.75) : .gray, .clear], startPoint: .top, endPoint: .bottom).frame(height: 110).offset(y: chatUsers.isEmpty ? 0 : -50)
                    Spacer()
                }.ignoresSafeArea().allowsHitTesting(false)
            } else {
                VStack {
                    Color.gray.opacity(0.001).frame(height: 110).offset(y: chatUsers.isEmpty ? 0 : -50)
                    Spacer()
                }.ignoresSafeArea().allowsHitTesting(false)
            }
            HStack(alignment: .top){
                if chatUsers.isEmpty {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showPlacesSheet = false
                        showTagSheet = false
                        showSingleSheet = false
                        showMultiSheet = false
                        showSettings = false
                        close(2)
                        withAnimation(.easeInOut(duration: 0.1)) {
                            vm.selectedPin = nil
                            vm.mapGroup = nil
                            vm.mapLocation = nil
                            newPin = nil
                            showNewPin = false
                            showMenu = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                if showStories {
                                    vm.setMapPosition(animate: true, isStory: true)
                                } else if showMemories || showPlaces {
                                    vm.setPlaceMemPosition(animate: true, isMemory: showMemories)
                                } else {
                                    if let loc = getUserLocation() {
                                        withAnimation(.easeIn(duration: 0.1)){
                                            vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                                        }
                                    }
                                }
                            }
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }, label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white).font(.title2).bold()
                            .frame(width: 40, height: 40)
                            .background(.gray.opacity(0.6))
                            .clipShape(Circle())
                    })
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 10){
                    Button(action: {
                        if showPlacesSheet || showTagSheet || showSingleSheet || showMultiSheet {
                            showPlacesSheet = false
                            showTagSheet = false
                            showSingleSheet = false
                            showMultiSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showSettings.toggle()
                            }
                        } else {
                            showSettings.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.white).font(.title3).bold()
                            .frame(width: 40, height: 40)
                            .background(.gray.opacity(0.6))
                            .clipShape(Circle())
                    })
                    HStack(alignment: .top, spacing: 5){
                        VStack(alignment: .trailing, spacing: 4){
                            let text = displayOption == .pins ? "Pins" : displayOption == .stories ? "Stories" : displayOption == .places ? "Places" : "Memories"
                            if showTempLabel || showPullDownMenu {
                                label(name: text).frame(height: 35)
                            }
                            if showPullDownMenu {
                                if text != "Pins" {
                                    label(name: "Pins")
                                        .frame(height: 35)
                                }
                                if text != "Stories" {
                                    label(name: "Stories")
                                        .frame(height: 35)
                                }
                                if text != "Places" {
                                    label(name: "Places")
                                        .frame(height: 35)
                                }
                                if text != "Memories" {
                                    label(name: "Memories")
                                        .frame(height: 35)
                                }
                            }
                        }.padding(.top, 2.5)
                        VStack(spacing: 4){
                            let color: Color = displayOption == .pins ? .red : displayOption == .stories ? Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255) : displayOption == .places ? .green : .orange
                            let image = displayOption == .pins ? "mappin" : displayOption == .stories ? "book.pages.fill" : displayOption == .places ? "fork.knife" : "wand.and.stars.inverse"
                            Button(action: {
                                if displayOption == .stories {
                                    storiesButClicked(isHeader: true)
                                } else if displayOption == .memories {
                                    memoriesButClicked(isHeader: true)
                                } else if displayOption == .pins {
                                    pinsButClicked(isHeader: true)
                                } else if displayOption == .places {
                                    placesButClicked(isHeader: true)
                                }
                            }, label: {
                                Image(systemName: image)
                                    .foregroundStyle(.white).font(.headline).bold()
                                    .frame(width: 35, height: 35)
                                    .background(color)
                                    .clipShape(Circle())
                                    .contentTransition(.symbolEffect(.replace))
                                    .overlay(alignment: .bottomTrailing){
                                        if showStories || showPins || showMemories || showPlaces {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 9)).bold()
                                                .foregroundStyle(.black)
                                                .padding(3)
                                                .background(.white)
                                                .clipShape(Circle())
                                                .transition(.scale)
                                        }
                                    }
                            })
                            if showPullDownMenu {
                                if image != "mappin" {
                                    Button {
                                        pinsButClicked(isHeader: true)
                                    } label: {
                                        Image(systemName: "mappin")
                                            .foregroundStyle(.white).font(.subheadline).bold()
                                            .frame(width: 35, height: 35)
                                            .background(.red)
                                            .clipShape(Circle())
                                    }
                                }
                                if image != "book.pages.fill" {
                                    Button {
                                        storiesButClicked(isHeader: true)
                                    } label: {
                                        Image(systemName: "book.pages.fill")
                                            .foregroundStyle(.white).font(.subheadline).bold()
                                            .frame(width: 35, height: 35)
                                            .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                                            .clipShape(Circle())
                                    }
                                }
                                if image != "fork.knife" {
                                    Button {
                                        placesButClicked(isHeader: true)
                                    } label: {
                                        Image(systemName: "fork.knife")
                                            .foregroundStyle(.white).font(.subheadline).bold()
                                            .frame(width: 35, height: 35)
                                            .background(.green)
                                            .clipShape(Circle())
                                    }
                                }
                                if image != "wand.and.stars.inverse" {
                                    Button {
                                        memoriesButClicked(isHeader: true)
                                    } label: {
                                        Image(systemName: "wand.and.stars.inverse")
                                            .foregroundStyle(.white).font(.subheadline).bold()
                                            .frame(width: 35, height: 35)
                                            .background(.orange)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)){
                                    showPullDownMenu.toggle()
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Image(systemName: showPullDownMenu ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(.white).font(.subheadline).bold()
                                    .contentTransition(.symbolEffect(.replace))
                                    .frame(width: 25, height: 25)
                                    .background(Color(UIColor.lightGray).opacity(0.7))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.vertical, 2.5)
                        .frame(width: 40)
                        .background(.gray.opacity(colorScheme == .dark ? 0.6 : 0.3))
                        .clipShape(Capsule())
                    }.opacity(chatUsers.isEmpty ? 1.0 : (isDragging ? 0.2 : 1.0))
                }
            }
            .padding(.horizontal)
            VStack(spacing: 6){
                HStack {
                    Spacer()
                    HStack(spacing: 20){
                        if storiesFoundForLocation {
                            ZStack {
                                Circle()
                                    .stroke(.pink, lineWidth: 1)
                                    .frame(width: 33, height: 33)
                                
                                let image: String? = storiesForPlace.first(where: { $0.story?.imageURL != nil })?.story?.imageURL
                                
                                KFImage(URL(string: image ?? "https://st3.depositphotos.com/1005145/15351/i/450/depositphotos_153516954-stock-photo-summer-landscape-with-flowers-in.jpg"))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                                    .transition(.scale.combined(with: .move(edge: .leading)))
                            }
                            .onTapGesture {
                                if !storiesForPlace.isEmpty {
                                    upData = storiesForPlace.sorted(by: { ($0.story?.timestamp ?? Timestamp()).dateValue() > ($1.story?.timestamp ?? Timestamp()).dateValue() })
                                    
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    tapCount -= 1
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        newPin = nil
                                        showNewPin = false
                                        showMenu = false
                                    }
                                    let sub = Double(currentPlaceName.count) * 7.0
                                    animateFromPoint = CGPoint(x: (widthOrHeight(width: true) / 2.0) - sub, y: top_Inset() + 20.0)
                                    animateToPoint = animateFromPoint
                                    showingStories = true
                                    withAnimation(.easeInOut(duration: 0.05)){
                                        showStoryOverlay = true
                                        disableTopGesture = true
                                    }
                                    withAnimation(.easeInOut(duration: 0.45)){
                                        circleSize = widthOrHeight(width: false) * 2.0
                                        backOpac = 1.0
                                        animateFromPoint = CGPoint(x: widthOrHeight(width: true) / 2.0, y: widthOrHeight(width: false) / 2.0)
                                    }
                                } else {
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                }
                            }
                        }
                        Text(currentPlaceName)
                            .foregroundStyle(.white)
                            .font(.title3).fontWeight(.heavy)
                            .truncationMode(.tail)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                            .transition(.slide.combined(with: .blurReplace))
                            .id("MyTitleComponent" + currentPlaceName)
                    }
                    .padding(.leading, 4).padding(.trailing, 10)
                    .frame(height: 40)
                    .background(storiesFoundForLocation ? .gray.opacity(0.6) : .clear)
                    .clipShape(Capsule())
                    .frame(maxWidth: widthOrHeight(width: true) * 0.7)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    Spacer()
                }
                HStack(spacing: 4){
                    Image(systemName: isDayOrNight ? "sun.max.fill" : "moon.stars.fill")
                    Text(timeString)
                }
                .transition(.slide.combined(with: .blurReplace))
                .id("MyTitleComponent" + currentPlaceName)
                .font(.caption).bold()
                .shadow(color: .gray, radius: 10)
                .offset(y: storiesFoundForLocation ? 0 : -10)
            }
        }
    }
    @ViewBuilder
    func pinMenu() -> some View {
        VStack(spacing: 10){
            if chatUsers.isEmpty {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let center = self.newPin {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        messageModel.postStoryLoc = (CGFloat(center.latitude), CGFloat(center.longitude))
                        withAnimation(.easeInOut(duration: 0.1)) {
                            showMenu = false
                        }
                        close(1)
                    }
                }, label: {
                    HStack {
                        Text("Post Story")
                            .font(.headline).bold()
                        Spacer()
                        Image(systemName: "plus").font(.headline)
                    }.foregroundStyle(colorScheme == .dark ? .white : .black)
                })
                Divider()
            }
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeInOut(duration: 0.1)) {
                    showMenu = false
                    self.showNewPin = true
                    vm.selectedPin = nil
                    vm.mapGroup = nil
                    vm.mapLocation = nil
                    if let center = self.newPin {
                        vm.mapCameraPosition = .region(MKCoordinateRegion(
                            center:  center,
                            span: MKCoordinateSpan(latitudeDelta: 0.0008, longitudeDelta: 0.0008)))
                        setPinAddress(coords: center)
                    }
                }
            }, label: {
                HStack {
                    Text("Drop Pin")
                        .font(.headline).bold()
                    Spacer()
                    Image(systemName: "mappin.and.ellipse").font(.headline)
                }.foregroundStyle(colorScheme == .dark ? .white : .black)
            })
        }
        .padding(10)
        .frame(width: 150, height: chatUsers.isEmpty ? 80 : 40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(content: {
            RoundedRectangle(cornerRadius: 12).stroke(.gray, lineWidth: 1.0)
        })
        .overlay(alignment: .top, content: {
            Triangle().frame(width: 14, height: 14)
                .foregroundStyle(.gray).offset(y: -14)
        })
        .transition(.scale.combined(with: .blurReplace))
        .position(x: MenuPosition.x, y: MenuPosition.y)
    }
    func label(name: String) -> some View {
        Text(name)
            .foregroundStyle(.black)
            .font(.caption).bold()
            .padding(4).padding(.horizontal, 6)
            .background(.white)
            .clipShape(Capsule())
            .transition(.scale.combined(with: .move(edge: .trailing)))
            .shadow(color: .gray, radius: 4)
    }
    func setPinAddress(coords: CLLocationCoordinate2D) {
        self.pinAddress = ""
        if let address = pinAddresses.first(where: { $0.0.latitude == coords.latitude && $0.0.longitude == coords.longitude })?.1 {
            self.pinAddress = address
        } else {
            let location = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                if error != nil { return }
                
                if let placemark = placemarks?.first {
                    var addressString = ""
                    
                    if let subThoroughfare = placemark.subThoroughfare {
                        addressString += subThoroughfare + " "
                    }
                    if let thoroughfare = placemark.thoroughfare {
                        addressString += thoroughfare + ", "
                    }
                    if let locality = placemark.locality {
                        addressString += locality + ", "
                    }
                    if let administrativeArea = placemark.administrativeArea {
                        addressString += administrativeArea + " "
                    }
                    if let postalCode = placemark.postalCode {
                        addressString += postalCode + " "
                    }
                    if let country = placemark.country {
                        addressString += country
                    }
                    
                    self.pinAddress = addressString
                    self.pinAddresses.append((coords, addressString))
                }
            }
        }
    }
    func pinView(item: chatPins?) -> some View {
        VStack {
            HStack(alignment: .top, spacing: 8){
                if let index = gcModel.currentChat, let image = gcModel.chats[index].photo {
                    CustomPin(image: image)
                } else {
                    CustomPin(image: auth.currentUser?.profileImageUrl ?? "")
                }
                VStack(alignment: .leading, spacing: 6){
                    HStack(spacing: 5){
                        if let item {
                            Text(item.name.isEmpty ? "Pin" : item.name)
                                .font(.title2).bold()
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .lineLimit(1).minimumScaleFactor(0.9).truncationMode(.tail)
                        } else {
                            Text(newPinText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Pin Name" : newPinText)
                                .font(.title2).bold()
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .lineLimit(1).minimumScaleFactor(0.9).truncationMode(.tail)
                        }
                        if item == nil {
                            Image(systemName: "pencil")
                                .font(.headline).bold()
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                        Spacer()
                    }
                    .onTapGesture {
                        if item == nil {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.1)) {
                                showChangeName = true
                            }
                            focusedField = .one
                        }
                    }
                    let lat: CGFloat = CGFloat(item?.coordinates.latitude ?? newPin?.latitude ?? 0.0)
                    let long: CGFloat = CGFloat(item?.coordinates.longitude ?? newPin?.longitude ?? 0.0)
                    Text(pinAddress.isEmpty ? "lat: \(String(format: "%.2f", lat)), long: \(String(format: "%.2f", long))" : pinAddress)
                        .lineLimit(2).minimumScaleFactor(0.9)
                        .font(.subheadline).foregroundStyle(.gray)
                        .onTapGesture {
                            if !pinAddress.isEmpty {
                                popRoot.alertReason = "Address copied"
                                UIPasteboard.general.string = pinAddress
                            } else {
                                popRoot.alertReason = "Location copied"
                                UIPasteboard.general.string = "https://hustle.page/location/lat=\(lat),long=\(long),name="
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            popRoot.alertImage = "link"
                            withAnimation {
                                popRoot.showAlert = true
                            }
                        }
                }.padding(.leading, 6)
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeIn(duration: 0.1)){
                        vm.selectedPin = nil
                        self.showNewPin = false
                    }
                    
                    let all = self.pins.compactMap({ $0.coordinates })
                    
                    if showPins && !all.isEmpty {
                        vm.setPinPosition(coords: all)
                    } else if showMemories || showPlaces {
                        vm.setPlaceMemPosition(animate: true, isMemory: showMemories)
                    } else if showStories {
                        vm.setMapPosition(animate: true, isStory: true)
                    } else if let loc = getUserLocation() {
                        withAnimation(.easeIn(duration: 0.1)){
                            vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                        }
                    } else {
                        vm.setMapPosition(animate: true, isStory: false)
                    }
                    selectedOffset = 0.0
                }, label: {
                    ZStack {
                        Rectangle().frame(width: 40, height: 40)
                            .foregroundStyle(.gray).opacity(0.001)
                        Image(systemName: "xmark")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .font(.subheadline).bold()
                            .frame(width: 30, height: 30)
                            .background(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                            .clipShape(Circle())
                    }
                })
            }.padding(.top, 10)
            Spacer()
            HStack(spacing: 12){
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let item {
                        sendLink = "\(item.coordinates.latitude),\(item.coordinates.longitude),\(item.name)"
                        showForward = true
                    } else if let pin = self.newPin {
                        sendLink = "\(pin.latitude),\(pin.longitude),\(newPinText)"
                        showForward = true
                    }
                }, label: {
                    HStack(spacing: 5){
                        Spacer()
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.white)
                            .font(.headline)
                        Text("Share Pin")
                            .foregroundStyle(.white)
                            .font(.headline)
                        Spacer()
                    }
                    .frame(height: 36)
                    .background(.green)
                    .clipShape(Capsule())
                })
                Button(action: {
                    if let item {
                        openMaps(lat: item.coordinates.latitude, long: item.coordinates.longitude, name: item.name)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    HStack(spacing: 5){
                        Image(systemName: "car.fill")

                        if let timeStr = item?.timeDistance {
                            Text(timeStr.isEmpty ? "-- min" : timeStr)
                        } else if !newPinDriveTime.isEmpty {
                            Text(newPinDriveTime)
                        } else {
                            ProgressView()
                        }
                    }
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .font(.headline)
                    .frame(width: 110, height: 36)
                    .background(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                    .clipShape(Capsule())
                })
                .onAppear(perform: {
                    if let item {
                        if item.timeDistance == nil {
                            if let start = getUserLocation() {
                                calculateDrivingTime(from: start, to: item.coordinates) { time in
                                    if let timeStr = time, !timeStr.isEmpty {
                                        if let idx = self.pins.firstIndex(where: { $0.id == item.id }) {
                                            self.pins[idx].timeDistance = timeStr
                                            self.vm.selectedPin?.timeDistance = timeStr
                                        }
                                    }
                                }
                            }
                        }
                    } else if let coord = newPin, let start = getUserLocation() {
                        newPinDriveTime = ""
                        calculateDrivingTime(from: start, to: coord) { time in
                            self.newPinDriveTime = time ?? "-- min"
                        }
                    }
                })
                Button(action: {
                    if let item {
                        let pinName = "\(item.coordinates.latitude),\(item.coordinates.longitude),\(item.name)"
                        if chatUsers.isEmpty {
                            auth.currentUser?.mapPins?.removeAll(where: { $0 == pinName })
                            UserService().removePinForUser(name: pinName)
                        } else if let index = messageModel.currentChat {
                            messageModel.chats[index].convo.chatPins?.removeAll(where: { $0 == pinName })
                            if let id = messageModel.chats[index].convo.id {
                                MessageService().removePinForChat(docID: id, name: pinName)
                            }
                        } else if let index = gcModel.currentChat {
                            gcModel.chats[index].chatPins?.removeAll(where: { $0 == pinName })
                            if let id = gcModel.chats[index].id {
                                GroupChatService().removePinForChat(docID: id, name: pinName)
                            }
                        }
                        if let idx = self.pins.firstIndex(where: { $0.id == item.id }) {
                            self.pins.remove(at: idx)
                        }
                    }
                    withAnimation(.easeIn(duration: 0.1)){
                        newPin = nil
                        vm.selectedPin = nil
                        self.showNewPin = false
                    }
                    if showMemories || showPlaces {
                        vm.setPlaceMemPosition(animate: true, isMemory: showMemories)
                    } else if showStories {
                        vm.setMapPosition(animate: true, isStory: true)
                    } else if let loc = getUserLocation() {
                        withAnimation(.easeIn(duration: 0.1)){
                            vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                        }
                    } else {
                        vm.setMapPosition(animate: true, isStory: false)
                    }
                    selectedOffset = 0.0
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.red)
                        .font(.title2).frame(width: 70, height: 36)
                        .background(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                        .clipShape(Capsule())
                })
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 135)
        .background(.ultraThinMaterial)
        .cornerRadius(25, corners: [.topLeft, .topRight])
        .shadow(color: .gray, radius: 4)
        .transition(.move(edge: .bottom))
        .offset(y: selectedOffset)
        .onDisappear(perform: {
            if let new = newPin {
                newPin = nil
                addPin(place: new, name: newPinText.isEmpty ? "Pin" : newPinText, show: false)
                newPinText = ""
            }
        })
        .gesture(DragGesture()
            .onChanged({ value in
                if showPullDownMenu {
                    withAnimation(.easeInOut(duration: 0.15)){
                        showPullDownMenu = false
                    }
                }
                if value.translation.height >= 0.0 {
                    selectedOffset = value.translation.height
                }
                if focusedField == .one {
                    focusedField = .two
                }
            })
            .onEnded({ value in
                if value.translation.height > 50.0 || value.velocity.height > 300.0 {
                    withAnimation(.easeIn(duration: 0.1)){
                        vm.selectedPin = nil
                        self.showNewPin = false
                    }
                    if showMemories || showPlaces {
                        vm.setPlaceMemPosition(animate: true, isMemory: showMemories)
                    } else if showStories {
                        vm.setMapPosition(animate: true, isStory: true)
                    } else if let loc = getUserLocation() {
                        withAnimation(.easeIn(duration: 0.1)){
                            vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                        }
                    } else {
                        vm.setMapPosition(animate: true, isStory: false)
                    }
                    selectedOffset = 0.0
                } else {
                    withAnimation(.easeInOut(duration: 0.2)){
                        selectedOffset = 0.0
                    }
                }
            })
        )
    }
    func personView(person: LocationMap) -> some View {
        VStack(spacing: 10){
            if (person.user?.id ?? "") != (auth.currentUser?.id ?? "") {
                HStack {
                    Spacer()
                    GeometryReader {
                        let size = $0.size
                        let topPadding: CGFloat = size.height - (itemHeight + 5.0)
                        let tempViewTop = self.tempTop
                        ScrollViewReader(content: { proxy in
                            ScrollView(.vertical) {
                                LazyVStack(alignment: .trailing, spacing: 10) {
                                    ForEach(Array(zip(itemsN.indices, itemsN)), id: \.0) { index, item in
                                        Button {
                                            if let user = person.user, let other_uid = user.id {
                                                let uid = auth.currentUser?.id ?? ""
                                                let uid_prefix = String(uid.prefix(5))
                                                let id = uid_prefix + String("\(UUID())".prefix(15))
                                                
                                                if let index = messageModel.chats.firstIndex(where: { $0.user.id == other_uid }) {
                                                    let new = Message(id: id, uid_one_did_recieve: (messageModel.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? false : true, seen_by_reciever: false, text: item.title.isEmpty ? nil : item.title, imageUrl: nil, timestamp: Timestamp(), sentAImage: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, pinmap: nil)
                                                    
                                                    messageModel.sendStory(i: index, myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: other_uid, caption: item.title, imageUrl: nil, videoUrl: nil, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: nil)
                                                    
                                                    messageModel.chats[index].lastM = new
                                                    
                                                    messageModel.chats[index].messages?.insert(new, at: 0)
                                                    
                                                    if let indexSec = messageModel.currentChat, indexSec == index {
                                                        if messageModel.chats[index].messages == nil {
                                                            messageModel.chats[index].messages = [new]
                                                        }
                                                        messageModel.setDate()
                                                    }
                                                } else {
                                                    messageModel.sendStorySec(otherUserUid: other_uid, caption: item.title, imageUrl: nil, videoUrl: nil, messageID: id, audioStr: nil, lat: nil, long: nil, name: nil, pinmap: nil)
                                                }
                                            }
                                            
                                            withAnimation(.easeInOut(duration: 0.05)){
                                                proxy.scrollTo("bottom", anchor: .bottom)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation(.easeInOut(duration: 0.05)){
                                                    tempTop = item.id
                                                }
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                status[item.title] = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                    withAnimation(.easeInOut(duration: 0.75)){
                                                        sentMessage = item.title
                                                    }
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                    tempTop = ""
                                                    sentMessage = ""
                                                    if person.id == vm.mapLocation?.id {
                                                        itemsN.removeAll(where: { $0.title == item.title })
                                                    }
                                                }
                                            }
                                        } label: {
                                            Text(item.title).font(.subheadline).bold()
                                                .foregroundStyle(.white).padding(12)
                                                .background(.blue.gradient)
                                                .clipShape(ChatBubbleShape(direction: .right))
                                        }
                                        .frame(height: itemHeight)
                                        .particleEffect360(systemImage: "paperplane.fill", font: .subheadline, status: status[item.title] ?? false, activeTint: Color.blue, inActiveTint: Color.gray, direction: true)
                                        .matchedGeometryEffect(id: item.title, in: namespace)
                                        .visualEffect { content, geometryProxy in
                                            content
                                                .opacity(tempViewTop == item.id ? 1.0 : tempViewTop.isEmpty ? opacity(geometryProxy) : 0.0)
                                                .scaleEffect(tempViewTop == item.id ? 1.0 : scale(geometryProxy, itemID: item.id), anchor: .bottom)
                                                .offset(y: tempViewTop == item.id ? offsetTemp(geometryProxy, top: topPadding) : offset(geometryProxy, top: topPadding))
                                        }
                                        .zIndex(zIndex(item.title))
                                    }
                                    Color.clear.frame(height: 1)
                                        .id("bottom")
                                }
                                .scrollTargetLayout()
                                Color.clear.frame(height: topPadding)
                            }
                            .scrollIndicators(.hidden)
                            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                        })
                    }
                    .frame(width: 160, height: frame * CGFloat(6) + 10.0)
                }.padding(.horizontal, 10)
            }
            VStack {
                HStack(alignment: .top, spacing: 8){
                    if let stories = person.userStories, !stories.isEmpty {
                        ZStack {
                            let seen = seenStory(currentViews: transformLocationMapArray(stories), otherUID: person.user?.id ?? "")
                            StoryRingView(size: 65, active: seen, strokeSize: 2.5)
                            let first = person.user?.fullname.first ?? Character("M")
                            personLetterView(size: 55, letter: String(first))
                            if let image = person.user?.profileImageUrl {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 55, height: 55)
                                    .clipShape(Circle())
                                    .shadow(color: .gray, radius: 2)
                            }
                        }
                        .onTapGesture {
                            upData = stories
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.1)) {
                                newPin = nil
                                showNewPin = false
                                showMenu = false
                            }
                            
                            animateFromPoint = CGPoint(x: 50, y: widthOrHeight(width: false) - (chatUsers.isEmpty ? 200 : 250))

                            animateToPoint = animateFromPoint
                            showingStories = true
                            withAnimation(.easeInOut(duration: 0.05)){
                                showStoryOverlay = true
                                disableTopGesture = true
                            }
                            withAnimation(.easeInOut(duration: 0.45)){
                                circleSize = widthOrHeight(width: false) * 2.0
                                backOpac = 1.0
                                animateFromPoint = CGPoint(x: widthOrHeight(width: true) / 2.0, y: widthOrHeight(width: false) / 2.0)
                            }
                        }
                    } else {
                        ZStack {
                            let first = person.user?.fullname.first ?? Character("M")
                            personLetterView(size: 65, letter: String(first))
                            KFImage(URL(string: person.user?.profileImageUrl ?? ""))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 65, height: 65)
                                .clipShape(Circle())
                                .shadow(color: .gray, radius: 2)
                        }
                        .onTapGesture {
                            if let uid = person.user?.id, chatUsers.isEmpty {
                                messageModel.userMapID = uid
                                close(2)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    messageModel.navigateStoryProfile = true
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 6){
                        Text(person.user?.fullname ?? "------")
                            .font(.title2).bold()
                            .onTapGesture {
                                if let uid = person.user?.id, chatUsers.isEmpty {
                                    messageModel.userMapID = uid
                                    close(2)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        messageModel.navigateStoryProfile = true
                                    }
                                }
                            }
                        if let index = messageModel.chats.firstIndex(where: { $0.user.id == person.user?.id }), let message = messageModel.chats[index].lastM {
                            
                            let isUidOne = (auth.currentUser?.id ?? "") == messageModel.chats[index].convo.uid_one
                            let received = isUidOne && message.uid_one_did_recieve || !isUidOne && !message.uid_one_did_recieve
                            let seen = (!received || message.seen_by_reciever)
                            let textFinal = getMessageTime(date: message.timestamp.dateValue())
                            
                            if received {
                               if seen {
                                   (Text(Image(systemName: "message")).foregroundColor(.blue).font(.subheadline) + Text("  Recieved - ").font(.subheadline) + Text(textFinal).font(.subheadline))
                               } else {
                                   (Text(Image(systemName: "message.fill")).foregroundColor(.blue).font(.subheadline) + Text("  New Chat - ").font(.subheadline).foregroundColor(.blue).bold() + Text(textFinal).font(.subheadline))
                               }
                           } else {
                               if message.seen_by_reciever {
                                   (Text(Image(systemName: "arrowshape.turn.up.forward")).foregroundColor(.red).font(.subheadline) + Text("  Opened - ").font(.subheadline) + Text(textFinal).font(.subheadline))
                               } else {
                                   (Text(Image(systemName: "arrowshape.turn.up.forward.fill")).foregroundColor(.blue).font(.subheadline) + Text("  Delivered - ").font(.subheadline) + Text(textFinal).font(.subheadline))
                               }
                           }
                        }
                        if (person.user?.id ?? "") != (auth.currentUser?.id ?? "") {
                            let timeFmt = formatTime(date: person.user?.lastSeen?.dateValue())
                            HStack(spacing: 3){
                                Text(timeFmt.0)
                                    .font(.subheadline).foregroundStyle(timeFmt.1)
                                let level = person.user?.currentBatteryPercentage
                                Image(systemName: getBatteryImage(battery: level))
                                    .foregroundStyle(getBatteryColor(battery: level))
                                    .font(.subheadline)
                            }
                        } else {
                            HStack(spacing: 3){
                                Text((auth.currentUser?.silent ?? 0) == 4 ? "Ghost Mode" : "Online")
                                    .font(.subheadline).foregroundStyle(.green)
                                let level = currBattery()
                                Image(systemName: getBatteryImage(battery: level))
                                    .foregroundStyle(getBatteryColor(battery: level))
                                    .font(.subheadline)
                            }
                        }
                    }.padding(.leading, 6)
                    Spacer()
                    Menu {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedOffset = 0.0
                            
                            withAnimation(.easeInOut(duration: 0.1)) {
                                vm.mapLocation = nil
                                vm.selectedPin = nil
                                vm.mapGroup = nil
                                showMenu = false
                                
                                self.newPin = person.coordinates
                                self.showNewPin = true
                                
                                vm.mapCameraPosition = .region(MKCoordinateRegion(
                                    center:  person.coordinates,
                                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                            }
                            
                            setPinAddress(coords: person.coordinates)
                        }, label: {
                            Label("Drop Pin", systemImage: "mappin.and.ellipse")
                        })
                    } label: {
                        ZStack {
                            Circle().foregroundStyle(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(.red)
                                .font(.subheadline).bold()
                        }.frame(width: 35, height: 35)
                    }
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeIn(duration: 0.1)){
                            vm.mapLocation = nil
                        }
                        selectedOffset = 0.0
                        
                        if let loc = getUserLocation() {
                            withAnimation(.easeIn(duration: 0.1)){
                                vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                            }
                        } else {
                            vm.setMapPosition(animate: true, isStory: showStories)
                        }
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                            Image(systemName: "xmark")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .font(.subheadline).bold()
                        }.frame(width: 35, height: 35)
                    })
                }.padding(.top, 10)
                Spacer()
                HStack(spacing: 12){
                    if (person.user?.id ?? "") != (auth.currentUser?.id ?? "") {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            if let user = person.user {
                                if let idx = messageModel.chats.firstIndex(where: { $0.user.id == user.id }), let docId = messageModel.chats[idx].convo.id {
                                    
                                    let isUidOne = (auth.currentUser?.id ?? "") == messageModel.chats[idx].convo.uid_one
                                    
                                    if (messageModel.chats[idx].convo.uid_one_sharing_location ?? false && isUidOne) || (messageModel.chats[idx].convo.uid_two_sharing_location ?? false && !isUidOne){
                                        MessageService().shareLocation(docID: docId, shareBool: false, isUidOne: isUidOne)
                                        popRoot.alertReason = "Stopped Sharing Live"
                                        if isUidOne {
                                            messageModel.chats[idx].convo.uid_one_sharing_location = false
                                        } else {
                                            messageModel.chats[idx].convo.uid_two_sharing_location = false
                                        }
                                    } else {
                                        MessageService().shareLocation(docID: docId, shareBool: true, isUidOne: isUidOne)
                                        popRoot.alertReason = "Live Location Shared!"
                                        if isUidOne {
                                            messageModel.chats[idx].convo.uid_one_sharing_location = true
                                        } else {
                                            messageModel.chats[idx].convo.uid_two_sharing_location = true
                                        }
                                    }
                                    popRoot.alertImage = "checkmark.seal"
                                } else {
                                    popRoot.alertReason = "Start chatting to Share Live"
                                    popRoot.alertImage = "person.fill.badge.plus"
                                }
                            } else {
                                popRoot.alertReason = "Error fetching user"
                                popRoot.alertImage = "exclamationmark.triangle.fill"
                            }
                            withAnimation(.easeInOut(duration: 0.15)){
                                popRoot.showAlert = true
                            }
                        }, label: {
                            if let user = person.user {
                                if let idx = messageModel.chats.firstIndex(where: { $0.user.id == user.id }) {
                                    
                                    let isUidOne = (auth.currentUser?.id ?? "") == messageModel.chats[idx].convo.uid_one
                                    
                                    if (messageModel.chats[idx].convo.uid_one_sharing_location ?? false && isUidOne) || (messageModel.chats[idx].convo.uid_two_sharing_location ?? false && !isUidOne){
                                        basicShareLabel(text: "Stop Live", color: Color.red)
                                    } else {
                                        basicShareLabel(text: "Share Live", color: Color.green)
                                    }
                                } else {
                                    basicShareLabel(text: "Share Live", color: Color.green)
                                }
                            } else {
                                basicShareLabel(text: "Share Live", color: Color.green)
                            }
                        })
                    } else {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            var name = "@\(person.user?.username ?? "")'s Location"
                            if let fullname = person.user?.fullname {
                                let words = fullname.split(separator: " ")
                                
                                if let firstWord = words.first {
                                    name = "\(firstWord)'s Location"
                                }
                            }

                            sendLink = "\(person.coordinates.latitude),\(person.coordinates.longitude),\(name)"
                            showForward = true
                        }, label: {
                            basicShareLabel(text: "Share Location", color: Color.green)
                        })
                    }
                    Button(action: {
                        openMaps(lat: person.coordinates.latitude, long: person.coordinates.longitude, name: person.user?.fullname ?? "Current Location")
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label: {
                        HStack(spacing: 5){
                            Image(systemName: "car.fill")
                                .font(.headline)

                            if let timeStr = person.timeDistance {
                                Text(timeStr.isEmpty ? "-- min" : timeStr).font(.headline)
                            } else {
                                ProgressView()
                            }
                        }
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .frame(width: 110, height: 36)
                        .background(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                        .clipShape(Capsule())
                    })
                    .onAppear(perform: {
                        if person.timeDistance == nil {
                            if let start = getUserLocation() {
                                calculateDrivingTime(from: start, to: person.coordinates) { time in
                                    if let timeStr = time, !timeStr.isEmpty {
                                        vm.mapLocation?.timeDistance = timeStr
                                        if let idx = vm.locations.firstIndex(where: { $0.user?.id == person.user?.id }) {
                                            vm.locations[idx].timeDistance = timeStr
                                            vm.mapLocation?.timeDistance = timeStr
                                        }
                                    }
                                }
                            }
                        }
                    })
                    if (person.user?.id ?? "") != (auth.currentUser?.id ?? "") {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if let user = person.user {
                                if let index = messageModel.currentChat, messageModel.chats[index].user.id == user.id && !chatUsers.isEmpty {
                                    close(3)
                                } else if chatUsers.isEmpty {
                                    close(2)
                                    messageModel.userMap = user
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        messageModel.navigateUserMap = true
                                    }
                                } else {
                                    close(9)
                                    messageModel.userMap = user
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                        messageModel.navigateUserMap = true
                                    }
                                }
                                vm.mapLocation = nil
                            }
                        }, label: {
                            Image(systemName: "message.fill")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .font(.title2).frame(width: 70, height: 36)
                                .background(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                                .clipShape(Capsule())
                        })
                    } else {
                        Button(action: {
                            if showPlacesSheet || showTagSheet || showSingleSheet || showMultiSheet {
                                showPlacesSheet = false
                                showTagSheet = false
                                showSingleSheet = false
                                showMultiSheet = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showSettings.toggle()
                                }
                            } else {
                                showSettings.toggle()
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label: {
                            Image(systemName: "gear")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .font(.title2).frame(width: 70, height: 36)
                                .background(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                                .clipShape(Capsule())
                        })
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 140)
            .background(.ultraThinMaterial)
            .cornerRadius(30, corners: [.topLeft, .topRight])
            .shadow(color: .gray, radius: 4)
        }
        .transition(.move(edge: .bottom))
        .offset(y: selectedOffset)
        .onAppear(perform: {
            if let uid = person.user?.id, person.triedToGetStories == false {
                if (person.userStories ?? []).isEmpty {
                    vm.mapLocation?.triedToGetStories = true
                    if let idx = vm.locations.firstIndex(where: { $0.user?.id == uid }) {
                        vm.locations[idx].triedToGetStories = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                        if let idx = vm.locations.firstIndex(where: { $0.user?.id == uid }) {
                            vm.locations[idx].triedToGetStories = false
                        }
                    }
                    
                    if let userStories = profileModel.users.first(where: { $0.user.id == uid })?.stories, !userStories.isEmpty {
                        var new = [LocationMap]()
                        userStories.forEach { element in
                            var newElement = LocationMap(coordinates: person.coordinates, story: element)
                            if let lat = element.lat, let long = element.long {
                                newElement.coordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
                            }
                            new.append(newElement)
                        }
                        vm.mapLocation?.userStories = new
                        if let idx = vm.locations.firstIndex(where: { $0.user?.id == uid }) {
                            vm.locations[idx].userStories = new
                        }
                    } else if let user = person.user {
                        profileModel.fetchStoriesUser(user: user) { stories in
                            if !stories.isEmpty {
                                var new = [LocationMap]()
                                stories.forEach { element in
                                    var newElement = LocationMap(coordinates: person.coordinates, story: element)
                                    if let lat = element.lat, let long = element.long {
                                        newElement.coordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
                                    }
                                    new.append(newElement)
                                }
                                if (vm.mapLocation?.user?.id ?? "") == uid {
                                    vm.mapLocation?.userStories = new
                                }
                                vm.mapLocation?.userStories = new
                                if let idx = vm.locations.firstIndex(where: { $0.user?.id == uid }) {
                                    vm.locations[idx].userStories = new
                                }
                            }
                        }
                    }
                } else if let uIndex = profileModel.users.firstIndex(where: { $0.user.id == uid }) {
                    
                    let date = profileModel.users[uIndex].lastUpdatedStories
                    
                    if date == nil || (date != nil && isDateAtLeastOneMinuteOld(date: date ?? Date())) {
                        profileModel.fetchStoriesUser(user: profileModel.users[uIndex].user) { stories in
                            if !stories.isEmpty {
                                var new = [LocationMap]()
                                stories.forEach { element in
                                    var newElement = LocationMap(coordinates: person.coordinates, story: element)
                                    if let lat = element.lat, let long = element.long {
                                        newElement.coordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
                                    }
                                    new.append(newElement)
                                }
                                if (vm.mapLocation?.user?.id ?? "") == uid {
                                    vm.mapLocation?.userStories = new
                                }
                                vm.mapLocation?.userStories = new
                                if let idx = vm.locations.firstIndex(where: { $0.user?.id == uid }) {
                                    vm.locations[idx].userStories = new
                                }
                            }
                        }
                    }
                }
            }
        })
        .gesture(DragGesture()
            .onChanged({ value in
                if value.translation.height >= 0.0 {
                    selectedOffset = value.translation.height
                }
            })
            .onEnded({ value in
                if value.translation.height > 80.0 || value.velocity.height > 300.0 {
                    withAnimation(.easeIn(duration: 0.1)){
                        vm.mapLocation = nil
                    }
                    if let loc = getUserLocation() {
                        withAnimation(.easeIn(duration: 0.1)){
                            vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                        }
                    } else {
                        vm.setMapPosition(animate: true, isStory: showStories)
                    }
                    selectedOffset = 0.0
                } else {
                    withAnimation(.easeInOut(duration: 0.2)){
                        selectedOffset = 0.0
                    }
                }
            })
        )
    }
    func seenStory(currentViews: [(String, [String])], otherUID: String) -> Bool {
        if let uid = auth.currentUser?.id {
            if otherUID == uid {
                return false
            }
            for i in 0..<currentViews.count {
                if !messageModel.viewedStories.contains(where: { $0.0 == currentViews[i].0 }) && !currentViews[i].1.contains(where: { $0.contains(uid) }) {
                    return true
                }
            }
        }
        return false
    }
    func transformLocationMapArray(_ locationMaps: [LocationMap]) -> [(String, [String])] {
        return locationMaps.compactMap { locationMap in
            guard let story = locationMap.story,
                  let storyId = story.id,
                  let storyViews = story.views else {
                return nil
            }
            return (storyId, storyViews)
        }
    }
    @ViewBuilder
    func basicShareLabel(text: String, color: Color) -> some View {
        HStack(spacing: 5){
            Spacer()
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(.white)
                .font(.headline)
            Text(text)
                .foregroundStyle(.white)
                .font(.headline).minimumScaleFactor(0.7).lineLimit(1)
            Spacer()
        }
        .frame(height: 36)
        .background(color)
        .clipShape(Capsule())
    }
    func formatTime(date: Date?) -> (String, Color) {
        let defaultColor: Color = Color.gray
        guard let lastSeenDate = date else {
            return ("AFK", defaultColor)
        }
        
        let currentDate = Date()
        let timeInterval = currentDate.timeIntervalSince(lastSeenDate)
        
        let oneMinute: TimeInterval = 60
        let oneHour: TimeInterval = 3600
        let oneDay: TimeInterval = 86400
        let oneMonth: TimeInterval = 2592000
        
        if timeInterval < oneMinute {
            return ("Seen Now", .green)
        } else if timeInterval < oneHour {
            let minutes = Int(timeInterval / oneMinute)
            return ("Seen \(minutes)m Ago", .green)
        } else if timeInterval < oneDay {
            let hours = Int(timeInterval / oneHour)
            return ("Last Seen \(hours)h Ago", defaultColor)
        } else if timeInterval < oneMonth {
            let days = Int(timeInterval / oneDay)
            return ("Last Seen \(days)d Ago", defaultColor)
        } else {
            return ("AFK", defaultColor)
        }
    }
    func getBatteryImage(battery: Double?) -> String {
        if let level = battery {
            if level < 0.05 {
                return "battery.0percent"
            } else if level < 0.3 {
                return "battery.25percent"
            } else if level < 0.6 {
                return "battery.50percent"
            } else if level < 0.8 {
                return "battery.75percent"
            } else {
                return "battery.100percent"
            }
        } else {
            return "battery.75percent"
        }
    }
    func getBatteryColor(battery: Double?) -> Color {
        if let level = battery {
            if level < 0.2 {
                return .red
            } else if level < 0.55 {
                return .yellow
            } else {
                return .green
            }
        } else {
            return .green
        }
    }
    nonisolated func zIndex(_ itemTitle: String) -> Double {
        let itemstemp: [ItemX] = [
            ItemX(title: "On my way!"),
            ItemX(title: "Leaving now!"),
            ItemX(title: "Send the address."),
            ItemX(title: "Just left."),
            ItemX(title: "Driving."),
        ]
        if let index = itemstemp.firstIndex(where: { $0.title == itemTitle }) {
            return Double(5) - Double(index)
        }
        return 0
    }
    nonisolated func offset(_ proxy: GeometryProxy, top: CGFloat) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let progress = minY / 40.0
        let maxOffset = CGFloat(1) * 8
        let offset = max(min(progress * 8, maxOffset), 0)
 
        return minY < 0 ? top : -minY + offset + top
    }
    nonisolated func offsetTemp(_ proxy: GeometryProxy, top: CGFloat) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        return -minY + top
    }
    nonisolated func scale(_ proxy: GeometryProxy, itemID: String) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let progress = minY / 40.0
        let maxScale = CGFloat(1) * 0.08
        let scale = max(min(progress * 0.08, maxScale), 0)
    
        return 1 - scale
    }
    nonisolated func opacity(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let progress = minY / 40.0
        let opacityForItem = 1 / CGFloat(1)
        
        let maxOpacity = CGFloat(opacityForItem) * CGFloat(1)
        let opacity = max(min(progress * opacityForItem, maxOpacity), 0)
        
        return progress < CGFloat(1) ? 1 - opacity : 0
    }
    @ViewBuilder
    func vpnAlert() -> some View {
        VStack(spacing: 10){
            Text("Turn Off VPN")
                .font(.headline).bold()
            Text("Disable VPN to allow Hustles to find Places near you.")
                .font(.caption).multilineTextAlignment(.center)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)){
                    showVPNError = false
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(.gray).frame(height: 32)
                    Text("Cancel").foregroundStyle(.white).bold().font(.headline)
                }.padding(.horizontal)
            }).padding(.top, 10)
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).frame(height: 32)
                    Text("Open Settings").foregroundStyle(.white).bold().font(.headline)
                }.padding(.horizontal)
            })
        }
        .padding(8)
        .overlay(content: {
            RoundedRectangle(cornerRadius: 15).stroke(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255), lineWidth: 1.0)
        })
        .padding(2)
        .background(colorScheme == .dark ? .black : .white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .frame(maxWidth: widthOrHeight(width: true) * 0.7)
        .shadow(color: .gray, radius: 4)
        .transition(.move(edge: .bottom).combined(with: .blurReplace))
    }
    @ViewBuilder
    func editPinName() -> some View {
        VStack(spacing: 10){
            Text("Edit Pin Name")
                .font(.headline).bold()
            
            TextField("New Name", text: $newPinText)
                .font(.headline).bold()
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .padding(.horizontal, 13).padding(.vertical, 8)
                .lineLimit(1)
                .tint(.blue)
                .focused($focusedField, equals: .one)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Button(action: {
                focusedField = .two
                withAnimation(.easeInOut(duration: 0.15)){
                    showChangeName = false
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(.gray).frame(height: 32)
                    Text("Cancel").foregroundStyle(.white).bold().font(.headline)
                }.padding(.horizontal)
            }).padding(.top, 20)
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                focusedField = .two
                withAnimation(.easeInOut(duration: 0.15)){
                    showChangeName = false
                }
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).frame(height: 32)
                    Text("Save").foregroundStyle(.white).bold().font(.headline)
                }.padding(.horizontal)
            })
        }
        .padding(8)
        .overlay(content: {
            RoundedRectangle(cornerRadius: 15).stroke(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255), lineWidth: 1.0)
        })
        .padding(2)
        .background(colorScheme == .dark ? .black : .white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .frame(maxWidth: widthOrHeight(width: true) * 0.7)
        .shadow(color: .gray, radius: 4)
        .transition(.move(edge: .bottom).combined(with: .blurReplace))
    }
    @ViewBuilder
    func newGroupMenu() -> some View {
        VStack(spacing: 10){
            if selectedUsers.isEmpty {
                Text("Select Chat Members")
                    .font(.headline).bold()
            } else {
                Text("Start Chatting (\(selectedUsers.count))")
                    .font(.headline).bold()
            }
            
            let height = min(max(100, newChatUsers.count * 65), 390)
            
            ScrollView {
                VStack(spacing: 8){
                    ForEach(newChatUsers) { user in
                        singleUser(user: user)
                        if (user.id ?? "") != (newChatUsers.last?.id ?? "") {
                            Divider()
                        }
                    }
                }
                .padding(8)
                .background(.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(1)
            }
            .padding(.horizontal, 10)
            .scrollIndicators(.hidden)
            .frame(height: CGFloat(height))

            Button(action: {
                newChatUsers = []
                selectedUsers = []
                withAnimation(.easeInOut(duration: 0.1)){
                    showNewChat = false
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(.gray).frame(height: 32)
                    Text("Cancel").foregroundStyle(.white).bold().font(.headline)
                }.padding(.horizontal)
            })
            Button(action: {
                if selectedUsers.isEmpty {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    
                    withAnimation(.easeInOut(duration: 0.1)){
                        showNewChat = false
                    }
                    
                    let newGroupID = UUID().uuidString
                    let all_uids = selectedUsers.compactMap({ $0.id })
                    
                    let prefix = String((auth.currentUser?.id ?? "").prefix(6))
                    let tempMessage = GroupMessage(id: "\(prefix)\(UUID().uuidString)", seen: false, text: "You created a group", normal: true, timestamp: Timestamp())
                    
                    let newGroup = GroupConvo(id: newGroupID, groupName: nil, allUsersUID: all_uids, timestamp: Timestamp(), lastM: tempMessage, messages: [tempMessage])
                    
                    DispatchQueue.main.async {
                        gcModel.chats.append(newGroup)
                        
                        GroupChatService().makeGC(name: nil, allU: all_uids, groupChatID: newGroupID, fullname: auth.currentUser?.username ?? "")
                        
                        gcModel.newMapGroupId = newGroupID
                    }
                    
                    if chatUsers.isEmpty {
                        close(2)
                    } else {
                        close(9)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        gcModel.navigateMapGroup = true
                    }
                    newChatUsers = []
                    selectedUsers = []
                }
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).frame(height: 32)
                    Text("Go").foregroundStyle(.white).bold().font(.headline)
                }.padding(.horizontal)
            })
        }
        .padding(8)
        .overlay(content: {
            RoundedRectangle(cornerRadius: 15).stroke(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255), lineWidth: 1.0)
        })
        .padding(2)
        .background(colorScheme == .dark ? .black : .white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .frame(maxWidth: widthOrHeight(width: true) * 0.7)
        .shadow(color: .gray, radius: 4)
        .transition(.move(edge: .bottom).combined(with: .blurReplace))
    }
    @ViewBuilder
    func singleUser(user: User) -> some View {
        HStack(spacing: 10){
            ZStack {
                let first = user.fullname.first ?? Character("M")
                personLetterView(size: 40, letter: String(first))
                KFImage(URL(string: user.profileImageUrl ?? ""))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 3){
                Text(user.fullname).font(.subheadline).bold()
                    .lineLimit(1).truncationMode(.tail)
                Text("@\(user.username)").foregroundStyle(.gray).font(.caption)
                    .lineLimit(1).truncationMode(.tail)
            }
            Spacer()
            if selectedUsers.contains(where: { $0.id == user.id }) {
                Circle().foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).frame(width: 19, height: 19)
                    .overlay {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white).font(.caption).bold()
                    }
            } else {
                Circle().stroke(.gray, lineWidth: 1.0).frame(width: 19, height: 19)
            }
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if selectedUsers.contains(where: { $0.id == user.id }) {
                selectedUsers.removeAll(where: { $0.id == user.id })
            } else {
                selectedUsers.append(user)
            }
        }
    }
    @ViewBuilder
    func enableLocation() -> some View {
        VStack(spacing: 10){
            Text("Enable Location Access")
                .font(.headline).bold()
            Text("Hustles needs to access your location to do things like calculating driving distance or displaying your location on the map").font(.caption2).foregroundStyle(.gray).multilineTextAlignment(.center)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.1)){
                    showEnableLocationAccess = false
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(.gray).frame(height: 32)
                    Text("Cancel").foregroundStyle(.white).bold().font(.headline)
                }.padding(.horizontal)
            }).padding(.top, 20)
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                GlobeLocationManager().requestLocation() { place in
                    if !place.0.isEmpty && !place.1.isEmpty {
                        globe.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                        addCurrentUser()
                        popRoot.alertReason = "We found you!"
                        popRoot.alertImage = "checkmark.seal"
                        withAnimation(.easeInOut(duration: 0.15)){
                            popRoot.showAlert = true
                            showEnableLocationAccess = false
                        }
                    } else {
                        popRoot.alertReason = "Could not locate you"
                        popRoot.alertImage = "exclamationmark.triangle.fill"
                        withAnimation(.easeInOut(duration: 0.15)){
                            popRoot.showAlert = true
                            showEnableLocationAccess = false
                        }
                    }
                }
                withAnimation(.easeInOut(duration: 0.15)){
                    showEnableLocationAccess = false
                }
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).frame(height: 32)
                    Text("Retry").foregroundStyle(.white).bold().font(.headline)
                }.padding(.horizontal)
            })
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).frame(height: 32)
                    Text("Enable").foregroundStyle(.white).bold().font(.headline)
                }.padding(.horizontal)
            })
        }
        .padding(8)
        .overlay(content: {
            RoundedRectangle(cornerRadius: 15).stroke(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255), lineWidth: 1.0)
        })
        .padding(2)
        .background(colorScheme == .dark ? .black : .white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .frame(maxWidth: widthOrHeight(width: true) * 0.7)
        .shadow(color: .gray, radius: 4)
        .transition(.move(edge: .bottom).combined(with: .blurReplace))
    }
    func haveSameElements(array1: [String], array2: [String]) -> Bool {
        return array1.sorted() == array2.sorted()
    }
    @ViewBuilder
    func groupView(item: groupLocation) -> some View {
        VStack {
            Spacer()
            let name = item.allLocs.first?.user?.username ?? "----"
            let fullname = "@\(name) & \(item.allLocs.count - 1) More"
            Text(fullname).font(.title3).bold()
            HStack(spacing: 12){
                Button(action: {
                    var temp = item.allLocs.compactMap({ $0.user })
                    temp.removeAll(where: { $0.id == (auth.currentUser?.id ?? "") })
                    let ids = temp.compactMap({ $0.id })

                    if !ids.isEmpty {
                        if haveSameElements(array1: chatUsers.compactMap({ $0.id }), array2: ids) {
                            close(3)
                        } else if let gcID = gcModel.chats.first(where: { haveSameElements(array1: ids, array2: $0.allUsersUID ) })?.id {
                            close(9)
                            gcModel.newMapGroupId = gcID
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                gcModel.navigateMapGroup = true
                            }
                        } else {
                            newChatUsers = temp
                            selectedUsers = temp
                            withAnimation(.easeInOut(duration: 0.1)){
                                showNewChat = true
                            }
                        }
                    }
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }, label: {
                    HStack(spacing: 5){
                        Spacer()
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                            .font(.headline)
                        Text("Group Chat")
                            .foregroundStyle(.white)
                            .font(.headline)
                        Spacer()
                    }
                    .frame(height: 36)
                    .background(.green)
                    .clipShape(Capsule())
                })
                Button(action: {
                    openMaps(lat: item.coordinates.latitude, long: item.coordinates.longitude, name: fullname)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    HStack(spacing: 5){
                        Image(systemName: "car.fill")

                        if !newPinDriveTime.isEmpty {
                            Text(newPinDriveTime)
                        } else {
                            ProgressView()
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 110, height: 36)
                    .background(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                    .clipShape(Capsule())
                })
                .onAppear(perform: {
                    if let start = getUserLocation() {
                        newPinDriveTime = ""
                        calculateDrivingTime(from: start, to: item.coordinates) { time in
                            self.newPinDriveTime = time ?? "-- min"
                        }
                    }
                })
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeIn(duration: 0.1)){
                        vm.mapGroup = nil
                    }
                    if let loc = getUserLocation() {
                        withAnimation(.easeIn(duration: 0.1)){
                            vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                        }
                    } else {
                        vm.setMapPosition(animate: true, isStory: showStories)
                    }
                    selectedOffset = 0.0
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .font(.subheadline).bold()
                        .frame(width: 30, height: 30)
                        .background(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                        .clipShape(Circle())
                })
            }.padding(.bottom, 10)
        }
        .padding(.horizontal, 10)
        .frame(height: 115)
        .background(.ultraThinMaterial)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .gray, radius: 4)
        .overlay(content: {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16){
                    Color.clear.frame(width: 1)
                    
                    let allU = item.allLocs.compactMap({ $0.user })
                    
                    ForEach(allU) { user in
                        Button {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            tapCount -= 1
                            withAnimation(.easeInOut(duration: 0.1)) {
                                showPullDownMenu = false
                                newPin = nil
                                showNewPin = false
                                showMenu = false
                            }
                            sentMessage = ""
                            itemsN = [
                                ItemX(title: "On my way!"),
                                ItemX(title: "Leaving now!"),
                                ItemX(title: "Send the address."),
                                ItemX(title: "Just left."),
                                ItemX(title: "Driving."),
                            ]
                            status = ["On my way!" : false, "Leaving now!" : false, "Send the address." : false, "Just left." : false, "Driving." : false]
                            if let first = item.allLocs.first(where: { $0.user?.id == user.id }) {
                                vm.showNextLocation(location: first, lat: 0.002, long: 0.002)
                            }
                        } label: {
                            VStack(spacing: 15){
                                ZStack {
                                    let first = user.fullname.first ?? Character("M")
                                    personLetterView(size: 55, letter: String(first))
                                    KFImage(URL(string: user.profileImageUrl ?? ""))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 55, height: 55)
                                        .clipShape(Circle())
                                        .shadow(color: .gray, radius: 2)
                                }
                                Text("@\(user.username)")
                                    .font(.caption2).fontWeight(.semibold).lineLimit(1).truncationMode(.tail).frame(maxWidth: 60)
                            }
                        }
                    }
                    Color.clear.frame(width: 1)
                }
            }.offset(y: -75).scrollIndicators(.hidden)
        })
        .transition(.move(edge: .bottom))
        .offset(y: selectedOffset)
        .gesture(DragGesture()
            .onChanged({ value in
                if value.translation.height >= 0.0 {
                    selectedOffset = value.translation.height
                }
            })
            .onEnded({ value in
                if value.translation.height > 80.0 || value.velocity.height > 300.0 {
                    withAnimation(.easeIn(duration: 0.1)){
                        vm.mapGroup = nil
                    }
                    if let loc = getUserLocation() {
                        withAnimation(.easeIn(duration: 0.1)){
                            vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                        }
                    } else {
                        vm.setMapPosition(animate: true, isStory: showStories)
                    }
                    selectedOffset = 0.0
                } else {
                    withAnimation(.easeInOut(duration: 0.2)){
                        selectedOffset = 0.0
                    }
                }
            })
        )
    }
    private var mapOptions: some View {
        VStack(spacing: 0){
            Spacer()
            if newPin != nil && showNewPin {
                pinView(item: nil)
            } else if let pin = vm.selectedPin {
                pinView(item: pin)
            } else if let person = vm.mapLocation {
                personView(person: person)
            } else if let group = vm.mapGroup {
                groupView(item: group)
            } else {
                ZStack {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if showPlaces || showMemories {
                            vm.setPlaceMemPosition(animate: true, isMemory: showMemories)
                        } else if showStories {
                            vm.setMapPosition(animate: true, isStory: true)
                        } else if let loc = getUserLocation() {
                            withAnimation(.easeIn(duration: 0.1)){
                                vm.mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                            }
                        } else {
                            vm.setMapPosition(animate: true, isStory: false)
                        }
                        withAnimation(.easeInOut(duration: 0.1)) {
                            showMenu = false
                        }
                    }, label: {
                        Image(systemName: "paperplane.fill")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(10)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(color: .gray, radius: 6)
                    }).transition(.scale.combined(with: .opacity))
                    if showPlaces && !showPlacesSheet && !showTagSheet {
                        HStack {
                            Spacer()
                            let has = vm.tags.contains(vm.selectedTag)
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if has {
                                    showPlacesSheet = true
                                } else {
                                    withAnimation(.easeInOut(duration: 0.1)){
                                        vm.selectedTag = "Restaurants"
                                    }
                                }
                            }, label: {
                                HStack(spacing: 4){
                                    if !has {
                                        Image(systemName: "xmark").fontWeight(.medium)
                                    }
                                    Text(vm.selectedTag).bold()
                                }.foregroundStyle(.white).font(.caption)
                            })
                            .padding(10)
                            .background(.blue.gradient)
                            .clipShape(Capsule())
                        }.transition(.scale.combined(with: .opacity)).padding(.trailing, 10)
                    }
                }.padding(.bottom, 10)
            }
            Divider().overlay(.gray)
            if showStories {
                VStack(spacing: 0){
                    HStack(spacing: 10){
                        Image(systemName: "book.pages.fill")
                            .foregroundStyle(.white).font(.title3)
                            .padding(12)
                            .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 5){
                            Text("Stories").font(.title3).bold()
                            Text("See your friends' stories everywhere.")
                                .font(.caption).opacity(0.9)
                        }
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            centerStoryID = ""
                            withAnimation(.easeInOut(duration: 0.1)){
                                showStories = false
                            }
                            vm.setMapPosition(animate: true, isStory: false)
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.subheadline).bold()
                                .frame(width: 30, height: 30)
                                .background(.gray.opacity(0.3))
                                .clipShape(Circle())
                        })
                    }
                    .frame(height: 55)
                    .padding(.top, 6).padding(.horizontal)
                    let bottomInset = chatUsers.isEmpty ? bottom_Inset() : 5.0
                    Color.clear.frame(height: bottomInset == 0.0 ? 40 : bottomInset)
                }
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
            } else if showMemories {
                VStack(spacing: 0){
                    HStack(spacing: 10){
                        Image(systemName: "wand.and.stars.inverse")
                            .foregroundStyle(.white).font(.title2)
                            .padding(12)
                            .background(.orange)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 5){
                            Text("Memories").font(.title3).bold()
                            Text("See your favorite memories.")
                                .font(.caption).opacity(0.9)
                        }
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            centerMemoryID = ""
                            withAnimation(.easeInOut(duration: 0.1)){
                                showMemories = false
                            }
                            vm.setMapPosition(animate: true, isStory: false)
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.subheadline).bold()
                                .frame(width: 30, height: 30)
                                .background(.gray.opacity(0.3))
                                .clipShape(Circle())
                        })
                    }
                    .frame(height: 55)
                    .padding(.top, 6).padding(.horizontal)
                    let bottomInset = chatUsers.isEmpty ? bottom_Inset() : 5.0
                    Color.clear.frame(height: bottomInset == 0.0 ? 40 : bottomInset)
                }
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
            } else {
                VStack(spacing: 0){
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 6){
                            Color.clear.frame(width: 5)
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showAIPlace = true
                            } label: {
                                ZStack {
                                    Capsule()
                                        .frame(width: 37, height: 50)
                                        .foregroundStyle(.gray).opacity(0.3)
                                        .overlay {
                                            Capsule()
                                                .stroke(.blue, lineWidth: 0.5)
                                                .frame(width: 37, height: 50)
                                        }
                                    LottieView(loopMode: .loop, name: "finite")
                                        .scaleEffect(0.054)
                                        .frame(width: 22, height: 10).rotationEffect(.degrees(90.0))
                                }
                            }
                            if chatUsers.isEmpty {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        newPin = nil
                                        showNewPin = false
                                        showMenu = false
                                    }
                                    if showPlaces {
                                        showPlacesSheet = true
                                    } else {
                                        withAnimation(.easeInOut(duration: 0.15)){
                                            showSearchUsers = true
                                        }
                                        focusField = .one
                                    }
                                }, label: {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                        .font(.title2)
                                        .frame(width: 50, height: 50)
                                        .background(.gray.opacity(0.3))
                                        .clipShape(Circle())
                                })
                            }
                            ForEach(chatUsers) { user in
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    sentMessage = ""
                                    itemsN = [
                                        ItemX(title: "On my way!"),
                                        ItemX(title: "Leaving now!"),
                                        ItemX(title: "Send the address."),
                                        ItemX(title: "Just left."),
                                        ItemX(title: "Driving."),
                                    ]
                                    status = ["On my way!" : false, "Leaving now!" : false, "Send the address." : false, "Just left." : false, "Driving." : false]
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        showPullDownMenu = false
                                        newPin = nil
                                        showNewPin = false
                                        showMenu = false
                                    }
                                    if let place = vm.locations.first(where: { $0.user?.id == user.id }) {
                                        vm.showNextLocation(location: place, lat: 0.002, long: 0.002)
                                    } else {
                                        userForSheet = user
                                        userForSheetUsername = user.username
                                        showUserSheet = true
                                    }
                                }, label: {
                                    ZStack {
                                        Circle()
                                            .fill(.gray.gradient)
                                            .frame(width: 50, height: 50)
                                            .overlay {
                                                if let char = user.fullname.first {
                                                    Text(String(char).uppercased())
                                                        .font(.title2).fontWeight(.heavy)
                                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                                } else {
                                                    Image(systemName: "person.fill")
                                                        .font(.title3)
                                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                                }
                                            }
                                        if let image = user.profileImageUrl {
                                            KFImage(URL(string: image))
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                                .shadow(color: .gray, radius: 1)
                                        }
                                    }
                                })
                            }
                            Button(action: {
                                pinsButClicked(isHeader: false)
                            }, label: {
                                HStack(spacing: 8){
                                    Image(systemName: "mappin")
                                        .foregroundStyle(.white)
                                        .padding(10)
                                        .background(.red)
                                        .clipShape(Circle())
                                        .overlay(alignment: .bottomTrailing){
                                            if showPins {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(.white)
                                                    .font(.caption2)
                                                    .padding(3)
                                                    .background(.green)
                                                    .clipShape(Circle())
                                                    .transition(.scale)
                                            }
                                        }
                                    
                                    Text("Pins").font(.title3).fontWeight(.semibold)
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                }
                                .padding(.horizontal, 8)
                                .frame(height: 50)
                                .background(.gray.opacity(0.3))
                                .clipShape(Capsule())
                            })
                            Button(action: {
                               storiesButClicked(isHeader: false)
                            }, label: {
                                HStack(spacing: 8){
                                    Image(systemName: "book.pages.fill")
                                        .foregroundStyle(.white)
                                        .padding(10)
                                        .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                                        .clipShape(Circle())
                                    
                                    Text("Stories").font(.title3).fontWeight(.semibold)
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                }
                                .padding(.horizontal, 8)
                                .frame(height: 50)
                                .background(.gray.opacity(0.3))
                                .clipShape(Capsule())
                            })
                            Button(action: {
                                placesButClicked(isHeader: false)
                            }, label: {
                                HStack(spacing: 8){
                                    Image(systemName: "fork.knife")
                                        .foregroundStyle(.white)
                                        .padding(10)
                                        .background(.green)
                                        .clipShape(Circle())
                                        .overlay(alignment: .bottomTrailing){
                                            if showPlaces {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(.black)
                                                    .font(.caption2)
                                                    .padding(3)
                                                    .background(.white)
                                                    .clipShape(Circle())
                                                    .transition(.scale)
                                            }
                                        }
                                    
                                    Text("Places").font(.title3).fontWeight(.semibold)
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                }
                                .padding(.horizontal, 8)
                                .frame(height: 50)
                                .background(.gray.opacity(0.3))
                                .clipShape(Capsule())
                            })
                            Button(action: {
                                memoriesButClicked(isHeader: false)
                            }, label: {
                                HStack(spacing: 8){
                                    Image(systemName: "wand.and.stars.inverse")
                                        .foregroundStyle(.white).bold()
                                        .scaleEffect(1.1)
                                        .padding(10)
                                        .background(.orange)
                                        .clipShape(Circle())
                                    
                                    Text("Memories").font(.title3).fontWeight(.semibold)
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                }
                                .padding(.horizontal, 8)
                                .frame(height: 50)
                                .background(.gray.opacity(0.3))
                                .clipShape(Capsule())
                            })
                            if chatUsers.isEmpty {
                                ForEach(vm.locations) { loc in
                                    if let user = loc.user {
                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            sentMessage = ""
                                            itemsN = [
                                                ItemX(title: "On my way!"),
                                                ItemX(title: "Leaving now!"),
                                                ItemX(title: "Send the address."),
                                                ItemX(title: "Just left."),
                                                ItemX(title: "Driving."),
                                            ]
                                            status = ["On my way!" : false, "Leaving now!" : false, "Send the address." : false, "Just left." : false, "Driving." : false]
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                showPullDownMenu = false
                                                newPin = nil
                                                showNewPin = false
                                                showMenu = false
                                            }
                                            vm.showNextLocation(location: loc, lat: 0.002, long: 0.002)
                                        }, label: {
                                            ZStack {
                                                let first = user.fullname.first ?? Character("M")
                                                personLetterView(size: 50, letter: String(first))
                                                KFImage(URL(string: user.profileImageUrl ?? ""))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(Circle())
                                                    .shadow(color: .gray, radius: 1)
                                            }
                                        })
                                    }
                                }
                            }
                            Color.clear.frame(width: 10)
                        }
                    }
                    .scrollIndicators(.hidden)
                    .frame(height: 55)
                    .padding(.top, 6)
                    let bottomInset = chatUsers.isEmpty ? bottom_Inset() : 5.0
                    Color.clear.frame(height: bottomInset == 0.0 ? 40 : bottomInset)
                }
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
            }
        }
    }
    private var sliderLayer: some View {
        HStack {
            Spacer()
            ZStack(alignment: .trailing){
                if dragEnded || isDragging {
                    Rectangle().foregroundStyle(.white).frame(width: 3).padding(.trailing, 5) .shadow(color: .gray, radius: 2)
                }
                ZStack(alignment: .topTrailing){
                    Rectangle().foregroundStyle(.gray).opacity(0.001).frame(width: 25)
               
                    if dragEnded || isDragging {
                        Image(systemName: scaleImage)
                            .foregroundStyle(color)
                            .frame(width: dragEnded && isDragging ? 90 : dragEnded ? 30 : 0, height: 26, alignment: .leading)
                            .padding(.leading, 5)
                            .background(.white)
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 5))
                            .shadow(color: .gray, radius: 5)
                            .padding(.trailing, 8)
                            .transition(.move(edge: .trailing).combined(with: .scale))
                            .offset(y: offset)
                    }
                }
                .gesture(DragGesture()
                    .onChanged({ value in
                        if !isDragging {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            offset = value.startLocation.y
                        }
                        if showMenu {
                            withAnimation(.easeIn(duration: 0.2)){
                                self.showMenu = false
                            }
                        }
                        if showPullDownMenu {
                            withAnimation(.easeInOut(duration: 0.15)){
                                showPullDownMenu = false
                            }
                        }
                        
                        withAnimation(.easeInOut(duration: 0.2)){
                            dragEnded = true
                            isDragging = true
                        }
                        
                        if value.location.y >= 0.0 && value.location.y <= ((widthOrHeight(width: false) * 0.6) - 26.0) {
                            offset = value.location.y
                        }
                    })
                    .onEnded({ value in
                        withAnimation(.easeInOut(duration: 0.2)){
                            isDragging = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeInOut(duration: 0.2)){
                                if !isDragging {
                                    dragEnded = false
                                }
                            }
                        }
                    })
                )
            }
            .frame(height: widthOrHeight(width: false) * 0.6)
            .offset(y: 20)
            .onChange(of: offset) { oldValue, newValue in
                let sections = (widthOrHeight(width: false) * 0.6) / 5.0
                
                if let center = vm.mapCameraPosition.region?.center ?? lastCameraPosition {
                    if let final = scaledValue(section: sections) {
                        let newMapSpan = MKCoordinateSpan(latitudeDelta: final, longitudeDelta: final)
                        vm.mapCameraPosition = .region(MKCoordinateRegion(
                            center: center,
                            span: newMapSpan))
                    }
                }
                
                if newValue < (sections) && oldValue >= (sections) {
                    if scaleImage != "shoe.fill" {
                        scaleImage = "shoe.fill"
                        color = .gray
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else if newValue < (sections * 2) && oldValue >= (sections * 2) {
                    if scaleImage != "bird.fill" {
                        scaleImage = "bird.fill"
                        color = .red
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else if newValue < (sections * 3) && oldValue >= (sections * 3) {
                    if scaleImage != "car.fill" {
                        scaleImage = "car.fill"
                        color = .blue
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else if newValue < (sections * 4) && oldValue >= (sections * 4) {
                    if scaleImage != "airplane" {
                        scaleImage = "airplane"
                        color = .black
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else if newValue < (sections * 5) && oldValue >= (sections * 5) {
                    if scaleImage != "moon.stars.fill" {
                        scaleImage = "moon.stars.fill"
                        color = .yellow
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                if newValue >= 0.0 && oldValue < (sections) {
                    if scaleImage != "shoe.fill" {
                        scaleImage = "shoe.fill"
                        color = .gray
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else if newValue >= (sections * 1) && oldValue < (sections * 2) {
                    if scaleImage != "bird.fill" {
                        scaleImage = "bird.fill"
                        color = .red
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else if newValue >= (sections * 2) && oldValue < (sections * 3) {
                    if scaleImage != "car.fill" {
                        scaleImage = "car.fill"
                        color = .blue
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else if newValue >= (sections * 3) && oldValue < (sections * 4) {
                    if scaleImage != "airplane" {
                        scaleImage = "airplane"
                        color = .black
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else if newValue >= (sections * 4) && oldValue < (sections * 5) {
                    if scaleImage != "moon.stars.fill" {
                        scaleImage = "moon.stars.fill"
                        color = .yellow
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
        }
    }
    func groupLocationsByProximity(locationPoints: [(LocationMap, CGPoint)], groupPoints: [(String, CGPoint)], maxDistance: CGFloat = 50) {
        var groups: [[LocationMap]] = []
        var visited = Set<String>()
        
        //merge 2 groups
        var processedIds = Set<String>()
        var toRemove = [String]()
        for (index, (id1, point1)) in groupPoints.enumerated() {
            guard !processedIds.contains(id1) else { continue }
            
            if let currentGroup = groupLocations.first(where: { $0.id == id1 }) {
                processedIds.insert(id1)
                
                for (otherIndex, (id2, point2)) in groupPoints.enumerated() where otherIndex > index {
                    guard !processedIds.contains(id2) else { continue }
                    
                    let xCondition = abs(point1.x - point2.x) <= maxDistance
                    let yCondition = abs(point1.y - point2.y) <= (maxDistance + 10)
                    
                    if xCondition && yCondition {
                        if let otherGroup = groupLocations.first(where: { $0.id == id2 }) {
                            
                            let combinedAllLocs = currentGroup.allLocs + otherGroup.allLocs
                            let totalLocs1 = currentGroup.allLocs.count
                            let totalLocs2 = otherGroup.allLocs.count
                            let totalLocs = totalLocs1 + totalLocs2
                            
                            let weightedLatitude = ((currentGroup.coordinates.latitude * Double(totalLocs1)) + (otherGroup.coordinates.latitude * Double(totalLocs2))) / Double(totalLocs)
                            let weightedLongitude = ((currentGroup.coordinates.longitude * Double(totalLocs1)) + (otherGroup.coordinates.longitude * Double(totalLocs2))) / Double(totalLocs)
                            
                            if let index = groupLocations.firstIndex(where: { $0.id == currentGroup.id }) {
                                groupLocations[index].allLocs = combinedAllLocs
                                groupLocations[index].coordinates = CLLocationCoordinate2D(latitude: weightedLatitude, longitude: weightedLongitude)
                                toRemove.append(id2)
                            }

                            processedIds.insert(id2)
                            for element in currentGroup.allLocs {
                                visited.insert(element.id)
                            }
                            for element in otherGroup.allLocs {
                                visited.insert(element.id)
                            }
                        }
                    }
                }
            }
        }
        toRemove.forEach { element in
            self.groupLocations.removeAll(where: { $0.id == element })
        }
        
        for i in locationPoints.indices {
            let (currentLocation, currentPoint) = locationPoints[i]
                        
            //Already in group: either remove or keep
            if let partOfGroup = groupLocations.firstIndex(where: { $0.allLocs.contains(where: { $0.id == currentLocation.id }) }) {

                if nearAtleastOnePoint(group: groupLocations[partOfGroup], allPoints: locationPoints, point: currentPoint, pointID: currentLocation.id, max: maxDistance, stories: false) {
                    visited.insert(currentLocation.id)
                    continue
                } else if groupLocations[partOfGroup].allLocs.count <= 2 {
                    groupLocations.remove(at: partOfGroup)
                } else {
                    groupLocations[partOfGroup].allLocs.removeAll(where: { $0.id == currentLocation.id })
                    
                    let allCoords = groupLocations[partOfGroup].allLocs.map { $0.coordinates }
                    let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                    let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                    groupLocations[partOfGroup].coordinates = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                }
            }
            
            //Add single to existing group
            if !groupLocations.contains(where: { $0.allLocs.contains(where: { $0.id == currentLocation.id }) }){
                var shouldContinue = false
                for x in groupLocations.indices {
                    if let otherPoint = groupPoints.first(where: { $0.0 == groupLocations[x].id })?.1 {
                        if abs(currentPoint.x - otherPoint.x) <= maxDistance && abs(currentPoint.y - otherPoint.y) <= (maxDistance + 10) {
                            shouldContinue = true
                            groupLocations[x].allLocs.append(currentLocation)
                            let allCoords = groupLocations[x].allLocs.map { $0.coordinates }
                            let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                            let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                            groupLocations[x].coordinates = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                            visited.insert(currentLocation.id)
                            break
                        }
                    }
                }
                if shouldContinue {
                    continue
                }
            }
            
            //make groups
            var group: [LocationMap] = [currentLocation]
            visited.insert(currentLocation.id)
            for j in locationPoints.indices {
                if i == j { continue }
                
                let (otherLocation, otherPoint) = locationPoints[j]
                
                if !visited.contains(otherLocation.id) {
                    if abs(currentPoint.x - otherPoint.x) <= maxDistance && abs(currentPoint.y - otherPoint.y) <= (maxDistance + 10) {
                        group.append(otherLocation)
                        visited.insert(otherLocation.id)
                    }
                }
            }
            if group.count > 1 {
                groups.append(group)
            }
        }
        
        //setup groups
        groups.forEach { newElement in
            var final = [LocationMap]()
            newElement.forEach { element in
                if !groupLocations.contains(where: { $0.allLocs.contains(where: { $0.id == element.id }) }){
                    final.append(element)
                }
            }
            if final.count > 1 {
                let allCoords = final.map { $0.coordinates }
                let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                let averageCoordinate = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                groupLocations.append(groupLocation(coordinates: averageCoordinate, allLocs: final))
            }
        }
    }
    func groupMemoriesByProximity(locationPoints: [(LocationMap, CGPoint)], groupPoints: [(String, CGPoint)], maxDistance: CGFloat = 50) {
        var groups: [[LocationMap]] = []
        var visited = Set<String>()
        
        //merge 2 groups
        var processedIds = Set<String>()
        var toRemove = [String]()
        for (index, (id1, point1)) in groupPoints.enumerated() {
            guard !processedIds.contains(id1) else { continue }
            
            if let currentGroup = memoryGroups.first(where: { $0.id == id1 }) {
                processedIds.insert(id1)
                
                for (otherIndex, (id2, point2)) in groupPoints.enumerated() where otherIndex > index {
                    guard !processedIds.contains(id2) else { continue }
                    
                    let xCondition = abs(point1.x - point2.x) <= maxDistance
                    let yCondition = abs(point1.y - point2.y) <= (maxDistance + 30)
                    
                    if xCondition && yCondition {
                        if let otherGroup = memoryGroups.first(where: { $0.id == id2 }) {
                            
                            let combinedAllLocs = currentGroup.allLocs + otherGroup.allLocs
                            let totalLocs1 = currentGroup.allLocs.count
                            let totalLocs2 = otherGroup.allLocs.count
                            let totalLocs = totalLocs1 + totalLocs2
                            
                            let weightedLatitude = ((currentGroup.coordinates.latitude * Double(totalLocs1)) + (otherGroup.coordinates.latitude * Double(totalLocs2))) / Double(totalLocs)
                            let weightedLongitude = ((currentGroup.coordinates.longitude * Double(totalLocs1)) + (otherGroup.coordinates.longitude * Double(totalLocs2))) / Double(totalLocs)
                            
                            if let index = memoryGroups.firstIndex(where: { $0.id == currentGroup.id }) {
                                memoryGroups[index].allLocs = combinedAllLocs
                                memoryGroups[index].coordinates = CLLocationCoordinate2D(latitude: weightedLatitude, longitude: weightedLongitude)
                                toRemove.append(id2)
                            }

                            processedIds.insert(id2)
                            for element in currentGroup.allLocs {
                                visited.insert(element.id)
                            }
                            for element in otherGroup.allLocs {
                                visited.insert(element.id)
                            }
                        }
                    }
                }
            }
        }
        toRemove.forEach { element in
            self.memoryGroups.removeAll(where: { $0.id == element })
        }
        
        for i in locationPoints.indices {
            let (currentLocation, currentPoint) = locationPoints[i]
                        
            //Already in group: either remove or keep
            if let partOfGroup = memoryGroups.firstIndex(where: { $0.allLocs.contains(where: { $0.id == currentLocation.id }) }) {

                if nearAtleastOnePoint(group: memoryGroups[partOfGroup], allPoints: locationPoints, point: currentPoint, pointID: currentLocation.id, max: maxDistance, stories: true) {
                    visited.insert(currentLocation.id)
                    continue
                } else if memoryGroups[partOfGroup].allLocs.count <= 2 {
                    memoryGroups.remove(at: partOfGroup)
                } else {
                    memoryGroups[partOfGroup].allLocs.removeAll(where: { $0.id == currentLocation.id })
                    
                    let allCoords = memoryGroups[partOfGroup].allLocs.map { $0.coordinates }
                    let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                    let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                    memoryGroups[partOfGroup].coordinates = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                }
            }
            
            //Add single to existing group
            if !memoryGroups.contains(where: { $0.allLocs.contains(where: { $0.id == currentLocation.id }) }){
                var shouldContinue = false
                for x in memoryGroups.indices {
                    if let otherPoint = groupPoints.first(where: { $0.0 == memoryGroups[x].id })?.1 {
                        if abs(currentPoint.x - otherPoint.x) <= maxDistance && abs(currentPoint.y - otherPoint.y) <= (maxDistance + 30) {
                            shouldContinue = true
                            memoryGroups[x].allLocs.append(currentLocation)
                            let allCoords = memoryGroups[x].allLocs.map { $0.coordinates }
                            let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                            let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                            memoryGroups[x].coordinates = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                            visited.insert(currentLocation.id)
                            break
                        }
                    }
                }
                if shouldContinue {
                    continue
                }
            }
            
            //make groups
            var group: [LocationMap] = [currentLocation]
            visited.insert(currentLocation.id)
            for j in locationPoints.indices {
                if i == j { continue }
                
                let (otherLocation, otherPoint) = locationPoints[j]
                
                if !visited.contains(otherLocation.id) {
                    if abs(currentPoint.x - otherPoint.x) <= maxDistance && abs(currentPoint.y - otherPoint.y) <= (maxDistance + 30) {
                        group.append(otherLocation)
                        visited.insert(otherLocation.id)
                    }
                }
            }
            if group.count > 1 {
                groups.append(group)
            }
        }
        
        //setup groups
        groups.forEach { newElement in
            var final = [LocationMap]()
            newElement.forEach { element in
                if !memoryGroups.contains(where: { $0.allLocs.contains(where: { $0.id == element.id }) }){
                    final.append(element)
                }
            }
            if final.count > 1 {
                let allCoords = final.map { $0.coordinates }
                let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                let averageCoordinate = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                memoryGroups.append(groupLocation(coordinates: averageCoordinate, allLocs: final))
            }
        }
    }
    func groupStoriesByProximity(locationPoints: [(LocationMap, CGPoint)], groupPoints: [(String, CGPoint)], maxDistance: CGFloat = 50) {
        var groups: [[LocationMap]] = []
        var visited = Set<String>()
        
        //merge 2 groups
        var processedIds = Set<String>()
        var toRemove = [String]()
        for (index, (id1, point1)) in groupPoints.enumerated() {
            guard !processedIds.contains(id1) else { continue }
            
            if let currentGroup = storyGroups.first(where: { $0.id == id1 }) {
                processedIds.insert(id1)
                
                for (otherIndex, (id2, point2)) in groupPoints.enumerated() where otherIndex > index {
                    guard !processedIds.contains(id2) else { continue }
                    
                    let xCondition = abs(point1.x - point2.x) <= maxDistance
                    let yCondition = abs(point1.y - point2.y) <= (maxDistance + 30)
                    
                    if xCondition && yCondition {
                        if let otherGroup = storyGroups.first(where: { $0.id == id2 }) {
                            
                            let combinedAllLocs = currentGroup.allLocs + otherGroup.allLocs
                            let totalLocs1 = currentGroup.allLocs.count
                            let totalLocs2 = otherGroup.allLocs.count
                            let totalLocs = totalLocs1 + totalLocs2
                            
                            let weightedLatitude = ((currentGroup.coordinates.latitude * Double(totalLocs1)) + (otherGroup.coordinates.latitude * Double(totalLocs2))) / Double(totalLocs)
                            let weightedLongitude = ((currentGroup.coordinates.longitude * Double(totalLocs1)) + (otherGroup.coordinates.longitude * Double(totalLocs2))) / Double(totalLocs)
                            
                            if let index = storyGroups.firstIndex(where: { $0.id == currentGroup.id }) {
                                storyGroups[index].allLocs = combinedAllLocs
                                storyGroups[index].coordinates = CLLocationCoordinate2D(latitude: weightedLatitude, longitude: weightedLongitude)
                                toRemove.append(id2)
                            }

                            processedIds.insert(id2)
                            for element in currentGroup.allLocs {
                                visited.insert(element.id)
                            }
                            for element in otherGroup.allLocs {
                                visited.insert(element.id)
                            }
                        }
                    }
                }
            }
        }
        toRemove.forEach { element in
            self.storyGroups.removeAll(where: { $0.id == element })
        }
        
        for i in locationPoints.indices {
            let (currentLocation, currentPoint) = locationPoints[i]
                        
            //Already in group: either remove or keep
            if let partOfGroup = storyGroups.firstIndex(where: { $0.allLocs.contains(where: { $0.id == currentLocation.id }) }) {

                if nearAtleastOnePoint(group: storyGroups[partOfGroup], allPoints: locationPoints, point: currentPoint, pointID: currentLocation.id, max: maxDistance, stories: true) {
                    visited.insert(currentLocation.id)
                    continue
                } else if storyGroups[partOfGroup].allLocs.count <= 2 {
                    storyGroups.remove(at: partOfGroup)
                } else {
                    storyGroups[partOfGroup].allLocs.removeAll(where: { $0.id == currentLocation.id })
                    
                    let allCoords = storyGroups[partOfGroup].allLocs.map { $0.coordinates }
                    let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                    let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                    storyGroups[partOfGroup].coordinates = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                }
            }
            
            //Add single to existing group
            if !storyGroups.contains(where: { $0.allLocs.contains(where: { $0.id == currentLocation.id }) }){
                var shouldContinue = false
                for x in storyGroups.indices {
                    if let otherPoint = groupPoints.first(where: { $0.0 == storyGroups[x].id })?.1 {
                        if abs(currentPoint.x - otherPoint.x) <= maxDistance && abs(currentPoint.y - otherPoint.y) <= (maxDistance + 30) {
                            shouldContinue = true
                            storyGroups[x].allLocs.append(currentLocation)
                            let allCoords = storyGroups[x].allLocs.map { $0.coordinates }
                            let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                            let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                            storyGroups[x].coordinates = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                            visited.insert(currentLocation.id)
                            break
                        }
                    }
                }
                if shouldContinue {
                    continue
                }
            }
            
            //make groups
            var group: [LocationMap] = [currentLocation]
            visited.insert(currentLocation.id)
            for j in locationPoints.indices {
                if i == j { continue }
                
                let (otherLocation, otherPoint) = locationPoints[j]
                
                if !visited.contains(otherLocation.id) {
                    if abs(currentPoint.x - otherPoint.x) <= maxDistance && abs(currentPoint.y - otherPoint.y) <= (maxDistance + 30) {
                        group.append(otherLocation)
                        visited.insert(otherLocation.id)
                    }
                }
            }
            if group.count > 1 {
                groups.append(group)
            }
        }
        
        //setup groups
        groups.forEach { newElement in
            var final = [LocationMap]()
            newElement.forEach { element in
                if !storyGroups.contains(where: { $0.allLocs.contains(where: { $0.id == element.id }) }){
                    final.append(element)
                }
            }
            if final.count > 1 {
                let allCoords = final.map { $0.coordinates }
                let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                let averageCoordinate = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                storyGroups.append(groupLocation(coordinates: averageCoordinate, allLocs: final))
            }
        }
    }
    func groupPlacesByProximity(locationPoints: [(Business, CGPoint)], groupPoints: [(String, CGPoint)], maxDistance: CGFloat = 50) {
        var groups: [[Business]] = []
        var visited = Set<String>()
        
        //merge 2 groups
        var processedIds = Set<String>()
        var toRemove = [String]()
        for (index, (id1, point1)) in groupPoints.enumerated() {
            guard !processedIds.contains(id1) else { continue }
            
            if let currentGroup = businessGroups.first(where: { $0.id == id1 }) {
                processedIds.insert(id1)
                
                for (otherIndex, (id2, point2)) in groupPoints.enumerated() where otherIndex > index {
                    guard !processedIds.contains(id2) else { continue }
                    
                    let xCondition = abs(point1.x - point2.x) <= maxDistance
                    let yCondition = abs(point1.y - point2.y) <= maxDistance
                    
                    if xCondition && yCondition {
                        if let otherGroup = businessGroups.first(where: { $0.id == id2 }) {
                            
                            let combinedAllLocs = currentGroup.allLocs + otherGroup.allLocs
                            let combinedPhotos = currentGroup.photos.count < 10 ? currentGroup.photos + otherGroup.photos : currentGroup.photos
                            let totalLocs1 = currentGroup.allLocs.count
                            let totalLocs2 = otherGroup.allLocs.count
                            let totalLocs = totalLocs1 + totalLocs2
                            
                            let weightedLatitude = ((currentGroup.coordinates.latitude * Double(totalLocs1)) + (otherGroup.coordinates.latitude * Double(totalLocs2))) / Double(totalLocs)
                            let weightedLongitude = ((currentGroup.coordinates.longitude * Double(totalLocs1)) + (otherGroup.coordinates.longitude * Double(totalLocs2))) / Double(totalLocs)
                            
                            if let index = businessGroups.firstIndex(where: { $0.id == currentGroup.id }) {
                                businessGroups[index].allLocs = combinedAllLocs
                                businessGroups[index].photos = combinedPhotos
                                businessGroups[index].coordinates = CLLocationCoordinate2D(latitude: weightedLatitude, longitude: weightedLongitude)
                                toRemove.append(id2)
                            }

                            processedIds.insert(id2)
                            for element in currentGroup.allLocs {
                                visited.insert(element.id ?? "")
                            }
                            for element in otherGroup.allLocs {
                                visited.insert(element.id ?? "")
                            }
                        }
                    }
                }
            }
        }
        toRemove.forEach { element in
            self.businessGroups.removeAll(where: { $0.id == element })
        }
        
        for i in locationPoints.indices {
            let (currentLocation, currentPoint) = locationPoints[i]
                        
            //Already in group: either remove or keep
            if let partOfGroup = businessGroups.firstIndex(where: { $0.allLocs.contains(where: { $0.id == currentLocation.id }) }) {

                if nearAtleastOneBusiness(group: businessGroups[partOfGroup], allPoints: locationPoints, point: currentPoint, pointID: currentLocation.id ?? "", max: maxDistance) {
                    visited.insert(currentLocation.id ?? "")
                    continue
                } else if businessGroups[partOfGroup].allLocs.count <= 2 {
                    businessGroups.remove(at: partOfGroup)
                } else {
                    businessGroups[partOfGroup].allLocs.removeAll(where: { $0.id == currentLocation.id })
                    
                    let allCoords = businessGroups[partOfGroup].allLocs.compactMap { $0.coordinates?.clLocationCoordinate2D }
                    let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                    let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                    businessGroups[partOfGroup].coordinates = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                }
            }
            
            //Add single to existing group
            if !businessGroups.contains(where: { $0.allLocs.contains(where: { $0.id == currentLocation.id }) }){
                var shouldContinue = false
                for x in businessGroups.indices {
                    if let otherPoint = groupPoints.first(where: { $0.0 == businessGroups[x].id })?.1 {
                        if abs(currentPoint.x - otherPoint.x) <= maxDistance && abs(currentPoint.y - otherPoint.y) <= maxDistance {
                            shouldContinue = true
                            if businessGroups[x].photos.count < 10 {
                                let more = [currentLocation.image_url].compactMap { $0 } + (currentLocation.photos ?? []).compactMap { $0 }
                                let neededPhotos = 10 - businessGroups[x].photos.count
                                businessGroups[x].photos += more.prefix(neededPhotos)
                            }
                            businessGroups[x].allLocs.append(currentLocation)
                            let allCoords = businessGroups[x].allLocs.compactMap { $0.coordinates?.clLocationCoordinate2D }
                            let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                            let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                            businessGroups[x].coordinates = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                            visited.insert(currentLocation.id ?? "")
                            break
                        }
                    }
                }
                if shouldContinue {
                    continue
                }
            }
            
            //make groups
            var group: [Business] = [currentLocation]
            visited.insert(currentLocation.id ?? "")
            for j in locationPoints.indices {
                if i == j { continue }
                
                let (otherLocation, otherPoint) = locationPoints[j]
                
                if !visited.contains(otherLocation.id ?? "") {
                    if abs(currentPoint.x - otherPoint.x) <= maxDistance && abs(currentPoint.y - otherPoint.y) <= maxDistance {
                        group.append(otherLocation)
                        visited.insert(otherLocation.id ?? "")
                    }
                }
            }
            if group.count > 1 {
                groups.append(group)
            }
        }
        
        //setup groups
        groups.forEach { newElement in
            var final = [Business]()
            newElement.forEach { element in
                if !businessGroups.contains(where: { $0.allLocs.contains(where: { $0.id == element.id }) }){
                    final.append(element)
                }
            }
            if final.count > 1 {
                let allCoords = final.compactMap { $0.coordinates?.clLocationCoordinate2D }
                let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
                let avgLong = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
                let averageCoordinate = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLong)
                var name = final.compactMap { $0.name }.filter { !$0.isEmpty }.min(by: { $0.count < $1.count }) ?? ""
                if name.isEmpty {
                    name = "\(final.count) restaurants"
                } else {
                    name += " & \(final.count)"
                }
                businessGroups.append(groupBusiness(name: name, photos: getFirst10Photos(businesses: final), coordinates: averageCoordinate, allLocs: final))
            }
        }
    }
    func nearAtleastOnePoint(group: groupLocation, allPoints: [(LocationMap, CGPoint)], point: CGPoint, pointID: String, max: Double, stories: Bool) -> Bool {
        for element in group.allLocs {
            if element.id != pointID {
                if let point2 = allPoints.first(where: { $0.0.id == element.id })?.1 {
                    if abs(point.x - point2.x) <= max && abs(point.y - point2.y) <= (max + (stories ? 30 : 10)) {
                        return true
                    }
                }
            }
        }
        return false
    }
    func nearAtleastOneBusiness(group: groupBusiness, allPoints: [(Business, CGPoint)], point: CGPoint, pointID: String, max: Double) -> Bool {
        for element in group.allLocs {
            if element.id != pointID {
                if let point2 = allPoints.first(where: { $0.0.id == element.id })?.1 {
                    if abs(point.x - point2.x) <= max && abs(point.y - point2.y) <= max {
                        return true
                    }
                }
            }
        }
        return false
    }
    func getFirst10Photos(businesses: [Business]) -> [String] {
        var photoArray: [String] = []
        for business in businesses {
            if let imageUrl = business.image_url {
                photoArray.append(imageUrl)
            }
            if let photos = business.photos {
                photoArray.append(contentsOf: photos)
            }
            if photoArray.count >= 10 {
                break
            }
        }
        return Array(photoArray.prefix(10))
    }
    func scaledValue(section: CGFloat) -> Double? {
        guard offset >= 0 else { return nil }
        
        let minValue: Double
        let maxValue: Double
        let ratio: CGFloat
        
        if offset <= section {
            ratio = offset / section
            minValue = 0.0015
            maxValue = 0.05
        } else if offset <= section * 2 {
            ratio = (offset - section) / section
            minValue = 0.05
            maxValue = 1.0
        } else if offset <= section * 3 {
            ratio = (offset - section * 2) / section
            minValue = 1.0
            maxValue = 6.0
        } else if offset <= section * 4 {
            ratio = (offset - section * 3) / section
            minValue = 6.0
            maxValue = 30.0
        } else if offset <= section * 5 {
            ratio = (offset - section * 4) / section
            minValue = 30.0
            maxValue = 70.0
        } else {
            return nil
        }
 
        let scaledValue = minValue + (maxValue - minValue) * Double(ratio)
        return scaledValue
    }
}

func calculateDrivingTime(
    from start: CLLocationCoordinate2D,
    to end: CLLocationCoordinate2D,
    completion: @escaping (String?) -> Void
) {
    let sourcePlacemark = MKPlacemark(coordinate: start)
    let destinationPlacemark = MKPlacemark(coordinate: end)
    
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: sourcePlacemark)
    request.destination = MKMapItem(placemark: destinationPlacemark)
    request.requestsAlternateRoutes = false
    request.transportType = .automobile
    
    let directions = MKDirections(request: request)
    directions.calculate { (response, error) in
        if let error = error {
            print("Error calculating directions: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let response = response, let route = response.routes.first else {
            completion(nil)
            return
        }
        
        let travelTimeInSeconds = route.expectedTravelTime
        let travelTimeInMinutes = Int(travelTimeInSeconds / 60)
        
        let timeString: String
        if travelTimeInMinutes < 60 {
            timeString = "\(travelTimeInMinutes) min"
        } else {
            let travelTimeInHours = travelTimeInMinutes / 60
            timeString = "\(travelTimeInHours)h"
        }
        
        completion(timeString)
    }
}

func isDayOrNightFunc(timeString: String) -> Bool? {
    let components = timeString.components(separatedBy: " ")
    guard components.count == 2 else {
        return nil
    }
    
    let timeComponents = components[0].components(separatedBy: ":")
    guard timeComponents.count == 2,
          let hour = Int(timeComponents[0]),
          let period = components[1].lowercased() == "am" ? "am" : "pm" else {
        return nil
    }
    
    switch (hour, period) {
    case (0..<6, "am"), (12, "pm"):
        return false // Night time
    case (6..<12, "am"), (1..<6, "pm"):
        return true // Day time
    default:
        return false // Night time (default)
    }
}

func isAtLeast5MinutesOld(date: Date) -> Bool {
    let currentDate = Date()

    let timeInterval = currentDate.timeIntervalSince(date)

    return timeInterval >= 300
}

var statesDictionary: [String: String] = [
    "AL": "Alabama",
    "AK": "Alaska",
    "AZ": "Arizona",
    "AR": "Arkansas",
    "CA": "California",
    "CO": "Colorado",
    "CT": "Connecticut",
    "DE": "Delaware",
    "FL": "Florida",
    "GA": "Georgia",
    "HI": "Hawaii",
    "ID": "Idaho",
    "IL": "Illinois",
    "IN": "Indiana",
    "IA": "Iowa",
    "KS": "Kansas",
    "KY": "Kentucky",
    "LA": "Louisiana",
    "ME": "Maine",
    "MD": "Maryland",
    "MA": "Massachusetts",
    "MI": "Michigan",
    "MN": "Minnesota",
    "MS": "Mississippi",
    "MO": "Missouri",
    "MT": "Montana",
    "NE": "Nebraska",
    "NV": "Nevada",
    "NH": "New Hampshire",
    "NJ": "New Jersey",
    "NM": "New Mexico",
    "NY": "New York",
    "NC": "North Carolina",
    "ND": "North Dakota",
    "OH": "Ohio",
    "OK": "Oklahoma",
    "OR": "Oregon",
    "PA": "Pennsylvania",
    "RI": "Rhode Island",
    "SC": "South Carolina",
    "SD": "South Dakota",
    "TN": "Tennessee",
    "TX": "Texas",
    "UT": "Utah",
    "VT": "Vermont",
    "VA": "Virginia",
    "WA": "Washington",
    "WV": "West Virginia",
    "WI": "Wisconsin",
    "WY": "Wyoming"
]

func currBattery() -> Double {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return Double(UIDevice.current.batteryLevel)
}

func getMessageTime(date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()
    
    let minC = calendar.dateComponents([.second, .minute], from: date, to: now)
    let hourC = calendar.dateComponents([.hour], from: date, to: now)
    let dayC = calendar.dateComponents([.day], from: date, to: now)
    
    let minute = minC.minute ?? 0
    if minute < 1 {
        return "\(minC.second ?? 0)s ago"
    } else if (minC.minute ?? 70) < 60 {
        return "\(minC.minute ?? 5)m ago"
    } else if let hour = hourC.hour, hour < 24 {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    } else if let day = dayC.day, day == 1 {
        return "Yesterday"
    } else if let day = dayC.day, day < 7 {
        let weekday = calendar.component(.weekday, from: date)
        let weekdayName = calendar.weekdaySymbols[weekday - 1]
        return weekdayName
    } else {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: date)
    }
}
