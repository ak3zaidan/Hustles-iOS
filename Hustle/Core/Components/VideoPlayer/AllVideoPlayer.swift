import SwiftUI
import AVKit

class VideoCacheManager {
    static let shared = VideoCacheManager()
    private init() {}
    
    var size: [String: CGSize] = [:]
    
    func playerSize(for url: URL) -> CGSize? {
        if let item = size[url.absoluteString] {
            return item
        }
        return nil
    }
    func setSize(aspect: CGSize, url: URL){
        size[url.absoluteString] = aspect
    }
}

struct HustleVideoPlayerR: View {
    @EnvironmentObject var popRoot: PopToRoot
    let url: URL
    @State var player: AVPlayer? = nil
    @State var isplaying = false
    @State var muted = true
    @State var value: Float = 0.0
    @State var currentTime: Double = 0.0
    @State var totalLength: Double = 1.0
    @State var aspect: CGSize = CGSize(width: 16, height: 9)
    @Environment(\.scenePhase) var scenePhase
    @State var appeared = false
    
    var body: some View {
        ZStack {
            if let vid = player {
                VidPlayer(player: vid)
                    .aspectRatio(VideoCacheManager.shared.playerSize(for: url) ?? aspect, contentMode: .fit)
                    .onTapGesture {
                        popRoot.currentAudio = url.absoluteString
                        popRoot.playID = url.absoluteString
                        withAnimation {
                            popRoot.player = player
                        }
                        player?.play()
                    }
                controls()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                player?.isMuted = true
                muted = true
            } else if newPhase == .active {
                if popRoot.currentAudio == url.absoluteString && appeared {
                    player?.isMuted = false
                    muted = false
                    self.isplaying = true
                    self.player?.play()
                }
            } else if newPhase == .background {
                player?.isMuted = true
                muted = true
                self.isplaying = false
                self.player?.pause()
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onChange(of: popRoot.playID) { _, _ in
            if popRoot.playID != url.absoluteString {
                player?.isMuted = true
                muted = true
            }
        }
        .onChange(of: popRoot.currentAudio) { _, _ in
            if popRoot.currentAudio != url.absoluteString {
                player?.isMuted = true
                muted = true
            } else if appeared {
                player?.isMuted = false
                muted = false
            }
        }
        .onAppear {
            appeared = true
            if player == nil {
                player = AVPlayer(url: url)
            }
            
            if popRoot.currentAudio.isEmpty || popRoot.currentAudio == url.absoluteString {
                popRoot.currentAudio = url.absoluteString
                self.player?.isMuted = false
                muted = false
            } else {
                muted = true
                self.player?.isMuted = true
            }
            
            if let temp_aspect = VideoCacheManager.shared.playerSize(for: url) {
                self.aspect = temp_aspect
            } else {
                Task {
                    do {
                        if let final = try await getVideoResolution(url: url.absoluteString) {
                            self.aspect = final
                            VideoCacheManager.shared.setSize(aspect: final, url: url)
                        }
                    } catch { }
                }
            }
            
            self.player?.play()
            self.isplaying = true
   
            self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: 1), queue: .main) { (_) in
                self.value = self.getSliderValue()
                
                if self.value == 1.0 {
                    self.player?.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                    self.player?.play()
                }
                if let total = self.player?.currentItem?.duration.seconds, totalLength == 1.0 && total > 0.0 {
                    totalLength = total
                }
            }
        }
        .onDisappear {
            appeared = false
            popRoot.currentAudio = ""
            self.player?.pause()
            self.isplaying = false
        }
    }
    func getSliderValue() -> Float {
        if let player = player {
            if let total = player.currentItem?.duration.seconds, player.currentTime().seconds > 0.0, total > 0.0 {
                currentTime = player.currentTime().seconds
                return Float(currentTime / total)
            } else {
                return 0.0
            }
        } else {
            return 0.0
        }
    }
    func controls() -> some View {
        VStack {
            HStack {
                Button(action: {
                    if muted {
                        popRoot.currentAudio = url.absoluteString
                        player?.isMuted = false
                    } else {
                        player?.isMuted = true
                    }
                    muted.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Circle().foregroundStyle(.ultraThickMaterial)
                        if muted {
                            Image(systemName: "speaker.slash.fill").foregroundStyle(.white).font(.headline)
                        } else {
                            Image(systemName: "speaker.wave.2").foregroundStyle(.white).font(.headline)
                        }
                    }.frame(width: 40, height: 40).opacity(0.6)
                })
                Spacer()
                Button(action: {
                    isplaying.toggle()
                    if isplaying {
                        player?.play()
                    } else {
                        player?.pause()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Circle().foregroundStyle(.ultraThickMaterial)
                        if isplaying {
                            Image(systemName: "pause").foregroundStyle(.white).font(.headline)
                        } else {
                            Image(systemName: "play.fill").foregroundStyle(.white).font(.headline)
                        }
                    }.frame(width: 40, height: 40).opacity(0.6)
                })
            }
            Spacer()
        }.padding()
    }
}

struct VidPlayer : UIViewControllerRepresentable {
    var player : AVPlayer
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<VidPlayer>) -> AVPlayerViewController {

        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.allowsVideoFrameAnalysis = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VidPlayer>) { }
}
