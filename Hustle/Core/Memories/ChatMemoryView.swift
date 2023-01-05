import SwiftUI
import Kingfisher
import Firebase
import CoreLocation
import AVFoundation

struct ChatMemoryView: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @Environment(\.colorScheme) var colorScheme
    @State var time = ""
    @State var place = ""
    @State var memory: Memory? = nil
    @State var noneFound = false
    @State var sendLink: String = ""
    @State private var showForward = false
    @State private var saved = false
    @State private var fetchingPlace = false
    @State var thumbnail: UIImage? = nil
    @State var playVideo = false
    @State var player: AVPlayer? = nil
    
    let url: String
    let leading: Bool
    
    var body: some View {
        HStack(spacing: 10){
            if leading {
                Spacer()
                if memory?.image != nil || memory?.video != nil {
                    optionButtons()
                }
            }
            VStack(alignment: .leading){
                HStack(spacing: 8){
                    Image("memory")
                        .resizable()
                        .scaledToFit().scaleEffect(1.4).offset(x: 2, y: 2)
                        .frame(width: 30, height: 30)
                    Text("Memory").bold()
                    if memory == nil && !noneFound {
                        ProgressView().padding(.leading, 20)
                    }
                }
                if let memory = memory {
                    if let image = memory.image {
                        KFImage(URL(string: image))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 225, height: 310)
                            .overlay(alignment: .bottom){
                                if !time.isEmpty {
                                    ZStack {
                                        VStack(spacing: 2){
                                            Text(time).fontWeight(.semibold).lineLimit(1).minimumScaleFactor(0.8)
                                            
                                            Text(place).fontWeight(.light).lineLimit(1)
                                                .font(.caption).minimumScaleFactor(0.8)
                                        }.transition(.move(edge: .bottom))
                                    }
                                    .frame(width: 225, height: 45)
                                    .background(.ultraThinMaterial)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                    } else if let video = memory.video {
                        if let image = thumbnail {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 225, height: 310)
                                .overlay(content: {
                                    if !playVideo {
                                        Image(systemName: "play.fill")
                                            .font(.title3).padding(10)
                                            .background(.ultraThickMaterial)
                                            .clipShape(Circle())
                                            .offset(y: -15)
                                    }
                                })
                                .overlay(alignment: .bottom){
                                    if !time.isEmpty && !playVideo {
                                        ZStack {
                                            VStack(spacing: 2){
                                                Text(time).fontWeight(.semibold).lineLimit(1).minimumScaleFactor(0.8)
                                                
                                                Text(place).fontWeight(.light).lineLimit(1)
                                                    .font(.caption).minimumScaleFactor(0.8)
                                            }
                                        }
                                        .frame(width: 225, height: 45)
                                        .background(.ultraThinMaterial)
                                        .transition(.move(edge: .bottom))
                                        .animation(.easeInOut(duration: 0.2), value: playVideo)
                                    }
                                }
                                .overlay(content: {
                                    if let player, playVideo {
                                        CustomVideoPlayer(player: player)
                                            .transition(.identity)
                                            .onAppear {
                                                player.isMuted = false
                                                player.play()
                                                NotificationCenter.default.addObserver (
                                                    forName: .AVPlayerItemDidPlayToEndTime,
                                                    object: player.currentItem,
                                                    queue: .main
                                                ) { _ in
                                                    player.seek(to: .zero)
                                                    player.play()
                                                }
                                                player.actionAtItemEnd = .none
                                            }
                                            .onDisappear {
                                                self.player?.isMuted = true
                                                self.player?.pause()
                                            }
                                    }
                                })
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .contentShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(.gray).opacity(0.2)
                                .frame(width: 225, height: 310)
                                .overlay(content: {
                                    ProgressView().scaleEffect(1.2)
                                })
                                .onAppear {
                                    if let url = URL(string: video) {
                                        extractImageAt(f_url: url, time: .zero, size: CGSize(width: 225.0, height: 310.0)) { thumbnail in
                                            self.thumbnail = thumbnail
                                        }
                                    }
                                }
                        }
                    } else {
                        Text("The Memory could not be fetched. This content may have been deleted by its owner. Check your network connection.").font(.system(size: 13)).multilineTextAlignment(.leading).frame(width: 150).padding(.top, 3)
                    }
                } else if noneFound {
                    Text("The Memory could not be fetched. This content may have been deleted by its owner. Check your network connection.").font(.system(size: 13)).multilineTextAlignment(.leading).frame(width: 150).padding(.top, 3)
                }
            }
            .padding(8)
            .background(.gray.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
            .onTapGesture {
                if memory?.image != nil {
                    //animate up
                } else if memory?.video != nil {
                    //animate video up
                }
            }
            if !leading {
                if memory?.image != nil || memory?.video != nil {
                    optionButtons()
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .onAppear(perform: {
            if memory == nil {
                getData()
            }
        })
        .onChange(of: scenePhase) { _, newPhase in
            if player != nil && playVideo {
                if newPhase == .inactive {
                    player?.pause()
                } else if newPhase == .active {
                    player?.play()
                } else if newPhase == .background {
                    player?.pause()
                }
            }
        }
    }
    func getData() {
        if let (uid, id) = extractUidAndId(from: url) {
            if let first = popRoot.randomMemories.first(where: { $0.id == id }) {
                self.memory = first
            } else if let idx = popRoot.allMemories.firstIndex(where: { $0.allMemories.contains(where: { $0.memory.id == id }) }) {
                self.memory = popRoot.allMemories[idx].allMemories.first(where: { $0.id == id })?.memory
            }
            if let date = memory?.createdAt, time.isEmpty {
                setTime(timestamp: date.dateValue())
            }
            if let lat = memory?.lat, let long = memory?.long, place.isEmpty {
                setPlace(lat: lat, long: long)
            }
            if memory == nil {
                UserService().fetchMemory(uid: uid, id: id) { mem in
                    if let memTemp = mem {
                        self.memory = memTemp
                        popRoot.randomMemories.append(memTemp)
                        setTime(timestamp:  memTemp.createdAt.dateValue())
                        if let lat = memory?.lat, let long = memory?.long {
                            setPlace(lat: lat, long: long)
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)){
                            noneFound = true
                        }
                    }
                }
            }
        }
    }
    func setTime(timestamp: Date) {
        let calendar = Calendar.current
        let currentDate = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: timestamp, to: currentDate)
        
        withAnimation(.easeInOut(duration: 0.2)){
            if let years = components.year, years >= 1, components.month == 0, components.day == 0 {
                time = "\(years) Year\(years > 1 ? "s" : "") Ago"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM dd, YYYY"
                time = dateFormatter.string(from: timestamp)
            }
        }
    }
    func setPlace(lat: CGFloat, long: CGFloat) {
        if !fetchingPlace {
            fetchingPlace = true
            let location = CLLocation(latitude: lat, longitude: long)
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    fetchingPlace = false
                }
                if error != nil { return }
                guard let placemark = placemarks?.first else { return }

                let city = placemark.locality
                let state = placemark.administrativeArea
                let country = placemark.country
              
                var flag: String = ""
                if let code = placemark.isoCountryCode {
                    flag = countryFlag(code)
                }
                if let city = city, var country = country {
                    if country == "Israel" {
                        country = "Palestine"
                        flag = "🇵🇸"
                    }
                    withAnimation(.easeInOut(duration: 0.2)){
                        if let state = state, !state.isEmpty {
                            place = "\(city), \(state)"
                        } else {
                            place = "\(city), \(country)\(flag)"
                        }
                    }
                }
            }
        }
    }
    func optionButtons() -> some View {
        VStack(spacing: 10){
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let id = memory?.id, let uid = auth.currentUser?.id {
                    sendLink = "https://hustle.page/memory/\(uid)/\(id)/"
                    showForward = true
                }
            }, label: {
                Image(systemName: "paperplane")
                    .frame(width: 18, height: 18)
                    .font(.headline)
                    .padding(8)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            })
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let image = memory?.image {
                    downloadAndSaveImage(url: image)
                    popRoot.alertReason = "Image Saved"
                } else if let video = memory?.video {
                    saveVideoToCameraRoll(urlStr: video)
                    popRoot.alertReason = "Video Saved"
                }
                popRoot.alertImage = "link"
                withAnimation(.easeInOut(duration: 0.2)){
                    popRoot.showAlert = true
                    saved = true
                }
            }, label: {
                Image(systemName: saved ? "checkmark.icloud" : "square.and.arrow.down")
                    .frame(width: 18, height: 18)
                    .font(.headline)
                    .contentTransition(.symbolEffect(.replace))
                    .padding(8).foregroundStyle(.blue)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            })
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                popRoot.alertReason = "Memory URL copied"
                popRoot.alertImage = "link"
                withAnimation {
                    popRoot.showAlert = true
                }
                if let id = memory?.id, let uid = auth.currentUser?.id {
                    UIPasteboard.general.string = "https://hustle.page/memory/\(uid)/\(id)/"
                }
            }, label: {
                Image(systemName: "link")
                    .frame(width: 18, height: 18)
                    .font(.headline)
                    .padding(8).foregroundStyle(.blue)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            })
            if let video = memory?.video {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)){
                        playVideo.toggle()
                    }
                    if playVideo {
                        if let url = URL(string: video), player == nil {
                            player = AVPlayer(url: url)
                        }
                        player?.play()
                        player?.isMuted = false
                    } else {
                        player?.isMuted = true
                        player?.pause()
                    }
                }, label: {
                    Image(systemName: playVideo ? "pause" : "play.fill")
                        .frame(width: 18, height: 18)
                        .font(.headline).contentTransition(.symbolEffect(.replace))
                        .padding(8).foregroundStyle(.blue)
                        .background(.gray.opacity(0.2))
                        .clipShape(Circle())
                })
            }
        }
    }
}

func extractUidAndId(from urlString: String) -> (uid: String, id: String)? {
    let components = urlString.split(separator: "/").map(String.init)
    guard components.count >= 5 else { return nil }
    let uid = components[3]
    let id = components[4]
    return (uid, id)
}
