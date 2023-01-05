import SwiftUI
import Kingfisher
import UIKit
import AVFoundation

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var explore: ExploreViewModel
    @State var offset: CGFloat = 0.0
    @Namespace private var newsAnimation
        
    init() {
        UITabBar.appearance().isHidden = true
        UIRefreshControl.appearance().tintColor = .clear
    }

    var body: some View {
        Group {
            if viewModel.userSession == nil {
                NavigationStack {
                    WelcomeView().dynamicTypeSize(.large)
                }
            } else {
                MainTabView(newsAnimation: newsAnimation)
                    .dynamicTypeSize(.large)
                    .onAppear {
                        if !explore.gotBreaking {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                explore.getBreaking()
                            }
                        }
                    }
                    .overlay(content: {
                        if explore.showBreaking {
                            if let news = explore.news.first(where: { $0.breaking != nil }) {
                                breakingNews(news: news)
                            }
                        }
                    })
                    .overlay(content: {
                        if popRoot.isNewsExpanded {
                            if let news = explore.news.first(where: { $0.id == popRoot.selectedNewsID }) {
                                TopNewsView(animation: newsAnimation, newsMid: popRoot.newsMid, animate: true, news: news)
                            }
                        }
                    })
                    .overlay {
                        if popRoot.showImage && !popRoot.image.isEmpty {
                            TopImageView(isPresented: $popRoot.showImage, imageReset: $popRoot.image, image: popRoot.image)
                        }
                        if popRoot.realImage != nil && popRoot.showImageMessage {
                            TopImageRealView(isPresented: $popRoot.showImageMessage, image: $popRoot.realImage)
                        }
                        if popRoot.showCopy && !popRoot.TextToCopy.isEmpty {
                            CopyRealView(showCopy: $popRoot.showCopy, textCopy: $popRoot.TextToCopy)
                        }
                        if popRoot.player != nil {
                            TopVideoView(player: $popRoot.player, idV: popRoot.playID)
                        }
 
                        if popRoot.showAlert, !popRoot.alertReason.isEmpty {
                            VStack {
                                bannerView().frame(width: widthOrHeight(width: true))
                                Spacer()
                            }
                            .padding(.top)
                            .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                        }
                        if popRoot.chatSentAlert {
                            VStack {
                                ChatSentBanner().frame(width: widthOrHeight(width: true))
                                Spacer()
                            }
                            .padding(.top)
                            .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                        }
                    }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .alert("Post deleted, allow a few moments for change", isPresented: $popRoot.show) {
            Button("Close", role: .cancel) { }
        }
        .onChange(of: popRoot.showImage) { _, _ in
            if popRoot.showImage {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .onChange(of: popRoot.showImageMessage) { _, _ in
            if popRoot.showImageMessage {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    @ViewBuilder
    func breakingNews(news: News) -> some View {
        VStack {
            let mid = (news.id ?? "") + "breaking"
            
            if !popRoot.isNewsExpanded || popRoot.newsMid != mid {
                NewsRowView(news: news, isRow: false)
                    .background(content: {
                        ZStack {
                            if colorScheme == .dark {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.black)
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.gray).opacity(0.35)
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.white)
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.gray).opacity(0.2)
                            }
                        }
                    })
                    .overlay(content: {
                        RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2.0)
                    })
                    .matchedGeometryEffect(id: mid, in: newsAnimation)
                    .offset(y: offset * 0.3)
                    .onTapGesture {
                        popRoot.selectedNewsID = news.id ?? ""
                        popRoot.newsMid = mid
                        withAnimation(.easeInOut(duration: 0.25)){
                            popRoot.isNewsExpanded = true
                        }
                    }
                    .gesture(DragGesture()
                        .onChanged({ value in
                            self.offset = value.translation.height
                        })
                        .onEnded({ value in
                            withAnimation(.easeInOut(duration: 0.2)){
                                self.offset = 0.0
                            }
                            if value.translation.height > 10 {
                                popRoot.selectedNewsID = news.id ?? ""
                                popRoot.newsMid = mid
                                withAnimation(.easeInOut(duration: 0.25)){
                                    popRoot.isNewsExpanded = true
                                }
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            } else {
                                withAnimation(.easeInOut(duration: 0.2)){
                                    explore.showBreaking = false
                                }
                            }
                        })
                    )
                    .padding(.horizontal, 10)
            }
            Spacer()
        }
        .padding(.top, 10)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                if offset == 0.0 && popRoot.newsMid != ((news.id ?? "") + "breaking") {
                    withAnimation(.easeInOut(duration: 0.2)){
                        explore.showBreaking = false
                    }
                }
            }
        })
        .onChange(of: popRoot.isNewsExpanded) { _, _ in
            if explore.showBreaking && !popRoot.isNewsExpanded {
                withAnimation(.easeInOut(duration: 0.3)){
                    explore.showBreaking = false
                }
            }
        }
    }
}

struct TopVideo: View {
    @Binding var player: AVPlayer?
    let idV: String
    @State var aspect: CGSize = CGSize(width: 16, height: 9)
    @State private var orien: UIDeviceOrientation = .portrait
    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero
    @State var showControls: Bool = false
    @State var vidPlaying: Bool = true
    @State var muted: Bool = false
    @State var timer: Timer? = nil
    @State var currentTime: Double = 0.0
    @State var totalTime: Double = 1.0
    @State var tempOffset: Double = 0.0
    @StateObject var orientationViewModel = OrientationTracker()
    @State private var position = 1
    @State var offsetC: CGSize = .zero
    @State var compressed: Bool = false
    @Namespace private var namespace
    
    var body: some View {
        ZStack {
            if !compressed {
                Color.black
                    .offset(x: tempOffset)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.1)){
                            showControls = true
                        }
                    }
            }
            
            if let vid = player {
                let portrait = (orien == .portrait || orien == .unknown || orien == .portraitUpsideDown)
                let width = widthOrHeight(width: true)
                let height = widthOrHeight(width: false)
                
                let vid_width = portrait ? width : (height * CGFloat(aspect.width / aspect.height))
                let vid_height = !portrait ? width : (height * CGFloat(aspect.height / aspect.width))
                
                let final_width = vid_width > width ? width : vid_width
                let final_height = vid_height > height ? height : vid_height
                
                if compressed {
                    VStack {
                        if position == 3 || position == 4 {
                            Spacer()
                        }
                        HStack {
                            if position == 2 || position == 4 {
                                Spacer()
                            }
                            VidPlayer(player: vid)
                                .rotationEffect(.degrees((orien == .portrait || orien == .unknown)  ? 0.0 : orien == .portraitUpsideDown ? 180.0 : orien == .landscapeLeft ? 90 : -90 ))
                                .matchedGeometryEffect(id: "squareAnim", in: namespace)
                                .frame(width: final_width * 0.25, height: final_height * 0.25)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(content: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.blue, lineWidth: 2)
                                })
                                .offset(offsetC)
                                .onTapGesture {
                                    withAnimation {
                                        compressed = false
                                    }
                                }
                                .gesture(DragGesture()
                                    .onChanged({ val in
                                        offsetC = val.translation
                                    })
                                    .onEnded({ val in
                                        let posX = val.predictedEndLocation.x
                                        let posY = val.predictedEndLocation.y

                                        withAnimation(.spring) {
                                            offsetC = .zero
                                            if abs(posX) > (width / 2) && abs(posY) < (height / 2){
                                                if posX < 0 {
                                                    if position > 2 {
                                                        position = 3
                                                    } else {
                                                        position = 1
                                                    }
                                                } else if posX >= 0 {
                                                    if position > 2 {
                                                        position = 4
                                                    } else {
                                                        position = 2
                                                    }
                                                }
                                            } else if abs(posY) > (height / 2) && abs(posX) < (width / 2){
                                                if posY < 0 {
                                                    if position == 3 {
                                                        position = 1
                                                    } else {
                                                        position = 2
                                                    }
                                                } else if posY >= 0 {
                                                    if position == 1 {
                                                        position = 3
                                                    } else {
                                                        position = 4
                                                    }
                                                }
                                            } else {
                                                if posX > (width / 2) && posY > (height / 2) {
                                                    position = 4
                                                } else if abs(posX) > (width / 2) && abs(posY) > (height / 2) && posX < 0 && posY < 0 {
                                                    position = 1
                                                } else if abs(posX) > (width / 2) && abs(posY) > (height / 2) && posX < 0 && posY > 0 {
                                                    position = 3
                                                } else if abs(posX) > (width / 2) && abs(posY) > (height / 2) && posX > 0 && posY < 0 {
                                                    position = 2
                                                }
                                            }
                                        }
                                    })
                                )
                            if position == 1 || position == 3 {
                                Spacer()
                            }
                        }
                        if position == 1 || position == 2 {
                            Spacer()
                        }
                    }.padding(.horizontal, 10).padding(.top, top_Inset()).padding(.bottom, 90)
                } else {
                    VidPlayer(player: vid)
                        .rotationEffect(.degrees((orien == .portrait || orien == .unknown)  ? 0.0 : orien == .portraitUpsideDown ? 180.0 : orien == .landscapeLeft ? 90 : -90 ))
                        .matchedGeometryEffect(id: "squareAnim", in: namespace)
                        .frame(width: final_width, height: final_height)
                        .offset(x: offset.x, y: offset.y)
                        .gesture(makeDragGesture(size: CGSize(width: final_width, height: final_height)))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.1)){
                                showControls = true
                            }
                        }
                }
                
                if showControls && !compressed {
                    Color.black.opacity(0.3)
                        .gesture(makeDragGesture(size: CGSize(width: final_width, height: final_height)))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.1)){
                                showControls = false
                            }
                        }
                    if offset.y == 0.0 {
                        controls(portrait: portrait, h1: width, h2: height)
                            .rotationEffect(.degrees((orien == .portrait || orien == .unknown)  ? 0.0 : orien == .portraitUpsideDown ? 180.0 : orien == .landscapeLeft ? 90 : -90 ))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: orientationViewModel.currentOrientation) { _,_ in
            withAnimation(.easeInOut(duration: 0.2)){
                orien = orientationViewModel.currentOrientation
            }
        }
        .onAppear {
            if let temp_aspect = VideoCacheManager.shared.playerSize(for: URL(string: idV)!) {
                self.aspect = temp_aspect
            } else {
                Task {
                    do {
                        if let final = try await getVideoResolution(url: idV) {
                            self.aspect = final
                            VideoCacheManager.shared.setSize(aspect: final, url: URL(string: idV)!)
                        }
                    } catch { }
                }
            }
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if let curr = player?.currentTime().seconds {
                    currentTime = curr
                }
                if let total = player?.currentItem?.duration.seconds {
                    totalTime = total
                }
            }
            orientationViewModel.startDeviceOrientationTracking()
        }
        .onDisappear {
            orientationViewModel.stopDeviceOrientationTracking()
            if timer != nil {  timer?.invalidate() }
        }
    }
    func controls(portrait: Bool, h1: CGFloat, h2: CGFloat) -> some View {
        ZStack {
            VStack {
                HStack(spacing: 14){
                    Button(action: {
                        close(size: h1)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(.gray).opacity(0.001)
                            Image(systemName: "xmark").foregroundStyle(.white).font(.title3)
                        }.frame(width: 40, height: 40)
                    })
                    Spacer()
                    Button(action: {
                        if muted {
                            player?.isMuted = false
                        } else {
                            player?.isMuted = true
                        }
                        muted.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(.gray).opacity(0.001)
                            if muted {
                                Image(systemName: "speaker.slash.fill").foregroundStyle(.white).font(.title3)
                            } else {
                                Image(systemName: "speaker.wave.2").foregroundStyle(.white).font(.title3)
                            }
                        }.frame(width: 40, height: 40)
                    })
                    Button(action: {
                        withAnimation {
                            compressed = true
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(.gray).opacity(0.001)
                            Image(systemName: "arrow.down.right.and.arrow.up.left").foregroundStyle(.white).font(.title3)
                        }.frame(width: 40, height: 40)
                    })
                }.transition(.move(edge: .top))
                Spacer()
 
                MusicProgressSlider(value: $currentTime, inRange: TimeInterval.zero...totalTime, activeFillColor: .white, fillColor: Color.white.opacity(0.5), emptyColor: Color.white.opacity(0.3), height: 37) { _ in
                    if player != nil {
                        let time = CMTime(seconds: currentTime, preferredTimescale: 600)
                        player?.seek(to: time)
                    }
                }.transition(.move(edge: .bottom))
            }
            .padding(.vertical, portrait ? top_Inset() + 20 : 15).padding(.horizontal, portrait ? 15 : top_Inset() + 15)
            .frame(width: portrait ? h1 : h2, height: portrait ? h2 : h1)
                
            VStack {
                Spacer()
                HStack(spacing: 45){
                    Spacer()
                    Button(action: {
                        seekVideo(by: -15.0)
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(.gray).opacity(0.001)
                            Image(systemName: "gobackward.15").foregroundStyle(.white).font(.title)
                        }.frame(width: 50, height: 50)
                    })
                    Button(action: {
                        if vidPlaying {
                            player?.pause()
                        } else {
                            player?.play()
                        }
                        vidPlaying.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(.gray).opacity(0.001)
                            if vidPlaying {
                                Image(systemName: "pause.fill").foregroundStyle(.white).font(.system(size: 40))
                            } else {
                                Image(systemName: "play.fill").foregroundStyle(.white).font(.system(size: 40))
                            }
                        }.frame(width: 55, height: 55)
                    })
                    Button(action: {
                        seekVideo(by: 15.0)
                    }, label: {
                        ZStack {
                            Circle().foregroundStyle(.gray).opacity(0.001)
                            Image(systemName: "goforward.15").foregroundStyle(.white).font(.title)
                        }.frame(width: 50, height: 50)
                    })
                    Spacer()
                }
                Spacer()
            }
        }
    }
    private func seekVideo(by seconds: Double) {
        if player != nil {
            if let currentTime = player?.currentTime().seconds {
                let newTime = max(0, currentTime + seconds)
                if let total = player?.currentItem?.duration.seconds, total < newTime {
                    let time = CMTime(seconds: 0, preferredTimescale: 600)
                    player?.seek(to: time)
                } else {
                    let time = CMTime(seconds: newTime, preferredTimescale: 600)
                    player?.seek(to: time)
                }
            }
        }
    }
    private func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                lastTranslation = value.translation
            }
            .onEnded { _ in
                if offset.y > 100 {
                    close(size: size.width)
                } else {
                    adjustMaxOffset(size: size)
                }
            }
    }
    func close(size: CGFloat){
        showControls = false
        withAnimation(.linear(duration: 0.1)){
            offset.y = .zero
        }
        withAnimation(.linear(duration: 0.2)){
            offset.x = size
            tempOffset = size
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            withAnimation {
                player = nil
            }
        }
    }
    private func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (1 - 1)) / 2
        let maxOffsetY = (size.height * (1 - 1)) / 2

        var newOffsetX = offset.x
        var newOffsetY = offset.y

        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }

        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }
        self.lastTranslation = .zero
    }
}

struct TopVideoView: View {
    @Namespace private var animation
    @Binding var player: AVPlayer?
    let idV: String
    @State private var hostingController: UIHostingController<TopVideo>? = nil

    func showImage() {
        let swiftUIView = TopVideo(player: $player, idV: idV)
        hostingController = UIHostingController(rootView: swiftUIView)
        hostingController?.view.backgroundColor = .clear
        hostingController?.view.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(hostingController!.view)

            hostingController?.view.center.x = window.center.x
        }
    }

    func dismissImage() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }

    var body: some View {
        VStack {}
            .onAppear { showImage() }
            .onDisappear { dismissImage() }
    }
}

struct CopyReal: View {
    @Binding var textCopy: String
    @Binding var showCopy: Bool

    var body: some View {
        ZStack {
            Color.gray.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 5){
                Spacer()
                Text(textCopy)
                    .lineLimit(10)
                    .truncationMode(.tail)
                    .font(.subheadline).foregroundColor(.black).padding()
                    .multilineTextAlignment(.leading).frame(width: widthOrHeight(width: true) * 0.8).background(.white).cornerRadius(14)
                ZStack {
                    RoundedRectangle(cornerRadius: 14).foregroundColor(.white)
                    Button {
                        UIPasteboard.general.string = textCopy
                        textCopy = ""
                        showCopy = false
                    } label: {
                        HStack {
                            Text("Copy Text").font(.system(size: 18)).foregroundColor(.black)
                            Spacer()
                            Image(systemName: "square.on.square").foregroundColor(.blue).font(.subheadline)
                        }.padding(.horizontal)
                    }
                }.frame(width: widthOrHeight(width: true) * 0.8, height: 50)
                Spacer()
            }
        }
        .dynamicTypeSize(.large)
        .onTapGesture {
            textCopy = ""
            showCopy = false
        }
        .ignoresSafeArea()
    }
}

struct CopyRealView: View {
    @Binding var showCopy: Bool
    @Binding var textCopy: String
    @State private var hostingController: UIHostingController<CopyReal>? = nil

    func showImage() {
        let swiftUIView = CopyReal(textCopy: $textCopy, showCopy: $showCopy)
        hostingController = UIHostingController(rootView: swiftUIView)
        hostingController?.view.backgroundColor = .clear
        hostingController?.view.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(hostingController!.view)

            hostingController?.view.center.x = window.center.x
        }
    }

    func dismissImage() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if showCopy {
                VStack {}
                    .onAppear {
                        showImage()
                    }
                    .onDisappear {
                        dismissImage()
                    }
                    .onChange(of: textCopy) { _, newValue in
                        dismissImage()
                        showImage()
                    }
            }
        }
    }
}

struct TopImageReal: View {
    @Binding var image: Image?
    @Binding var isPres: Bool
    @State var imageHeight: Double = 0.0
    @State var imageWidth: Double = 0.0
    @State var opac: Double = 1.0
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero

    var body: some View {
        ZStack {
            Rectangle().foregroundColor(.black).opacity(opac).ignoresSafeArea()
            GeometryReader { geometry in
                image!
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(x: offset.x + (widthOrHeight(width: true) - imageWidth) / 2.0, y: offset.y + (widthOrHeight(width: false) - imageHeight) / 2.0)
                    .gesture(makeDragGesture(size: geometry.size))
                    .gesture(makeMagnificationGesture(size: geometry.size))
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    imageHeight = proxy.size.height
                                    imageWidth = proxy.size.width
                                }
                            
                        }
                    )
            }
        }
        .onTapGesture {
            withAnimation(.linear(duration: 0.1)){
                isPres = false
                image = nil
            }
        }
        .ignoresSafeArea()
        .onChange(of: offset) { _, _ in
            if scale < 1.3 {
                let height = abs(offset.y) > abs(offset.x) ? abs(offset.y) : abs(offset.x)
                if height < 10 {
                    opac = 1.0
                } else if height > 300 {
                    opac = 0.7
                } else {
                    let opacityRange = 0.3
                    let heightRange = 290.0
                    let opacity = 1.0 - (height / heightRange) * opacityRange
                    opac = opacity
                }
            }
        }
    }
    private func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value

                if abs(1 - delta) > 0.01 {
                    scale *= delta
                }
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation {
                        scale = 1
                    }
                }
                adjustMaxOffset(size: size)
            }
    }
    private func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                lastTranslation = value.translation
            }
            .onEnded { _ in
                adjustMaxOffset(size: size)
            }
    }
    private func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2

        var newOffsetX = offset.x
        var newOffsetY = offset.y

        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }

        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }
        self.lastTranslation = .zero
    }
}

struct TopImageRealView: View {
    @Binding var isPresented: Bool
    @Binding var image: Image?
    @State private var hostingController: UIHostingController<TopImageReal>? = nil

    func showImage() {
        let swiftUIView = TopImageReal(image: $image, isPres: $isPresented)
        hostingController = UIHostingController(rootView: swiftUIView)
        hostingController?.view.backgroundColor = .clear
        hostingController?.view.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(hostingController!.view)

            hostingController?.view.center.x = window.center.x
        }
    }

    func dismissImage() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                VStack {}
                    .onAppear {
                        showImage()
                    }
                    .onDisappear {
                        dismissImage()
                    }
                    .onChange(of: image) { _, newValue in
                        dismissImage()
                        showImage()
                    }
            }
        }
    }
}

struct TopImage: View {
    let image: String
    @Binding var isPres: Bool
    @Binding var imageReset: String
    @State var imageHeight: Double = 0.0
    @State var imageWidth: Double = 0.0
    @State var opac: Double = 1.0
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero

    var body: some View {
        ZStack {
            Rectangle().foregroundColor(.black).opacity(opac).ignoresSafeArea()
            GeometryReader { geometry in
                KFImage(URL(string: image))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(x: offset.x + (widthOrHeight(width: true) - imageWidth) / 2.0, y: offset.y + (widthOrHeight(width: false) - imageHeight) / 2.0)
                    .gesture(makeDragGesture(size: geometry.size))
                    .gesture(makeMagnificationGesture(size: geometry.size))
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onChange(of: proxy.size.height) { _, _ in
                                    imageHeight = proxy.size.height
                                    imageWidth = proxy.size.width
                                }

                        }
                    )
            }
            VStack {
                HStack {
                    Spacer()
                    SaveImageButton(url: image, video: false)
                }
                Spacer()
            }.padding(.trailing).padding(.top, top_Inset())
        }
        .onTapGesture {
            withAnimation(.linear(duration: 0.1)){
                isPres = false
                imageReset = ""
            }
        }
        .ignoresSafeArea()
        .onChange(of: offset) { _, _ in
            if scale < 1.3 {
                let height = abs(offset.y) > abs(offset.x) ? abs(offset.y) : abs(offset.x)
                if height < 10 {
                    opac = 1.0
                } else if height > 300 {
                    opac = 0.7
                } else {
                    let opacityRange = 0.3
                    let heightRange = 290.0
                    let opacity = 1.0 - (height / heightRange) * opacityRange
                    opac = opacity
                }
            }
        }
    }
    private func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value

                if abs(1 - delta) > 0.01 {
                    scale *= delta
                }
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation {
                        scale = 1
                    }
                }
                adjustMaxOffset(size: size)
            }
    }
    private func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                lastTranslation = value.translation
            }
            .onEnded { _ in
                adjustMaxOffset(size: size)
            }
    }
    private func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2

        var newOffsetX = offset.x
        var newOffsetY = offset.y

        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }

        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }
        self.lastTranslation = .zero
    }
}

struct TopImageView: View {
    @Binding var isPresented: Bool
    @Binding var imageReset: String
    @State private var hostingController: UIHostingController<TopImage>? = nil
    let image: String

    func showImage() {
        let swiftUIView = TopImage(image: image, isPres: $isPresented, imageReset: $imageReset)
        hostingController = UIHostingController(rootView: swiftUIView)
        hostingController?.view.backgroundColor = .clear
        hostingController?.view.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(hostingController!.view)

            hostingController?.view.center.x = window.center.x
        }
    }

    func dismissImage() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                VStack {}
                    .onAppear {
                        showImage()
                    }
                    .onDisappear {
                        dismissImage()
                    }
                    .onChange(of: image) { _, newValue in
                        dismissImage()
                        showImage()
                    }
            }
        }
    }
}
