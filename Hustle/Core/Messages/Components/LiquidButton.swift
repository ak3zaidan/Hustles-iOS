import SwiftUI

struct SaveImageButton: View {
    @State var saved: Bool = false
    @State var scale: Bool = false
    @State var ringscale: Bool = false
    @State var showRing: Bool = false
    @State var hideAll: Bool = false
    @State var clicked: Bool = false
    @State var size = 1.0
    let url: String
    let video: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if !hideAll {
                Button {
                    if !clicked {
                        clicked = true
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scale = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                scale = false
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.spring(duration: 0.3)) {
                                size = 35.0
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                showRing = true
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                ringscale = false
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                ringscale = true
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                saved = true
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                hideAll = true
                            }
                        }
                        if video {
                            if let url = URL(string: url) {
                                downloadVideoFromURL(url)
                            }
                        } else {
                            downloadAndSaveImage(url: url)
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.gray, lineWidth: 1.0)
                            .frame(width: 35)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                        
                        if showRing {
                            Circle()
                                .stroke(.blue, lineWidth: 0.2)
                                .frame(width: 35)
                                .scaleEffect(ringscale ? 1.75 : 1.0)
                        }
                        
                        Circle().frame(width: size).foregroundStyle(.blue)
                        
                        
                        Circle()
                            .stroke(colorScheme == .dark ? .white : .black, lineWidth: 3.5)
                            .frame(width: size).opacity(size == 1.0 ? 0.0 : 1.0)
                        
                        if saved {
                            Image(systemName: "checkmark")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .scaleEffect(scale ? 0.2 : 1.0)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundStyle(.blue)
                                .font(.headline)
                                .scaleEffect(scale ? 0.2 : 1.0)
                                .offset(y: -2)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct LiquidMenuButtons: View {
    @State var offsetOne: CGSize = .zero
    @State var offsetTwo: CGSize = .zero
    @State var offsetThree: CGSize = .zero
    @State var offsetFour: CGSize = .zero
    @State var offsetFive: CGSize = .zero
    @State var offsetSix: CGSize = .zero
    @State var offsetSeven: CGSize = .zero
    @Binding var isCollapsed: Bool
    @State private var trueSize: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @Binding var showFilePicker: Bool
    @Binding var showCameraPicker: Bool
    @Binding var showLibraryPicker: Bool
    @Binding var sendElo: Bool
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @Binding var addAudio: Bool
    @State private var showText: Bool = false
    let isChat: Bool
    @State private var showing: Bool = false
    @State private var showMapSheet: Bool = false
    @State var showAddPoll: Bool = false
    @Binding var showMemoryPicker: Bool
    @State var showTextCorrection = false
    @State var showAI = false
    @Binding var captionBind: String
    
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
                    Rectangle()
                        .fill(.linearGradient(colors: [.blue, .green], startPoint: .bottom, endPoint: .top))
                        .mask(canvas)
                        .overlay {
                            ZStack(alignment: .leading){
                                CancelButton()
                                    .rotationEffect(Angle(degrees: showAI ? 0 : isCollapsed ? 90 : 45))
                                    .offset(x: isCollapsed ? -1 : 0, y: isCollapsed ? 0.5 : 0)
                                CameraButton().offset(offsetOne).opacity(isCollapsed ? 1 : 0)
                                PhotosButton().offset(offsetTwo).opacity(isCollapsed ? 1 : 0)
                                FilesButton().offset(offsetThree).opacity(isCollapsed ? 1 : 0)
                                audioButton().offset(offsetFour).opacity(isCollapsed ? 1 : 0)
                                MapButton().offset(offsetFive).opacity(isCollapsed ? 1 : 0)
                                memoryButton().offset(offsetSix).opacity(isCollapsed ? 1 : 0)
                                if isChat {
                                    EloButton().offset(offsetSeven).opacity(isCollapsed ? 1 : 0)
                                } else {
                                    pollButton().offset(offsetSeven).opacity(isCollapsed ? 1 : 0)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .offset(x: 9.5, y: -4)
                        }
                        .frame(width: isCollapsed ? 200 : 65, height: isCollapsed ? 450 : 65)
                    Spacer()
                }
            }
        }
        .offset(x: showAI ? -5 : 0)
        .sheet(isPresented: $showTextCorrection, content: {
            RecommendTextView(oldText: $captionBind)
        })
        .sheet(isPresented: $showMapSheet) {
            SendLocationView().presentationDetents([.large])
        }
        .sheet(isPresented: $showAddPoll, content: {
            ChatPollView(isDevGroup: false)
        })
        .onChange(of: captionBind) { _, _ in
            if captionBind.count > 30, !showAI && !isCollapsed {
                withAnimation(.easeInOut(duration: 0.1)){
                    showAI = true
                }
            } else if showAI && captionBind.count <= 30 {
                withAnimation(.easeInOut(duration: 0.1)){
                    showAI = false
                }
            }
        }
    }
    var canvas: some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.9, color: .black))
            context.addFilter(.blur(radius: 5))

            context.drawLayer { ctx in
                for index in [1,2,3,4,5,6,7,8] {
                    if let resolvedView = context.resolveSymbol(id: index) {
                        ctx.draw(resolvedView, at: CGPoint(x: 32, y: size.height - 27))
                    }
                }
            }
        } symbols: {
            mainSymbol().tag(1)

            Symbol(offset: offsetOne, diameter: 52).tag(2).opacity(trueSize ? 1 : 0)
            
            Symbol(offset: offsetTwo, diameter: 52).tag(3).opacity(trueSize ? 1 : 0)
            
            Symbol(offset: offsetThree, diameter: 52).tag(4).opacity(trueSize ? 1 : 0)
            
            Symbol(offset: offsetFour, diameter: 52).tag(5).opacity(trueSize ? 1 : 0)
            
            Symbol(offset: offsetFive, diameter: 52).tag(6).opacity(trueSize ? 1 : 0)
            
            Symbol(offset: offsetSix, diameter: 52).tag(7).opacity(trueSize ? 1 : 0)
            
            Symbol(offset: offsetSeven, diameter: 52).tag(8).opacity(trueSize ? 1 : 0)
        }
    }
}

extension LiquidMenuButtons {
    private func Symbol(offset: CGSize = .zero, diameter: CGFloat = 45) -> some View {
        Circle().frame(width: diameter, height: diameter).offset(offset)
    }
    private func mainSymbol() -> some View {
        Capsule().frame(width: showAI ? 54 : 44, height: 44)
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
            offsetOne  = isCollapsed ? CGSize(width: 0, height: -55) : .zero
            offsetTwo  = isCollapsed ? CGSize(width: 0, height: -112) : .zero
            offsetThree  = isCollapsed ? CGSize(width: 0, height: -169) : .zero
            offsetFour  = isCollapsed ? CGSize(width: 0, height: -226) : .zero
            offsetFive  = isCollapsed ? CGSize(width: 0, height: -283) : .zero
            offsetSix  = isCollapsed ? CGSize(width: 0, height: -340) : .zero
            offsetSeven  = isCollapsed ? CGSize(width: 0, height: -397) : .zero
        }
    }
    func CancelButton() -> some View {
        ZStack {
            if showAI {
                ZStack {
                    LottieView(loopMode: .loop, name: "finite")
                        .scaleEffect(0.053)
                        .frame(width: 45, height: 14).transition(.scale)
                }
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showTextCorrection = true
                }
            } else {
                ZStack {
                    Image(systemName: "xmark")
                        .frame(width: 45, height: 14).transition(.scale)
                        .aspectRatio(.zero, contentMode: .fit).contentShape(Circle())
                }
                .offset(x: -1, y: -0.5)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    closeView()
                }
            }
        }
    }
    func CameraButton() -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showCameraPicker = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
        } label: {
            HStack(spacing: 15){
                Image(systemName: "camera.fill")
                    .scaleEffect(1.2).foregroundStyle(.white)
                    .frame(width: 45)
                if showText {
                    Text("Camera")
                        .font(.title3).bold()
                }
            }.frame(height: 45)
        }
    }
    func PhotosButton() -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showLibraryPicker = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
        } label: {
            HStack(spacing: 15){
                Image(systemName: "photo").scaleEffect(1.3).foregroundStyle(.white)
                    .frame(width: 45)
                if showText {
                    Text("Media")
                        .font(.title3).bold()
                }
            }.frame(height: 45)
        }
    }
    func FilesButton() -> some View {
        Button {
            showFilePicker = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 15){
                Image(systemName: "paperclip")
                    .scaleEffect(1.4).foregroundStyle(.white)
                    .frame(width: 45)
                if showText {
                    Text("Files")
                        .font(.title3).bold()
                }
            }.frame(height: 45)
        }
    }
    func MapButton() -> some View {
        Button {
            showMapSheet = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 15){
                Image(systemName: "mappin.and.ellipse")
                    .scaleEffect(1.4).foregroundStyle(.white)
                    .frame(width: 45)
                if showText {
                    Text("Location")
                        .font(.title3).bold()
                }
            }.frame(height: 45)
        }
    }
    
    func audioButton() -> some View {
        Button {
            addAudio = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 15){
                Image(systemName: "mic.fill")
                    .scaleEffect(1.4).scaleEffect(y: 0.85).foregroundStyle(.white)
                    .frame(width: 45)
                if showText {
                    Text("Audio")
                        .font(.title3).bold()
                }
            }.frame(height: 45)
        }
    }
    func pollButton() -> some View {
        Button {
            showAddPoll = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 15){
                Image(systemName: "chart.bar.fill")
                    .scaleEffect(1.1).foregroundStyle(.white)
                    .frame(width: 45)
                if showText {
                    Text("Poll")
                        .font(.title3).bold()
                }
            }.frame(height: 45)
        }
    }
    func memoryButton() -> some View {
        Button {
            showMemoryPicker = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                closeView()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 15){
                Image("memWhite")
                    .resizable().scaledToFit().frame(width: 33, height: 33)
                    .frame(width: 45)
                if showText {
                    Text("Memory")
                        .font(.title3).bold()
                }
            }.frame(height: 45)
        }
    }
    func EloButton() -> some View {
        Button {
            if let elo = auth.currentUser?.elo {
                if let index = viewModel.currentChat {
                    if elo < 850 {
                        popRoot.alertReason = "You must have 850ELO to use this feature"
                        popRoot.alertImage = "exclamationmark.triangle.fill"
                        withAnimation {
                            popRoot.showAlert = true
                        }
                    } else if viewModel.chats[index].user.elo > elo{
                        popRoot.alertReason = "You can only send elo to a lower level"
                        popRoot.alertImage = "exclamationmark.triangle.fill"
                        withAnimation {
                            popRoot.showAlert = true
                        }
                    } else {
                        sendElo.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            closeView()
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 15){
                Image(systemName: "dollarsign")
                    .scaleEffect(1.4).foregroundStyle(.white)
                    .frame(width: 45)
                if showText {
                    Text("ELO")
                        .font(.title3).bold()
                }
            }.frame(height: 45)
        }
    }
}

