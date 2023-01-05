import SwiftUI
import Kingfisher

struct VoicePlayerView: View {
    @StateObject var audioPlayer = AudioPlayer(numberOfSamples: 15)
    @Environment(\.colorScheme) var colorScheme
    @Binding var makenil: Bool
    var audioUrl: URL
    let userPhoto: String?
    let removeView: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.orange).opacity(0.7)
            VStack {
                Spacer()
                HStack(spacing: 4){
                    Text(audioPlayer.currentTime.description)
                    Image(systemName: "speaker.wave.3")
                    Spacer()
                    Image("logowhite 1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .offset(x: 6)
                    Text("Voice").fontWeight(.heavy)
                }
                .padding(.vertical, 5)
                .font(.system(size: 13)).foregroundStyle(.white)
            }.padding(.horizontal)
            ZStack {
                Circle().foregroundColor(Color(UIColor.lightGray))
                    .opacity(colorScheme == .dark ? 0.8 : 0.6)
                Circle().foregroundColor(.blue).opacity(0.05)
                Image(systemName: "person.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color(UIColor.darkGray))
                    .opacity(0.8)
                if let userPhoto {
                    KFImage(URL(string: userPhoto))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaledToFill()
                        .clipShape(Circle())
                        .contentShape(Circle())
                        .frame(width: 100, height: 100)
                }
            }.frame(width: 100, height: 100).opacity(audioPlayer.isPlaying ? 0.3 : 1.0)
            if audioPlayer.isPlaying {
                HStack {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack {
                                ForEach(audioPlayer.soundSamples, id: \.id) { level in
                                    BarView(isRecording: false, sample: level).id(level)
                                }
                            }
                        }
                        .onChange(of: audioPlayer.soundSamples) { _, _ in
                            proxy.scrollTo(audioPlayer.soundSamples.last)
                        }
                    }
                }.padding(.horizontal, 8)
            } else {
                Button(action: {
                    playAudio()
                }, label: {
                    Image(systemName: "play.fill").font(.system(size: 17))
                        .padding().background(.ultraThickMaterial)
                        .clipShape(Circle())
                })
            }
            VStack {
                HStack(alignment: .top){
                    if audioPlayer.isPlaying {
                        Button(action: {
                            stopPlaying()
                        }, label: {
                            Image(systemName: "stop.fill").font(.system(size: 16))
                                .padding(9).background(.ultraThickMaterial)
                                .clipShape(Circle())
                        })
                    }
                    Spacer()
                    Button(action: {
                        removeView()
                    }, label: {
                        Image(systemName: "trash").font(.system(size: 16))
                            .padding(9).background(.ultraThickMaterial)
                            .clipShape(Circle()).foregroundStyle(.red)
                    })
                }
                .padding(.vertical, 12)
                .font(.system(size: 13)).foregroundStyle(.white)
                Spacer()
            }.padding(.horizontal)
        }
        .frame(height: 160)
        .onChange(of: makenil) { _, _ in
            stopPlaying()
        }
    }
    func playAudio() {
        audioPlayer.playSystemSound(soundID: 1306)
        audioPlayer.startPlayback(audio: audioUrl)
    }
    func stopPlaying() {
        audioPlayer.stopPlayback()
    }
}

struct VoiceStreamView: View {
    @EnvironmentObject var popRoot: PopToRoot
    @StateObject var audioPlayer = AudioPlayer(numberOfSamples: 15)
    let audioUrl: URL
    @State var loading = false
    @Environment(\.colorScheme) var colorScheme
    @Binding var currentAudio: String
    let hustleID: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.orange).opacity(0.7)
            VStack {
                Spacer()
                HStack(spacing: 4){
                    Text(audioPlayer.currentTime.description)
                    Image(systemName: "speaker.wave.3")
                    Spacer()
                    Image("logowhite 1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .offset(x: 6)
                    Text("Voice")
                }
                .padding(.vertical, 5)
                .font(.system(size: 13)).foregroundStyle(.white)
            }.padding(.horizontal)
            ZStack {
                Circle().foregroundColor(Color(UIColor.lightGray))
                    .opacity(colorScheme == .dark ? 0.8 : 0.6)
                Circle().foregroundColor(.blue).opacity(0.05)
                Image(systemName: "person.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color(UIColor.darkGray))
                    .opacity(0.8)
            }.frame(width: 100, height: 100).opacity(audioPlayer.isPlaying ? 0.3 : 1.0)
            if audioPlayer.isPlaying {
                HStack {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack {
                                ForEach(audioPlayer.soundSamples, id: \.id) { level in
                                    BarView(isRecording: false, sample: level).id(level)
                                }
                            }
                        }
                        .onChange(of: audioPlayer.soundSamples) { _, _ in
                            proxy.scrollTo(audioPlayer.soundSamples.last)
                        }
                    }
                }.padding(.horizontal, 8)
            } else if loading {
                ProgressView()
                    .padding().background(.ultraThickMaterial)
                    .clipShape(Circle())
            } else {
                Button(action: {
                    playAudio()
                }, label: {
                    Image(systemName: "play.fill").font(.system(size: 17))
                        .padding().background(.ultraThickMaterial)
                        .clipShape(Circle())
                })
            }
            VStack {
                HStack(alignment: .top){
                    Text("1/1")
                    Spacer()
                    if audioPlayer.isPlaying {
                        Button(action: {
                            stopPlaying()
                            popRoot.currentSound = ""
                        }, label: {
                            Image(systemName: "stop.fill").font(.system(size: 16))
                                .padding(9).background(.ultraThickMaterial)
                                .clipShape(Circle())
                        })
                    }
                }
                .padding(.vertical, 12)
                .font(.system(size: 13)).foregroundStyle(.white)
                Spacer()
            }.padding(.horizontal)
        }
        .frame(height: 160)
        .onChange(of: popRoot.currentSound, { _, new in
            if new != (hustleID + audioUrl.absoluteString) {
                stopPlaying()
            }
        })
        .onChange(of: currentAudio, { _, new in
            if !currentAudio.isEmpty {
                stopPlaying()
            }
        })
        .onDisappear(perform: {
            if popRoot.currentSound == (hustleID + audioUrl.absoluteString) {
                popRoot.currentSound = ""
            }
        })
    }
    func playAudio() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        audioPlayer.playSystemSound(soundID: 1306)
        if let local = popRoot.audioFiles.first(where: { $0.0 == audioUrl.absoluteString })?.1 {
            audioPlayer.startPlayback(audio: local)
        } else {
            downloadAndPlayAudio(from: audioUrl)
        }
        currentAudio = ""
        popRoot.currentSound = hustleID + audioUrl.absoluteString
    }
    func stopPlaying() {
        audioPlayer.stopPlayback()
    }
    func downloadAndPlayAudio(from url: URL) {
        withAnimation {
            loading = true
        }
        let timestamp = Date().timeIntervalSince1970
        let fileName = "downloadedAudio_\(timestamp).m4a"
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectoryURL.appendingPathComponent(fileName)
        let session = URLSession(configuration: .default)

        let downloadTask = session.downloadTask(with: url) { (tempURL, response, error) in
            guard let tempURL = tempURL, error == nil else {
                withAnimation {
                    loading = false
                }
                return
            }
            do {
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                DispatchQueue.main.async {
                    withAnimation {
                        loading = false
                    }
                    self.audioPlayer.startPlayback(audio: destinationURL)
                    self.popRoot.audioFiles.append((audioUrl.absoluteString, destinationURL))
                }
            } catch {
                withAnimation {
                    loading = false
                }
            }
        }
        downloadTask.resume()
    }
}

func downloadAudio(from url: URL) {
    let timestamp = Date().timeIntervalSince1970
    let fileName = "downloadedAudio_\(timestamp).m4a"
    let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let destinationURL = documentsDirectoryURL.appendingPathComponent(fileName)
    let session = URLSession(configuration: .default)

    let downloadTask = session.downloadTask(with: url) { (tempURL, response, error) in
        guard let tempURL = tempURL, error == nil else {
            return
        }
        do {
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        } catch {
            print("err")
        }
    }
    downloadTask.resume()
}
