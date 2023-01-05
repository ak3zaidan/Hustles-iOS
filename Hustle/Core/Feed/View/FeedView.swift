import SwiftUI
import Kingfisher

struct TabModel2: Identifiable {
    private(set) var id: String
    var size: CGSize = .zero
    var minX: CGFloat = .zero
}

struct FeedView: View {
    @EnvironmentObject var viewModel: FeedViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var notifModel: MessageViewModel
    @EnvironmentObject var exploreModel: ExploreViewModel
    @EnvironmentObject var stocks: StockViewModel
    let manager = GlobeLocationManager()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    let generator = UINotificationFeedbackGenerator()
    
    @State private var glitchTrigger = true
    @State private var showNewTweetView = false
    @State private var fetchFollows = true
    @State private var offset: Double = 0
    @State private var lastOffset: Double = 0
    @State private var canROne = true
    @State private var canRTwo = true
    @State private var canRThree = true
    @State private var canRFour = true
    @State private var canRFive = true
    @State private var canRSix = true
    @State private var canOne = true
    @State private var canTwo = true
    @State private var canFour = true
    @State private var canSix = true
    @State var scrollViewSize: CGSize = .zero
    @State var headerHeight: CGFloat = 130
    @State var headerOffset: CGFloat = 0
    @State var lastHeaderOffset: CGFloat = 0
    @State var direction: SwipeDirection = .none
    @State var shiftOffset: CGFloat = 0
    @State var place: myLoc? = nil
    @State private var showRefreshButton = false
    @State private var scrollNow = true
    @State private var lastShowedRefresh: Date = Date(timeIntervalSince1970: 1585220555)
    @Binding var showMenu: Bool
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State var initialContent: uploadContent? = nil
    @State var currentAudio: String = ""
    @State private var tabs: [TabModel2] = [
        .init(id: "For you"),
        .init(id: "Following"),
        .init(id: "Markets"),
        .init(id: "News"),
        .init(id: "Lives"),
        .init(id: "Voices")
    ]
    @State private var activeTab: String = "For you"
    @State private var tabBarScrollState: String?
    @State private var progress: CGFloat = .zero
    @State private var isDragging: Bool = false
    @State private var delayTask: DispatchWorkItem?
    @State private var showStoryProfile = false
    @State private var showStoryChat = false
    @State private var storyUID = ""
    @Namespace private var animation
    @State var isExpanded: Bool = false
    @State var tempTest: Bool = false
    
    //for main story
    @Binding var storiesUidOrder: [String]
    @Binding var mutedStories: [String]
    @State var isMainExpanded: Bool = false
    @State var showCamera: Bool = false
    @Namespace private var animationMain
    @State var initialSend: messageSendType? = nil
    @State var refreshStories: Bool = false
    @State var tempMid: String = ""
    @Binding var noneFound: Bool
    @State var storySelection: String = ""
    @State var storiesUnseen: [(String, String, String, String)] = []
    
    let newsAnimation: Namespace.ID

    var body: some View {
        ZStack(alignment: .bottomTrailing){
            GeometryReader {
                let size = $0.size
                ScrollView(.init()){
                    TabView(selection: $activeTab) {
                        GeometryReader { geometry in
                            ScrollViewReader { proxy in
                                ScrollView {
                                    Rectangle()
                                        .fill(.clear)
                                        .frame(height: 80 + top_Inset())
                                        .offsetY { previous, current in
                                            if previous > current {
                                                if direction != .up && current < 0{
                                                    shiftOffset = current - headerOffset
                                                    direction = .up
                                                    lastHeaderOffset = headerOffset
                                                }
                                                if self.offset > 85 {
                                                    let offset = current < 0 ? (current - shiftOffset) : 0
                                                    withAnimation {
                                                        headerOffset = (-offset < headerHeight ? (offset < 0 ? offset : 0) : -headerHeight * 2.0)
                                                    }
                                                }
                                            } else {
                                                if direction != .down {
                                                    shiftOffset = current
                                                    direction = .down
                                                    lastHeaderOffset = headerOffset
                                                }
                                                let offset = lastHeaderOffset + (current - shiftOffset)
                                                withAnimation {
                                                    headerOffset = (offset > 0 ? 0 : offset)
                                                }
                                            }
                                        }
                                    ChildSizeReader(size: $scrollViewSize) {
                                        LazyVStack {
                                            Color.clear.frame(height: 1).id("scrolltop")
                                            
                                            MainStoryBottom(storiesUidOrder: $storiesUidOrder, isMainExpanded: $isMainExpanded, showCamera: $showCamera, mutedStories: $mutedStories, showProfile: $showStoryProfile, profileUID: $storyUID, refreshStories: $refreshStories, noneFound: $noneFound, selection: $storySelection, tempMid: $tempMid, storiesUnseen: $storiesUnseen, animation: animationMain).padding(.top, 3)
                                            
                                            if viewModel.new.isEmpty {
                                                LazyVStack {
                                                    ForEach(0..<7){ i in
                                                        LoadingFeed(lesson: "")
                                                    }
                                                    Color.clear.frame(height: 50)
                                                }.shimmering()
                                            } else {
                                                ForEach(viewModel.new) { tweet in
                                                    TweetRowView(tweet: tweet, edit: false, canShow: true, canSeeComments: true, map: false, currentAudio: $currentAudio, isExpanded: $isExpanded, animationT: animation, seenAllStories: storiesLeftToView(otherUID: tweet.uid), isMain: true, showSheet: $tempTest, newsAnimation: newsAnimation, tabID: "ForYou")
                                                        .overlay(GeometryReader { proxy in
                                                            Color.clear
                                                                .onChange(of: offset, { _, _ in
                                                                    if let vid_id = tweet.videoURL, popRoot.currentSound.isEmpty {
                                                                        let frame = proxy.frame(in: .global)
                                                                        let bottomDistance = frame.minY - geometry.frame(in: .global).minY
                                                                        let topDistance = geometry.frame(in: .global).maxY - frame.maxY
                                                                        let diff = bottomDistance - topDistance

                                                                        if (bottomDistance < 0.0 && abs(bottomDistance) >= (frame.height / 2.0)) || (topDistance < 0.0 && abs(topDistance) >= (frame.height / 2.0)) {
                                                                            if currentAudio == vid_id + (tweet.id ?? "") {
                                                                                currentAudio = ""
                                                                            }
                                                                        } else if abs(diff) < 140 && abs(diff) > -140 {
                                                                            currentAudio = vid_id + (tweet.id ?? "")
                                                                        }
                                                                    }
                                                                })
                                                        })
                                                    
                                                    if storiesUnseen.count > 2 && indexOfPost(ForYou: true, postID: tweet.id) == 15 {
                                                        SuggestStories
                                                    } else if tweet != viewModel.new.last {
                                                        Divider().overlay(.gray).padding(.bottom, 6).opacity(0.4)
                                                    } else if !viewModel.suggestedFollow.isEmpty {
                                                        SuggestView
                                                    }
                                                }
                                                Color.clear.frame(height: 150)
                                            }
                                        }
                                        .background(GeometryReader {
                                            Color.clear.preference(key: ViewOffsetKey.self,
                                                                   value: -$0.frame(in: .named("scroll")).origin.y)
                                        })
                                        .onPreferenceChange(ViewOffsetKey.self) { value in
                                            offset = value

                                            if offset > 100 && canOne {
                                                if value > (scrollViewSize.height - geometry.size.height) - 400 {
                                                    canOne = false
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                                                        canOne = true
                                                    }
                                                    
                                                    viewModel.fetch25MoreNew(blocked: auth.currentUser?.blockedUsers ?? [], ads: [])
                                                }
                                            }
                                        }
                                    }
                                }
                                .coordinateSpace(name: "scroll")
                                .scrollIndicators(.hidden)
                                .onChange(of: popRoot.tap) { _, _ in
                                    if popRoot.tap == 1 && activeTab == "For you" && !viewModel.showProfile {
                                        withAnimation {
                                            proxy.scrollTo("scrolltop", anchor: .bottom)
                                            headerOffset = 0
                                            lastHeaderOffset = 0
                                            direction = .none
                                            shiftOffset = 0
                                        }
                                        refreshStories.toggle()
                                        popRoot.tap = 0
                                    }
                                }
                                .onChange(of: scrollNow) { _, _ in
                                    withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                                }
                            }
                        }
                        .tag("For you")
                        .frame(width: size.width, height: size.height)
                        .rect { tabProgress("For you", rect: $0, size: size) }
                        .overlay(alignment: .trailing){
                            Rectangle().frame(width: 1.0).foregroundStyle(.gray).opacity(0.3).offset(x: 1)
                        }
                        
                        GeometryReader { geometry in
                            ScrollViewReader { proxy in
                                ScrollView {
                                    Rectangle()
                                        .fill(.clear)
                                        .frame(height: 80 + top_Inset())
                                        .offsetY { previous, current in
                                            if previous > current {
                                                if direction != .up && current < 0 {
                                                    shiftOffset = current - headerOffset
                                                    direction = .up
                                                    lastHeaderOffset = headerOffset
                                                }
                                                if self.offset > 85 {
                                                    let offset = current < 0 ? (current - shiftOffset) : 0
                                                    withAnimation {
                                                        headerOffset = (-offset < headerHeight ? (offset < 0 ? offset : 0) : -headerHeight * 2.0)
                                                    }
                                                }
                                            } else {
                                                if direction != .down{
                                                    shiftOffset = current
                                                    direction = .down
                                                    lastHeaderOffset = headerOffset
                                                }
                                                let offset = lastHeaderOffset + (current - shiftOffset)
                                                withAnimation {
                                                    headerOffset = (offset > 0 ? 0 : offset)
                                                }
                                            }
                                        }
                                    ChildSizeReader(size: $scrollViewSize) {
                                        LazyVStack {
                                            Color.clear.frame(height: 6).id("scrolltop")
                                            
                                            if !viewModel.followers.isEmpty {
                                                ForEach(viewModel.followers) { tweet in
                                                    TweetRowView(tweet: tweet, edit: false, canShow: true, canSeeComments: true, map: false, currentAudio: $currentAudio, isExpanded: $isExpanded, animationT: animation, seenAllStories: storiesLeftToView(otherUID: tweet.uid), isMain: true, showSheet: $tempTest, newsAnimation: newsAnimation, tabID: "Following")
                                                        .overlay(GeometryReader { proxy in
                                                            Color.clear
                                                                .onChange(of: offset, { _, _ in
                                                                    if let vid_id = tweet.videoURL, popRoot.currentSound.isEmpty {
                                                                        let frame = proxy.frame(in: .global)
                                                                        let bottomDistance = frame.minY - geometry.frame(in: .global).minY
                                                                        let topDistance = geometry.frame(in: .global).maxY - frame.maxY
                                                                        let diff = bottomDistance - topDistance

                                                                        if (bottomDistance < 0.0 && abs(bottomDistance) >= (frame.height / 2.0)) || (topDistance < 0.0 && abs(topDistance) >= (frame.height / 2.0)) {
                                                                            if currentAudio == vid_id + (tweet.id ?? "") {
                                                                                currentAudio = ""
                                                                            }
                                                                        } else if abs(diff) < 140 && abs(diff) > -140 {
                                                                            currentAudio = vid_id + (tweet.id ?? "")
                                                                        }
                                                                    }
                                                                })
                                                        })

                                                    let index = indexOfPost(ForYou: false, postID: tweet.id)

                                                    if index == 15 && !viewModel.suggestedFollow.isEmpty {
                                                        SuggestView
                                                    } else if storiesUnseen.count > 2 && index == 25 {
                                                        SuggestStories
                                                    } else if index < viewModel.followers.count {
                                                        Divider().overlay(.gray).padding(.bottom, 6).opacity(0.4)
                                                    }
                                                }
                                                Color.clear.frame(height: 150)
                                            } else if viewModel.noPostsFromFollowers || !viewModel.suggestedFollow.isEmpty {
                                                if viewModel.noPostsFromFollowers {
                                                    HStack {
                                                        Spacer()
                                                        Text("No posts yet...")
                                                            .font(.headline).bold()
                                                        Spacer()
                                                    }.padding(.vertical, 30)
                                                }
                                                if !viewModel.suggestedFollow.isEmpty {
                                                    SuggestView
                                                }
                                            } else {
                                                VStack {
                                                    ForEach(0..<7){ i in
                                                        LoadingFeed(lesson: "")
                                                    }
                                                    Color.clear.frame(height: 50)
                                                }.shimmering()
                                            }
                                        }
                                        .background(GeometryReader {
                                            Color.clear.preference(key: ViewOffsetKey.self,
                                                                   value: -$0.frame(in: .named("scroll")).origin.y)
                                        })
                                        .onPreferenceChange(ViewOffsetKey.self) { value in
                                            offset = value
                                            
                                            if offset > 100 && canTwo {
                                                if value > (scrollViewSize.height - geometry.size.height) - 400 {
                                                    canTwo = false
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                                                        canTwo = true
                                                    }
                                                    
                                                    viewModel.fetchMoreFollowers(following: auth.currentUser?.following ?? [])
                                                }
                                            }
                                        }
                                    }
                                }
                                .coordinateSpace(name: "scroll")
                                .scrollIndicators(.hidden)
                                .onChange(of: popRoot.tap) { _, _ in
                                    if popRoot.tap == 1 && activeTab == "Following" && !viewModel.showProfile {
                                        withAnimation {
                                            proxy.scrollTo("scrolltop", anchor: .bottom)
                                            headerOffset = 0
                                            lastHeaderOffset = 0
                                            direction = .none
                                            shiftOffset = 0
                                        }
                                        popRoot.tap = 0
                                    }
                                }
                                .onChange(of: scrollNow) { _, _ in
                                    withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                                }
                            }
                        }
                        .tag("Following")
                        .frame(width: size.width, height: size.height)
                        .rect { tabProgress("Following", rect: $0, size: size) }
                        .overlay(alignment: .trailing){
                            Rectangle().frame(width: 1.0).foregroundStyle(.gray).opacity(0.3).offset(x: 1)
                        }
                        
                        ScrollViewReader { proxy in
                            ScrollView {
                                Rectangle()
                                    .fill(.clear)
                                    .frame(height: 80 + top_Inset())
                                    .offsetY { previous, current in
                                        if previous > current {
                                            if direction != .up && current < 0 {
                                                shiftOffset = current - headerOffset
                                                direction = .up
                                                lastHeaderOffset = headerOffset
                                            }
                                            if self.offset > 85 {
                                                let offset = current < 0 ? (current - shiftOffset) : 0
                                                withAnimation {
                                                    headerOffset = (-offset < headerHeight ? (offset < 0 ? offset : 0) : -headerHeight * 2.0)
                                                }
                                            }
                                        } else {
                                            if direction != .down{
                                                shiftOffset = current
                                                direction = .down
                                                lastHeaderOffset = headerOffset
                                            }
                                            let offset = lastHeaderOffset + (current - shiftOffset)
                                            withAnimation {
                                                headerOffset = (offset > 0 ? 0 : offset)
                                            }
                                        }
                                    }
                                LazyVStack(alignment: .leading, spacing: 0){
                                    Color.clear.frame(height: 6).id("scrolltop")
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
                                    }
                                    if stocks.coins.isEmpty {
                                        LoadingStocks()
                                    }
                                    Color.clear.frame(height: 150)
                                }
                                .background(GeometryReader {
                                    Color.clear.preference(key: ViewOffsetKey.self,
                                                           value: -$0.frame(in: .named("scroll")).origin.y)
                                })
                                .onPreferenceChange(ViewOffsetKey.self) { value in
                                    offset = value
                                }
                            }
                            .coordinateSpace(name: "scroll")
                            .onChange(of: popRoot.tap) { _, _ in
                                if popRoot.tap == 1 && activeTab == "Markets" && !viewModel.showProfile {
                                    withAnimation {
                                        proxy.scrollTo("scrolltop", anchor: .bottom)
                                        headerOffset = 0
                                        lastHeaderOffset = 0
                                        direction = .none
                                        shiftOffset = 0
                                    }
                                    popRoot.tap = 0
                                }
                            }
                            .onChange(of: scrollNow) { _, _ in
                                withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                            }
                        }
                        .tag("Markets")
                        .frame(width: size.width, height: size.height)
                        .rect { tabProgress("Markets", rect: $0, size: size) }
                        .overlay(alignment: .trailing){
                            Rectangle().frame(width: 1.0).foregroundStyle(.gray).opacity(0.3).offset(x: 1)
                        }

                        GeometryReader { geometry in
                            ScrollViewReader { proxy in
                                ScrollView {
                                    Rectangle()
                                        .fill(.clear)
                                        .frame(height: 80 + top_Inset())
                                        .offsetY { previous, current in
                                            if previous > current {
                                                if direction != .up && current < 0{
                                                    shiftOffset = current - headerOffset
                                                    direction = .up
                                                    lastHeaderOffset = headerOffset
                                                }
                                                if self.offset > 85 {
                                                    let offset = current < 0 ? (current - shiftOffset) : 0
                                                    withAnimation {
                                                        headerOffset = (-offset < headerHeight ? (offset < 0 ? offset : 0) : -headerHeight * 2.0)
                                                    }
                                                }
                                            } else {
                                                if direction != .down{
                                                    shiftOffset = current
                                                    direction = .down
                                                    lastHeaderOffset = headerOffset
                                                }
                                                let offset = lastHeaderOffset + (current - shiftOffset)
                                                withAnimation {
                                                    headerOffset = (offset > 0 ? 0 : offset)
                                                }
                                            }
                                        }
                                    ChildSizeReader(size: $scrollViewSize) {
                                        LazyVStack {
                                            Color.clear.frame(height: 6).id("scrolltop")
                                            ForEach(exploreModel.news) { news in
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
                                            if (exploreModel.news.count - exploreModel.singleNewsFetched) <= 1 {
                                                VStack {
                                                    ForEach(0..<5) { _ in
                                                        HStack {
                                                            Spacer()
                                                            LoadingNews().padding(.horizontal, 10)
                                                            Spacer()
                                                        }
                                                    }
                                                }.shimmering()
                                            }
                                            Color.clear.frame(height: 150)
                                        }
                                        .background(GeometryReader {
                                            Color.clear.preference(key: ViewOffsetKey.self,
                                                                   value: -$0.frame(in: .named("scroll")).origin.y)
                                        })
                                        .onPreferenceChange(ViewOffsetKey.self) { value in
                                            offset = value
                                            
                                            if offset > 100 && canFour {
                                                if value > (scrollViewSize.height - geometry.size.height) - 400 {
                                                    canFour = false
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                                                        canFour = true
                                                    }
                                                    
                                                    exploreModel.getNews()
                                                }
                                            }
                                        }
                                    }
                                }
                                .coordinateSpace(name: "scroll")
                                .scrollIndicators(.hidden)
                                .onChange(of: popRoot.tap) { _, _ in
                                    if popRoot.tap == 1 && activeTab == "News" && !viewModel.showProfile {
                                        withAnimation {
                                            proxy.scrollTo("scrolltop", anchor: .bottom)
                                            headerOffset = 0
                                            lastHeaderOffset = 0
                                            direction = .none
                                            shiftOffset = 0
                                        }
                                        popRoot.tap = 0
                                    }
                                }
                                .onChange(of: scrollNow) { _, _ in
                                    withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                                }
                            }
                        }
                        .tag("News")
                        .frame(width: size.width, height: size.height)
                        .rect { tabProgress("News", rect: $0, size: size) }
                        .overlay(alignment: .trailing){
                            Rectangle().frame(width: 1.0).foregroundStyle(.gray).opacity(0.3).offset(x: 1)
                        }
                        
                        ScrollViewReader { proxy in
                            ScrollView {
                                Rectangle()
                                    .fill(.clear)
                                    .frame(height: 80 + top_Inset())
                                    .offsetY { previous, current in
                                        if previous > current {
                                            if direction != .up && current < 0 {
                                                shiftOffset = current - headerOffset
                                                direction = .up
                                                lastHeaderOffset = headerOffset
                                            }
                                            if self.offset > 85 {
                                                let offset = current < 0 ? (current - shiftOffset) : 0
                                                withAnimation {
                                                    headerOffset = (-offset < headerHeight ? (offset < 0 ? offset : 0) : -headerHeight * 2.0)
                                                }
                                            }
                                        } else {
                                            if direction != .down{
                                                shiftOffset = current
                                                direction = .down
                                                lastHeaderOffset = headerOffset
                                            }
                                            let offset = lastHeaderOffset + (current - shiftOffset)
                                            withAnimation {
                                                headerOffset = (offset > 0 ? 0 : offset)
                                            }
                                        }
                                    }
                                LazyVStack(spacing: 10){
                                    Color.clear.frame(height: 6).id("scrolltop")
                                   
                                    Text("No one is Live yet.")
                                        .font(.title3).bold()
                                        .padding(.top, widthOrHeight(width: false) * 0.15)
                                    Text("Lives will appear here")
                                        .font(.subheadline).fontWeight(.light)
                                        .padding(.bottom, 20)
                                    LottieView(loopMode: .loop, name: "liveLoader")
                                        .scaleEffect(0.9)
                                        .frame(width: 85, height: 85)
                                    
                                    Color.clear.frame(height: 150)
                                }
                                .background(GeometryReader {
                                    Color.clear.preference(key: ViewOffsetKey.self,
                                                           value: -$0.frame(in: .named("scroll")).origin.y)
                                })
                                .onPreferenceChange(ViewOffsetKey.self) { value in
                                    offset = value
                                }
                            }
                            .coordinateSpace(name: "scroll")
                            .onChange(of: popRoot.tap) { _, _ in
                                if popRoot.tap == 1 && activeTab == "Lives" && !viewModel.showProfile {
                                    withAnimation {
                                        proxy.scrollTo("scrolltop", anchor: .bottom)
                                        headerOffset = 0
                                        lastHeaderOffset = 0
                                        direction = .none
                                        shiftOffset = 0
                                    }
                                    popRoot.tap = 0
                                }
                            }
                            .onChange(of: scrollNow) { _, _ in
                                withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                            }
                        }
                        .tag("Lives")
                        .frame(width: size.width, height: size.height)
                        .rect { tabProgress("Lives", rect: $0, size: size) }
                        .overlay(alignment: .trailing){
                            Rectangle().frame(width: 1.0).foregroundStyle(.gray).opacity(0.3).offset(x: 1)
                        }
                        
                        GeometryReader { geometry in
                            ScrollViewReader { proxy in
                                ScrollView {
                                    Rectangle()
                                        .fill(.clear)
                                        .frame(height: 80 + top_Inset())
                                        .offsetY { previous, current in
                                            if previous > current {
                                                if direction != .up && current < 0 {
                                                    shiftOffset = current - headerOffset
                                                    direction = .up
                                                    lastHeaderOffset = headerOffset
                                                }
                                                if self.offset > 85 {
                                                    let offset = current < 0 ? (current - shiftOffset) : 0
                                                    withAnimation {
                                                        headerOffset = (-offset < headerHeight ? (offset < 0 ? offset : 0) : -headerHeight * 2.0)
                                                    }
                                                }
                                            } else {
                                                if direction != .down{
                                                    shiftOffset = current
                                                    direction = .down
                                                    lastHeaderOffset = headerOffset
                                                }
                                                let offset = lastHeaderOffset + (current - shiftOffset)
                                                withAnimation {
                                                    headerOffset = (offset > 0 ? 0 : offset)
                                                }
                                            }
                                        }
                                    ChildSizeReader(size: $scrollViewSize) {
                                        LazyVStack {
                                            Color.clear.frame(height: 6).id("scrolltop")
                                            
                                            if !viewModel.audio.isEmpty {
                                                ForEach(viewModel.audio) { tweet in
                                                    TweetRowView(tweet: tweet, edit: false, canShow: true, canSeeComments: true, map: false, currentAudio: $currentAudio, isExpanded: $isExpanded, animationT: animation, seenAllStories: storiesLeftToView(otherUID: tweet.uid), isMain: true, showSheet: $tempTest, newsAnimation: newsAnimation, tabID: "Voices")
  
                                                    let index = indexOfAudio(postID: tweet.id)

                                                    if index == 15 && !viewModel.suggestedFollow.isEmpty {
                                                        SuggestView
                                                    } else if storiesUnseen.count > 2 && index == 25 {
                                                        SuggestStories
                                                    } else if index < viewModel.audio.count {
                                                        Divider().overlay(.gray).padding(.bottom, 6).opacity(0.4)
                                                    }
                                                }
                                                Color.clear.frame(height: 150)
                                            } else if viewModel.noAudioPosts || !viewModel.suggestedFollow.isEmpty {
                                                if viewModel.noAudioPosts {
                                                    HStack {
                                                        Spacer()
                                                        Text("No voices yet...")
                                                            .font(.headline).bold()
                                                        Spacer()
                                                    }.padding(.vertical, 30)
                                                }
                                                if !viewModel.suggestedFollow.isEmpty {
                                                    SuggestView
                                                }
                                            } else {
                                                VStack {
                                                    ForEach(0..<7){ i in
                                                        LoadingFeed(lesson: "")
                                                    }
                                                    Color.clear.frame(height: 50)
                                                }.shimmering()
                                            }
                                        }
                                        .background(GeometryReader {
                                            Color.clear.preference(key: ViewOffsetKey.self,
                                                                   value: -$0.frame(in: .named("scroll")).origin.y)
                                        })
                                        .onPreferenceChange(ViewOffsetKey.self) { value in
                                            offset = value
                                            
                                            if offset > 100 && canSix {
                                                if value > (scrollViewSize.height - geometry.size.height) - 400 {
                                                    canSix = false
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                                                        canSix = true
                                                    }
                                                    
                                                    viewModel.fetchMoreAudio(blocked: auth.currentUser?.blockedUsers ?? [])
                                                }
                                            }
                                        }
                                    }
                                }
                                .coordinateSpace(name: "scroll")
                                .scrollIndicators(.hidden)
                                .onChange(of: popRoot.tap) { _, _ in
                                    if popRoot.tap == 1 && activeTab == "Voices" && !viewModel.showProfile {
                                        withAnimation {
                                            proxy.scrollTo("scrolltop", anchor: .bottom)
                                            headerOffset = 0
                                            lastHeaderOffset = 0
                                            direction = .none
                                            shiftOffset = 0
                                        }
                                        popRoot.tap = 0
                                    }
                                }
                                .onChange(of: scrollNow) { _, _ in
                                    withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                                }
                            }
                        }
                        .tag("Voices")
                        .frame(width: size.width, height: size.height)
                        .rect { tabProgress("Voices", rect: $0, size: size) }
                        .overlay(alignment: .trailing){
                            Rectangle().frame(width: 1.0).foregroundStyle(.gray).opacity(0.3).offset(x: 1)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .overlay(alignment: .top) {
                        headerView().opacity(headerOffset < 0 ? opac() : 1.0).offset(y: -headerOffset < headerHeight ? headerOffset : (headerOffset < 0 ? headerOffset : 0))
                    }
                    .allowsHitTesting(!isDragging)
                    .onChange(of: activeTab) { oldValue, newValue in
                        guard tabBarScrollState != newValue else { return }
                        withAnimation(.snappy) {
                            tabBarScrollState = newValue
                        }
                    }
                }
            }.ignoresSafeArea()
            HStack {
                Spacer()
                Button {
                    popRoot.tempCurrentAudio = popRoot.currentAudio
                    popRoot.currentAudio = ""
                    withAnimation(.easeInOut(duration: 0.25)){
                        popRoot.hideTabBar = true
                    }
                    showNewTweetView.toggle()
                } label: {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 57)
                        .padding()
                }
                .shadow(color: .gray.opacity(0.6), radius: 10, x: 0, y: 0)
                .frame(width: 75, height: 35)
                .background(Color(.systemOrange).opacity(0.9))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .opacity(opacSec())
                Spacer()
            }
            .padding(.bottom, 139)
            .navigationDestination(isPresented: $showNewTweetView) {
                NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent)
                    .enableFullSwipePop(true)
                    .navigationBarBackButtonHidden(true)
                    .onDisappear {
                        withAnimation(.easeInOut(duration: 0.15)){
                            popRoot.hideTabBar = false
                        }
                        place = nil
                    }
            }
            if (offset <= (-130 - top_Inset())) {
                VStack {
                    HStack {
                        Spacer()
                        let val = loaderConfig()
                        ProgressView()
                            .opacity(val)
                            .scaleEffect(val)
                        Spacer()
                    }.padding(.top)
                    Spacer()
                }.padding(.top, 100)
            }
            if showRefreshButton {
                VStack {
                    HStack {
                        Spacer()
                        upButton()
                            .padding(.top).padding(.top, max(0, 140.0 + headerOffset - top_Inset()))
                        Spacer()
                    }
                    Spacer()
                }.transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: $showCamera, content: {
            MessageCamera(initialSend: $initialSend, showMemories: true)
        })
        .navigationDestination(isPresented: $viewModel.showProfile) {
            ProfileView(showSettings: true, showMessaging: false, uid: auth.currentUser?.id ?? "", photo: auth.currentUser?.profileImageUrl ?? "", user: auth.currentUser, expand: false, isMain: true).enableFullSwipePop(!popRoot.hideTabBar)
        }
        .navigationDestination(isPresented: $showStoryProfile) {
            ProfileView(showSettings: false, showMessaging: false, uid: storyUID, photo: "", user: nil, expand: false, isMain: false).enableFullSwipePop(!popRoot.hideTabBar)
        }
        .navigationDestination(isPresented: $showStoryChat) {
            MessagesView(exception: false, user: nil, uid: storyUID, tabException: false, canCall: true)
                .enableFullSwipePop(true)
                .onDisappear {
                    withAnimation(.easeInOut(duration: 0.15)){
                        popRoot.hideTabBar = false
                    }
                }
        }
        .overlay(content: {
            if isMainExpanded {
                CubeTopStory(selection: $storySelection, storiesUidOrder: $storiesUidOrder, isMainExpanded: $isMainExpanded, showProfile: $showStoryProfile, showChat: $showStoryChat, profileUID: $storyUID, showNewTweetView: $showNewTweetView, initialContent: $initialContent, tempMid: $tempMid, animation: animationMain)
                    .onAppear(perform: {
                        currentAudio = ""
                    })
                    .onDisappear {
                        withAnimation(.easeInOut(duration: 0.15)){
                            popRoot.hideTabBar = false
                        }
                    }
            }
        })
        .overlay(content: {
            if isExpanded {
                if profile.mid.contains("suggested") {
                    MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: profile.mid, isHome: false, canOpenChat: true, canOpenProfile: true, openChat: { uid in
                        storyUID = uid
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
                            showStoryChat = true
                        }
                    }, openProfile: { uid in
                        storyUID = uid
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
                            showStoryProfile = true
                        }
                    })
                    .onDisappear {
                        withAnimation(.easeInOut(duration: 0.15)){
                            popRoot.hideTabBar = false
                        }
                    }
                } else {
                    MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: profile.mid, isHome: true, canOpenChat: true, canOpenProfile: true, openChat: { uid in
                        storyUID = uid
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
                            showStoryChat = true
                        }
                    }, openProfile: { uid in
                        storyUID = uid
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
                            showStoryProfile = true
                        }
                    })
                    .transition(.scale)
                    .onAppear(perform: {
                        currentAudio = ""
                    })
                    .onDisappear {
                        withAnimation(.easeInOut(duration: 0.15)){
                            popRoot.hideTabBar = false
                        }
                    }
                }
            }
        })
        .onChange(of: offset) { _, _ in
            if offset <= (-160 - top_Inset()) {
                refreshStories.toggle()
                if activeTab == "For you" && canROne {
                    canROne = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                       canROne = true
                    }
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    
                    viewModel.fetchNew(blocked: auth.currentUser?.blockedUsers ?? [])
                    Task { glitchTrigger.toggle() }
                } else if activeTab == "Following" && canRTwo {
                    canRTwo = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        canRTwo = true
                    }
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    
                    viewModel.fetchFollowers(following: auth.currentUser?.following ?? [])
                    Task { glitchTrigger.toggle() }
                } else if activeTab == "Markets" && canRThree {
                    canRThree = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        canRThree = true
                    }
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    
                    if stocks.coins.isEmpty {
                        stocks.startStocks()
                        if stocks.holiday.0 {
                            stocks.verifyHoliday()
                        }
                    } else if popRoot.lastFetchedStocks == nil || isAtLeastXSecondsOld(seconds: 10.0, date: popRoot.lastFetchedStocks ?? Date()) {
                        popRoot.lastFetchedStocks = Date()
                        stocks.refreshAllStock()
                    }
                    Task { glitchTrigger.toggle() }
                } else if activeTab == "News" && canRFour {
                    canRFour = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        canRFour = true
                    }
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    
                    if (exploreModel.news.count - exploreModel.singleNewsFetched) <= 1 {
                        exploreModel.getNews()
                    }
                    Task { glitchTrigger.toggle() }
                } else if activeTab == "Lives" && canRFive {
                    canRFive = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        canRFive = true
                    }
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
 
                    //fetch new lives here
                    Task { glitchTrigger.toggle() }
                } else if activeTab == "Voices" && canRSix {
                    canRSix = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        canRSix = true
                    }
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    
                    viewModel.fetchAudio(blocked: auth.currentUser?.blockedUsers ?? [])
                    Task { glitchTrigger.toggle() }
                }
            }
            
            if offset > (lastOffset + 30.0) {
                lastOffset = offset
                if !popRoot.dimTab {
                    withAnimation {
                        popRoot.dimTab = true
                    }
                }
            } else if offset < (lastOffset - 30.0) || offset < 50.0 {
                lastOffset = offset
                if popRoot.dimTab {
                    withAnimation {
                        popRoot.dimTab = false
                    }
                }
            }
            
            if offset > 5000 {
                if let thirtySecondsAgo = Calendar.current.date(byAdding: .second, value: -20, to: Date()) {
                    if lastShowedRefresh <= thirtySecondsAgo {
                        withAnimation {
                            showRefreshButton = true
                        }
                        lastShowedRefresh = Date()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            withAnimation(.easeInOut(duration: 0.3)){
                                showRefreshButton = false
                            }
                        }
                    }
                }
            } else if showRefreshButton && offset < 4000 {
                withAnimation {
                    showRefreshButton = false
                }
            }
        }
        .onAppear {
            if let user = auth.currentUser, let id = user.id, !notifModel.gotNotifications {
                if let prof = profile.users.first(where: { $0.user.id ?? "" == id }) {
                    notifModel.getNotifications(profile: prof)
                } else {
                    notifModel.getNotifications(profile: Profile(user: user, tweets: [], listJobs: [], likedTweets: [], forSale: [], questions: []))
                }
            }
            
            if globe.currentLocation == nil {
                manager.requestLocation() { place in
                    if !place.0.isEmpty && !place.1.isEmpty {
                        globe.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                    }
                }
            }
        }
        .onChange(of: auth.currentUser) { _, _ in
            if let user = auth.currentUser, let id = user.id {
                
                if fetchFollows && viewModel.followers.isEmpty && activeTab == "Markets" {
                    viewModel.fetchFollowers(following: user.following)
                    fetchFollows = false
                }
                
                if !notifModel.gotNotifications {
                    if let prof = profile.users.first(where: { $0.user.id ?? "" == id }) {
                        notifModel.getNotifications(profile: prof)
                    } else {
                        notifModel.getNotifications(profile: Profile(user: user, tweets: [], listJobs: [], likedTweets: [], forSale: [], questions: []))
                    }
                }
            }
        }
        .onChange(of: activeTab) { _, _ in
            withAnimation {
                headerOffset = 0
                lastHeaderOffset = 0
                direction = .none
                shiftOffset = 0
            }
            
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if activeTab == "Following" {
                if let user = auth.currentUser, fetchFollows && viewModel.followers.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.fetchFollowers(following: user.following)
                    }
                    fetchFollows = false
                }
            } else if activeTab == "Markets" {
                stocks.startStocks()
                
                if stocks.holiday.0 {
                    stocks.verifyHoliday()
                }
                if !stocks.coins.isEmpty {
                    recursiveStockUpdater()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
                        recursiveStockUpdater()
                    }
                }
            } else if activeTab == "News" {
                if (exploreModel.news.count - exploreModel.singleNewsFetched) <= 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        exploreModel.getNews()
                    }
                }
            } else if activeTab == "Lives" {
                
            } else if activeTab == "Voices" {
                if viewModel.audio.isEmpty && !viewModel.noAudioPosts {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.fetchAudio(blocked: auth.currentUser?.blockedUsers ?? [])
                    }
                }
            }
        }
    }
    func indexOfPost(ForYou: Bool, postID: String?) -> Int {
        if ForYou {
            return viewModel.new.firstIndex(where: { $0.id == postID }) ?? 0
        } else {
            return viewModel.followers.firstIndex(where: { $0.id == postID }) ?? 0
        }
    }
    func indexOfAudio(postID: String?) -> Int {
        return viewModel.audio.firstIndex(where: { $0.id == postID }) ?? 0
    }
    func recursiveStockUpdater() {
        if popRoot.lastFetchedStocks == nil || isAtLeastXSecondsOld(seconds: 12.0, date: popRoot.lastFetchedStocks ?? Date()) {
            if scenePhase == .active && activeTab == "Markets" && popRoot.tab == 1 && !stocks.coins.isEmpty {
                popRoot.lastFetchedStocks = Date()
                stocks.refreshAllStock()
                DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
                    recursiveStockUpdater()
                }
            }
        }
    }
    func loaderConfig() -> CGFloat {
        var minT = -130.0 - top_Inset()
        let maxT = minT - 50.0
        
        if offset > minT {
            return 0.5
        } else if offset < maxT {
            return 1.3
        }
        minT = abs(minT)

        let normalizedOffset = (CGFloat(abs(offset)) - minT) / (abs(maxT) - minT)
        
        let scale = min(max(0.5, CGFloat(normalizedOffset) * 1.3), 1.3)

        return scale
    }
    func storiesLeftToView(otherUID: String?) -> Bool {
        if let uid = auth.currentUser?.id, let otherUID {
            if otherUID == uid {
                return false
            }
            if let stories = profile.users.first(where: { $0.user.id == otherUID })?.stories {
                for i in 0..<stories.count {
                    if let sid = stories[i].id {
                        if !notifModel.viewedStories.contains(where: { $0.0 == sid }) && !(stories[i].views ?? []).contains(where: { $0.contains(uid) }) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    func upButton() -> some View {
        Button(action: {
            withAnimation {
                showRefreshButton = false
                headerOffset = 0
                lastHeaderOffset = 0
                direction = .none
                shiftOffset = 0
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            scrollNow.toggle()
            if activeTab == "For you" {
                viewModel.fetchNew(blocked: auth.currentUser?.blockedUsers ?? [])
            } else if activeTab == "Following" {
                viewModel.fetchFollowers(following: auth.currentUser?.following ?? [])
            }
            Task {
                glitchTrigger.toggle()
            }
        }, label: {
            HStack {
                Image(systemName: "arrow.up").foregroundStyle(.white).font(.caption).bold()
                ZStack(alignment: .leading){
                    ZStack {
                        Circle().foregroundStyle(.red)
                        KFImage(URL(string: viewModel.recentPhotos[0]))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .frame(width: 28, height: 28)
                    .padding(2)
                    .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .clipShape(Circle())
                    .padding(.leading, 32)
                    
                    ZStack {
                        Circle().foregroundStyle(.black)
                        KFImage(URL(string: viewModel.recentPhotos[1]))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .frame(width: 28, height: 28)
                    .padding(2)
                    .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .clipShape(Circle())
                    .padding(.leading, 16)
                    
                    ZStack {
                        Circle().foregroundStyle(.green)
                        KFImage(URL(string: viewModel.recentPhotos[2]))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .frame(width: 28, height: 28)
                    .padding(2)
                    .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .clipShape(Circle())
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
            .clipShape(Capsule())
            .shadow(color: .gray, radius: 4)
        })
    }
    func hasStories(uid: String) -> Bool {
        return !(profile.users.first(where: { $0.user.id == uid })?.stories ?? []).isEmpty
    }
    func singleUser(user: User) -> some View {
        ZStack {
            VStack {
                if hasStories(uid: user.id ?? "") {
                    ZStack {
                        StoryRingView(size: 77, active: storiesLeftToView(otherUID: user.id), strokeSize: 2.0)
                        
                        let mid = (user.id ?? "") + "SuggestUpStory"
                        let size = isExpanded && profile.mid == mid ? 200.0 : 67.0
                        GeometryReader { _ in
                            ZStack {
                                personLetterView(size: size, letter: String(user.fullname.first ?? Character("M")))
                                
                                if let image = user.profileImageUrl {
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width:size, height: size)
                                        .clipShape(Circle())
                                        .contentShape(Circle())
                                }
                            }.opacity(isExpanded && profile.mid == mid ? 0.0 : 1.0)
                        }
                        .matchedGeometryEffect(id: mid, in: animation, anchor: .topTrailing)
                        .frame(width: 67.0, height: 67.0)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if let stories = profile.users.first(where: { $0.user.id == user.id })?.stories {
                                profile.selectedStories = stories
                            }
                            profile.mid = mid
                            withAnimation(.easeInOut(duration: 0.15)){
                                popRoot.hideTabBar = true
                                isExpanded = true
                            }
                        }
                    }
                } else {
                    NavigationLink {
                        ProfileView(showSettings: false, showMessaging: true, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: false, isMain: false)
                    } label: {
                        ZStack {
                            personLetterView(size: 75, letter: String(user.fullname.first ?? Character("M")))
                            
                            if let image = user.profileImageUrl {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 75, height: 75)
                                    .clipShape(Circle())
                                    .contentShape(Circle())
                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                            }
                        }
                    }
                }
                Spacer()
                NavigationLink {
                    ProfileView(showSettings: false, showMessaging: true, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: false, isMain: false)
                } label: {
                    VStack {
                        Text(user.fullname)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        Text(user.username)
                            .font(.caption).foregroundStyle(.gray)
                    }
                }
                Spacer()
                Button(action: {
                    if let following = auth.currentUser?.following, let uid = user.id {
                        if following.contains(uid){
                            profile.unfollow(withUid: uid)
                            auth.currentUser?.following.removeAll(where: { $0 == uid })
                            generator.notificationOccurred(.error)
                        } else {
                            profile.follow(withUid: uid)
                            generator.notificationOccurred(.success)
                            auth.currentUser?.following.append(uid)
                        }
                    }
                }, label: {
                    let following = auth.currentUser?.following ?? []
                            
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.blue.gradient)
                            .frame(height: 24).opacity(0.7)
                        Text(following.contains(user.id ?? "") ? "Following" : "Follow").foregroundStyle(.white)
                            .font(.caption).bold()
                    }
                })
            }.padding(.top, 5)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)){
                            viewModel.suggestedFollow.removeAll(where: { $0.id == user.id })
                        }
                    }, label: {
                        Image(systemName: "xmark")
                            .font(.caption).bold()
                            .foregroundStyle(.gray)
                    })
                }
                Spacer()
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 8)
        .frame(width: 135, height: 178)
        .background(colorScheme == .dark ? Color(UIColor.darkGray).opacity(0.6) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
    }
    var SuggestStories: some View {
        VStack(spacing: 10){
            HStack {
                Text("Suggested Stories")
                    .font(.headline).bold()
                Spacer()
            }.padding(.horizontal, 12).padding(.top, 10)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10){
                    Color.clear.frame(width: 2, height: 1)
                    ForEach(storiesUnseen, id: \.2) { element in
                        let mid = element.1 + element.2 + "suggested"
                        
                        if !isExpanded || profile.mid != mid {
                            storyFeedImagePart(mid: mid, animation: animation, image: element.0)
                                .frame(width: 170.0, height: 270.0)
                                .overlay(alignment: .topLeading) {
                                    ZStack {
                                        if element.3.count == 1 {
                                            if element.3 != "-" {
                                                personLetterView(size: 35, letter: element.3)
                                            }
                                        } else if !element.3.isEmpty {
                                            KFImage(URL(string: element.3))
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 35, height: 35)
                                                .clipShape(Circle())
                                                .contentShape(Circle())
                                        }
                                    }.padding(10)
                                }
                                .onTapGesture {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    if var stories = profile.users.first(where: {$0.user.id == element.2})?.stories {
                                        if let idx = stories.firstIndex(where: { $0.id == element.1 }) {
                                            let start = stories.remove(at: idx)
                                            stories = [start] + stories
                                        }
                                        currentAudio = ""
                                        profile.selectedStories = stories
                                        profile.mid = mid
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            popRoot.hideTabBar = true
                                            isExpanded = true
                                        }
                                    }
                                }
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(.gray).opacity(0.15)
                                .frame(width: 170.0, height: 270.0)
                        }
                    }
                    Color.clear.frame(width: 2, height: 1)
                }
            }.scrollIndicators(.hidden).frame(height: 270)
        }.padding(.bottom)
    }
    var SuggestView: some View {
        VStack(spacing: 10){
            HStack {
                Text("Suggested for You")
                    .font(.subheadline).bold()
                Spacer()
                NavigationLink {
                    DiscoverPeople()
                        .onAppear(perform: {
                            currentAudio = ""
                        })
                } label: {
                    Text("See All")
                        .foregroundStyle(.blue)
                        .font(.subheadline).bold()
                }
            }.padding(.horizontal, 12)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10){
                    Color.clear.frame(width: 2, height: 12)
                    ForEach(viewModel.suggestedFollow) { user in
                        if user.id != auth.currentUser?.id {
                            singleUser(user: user)
                        }
                    }
                    Color.clear.frame(width: 2, height: 12)
                }
            }.scrollIndicators(.hidden).frame(height: 180)
        }
        .padding(.vertical, 8)
        .background(.gray.opacity(colorScheme == .dark ? 0.25 : 0.1))
    }
    func opac() -> CGFloat {
        if -headerOffset > 130 {
            return 0.0
        } else {
            return (130.0 - -headerOffset) / 130.0
        }
    }
    func opacSec() -> CGFloat {
        if -headerOffset > 130 {
            return 0.4
        } else {
            let temp = (130.0 - -headerOffset) / 130.0
            return temp < 0.4 ? 0.4 : temp
        }
    }
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 0){
            HStack(spacing: 25){
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)){
                        showMenu = true
                    }
                }, label: {
                    HStack(spacing: 7){
                        ZStack {
                            Color.gray.opacity(0.001)
                                .frame(width: 17, height: 17)
                            VStack(spacing: 6){
                                Rectangle().frame(width: 15, height: 1)
                                Rectangle().frame(width: 15, height: 1)
                                Rectangle().frame(width: 15, height: 1)
                            }.foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                        GlitchEffect(trigger: $glitchTrigger, text: "Hustles")
                            .font(.title).bold()
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                })
                Spacer()
                NavigationLink {
                    FeedNotificationView(close: {}).enableFullSwipePop(true)
                } label: {
                    ZStack {
                        Image(systemName: "bell").font(.system(size: 24))
                        if notifModel.notifs.count > 0 {
                            ZStack {
                                Circle().foregroundStyle(.red)
                                Text("\(notifModel.notifs.count)").font(.caption2).foregroundStyle(.white).bold()
                            }.frame(width: 18, height: 18).offset(x: 12, y: 12)
                        }
                    }
                }
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)){
                        viewModel.showProfile = true
                    }
                }, label: {
                    ZStack(alignment: .bottomTrailing) {
                        personView(size: 40)
                        
                        if let image = auth.currentUser?.profileImageUrl {
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width:40, height: 40)
                                .clipShape(Circle())
                                .contentShape(Circle())
                                .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                        }
                        if auth.currentUser?.verified != nil {
                            Image("veriBlue")
                                .resizable()
                                .frame(width: 25, height: 20).offset(x: 3, y: 5)
                        }
                    }
                })
            }.padding(.horizontal)
            CustomTabBar().padding(.top, 10)
        }
        .padding(.top, top_Inset())
        .background {
            TransparentBlurView(removeAllFilters: true)
                .blur(radius: 14, opaque: true)
                 .background(colorScheme == .dark ? .black.opacity(0.8) : .white.opacity(0.8))
        }
    }
    func tabProgress(_ tab: String, rect: CGRect, size: CGSize) {
        if let index = tabs.firstIndex(where: { $0.id == activeTab }), activeTab == tab, !isDragging {
            let offsetX = rect.minX - (size.width * CGFloat(index))
            progress = -offsetX / size.width
        }
    }
    @ViewBuilder
    func CustomTabBar() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach($tabs, id: \.id) { $tab in
                    Button(action: {
                        delayTask?.cancel()
                        delayTask = nil
                        
                        isDragging = true
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            activeTab = tab.id
                            tabBarScrollState = tab.id
                            progress = CGFloat(tabs.firstIndex(where: { $0.id == tab.id }) ?? 0)
                        }
                        
                        delayTask = .init { isDragging = false }
                        
                        if let delayTask { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: delayTask)
                        }
                    }) {
                        Text(tab.id)
                            .fontWeight(.bold)
                            .font(.subheadline)
                            .padding(.vertical, 12)
                            .foregroundStyle(activeTab == tab.id ? Color.primary : .gray)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .rect { rect in
                        tab.size = rect.size
                        tab.minX = rect.minX
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: .init(get: {
            return tabBarScrollState
        }, set: { _ in
            
        }), anchor: .center)
        .overlay(alignment: .bottom) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, -15)
                
                let inputRange = tabs.indices.compactMap { return CGFloat($0) }
                let ouputRange = tabs.compactMap { return $0.size.width }
                let outputPositionRange = tabs.compactMap { return $0.minX }
                let indicatorWidth = progress.interpolate(inputRange: inputRange, outputRange: ouputRange)
                let indicatorPosition = progress.interpolate(inputRange: inputRange, outputRange: outputPositionRange)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue)
                    .frame(width: indicatorWidth, height: 3)
                    .offset(x: indicatorPosition)
                    .offset(y: -2)
            }
        }
        .safeAreaPadding(.horizontal, 15)
        .scrollIndicators(.hidden)
    }
}
