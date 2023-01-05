import SwiftUI
import AVKit
import Kingfisher
import AVFoundation

struct pollMakeView: View {
    @Binding var text1: String
    @Binding var text2: String
    @Binding var text3: String
    @Binding var text4: String
    @Binding var show: Bool
    @State var amountShow: Int = 2
    @Environment(\.colorScheme) var colorScheme
    @FocusState var focusedField1: FocusedField?
    @FocusState var focusedField2: FocusedField?
    @FocusState var focusedField3: FocusedField?
    @FocusState var focusedField4: FocusedField?
    
    var body: some View {
        HStack {
            VStack(spacing: 10){
                TextField("Choice 1", text: $text1)
                    .tint(.blue)
                    .padding(10)
                    .padding(.trailing, 7)
                    .focused($focusedField1, equals: .one)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(focusedField1 == .one ? .blue : (colorScheme == .dark ? .white : .black), lineWidth: 1.0)
                    }
                    .overlay {
                        HStack {
                            Spacer()
                            Text("\(35 - text1.count)")
                                .foregroundStyle(.gray)
                        }.padding(.trailing, 5)
                    }
                    .onChange(of: text1){ _, new in
                        if text1.count > 35 {
                            text1.removeLast()
                        }
                    }
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded({ _ in
                                focusedField1 = .one
                            })
                    )
                TextField("Choice 2", text: $text2)
                    .tint(.blue)
                    .padding(10)
                    .padding(.trailing, 7)
                    .focused($focusedField2, equals: .one)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(focusedField2 == .one ? .blue : (colorScheme == .dark ? .white : .black), lineWidth: 1.0)
                    }
                    .overlay {
                        HStack {
                            Spacer()
                            Text("\(35 - text2.count)")
                                .foregroundStyle(.gray)
                        }.padding(.trailing, 5)
                    }
                    .onChange(of: text2){ _, new in
                        if text2.count > 35 {
                            text2.removeLast()
                        }
                    }
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded({ _ in
                                focusedField2 = .one
                            })
                    )
                if amountShow > 2 {
                    TextField("Choice 3 (optional)", text: $text3)
                        .tint(.blue)
                        .padding(10)
                        .padding(.trailing, 7)
                        .focused($focusedField3, equals: .one)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(focusedField3 == .one ? .blue : (colorScheme == .dark ? .white : .black), lineWidth: 1.0)
                        }
                        .overlay {
                            HStack {
                                Spacer()
                                Text("\(35 - text3.count)")
                                    .foregroundStyle(.gray)
                            }.padding(.trailing, 5)
                        }
                        .onChange(of: text3){ _, new in
                            if text3.count > 35 {
                                text3.removeLast()
                            }
                        }
                        .highPriorityGesture(
                            TapGesture()
                                .onEnded({ _ in
                                    focusedField3 = .one
                                })
                        )
                }
                if amountShow > 3 {
                    TextField("Choice 4 (optional)", text: $text4)
                        .tint(.blue)
                        .padding(10)
                        .padding(.trailing, 7)
                        .focused($focusedField4, equals: .one)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(focusedField4 == .one ? .blue : (colorScheme == .dark ? .white : .black), lineWidth: 1.0)
                        }
                        .overlay {
                            HStack {
                                Spacer()
                                Text("\(35 - text4.count)")
                                    .foregroundStyle(.gray)
                            }.padding(.trailing, 5)
                        }
                        .onChange(of: text4){ _, new in
                            if text4.count > 35 {
                                text4.removeLast()
                            }
                        }
                        .highPriorityGesture(
                            TapGesture()
                                .onEnded({ _ in
                                    focusedField4 = .one
                                })
                        )
                }
            }.padding(.trailing, 35)
        }
        .overlay(content: {
            HStack {
                Spacer()
                VStack {
                    Button(action: {
                        withAnimation {
                            show = false
                        }
                        text1 = ""
                        text3 = ""
                        text2 = ""
                        text4 = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }, label: {
                        Image(systemName: "xmark").font(.subheadline)
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                            .padding(5)
                            .background(colorScheme == .dark ? .white : .black)
                            .clipShape(Circle())
                    })
                    Spacer()
                    Button(action: {
                        withAnimation {
                            amountShow += 1
                        }
                    }, label: {
                        Image(systemName: "plus").foregroundStyle(.blue)
                            .font(.headline)
                    }).padding(.bottom, 14)
                }
            }
        })
        .padding(10)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray, lineWidth: 1.0)
        }
    }
}

struct uploadContent: Identifiable {
    var id: UUID = UUID()
    var isImage: Bool
    var videoURL: URL?
    var selectedImage: UIImage?
    var hustleImage: Image?
    var imageURL: String?
}

struct UploadHustleVideo: View {
    let url: URL
    @Binding var muted: Bool
    @State var player: AVPlayer? = nil
    @State var value: Float = 0
    @State var currentTime: Double = 0.0
    @State var totalLength: Double = 1.0
    let isSelected: Bool
    @Binding var makenil: Bool
    let executeNow: () -> Void
    
    var body: some View {
        ZStack {
            if player != nil {
                VideoPlayerUpload(player: $player).scaledToFill()
            }
        }
        .frame(height: 300)
        .onChange(of: makenil, { _, _ in
            self.player?.pause()
            player = nil
        })
        .onDisappear(perform: {
            self.player?.pause()
            player = nil
        })
        .overlay(alignment: .topTrailing){
            Button {
                self.player?.pause()
                player = nil
                executeNow()
            } label: {
                Image(systemName: "xmark")
                    .padding(9)
                    .background(.ultraThickMaterial)
                    .clipShape(Circle())
            }.padding(10)
        }
        .task(id: isSelected) {
            if isSelected {
                if player == nil {
                    player = AVPlayer(url: url)
                    player?.isMuted = muted
                    
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
                await self.player?.seek(to: .zero)
                self.player?.play()
            } else {
                self.player?.pause()
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onChange(of: muted) { _, _ in
            player?.isMuted = muted
        }
    }
    func getSliderValue() -> Float {
        if let total = self.player?.currentItem?.duration.seconds, self.player?.currentTime().seconds ?? 0.0 > 0.0, total > 0.0 {
            currentTime = self.player?.currentTime().seconds ?? 0.0
            return Float(currentTime / total)
        } else {
            return 0.0
        }
    }
}

struct VideoPlayerUpload: UIViewControllerRepresentable {
    @Binding var player: AVPlayer?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayerUpload>) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.allowsVideoFrameAnalysis = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayerUpload>) { }
}
