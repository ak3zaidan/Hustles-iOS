import SwiftUI
import Kingfisher
import Firebase
import Combine
import UIKit

struct ExploreView: View, KeyboardReadable {
    let lightGen = UIImpactFeedbackGenerator(style: .light)
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var appeared = false
    @State private var scrollNow = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vModel: GroupViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mapFeed: FeedViewModel
    @EnvironmentObject var viewModel: ExploreViewModel
    @EnvironmentObject var globeModel: GlobeViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var videos: VideoModel
    @EnvironmentObject var stocks: StockViewModel
    @State var imageArray: [String] = ["final", "final2", "crypto", "invest", "drop", "ecom", "stock", "amazon", "service", "tech"]
    @State var titleArray: [String] = ["Sneakers", "Real Estate", "Crypto", "Investing", "DropShip", "eCommerce", "Stocks", "Amazon", "Services", "Tech"]
    @State var scaleArray: [Double] = [0.25, 0.18, 0.11, 0.14, 0.12, 0.16, 0.18, 0.12, 0.12, 0.26]
    @State private var offset: Double = 0
    @State private var canOne = true
    @State private var hstackSize: CGSize = .zero
    @State private var pos1: Int = 0
    @State private var id1: String = ""
    @Environment(\.scenePhase) var scenePhase
    
    enum FocusedField {
        case one, two
    }
    @FocusState private var focusField: FocusedField?

    @FocusState var isEditing

    @Namespace var namespace
    @State var scrollViewSize: CGSize = .zero
    @State var wholeSize: CGSize = .zero
    @State private var canTwo = true
    @State private var canThree = true
    @State private var canRefreshNew = true
    @State private var howLongToShow = true
    @State private var textScale = 1.0
    @State private var tag = ""
    @State private var target = ""
    @State private var keyBoardVisible = true
    @State private var showAnonymous = false
    @State private var includeUsername: Bool? = nil
    @State private var newOrTop = 0
    @State private var NewsOrStocks = 0
    let manager = GlobeLocationManager()
    @EnvironmentObject var searchModel: CitySearchViewModel
    @State var place: myLoc? = nil
    @State private var showLocation = false
    @State private var fetchingLocation = false
    @State private var showAI: Bool = false
    
    @State var showForward = false
    @State var sendString: String = ""
    @State var ShowAIPlace = false
    @State var showFixSheet = false
    @State var showAIText = false
    
    let newsAnimation: Namespace.ID
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                AllVideoView().frame(maxWidth: proxy.size.width).offset(y: popRoot.Explore_or_Video ? -widthOrHeight(width: false) : 0)
            }
            NavigationStack {
                ZStack {
                    VStack(alignment: .leading, spacing: 0){
                        if !viewModel.showSearch {
                            HStack {
                                headerButton()
                                Spacer()
                                Button {
                                    ShowAIPlace = true
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    ZStack {
                                        Capsule()
                                            .frame(width: 45, height: 32)
                                            .foregroundStyle(.gray.opacity(0.3))
                                        LottieView(loopMode: .loop, name: "finite")
                                            .scaleEffect(0.05)
                                            .frame(width: 22, height: 10)
                                    }
                                }.padding(.trailing, 15)
                            }
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                        groupSection().padding(.bottom, 8).id("groupSec")
                                        
                                        Section(header: mainMenu()) {
                                            newsAndStocks()
                                        }
                                    }
                                    .onChange(of: scrollNow) { _, _ in
                                        withAnimation { proxy.scrollTo("groupSec", anchor: .bottom) }
                                    }
                                }
                            }
                        }
                        searchContent()
                        Spacer()
                        searchStuff()
                    }
                }
            }.offset(y: popRoot.Explore_or_Video ? 0 : widthOrHeight(width: false))
        }
        .sheet(isPresented: $ShowAIPlace, content: {
            RecommendPlaceView()
        })
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendString)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .fullScreenCover(isPresented: $showAI, content: {
            BaseAIView()
        })
        .onChange(of: popRoot.tap, { _, _ in
            if popRoot.tap == 3 && appeared {
                scrollNow.toggle()
                popRoot.tap = 0
            }
        })
        .fullScreenCover(isPresented: $showLocation, content: {
            MapFeedView(loc: $place)
        })
        .onDisappear {
            appeared = false
        }
        .onAppear {
            appeared = true
            vModel.currentGroup = nil
            if viewModel.news.isEmpty {
                viewModel.start()
            }
            if let all = authViewModel.currentUser?.groupIdentifier, !all.isEmpty && (viewModel.userGroup ?? []).isEmpty {
                viewModel.getUserGroupCover(userGroupId: all)
            }
            if !(authViewModel.currentUser?.pinnedGroups.isEmpty ?? false) && viewModel.joinedGroups.isEmpty {
                viewModel.getUserJoinedGroupCovers(groupIds: authViewModel.currentUser?.pinnedGroups ?? [])
            }
            Timer.scheduledTimer(withTimeInterval: 12.0, repeats: true) { _ in
                if scenePhase == .active && NewsOrStocks == 1 {
                    stocks.refreshAllStock()
                }
            }
        }
        .onChange(of: authViewModel.currentUser?.id) { _, _ in
            if let all = authViewModel.currentUser?.groupIdentifier, !all.isEmpty && (viewModel.userGroup ?? []).isEmpty {
                viewModel.getUserGroupCover(userGroupId: all)
            }
            if !(authViewModel.currentUser?.pinnedGroups.isEmpty ?? false) && viewModel.joinedGroups.isEmpty {
                viewModel.getUserJoinedGroupCovers(groupIds: authViewModel.currentUser?.pinnedGroups ?? [])
            }
        }
        .onChange(of: id1) { _, _ in
            lightGen.impactOccurred()
        }
        .onChange(of: pos1) { _, _ in
            lightGen.impactOccurred()
        }
        .alert("Only 1 opinion per category is allowed", isPresented: $viewModel.showOnlyOne) {
            Button("Cancel", role: .cancel) { }
        }
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
            keyBoardVisible = newIsKeyboardVisible
        }
    }
    func gOptions() -> some View {
        VStack(spacing: 10){
            if let user = authViewModel.currentUser, user.elo >= 600 || user.groupIdentifier == nil {
                NavigationLink {
                    CreateGroupView()
                } label: {
                    ZStack {
                        Circle().foregroundStyle(.gray).opacity(0.4).frame(width: 50, height: 50)
                        Image(systemName: "lock.open").foregroundStyle(.green).font(.headline)
                    }
                }
            } else {
                ZStack {
                    Circle().foregroundStyle(.gray).opacity(0.4).frame(width: 50, height: 50)
                    Image(systemName: "lock").foregroundStyle(.green).font(.headline)
                }
            }
            NavigationLink {
                SearchGroupsView()
            } label: {
                ZStack {
                    Circle().foregroundStyle(.gray).opacity(0.4).frame(width: 50, height: 50)
                    Image(systemName: "magnifyingglass").foregroundStyle(.green).font(.headline)
                }
            }
        }.padding(.trailing, 10)
    }
    @ViewBuilder
    func searchStuff() -> some View {
        HStack(alignment: .center){
            Spacer()
            ZStack(alignment: .trailing){
                SearchBar(text: $viewModel.searchText, fill: viewModel.selectedSearch == 0 ? "Users" : viewModel.selectedSearch == 1 ? "Groups" : viewModel.selectedSearch == 2 ? "Tickers" : "Places")
                    .padding(.horizontal, 4)
                    .submitLabel(.search)
                    .focused($focusField, equals: .one)
                    .padding(.bottom, 5)
                    .frame(width: widthOrHeight(width: true) * 0.76)
                    .onSubmit {
                        viewModel.noResults = false
                        stocks.noResults = false
                        if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            if viewModel.selectedSearch == 0 {
                                viewModel.UserSearch(userId: authViewModel.currentUser?.id ?? "")
                                viewModel.showSearch = true
                            } else if viewModel.selectedSearch == 1 {
                                viewModel.GroupSearch()
                                viewModel.showSearch = true
                            } else if viewModel.selectedSearch == 2 {
                                stocks.showSearchLoader = true
                                stocks.searchCoins(query: viewModel.searchText)
                                viewModel.showSearch = true
                            } else {
                                viewModel.showSearch = true
                                searchModel.performCustomSearch(query: viewModel.searchText)
                            }
                        }
                    }
                    .onChange(of: viewModel.searchText) { _, _ in
                        viewModel.noResults = false
                        stocks.noResults = false
                        if viewModel.selectedSearch == 0 {
                            viewModel.UserSearchBestFit()
                            if !viewModel.matchedU.isEmpty {
                                viewModel.showSearch = true
                            } else { viewModel.showSearch = false }
                        } else if viewModel.selectedSearch == 1 {
                            viewModel.GroupSearchBestFit()
                            if !viewModel.matchedG.isEmpty {
                                viewModel.showSearch = true
                            } else { viewModel.showSearch = false }
                        } else if viewModel.selectedSearch == 2 {
                            stocks.matched = stocks.sortStocks(arr: stocks.matched, query: viewModel.searchText)
                            if !viewModel.searchText.isEmpty {
                                viewModel.showSearch = true
                            } else { viewModel.showSearch = false }
                        } else {
                            viewModel.showSearch = true
                            searchModel.sortCustomSearch(searchSTR: viewModel.searchText)
                        }
                    }
                    .onChange(of: NewsOrStocks) { _, _ in
                        if NewsOrStocks == 1 {
                            viewModel.selectedSearch = 2
                        } else {
                            viewModel.selectedSearch = 0
                        }
                    }
                if viewModel.searchText != "" {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.searchText = ""
                        focusField = .two
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "xmark").padding(.trailing).padding(.bottom, 3)
                    }
                }
            }
            Button {
                viewModel.noResults = false
                stocks.noResults = false
                impactFeedbackgenerator.impactOccurred()
                if viewModel.selectedSearch == 0 {
                    viewModel.selectedSearch = 1
                    viewModel.GroupSearchBestFit()
                    if !viewModel.matchedG.isEmpty {
                        viewModel.showSearch = true
                    } else { viewModel.showSearch = false }
                } else if viewModel.selectedSearch == 1 {
                    viewModel.selectedSearch = 2
                    stocks.matched = stocks.sortStocks(arr: stocks.matched, query: viewModel.searchText)
                    if !stocks.matched.isEmpty && !viewModel.searchText.isEmpty {
                        viewModel.showSearch = true
                    } else { viewModel.showSearch = false }
                } else if viewModel.selectedSearch == 2 {
                    viewModel.selectedSearch = 3
                    viewModel.showSearch = true
                    if searchModel.searchResults.isEmpty {
                        searchModel.makeCityCanidates()
                    }
                } else {
                    viewModel.selectedSearch = 0
                    viewModel.UserSearchBestFit()
                    if !viewModel.matchedU.isEmpty {
                        viewModel.showSearch = true
                    } else { viewModel.showSearch = false }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5).fill(Color.gray.opacity(0.5))
                    if viewModel.selectedSearch == 0 {
                        Text("Users").font(.callout)
                    } else if viewModel.selectedSearch == 1 {
                        Text("Groups").font(.callout)
                    } else if viewModel.selectedSearch == 2 {
                        Text("Stocks").font(.callout)
                    } else {
                        Text("Places").font(.callout)
                    }
                }
            }.frame(width: 60, height: 30).padding(.bottom, 5)
            Spacer()
        }.padding(.bottom, focusField == .one ? 0 : 50)
    }
    @ViewBuilder
    func headerButton() -> some View {
        Button {
            popRoot.Hide_Video = false
            if videos.VideosToShow.isEmpty {
                videos.getBatch("")
            }
            withAnimation {
                popRoot.Explore_or_Video = false
            }
        } label: {
            HStack(spacing: 1){
                Text("Explore").font(.title).bold().padding(.leading)
                Image(systemName: "chevron.down").font(.body).bold()
            }.scaleEffect(textScale)
        }
        .onAppear {
            if popRoot.Explore_or_Video {
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                    withAnimation(.linear(duration: 0.1)){ textScale = 1.15 }
                }
                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    withAnimation(.linear(duration: 0.1)){ textScale = 1.0 }
                }
                Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                    withAnimation(.linear(duration: 0.1)){ textScale = 1.15 }
                }
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    withAnimation(.linear(duration: 0.1)){ textScale = 1.0 }
                }
            }
        }
    }
    @ViewBuilder
    func mainMenu() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .opacity(0.5)
            
            HStack {
                if NewsOrStocks == 1 {
                    Spacer()
                }
                TransparentBlurView(removeAllFilters: true)
                    .frame(width: 80, height: 40)
                    .blur(radius: 8, opaque: true)
                    .background(colorScheme == .dark ? .black.opacity(0.35) : .white.opacity(0.25))
                    .cornerRadius(13, corners: .allCorners)
                if NewsOrStocks == 0 || NewsOrStocks == 1 {
                    Spacer()
                }
            }.padding(.horizontal, 4).animation(.easeInOut, value: NewsOrStocks)
            
            HStack {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    NewsOrStocks = 0
                }, label: {
                    Text("News")
                        .foregroundStyle(.white)
                        .font(.headline).bold()
                })
                Spacer()
            }.padding(.leading, 20)
            HStack {
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    NewsOrStocks = 1
                }, label: {
                    Text("Markets")
                        .foregroundStyle(.white)
                        .font(.headline).bold()
                })
                Spacer()
            }
            HStack {
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    popRoot.Hide_Video = false
                    if videos.VideosToShow.isEmpty {
                        videos.getBatch("")
                    }
                    withAnimation {
                        popRoot.Explore_or_Video = false
                    }
                }, label: {
                    Text("Clips")
                        .foregroundStyle(.white)
                        .font(.headline).bold()
                })
            }.padding(.trailing, 20)
        }
        .frame(height: 45)
        .padding(.horizontal, 30).padding(.vertical, 8)
        .background(colorScheme == .dark ? .black : .white)
    }
    @ViewBuilder
    func newsAndStocks() -> some View {
        VStack {
            if NewsOrStocks == 0 {
                ForEach(viewModel.news) { news in
                    let mid = (news.id ?? "") + "feed"
                    
                    if !popRoot.isNewsExpanded || popRoot.newsMid != mid {
                        NewsRowView(news: news, isRow: false)
                            .matchedGeometryEffect(id: mid, in: newsAnimation)
                            .onTapGesture(perform: {
                                popRoot.selectedNewsID = news.id ?? "NANID"
                                popRoot.newsMid = mid
                                withAnimation(.easeInOut(duration: 0.25)){
                                    popRoot.isNewsExpanded = true
                                }
                            })
                            .padding(.horizontal, 10)
                    } else {
                        NewsRowView(news: news, isRow: false).opacity(0.0).disabled(true)
                    }
                }
                if viewModel.news.count <= 1 {
                    VStack {
                        ForEach(0..<4) { _ in
                            HStack {
                                Spacer()
                                LoadingNews().padding(.horizontal, 10)
                                Spacer()
                            }
                        }
                    }.shimmering()
                }
            } else {
                LazyVStack(alignment: .leading, spacing: 0){
                    if stocks.coins.isEmpty {
                        LoadingStocks()
                    } else {
                        ForEach(stocks.coins){ coin in
                            NavigationLink {
                                AllStockView(symbol: coin.symbol, name: coin.name, selected: .constant(nil), isSheet: false)
                            } label: {
                                let isSaved = stocks.savedStocks.contains(where: { $0.1.uppercased() == coin.symbol.uppercased() })
                                
                                StockRowView(coin: coin, isHoliday: stocks.holiday.0, isSaved: isSaved) { ticker in
                                    popRoot.alertReason = "\(ticker) copied"
                                    popRoot.alertImage = "link"
                                    withAnimation {
                                        popRoot.showAlert = true
                                    }
                                }
                            }
                            .contextMenu {
                                Button {
                                    sendString = "$\(coin.symbol.uppercased())"
                                    showForward = true
                                } label: {
                                    Label("Share", systemImage: "paperplane")
                                }
                                Button {
                                    popRoot.alertReason = "\(coin.symbol.uppercased()) copied"
                                    popRoot.alertImage = "link"
                                    withAnimation {
                                        popRoot.showAlert = true
                                    }
                                    UIPasteboard.general.string = "$\(coin.symbol.uppercased())"
                                } label: {
                                    Label("Copy asset symbol", systemImage: "link")
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    stocks.startStocks()
                    if !stocks.coins.isEmpty {
                        if stocks.holiday.0 {
                            stocks.verifyHoliday()
                        }
                    }
                }
            }
            HStack(spacing: 10){
                Spacer()
                Button {
                    showAI = true
                } label: {
                    AIButton()
                }
                Spacer()
                TrackStockButton()
                Spacer()
                RandomChat()
                Spacer()
            }.padding(.horizontal).padding(.top, 10)
        }
        .background(colorScheme == .dark ? .black : .white)
    }
    @ViewBuilder
    func searchContent() -> some View {
        VStack(alignment: .leading, spacing: 0){
            if viewModel.showSearch {
                HStack {
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.showSearch = false
                        viewModel.noResults = false
                        viewModel.searchText = ""
                        stocks.noResults = false
                    } label: {
                        Image(systemName: "xmark").resizable().frame(width: 25, height:25)
                    }.padding(.trailing, 25)
                }.padding(.top)
                if (viewModel.noResults && viewModel.selectedSearch != 2) {
                    VStack {
                        Spacer()
                        HStack{
                            Spacer()
                            Text("No results found").font(.subheadline).bold()
                            Spacer()
                        }
                        Spacer()
                    }
                } else if (viewModel.matchedU.isEmpty && viewModel.selectedSearch == 0) || (viewModel.matchedG.isEmpty && viewModel.selectedSearch == 1) {
                    VStack {
                        Spacer()
                        HStack{
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        Spacer()
                    }
                } else {
                    if viewModel.selectedSearch == 0 {
                        ScrollView {
                            LazyVStack(spacing: 12){
                                ForEach(viewModel.matchedU){ user in
                                    HStack {
                                        NavigationLink {
                                            ProfileView(showSettings: false, showMessaging: false, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: false, isMain: false)
                                        } label: {
                                            HStack(spacing: 10){
                                                if let image = user.profileImageUrl {
                                                    KFImage(URL(string: image))
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 46, height: 46)
                                                        .clipShape(Circle())
                                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                                } else {
                                                    ZStack(alignment: .center){
                                                        Image(systemName: "circle.fill")
                                                            .resizable()
                                                            .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                                                            .frame(width: 46, height: 46)
                                                        Image(systemName: "questionmark")
                                                            .resizable()
                                                            .foregroundColor(.white)
                                                            .frame(width: 14, height: 19)
                                                    }
                                                }
                                                Text("@\(user.username)").font(.subheadline).bold()
                                            }
                                        }
                                        Spacer()
                                        NavigationLink{
                                            MessagesView(exception: false, user: user, uid: user.id ?? "", tabException: true, canCall: true)
                                                .onAppear {
                                                    withAnimation {
                                                        self.popRoot.hideTabBar = true
                                                    }
                                                }
                                        } label: {
                                            Image(systemName: "paperplane.fill")
                                                .font(.title3)
                                                .foregroundColor(.gray)
                                                .padding(6)
                                                .padding(.vertical, 2)
                                                .overlay(Circle().stroke(Color.gray,lineWidth: 0.75))
                                        }
                                    }.padding(.vertical, 4)
                                }
                            }.padding(.top, 10).padding()
                        }
                    } else if viewModel.selectedSearch == 1 {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 60) {
                                ForEach(viewModel.matchedG){ group in
                                    NavigationLink {
                                        GroupView(group: group, imageName: "", title: "", remTab: true, showSearch: true)
                                    } label: {
                                        GroupFindRow(group: group)
                                    }
                                }
                            }.padding(.vertical, 30).padding()
                        }
                    } else if viewModel.selectedSearch == 2 {
                        ScrollView {
                            LazyVStack(spacing: 12){
                                if stocks.noResults {
                                    HStack{
                                        Spacer()
                                        Text("No results found").font(.subheadline).bold()
                                        Spacer()
                                    }
                                }
                                if stocks.showSearchLoader {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                }
                                stockFinds(arr: stocks.matched)
                            }.padding()
                        }.padding(.top, 10)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20){
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if let curr = globeModel.currentLocation {
                                        self.place = curr
                                        self.showLocation = true
                                    } else {
                                        fetchingLocation = true
                                        manager.requestLocation() { place in
                                            if !place.0.isEmpty && !place.1.isEmpty && (place.2 != 0.0 || place.3 != 0.0){
                                                fetchingLocation = false
                                                let temp = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                                                globeModel.currentLocation = temp
                                                self.place = temp
                                                self.mapFeed.fetchLocation(city: place.0, country: place.1)
                                                self.showLocation = true
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.system(size: 25)).foregroundStyle(.blue)
                                        Text("Current Location").foregroundStyle(.white)
                                            .font(.system(size: 18)).bold()
                                        Spacer()
                                        if fetchingLocation {
                                            ProgressView()
                                        }
                                    }
                                    .padding(5)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                ForEach(searchModel.searchResults) { spot in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        self.place = myLoc(country: spot.country, state: "", city: spot.city, lat: spot.latitude, long: spot.longitude)
                                        self.mapFeed.fetchLocation(city: spot.city, country: spot.country)
                                        self.showLocation = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "globe")
                                                .font(.system(size: 25)).foregroundStyle(.blue)
                                            Text("\(spot.city), \(spot.country)").foregroundStyle(.white)
                                                .font(.system(size: 18)).bold()
                                                .lineLimit(1).minimumScaleFactor(0.7)
                                            Spacer()
                                            Text("(\(String(format: "%.1f", spot.latitude)), \(String(format: "%.1f", spot.longitude)))").font(.caption2).foregroundStyle(.purple)
                                        }
                                    }
                                }
                            }.padding()
                        }.padding(.top, 10)
                    }
                }
            }
        }
    }
    @ViewBuilder
    func groupSection() -> some View {
        GeometryReader { geometry in
            GeometryReader { geometry2 in
                ScrollView(.horizontal, showsIndicators: false){
                    LazyHStack(alignment: .bottom, spacing: 5){
                        ForEach(titleArray.indices, id: \.self){ i in
                            if i == 0 {
                                if authViewModel.currentUser?.groupIdentifier != nil {
                                    gOptions()
                                    if (viewModel.userGroup ?? []).isEmpty {
                                        DiscoverRowView(title: "", imageName: "", scale: 0.0)
                                    } else if let allMine = viewModel.userGroup {
                                        ForEach(allMine) { allsingle in
                                            NavigationLink{
                                                GroupView(group: allsingle, imageName: "", title: "", remTab: true, showSearch: true)
                                            } label: {
                                                DiscoverRowView(title: allsingle.title, imageName: allsingle.imageUrl, scale: 0.0)
                                            }
                                            .offset(y: allsingle.id == id1 ? -12 : 0)
                                            .overlay(GeometryReader { proxy in
                                                Color.clear
                                                    .onChange(of: offset, { _, _ in
                                                        let frame = proxy.frame(in: .global)
                                                        let leadingDistance = frame.minX - geometry2.frame(in: .global).minX
                                                        let trailingDistance = geometry2.frame(in: .global).maxX - frame.maxX
                                                        let diff1 = leadingDistance - trailingDistance
                                                        if abs(diff1) < 70 {
                                                            withAnimation(.easeInOut(duration: 0.3)){
                                                                id1 = allsingle.id
                                                                pos1 = -1
                                                            }
                                                        }
                                                    })
                                            })
                                        }
                                    }
                                } else {
                                    gOptions()
                                }
                                if let arr = authViewModel.currentUser?.pinnedGroups {
                                    if arr.count > 0 {
                                        if viewModel.joinedGroups.isEmpty {
                                            ForEach(arr.indices, id: \.self){ _ in
                                                DiscoverRowView(title: "", imageName: "", scale: 0.0)
                                            }
                                        } else {
                                            ForEach(viewModel.joinedGroups){ group in
                                                NavigationLink{
                                                    GroupView(group: group, imageName: "", title: "", remTab: true, showSearch: true)
                                                } label: {
                                                    DiscoverRowView(title: group.title, imageName: group.imageUrl, scale: 0.0)
                                                }
                                                .offset(y: group.id == id1 ? -12 : 0)
                                                .overlay(GeometryReader { proxy in
                                                    Color.clear
                                                        .onChange(of: offset, { _, _ in
                                                            let frame = proxy.frame(in: .global)
                                                            let leadingDistance = frame.minX - geometry2.frame(in: .global).minX
                                                            let trailingDistance = geometry2.frame(in: .global).maxX - frame.maxX
                                                            let diff1 = leadingDistance - trailingDistance
                                                            if abs(diff1) < 70 {
                                                                withAnimation(.easeInOut(duration: 0.3)){
                                                                    id1 = group.id
                                                                    pos1 = -1
                                                                }
                                                            }
                                                        })
                                                })
                                            }
                                        }
                                    }
                                }
                            }
                            NavigationLink{
                                GroupView(group: GroupX(id: "", title: "", imageUrl: "", members: [], membersCount: 0, publicstatus: true, leaders: [], desc: ""), imageName: imageArray[i], title: titleArray[i], remTab: true, showSearch: true)
                            } label: {
                                DiscoverRowView(title: titleArray[i], imageName: imageArray[i], scale: scaleArray[i])
                            }
                            .offset(y: i == pos1 ? -12 : 0)
                            .overlay(GeometryReader { proxy in
                                Color.clear
                                    .onChange(of: offset, { _, _ in
                                        let frame = proxy.frame(in: .global)
                                        let leadingDistance = frame.minX - geometry.frame(in: .global).minX
                                        let trailingDistance = geometry.frame(in: .global).maxX - frame.maxX
                                        let diff1 = leadingDistance - trailingDistance
                                        if abs(diff1) < 70 {
                                            withAnimation(.easeInOut(duration: 0.3)){
                                                pos1 = i
                                                id1 = ""
                                            }
                                        }
                                    })
                            })
                        }
                        ForEach(viewModel.exploreGroups){ group in
                            NavigationLink{
                                GroupView(group: group, imageName: "", title: "", remTab: true, showSearch: true)
                            } label: {
                                DiscoverRowView(title: group.title, imageName: group.imageUrl, scale: 0.0)
                            }
                            .offset(y: group.id == id1 ? -12 : 0)
                            .overlay(GeometryReader { proxy in
                                Color.clear
                                    .onChange(of: offset, { _, _ in
                                        let frame = proxy.frame(in: .global)
                                        let leadingDistance = frame.minX - geometry.frame(in: .global).minX
                                        let trailingDistance = geometry.frame(in: .global).maxX - frame.maxX
                                        let diff1 = leadingDistance - trailingDistance
                                        if abs(diff1) < 70 {
                                            withAnimation(.easeInOut(duration: 0.3)){
                                                id1 = group.id
                                                pos1 = -1
                                            }
                                        }
                                    })
                            })
                        }
                        if offset > 100 {
                            DiscoverRowView(title: "", imageName: "", scale: 0.0)
                        }
                    }
                    .background(GeometryReader { proxy in
                        Color.clear
                            .onChange(of: offset) { _, newValue in
                                hstackSize = proxy.size
                            }
                    })
                    .padding(.horizontal, 12)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self,
                                               value: -$0.frame(in: .named("scroll")).origin.x)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) { value in
                        offset = value
                        if value > 150 {
                            if offset > ((hstackSize.width - widthOrHeight(width: true)) - 250.0) {
                                if canOne {
                                    canOne = false
                                    viewModel.get10GroupCovers(groupId: authViewModel.currentUser?.groupIdentifier ?? [], joinedGroups: authViewModel.currentUser?.pinnedGroups ?? [])
                                    Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                        canOne = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }.frame(height: 130)
    }
    func stockFinds(arr: [SearchDisplay]) -> some View {
        ForEach(arr){ element in
            NavigationLink {
                AllStockView(symbol: element.symbol, name: element.displaySymbol, selected: .constant(nil), isSheet: false)
            } label: {
                HStack {
                    VStack(alignment: .leading){
                        HStack(spacing: 5){
                            Text(element.symbol).font(.system(size: 18))
                            if stocks.savedStocks.contains(where: { $0.0 == element.displaySymbol && $0.1 == element.symbol }) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 18))
                            }
                            Spacer()
                        }
                        Text(element.displaySymbol).frame(width: widthOrHeight(width: true) * 0.55, alignment: .leading).font(.system(size: 15)).foregroundStyle(.gray).lineLimit(1).truncationMode(.tail)
                    }
                    Spacer()
                    Text(element.type).font(.system(size: 15)).foregroundStyle(.gray)
                }
            }.padding(.vertical, 4)
            Divider().overlay(colorScheme == .dark ? Color(UIColor.lightGray) : .gray)
        }
    }
}

func formatNumber(number: Double) -> String {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    if number >= 1000000 {
        let formattedNumber = number / 1000000
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter.string(from: NSNumber(value: formattedNumber))! + "M"
    } else if number >= 1000 {
        let formattedNumber = number / 1000
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 1
        return numberFormatter.string(from: NSNumber(value: formattedNumber))! + "K"
    } else {
        return "\(Int(number))"
    }
}

protocol KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

extension KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}
