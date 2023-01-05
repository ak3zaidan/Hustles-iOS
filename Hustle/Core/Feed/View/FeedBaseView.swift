import SwiftUI

struct FeedBaseView: View {
    @State var showMenu: Bool = false
    @State var offset: CGFloat = 0
    @State var lastStoredOffset: CGFloat = 0
    @GestureState var gestureOffset: CGFloat = 0
    @State var showCreateCommunity: Bool = false
    @State var showSearchCommunity: Bool = false
    @State var showSaved: Bool = false
    @State var showMemories: Bool = false
    @Binding var storiesUidOrder: [String]
    @Binding var mutedStories: [String]
    @Binding var noneFound: Bool
    let newsAnimation: Namespace.ID
    
    var body: some View {
        let sideBarWidth = widthOrHeight(width: true) - 90
        VStack {
            HStack(spacing: 0) {
                FeedSideMenu(showMenu: $showMenu, showCreateCommunity: $showCreateCommunity, showSearchCommunity: $showSearchCommunity, showSaved: $showSaved, showMemory: $showMemories).frame(width: sideBarWidth)
                
                Rectangle()
                    .frame(width: 1.0, height: widthOrHeight(width: false))
                    .foregroundStyle(.gray).opacity(0.3)

                VStack(spacing: 0) {
                    FeedView(showMenu: $showMenu, storiesUidOrder: $storiesUidOrder, mutedStories: $mutedStories, noneFound: $noneFound, newsAnimation: newsAnimation)
                        .overlay(alignment: .leading){
                            Color.gray.opacity(0.001).frame(width: 18)
                        }
                        .ignoresSafeArea(edges: .bottom)
                }
                .blur(radius: showMenu ? 10 : 0)
                .frame(width: widthOrHeight(width: true))
                .overlay(
                    Rectangle()
                        .fill(
                            Color.primary.opacity( (offset / sideBarWidth) / 6.0 )
                        )
                        .ignoresSafeArea(.container, edges: .all)
                        .onTapGesture {
                            if showMenu {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showMenu = false
                            }
                        }
                )
            }
            .frame(width: sideBarWidth + 1.0 + widthOrHeight(width: true))
            .offset(x: (-sideBarWidth / 2) - 1.0)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .updating($gestureOffset, body: { value, out, _ in
                        out = value.translation.width
                    })
                    .onChanged({ value in
                        if abs(value.translation.height) > 10 && !showMenu {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    })
                    .onEnded(onEnd(value:))
            )
        }
        .navigationDestination(isPresented: $showCreateCommunity) {
            CreateCommView().enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $showSearchCommunity) {
            SearchCommView().enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $showSaved) {
            SavedView().enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $showMemories) {
            MemoriesView { 
                showMemories = false
            }
        }
        .animation(.linear(duration: 0.15), value: offset == 0)
        .onChange(of: showMenu, { _, _ in
            if showMenu {
                if offset == 0 {
                    offset = sideBarWidth
                    lastStoredOffset = offset
                }
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            if !showMenu && offset == sideBarWidth {
                offset = 0
                lastStoredOffset = 0
            }
        })
        .onChange(of: gestureOffset, { _, newValue in
            if showMenu {
                if newValue < 0 {
                    if gestureOffset != 0 {
                        if gestureOffset + lastStoredOffset < sideBarWidth && (gestureOffset + lastStoredOffset) > 0 {
                            offset = lastStoredOffset + gestureOffset
                        } else {
                            if gestureOffset + lastStoredOffset < 0 {
                                offset = 0
                            }
                        }
                    }
                }
            } else {
                if gestureOffset != 0 {
                    if gestureOffset + lastStoredOffset < sideBarWidth && (gestureOffset + lastStoredOffset) > 0 {
                        offset = lastStoredOffset + gestureOffset
                    } else {
                        if gestureOffset + lastStoredOffset < 0 {
                            offset = 0
                        }
                    }
                }
            }
        })
    }
    
    func onEnd(value: DragGesture.Value) {
        let sideBarWidth = widthOrHeight(width: true) - 90
        withAnimation(.spring(duration: 0.15)) {
            if value.translation.width > 0 {
                if value.translation.width > sideBarWidth / 2 {
                    offset = sideBarWidth
                    lastStoredOffset = sideBarWidth
                    if !showMenu {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    showMenu = true
                } else {
                    if value.translation.width > sideBarWidth && showMenu {
                        offset = 0
                        if showMenu {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        showMenu = false
                    } else {
                        let Xp = sideBarWidth / 2.0

                        if value.velocity.width > 800 && value.startLocation.x >= Xp && value.startLocation.x <= Xp + 18 {
                            offset = sideBarWidth
                            if !showMenu {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                            showMenu = true
                        } else if showMenu == false {
                            offset = 0
                        }
                    }
                }
            } else {
                if -value.translation.width > sideBarWidth / 2 {
                    offset = 0
                    if showMenu {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    showMenu = false
                } else {
                    guard showMenu else { return }
                    if -value.velocity.width > 800 {
                        offset = 0
                        if showMenu {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        showMenu = false
                    } else {
                        offset = sideBarWidth
                        if !showMenu {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        showMenu = true
                    }
                }
            }
        }
        lastStoredOffset = offset
    }
}

