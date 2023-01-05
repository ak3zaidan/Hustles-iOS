import SwiftUI
import Kingfisher
import Combine
import SceneKit
import CoreLocation

class ActionViewModel: ObservableObject {
    weak var controller: GlobeViewController?
    
    func moveToLocation(lat: Double, long: Double) {
        guard let controller else { return }
        controller.moveToLocation(lat: lat, long: long)
    }
    func zoom(inOut: Bool){
        guard let controller else { return }
        controller.zoomIn(zoomIn: inOut)
    }
}

private struct GlobeViewControllerRepresentable: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: GlobeViewModel
    
    let actionModel: ActionViewModel
    
    func makeUIViewController(context: Context) -> GlobeViewController {
        let globeController = GlobeViewController(popRoot: viewModel, action: actionModel)
        return globeController
    }
    
    func updateUIViewController(_ uiViewController: GlobeViewController, context: Context) { }
}

struct MainProfile: View, KeyboardReadable {
    let uid: String
    let photo: String
    let user: User?
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: GlobeViewModel
    @EnvironmentObject var searchModel: CitySearchViewModel
    @State private var keyboardV = false
    @StateObject var actionModel: ActionViewModel = .init()
    @State var showAddStory = false
    let manager = GlobeLocationManager()
    @State var showAnimation = false
    @State private var showOnlineStatus = false
    @Environment(\.colorScheme) var colorScheme
    @FocusState var focusedField: FocusedField?
    
    @State private var postHustle = false
    @State private var postJob = false
    @State private var postMarketPlace = false
    @State private var postQuestion = false
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State var initialContent: uploadContent? = nil
    @State var place: myLoc? = nil
    @State var uploadJob: Int = 2
    @State var uploadShop: Int = 1
    @StateObject var uploadViewModel = UploadJobViewModel()
    @StateObject var PostShopViewModel = UploadShopViewModel()
    @State private var showMemories = false
    
    @State var offset: CGSize = .zero
    @State var showWhenDone = false
    @State var opacity = 0.0
    @State var addPadding = false
    
    @Namespace private var animation
    @State var isExpanded: Bool = false
    @State var showUserSheet: Bool = false
    @State var userSheetId = ""
    
    var body: some View {
        ZStack(alignment: .bottomTrailing){
            if viewModel.option == 1 {
                NavigationStack {
                    ProfileView(showSettings: true, showMessaging: false, uid: uid, photo: photo, user: user, expand: false, isMain: true)
                }.transition(.move(edge: .bottom).combined(with: .opacity))
            } else if !showAddStory {
                Color.black.ignoresSafeArea()
                GlobeViewControllerRepresentable(actionModel: actionModel).ignoresSafeArea().offset(y: -65)
                    .padding(.top, addPadding ? top_Inset() : 0.0)
                
                if let points = viewModel.focusLocation, !isExpanded {
                    FocusView()
                        .offset(y: -65)
                        .position(x: points.x, y: points.y)
                        .task {
                            do {
                                try await Task.sleep(for: .milliseconds(450))
                                self.viewModel.focusLocation = nil
                            } catch { }
                        }
                        .id(points.id)
                        .transition(.scale.combined(with: .opacity))
                }
                
                if !isExpanded {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 8){
                                Button {
                                    if let loc = viewModel.currentLocation {
                                        actionModel.moveToLocation(lat: loc.lat, long: loc.long)
                                    }
                                } label: {
                                    VStack(spacing: 3){
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.system(size: 15))
                                            .padding(8)
                                            .foregroundStyle(.white)
                                            .frame(width: 38, height: 38)
                                            .background(.blue.opacity(0.8)).clipShape(Circle())
                                        Text("Center").font(.caption2).foregroundStyle(.white).bold()
                                    }
                                }
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    //find lives
                                } label: {
                                    VStack(spacing: 3){
                                        Image(systemName: "video.badge.waveform")
                                            .font(.system(size: 15))
                                            .padding(8)
                                            .foregroundStyle(.white)
                                            .frame(width: 38, height: 38)
                                            .background(LinearGradient(colors: [.red, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(Circle())
                                        Text("Live").font(.caption2).foregroundStyle(.white).bold()
                                    }
                                }
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    //find people to chat with
                                } label: {
                                    VStack(spacing: 3){
                                        Image(systemName: "person.line.dotted.person.fill")
                                            .font(.system(size: 15))
                                            .padding(8)
                                            .foregroundStyle(.white)
                                            .frame(width: 38, height: 38)
                                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(Circle())
                                        Text("Chat").font(.caption2).foregroundStyle(.white).bold()
                                    }
                                }
                                Menu {
                                    Button {
                                        showAddStory = true
                                    } label: {
                                        Label("Add Story", systemImage: "globe")
                                    }
                                    Button {
                                        //go live
                                    } label: {
                                        Label("Go Live", systemImage: "video.badge.plus")
                                    }
                                    Button {
                                        postHustle = true
                                    } label: {
                                        Label("Hustle", systemImage: "newspaper")
                                    }
                                    Button {
                                        postJob = true
                                    } label: {
                                        Label("Job", systemImage: "wrench.and.screwdriver.fill")
                                    }
                                    Button {
                                        postMarketPlace = true
                                    } label: {
                                        Label("Marketplace", systemImage: "house")
                                    }
                                    Button {
                                        postQuestion = true
                                    } label: {
                                        Label("Question", systemImage: "questionmark")
                                    }
                                } label: {
                                    VStack(spacing: 3){
                                        Image(systemName: "plus")
                                            .font(.system(size: 15))
                                            .padding(8)
                                            .foregroundStyle(.white)
                                            .frame(width: 38, height: 38)
                                            .background(Color(UIColor.darkGray)
                                                .opacity(0.8))
                                            .clipShape(Circle())
                                        Text("Create").font(.caption2).foregroundStyle(.white).bold()
                                    }
                                }
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation {
                                        focusedField = .one
                                    }
                                } label: {
                                    VStack(spacing: 3){
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 15))
                                            .padding(8)
                                            .foregroundStyle(.white)
                                            .frame(width: 38, height: 38)
                                            .background(Color(UIColor.darkGray).opacity(0.8)).clipShape(Circle())
                                        Text("Search").font(.caption2).foregroundStyle(.white).bold()
                                    }
                                }
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        showMemories = true
                                        popRoot.hideTabBar = true
                                    }
                                } label: {
                                    VStack(spacing: 3){
                                        ZStack {
                                            Circle().foregroundStyle(.black).opacity(0.6)
                                            Image("memory")
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                                .scaledToFit().offset(x: 1)
                                        }.frame(width: 38, height: 38)
                                        Text("Memory").font(.caption2).foregroundStyle(.white).bold()
                                    }
                                }
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color(UIColor.lightGray))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            Spacer()
                        }
                        Spacer()
                    }.padding(.top, 10).padding(.top, addPadding ? top_Inset() : 0.0).transition(.move(edge: .top).combined(with: .opacity))
                }
                VStack(spacing: 3){
                    Spacer()
                    if searchModel.showSearch {
                        searchBody().transition(.move(edge: .leading))
                    }
                    ZStack(alignment: .leading){
                        TextField("", text: $searchModel.searchQuery)
                            .tint(.blue)
                            .padding(.vertical, 10)
                            .focused($focusedField, equals: .one)
                            .padding(.leading, 31)
                            .padding(.trailing, 25)
                            .background(colorScheme == .dark ? .ultraThickMaterial : .ultraThinMaterial)
                            .cornerRadius(18, corners: .allCorners)
                            .onChange(of: searchModel.searchQuery) { _, _ in
                                searchModel.sortSearch()
                            }
                            .onReceive (
                                searchModel.$searchQuery
                                    .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
                            ) {
                                guard !$0.isEmpty else { return }
                                searchModel.performSearch()
                            }
                            .onSubmit {
                                withAnimation(.easeIn(duration: 0.2)){
                                    focusedField = .two
                                    searchModel.searching = false
                                    searchModel.showSearch = false
                                }
                            }
                        if searchModel.searchQuery.isEmpty {
                            HStack(spacing: 3){
                                Image(systemName: "magnifyingglass")
                                Text("Search")
                                Spacer()
                            }.offset(x: 8).font(.system(size: 17))
                        } else {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .offset(x: 8).font(.system(size: 17))
                                Spacer()
                                if searchModel.searching {
                                    ProgressView().padding(.trailing, 5)
                                } else {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        searchModel.searchQuery = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 17))
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    }.padding(.trailing, 5)
                                }
                            }
                        }
                    }.padding(.horizontal, 18).padding(.bottom, keyboardV ? 8 : 0)
                }
                
                if viewModel.option == 3 && !isExpanded {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Image("memory")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .padding(4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .opacity(showWhenDone ? 1.0 : opacity)
                                    .scaleEffect(showWhenDone ? 1.5 : 1.0)
                                    .animation(.bouncy(duration: 0.2), value: showWhenDone)
                                
                                ZStack {
                                    personView(size: 55)
                                    if let image = auth.currentUser?.profileImageUrl {
                                        KFImage(URL(string: image))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 55, height: 55)
                                            .clipShape(Circle())
                                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                    }
                                }
                                .offset(offset)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.25)){
                                        viewModel.option = 1
                                    }
                                }
                                .gesture(
                                    DragGesture()
                                        .onChanged({ value in
                                            self.offset = value.translation
                                            let max = max(abs(value.translation.width), abs(value.translation.height))
                                            self.opacity = min(1.0, (max / 140))
                                            
                                            if max >= 140 && !showWhenDone {
                                                showWhenDone = true
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            } else if max < 140 && showWhenDone {
                                                showWhenDone = false
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            }
                                        })
                                        .onEnded({ value in
                                            if showWhenDone {
                                                withAnimation(.easeInOut(duration: 0.2)){
                                                    showMemories = true
                                                    popRoot.hideTabBar = true
                                                }
                                            }
                                            showWhenDone = false
                                            withAnimation(.easeInOut(duration: 0.2)){
                                                offset = .zero
                                                opacity = 0.0
                                            }
                                        })
                                )
                            }
                        }
                    }
                    .padding(.bottom, 110).padding(.trailing, 25).ignoresSafeArea()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if viewModel.option == 2 {
                    userProfileCover()
                }
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    GeometryReader { _ in
                        Circle().foregroundStyle(.white)
                    }
                    .matchedGeometryEffect(id: "showMainStories", in: animation, anchor: .center)
                    .frame(width: 3, height: 3).opacity(0.0)
                    Spacer()
                }
                Spacer()
            }
        }
        .overlay(content: {
            if showMemories {
                MemoriesView(close: {
                    withAnimation(.easeInOut(duration: 0.2)){
                        showMemories = false
                        popRoot.hideTabBar = false
                    }
                })
                .background(colorScheme == .dark ? .black : .white)
                .transition(.move(edge: .trailing))
            }
        })
        .fullScreenCover(isPresented: $postHustle, content: {
            NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent)
                .onDisappear {
                    place = nil
                }
        })
        .fullScreenCover(isPresented: $postJob, content: {
            TabView(selection: $uploadJob) {
                UploadJobView(viewModel: uploadViewModel, selTab: $uploadJob, lastTab: 2, isProfile: true)
                    .tag(2)
                PromoteUploadView(viewModel: uploadViewModel, selTab: $uploadJob, lastTab: 2, isProfile: true)
                    .tag(3)
            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        })
        .fullScreenCover(isPresented: $postMarketPlace, content: {
            TabView(selection: $uploadShop) {
                UploadFirstView(viewModel: PostShopViewModel, selTab: $uploadShop, lastTab: 1, isProfile: true).tag(1)
                UploadSecView(viewModel: PostShopViewModel, selTab: $uploadShop, lastTab: 1, isProfile: true).tag(2)
            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        })
        .fullScreenCover(isPresented: $postQuestion, content: {
            UploadQuestion()
        })
        .sheet(isPresented: $showOnlineStatus, content: {
            SilentEditView()
        })
        .onChange(of: viewModel.couldntFindContent, { _, _ in
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        })
        .onChange(of: viewModel.showMainStories, { _, _ in
            DispatchQueue.main.async {
                addPadding = true
                profile.selectedStories = viewModel.currentStory
                profile.mid = "showMainStories"
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                actionModel.zoom(inOut: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15){
                    withAnimation(.easeInOut(duration: 0.15)){
                        popRoot.hideTabBar = true
                        self.isExpanded = true
                    }
                }
            }
        })
        .onAppear {
            if viewModel.currentLocation == nil {
                manager.requestLocation() { place in
                    if !place.0.isEmpty && !place.1.isEmpty {
                        actionModel.moveToLocation(lat: place.2, long: place.3)
                        viewModel.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                    }
                }
            } else {
                actionModel.moveToLocation(lat: viewModel.currentLocation?.lat ?? 0.0, long: viewModel.currentLocation?.long ?? 0.0)
            }
            if let current = auth.currentUser {
                if !profile.users.contains(where: { $0.user.id == current.id }) {
                    profile.start(uid: uid, currentUser: current, optionalUser: nil)
                }
                profile.updateStoriesUser(user: current)
            }
        }
        .onChange(of: auth.currentUser?.id, { _, _ in
            if let current = auth.currentUser {
                if !profile.users.contains(where: { $0.user.id == current.id }) {
                    profile.start(uid: uid, currentUser: current, optionalUser: nil)
                }
                profile.updateStoriesUser(user: current)
            }
        })
        .fullScreenCover(isPresented: $showAddStory, content: {
            MessageCamera(initialSend: .constant(nil), showMemories: true)
        })
        .onReceive(keyboardPublisher) { new in
            keyboardV = new
            if new && viewModel.option != 1 && !showAddStory && !postHustle && !postJob && !postMarketPlace && !postQuestion && !showMemories && !isExpanded {
                searchModel.makeCityCanidates()
                withAnimation(.easeIn(duration: 0.2)){
                    searchModel.showSearch = true
                }
            }
        }
        .onChange(of: viewModel.option) { _, _ in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: viewModel.hideSearch) { _, _ in
            withAnimation(.easeIn(duration: 0.2)){
                searchModel.searching = false
                searchModel.showSearch = false
            }
        }
        .sheet(isPresented: $showUserSheet) {
            NavigationStack {
                ProfileSheetView(uid: self.userSheetId, photo: "", user: nil, username: .constant(nil))
                    .dynamicTypeSize(.large).ignoresSafeArea(.keyboard)
            }
            .presentationDetents([.large])
            .onDisappear {
                showUserSheet = false
            }
        }
        .overlay {
            if isExpanded {
                MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: profile.mid, isHome: false, canOpenChat: false, canOpenProfile: true, openChat: { _ in
                }, openProfile: { uid in
                    self.userSheetId = uid
                    self.showUserSheet = true
                })
                .transition(.scale)
                .onDisappear {
                    addPadding = false
                    withAnimation(.easeInOut(duration: 0.15)){
                        popRoot.hideTabBar = false
                    }
                    if profile.mid == "showMainStories" {
                        actionModel.zoom(inOut: false)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: addPadding ? .all : [])
    }
    func hasStories() -> Bool {
        if let uid = auth.currentUser?.id {
            return !(profile.users.first(where: { $0.user.id == uid })?.stories ?? []).isEmpty
        }
        return false
    }
    func userProfileCover() -> some View {
        VStack {
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.25)){
                    viewModel.option = 1
                }
            } label: {
                ZStack {
                    if let image = auth.currentUser?.userBackground {
                        Color.orange.opacity(0.7)
                        KFImage(URL(string: image))
                            .resizable()
                            .scaledToFill()
                            .frame(height: 165)
                            .clipped()
                        TransparentBlurView(removeAllFilters: true)
                            .blur(radius: 8, opaque: true)
                            .background(.black.opacity(0.3))
                    } else {
                        Color.orange.opacity(0.7)
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 5){
                            HStack(spacing: 0){
                                Text(auth.currentUser?.fullname ?? "").foregroundStyle(.white).bold().font(.system(size: 18))
                                if let index = profile.currentUser {
                                    Button(action: {
                                        showOnlineStatus.toggle()
                                    }, label: {
                                        ZStack {
                                            Circle().foregroundStyle(.gray).opacity(0.001).frame(width: 30, height: 30)
                                            if let silent = profile.users[index].user.silent {
                                                if silent == 1 {
                                                    Circle().foregroundStyle(.green).frame(width: 13, height: 13)
                                                } else if silent == 2 {
                                                    Image(systemName: "moon.fill").foregroundStyle(.yellow).frame(width: 18, height: 18)
                                                } else if silent == 3 {
                                                    Image(systemName: "slash.circle.fill").foregroundStyle(.red).frame(width: 18, height: 18)
                                                } else {
                                                    Image("ghostMode")
                                                        .resizable().scaledToFit().frame(width: 18, height: 18).scaleEffect(1.4)
                                                }
                                            } else {
                                                Circle().foregroundStyle(.green).frame(width: 13, height: 13)
                                            }
                                        }
                                    }).transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                                }
                                Spacer()
                            }
                            Text("@\(auth.currentUser?.username ?? "")").foregroundStyle(.white).bold().font(.system(size: 15))
                            Spacer()
                        }.padding(.top)
                        Spacer()
                        VStack {
                            ZStack {
                                if hasStories() {
                                    StoryRingView(size: 54, active: false, strokeSize: 2.5)
                                    
                                    let size = isExpanded ? 200 : 43.0
                                    GeometryReader { _ in
                                        ZStack {
                                            personView(size: size)
                                            
                                            if let image = auth.currentUser?.profileImageUrl {
                                                KFImage(URL(string: image))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .scaledToFill()
                                                    .clipShape(Circle())
                                                    .frame(width: size, height: size)
                                                    .shadow(radius: 1)
                                            }
                                        }.opacity(isExpanded ? 0.0 : 1.0)
                                    }
                                    .matchedGeometryEffect(id: "MainProfile", in: animation, anchor: .bottom)
                                    .frame(width: 43, height: 43)
                                    .onTapGesture {
                                        if let uid = auth.currentUser?.id, let stories = profile.users.first(where: { $0.user.id == uid })?.stories {
                                            DispatchQueue.main.async {
                                                profile.selectedStories = stories
                                                profile.mid = "MainProfile"
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                withAnimation(.easeInOut(duration: 0.15)){
                                                    popRoot.hideTabBar = true
                                                    self.isExpanded = true
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    personView(size: 45.0)
                                    if let image = auth.currentUser?.profileImageUrl {
                                        KFImage(URL(string: image))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .scaledToFill()
                                            .clipShape(Circle())
                                            .frame(width: 45.0, height: 45.0)
                                            .shadow(color: .gray, radius: 2)
                                    }
                                }
                            }
                            Spacer()
                        }.padding(.top)
                    }.padding(.horizontal, 25)
                }.frame(height: 165).cornerRadius(40, corners: [.topLeft, .topRight])
            }
        }
        .ignoresSafeArea()
        .transition(.move(edge: .bottom))
    }
    func searchBody() -> some View {
        VStack(spacing: 10){
            ScrollView {
                VStack {
                    ForEach(searchModel.searchResults){ element in
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.easeIn(duration: 0.2)){
                                searchModel.searching = false
                                searchModel.showSearch = false
                            }
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            actionModel.moveToLocation(lat: element.latitude, long: element.longitude)
                            
                            let globeCoordinate = CLLocationCoordinate2D(latitude: element.latitude, longitude: element.longitude)
                            
                            let index = globeCoordinate.h3CellIndex(resolution: 1)
                            let hex = String(index, radix: 16, uppercase: true)
                            let neighbors = globeCoordinate.h3Neighbors(resolution: 1, ringLevel: 1)
                            var arr = [String]()
                            for item in neighbors {
                                arr.append(String(item, radix: 16, uppercase: true))
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                viewModel.handleGlobeTap(place: hex, neighbors: arr)
                            }
                        }, label: {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 20)).foregroundStyle(.blue)
                                Text("\(element.city), \(element.country)").foregroundStyle(.white)
                                    .font(.system(size: 18))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .truncationMode(.tail)
                                Spacer()
                                if searchModel.popularCities.contains(where: { $0.city == element.city }) {
                                    Text("popular").font(.caption).foregroundStyle(.purple)
                                } else {
                                    Text("(\(String(format: "%.1f", element.latitude)), \(String(format: "%.1f", element.longitude)))").font(.caption2).foregroundStyle(.purple)
                                }
                            }
                        })
                        if element.city != searchModel.searchResults.last?.city {
                            Divider().overlay(Color(UIColor.lightGray))
                        }
                    }
                }.padding()
            }.scrollIndicators(.hidden)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(18, corners: .allCorners)
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(Color.white, lineWidth: 2)
        }
        .frame(maxHeight: widthOrHeight(width: false) * 0.45)
        .padding(.horizontal).padding(.bottom)
    }
}
