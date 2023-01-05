import SwiftUI
import AVKit

struct MainVideoPlayer: View {
    let url: URL
    @Binding var muted: Bool
    @State var player = AVPlayer(url: URL(string: "https://www.google.com")!)
    @State var isplaying = false
    @State var value: Float = 0
    @State var viewID = false
    @Binding var currentTime: Double
    @Binding var totalLength: Double
    @State private var fillCircles = 0
    @State private var startDragTime = 0.0
    @State private var isChangingTime = false
    @State private var isHolding = false
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var globe: GlobeViewModel
    
    @State private var dragToClose = false
    let canClose: Bool
    @Binding var offSetY: CGFloat
    @Binding var playVid: Bool
    @Binding var pauseVid: Bool
    let shouldPlayAppear: Bool
    
    var body: some View {
        ZStack {
            VideoPlayer(player: $player).id(viewID)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .offset(y: offSetY)
                .simultaneousGesture(DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        if !isHolding {
                            isHolding = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            player.pause()
                            isplaying = false
                        }
                        if canClose {
                            if abs(value.translation.width) < 10 && value.translation.height > 5 {
                                offSetY = value.translation.height
                                dragToClose = true
                            }
                        }
                        let speed: CGFloat = 100
                        if totalLength != 1.0 {
                            let translation = value.translation.width
                            if translation > 20 {
                                isChangingTime = true
                                let timeLeft = totalLength - startDragTime
                                let changeRatio = ((translation / speed) > 1) ? 1 : (translation / speed)
                                let timeToAdd = changeRatio * timeLeft
                                currentTime = startDragTime + timeToAdd
                                player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 1))
                            } else if translation < -20 {
                                isChangingTime = true
                                let changeRatio = ((abs(translation) / speed) > 1) ? 1 : (abs(translation) / speed)
                                let timeToSubtract = changeRatio * startDragTime
                                currentTime = startDragTime - timeToSubtract
                                player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 1))
                            }
                        }
                    })
                    .onEnded { value in
                        if canClose && value.translation.height > 90 && dragToClose {
                            withAnimation {
                                offSetY = widthOrHeight(width: true)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    popRoot.showStories = false
                                    popRoot.showFriends = false
                                    globe.showMainStories = false
                                    popRoot.hideTabBar = false
                                }
                            }
                        } else {
                            withAnimation {
                                offSetY = 0.0
                            }
                            dragToClose = false
                            isHolding = false
                            isplaying = true
                            isChangingTime = false
                            self.player.play()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                )

            if isChangingTime && totalLength != 1.0 {
                ZStack(alignment: .center){
                    RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)
                    HStack {
                        Text("0:00").foregroundColor(.white).font(.subheadline)
                        Spacer()
                        ZStack(alignment: .leading){
                            HStack(alignment: .center, spacing: 1) {
                                ForEach(0..<50, id: \.self) { _ in
                                    Circle().frame(width: 4, height: 4)
                                        .foregroundColor(.black)
                                }
                            }
                            HStack(alignment: .center, spacing: 1) {
                                ForEach(0..<fillCircles, id: \.self) { _ in
                                    Circle().frame(width: 4, height: 4)
                                        .foregroundColor(.white)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2){
                                Text(formatTime(seconds: currentTime)).foregroundColor(.white).font(.caption).offset(x: -12)
                                Rectangle().foregroundColor(.blue).frame(width: 1, height: 25)
                                Spacer()
                            }.offset(x: CGFloat(fillCircles * 5)).padding(.top, 6)
                        }
                        Spacer()
                        Text(formatTime(seconds: totalLength)).foregroundColor(.white).font(.subheadline)
                    }.padding(.horizontal, 10)
                }
                .frame(width: widthOrHeight(width: true) * 0.95, height: 80)
                .onDisappear {
                    isplaying = true
                    isChangingTime = false
                }
            }
        }
        .onChange(of: playVid) { _, _ in
            player.play()
        }
        .onChange(of: pauseVid) { _, _ in
            player.pause()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onChange(of: muted) { _, _ in
            player.isMuted = muted
        }
        .onAppear {
            player = AVPlayer(url: url)
            player.isMuted = muted
            viewID.toggle()
            
            if shouldPlayAppear {
                self.player.play()
                self.isplaying = true
       
                self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: 1), queue: .main) { (_) in
                    self.value = self.getSliderValue()
                    
                    if self.value == 1.0 {
                        self.player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                        self.player.play()
                    }
                    if let total = self.player.currentItem?.duration.seconds, totalLength == 1.0 && total > 0.0 {
                        totalLength =  total
                    }
                }
            }
        }
        .onDisappear {
            self.player.pause()
            player = AVPlayer(url: URL(string: "https://www.google.com")!)
            viewID.toggle()
        }
        .onChange(of: currentTime) { _, _ in
            fillCircles = Int((currentTime / totalLength) * 50)
        }
    }
    func getSliderValue() -> Float {
        if let total = self.player.currentItem?.duration.seconds, self.player.currentTime().seconds > 0.0, total > 0.0 {
            currentTime = self.player.currentTime().seconds
            return Float(currentTime / total)
        } else {
            return 0.0
        }
    }
    func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60

        if minutes < 1 {
            return String(format: "0:%02d", remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
}

func getVideoResolution(url: String) async throws -> CGSize? {
    guard let track = try await AVURLAsset(url: URL(string: url)!).loadTracks(withMediaType: AVMediaType.video).first else { return nil }
    let size = try await track.load(.naturalSize).applying(track.load(.preferredTransform))
    return size
}

struct HustleVideoPlayer: View {
    let url: URL
    @Binding var muted: Bool
    @Binding var currentTime: Double
    @Binding var totalLength: Double
    @Binding var playVid: Bool
    @Binding var pauseVid: Bool
    @Binding var togglePlay: Bool
    let shouldPlayAppear: Bool
    
    @State var player = AVPlayer(url: URL(string: "https://www.google.com")!)
    @State var isplaying = false
    @State var value: Float = 0
    @State var viewID = false
    @State private var fillCircles = 0
    @State private var startDragTime = 0.0
    @State private var isChangingTime = false
    @State private var isHolding = false
    @State var aspect: CGSize = CGSize(width: 16, height: 9)
    
    var body: some View {
        ZStack {
            VideoPlayer(player: $player)
                .id(viewID)
                .aspectRatio(aspect, contentMode: .fit)
                .simultaneousGesture(DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        if !isHolding {
                            isHolding = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            player.pause()
                            isplaying = false
                        }
                        let speed: CGFloat = 100
                        if totalLength != 1.0 {
                            let translation = value.translation.width
                            if translation > 20 {
                                isChangingTime = true
                                let timeLeft = totalLength - startDragTime
                                let changeRatio = ((translation / speed) > 1) ? 1 : (translation / speed)
                                let timeToAdd = changeRatio * timeLeft
                                currentTime = startDragTime + timeToAdd
                                player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 1))
                            } else if translation < -20 {
                                isChangingTime = true
                                let changeRatio = ((abs(translation) / speed) > 1) ? 1 : (abs(translation) / speed)
                                let timeToSubtract = changeRatio * startDragTime
                                currentTime = startDragTime - timeToSubtract
                                player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 1))
                            }
                        }
                    })
                    .onEnded { value in
                        isHolding = false
                        isplaying = true
                        isChangingTime = false
                        self.player.play()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )

            if isChangingTime && totalLength != 1.0 {
                ZStack(alignment: .center){
                    RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)
                    HStack {
                        Text("0:00").foregroundColor(.white).font(.subheadline)
                        Spacer()
                        ZStack(alignment: .leading){
                            HStack(alignment: .center, spacing: 1) {
                                ForEach(0..<50, id: \.self) { _ in
                                    Circle().frame(width: 4, height: 4)
                                        .foregroundColor(.black)
                                }
                            }
                            HStack(alignment: .center, spacing: 1) {
                                ForEach(0..<fillCircles, id: \.self) { _ in
                                    Circle().frame(width: 4, height: 4)
                                        .foregroundColor(.white)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2){
                                Text(formatTime(seconds: currentTime)).foregroundColor(.white).font(.caption).offset(x: -12)
                                Rectangle().foregroundColor(.blue).frame(width: 1, height: 25)
                                Spacer()
                            }.offset(x: CGFloat(fillCircles * 5)).padding(.top, 6)
                        }
                        Spacer()
                        Text(formatTime(seconds: totalLength)).foregroundColor(.white).font(.subheadline)
                    }.padding(.horizontal, 10)
                }
                .frame(width: widthOrHeight(width: true) * 0.95, height: 80)
                .onDisappear {
                    isplaying = true
                    isChangingTime = false
                }
            }
        }
        .onChange(of: togglePlay) { _, _ in
            if togglePlay {
                player.play()
            } else {
                player.pause()
            }
        }
        .onChange(of: playVid) { _, _ in
            player.play()
        }
        .onChange(of: pauseVid) { _, _ in
            player.pause()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onChange(of: muted) { _, _ in
            player.isMuted = muted
        }
        .onAppear {
            player = AVPlayer(url: url)
            player.isMuted = muted
            viewID.toggle()
            
            Task {
                do {
                    if let final = try await getVideoResolution(url: url.absoluteString) {
                        self.aspect = final
                    }
                } catch { }
            }
            
            if shouldPlayAppear {
                self.player.play()
                togglePlay = true
                self.isplaying = true
       
                self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: 1), queue: .main) { (_) in
                    self.value = self.getSliderValue()
                    
                    if self.value == 1.0 {
                        self.player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                        self.player.play()
                    }
                    if let total = self.player.currentItem?.duration.seconds, totalLength == 1.0 && total > 0.0 {
                        totalLength = total
                    }
                }
            }
        }
        .onDisappear {
            self.player.pause()
            togglePlay = false
            player = AVPlayer(url: URL(string: "https://www.google.com")!)
            viewID.toggle()
        }
        .onChange(of: currentTime) { _, _ in
            fillCircles = Int((currentTime / totalLength) * 50)
        }
    }
    func getSliderValue() -> Float {
        if let total = self.player.currentItem?.duration.seconds, self.player.currentTime().seconds > 0.0, total > 0.0 {
            currentTime = self.player.currentTime().seconds
            return Float(currentTime / total)
        } else {
            return 0.0
        }
    }
    func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60

        if minutes < 1 {
            return String(format: "0:%02d", remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
}

struct HustleVideoPlayerX: View {
    let url: URL
    @Binding var muted: Bool
    @State var player = AVPlayer(url: URL(string: "https://www.google.com")!)
    @State var isplaying = false
    @State var value: Float = 0
    @State var viewID = false
    @Binding var currentTime: Double
    @Binding var totalLength: Double
    @State private var fillCircles = 0
    @State private var startDragTime = 0.0
    @State private var isChangingTime = false
    @State private var isHolding = false
    @Binding var playVid: Bool
    @Binding var pauseVid: Bool
    let shouldPlayAppear: Bool
    
    var body: some View {
        ZStack {
            VideoPlayer(player: $player).id(viewID)
                .simultaneousGesture(DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        if !isHolding {
                            isHolding = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            player.pause()
                            isplaying = false
                        }
                        let speed: CGFloat = 100
                        if totalLength != 1.0 {
                            let translation = value.translation.width
                            if translation > 20 {
                                isChangingTime = true
                                let timeLeft = totalLength - startDragTime
                                let changeRatio = ((translation / speed) > 1) ? 1 : (translation / speed)
                                let timeToAdd = changeRatio * timeLeft
                                currentTime = startDragTime + timeToAdd
                                player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 1))
                            } else if translation < -20 {
                                isChangingTime = true
                                let changeRatio = ((abs(translation) / speed) > 1) ? 1 : (abs(translation) / speed)
                                let timeToSubtract = changeRatio * startDragTime
                                currentTime = startDragTime - timeToSubtract
                                player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 1))
                            }
                        }
                    })
                    .onEnded { value in
                        isHolding = false
                        isplaying = true
                        isChangingTime = false
                        self.player.play()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )

            if isChangingTime && totalLength != 1.0 {
                ZStack(alignment: .center){
                    RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)
                    HStack {
                        Text("0:00").foregroundColor(.white).font(.subheadline)
                        Spacer()
                        ZStack(alignment: .leading){
                            HStack(alignment: .center, spacing: 1) {
                                ForEach(0..<50, id: \.self) { _ in
                                    Circle().frame(width: 4, height: 4)
                                        .foregroundColor(.black)
                                }
                            }
                            HStack(alignment: .center, spacing: 1) {
                                ForEach(0..<fillCircles, id: \.self) { _ in
                                    Circle().frame(width: 4, height: 4)
                                        .foregroundColor(.white)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2){
                                Text(formatTime(seconds: currentTime)).foregroundColor(.white).font(.caption).offset(x: -12)
                                Rectangle().foregroundColor(.blue).frame(width: 1, height: 25)
                                Spacer()
                            }.offset(x: CGFloat(fillCircles * 5)).padding(.top, 6)
                        }
                        Spacer()
                        Text(formatTime(seconds: totalLength)).foregroundColor(.white).font(.subheadline)
                    }.padding(.horizontal, 10)
                }
                .frame(width: widthOrHeight(width: true) * 0.95, height: 80)
                .onDisappear {
                    isplaying = true
                    isChangingTime = false
                }
            }
        }
        .onChange(of: playVid) { _, _ in
            player.play()
        }
        .onChange(of: pauseVid) { _, _ in
            player.pause()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onChange(of: muted) { _, _ in
            player.isMuted = muted
        }
        .onAppear {
            player = AVPlayer(url: url)
            player.isMuted = muted
            viewID.toggle()
            
            if shouldPlayAppear {
                self.player.play()
                self.isplaying = true
       
                self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: 1), queue: .main) { (_) in
                    self.value = self.getSliderValue()
                    
                    if self.value == 1.0 {
                        self.player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                        self.player.play()
                    }
                    if let total = self.player.currentItem?.duration.seconds, totalLength == 1.0 && total > 0.0 {
                        totalLength = total
                    }
                }
            }
        }
        .onDisappear {
            self.player.pause()
            player = AVPlayer(url: URL(string: "https://www.google.com")!)
            viewID.toggle()
        }
        .onChange(of: currentTime) { _, _ in
            fillCircles = Int((currentTime / totalLength) * 50)
        }
    }
    func getSliderValue() -> Float {
        if let total = self.player.currentItem?.duration.seconds, self.player.currentTime().seconds > 0.0, total > 0.0 {
            currentTime = self.player.currentTime().seconds
            return Float(currentTime / total)
        } else {
            return 0.0
        }
    }
    func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60

        if minutes < 1 {
            return String(format: "0:%02d", remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
}



struct VideoPlayer : UIViewControllerRepresentable {
    @Binding var player : AVPlayer
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayer>) -> AVPlayerViewController {

        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.allowsVideoFrameAnalysis = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayer>) { }
}
