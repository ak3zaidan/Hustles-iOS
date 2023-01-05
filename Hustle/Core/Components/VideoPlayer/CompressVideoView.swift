import SwiftUI

#Preview(body: {
    Home13()
})

enum Tab: String, CaseIterable {
    case home = "Home"
    case shorts = "Shorts"
    case subscriptions = "Subscriptions"
    case you = "You"
    
    var symbol: String {
        switch self {
        case .home:
            "house.fill"
        case .shorts:
            "video.badge.waveform.fill"
        case .subscriptions:
            "play.square.stack.fill"
        case .you:
            "person.circle.fill"
        }
    }
}

struct Home13: View {
    @State private var activeTab: Tab = .home
    @State private var config: PlayerConfig = .init()
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $activeTab) {
                HomeTabView()
                    .setupTab(.home)
                
                Text(Tab.shorts.rawValue)
                    .setupTab(.shorts)
                
                Text(Tab.subscriptions.rawValue)
                    .setupTab(.subscriptions)
                
                Text(Tab.you.rawValue)
                    .setupTab(.you)
            }
            .padding(.bottom, tabBarHeight)

            GeometryReader {
                let size = $0.size
                
                if config.showMiniPlayer {
                    MiniPlayerView(size: size, config: $config) {
                        withAnimation(.easeInOut(duration: 0.3), completionCriteria: .logicallyComplete) {
                            config.showMiniPlayer = false
                        } completion: {
                            config.resetPosition()
                            config.selectedPlayerItem = nil
                        }
                    }
                }
            }
            
            CustomTabBar()
                .offset(y: config.showMiniPlayer ? tabBarHeight - (config.progress * tabBarHeight) : 0)
        }
        .overlay(alignment: .top) {
            if config.showMiniPlayer {
                Rectangle()
                    .fill(.black)
                    .frame(height: safeAreax.top)
                    .opacity(config.showMiniPlayer ? 1.0 - (config.progress * 2) : 0)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    @ViewBuilder
    func HomeTabView() -> some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 15) {
                    ForEach(items) { item in
                        PlayerItemCardView(item) {
                            config.selectedPlayerItem = item
                            withAnimation(.easeInOut(duration: 0.3)) {
                                config.showMiniPlayer = true
                            }
                        }
                    }
                }
                .padding(15)
            }
            .navigationTitle("YouTube")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.background, for: .navigationBar)
        }
    }

    @ViewBuilder
    func PlayerItemCardView(_ item: PlayerItem, onTap: @escaping () -> ()) -> some View {
        VStack(alignment: .leading, spacing: 6, content: {
            Rectangle()
                .fill(item.color.gradient)
                .frame(height: 180)
                .clipShape(.rect(cornerRadius: 10))
                .contentShape(.rect)
                .onTapGesture(perform: onTap)
            
            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4, content: {
                    Text(item.title)
                        .font(.callout)
                    
                    HStack(spacing: 6) {
                        Text(item.author)
                        
                        Text("· 2 Days Ago")
                    }
                    .font(.caption)
                    .foregroundStyle(.gray)
                })
            }
        })
    }
    
    /// Custom Tab Bar
    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                VStack(spacing: 2) {
                    Image(systemName: tab.symbol)
                        .font(.title3)
                        .scaleEffect(0.9, anchor: .bottom)
                    
                    Text(tab.rawValue)
                        .font(.caption2)
                }
                .foregroundStyle(activeTab == tab ? Color.primary : .gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
                .onTapGesture {
                    activeTab = tab
                }
            }
        }
        .frame(height: 49)
        .overlay(alignment: .top) {
            Divider()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(height: tabBarHeight)
        .background(.background)
    }
}

/// View Extensions
extension View {
    @ViewBuilder
    func setupTab(_ tab: Tab) -> some View {
        self
            .tag(tab)
            .toolbar(.hidden, for: .tabBar)
    }
    
    /// SafeArea Value
    var safeAreax: UIEdgeInsets {
        if let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets {
            return safeArea
        }
        
        return .zero
    }
    
    var tabBarHeight: CGFloat {
        return 49 + safeAreax.bottom
    }
}


struct MiniPlayerView: View {
    var size: CGSize
    @Binding var config: PlayerConfig
    var close: () -> ()
    let miniPlayerHeight: CGFloat = 50
    let playerHeight: CGFloat = 200
    var body: some View {
        let progress = config.progress > 0.7 ? (config.progress - 0.7) / 0.3 : 0
        
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                GeometryReader {
                    let size = $0.size
                    let width = size.width - 120
                    let height = size.height
                    
                    VideoPlayerView()
                        .frame(width: 120 + (width - (width * progress)), height: height)
                }
                .zIndex(1)
                
                if let selectedPlayerItem = config.selectedPlayerItem {
                    PlayerMinifiedContent(selectedPlayerItem)
                        .padding(.leading, 130)
                        .padding(.trailing, 15)
                        .foregroundStyle(Color.primary)
                        .opacity(progress)
                }
            }
            .frame(minHeight: miniPlayerHeight, maxHeight: playerHeight)
            .zIndex(1)
            
            ScrollView(.vertical) {
                if let playerItem = config.selectedPlayerItem {
                    PlayerExpandedContent(playerItem)
                }
            }
            .opacity(1.0 - (config.progress * 2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.background)
        .clipped()
        .contentShape(.rect)
        .offset(y: config.progress * -tabBarHeight)
        .frame(height: size.height - config.position, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let start = value.startLocation.y
                    guard start < playerHeight || start > (size.height - (tabBarHeight + miniPlayerHeight)) else { return }
                    
                    let height = config.lastPosition + value.translation.height
                    config.position = min(height, (size.height - miniPlayerHeight))
                    generateProgress()
                }.onEnded { value in
                    let start = value.startLocation.y
                    guard start < playerHeight || start > (size.height - (tabBarHeight + miniPlayerHeight)) else { return }
                    
                    let velocity = value.velocity.height * 5
                    withAnimation(.smooth(duration: 0.3)) {
                        if (config.position + velocity) > (size.height * 0.65) {
                            config.position = (size.height - miniPlayerHeight)
                            config.lastPosition = config.position
                            config.progress = 1
                        } else {
                            config.resetPosition()
                        }
                    }
                }.simultaneously(with: TapGesture().onEnded { _ in
                    withAnimation(.smooth(duration: 0.3)) {
                        config.resetPosition()
                    }
                })
        )
        .transition(.offset(y: config.progress == 1 ? tabBarHeight : size.height))
        .onChange(of: config.selectedPlayerItem, initial: false) { oldValue, newValue in
            withAnimation(.smooth(duration: 0.3)) {
                config.resetPosition()
            }
        }
    }

    @ViewBuilder
    func VideoPlayerView() -> some View {
        GeometryReader {
            let size = $0.size
            
            Rectangle()
                .fill(.black)
            
            /// Replace with your Video Player View
            if let playerItem = config.selectedPlayerItem {
                Rectangle()
                    .fill(playerItem.color.gradient)
                    .frame(width: size.width, height: size.height)
            }
        }
    }
    
    /// Player Minified Content View
    @ViewBuilder
    func PlayerMinifiedContent(_ playerItem: PlayerItem) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3, content: {
                Text(playerItem.title)
                    .font(.callout)
                    .textScale(.secondary)
                    .lineLimit(1)
                Text(playerItem.author)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            })
            .frame(maxHeight: .infinity)
            .frame(maxHeight: miniPlayerHeight)
            
            Spacer(minLength: 0)
            
            Button(action: {}, label: {
                Image(systemName: "pause.fill")
                    .font(.title2)
                    .frame(width: 35, height: 35)
                    .contentShape(.rect)
            })
            
            Button(action: close, label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .frame(width: 35, height: 35)
                    .contentShape(.rect)
            })
        }
    }
    
    @ViewBuilder
    func PlayerExpandedContent(_ item: PlayerItem) -> some View {
        VStack(alignment: .leading, spacing: 15, content: {
            Text(item.title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(item.description)
                .font(.callout)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .padding(.top, 10)
    }
    
    func generateProgress() {
        let progress = max(min(config.position / (size.height - miniPlayerHeight), 1.0), .zero)
        config.progress = progress
    }
}

struct PlayerConfig: Equatable {
    var position: CGFloat = .zero
    var lastPosition: CGFloat = .zero
    var progress: CGFloat = .zero
    var selectedPlayerItem: PlayerItem?
    var showMiniPlayer: Bool = false
    
    mutating func resetPosition() {
        position = .zero
        lastPosition = .zero
        progress = .zero
    }
}


let dummyDescription: String = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."

struct PlayerItem: Identifiable, Equatable {
    let id: UUID = .init()
    var title: String
    var author: String
    var image: String
    var description: String = dummyDescription
    var color: Color
}

/// Sample Data
var items: [PlayerItem] = [
    .init(
        title: "Apple Vision Pro - Unboxing, Review and demos!",
        author: "iJustine",
        image: "Pic 1",
        color: .red
    ),
    .init(
        title: "Hero Effect - SwiftUI",
        author: "Kavsoft",
        image: "Pic 2",
        color: .blue
    ),
    .init(
        title: "What Apple Vision Pro is really like.",
        author: "iJustine",
        image: "Pic 3",
        color: .yellow
    ),
    .init(
        title: "Draggable Map Pin",
        author: "Kavsoft",
        image: "Pic 4",
        color: .purple
    ),
    .init(
        title: "Maps Bottom Sheet",
        author: "Kavsoft",
        image: "Pic 5",
        color: .cyan
    ),
]
