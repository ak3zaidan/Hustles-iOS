import SwiftUI

struct MessageBaseView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var v1: GroupChatViewModel
    @EnvironmentObject var v2: MessageViewModel
    @EnvironmentObject var v3: GroupViewModel
    @EnvironmentObject var v4: ProfileViewModel
    @State var offset: CGFloat = 0
    @State var option: Int = 2
    @State var lastStoredOffset: CGFloat = 0
    @GestureState var gestureOffset: CGFloat = 0
    @State var scale: CGFloat = 0.7
    @State var content: Bool = false
    @State var isRecording: Bool = false
    @State var disableTopGesture: Bool = false
    @State var disableSwipe: Bool = false
    
    @Namespace private var animation
    @State var isExpanded: Bool = false
    @Binding var messageOrder: [String]
    
    var body: some View {
        HStack(spacing: 0){
            ZStack {
                Color.black.frame(width: widthOrHeight(width: true)).ignoresSafeArea().zIndex(1)
                
                MessageCameraSec(option: $option, offset: $offset, content: $content, isRecording: $isRecording, showMemories: true){
                    withAnimation(.easeInOut(duration: 0.2)){
                        offset = 0
                        scale = 0.7
                    }
                    lastStoredOffset = 0
                    option = 2
                }
                .frame(width: widthOrHeight(width: true))
                .padding(.top, top_Inset())
                .scaleEffect(scale)
                .zIndex(1)
            }
            .frame(width: widthOrHeight(width: true))
            .cornerRadius(20, corners: .allCorners)
            .ignoresSafeArea()
            .background {
                if colorScheme == .dark {
                    Color(UIColor.lightGray).ignoresSafeArea().zIndex(1)
                } else {
                    Color.black.ignoresSafeArea().zIndex(1)
                }
            }
            .zIndex(1)
            
            if colorScheme == .dark {
                Color(UIColor.lightGray).ignoresSafeArea().frame(width: 13).zIndex(1)
            } else {
                Color.black.ignoresSafeArea().frame(width: 13).zIndex(1)
            }
            
            FullSwipeNavigationStack {
                MessagesHomeView(disableSwipe: $disableSwipe, isExpanded: $isExpanded, animation: animation, messageOrder: $messageOrder, showNotifs: {
                    let width = widthOrHeight(width: true)
                    withAnimation(.easeInOut(duration: 0.25)){
                        offset = -width - 13
                        scale = 1.0
                    }
                    lastStoredOffset = -width - 13
                    option = 3
                }, showMainCamera: {
                    let width = widthOrHeight(width: true)
                    withAnimation(.easeInOut(duration: 0.25)){
                        offset = width + 13
                        scale = 1.0
                    }
                    lastStoredOffset = width + 13
                    option = 1
                })
                .overlay(alignment: .bottom){
                    tabBarMain()
                }
                .background {
                    if colorScheme == .dark {
                        Color.black.ignoresSafeArea()
                    } else {
                        Color.white.ignoresSafeArea()
                    }
                }
                .cornerRadius(20, corners: .allCorners)
                .background {
                    if colorScheme == .dark {
                        Color(UIColor.lightGray).ignoresSafeArea()
                    } else {
                        Color.black.ignoresSafeArea()
                    }
                }
                .ignoresSafeArea()
            }
            .frame(width: widthOrHeight(width: true))
            .ignoresSafeArea()
            .zIndex(1000)
           
            if colorScheme == .dark {
                Color(UIColor.lightGray).ignoresSafeArea().frame(width: 13).zIndex(1)
            } else {
                Color.black.ignoresSafeArea().frame(width: 13).zIndex(1)
            }
            
            SwiftfulMapAppApp(disableTopGesture: $disableTopGesture, option: $option, chatUsers: []){ num in
                if num == 2 {
                    withAnimation(.easeInOut(duration: 0.25)){
                        offset = 0
                        scale = 0.7
                    }
                    lastStoredOffset = 0
                    option = 2
                } else {
                    let width = widthOrHeight(width: true)
                    withAnimation(.easeInOut(duration: 0.15)){
                        offset = width + 13
                        scale = 1.0
                    }
                    lastStoredOffset = width + 13
                    option = 1
                }
            }
            .frame(width: widthOrHeight(width: true))
            .cornerRadius(20, corners: .allCorners)
            .ignoresSafeArea()
            .background {
                if colorScheme == .dark {
                    Color(UIColor.lightGray).ignoresSafeArea().zIndex(1)
                } else {
                    Color.black.ignoresSafeArea().zIndex(1)
                }
            }
            .zIndex(1)
        }
        .onChange(of: option, { _, new in
            if new != 1 {
                v2.initialSend = nil
                content = false
            }
        })
        .offset(x: offset)
        .overlay(alignment: .leading, content: {
            if option == 2 {
                if v1.currentChat == nil && v2.currentChat == nil && v3.currentGroup ==  nil && v4.currentUser == nil && !disableSwipe {
                    let offset = widthOrHeight(width: true) + 13.0
                    
                    Color.gray.opacity(0.001)
                        .frame(width: 15)
                        .offset(x: offset)
                        .simultaneousGesture (
                            DragGesture()
                                .onChanged({ value in
                                    let width = widthOrHeight(width: true)
                                    self.offset = value.translation.width + lastStoredOffset
                                    let ratio = (abs(self.offset) / width) * 0.3
                                    scale = 0.7 + min(0.3, max(0.0, ratio))
                                })
                                .onEnded({ value in
                                    handleDragEnd(value: value, left: true)
                                })
                        )
                }
            }
        })
        .overlay(alignment: .leading, content: {
            if v1.currentChat == nil && v2.currentChat == nil && v3.currentGroup ==  nil && v4.currentUser == nil && !disableSwipe && !disableTopGesture {
                if option == 2 {
                    let offset = widthOrHeight(width: true) * 2.0
                    
                    Color.gray.opacity(0.001)
                        .frame(width: 15)
                        .offset(x: offset)
                        .simultaneousGesture (
                            DragGesture()
                                .onChanged({ value in
                                    let width = widthOrHeight(width: true)
                                    self.offset = value.translation.width + lastStoredOffset
                                    let ratio = (abs(self.offset) / width) * 0.3
                                    scale = 0.7 + min(0.3, max(0.0, ratio))
                                })
                                .onEnded({ value in
                                    handleDragEnd(value: value, left: false)
                                })
                        )
                    
                } else if option == 3 {
                    let offset = widthOrHeight(width: true) + 15.0
                    
                    Color.gray.opacity(0.001)
                        .frame(width: 15)
                        .offset(x: offset)
                        .simultaneousGesture (
                            DragGesture()
                                .onChanged({ value in
                                    let width = widthOrHeight(width: true)
                                    self.offset = value.translation.width + lastStoredOffset
                                    let ratio = (abs(self.offset) / width) * 0.3
                                    scale = 0.7 + min(0.3, max(0.0, ratio))
                                })
                                .onEnded({ value in
                                    handleDragEnd(value: value, left: false)
                                })
                        )
                }
            }
        })
        .simultaneousGesture (
            (option == 1 && !content && !isRecording) ? DragGesture()
                .onChanged({ value in
                    if value.translation.width < 0 {
                        let width = widthOrHeight(width: true)
                        self.offset = value.translation.width + lastStoredOffset
                        let ratio = (abs(offset) / width) * 0.3
                        scale = 0.7 + min(0.3, max(0.0, ratio))
                    }
                })
                .onEnded({ value in
                    handleDragEnd(value: value, left: false)
                }) : nil
        )
        .overlay {
            HStack {
                Spacer()
                if isExpanded {
                    MessageStoriesView(isExpanded: $isExpanded, animation: animation, mid: v4.mid, isHome: true, canOpenChat: true, canOpenProfile: true, openChat: { uid in
                        v2.userMapID = uid
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
                            v2.navigateUserMap = true
                        }
                    }, openProfile: { uid in
                        v2.userMapID = uid
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
                            v2.navigateStoryProfile = true
                        }
                    })
                    .frame(width: widthOrHeight(width: true))
                    .transition(.scale)
                }
                Spacer()
            }
        }
    }
    func handleDragEnd(value: DragGesture.Value, left: Bool) {
        let width = widthOrHeight(width: true)
        
        if option == 1 {
            if offset < (width * 0.6) || value.velocity.width < -400.0 {
                withAnimation(.easeInOut(duration: 0.15)){
                    offset = 0
                    scale = 0.7
                }
                lastStoredOffset = 0
                option = 2
            } else {
                withAnimation(.easeInOut(duration: 0.15)){
                    offset = width + 13
                    scale = 1.0
                }
                lastStoredOffset = width + 13
            }
        } else if option == 2 {
            if offset > (width * 0.4) || (value.velocity.width > 400.0 && left) {
                withAnimation(.easeInOut(duration: 0.15)){
                    offset = width + 13
                    scale = 1.0
                }
                lastStoredOffset = width + 13
                option = 1
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } else if offset < -(width * 0.4) || (value.velocity.width < -400.0 && !left) {
                withAnimation(.easeInOut(duration: 0.15)){
                    offset = -width - 13
                    scale = 1.0
                }
                lastStoredOffset = -width - 13
                option = 3
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } else {
                withAnimation(.easeInOut(duration: 0.15)){
                    offset = 0
                    scale = 0.7
                }
                lastStoredOffset = 0
            }
        } else {
            if offset > -(width * 0.6) || value.velocity.width > 400.0 {
                withAnimation(.easeInOut(duration: 0.15)){
                    offset = 0
                    scale = 0.7
                }
                lastStoredOffset = 0
                option = 2
            } else {
                withAnimation(.easeInOut(duration: 0.15)){
                    offset = -width - 13
                    scale = 1.0
                }
                lastStoredOffset = -width - 13
            }
        }
    }
}
