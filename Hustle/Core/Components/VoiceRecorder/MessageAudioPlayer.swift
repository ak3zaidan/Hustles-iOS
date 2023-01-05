import SwiftUI
import Speech

func transcribeAudio(url: URL, completion: @escaping (String?) -> Void) {
    let recognizer = SFSpeechRecognizer()
    let request = SFSpeechURLRecognitionRequest(url: url)
    
    recognizer?.recognitionTask(with: request) { result, error in
        if error != nil {
            completion(nil)
        } else if let result = result, result.isFinal {
            completion(result.bestTranscription.formattedString)
        }
    }
}

public struct MessageAudioPView: View {
    @StateObject var audioPlayer = AudioPlayer(numberOfSamples: 15)
    let audioUrl: URL
    @Binding var empty: [Recording]
    @Binding var currentAudio: String
    let onClose: () -> Void
    @EnvironmentObject var popRoot: PopToRoot
    
    public var body: some View {
        HStack(spacing: 12){
            Button(action: {
                if audioPlayer.isPlaying {
                    stopPlaying()
                    popRoot.currentSound = ""
                } else {
                    playAudio()
                }
            }, label: {
                if audioPlayer.isPlaying {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 17)).padding(12)
                        .background(.white).clipShape(Circle())
                } else {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 17)).padding(12)
                        .background(Color(red: 1.0, green: 0.7, blue: 0.5)).clipShape(Circle())
                }
            })
            if audioPlayer.soundSamples.isEmpty {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 2){
                            ForEach(0..<80, id: \.self){ i in
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: 2, height: 2)
                                    .foregroundStyle(.white)
                            }
                        }
                    }.disabled(true)
                }.frame(width: widthOrHeight(width: true) * 0.35)
            } else {
                HStack {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 2){
                                ForEach(audioPlayer.soundSamples, id: \.id) { level in
                                    BarView(isRecording: false, sample: level).id(level)
                                }
                            }
                            .onChange(of: audioPlayer.soundSamples) { _, _ in
                                proxy.scrollTo(audioPlayer.soundSamples.last)
                            }
                        }
                        .disabled(true)
                    }
                }.frame(width: widthOrHeight(width: true) * 0.35)
            }
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                empty = []
                onClose()
            }, label: {
                Image(systemName: "xmark")
                    .foregroundStyle(!audioPlayer.isPlaying ? .white : .orange)
                    .font(.system(size: 17)).padding(12)
                    .background(audioPlayer.isPlaying ? .white : Color(red: 1.0, green: 0.7, blue: 0.5)).clipShape(Circle())
            })
        }
        .onChange(of: popRoot.currentSound, { _, new in
            if new != ("new" + audioUrl.absoluteString) {
                stopPlaying()
            }
        })
        .onChange(of: currentAudio, { _, new in
            if !currentAudio.isEmpty {
                stopPlaying()
            }
        })
        .onDisappear(perform: {
            if popRoot.currentSound == ("new" + audioUrl.absoluteString) {
                popRoot.currentSound = ""
            }
        })
        .frame(height: 45)
        .padding(10)
        .background(audioPlayer.isPlaying ? Color(red: 1.0, green: 0.7, blue: 0.5) : Color(UIColor.lightGray))
        .clipShape(Capsule())
    }
    private func playAudio() {
        audioPlayer.playSystemSound(soundID: 1306)
        audioPlayer.startPlayback(audio: audioUrl)
        currentAudio = ""
        popRoot.currentSound = "new" + audioUrl.absoluteString
    }
    private func stopPlaying() {
        audioPlayer.stopPlayback()
    }
}

public struct MessageVoiceStreamView: View {
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var gModel: GroupViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @StateObject var audioPlayer = AudioPlayer(numberOfSamples: 15)
    let audioUrl: URL
    @State private var loading = false
    let messageID: String
    let isGroup: Bool
    @Binding var currentAudio: String

    public var body: some View {
        HStack(spacing: 12){
            if loading {
                ProgressView().padding(10).background(.ultraThickMaterial).clipShape(Circle())
            } else {
                Button(action: {
                    if audioPlayer.isPlaying {
                        stopPlaying()
                        popRoot.currentSound = ""
                    } else {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        audioPlayer.playSystemSound(soundID: 1306)
                        playAudio()
                    }
                }, label: {
                    if audioPlayer.isPlaying {
                        Image(systemName: "stop.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 17)).padding(12)
                            .background(.white).clipShape(Circle())
                    } else {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 17)).padding(12)
                            .background(Color(red: 1.0, green: 0.7, blue: 0.5)).clipShape(Circle())
                    }
                })
            }
            if audioPlayer.soundSamples.isEmpty {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 2){
                            ForEach(0..<80, id: \.self){ i in
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: 2, height: 2)
                                    .foregroundStyle(.white)
                            }
                        }
                    }.disabled(true)
                }.frame(width: widthOrHeight(width: true) * 0.35)
            } else {
                HStack {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 2){
                                ForEach(audioPlayer.soundSamples, id: \.id) { level in
                                    BarView(isRecording: false, sample: level).id(level)
                                }
                            }
                            .onChange(of: audioPlayer.soundSamples) { _, _ in
                                proxy.scrollTo(audioPlayer.soundSamples.last)
                            }
                        }
                        .disabled(true)
                    }
                }.frame(width: widthOrHeight(width: true) * 0.35)
            }
            HStack(spacing: 4){
                Text(audioPlayer.currentTime.description)
                Image(systemName: "speaker.wave.3")
            }.font(.system(size: 13))
        }
        .onChange(of: popRoot.currentSound, { _, new in
            if new != (messageID + audioUrl.absoluteString) {
                stopPlaying()
            }
        })
        .onChange(of: currentAudio, { _, new in
            if !currentAudio.isEmpty {
                stopPlaying()
            }
        })
        .onDisappear(perform: {
            if popRoot.currentSound == (messageID + audioUrl.absoluteString) {
                popRoot.currentSound = ""
            }
        })
        .frame(height: 45)
        .padding(10)
        .background(audioPlayer.isPlaying ? Color(red: 1.0, green: 0.7, blue: 0.5) : Color(UIColor.lightGray))
        .clipShape(Capsule())
        .onChange(of: viewModel.startNextAudio) { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue == full {
                viewModel.startNextAudio = ""
                playAudio()
            }
        }
        .onChange(of: gModel.startNextAudio) { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue == full {
                gModel.startNextAudio = ""
                playAudio()
            }
        }
        .onChange(of: viewModel.currentAudio, { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue != full && audioPlayer.isPlaying {
                stopPlaying()
            }
        })
        .onChange(of: gModel.currentAudio, { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue != full && audioPlayer.isPlaying {
                stopPlaying()
            }
        })
        .onChange(of: audioPlayer.didEnd) { _, newValue in
            if newValue && !messageID.isEmpty {
                if isGroup {
                    if let index = gModel.currentGroup, index < gModel.groups.count {
                        if let square = gModel.groups[index].1.messages?.first(where: { $0.id == gModel.groups[index].0 }) {
                            if let position = square.messages.firstIndex(where: { $0.id == messageID }) {
                                if position < (square.messages.count - 1) {
                                    if let urlID = square.messages[position + 1].audioURL, let messID = square.messages[position + 1].id {
                                        gModel.startNextAudio = messID + urlID
                                    } else if let urlID = square.messages[position + 1].replyAudio, let messID = square.messages[position + 1].id {
                                        gModel.startNextAudio = messID + urlID
                                    } else if position < (square.messages.count - 2) {
                                        if let urlID = square.messages[position + 2].audioURL, let messID = square.messages[position + 2].id {
                                            gModel.startNextAudio = messID + urlID
                                        } else if let urlID = square.messages[position + 2].replyAudio, let messID = square.messages[position + 2].id {
                                            gModel.startNextAudio = messID + urlID
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if let index = viewModel.currentChat, index < viewModel.chats.count {
                        if let position = viewModel.chats[index].messages?.firstIndex(where: { $0.id == messageID }) {
                            if position > 0 {
                                if let urlID = viewModel.chats[index].messages?[position - 1].audioURL, let messID = viewModel.chats[index].messages?[position - 1].id {
                                    viewModel.startNextAudio = messID + urlID
                                } else if let urlID = viewModel.chats[index].messages?[position - 1].replyAudio, let messID = viewModel.chats[index].messages?[position - 1].id {
                                    viewModel.startNextAudio = messID + urlID
                                } else if position > 1 {
                                    if let urlID = viewModel.chats[index].messages?[position - 2].audioURL, let messID = viewModel.chats[index].messages?[position - 2].id {
                                        viewModel.startNextAudio = messID + urlID
                                    } else if let urlID = viewModel.chats[index].messages?[position - 2].replyAudio, let messID = viewModel.chats[index].messages?[position - 2].id {
                                        viewModel.startNextAudio = messID + urlID
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    private func playAudio() {
        if let local = popRoot.audioFiles.first(where: { $0.0 == audioUrl.absoluteString })?.1 {
            audioPlayer.startPlayback(audio: local)
        } else {
            downloadAndPlayAudio(from: audioUrl)
        }
        currentAudio = ""
        popRoot.currentSound = messageID + audioUrl.absoluteString
    }
    private func stopPlaying() {
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

public struct MessageVoiceStreamViewSec: View {
    @EnvironmentObject var gcModel: GroupChatViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @StateObject var audioPlayer = AudioPlayer(numberOfSamples: 15)
    let audioUrl: URL
    @State private var loading = false
    let messageID: String
    @Binding var currentAudio: String
    
    public var body: some View {
        HStack(spacing: 12){
            if loading {
                ProgressView().padding(10).background(.ultraThickMaterial).clipShape(Circle())
            } else {
                Button(action: {
                    if audioPlayer.isPlaying {
                        stopPlaying()
                        popRoot.currentSound = ""
                    } else {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        audioPlayer.playSystemSound(soundID: 1306)
                        playAudio()
                    }
                }, label: {
                    if audioPlayer.isPlaying {
                        Image(systemName: "stop.fill")
                            .foregroundStyle(.blue)
                            .font(.system(size: 17)).padding(12)
                            .background(.white).clipShape(Circle())
                    } else {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 17)).padding(12)
                            .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).clipShape(Circle())
                    }
                })
            }
            if audioPlayer.soundSamples.isEmpty {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 2){
                            ForEach(0..<80, id: \.self){ i in
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: 2, height: 2)
                                    .foregroundStyle(.white)
                            }
                        }
                    }.disabled(true)
                }.frame(width: widthOrHeight(width: true) * 0.35)
            } else {
                HStack {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 2){
                                ForEach(audioPlayer.soundSamples, id: \.id) { level in
                                    BarView(isRecording: false, sample: level).id(level)
                                }
                            }
                            .onChange(of: audioPlayer.soundSamples) { _, _ in
                                proxy.scrollTo(audioPlayer.soundSamples.last)
                            }
                        }.disabled(true)
                    }
                }.frame(width: widthOrHeight(width: true) * 0.35)
            }
            HStack(spacing: 4){
                Text(audioPlayer.currentTime.description)
                Image(systemName: "speaker.wave.3").bold()
            }.font(.system(size: 13))
        }
        .onChange(of: popRoot.currentSound, { _, new in
            if new != (messageID + audioUrl.absoluteString) {
                stopPlaying()
            }
        })
        .onChange(of: currentAudio, { _, new in
            if !currentAudio.isEmpty {
                stopPlaying()
            }
        })
        .onDisappear(perform: {
            if popRoot.currentSound == (messageID + audioUrl.absoluteString) {
                popRoot.currentSound = ""
            }
        })
        .frame(height: 45)
        .onChange(of: gcModel.startNextAudio) { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue == full {
                gcModel.startNextAudio = ""
                playAudio()
            }
        }
        .onChange(of: gcModel.currentAudio, { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue != full && audioPlayer.isPlaying {
                stopPlaying()
            }
        })
        .onChange(of: audioPlayer.didEnd) { _, newValue in
            if newValue && !messageID.isEmpty {
                if let index = gcModel.currentChat, index < gcModel.chats.count {
                    if let position = gcModel.chats[index].messages?.firstIndex(where: { $0.id == messageID }) {
                        if position > 0 {
                            if let urlID = gcModel.chats[index].messages?[position - 1].audioURL, let messID = gcModel.chats[index].messages?[position - 1].id {
                                gcModel.startNextAudio = messID + urlID
                            } else if let urlID = gcModel.chats[index].messages?[position - 1].replyAudio, let messID = gcModel.chats[index].messages?[position - 1].id {
                                gcModel.startNextAudio = messID + urlID
                            } else if position > 1 {
                                if let urlID = gcModel.chats[index].messages?[position - 2].audioURL, let messID = gcModel.chats[index].messages?[position - 2].id {
                                    gcModel.startNextAudio = messID + urlID
                                } else if let urlID = gcModel.chats[index].messages?[position - 2].replyAudio, let messID = gcModel.chats[index].messages?[position - 2].id {
                                    gcModel.startNextAudio = messID + urlID
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    private func playAudio() {
        gcModel.currentAudio = messageID + audioUrl.absoluteString
        if let local = popRoot.audioFiles.first(where: { $0.0 == audioUrl.absoluteString })?.1 {
            audioPlayer.startPlayback(audio: local)
        } else {
            downloadAndPlayAudio(from: audioUrl)
        }
        currentAudio = ""
        popRoot.currentSound = messageID + audioUrl.absoluteString
    }
    private func stopPlaying() {
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

public struct MessageAudioPViewSec: View {
    @EnvironmentObject var gcModel: GroupChatViewModel
    @StateObject var audioPlayer = AudioPlayer(numberOfSamples: 15)
    let audioUrl: URL
    let messageID: String
    @Binding var currentAudio: String
    @EnvironmentObject var popRoot: PopToRoot
    
    public var body: some View {
        HStack(spacing: 12){
            Button(action: {
                if audioPlayer.isPlaying {
                    stopPlaying()
                    popRoot.currentSound = ""
                } else {
                    audioPlayer.playSystemSound(soundID: 1306)
                    playAudio()
                }
            }, label: {
                if audioPlayer.isPlaying {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 17)).padding(12)
                        .background(.white).clipShape(Circle())
                } else {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 17)).padding(12)
                        .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).clipShape(Circle())
                }
            })
            if audioPlayer.soundSamples.isEmpty {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 2){
                            ForEach(0..<80, id: \.self){ i in
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: 2, height: 2)
                                    .foregroundStyle(.white)
                            }
                        }
                    }.disabled(true)
                }.frame(width: widthOrHeight(width: true) * 0.35)
            } else {
                HStack {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 2){
                                ForEach(audioPlayer.soundSamples, id: \.id) { level in
                                    BarView(isRecording: false, sample: level).id(level)
                                }
                            }
                            .onChange(of: audioPlayer.soundSamples) { _, _ in
                                proxy.scrollTo(audioPlayer.soundSamples.last)
                            }
                        }
                        .disabled(true)
                    }
                }.frame(width: widthOrHeight(width: true) * 0.35)
            }
            HStack(spacing: 4){
                Text(audioPlayer.currentTime.description)
                Image(systemName: "speaker.wave.3").bold()
            }.font(.system(size: 13))
        }
        .onChange(of: popRoot.currentSound, { _, new in
            if new != (messageID + audioUrl.absoluteString) {
                stopPlaying()
            }
        })
        .onChange(of: currentAudio, { _, new in
            if !currentAudio.isEmpty {
                stopPlaying()
            }
        })
        .onDisappear(perform: {
            if popRoot.currentSound == (messageID + audioUrl.absoluteString) {
                popRoot.currentSound = ""
            }
        })
        .frame(height: 45)
        .onChange(of: gcModel.startNextAudio) { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue == full {
                gcModel.startNextAudio = ""
                playAudio()
            }
        }
        .onChange(of: gcModel.currentAudio, { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue != full && audioPlayer.isPlaying {
                stopPlaying()
            }
        })
        .onChange(of: audioPlayer.didEnd) { _, newValue in
            if newValue && !messageID.isEmpty {
                if let index = gcModel.currentChat, index < gcModel.chats.count {
                    if let position = gcModel.chats[index].messages?.firstIndex(where: { $0.id == messageID }) {
                        if position > 0 {
                            if let urlID = gcModel.chats[index].messages?[position - 1].audioURL, let messID = gcModel.chats[index].messages?[position - 1].id {
                                gcModel.startNextAudio = messID + urlID
                            } else if let urlID = gcModel.chats[index].messages?[position - 1].replyAudio, let messID = gcModel.chats[index].messages?[position - 1].id {
                                gcModel.startNextAudio = messID + urlID
                            } else if position > 1 {
                                if let urlID = gcModel.chats[index].messages?[position - 2].audioURL, let messID = gcModel.chats[index].messages?[position - 2].id {
                                    gcModel.startNextAudio = messID + urlID
                                } else if let urlID = gcModel.chats[index].messages?[position - 2].replyAudio, let messID = gcModel.chats[index].messages?[position - 2].id {
                                    gcModel.startNextAudio = messID + urlID
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    private func playAudio() {
        audioPlayer.startPlayback(audio: audioUrl)
        currentAudio = ""
        popRoot.currentSound = messageID + audioUrl.absoluteString
    }
    private func stopPlaying() {
        audioPlayer.stopPlayback()
    }
}

func downloadAudioGetLocalURL(url_str: String, completion: @escaping (URL?) -> Void) {
    if let url = URL(string: url_str) {
        let timestamp = Date().timeIntervalSince1970
        let fileName = "downloadedAudio_\(timestamp).m4a"
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectoryURL.appendingPathComponent(fileName)
        let session = URLSession(configuration: .default)
        
        let downloadTask = session.downloadTask(with: url) { (tempURL, response, error) in
            guard let tempURL = tempURL, error == nil else {
                completion(nil)
                return
            }
            do {
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                completion(destinationURL)
            } catch {
                completion(nil)
            }
        }
        downloadTask.resume()
    } else {
        completion(nil)
    }
}

public struct MessageVoiceStreamViewThird: View {
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var gModel: GroupViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @StateObject var audioPlayer = AudioPlayer(numberOfSamples: 15)
    let audioUrl: URL
    let messageID: String
    let isGroup: Bool
    @Binding var currentAudio: String

    public var body: some View {
        HStack(spacing: 12){
            Button(action: {
                if audioPlayer.isPlaying {
                    stopPlaying()
                    popRoot.currentSound = ""
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    audioPlayer.playSystemSound(soundID: 1306)
                    playAudio()
                }
            }, label: {
                if audioPlayer.isPlaying {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 17)).padding(12)
                        .background(.white).clipShape(Circle())
                } else {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 17)).padding(12)
                        .background(Color(red: 1.0, green: 0.7, blue: 0.5)).clipShape(Circle())
                }
            })
            if audioPlayer.soundSamples.isEmpty {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 2){
                            ForEach(0..<80, id: \.self){ i in
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: 2, height: 2)
                                    .foregroundStyle(.white)
                            }
                        }
                    }.disabled(true)
                }.frame(width: widthOrHeight(width: true) * 0.35)
            } else {
                HStack {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 2){
                                ForEach(audioPlayer.soundSamples, id: \.id) { level in
                                    BarView(isRecording: false, sample: level).id(level)
                                }
                            }
                            .onChange(of: audioPlayer.soundSamples) { _, _ in
                                proxy.scrollTo(audioPlayer.soundSamples.last)
                            }
                        }
                        .disabled(true)
                    }
                }.frame(width: widthOrHeight(width: true) * 0.35)
            }
            HStack(spacing: 4){
                Text(audioPlayer.currentTime.description)
                Image(systemName: "speaker.wave.3")
            }.font(.system(size: 13))
        }
        .onChange(of: popRoot.currentSound, { _, new in
            if new != (messageID + audioUrl.absoluteString) {
                stopPlaying()
            }
        })
        .onChange(of: currentAudio, { _, new in
            if !currentAudio.isEmpty {
                stopPlaying()
            }
        })
        .onDisappear(perform: {
            if popRoot.currentSound == (messageID + audioUrl.absoluteString) {
                popRoot.currentSound = ""
            }
        })
        .frame(height: 45)
        .padding(10)
        .background(audioPlayer.isPlaying ? Color(red: 1.0, green: 0.7, blue: 0.5) : Color(UIColor.lightGray))
        .clipShape(Capsule())
        .onChange(of: viewModel.startNextAudio) { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue == full {
                viewModel.startNextAudio = ""
                playAudio()
            }
        }
        .onChange(of: gModel.startNextAudio) { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue == full {
                gModel.startNextAudio = ""
                playAudio()
            }
        }
        .onChange(of: viewModel.currentAudio, { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue != full && audioPlayer.isPlaying {
                stopPlaying()
            }
        })
        .onChange(of: gModel.currentAudio, { _, newValue in
            let full = messageID + audioUrl.absoluteString
            if newValue != full && audioPlayer.isPlaying {
                stopPlaying()
            }
        })
        .onChange(of: audioPlayer.didEnd) { _, newValue in
            if newValue && !messageID.isEmpty {
                if isGroup {
                    if let index = gModel.currentGroup, index < gModel.groups.count {
                        if let square = gModel.groups[index].1.messages?.first(where: { $0.id == gModel.groups[index].0 }) {
                            if let position = square.messages.firstIndex(where: { $0.id == messageID }) {
                                if position < (square.messages.count - 1) {
                                    if let urlID = square.messages[position + 1].audioURL, let messID = square.messages[position + 1].id {
                                        gModel.startNextAudio = messID + urlID
                                    } else if let urlID = square.messages[position + 1].replyAudio, let messID = square.messages[position + 1].id {
                                        gModel.startNextAudio = messID + urlID
                                    } else if position < (square.messages.count - 2) {
                                        if let urlID = square.messages[position + 2].audioURL, let messID = square.messages[position + 2].id {
                                            gModel.startNextAudio = messID + urlID
                                        } else if let urlID = square.messages[position + 2].replyAudio, let messID = square.messages[position + 2].id {
                                            gModel.startNextAudio = messID + urlID
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if let index = viewModel.currentChat, index < viewModel.chats.count {
                        if let position = viewModel.chats[index].messages?.firstIndex(where: { $0.id == messageID }) {
                            if position > 0 {
                                if let urlID = viewModel.chats[index].messages?[position - 1].audioURL, let messID = viewModel.chats[index].messages?[position - 1].id {
                                    viewModel.startNextAudio = messID + urlID
                                } else if let urlID = viewModel.chats[index].messages?[position - 1].replyAudio, let messID = viewModel.chats[index].messages?[position - 1].id {
                                    viewModel.startNextAudio = messID + urlID
                                } else if position > 1 {
                                    if let urlID = viewModel.chats[index].messages?[position - 2].audioURL, let messID = viewModel.chats[index].messages?[position - 2].id {
                                        viewModel.startNextAudio = messID + urlID
                                    } else if let urlID = viewModel.chats[index].messages?[position - 2].replyAudio, let messID = viewModel.chats[index].messages?[position - 2].id {
                                        viewModel.startNextAudio = messID + urlID
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    private func playAudio() {
        currentAudio = ""
        audioPlayer.startPlayback(audio: audioUrl)
        popRoot.currentSound = messageID + audioUrl.absoluteString
    }
    private func stopPlaying() {
        audioPlayer.stopPlayback()
    }
}
