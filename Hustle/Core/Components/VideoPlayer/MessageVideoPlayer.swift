import SwiftUI
import AVFoundation

struct MessageVideoPlayer: View {
    @EnvironmentObject var popRoot: PopToRoot
    @State var player: AVPlayer
    @State var isplaying = false
    @State var value: Float = 0.0
    @State var currentTime: Double = 0.0
    @State var totalLength: Double = 1.0
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @State var appeared = false
    let url: URL
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    @State var viewID: String
    @Binding var currentAudio: String
    
    init(url: URL, width: CGFloat, height: CGFloat, cornerRadius: CGFloat, viewID: String? = nil, currentAudio: Binding<String>) {
        self.url = url
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        _viewID = State(initialValue: viewID ?? UUID().uuidString)
        _player = State(initialValue: AVPlayer(url: url))
        self._currentAudio = currentAudio
    }
    
    var body: some View {
        ZStack {
            VidPlayer(player: player)
            controls()
        }
        .overlay(content: {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1.0)
        })
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                player.isMuted = true
            } else if newPhase == .active {
                if (currentAudio == (url.absoluteString + viewID) || currentAudio.isEmpty) && appeared {
                    player.isMuted = popRoot.muted
                    self.isplaying = true
                    self.player.play()
                    currentAudio = url.absoluteString + viewID
                }
            } else if newPhase == .background {
                player.isMuted = true
                self.isplaying = false
                self.player.pause()
            }
        }
        .onChange(of: popRoot.playID) { _, _ in
            if popRoot.playID != url.absoluteString {
                player.isMuted = true
            }
        }
        .onChange(of: currentAudio) { _, _ in
            if currentAudio != (url.absoluteString + viewID) {
                player.isMuted = true
            } else if appeared {
                player.isMuted = popRoot.muted
            }
        }
        .onAppear {
            appeared = true
            
            if currentAudio.isEmpty || currentAudio == (url.absoluteString + viewID) {
                self.player.isMuted = popRoot.muted
                currentAudio = url.absoluteString + viewID
            } else {
                self.player.isMuted = true
            }
            
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
        .onDisappear {
            appeared = false
            if currentAudio == (url.absoluteString + viewID) {
                currentAudio = ""
            }
            self.player.pause()
            self.isplaying = false
        }
    }
    func getSliderValue() -> Float {
        if let total = player.currentItem?.duration.seconds, player.currentTime().seconds > 0.0, total > 0.0 {
            currentTime = player.currentTime().seconds
            return Float(currentTime / total)
        } else {
            return 0.0
        }
    }
    func controls() -> some View {
        VStack {
            Spacer()
            HStack {
                Button(action: {
                    if popRoot.muted {
                        currentAudio = url.absoluteString + viewID
                        player.isMuted = false
                    } else {
                        player.isMuted = true
                    }
                    popRoot.muted.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Circle().foregroundStyle(.ultraThickMaterial)
                        if popRoot.muted || currentAudio != (url.absoluteString + viewID) {
                            Image(systemName: "speaker.slash.fill").font(.subheadline)
                        } else {
                            Image(systemName: "speaker.wave.2").font(.subheadline)
                        }
                    }.frame(width: 30, height: 30).opacity(0.7)
                })
                Spacer()
                Button(action: {
                    isplaying.toggle()
                    if isplaying {
                        currentAudio = url.absoluteString + viewID
                        player.play()
                    } else {
                        currentAudio = ""
                        player.pause()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Circle().foregroundStyle(.ultraThickMaterial)
                        if isplaying {
                            Image(systemName: "pause").font(.subheadline)
                        } else {
                            Image(systemName: "play.fill").font(.subheadline)
                        }
                    }.frame(width: 30, height: 30).opacity(0.7)
                })
            }
        }.padding()
    }
}

struct MessageVideoPlayerNoFrameWidth: View {
    @EnvironmentObject var popRoot: PopToRoot
    @State var player: AVPlayer
    @State var isplaying = false
    @State var value: Float = 0.0
    @State var currentTime: Double = 0.0
    @State var totalLength: Double = 1.0
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @State var appeared = false
    let url: URL
    let height: CGFloat
    let cornerRadius: CGFloat
    @State var viewID: String
    @Binding var currentAudio: String
    
    init(url: URL, height: CGFloat, cornerRadius: CGFloat, viewID: String? = nil, currentAudio: Binding<String>) {
        self.url = url
        self.height = height
        self.cornerRadius = cornerRadius
        _viewID = State(initialValue: viewID ?? UUID().uuidString)
        _player = State(initialValue: AVPlayer(url: url))
        self._currentAudio = currentAudio
    }
    
    var body: some View {
        ZStack {
            VidPlayer(player: player)
                .onTapGesture {
                    popRoot.currentAudio = url.absoluteString + viewID
                    popRoot.playID = url.absoluteString
                    withAnimation {
                        popRoot.player = player
                    }
                    player.play()
                }
            controls()
        }
        .overlay(content: {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1.0)
        })
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                player.isMuted = true
            } else if newPhase == .active {
                if (currentAudio == (url.absoluteString + viewID) || currentAudio.isEmpty) && appeared {
                    player.isMuted = popRoot.muted
                    self.isplaying = true
                    self.player.play()
                    currentAudio = url.absoluteString + viewID
                }
            } else if newPhase == .background {
                player.isMuted = true
                self.isplaying = false
                self.player.pause()
            }
        }
        .onChange(of: popRoot.playID) { _, _ in
            if popRoot.playID != url.absoluteString {
                player.isMuted = true
            }
        }
        .onChange(of: currentAudio) { _, _ in
            if currentAudio != (url.absoluteString + viewID) {
                player.isMuted = true
            } else if appeared {
                player.isMuted = popRoot.muted
            }
        }
        .onAppear {
            appeared = true
            
            if currentAudio.isEmpty || currentAudio == (url.absoluteString + viewID) {
                self.player.isMuted = popRoot.muted
                currentAudio = url.absoluteString + viewID
            } else {
                self.player.isMuted = true
            }
            
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
        .onDisappear {
            appeared = false
            if currentAudio == (url.absoluteString + viewID) {
                currentAudio = ""
            }
            self.player.pause()
            self.isplaying = false
        }
    }
    func getSliderValue() -> Float {
        if let total = player.currentItem?.duration.seconds, player.currentTime().seconds > 0.0, total > 0.0 {
            currentTime = player.currentTime().seconds
            return Float(currentTime / total)
        } else {
            return 0.0
        }
    }
    func controls() -> some View {
        VStack {
            Spacer()
            HStack {
                Button(action: {
                    if popRoot.muted {
                        currentAudio = url.absoluteString + viewID
                        player.isMuted = false
                    } else {
                        player.isMuted = true
                    }
                    popRoot.muted.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Circle().foregroundStyle(.ultraThickMaterial)
                        if popRoot.muted || currentAudio != (url.absoluteString + viewID) {
                            Image(systemName: "speaker.slash.fill").font(.subheadline)
                        } else {
                            Image(systemName: "speaker.wave.2").font(.subheadline)
                        }
                    }.frame(width: 30, height: 30).opacity(0.7)
                })
                Spacer()
                Button(action: {
                    isplaying.toggle()
                    if isplaying {
                        currentAudio = url.absoluteString + viewID
                        player.play()
                    } else {
                        currentAudio = ""
                        player.pause()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Circle().foregroundStyle(.ultraThickMaterial)
                        if isplaying {
                            Image(systemName: "pause").font(.subheadline)
                        } else {
                            Image(systemName: "play.fill").font(.subheadline)
                        }
                    }.frame(width: 30, height: 30).opacity(0.7)
                })
            }
        }.padding()
    }
}
