import SwiftUI
import Combine
import Photos
import Firebase

enum FocusedField {
    case one, two
}

struct FinalPreview: View {
    var url: URL
    @Binding var showPreview: Bool
    
    @State var muted = false
    @State var savedPhoto = false
    @State var caption = ""
    @State var link = ""
    @State var point: CGFloat = 0.0
    @State var showKeyboard = false
    @State var showLinkAdd = false
    @State var showLocation = false
    @State var notNeeded = false
    
    @State var captionURL: String = ""
    @State var allURL = [URL]()
    @State var selectedURL: URL? = nil
    
    @State var selection = 0
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State var fetchingLocation = false
    
    @FocusState var focusField: FocusedField?
    @FocusState private var focusFieldSec: FocusedField?
    @EnvironmentObject var viewModel: GlobeViewModel
    @EnvironmentObject var searchModel: CitySearchViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    let manager = GlobeLocationManager()
    
    @State private var currentTime: Double = 0.0
    @State private var totalLength: Double = 1.0
    @State private var random: CGFloat = 0.0
    
    @State var infinite = false
    
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
                
                MainVideoPlayer(url: url, muted: $muted, currentTime: $currentTime, totalLength: $totalLength, canClose: false, offSetY: $random, playVid: $notNeeded, pauseVid: $notNeeded, shouldPlayAppear: true)
                    .offset(y: -(top_Inset() / 2))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .ignoresSafeArea(.keyboard)
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
                
                if !caption.isEmpty || showKeyboard {
                    VStack {
                        Spacer()
                        keyboardImage()
                            .offset(y: focusField == .one ? 0.0 : -point)
                            .gesture (
                                DragGesture()
                                    .onChanged { gesture in
                                        let screenH = widthOrHeight(width: false)
                                        let max = screenH * 0.83
                                        let min = screenH * 0.1
                                        let val = abs(gesture.location.y)
                                        if val > min && val < max {
                                            point = val
                                        }
                                    }
                                
                            )
                        
                    }
                }
                VStack {
                    HStack(alignment: .top){
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeIn(duration: 0.15)){
                                showPreview = false
                            }
                        
                        } label: {
                            ZStack {
                                Circle().frame(width: 47, height: 47).foregroundStyle(Color.black.opacity(0.7))
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 23))
                            }
                        }
                        Spacer()
                        VStack {
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
                                showLinkAdd.toggle()
                            } label: {
                                ZStack {
                                    Circle().frame(width: 47, height: 47).foregroundStyle(Color.black.opacity(0.7))
                                    Image(systemName: "paperclip")
                                        .foregroundColor(selectedURL == nil ? .white : .green)
                                        .font(.system(size: 23))
                                }
                            }.padding(.top, 4)
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                muted.toggle()
                            } label: {
                                ZStack {
                                    Circle().frame(width: 47, height: 47).foregroundStyle(Color.black.opacity(0.7))
                                    Image(systemName: muted ? "speaker.slash" : "speaker.wave.2")
                                        .foregroundColor(.white).font(.system(size: 23))
                                }
                            }.padding(.top)
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
                            }.padding(.top)
                            Spacer()
                        }
                    }.padding(.horizontal, 20).padding(.top, 70)
                    Spacer()
                    ZStack(alignment: .top){
                        Rectangle().cornerRadius(30, corners: [.topLeft, .topRight]).foregroundStyle(.ultraThinMaterial)
                        HStack(spacing: 5){
                            Button {
                                if !savedPhoto {
                                    savedPhoto = true
                                    
                                    PHPhotoLibrary.shared().performChanges({
                                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.url)
                                    }) { saved, error in }
                                    
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                    if savedPhoto {
                                        Image(systemName: "checkmark.icloud")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 20)).bold()
                                    } else {
                                        Image(systemName: "square.and.arrow.down")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 20)).bold()
                                            .offset(y: -3)
                                    }
                                }
                            }.frame(width: 45)
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showLocation.toggle()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                    Text("My Location")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 18)).bold()
                                }
                            }
                            Button {
                                if viewModel.currentLocation == nil {
                                    showLocation = true
                                } else {
                                    if let user = auth.currentUser {
                                        showPreview = false
                                        presentationMode.wrappedValue.dismiss()
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        
                                        let size = widthOrHeight(width: false)
                                        let pos = (size - point) / size
                                        let url = selectedURL?.absoluteString
                                        
                                        let postID = "\(UUID())"
                                        viewModel.uploadStoryVideo(caption: caption, captionPos: pos, link: url, videoURL: self.url, id: postID, uid: user.id ?? "", username: user.username, userphoto: user.profileImageUrl, muted: muted, infinite: infinite == true ? true : nil, optionalLoc: nil)
                                        
                                        profile.addedStoriesVideos.append((postID, self.url.absoluteString))
                                        if let x = profile.users.firstIndex(where: { $0.user.id == user.id }) {
                                            let new = Story(id: postID, uid: user.id ?? "", username: user.username, profilephoto: user.profileImageUrl, long: viewModel.currentLocation?.long ?? 0.0, lat: viewModel.currentLocation?.lat ?? 0.0, text: caption.isEmpty ? nil : caption, textPos: pos, timestamp: Timestamp(), link: url, geoHash: "")
                                            if profile.users[x].stories != nil {
                                                profile.users[x].stories?.append(new)
                                            }
                                        }
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    }
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 50).foregroundStyle(.blue.opacity(0.6))
                                    HStack {
                                        Text("Add Story")
                                            .font(.system(size: 18)).bold()
                                        Image(systemName: "arrowtriangle.right.fill")
                                            .font(.system(size: 16)).bold()
                                    }.foregroundStyle(.white)
                                }
                            }
                        }.frame(height: 40).padding(6).padding(.horizontal)
                    }.frame(height: 95)
                }.ignoresSafeArea()
            }
            .disabled(showLinkAdd || showLocation)
            if showLinkAdd {
                linkView()
            }
            if showLocation {
                currentLocation()
            }
        }.background(.black)
    }
    func currentLocation() -> some View {
        ZStack {
            Rectangle().foregroundStyle(.ultraThickMaterial).ignoresSafeArea()
            VStack(spacing: 0){
                HStack {
                    Button(action: {
                        withAnimation {
                            selection = 0
                        }
                    }, label: {
                        HStack(spacing: 3){
                            Text("Current Location").foregroundStyle(colorScheme == .dark ? .white : .black)
                            Image(systemName: "mappin.and.ellipse").foregroundStyle(.gray)
                        }
                    })
                    Spacer()
                    Button(action: {
                        withAnimation {
                            selection = 1
                        }
                    }, label: {
                        HStack(spacing: 3){
                            Text("Input Location").foregroundStyle(colorScheme == .dark ? .white : .black)
                            Image(systemName: "globe").foregroundStyle(.gray)
                        }
                    })
                }.font(.system(size: 17)).bold().padding(.horizontal)
                ZStack {
                    Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray).padding(.top, 8)
                    HStack {
                        if selection == 1 {
                            Spacer()
                        }
                        Rectangle()
                            .frame(width: widthOrHeight(width: true) * 0.5, height: 3).foregroundStyle(.blue).offset(y: 3)
                            .animation(.easeInOut, value: selection)
                        if selection == 0 {
                            Spacer()
                        }
                    }
                }
                TabView(selection: $selection) {
                    VStack {
                        HStack(spacing: 50){
                            Spacer()
                            VStack {
                                Text("Latitude").font(.subheadline)
                                    .foregroundStyle(.gray)
                                Text(String(format: "%.2f", viewModel.currentLocation?.lat ?? 0.0))
                                    .foregroundStyle(.white).font(.title3).bold()
                                    .padding().background(.gray).cornerRadius(15, corners: .allCorners)
                            }
                            VStack {
                                Text("Longitude").font(.subheadline)
                                    .foregroundStyle(.gray)
                                Text(String(format: "%.2f", viewModel.currentLocation?.long ?? 0.0))
                                    .foregroundStyle(.white).font(.title3).bold()
                                    .padding().background(.gray).cornerRadius(15, corners: .allCorners)
                            }
                            Spacer()
                        }
                        
                        if fetchingLocation {
                            CirclesExpand()
                        } else if viewModel.currentLocation != nil {
                            foundView()
                        } else {
                            locateView()
                        }
                        
                        Spacer()
                        
                        if viewModel.currentLocation != nil {
                            Button {
                                fetchingLocation = true
                                manager.requestLocation() { place in
                                    if !place.0.isEmpty && !place.1.isEmpty && (place.2 != 0.0 || place.3 != 0.0){
                                        fetchingLocation = false
                                        viewModel.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                                    }
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .foregroundStyle(.blue)
                                    Text("Relocate").font(.title3).bold().foregroundStyle(.white)
                                }.frame(width: 135, height: 40)
                            }.padding(.bottom, 30).disabled(fetchingLocation)
                        }
                    }.padding(.top, 60).tag(0)
                    VStack {
                        ZStack {
                            TextField("Find a place", text: $searchModel.searchQuery)
                                .tint(.blue)
                                .autocorrectionDisabled(true)
                                .padding(15)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 24)
                                .padding(.trailing, 14)
                                .background(Color(.systemGray4))
                                .cornerRadius(20)
                                .onChange(of: searchModel.searchQuery) { _ in
                                    searchModel.sortSearch()
                                }
                                .onReceive (
                                    searchModel.$searchQuery
                                        .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
                                ) {
                                    guard !$0.isEmpty else { return }
                                    searchModel.performSearch()
                                }
                                .overlay (
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.gray)
                                            .padding(.leading, 8)
                                        Spacer()
                                        if searchModel.searching {
                                            ProgressView().scaleEffect(1.25).padding(.trailing, 8)
                                        } else {
                                            Button(action: {
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                showLocation.toggle()
                                                searchModel.searchQuery = ""
                                            }, label: {
                                                ZStack {
                                                    Circle().frame(width: 40, height: 40).foregroundStyle(Color.black.opacity(0.7))
                                                    Image(systemName: "mappin.and.ellipse")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 23))
                                                }
                                            }).padding(.trailing, 8)
                                        }
                                    }
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, top_Inset())
                        .ignoresSafeArea()
                        
                        ScrollView {
                            VStack(spacing: 10){
                                ForEach(searchModel.searchResults){ element in
                                    Button(action: {
                                        if !element.city.isEmpty && !element.country.isEmpty && (element.latitude != 0.0 || element.longitude != 0.0) {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            fetchingLocation = false
                                            viewModel.currentLocation = myLoc(country: element.country, state: "", city: element.city, lat: element.latitude, long: element.longitude)
                                            withAnimation(.easeIn(duration: 0.2)){
                                                selection = 0
                                            }
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }
                                    }, label: {
                                        HStack {
                                            Image(systemName: "globe")
                                                .font(.system(size: 20)).foregroundStyle(.blue)
                                            Text("\(element.city), \(element.country)").foregroundStyle(.white)
                                                .font(.system(size: 18))
                                            Spacer()
                                            Text("(\(String(format: "%.1f", element.latitude)), \(String(format: "%.1f", element.longitude)))").font(.caption2).foregroundStyle(.purple)
                                        }
                                    })
                                    if element.city != searchModel.searchResults.last?.city {
                                        Divider().overlay(Color(UIColor.lightGray))
                                    }
                                }
                            }.padding().padding(.horizontal, 5)
                        }.scrollIndicators(.hidden)
                    }
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }.padding(.top)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        searchModel.searchQuery = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showLocation = false
                    } label: {
                        Image(systemName: "xmark").font(.title2).padding(12).foregroundStyle(.white)
                            .background(.black).clipShape(Circle())
                    }.padding(30)
                }
            }
        }
    }
    func foundView() -> some View {
        ZStack {
            ForEach(2..<6) { index in
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .opacity(1.0 - CGFloat(index) * 0.1)
                    .frame(width: (120 + CGFloat(index) * CGFloat(index) * 7), height: (120 + CGFloat(index) * CGFloat(index) * 7))
            }
            VStack(spacing: 3){
                Image(systemName: "mappin.and.ellipse").bold()
                Text("\(viewModel.currentLocation?.city ?? "---")").minimumScaleFactor(0.6).lineLimit(1).bold()
                if let state = viewModel.currentLocation?.state, !state.isEmpty {
                    Text(state).minimumScaleFactor(0.6).lineLimit(1).bold()
                }
                Text("\(viewModel.currentLocation?.country ?? "---")").minimumScaleFactor(0.6).lineLimit(1).bold()
            }.offset(y: -15).frame(maxWidth: 120)
        }.padding(.top, 50)
    }
    func locateView() -> some View {
        ZStack {
            ForEach(2..<6) { index in
                Circle()
                    .stroke(Color.gray, lineWidth: 3)
                    .opacity(1.0 - CGFloat(index) * 0.1)
                    .frame(width: (120 + CGFloat(index) * CGFloat(index) * 7), height: (120 + CGFloat(index) * CGFloat(index) * 7))
            }
            Button {
                fetchingLocation = true
                manager.requestLocation() { place in
                    if !place.0.isEmpty && !place.1.isEmpty && (place.2 != 0.0 || place.3 != 0.0){
                        fetchingLocation = false
                        viewModel.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                    }
                }
            } label: {
                ZStack {
                    Circle().frame(width: 100, height: 100).foregroundStyle(.blue)
                    Text("Locate me").foregroundStyle(.white).font(.subheadline).bold()
                }
            }
        }.padding(.top, 50)
    }
    func linkView() -> some View {
        ZStack {
            Rectangle().foregroundStyle(.ultraThickMaterial).ignoresSafeArea()
            VStack {
                ZStack {
                    TextField("Paste a URL", text: $captionURL)
                        .focused($focusFieldSec, equals: .one)
                        .tint(.blue)
                        .autocorrectionDisabled(true)
                        .padding(15)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 24)
                        .padding(.trailing, 14)
                        .background(Color(.systemGray4))
                        .cornerRadius(20)
                        .overlay (
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 8)
                                Spacer()
                                Button(action: {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    focusFieldSec = .two
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation {
                                        showLinkAdd.toggle()
                                    }
                                }, label: {
                                    ZStack {
                                        Circle().frame(width: 40, height: 40).foregroundStyle(Color.black.opacity(0.7))
                                        Image(systemName: "paperclip")
                                            .foregroundColor(.white)
                                            .font(.system(size: 23))
                                    }
                                }).padding(.trailing, 8)
                            }
                        )
                        .onChange(of: captionURL) { newValue in
                            if let url = checkForFirstUrl(text: captionURL) {
                                allURL.insert(url, at: 0)
                                allURL = removeSubURLs(allURL)
                            }
                        }
                }
                .padding(.horizontal)
                .padding(.top, top_Inset())
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 10){
                        ForEach(allURL, id: \.self){ url in
                            Button {
                                if selectedURL == url {
                                    selectedURL = nil
                                } else {
                                    selectedURL = url
                                }
                            } label: {
                                MainPreviewLink(url: url, message: false)
                                    .disabled(true)
                                    .padding()
                                    .background(selectedURL == url ? Color.blue : Color(UIColor.lightGray))
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                        }
                    }.padding(.top)
                }.scrollIndicators(.hidden).ignoresSafeArea()
                Spacer()
                if selectedURL != nil {
                    HStack {
                        Spacer()
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation {
                                showLinkAdd.toggle()
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: 140, height: 45)
                                    .foregroundStyle(.blue).opacity(0.8)
                                Text("Add Link").font(.title2).bold().foregroundStyle(.white)
                            }
                        }
                        Spacer()
                    }.padding(.bottom)
                }
            }
            .onAppear {
                focusFieldSec = .one
            }
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
                .onChange(of: caption) { newValue in
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
