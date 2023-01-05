import SwiftUI

struct PlusButtonView: View {
    @State var offsetOne: CGSize = .zero
    @State var offsetTwo: CGSize = .zero
    @State var offsetThree: CGSize = .zero
    @State var offsetFour: CGSize = .zero
    @Binding var isCollapsed: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var trueSize: Bool = false
    @State private var showText: Bool = false
    @State private var showCallSheet: Bool = false
    @State private var showChatSheet: Bool = false
    @State var navigateNow: Bool = false
    @State var navigateNowGroup: Bool = false
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @State var selectedUser: String? = nil
    @State private var showing: Bool = false
    @State private var showExploreGC: Bool = false
    @Binding var navToProfile: Bool
    
    var body: some View {
        ZStack {
            if isCollapsed && showing {
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 7, opaque: true)
                    .background(colorScheme == .dark ? .black.opacity(0.3) : .white.opacity(0.3))
                    .onTapGesture {
                        closeView()
                    }
                    .ignoresSafeArea()
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(.linearGradient(colors: [.blue, .purple], startPoint: .bottom, endPoint: .top))
                        .mask(canvas)
                        .overlay {
                            ZStack(alignment: .trailing){
                                CancelButton()
                                    .rotationEffect(Angle(degrees: isCollapsed ? 90 : 45))
                                    .offset(x: isCollapsed ? -0.5 : -0.75, y: 0.5)
                                chatButton().offset(offsetOne).opacity(isCollapsed ? 1 : 0)
                                channelButton().offset(offsetTwo).opacity(isCollapsed ? 1 : 0)
                                videoCallButton().offset(offsetThree).opacity(isCollapsed ? 1 : 0)
                                newLive().offset(offsetFour).opacity(isCollapsed ? 1 : 0)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .offset(x: -37, y: -3)
                        }
                        .frame(width: isCollapsed ? 200 : 85, height: isCollapsed ? 550 : 50, alignment: .top)
                }.padding(.bottom, 128)
            }
        }
        .navigationDestination(isPresented: $showExploreGC) {
            SearchGroupsView().enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $navigateNow) {
            MessagesView(exception: false, user: nil, uid: selectedUser ?? "", tabException: true, canCall: true)
                .enableFullSwipePop(true)
        }
        .navigationDestination(isPresented: $navigateNowGroup) {
            GroupChatView(groupID: selectedUser ?? "", navUserId: $viewModel.userMapID, navToUser: $viewModel.navigateUserMap, navToProfile: $navToProfile)
                .enableFullSwipePop(true)
        }
        .sheet(isPresented: $showCallSheet, content: {
            CallSheetView().presentationDetents([.large])
        })
        .sheet(isPresented: $showChatSheet, content: {
            ChatSheetView(navigateNow: $navigateNow, navigateNowGroup: $navigateNowGroup, selectedUser: $selectedUser).presentationDetents([.large])
        })
    }
    var canvas: some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.9, color: .black))
            context.addFilter(.blur(radius: 5))

            context.drawLayer { ctx in
                for index in [1,2,3,4,5] {
                    if let resolvedView = context.resolveSymbol(id: index) {
                        ctx.draw(resolvedView, at: CGPoint(x: size.width - 60, y: size.height - 25))
                    }
                }
            }
        } symbols: {
            Symbol(offset: .zero, diameter: 50)
                .scaleEffect(isCollapsed ? 0.9 : 1.15)
                .tag(1)

            Symbol(offset: offsetOne, diameter: 60).tag(2).opacity(trueSize ? 1 : 0)
            
            Symbol(offset: offsetTwo, diameter: 60).tag(3).opacity(trueSize ? 1 : 0)
            
            Symbol(offset: offsetThree, diameter: 60).tag(4).opacity(trueSize ? 1 : 0)
            
            Symbol(offset: offsetFour, diameter: 60).tag(5).opacity(trueSize ? 1 : 0)
        }
    }
}

extension PlusButtonView {
    private func Symbol(offset: CGSize = .zero, diameter: CGFloat = 45) -> some View {
        Circle().frame(width: diameter, height: diameter).offset(offset)
    }
    func closeView(){
        if !isCollapsed {
            showing = true
            withAnimation(.easeIn(duration: 1.0)){
                showText = true
            }
            withAnimation(.easeIn(duration: 0.05)){
                trueSize.toggle()
            }
        } else {
            showing = false
            withAnimation(.easeIn(duration: 0.1)){
                showText = false
            }
            withAnimation(.easeIn(duration: 0.4)){
                trueSize.toggle()
            }
        }
        withAnimation { isCollapsed.toggle() }
        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.1).speed(0.5)) {
            offsetOne  = isCollapsed ? CGSize(width: 0, height: -75) : .zero
            offsetTwo  = isCollapsed ? CGSize(width: 0, height: -145) : .zero
            offsetThree  = isCollapsed ? CGSize(width: 0, height: -215) : .zero
            offsetFour  = isCollapsed ? CGSize(width: 0, height: -285) : .zero
        }
    }
    func CancelButton() -> some View {
        ZStack {
            Image(systemName: "xmark")
                .fontWeight(.semibold)
                .frame(width: 45, height: 14)
                .aspectRatio(.zero, contentMode: .fit).contentShape(Circle())
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            closeView()
        }
    }
    func chatButton() -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
            viewModel.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
            showChatSheet = true
        } label: {
            HStack(spacing: 15){
                if showText {
                    Text("New Chat")
                        .font(.title2).bold()
                }
                Image(systemName: "message.fill")
                    .scaleEffect(1.2).foregroundStyle(.white)
                    .frame(width: 45)
            }.frame(height: 45)
        }
    }
    func channelButton() -> some View {
        Button {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showExploreGC = true
        } label: {
            HStack(spacing: 15){
                if showText {
                    Text("New Channel")
                        .font(.title2).bold()
                }
                Image(systemName: "person.3.fill")
                    .scaleEffect(1.1).foregroundStyle(.white)
                    .frame(width: 45)
            }.frame(height: 45)
        }
    }
    func videoCallButton() -> some View {
        Button {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.getSearchContent(currentID: auth.currentUser?.id ?? "", following: auth.currentUser?.following ?? [])
            showCallSheet = true
        } label: {
            HStack(spacing: 15){
                if showText {
                    Text("New Call")
                        .font(.title2).bold()
                }
                Image(systemName: "video.fill")
                    .scaleEffect(1.3).foregroundStyle(.white)
                    .frame(width: 45)
            }.frame(height: 45)
        }
    }
    func newLive() -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
        } label: {
            HStack(spacing: 15){
                if showText {
                    Text("New Live")
                        .font(.title2).bold()
                }
                Image(systemName: "livephoto")
                    .scaleEffect(1.4).foregroundStyle(.white)
                    .frame(width: 45).offset(x: -1)
            }.frame(height: 45)
        }
    }
}
