import SwiftUI
import MapKit
import Kingfisher

struct MapFeedView: View {
    @State var pictrue: String = "city1"
    @State var showSheet: Bool = true
    @State var sheetFull: CGFloat = .zero
    @Binding var loc: myLoc?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State var selectedDetent: PresentationDetent = .fraction(0.8)
    @EnvironmentObject var viewModel: FeedViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var globeModel: GlobeViewModel
    @EnvironmentObject var auth: AuthViewModel
    @State var top: Bool = true
    @State var addPadding: Bool = false
    @State var offset: CGFloat = 0.0
    @State var currentAudio: String = ""
    @Namespace private var animation
    @State var isExpanded: Bool = false
    @State var openUID: String = ""
    @State var showProfile: Bool = false
    @State var showChat: Bool = false
    @State var active: Bool = true
    @Namespace private var newsAnimation
    
    var body: some View {
        ZStack {
            MapViewSec(coordinate: CLLocationCoordinate2DMake(loc?.lat ?? 45.5173, loc?.long ?? -122.6836))
                .overlay {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if let loc = loc {
                            let coordinate = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.long)

                            let index = coordinate.h3CellIndex(resolution: 1)
                            let hex = String(index, radix: 16, uppercase: true)
                            let neighbors = coordinate.h3Neighbors(resolution: 1, ringLevel: 1)
                            var arr = [String]()
                            for item in neighbors {
                                arr.append(String(item, radix: 16, uppercase: true))
                            }
                            globeModel.handleGlobeTap(place: hex, neighbors: arr)
                        }
                    } label: {
                        ZStack {
                            Circle().foregroundStyle(.white)
                                .frame(width: 78, height: 78)
                            Triangle().foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .rotationEffect(.degrees(180))
                                .offset(y: 56)
                                .scaleEffect(y: 0.7)
                            let mid = "showMainStories"
                            let size = isExpanded && profile.mid == mid ? 250.0 : 70.0
                            GeometryReader { _ in
                                Image(pictrue)
                                       .resizable()
                                       .aspectRatio(contentMode: .fill)
                                       .frame(width: size, height: size)
                                       .clipShape(Circle())
                                       .opacity(isExpanded && profile.mid == mid ? 0.0 : 1.0)
                            }
                            .matchedGeometryEffect(id: mid, in: animation, anchor: .center)
                            .frame(width: 70, height: 70)
                        }
                    }.offset(y: -35.0)
                }
                .padding(.bottom, sheetFull - 75.0)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.2), value: sheetFull)
            if !isExpanded {
                VStack {
                    ZStack {
                        HStack {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                                popRoot.currentAudio = popRoot.tempCurrentAudio
                                popRoot.tempCurrentAudio = ""
                            }, label: {
                                Image(systemName: "xmark").font(.headline)
                                    .padding(12)
                                    .background(colorScheme == .dark ? .black : .white)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .clipShape(Circle())
                            })
                            Spacer()
                        }.padding(.leading)
                        if globeModel.searching {
                            HStack {
                                Spacer()
                                HStack(spacing: 5){
                                    ProgressView()
                                        .tint(.gray)
                                        .foregroundStyle(.gray)
                                    Text("Loading...").font(.headline)
                                }
                                .padding(8)
                                .background(colorScheme == .dark ? .black : .white)
                                .clipShape(Capsule())
                                Spacer()
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.easeInOut, value: globeModel.searching)
                        }
                    }
                    Spacer()
                }.padding(.top, addPadding ? top_Inset() : 0.0).transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showProfile) {
            ProfileView(showSettings: false, showMessaging: true, uid: openUID, photo: "", user: nil, expand: true, isMain: false).dynamicTypeSize(.large).enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $showChat) {
            MessagesView(exception: false, user: nil, uid: openUID, tabException: true, canCall: true).enableFullSwipePop(true)
        }
        .overlay {
            if isExpanded {
                MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: profile.mid, isHome: false, canOpenChat: true, canOpenProfile: true, openChat: { uid in
                    openUID = uid
                    showChat = true
                }, openProfile: { uid in
                    openUID = uid
                    showProfile = true
                })
                .transition(.scale)
                .onAppear(perform: {
                    withAnimation(.easeInOut(duration: 0.3)){
                        sheetFull = .zero
                        globeModel.searching = false
                    }
                    popRoot.currentAudio = ""
                    addPadding = true
                })
                .onDisappear {
                    if !showProfile && !showChat {
                        showSheet = true
                    }
                    addPadding = false
                    if !showChat {
                        withAnimation(.easeInOut(duration: 0.15)){
                            popRoot.hideTabBar = false
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(edges: addPadding ? .all : [])
        .onChange(of: globeModel.showMainStories, { _, _ in
            DispatchQueue.main.async {
                showSheet = false
                profile.selectedStories = globeModel.currentStory
                profile.mid = "showMainStories"
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15){
                    withAnimation(.easeInOut(duration: 0.15)){
                        popRoot.hideTabBar = true
                        self.isExpanded = true
                    }
                }
            }
            active = true
        })
        .onChange(of: globeModel.couldntFindContent, { _, _ in
            active = false
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        })
        .onAppear {
            let rand = "city" + String(Int.random(in: 1...6))
            pictrue = rand
            showSheet = true
        }
        .onDisappear(perform: {
            showSheet = false
        })
        .sheet(isPresented: $showSheet, content: {
            sheetView()
                .presentationDetents([.height(200), .fraction(0.8), .large], selection: $selectedDetent)
                .presentationCornerRadius(40)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.8)))
        })
    }
    func sheetView() -> some View {
        GeometryReader(content: { geometry in
            ZStack {
                if colorScheme == .dark {
                    Color.black
                } else {
                    Color.white
                }
                VStack {
                    HStack {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if let loc = loc {
                                let coordinate = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.long)

                                let index = coordinate.h3CellIndex(resolution: 1)
                                let hex = String(index, radix: 16, uppercase: true)
                                let neighbors = coordinate.h3Neighbors(resolution: 1, ringLevel: 1)
                                var arr = [String]()
                                for item in neighbors {
                                    arr.append(String(item, radix: 16, uppercase: true))
                                }
                                globeModel.handleGlobeTap(place: hex, neighbors: arr)
                            }
                        }, label: {
                            ZStack {
                                if globeModel.searching {
                                    LottieView(loopMode: .loop, name: "loadingStory")
                                        .scaleEffect(0.09)
                                        .frame(width: 50, height: 50)
                                } else {
                                    StoryRingView(size: 50, active: active, strokeSize: 2.0).scaleEffect(1.21)
                                }
                                Image(pictrue)
                                       .resizable().aspectRatio(contentMode: .fill)
                                       .frame(width: 50, height: 50).clipShape(Circle())
                            }
                        })
                        if let loc = loc {
                            Text("\(loc.city), \(loc.country)")
                                .font(.title3).bold()
                                .padding(.leading, 5)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        Spacer()
                    }.padding(.leading, 20).padding(.top, 20).padding(.trailing, 5)
                    HStack {
                        if let city = loc?.city, let country = loc?.country, let content = viewModel.locations.first(where: {$0.0 == "\(city), \(country)"})?.1.count {
                            let textC = content == 1 ? "post" : "posts"
                            Text("City - \(content) \(textC)").font(.headline)
                        } else {
                            Text("City - 391 posts").font(.headline)
                        }
                        Spacer()
                        MapFeedViewAdd(loc: loc)
                    }.padding(.leading, 20).padding(.top, 10).padding(.trailing, 18)
                    GeometryReader { geometry in
                        ScrollView {
                            LazyVStack {
                                HStack(spacing: 60){
                                    Button(action: {
                                        top = true
                                        if let city = loc?.city, let country = loc?.country {
                                            viewModel.sortTop(place: "\(city), \(country)")
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }, label: {
                                        Text("Top").font(.headline).bold()
                                    }).opacity(top ? 1.0 : 0.6)
                                    Button(action: {
                                        top = false
                                        if let city = loc?.city, let country = loc?.country {
                                            viewModel.sortRecent(place: "\(city), \(country)")
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }, label: {
                                        Text("Recent").font(.headline).bold()
                                    }).opacity(!top ? 1.0 : 0.6)
                                }.padding(.bottom, 10)
                                if let city = loc?.city, let country = loc?.country {
                                    if let content = viewModel.locations.first(where: {$0.0 == "\(city), \(country)"})?.1{
                                        if content.isEmpty {
                                            HStack {
                                                Spacer()
                                                VStack(spacing: 18){
                                                    Text("Be the first to post in \(city)...")
                                                        .gradientForeground(colors: [.blue, .purple])
                                                        .font(.headline).bold()
                                                    LottieView(loopMode: .playOnce, name: "nofound")
                                                        .scaleEffect(0.3)
                                                        .frame(width: 100, height: 100)
                                                }
                                                Spacer()
                                            }.padding(.top, 70)
                                        } else {
                                            ForEach(content) { element in
                                                TweetRowView(tweet: element, edit: false, canShow: false, canSeeComments: true, map: true, currentAudio: $currentAudio, isExpanded: $isExpanded, animationT: animation, seenAllStories: storiesLeftToView(otherUID: element.uid), isMain: true, showSheet: $showSheet, newsAnimation: newsAnimation)
                                                    .overlay(GeometryReader { proxy in
                                                        Color.clear
                                                            .onChange(of: offset, { _, _ in
                                                                let frame = proxy.frame(in: .global)
                                                                let bottomDistance = frame.minY - geometry.frame(in: .global).minY
                                                                let topDistance = geometry.frame(in: .global).maxY - frame.maxY
                                                                let diff = bottomDistance - topDistance
                                                                if let vid_id = element.videoURL {
                                                                    if bottomDistance < 0.0 && abs(bottomDistance) >= (frame.height / 2.0) {
                                                                        if popRoot.currentAudio == vid_id {
                                                                            popRoot.currentAudio = ""
                                                                        }
                                                                    } else if topDistance < 0.0 && abs(topDistance) >= (frame.height / 2.0) {
                                                                        if popRoot.currentAudio == vid_id {
                                                                            popRoot.currentAudio = ""
                                                                        }
                                                                    } else if abs(diff) < 140 && abs(diff) > -140 {
                                                                        popRoot.currentAudio = vid_id
                                                                    }
                                                                }
                                                            })
                                                    })
                                                if element != content.last {
                                                    Divider().overlay(.gray).padding(.bottom, 6).opacity(0.4)
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
                                } else {
                                    VStack {
                                        ForEach(0..<7){ i in
                                            LoadingFeed(lesson: "")
                                        }
                                    }.shimmering()
                                }
                            }
                            .background(GeometryReader {
                                Color.clear.preference(key: ViewOffsetKey.self,
                                                       value: -$0.frame(in: .named("scroll")).origin.y)
                            })
                            .onPreferenceChange(ViewOffsetKey.self) { value in
                                offset = value
                            }
                        }.scrollIndicators(.hidden)
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear(perform: {
                sheetFull = geometry.size.height
            })
            .onChange(of: geometry.size.height) { _, _ in
                sheetFull = geometry.size.height
            }
        })
        .interactiveDismissDisabled(true)
    }
    func storiesLeftToView(otherUID: String?) -> Bool {
        if let uid = auth.currentUser?.id, let otherUID {
            if otherUID == uid {
                return false
            }
            if let stories = profile.users.first(where: { $0.user.id == otherUID })?.stories {
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
}

struct MapViewSec: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        mapView.setCenter(self.coordinate, animated: true)
        
        let region = MKCoordinateRegion(center: self.coordinate, latitudinalMeters: 4500, longitudinalMeters: 4500)
        mapView.setRegion(region, animated: true)
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(circle: circle)
                circleRenderer.strokeColor = UIColor.black
                circleRenderer.fillColor = UIColor.green
                circleRenderer.lineWidth = 1.0
                return circleRenderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct MapFeedViewAdd: View {
    @EnvironmentObject var popRoot: PopToRoot
    @State var showNewTweetView: Bool = false
    @State var place: myLoc? = nil
    let loc: myLoc?
    @Environment(\.colorScheme) var colorScheme
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State var initialContent: uploadContent? = nil
    
    var body: some View {
        Button(action: {
            popRoot.tempCurrentAudio = popRoot.currentAudio
            popRoot.currentAudio = ""
            if let loc = loc {
                self.place = myLoc(country: loc.country, state: "", city: loc.city, lat: loc.lat, long: loc.long)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.showNewTweetView = true
        }, label: {
            Image(systemName: "plus").font(.headline)
                .padding(10)
                .background(Color.gray.opacity(0.4))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .clipShape(Circle())
        })
        .fullScreenCover(isPresented: $showNewTweetView, content: {
            NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent)
        })
    }
}
