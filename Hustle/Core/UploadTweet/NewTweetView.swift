import SwiftUI
import UIKit
import Kingfisher
import AVFoundation

struct NewTweetView: View, KeyboardReadable {  
    @StateObject var storeKit = StoreKitManager()
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var recorder: AudioRecorder
    @EnvironmentObject var searchModel: CitySearchViewModel
    @EnvironmentObject var stockModel: StockViewModel
    @EnvironmentObject var exploreModel: ExploreViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State var purchaseFailed: Bool = false
    @State private var selectedFilter: PromoteViewModel = .USD
    @State private var tooManyInOneHour = ""
    @Namespace var animation
    @State private var caption = ""
    @State private var captionError = ""
    @State private var videoLink = ""
    @State private var videoLinkError = false
    @State private var showVideo = false
    @State private var kingPro: Int = 0
    @State private var promotedELO: Int = 0
    @State private var promotedUSD: Int = 0
    @State private var uploadError = ""
    @State private var uploaded = false
    @State private var keyBoardShowing = false
    @State private var showPromoteSheet = false
    @State private var showImagePicker = false
    @State var muted = false
    @FocusState var focusedField: FocusedField?
    @State private var recordingTimer: Timer?
    @State private var currentTimeR = 0
    @State private var audioTooLong = false
    @State private var whichToggle: Int = 1
    @State private var mediaAlert = false
    @State private var showCamera = false
    @State private var showAudioSheet = false
    @Binding var place: myLoc?
    @State private var showLocPicker = false
    @State var selection = 0
    @State var fetchingLocation = false
    let manager = GlobeLocationManager()
    @State private var matchedStocks = [String]()
    @State private var matchedHashtags = [String]()
    @State var choice1: String = ""
    @State var choice2: String = ""
    @State var choice3: String = ""
    @State var choice4: String = ""
    @State var showPoll = false
    @State private var tag = ""
    @State private var target = ""
    @State var showVisibleSheet = false
    @Binding var visibility: String
    @Binding var visibilityImage: String
    @State var uploadCont = [uploadContent]()
    @State private var selectionNew = 0
    @Binding var initialContent: uploadContent?
    @State var showMemories = false
    @State var yelpID: String?
    @State var newsID: String?
    @State var showAI = false
    @State var dismissAI = false
    @State var showFixText = false
    @State var makeVidNil = false
    @State var fetchingTopHashtags = false
    @State var showAlert: Int = 0
    @State var showNewsSheetPicker = false
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    HStack {
                        Button {
                            makeVidNil.toggle()
                            presentationMode.wrappedValue.dismiss()
                            popRoot.currentAudio = popRoot.tempCurrentAudio
                            popRoot.tempCurrentAudio = ""
                        } label: {
                            Text("Cancel").foregroundColor(Color(.systemBlue))
                        }
                        Spacer()
                        if tooManyInOneHour.isEmpty {
                            let status = ((!caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && captionError.isEmpty) || (!videoLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !videoLinkError) || !uploadCont.isEmpty || !recorder.recordings.isEmpty)
                            
                            Button {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                if status && !uploaded {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    uploadPost()
                                }
                            } label: {
                                if uploaded {
                                    LottieView(loopMode: .loop, name: "placeLoader")
                                        .frame(width: 30, height: 30)
                                        .scaleEffect(0.45)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Text(promotedUSD > 0 ? "Pay + Upload" : "Share Hustle")
                                        .bold().font(.subheadline)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(status ? .orange.opacity(0.7) : .gray.opacity(0.7))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                        .shadow(color: .gray.opacity(0.6), radius: 10, x: 0, y: 0)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        } else {
                            Text(tooManyInOneHour).font(.subheadline).foregroundColor(.red)
                        }
                    }
                    .padding()
                    .alert("Purchase failed", isPresented: $purchaseFailed) { Button("Close", role: .cancel) {} }
                    
                    if showAI {
                        HStack {
                            BasicAiButtonView(showFixText: $showFixText, caption: $caption, showAI: $showAI, dismissAI: $dismissAI, showAlert: $showAlert, viewOption: false).transition(.scale.combined(with: .opacity))
                            Spacer()
                        }.padding(.horizontal).padding(.top)
                    }
                    
                    ZStack(alignment: .topLeading){
                        TextEditor(text: $caption)
                            .padding(4)
                            .lineLimit(10)
                            .tint(colorScheme == .dark ? .white : .black)
                            .focused($focusedField, equals: .one)
                            .onAppear {
                                focusedField = .one
                            }
                        if caption.isEmpty {
                            HStack {
                                Text("Post a huslte, be specific, or post anything business related")
                                    .foregroundColor(Color(.placeholderText))
                                    .font(.system(size: 18))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 12)
                                Spacer()
                            }
                            .onTapGesture {
                                focusedField = .one
                            }
                        }
                    }
                    .font(.body)
                    .padding()
                    .onChange(of: caption) { _, _ in
                        captionError = inputChecker().myInputChecker(withString: caption, withLowerSize: 0, withUpperSize: 2000, needsLower: false)
                        if caption.isEmpty { captionError = "" }
                        uploadError = ""
                        getStock()
                        getHashtag()
                    }
                    
                    if !captionError.isEmpty {
                        HStack {
                            Text(captionError).font(.caption).foregroundColor(.red).bold()
                            Spacer()
                        }.padding(.bottom, 10).padding(.leading).padding(.leading, 4)
                    } else if !uploadError.isEmpty {
                        HStack {
                            Text(uploadError).font(.caption).foregroundColor(.red).bold()
                            Spacer()
                        }.padding(.bottom, 10).padding(.leading).padding(.leading, 4)
                    }
                    
                    if let loc = self.place {
                        HStack {
                            HStack(spacing: 12){
                                Image(systemName: "globe").foregroundStyle(.blue).font(.headline)
                                if !loc.city.isEmpty && !loc.state.isEmpty{
                                    Text("\(loc.city) \(loc.state), \(loc.country)").font(.headline)
                                } else {
                                    Text("\(loc.city)\(loc.state), \(loc.country)").font(.headline)
                                }
                                Button {
                                    withAnimation {
                                        self.place = nil
                                    }
                                } label: {
                                    Image(systemName: "xmark").font(.headline)
                                }.padding(.leading, 10)
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            Spacer()
                        }
                        .padding(.top, 5).padding(.leading).padding(.leading, 4)
                        .transition(.scale.combined(with: .opacity))
                    }
                    if !uploadCont.isEmpty {
                        TabView(selection: $selectionNew) {
                            ForEach(Array(uploadCont.enumerated()), id: \.1.id) { index, content in
                                Group {
                                    if let image = content.hustleImage {
                                        HStack {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxWidth: widthOrHeight(width: true) - 50, maxHeight: 300)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                .contentShape(Rectangle())
                                                .overlay(content: {
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .stroke(Color(UIColor.lightGray), lineWidth: 1)
                                                })
                                                .contextMenu {
                                                    Button {
                                                        withAnimation {
                                                            self.uploadCont.removeAll(where: { $0.id == content.id })
                                                        }
                                                    } label: {
                                                        Text("Delete")
                                                    }
                                                } preview: {
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                                        .contentShape(Rectangle())
                                                }
                                                .overlay(alignment: .topTrailing){
                                                    ZStack {
                                                        Circle().frame(width: 30).disabled(true)
                                                        Button {
                                                            withAnimation {
                                                                self.uploadCont.removeAll(where: { $0.id == content.id })
                                                            }
                                                        } label: {
                                                            Image(systemName: "xmark").foregroundStyle(.white)
                                                                .padding(9)
                                                                .background(.ultraThickMaterial)
                                                                .clipShape(Circle())
                                                        }.padding(10)
                                                    }
                                                }
                                            Spacer()
                                        }
                                        .padding(.vertical, 5).padding(.horizontal).padding(.leading, 4)
                                    } else if let url = content.videoURL {
                                        HStack {
                                            UploadHustleVideo(url: url, muted: $muted, isSelected: selectionNew == index, makenil: $makeVidNil, executeNow: {
                                                withAnimation {
                                                    self.uploadCont.removeAll(where: { $0.id == content.id })
                                                }
                                            })
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .contentShape(Rectangle())
                                            .overlay(content: {
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color(UIColor.lightGray), lineWidth: 1)
                                            })
                                            .overlay(alignment: .topLeading){
                                                Button {
                                                    muted.toggle()
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                } label: {
                                                    Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2")
                                                        .padding(9)
                                                        .background(.ultraThickMaterial)
                                                        .clipShape(Circle())
                                                }.padding(10)
                                            }
                                            Spacer()
                                        }.padding(.vertical, 5).padding(.horizontal).padding(.leading, 4)
                                    } else if let image = content.imageURL {
                                        HStack {
                                            KFImage(URL(string: image))
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxWidth: widthOrHeight(width: true) - 50, maxHeight: 300)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                .contentShape(Rectangle())
                                                .overlay(content: {
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .stroke(Color(UIColor.lightGray), lineWidth: 1)
                                                })
                                                .contextMenu {
                                                    Button {
                                                        withAnimation {
                                                            self.uploadCont.removeAll(where: { $0.id == content.id })
                                                        }
                                                    } label: {
                                                        Text("Delete")
                                                    }
                                                } preview: {
                                                    KFImage(URL(string: image))
                                                        .resizable()
                                                        .scaledToFit()
                                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                                        .contentShape(Rectangle())
                                                }
                                                .overlay(alignment: .topTrailing){
                                                    ZStack {
                                                        Circle().frame(width: 30).disabled(true)
                                                        Button {
                                                            withAnimation {
                                                                self.uploadCont.removeAll(where: { $0.id == content.id })
                                                            }
                                                        } label: {
                                                            Image(systemName: "xmark").foregroundStyle(.white)
                                                                .padding(9)
                                                                .background(.ultraThickMaterial)
                                                                .clipShape(Circle())
                                                        }.padding(10)
                                                    }
                                                }
                                            Spacer()
                                        }
                                        .padding(.vertical, 5).padding(.horizontal).padding(.leading, 4)
                                    }
                                }.tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(width: widthOrHeight(width: true), height: 310)
                        .overlay(alignment: .bottom){
                            if uploadCont.count > 1 {
                                HStack(spacing: 4){
                                    ForEach(Array(uploadCont.enumerated()), id: \.1.id) { index, _ in
                                        Circle().frame(width: 4, height: 4)
                                            .foregroundStyle(index == selectionNew ? .white : .gray)
                                    }
                                }
                                .padding(5)
                                .background {
                                    TransparentBlurView(removeAllFilters: true)
                                        .blur(radius: 7, opaque: true)
                                        .background(.gray.opacity(0.6))
                                }
                                .clipShape(Capsule())
                                .padding(.bottom)
                                .scaleEffect(1.2)
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else if !videoLink.isEmpty && !videoLinkError {
                        HStack {
                            let videoLink = inputChecker().getLink(videoLink: videoLink)
                            if !videoLink.contains(".") && !videoLink.contains("https://") && !videoLink.contains("com") && videoLink.contains("shorts"){
                                YouTubeView(link: videoLink, short: true).frame(width: 370, height: 370)
                            } else if !videoLink.contains(".") && !videoLink.contains("https://") && !videoLink.contains("com"){
                                YouTubeView(link: videoLink, short: false).frame(width: widthOrHeight(width: true) * 0.8, height: widthOrHeight(width: false) * 0.25)
                            } else {
                                WebVideoView(link: videoLink)
                                    .frame(width: widthOrHeight(width: true) * 0.88, height: widthOrHeight(width: false) * 0.23)
                            }
                            Spacer()
                        }.padding(.top, 5).padding(.horizontal).padding(.leading, 4)
                    } else if let first = recorder.recordings.first {
                        HStack {
                            VoicePlayerView(makenil: $makeVidNil, audioUrl: first.fileURL, userPhoto: authViewModel.currentUser?.profileImageUrl) {
                                deleteRecording()
                            }
                            Spacer()
                        }
                        .padding(.top, 5).padding(.horizontal).padding(.leading, 4)
                        .transition(.scale.combined(with: .opacity))
                    }
                    if showPoll {
                        HStack {
                            pollMakeView(text1: $choice1, text2: $choice2, text3: $choice3, text4: $choice4, show: $showPoll)
                            Spacer()
                        }
                        .padding(.top, 5).padding(.horizontal).padding(.leading, 4)
                        .transition(.scale.combined(with: .opacity))
                    }
                    if let id = yelpID {
                        HStack {
                            YelpRowView(placeID: id, isChat: false, isGroup: false, otherPhoto: nil)
                            Spacer()
                        }
                        .padding(.top, 5).padding(.horizontal).padding(.leading, 4)
                        .transition(.scale.combined(with: .opacity))
                    }
                    if let id = newsID, let news = exploreModel.news.first(where: { $0.id == id }) {
                        HStack {
                            Link(destination: URL(string: news.link)!) {
                                NewsRowView(news: news, isRow: false)
                                    .disabled(true)
                                    .overlay(alignment: .topTrailing){
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)){
                                                newsID = nil
                                            }
                                        } label: {
                                            Image(systemName: "xmark")
                                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                                .font(.subheadline)
                                                .padding(6)
                                                .background(.ultraThickMaterial)
                                                .clipShape(Circle())
                                        }.padding(10)
                                    }
                            }
                            Spacer()
                        }
                        .padding(.top, 5).padding(.horizontal).padding(.leading, 4)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .scrollIndicators(.hidden)
                Spacer()
                
                if (matchedStocks.isEmpty && matchedHashtags.isEmpty && (!caption.contains("@") || !tag.isEmpty)) || !keyBoardShowing {
                    if keyBoardShowing {
                        Divider().padding(.bottom, 3)
                    }
                    HStack {
                        Button {
                            showVisibleSheet = true
                        } label: {
                            HStack(spacing: 12){
                                if !visibility.isEmpty {
                                    KFImage(URL(string: visibilityImage))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 20, height: 20)
                                        .clipShape(Circle())
                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                    Text(visibility).font(.subheadline).foregroundStyle(.blue)
                                } else {
                                    Image(systemName: "globe").foregroundStyle(.blue).font(.subheadline)
                                    Text("Everyone can view").font(.subheadline).foregroundStyle(.blue)
                                }
                            }
                        }
                        Spacer()
                    }.padding(.leading, 10)
                    
                    Divider().padding(.bottom, 1)
                    ScrollView(.horizontal){
                        HStack(spacing: 7){
                            Color.clear.frame(width: 1, height: 6)
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if uploadCont.count > 9 {
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        showAlert = 1
                                    }
                                } else if !recorder.recordings.isEmpty || !videoLink.isEmpty {
                                    whichToggle = 1
                                    mediaAlert.toggle()
                                } else {
                                    muted = true
                                    showImagePicker.toggle()
                                }
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image(systemName: "photo").foregroundColor(.blue)
                                            .font(.system(size: 16))
                                    }.frame(width: 30, height: 30)
                                    Text("Media").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            Button {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if uploadCont.count > 9 {
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        showAlert = 1
                                    }
                                } else if !recorder.recordings.isEmpty || !videoLink.isEmpty {
                                    whichToggle = 2
                                    mediaAlert.toggle()
                                } else {
                                    if keyBoardShowing {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                            showCamera.toggle()
                                        }
                                    } else {
                                        showCamera.toggle()
                                    }
                                }
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image(systemName: "camera.fill").foregroundColor(.blue)
                                            .font(.system(size: 16))
                                    }.frame(width: 30, height: 30)
                                    Text("Camera").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            Button {
                                if !uploadCont.isEmpty || !videoLink.isEmpty {
                                    whichToggle = 3
                                    mediaAlert.toggle()
                                } else {
                                    showAudioSheet.toggle()
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image(systemName: "waveform").foregroundColor(.purple)
                                            .font(.system(size: 16))
                                    }.frame(width: 30, height: 30)
                                    Text("Audio").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            Button {
                                if !uploadCont.isEmpty || !recorder.recordings.isEmpty {
                                    whichToggle = 4
                                    mediaAlert.toggle()
                                } else {
                                    showVideo.toggle()
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .frame(height: 23)
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                        Image(systemName: "triangleshape.fill")
                                            .offset(y: -1)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.red)
                                            .rotationEffect(.degrees(90))
                                    }.frame(width: 35, height: 30)
                                    
                                    Text("Youtube").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if uploadCont.count > 9 {
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        showAlert = 1
                                    }
                                } else if !recorder.recordings.isEmpty || !videoLink.isEmpty {
                                    whichToggle = 5
                                    mediaAlert.toggle()
                                } else {
                                    showMemories = true
                                }
                            }, label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image("memory")
                                            .resizable()
                                            .frame(width: 28, height: 28)
                                            .scaledToFit()
                                            .offset(x: 1)
                                    }.frame(width: 30, height: 30)
                                    Text("Memory").font(.caption2).foregroundStyle(.blue)
                                }
                            })
                            Button {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                withAnimation(.easeIn(duration: 0.2)){
                                    showLocPicker.toggle()
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image(systemName: "mappin.and.ellipse").foregroundColor(.green)
                                            .font(.system(size: 16))
                                    }.frame(width: 30, height: 30)
                                    Text("Place").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            Button {
                                withAnimation {
                                    showPoll = true
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image(systemName: "exclamationmark.2")
                                            .rotationEffect(.degrees(90)).scaleEffect(x: 0.95)
                                            .font(.system(size: 18))
                                            .foregroundStyle(.blue)
                                    }.frame(width: 30, height: 30)
                                    Text("Poll").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            Button {
                                withAnimation {
                                    showNewsSheetPicker = true
                                }
                                if (exploreModel.news.count - exploreModel.singleNewsFetched) <= 1 {
                                    exploreModel.getNews()
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image(systemName: "newspaper.fill")
                                            .font(.system(size: 17))
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    }.frame(width: 30, height: 30)
                                    Text("News").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            Button {
                                focusedField = .one
                                if caption.isEmpty {
                                    caption += "$"
                                } else {
                                    caption += " $"
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image(systemName: "dollarsign").foregroundColor(.green).font(.system(size: 16))
                                    }.frame(width: 30, height: 30)
                                    Text("Asset").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            BasicAiButtonView(showFixText: $showFixText, caption: $caption, showAI: $showAI, dismissAI: $dismissAI, showAlert: $showAlert, viewOption: true)
                            Button {
                                focusedField = .one
                                if caption.isEmpty {
                                    caption += "@"
                                } else {
                                    caption += " @"
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    }.frame(width: 30, height: 30)
                                    Text("tag").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            Button {
                                focusedField = .one
                                if caption.isEmpty {
                                    caption += "#"
                                } else {
                                    caption += " #"
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image("hashtag")
                                            .resizable().scaledToFit()
                                    }.frame(width: 30, height: 30)
                                    Text("hashtag").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showPromoteSheet.toggle()
                            } label: {
                                VStack(spacing: 2){
                                    ZStack {
                                        Circle().foregroundStyle(.gray).opacity(0.4)
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 16))
                                            .gradientForeground(colors: colorScheme == .dark ? [.yellow, .green] : [.purple, .blue])
                                    }.frame(width: 30, height: 30)
                                    Text("promo").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            Color.clear.frame(width: 1, height: 6)
                        }
                    }
                    .padding(.bottom, 5)
                    .scrollIndicators(.hidden)
                }
            }
            .onTapGesture {
                focusedField = .one
                if showVideo {
                    showVideo = false
                }
            }
            .blur(radius: showVideo ? 5 : 0)
            .disabled(showVideo)
            if showVideo {
                VStack {
                    Spacer()
                    ZStack(alignment: .center){
                        RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                        RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                        VStack(spacing: 0){
                            HStack{
                                Text("Attach a video link").font(.system(size: 18)).foregroundColor(videoLinkError ? .red : colorScheme == .dark ? .black : .white).bold()
                                Spacer()
                            }.padding()
                            CustomVideoField(place: "Add a link to a Youtube video or any video online", text: $videoLink)
                                .padding(.bottom)
                                .onChange(of: videoLink) { _, _ in
                                    if !videoLink.isEmpty {
                                        if let url = URL(string: videoLink), UIApplication.shared.canOpenURL(url) {
                                            videoLinkError = false
                                        } else { videoLinkError = true }
                                    } else {
                                        videoLinkError = false
                                    }
                                }
                            Spacer()
                            HStack(spacing: 15){
                                Button {
                                    videoLink = ""
                                } label: {
                                    Text("Clear").font(.subheadline).bold().foregroundColor(.white)
                                        .padding(.horizontal).padding(.vertical, 4).background(.blue).cornerRadius(8)
                                }
                                Button {
                                    showVideo = false
                                } label: {
                                    Text("Add").font(.subheadline).bold().foregroundColor(.white)
                                        .padding(.horizontal, 20).padding(.vertical, 4).background(.blue).cornerRadius(8)
                                }
                            }.padding(.bottom, 5)
                        }.padding(5)
                    }
                    .frame(width: 320, height: 190)
                    .offset(y: -80)
                    Spacer()
                }
            }
            if keyBoardShowing {
                if !matchedStocks.isEmpty {
                    VStack {
                        Spacer()
                        stockPicker()
                    }
                } else if !matchedHashtags.isEmpty {
                    VStack {
                        Spacer()
                        hashtagPicker()
                    }
                } else if caption.contains("@") && tag.isEmpty {
                    VStack {
                        Spacer()
                        TaggedUserView(text: $caption, target: $target, commentID: nil, newsID: nil, newsRepID: nil, questionID: nil, groupID: nil, selectedtag: $tag)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewsSheetPicker, content: {
            VStack {
                ScrollView {
                    LazyVStack {
                        ForEach(exploreModel.news) { news in
                            NewsRowView(news: news, isRow: false)
                                .disabled(true)
                                .overlay(content: {
                                    if (newsID ?? "NA") == news.id {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue, lineWidth: 2.0)
                                    }
                                })
                                .overlay(content: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundStyle(Color.gray).opacity(0.001)
                                        .onTapGesture {
                                            showNewsSheetPicker = false
                                            withAnimation(.easeInOut(duration: 0.25)){
                                                self.newsID = news.id
                                            }
                                        }
                                })
                                .padding(.horizontal, 10)
                        }
                        if (exploreModel.news.count - exploreModel.singleNewsFetched) <= 1 {
                            VStack {
                                ForEach(0..<5) { _ in
                                    HStack {
                                        Spacer()
                                        LoadingNews().padding(.horizontal, 10)
                                        Spacer()
                                    }
                                }
                            }.shimmering()
                        }
                    }
                }.padding(.top, 15).scrollIndicators(.hidden)
            }
            .presentationDetents([.large])
            .presentationCornerRadius(20.0)
        })
        .onDisappear(perform: {
            makeVidNil.toggle()
        })
        .sheet(isPresented: $showMemories, content: {
            MemoryPickerSheetView(photoOnly: false, maxSelect: 10 - uploadCont.count) { allData in
                allData.forEach { element in
                    if element.isImage {
                        self.uploadCont.append(uploadContent(isImage: element.isImage, imageURL: element.urlString))
                    } else if let url = URL(string: element.urlString){
                        self.uploadCont.append(uploadContent(isImage: element.isImage, videoURL: url))
                    }
                }
            }
        })
        .overlay(content: {
            if showLocPicker {
                locPickView().transition(.move(edge: .bottom))
            }
        })
        .overlay(content: {
            if showAlert > 0 {
                VStack {
                    Text(showAlert == 1 ? "Limit 10 photos per post." : "Start typing for AI recommendations.")
                        .font(.subheadline).bold()
                        .padding(.horizontal)
                        .padding(.vertical, 7)
                        .background(.ultraThickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                    Spacer()
                }
                .transition(.move(edge: .top))
                .padding(.top, 30)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)){
                        showAlert = 0
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.15)){
                            showAlert = 0
                        }
                    }
                }
            }
        })
        .onChange(of: tag) { _, _ in
            if !tag.isEmpty {
                if let range = caption.range(of: "@") {
                    let final = caption.replacingCharacters(in: range, with: "@\(tag) ")
                    caption = removeSecondOccurrence(of: target, in: final)
                    target = ""
                }
            }
        }
        .onChange(of: caption) { _, _ in
            if !tag.isEmpty && !caption.contains("@\(tag)") {
                tag = ""
            }
            if caption.count > 30 && !showAI && !dismissAI {
                withAnimation(.easeInOut(duration: 0.15)){
                    showAI = true
                }
            } else if caption.count <= 30 && showAI {
                withAnimation(.easeInOut(duration: 0.15)){
                    showAI = false
                }
            }
        }
        .alert("Only 1 media type can be attached, would you like to replace it?", isPresented: $mediaAlert) {
            Button("Replace", role: .destructive) {
                withAnimation {
                    videoLink = ""
                    uploadCont = []
                    showPoll = false
                }
                deleteRecording()
                choice1 = ""
                choice2 = ""
                choice3 = ""
                choice4 = ""
                if whichToggle == 1 {
                    muted = true
                    showImagePicker = true
                } else if whichToggle == 2 {
                    showCamera = true
                } else if whichToggle == 3 {
                    showAudioSheet = true
                } else if whichToggle == 4 {
                    showVideo = true
                } else if whichToggle == 5 {
                    showMemories = true
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showImagePicker, content: {
            HustlePickerViewNew(add_content: $uploadCont, isImagePickerPresented: $showImagePicker)
        })
        .fullScreenCover(isPresented: $showCamera, content: {
            UploadTweetCamera(uploadCont: $uploadCont, isImagePickerPresented: $showCamera)
        })
        .sheet(isPresented: $showPromoteSheet, content: {
           promoView()
                .presentationDetents([.height(270.0)])
                .presentationCornerRadius(40)
        })
        .sheet(isPresented: $showAudioSheet, content: {
            audioView()
                .presentationDragIndicator(.hidden)
                .presentationDetents([.large])
                .presentationCornerRadius(40)
        })
        .sheet(isPresented: $showVisibleSheet, content: {
            visibileView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium])
                .presentationCornerRadius(40)
        })
        .onChange(of: showAudioSheet, { _, _ in
            if !showAudioSheet && recorder.recording {
                pauseRecording()
            }
        })
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
            keyBoardShowing = newIsKeyboardVisible
        }
        .dynamicTypeSize(.large)
        .onDisappear{ tooManyInOneHour = "" }
        .onChange(of: showVideo, { _, _ in
            if !showVideo && videoLinkError {
                videoLink = ""
                videoLinkError = false
            }
        })
        .onAppear {
            if let temp = initialContent {
                uploadCont.append(temp)
            }
            uploadError = ""
            tooManyInOneHour = ""
            if let user = authViewModel.currentUser {
                if user.elo >= 2900 { kingPro = 4 }
                if user.elo >= 850 { return }
                else {
                    let hustles = profile.users.first(where: { $0.user.username == user.username })
                    if let posts = hustles?.tweets {
                        var x = 0
                        let currentDate = Date()
                        posts.forEach { item in
                            let date = item.timestamp.dateValue()
                            let calendar = Calendar.current
                            if calendar.isDate(date, equalTo: currentDate, toGranularity: .hour) {
                                x += 1
                            }
                        }
                        if (x == 1 && user.elo < 600) || (x == 3 && user.elo < 850) {
                            tooManyInOneHour = "max uploads for this hour"
                        }
                    } else { return }
                }
            }
        }
        .onChange(of: promotedELO) { _, _ in
            if promotedELO > 0 {
                promotedUSD = 0
            }
        }
        .onChange(of: promotedUSD) { _, _ in
            if promotedUSD > 0 {
                promotedELO = 0
            }
        }
    }
    func handleCompletion(success: Bool) {
        if success {
            if promotedELO > 0 {
                UserService().editElo(withUid: nil, withAmount: (promotedELO * -50)) {}
            }
            
            deleteRecording()
            makeVidNil.toggle()
            
            presentationMode.wrappedValue.dismiss()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                popRoot.alertReason = "Post Uploaded!"
                popRoot.alertImage = "checkmark"
                withAnimation(.easeInOut(duration: 0.2)){
                    popRoot.showAlert = true
                }
            }
            
            if popRoot.tab == 1 {
                popRoot.currentAudio = popRoot.tempCurrentAudio
                popRoot.tempCurrentAudio = ""
            }
        } else if uploaded {
            uploadError = "Could not upload hustle"
            uploaded = false
        }
    }
    func leaveBackground() {
        deleteRecording()
        makeVidNil.toggle()
        
        presentationMode.wrappedValue.dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            popRoot.alertReason = "Upload in Progress"
            popRoot.alertImage = "clock.arrow.2.circlepath"
            withAnimation(.easeInOut(duration: 0.2)){
                popRoot.showAlert = true
            }
        }
        
        if popRoot.tab == 1 {
            popRoot.currentAudio = popRoot.tempCurrentAudio
            popRoot.tempCurrentAudio = ""
        }
    }
    func uploadPost() {
        let choice1 = choice1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : choice1
        let choice2 = choice2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : choice2
        let choice3 = choice3.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : choice3
        let choice4 = choice4.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : choice4
        
        if let user = authViewModel.currentUser {
            var shouldReturn = false
            if !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let hustles = profile.users.first(where: { $0.user.username == user.username })
                if let posts = hustles?.tweets?.prefix(7) {
                    let arr = Array(posts)

                    for i in 0..<arr.count {
                        if calculateCosineSimilarity(caption, arr[i].caption) > 0.6 {
                            uploadError = "This post matches another, please make it unique."
                            shouldReturn = true
                            break
                        }
                    }
                }
            }
            if shouldReturn {
                return
            }
            
            let smallLoc: String? = (place?.city ?? "").isEmpty ? place?.state : place?.city
            var background = recorder.recordings.first != nil
            
            if !background {
                for i in 0..<uploadCont.count {
                    if uploadCont[i].videoURL != nil || uploadCont[i].selectedImage != nil {
                        background = true
                        break
                    }
                }
            }
            
            if promotedUSD > 0 {
                Task {
                    if let product = storeKit.storeProducts.first(where: { $0.id == (promotedUSD == 3 ? "3Day" : "1Day") }){
                        do {
                            let result = try await storeKit.purchase(product)
                            if result {
                                popRoot.uploadTweet(withCaption: caption, withPro: promotedUSD, userPhoto: user.profileImageUrl ?? "", username: user.username, videoLink: videoLink, content: uploadCont, userVeri: user.verified, audioURL: recorder.recordings.first?.fileURL, sloc: smallLoc, bloc: place?.country, lat: place?.lat, long: place?.long, choice1: choice1, choice2: choice2, choice3: choice3, choice4: choice4, fullname: user.fullname, yelpID: yelpID, newsID: newsID, background: background, reduceAmount: promotedELO > 0 ? (promotedELO * -50) : nil) { success in
                                    if !background {
                                        handleCompletion(success: success)
                                    }
                                }
                                if background {
                                    leaveBackground()
                                } else {
                                    withAnimation(.easeInOut(duration: 0.3)){ uploaded = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                        withAnimation(.easeInOut(duration: 0.3)){ uploaded = false }
                                        uploadError = "Action took too long"
                                    }
                                }
                            } else { purchaseFailed = true }
                        } catch { purchaseFailed = true }
                    } else { purchaseFailed = true }
                }
            } else {
                popRoot.uploadTweet(withCaption: caption, withPro: promotedELO > 0 ? promotedELO : kingPro, userPhoto: user.profileImageUrl ?? "", username: user.username, videoLink: videoLink, content: uploadCont, userVeri: user.verified, audioURL: recorder.recordings.first?.fileURL, sloc: smallLoc, bloc: place?.country, lat: place?.lat, long: place?.long, choice1: choice1, choice2: choice2, choice3: choice3, choice4: choice4, fullname: user.fullname, yelpID: yelpID, newsID: newsID, background: background, reduceAmount: promotedELO > 0 ? (promotedELO * -50) : nil) { success in
                    if !background {
                        handleCompletion(success: success)
                    }
                }
                if background {
                    leaveBackground()
                } else {
                    withAnimation(.easeInOut(duration: 0.3)){ uploaded = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                        withAnimation(.easeInOut(duration: 0.3)){ uploaded = false }
                        uploadError = "Action took too long"
                    }
                }
            }
        } else { uploadError = "An error occured, try again later." }
    }
    func visibileView() -> some View {
        VStack(alignment: .leading, spacing: 15){
            Text("Who can view?").font(.title).bold()
            Text("Pick a community to view this post, or anyone will be able to view this post.").foregroundStyle(.gray).font(.subheadline)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20){
                    Button {
                        showVisibleSheet = false
                        visibility = ""
                        visibilityImage = ""
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 18){
                            ZStack {
                                Circle().foregroundStyle(.blue)
                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                Image(systemName: "globe").font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 40, height: 40)
                            .overlay(alignment: .bottomTrailing){
                                if visibility.isEmpty {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .padding(3)
                                        .background(.green)
                                        .clipShape(Circle())
                                        .padding(2)
                                        .background(.white)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: 8)
                                }
                            }
                            Text("Everyone").font(.headline).foregroundStyle(colorScheme == .dark ? .white : .black)
                            Spacer()
                        }
                    }
                    Button(action: {
                        showVisibleSheet = false
                        visibility = "ChatGPT"
                        visibilityImage = "https://cdn.pixabay.com/photo/2016/05/05/02/37/sunset-1373171_1280.jpg"
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label: {
                        commRow(image: "https://cdn.pixabay.com/photo/2016/05/05/02/37/sunset-1373171_1280.jpg", name: "ChatGPT")
                    })
                    Button(action: {
                        
                    }, label: {
                        commRow(image: "https://letsenhance.io/static/8f5e523ee6b2479e26ecc91b9c25261e/1015f/MainAfter.jpg", name: "Red Bull Racing")
                    })
                    Button(action: {
                        
                    }, label: {
                        commRow(image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLzOsXAGnBHRlP3m5OClYHGLxQHkqyJQGVI3Vxk3d6aA&s", name: "Call of Duty Moden")
                    })
                }
                .padding(.top, 8)
                .padding(.leading, 10)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, 25)
        .padding(.horizontal)
    }
    func commRow(image: String, name: String) -> some View {
        HStack(spacing: 18){
            KFImage(URL(string: image))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                .overlay(alignment: .bottomTrailing){
                    if visibility == name {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(.green)
                            .clipShape(Circle())
                            .padding(2)
                            .background(.white)
                            .clipShape(Circle())
                            .offset(x: 8, y: 8)
                    }
                }
            Text(name).font(.headline).foregroundStyle(colorScheme == .dark ? .white : .black)
            Spacer()
        }
    }
    func stockPicker() -> some View {
        ScrollView {
            LazyVStack(spacing: 10){
                ForEach(0..<matchedStocks.count, id: \.self){ i in
                    Button {
                        replaceStock(new: matchedStocks[i])
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.up.and.down.and.sparkles").font(.headline).foregroundStyle(.green)
                            Text(matchedStocks[i].uppercased()).font(.headline).bold()
                            Spacer()
                            Text("stock").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                        }.padding(.leading, 5).padding(.trailing, 12).frame(height: 40).padding(.top, 5)
                    }
                    Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray).padding(.leading, 55)
                }
            }.padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .frame(height: matchedStocks.count > 3 ? 160.0 : (CGFloat(matchedStocks.count) * 50.0))
        .background(colorScheme == .dark ? Color(red: 66 / 255.0, green: 69 / 255.0, blue: 73 / 255.0) : Color(UIColor.lightGray))
        .animation(.easeOut, value: matchedStocks)
    }
    func hashtagPicker() -> some View {
        ScrollView {
            LazyVStack(spacing: 10){
                ForEach(0..<matchedHashtags.count, id: \.self){ i in
                    Button {
                        replaceHashtag(new: matchedHashtags[i])
                    } label: {
                        HStack(spacing: 10) {
                            Image("hashtag")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 25).scaleEffect(1.2)
                            Text(matchedHashtags[i]).font(.headline).bold()
                            Spacer()
                            Text("trending").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
                        }.padding(.leading, 5).padding(.trailing, 12).frame(height: 40).padding(.top, 5)
                    }
                    Divider().overlay(colorScheme == .dark ? Color.white.opacity(0.6) : .gray).padding(.leading, 55)
                }
            }.padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .frame(height: matchedHashtags.count > 3 ? 160.0 : (CGFloat(matchedHashtags.count) * 50.0))
        .background(colorScheme == .dark ? Color(red: 66 / 255.0, green: 69 / 255.0, blue: 73 / 255.0) : Color(UIColor.lightGray))
        .animation(.easeOut, value: matchedHashtags)
    }
    func replaceStock(new: String){
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        caption = replaceLastWord(originalString: caption, newWord: ("$" + new.uppercased()))
        matchedStocks = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            matchedStocks = []
        }
    }
    func replaceHashtag(new: String){
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        caption = replaceLastWord(originalString: caption, newWord: ("#" + new))
        matchedHashtags = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            matchedHashtags = []
        }
    }
    func getStock(){
        let temp = stockModel.coins.map { String($0.symbol) } + stockModel.companyData.map { String($0.1) }
        let possible = Array(Set(temp))
        
        if let last = caption.last, last == "$" {
            matchedStocks = possible
            return
        } else if let last = caption.last, last == " " {
            matchedStocks = []
        } else {
            let words = caption.components(separatedBy: " ")

            if var lastWord = words.last {
                if lastWord.hasPrefix("$") {
                    lastWord.removeFirst()
                    let query = lastWord.lowercased()
                    matchedStocks = possible.filter({ str in
                        str.lowercased().contains(query)
                    })
                } else {
                    matchedStocks = []
                }
            } else {
                matchedStocks = []
            }
        }
    }
    func getHashtag(){
        let temp = popRoot.trendingHashtags
        let possible = Array(Set(temp))
        
        if let last = caption.last, last == "#" {
            if possible.isEmpty && !fetchingTopHashtags {
                fetchingTopHashtags = true
                TweetService().fetchRecentHashtags { hashtags in
                    popRoot.trendingHashtags = hashtags
                    if let last = caption.last, last == "#" {
                        matchedHashtags = hashtags
                    }
                }
            } else {
                matchedHashtags = possible
            }
            return
        } else if let last = caption.last, last == " " {
            matchedHashtags = []
        } else {
            let words = caption.components(separatedBy: " ")

            if var lastWord = words.last {
                if lastWord.hasPrefix("#") {
                    lastWord.removeFirst()
                    let query = lastWord.lowercased()
                    matchedHashtags = possible.filter({ str in
                        str.lowercased().contains(query)
                    })
                } else {
                    matchedHashtags = []
                }
            } else {
                matchedHashtags = []
            }
        }
    }
    func locPickView() -> some View {
        ZStack {
            Rectangle().foregroundStyle(.ultraThickMaterial).ignoresSafeArea()
            VStack(spacing: 0){
                HStack {
                    Button(action: {
                        withAnimation {
                            selection = 0
                        }
                    }, label: {
                        HStack(spacing: 3){
                            Text("Current Location").foregroundStyle(colorScheme == .dark ? .white : .black)
                            Image(systemName: "mappin.and.ellipse").foregroundStyle(.gray)
                        }
                    })
                    Spacer()
                    Button(action: {
                        withAnimation {
                            selection = 1
                        }
                    }, label: {
                        HStack(spacing: 3){
                            Text("Input Location").foregroundStyle(colorScheme == .dark ? .white : .black)
                            Image(systemName: "globe").foregroundStyle(.gray)
                        }
                    })
                }.font(.system(size: 17)).bold().padding(.horizontal)
                ZStack {
                    Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray).padding(.top, 8)
                    HStack {
                        if selection == 1 {
                            Spacer()
                        }
                        Rectangle()
                            .frame(width: widthOrHeight(width: true) * 0.5, height: 3).foregroundStyle(.blue).offset(y: 3)
                            .animation(.easeInOut, value: selection)
                        if selection == 0 {
                            Spacer()
                        }
                    }
                }
                TabView(selection: $selection) {
                    VStack {
                        HStack(spacing: 50){
                            Spacer()
                            VStack {
                                Text("Latitude").font(.subheadline)
                                    .foregroundStyle(.gray)
                                Text(String(format: "%.2f", place?.lat ?? 0.0))
                                    .foregroundStyle(.white).font(.title3).bold()
                                    .padding().background(.gray).cornerRadius(15, corners: .allCorners)
                            }
                            VStack {
                                Text("Longitude").font(.subheadline)
                                    .foregroundStyle(.gray)
                                Text(String(format: "%.2f", place?.long ?? 0.0))
                                    .foregroundStyle(.white).font(.title3).bold()
                                    .padding().background(.gray).cornerRadius(15, corners: .allCorners)
                            }
                            Spacer()
                        }
                        
                        if fetchingLocation {
                            CirclesExpand()
                        } else if place != nil {
                            foundView()
                        } else {
                            locateView()
                        }
                        
                        Spacer()
                        
                        if place != nil {
                            Button {
                                fetchingLocation = true
                                manager.requestLocation() { place in
                                    if !place.0.isEmpty && !place.1.isEmpty && (place.2 != 0.0 || place.3 != 0.0){
                                        fetchingLocation = false
                                        self.place = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                                    }
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .foregroundStyle(.blue)
                                    Text("Relocate").font(.title3).bold().foregroundStyle(.white)
                                }.frame(width: 135, height: 40)
                            }.padding(.bottom, 30).disabled(fetchingLocation)
                        }
                    }.padding(.top, 60).tag(0)
                    VStack {
                        ZStack {
                            TextField("Find a place", text: $searchModel.searchQuery)
                                .tint(.blue)
                                .autocorrectionDisabled(true)
                                .padding(15)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 24)
                                .padding(.trailing, 14)
                                .background(Color(.systemGray4))
                                .cornerRadius(20)
                                .onChange(of: searchModel.searchQuery) { _, _ in
                                    searchModel.sortSearch()
                                }
                                .onReceive (
                                    searchModel.$searchQuery
                                        .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
                                ) {
                                    guard !$0.isEmpty else { return }
                                    searchModel.performSearch()
                                }
                                .overlay (
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.gray)
                                            .padding(.leading, 8)
                                        Spacer()
                                        if searchModel.searching {
                                            ProgressView().scaleEffect(1.25).padding(.trailing, 8)
                                        } else {
                                            Button(action: {
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                showLocPicker.toggle()
                                                searchModel.searchQuery = ""
                                            }, label: {
                                                ZStack {
                                                    Circle().frame(width: 40, height: 40).foregroundStyle(Color.black.opacity(0.7))
                                                    Image(systemName: "mappin.and.ellipse")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 23))
                                                }
                                            }).padding(.trailing, 8)
                                        }
                                    }
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, top_Inset())
                        .ignoresSafeArea()
                        
                        ScrollView {
                            VStack(spacing: 10){
                                ForEach(searchModel.searchResults){ element in
                                    Button(action: {
                                        if !element.city.isEmpty && !element.country.isEmpty && (element.latitude != 0.0 || element.longitude != 0.0) {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            fetchingLocation = false
                                            self.place = myLoc(country: element.country, state: "", city: element.city, lat: element.latitude, long: element.longitude)
                                            withAnimation(.easeIn(duration: 0.2)){
                                                selection = 0
                                            }
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }
                                    }, label: {
                                        HStack {
                                            Image(systemName: "globe")
                                                .font(.system(size: 20)).foregroundStyle(.blue)
                                            Text("\(element.city), \(element.country)").foregroundStyle(.white)
                                                .font(.system(size: 18))
                                            Spacer()
                                            Text("(\(String(format: "%.1f", element.latitude)), \(String(format: "%.1f", element.longitude)))").font(.caption2).foregroundStyle(.purple)
                                        }
                                    })
                                    if element.city != searchModel.searchResults.last?.city {
                                        Divider().overlay(Color(UIColor.lightGray))
                                    }
                                }
                            }.padding().padding(.horizontal, 5)
                        }.scrollIndicators(.hidden)
                    }
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }.padding(.top)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        searchModel.searchQuery = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeOut(duration: 0.2)){
                            showLocPicker = false
                        }
                    } label: {
                        Image(systemName: "xmark").font(.title2).padding(12).foregroundStyle(.white)
                            .background(.black).clipShape(Circle())
                    }.padding(30)
                }
            }
        }
    }
    func foundView() -> some View {
        ZStack {
            ForEach(2..<6) { index in
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .opacity(1.0 - CGFloat(index) * 0.1)
                    .frame(width: (120 + CGFloat(index) * CGFloat(index) * 7), height: (120 + CGFloat(index) * CGFloat(index) * 7))
            }
            VStack(spacing: 3){
                Image(systemName: "mappin.and.ellipse").bold()
                Text("\(place?.city ?? "---")").minimumScaleFactor(0.6).lineLimit(1).bold()
                if let state = place?.state, !state.isEmpty {
                    Text(state).minimumScaleFactor(0.6).lineLimit(1).bold()
                }
                Text("\(place?.country ?? "---")").minimumScaleFactor(0.6).lineLimit(1).bold()
            }.offset(y: -15).frame(maxWidth: 120)
        }.padding(.top, 50)
    }
    func locateView() -> some View {
        ZStack {
            ForEach(2..<6) { index in
                Circle()
                    .stroke(Color.gray, lineWidth: 3)
                    .opacity(1.0 - CGFloat(index) * 0.1)
                    .frame(width: (120 + CGFloat(index) * CGFloat(index) * 7), height: (120 + CGFloat(index) * CGFloat(index) * 7))
            }
            Button {
                fetchingLocation = true
                manager.requestLocation() { place in
                    if !place.0.isEmpty && !place.1.isEmpty && (place.2 != 0.0 || place.3 != 0.0){
                        fetchingLocation = false
                        self.place = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                    }
                }
            } label: {
                ZStack {
                    Circle().frame(width: 100, height: 100).foregroundStyle(.blue)
                    Text("Locate me").foregroundStyle(.white).font(.subheadline).bold()
                }
            }
        }.padding(.top, 50)
    }
    func audioView() -> some View {
        ZStack {
            VStack {
                ZStack {
                    HStack {
                        Button(action: {
                            withAnimation {
                                cancelRecording()
                            }
                            showAudioSheet = false
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label: {
                            Text("Cancel").font(.headline)
                                .foregroundStyle(colorScheme == .dark ? .white : .black).opacity(0.9)
                        })
                        Spacer()
                        if recorder.recordings.first != nil || recorder.recording {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if recorder.recording {
                                    withAnimation {
                                        pauseRecording()
                                    }
                                }
                                showAudioSheet = false
                            }, label: {
                                Text("Done")
                                    .font(.system(size: 15))
                                    .foregroundStyle(colorScheme == .dark ? .black : .white).bold()
                                    .padding(.horizontal, 13).padding(.vertical, 8)
                                    .background {
                                        Capsule().foregroundStyle(colorScheme == .dark ? .white : .black).opacity(0.7)
                                    }
                            })
                        }
                    }
                    if recorder.recordings.first != nil || recorder.recording {
                        HStack(spacing: 4){
                            Spacer()
                            Circle().frame(width: 10)
                                .foregroundStyle(recorder.recording ? .red : .gray)
                                .animation(.easeInOut, value: currentTimeR)
                                .opacity(recorder.recording ? (Int(currentTimeR) % 2 == 0 ? 1 : 0) : 1.0)
                            Text(recorder.recording ? "Recording" : "Paused")
                                .font(.system(size: 20)).bold()
                            Spacer()
                        }
                    }
                }
                VStack(spacing: 10){
                    ZStack {
                        Circle().foregroundColor(Color(UIColor.lightGray))
                            .opacity(colorScheme == .dark ? 1.0 : 0.6)
                        Circle().foregroundColor(.blue).opacity(0.1)
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(Color(UIColor.darkGray))
                            .opacity(0.8)
                        if let url = authViewModel.currentUser?.profileImageUrl {
                            KFImage(URL(string: url))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        }
                    }.frame(width: 120, height: 120).padding(.top, 90)
                    if currentTimeR > 0 {
                        Text(currentTimeR.description).font(.subheadline).foregroundStyle(.gray)
                    }
                }
                if !(recorder.recordings.first != nil || recorder.recording) {
                    VStack(spacing: 4){
                        Text("What's happening?").font(.headline).foregroundStyle(.gray)
                        Text("Hit record").font(.headline).foregroundStyle(.gray).opacity(0.7)
                    }.padding(.top, 65)
                }
                Spacer()
            }.padding()
            if recorder.recordings.first != nil || recorder.recording {
                VStack {
                    Spacer()
                    HStack(spacing: 2){
                        ForEach(recorder.soundSamples, id: \.self) { level in
                            BarView(isRecording: true, value: recorder.recording ? normalizeSoundLevel(level: Float(level.sample)) : 2.0, sample: nil)
                        }
                    }.offset(y: 60)
                    Spacer()
                }
            }
            VStack {
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if recorder.recording {
                        withAnimation {
                            pauseRecording()
                        }
                    } else {
                        if currentTimeR < 120 {
                            withAnimation {
                                startRecording()
                            }
                        } else {
                            audioTooLong = true
                        }
                    }
                }, label: {
                    ZStack {
                        if recorder.recording {
                            Circle().stroke(.purple, lineWidth: 2)
                            Image(systemName: "pause").foregroundStyle(.purple)
                                .font(.system(size: 30)).bold()
                        } else {
                            Circle().foregroundStyle(.purple)
                            Circle().stroke(.white, lineWidth: 3)
                                .frame(width: 70, height: 70)
                            Image(systemName: "mic.fill").foregroundStyle(.white)
                                .font(.system(size: 30)).scaleEffect(y: 0.8)
                        }
                    }
                })
                .frame(width: 80, height: 80)
                .alert("Recording has reached max length", isPresented: $audioTooLong) {
                    Button("Okay", role: .cancel) { }
                }
            }.padding(.bottom, 60)
        }
    }
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        var level = max(2.0, CGFloat(level) + 50)
        if level > 2.0 {
            level *= 1.1
        }
        return CGFloat(level)
    }
    private func startRecording() {
        recorder.recording = true
        recorder.startRecording()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            withAnimation {
                currentTimeR += 1
                if currentTimeR >= 120 {
                    pauseRecording()
                }
            }
        })
    }
    func cancelRecording() {
        recordingTimer?.invalidate()
        recorder.recording = false
        recorder.stopRecording()
    }
    func pauseRecording() {
        recordingTimer?.invalidate()
        recorder.stopRecording()
        recorder.recording = false
        guard let tempUrl = UserDefaults.standard.string(forKey: "tempUrl") else { return }
        if let url = URL(string: tempUrl) {
            let newRecording = Recording(fileURL: url)
            recorder.recordings.append(newRecording)
            Task {
                await recorder.mergeAudios()
            }
        }
    }
    func deleteRecording() {
        withAnimation(.easeInOut(duration: 0.2)){
            recorder.recordings = []
        }
        currentTimeR = 0
        recorder.recording = false
        recordingTimer?.invalidate()
        recorder.stopRecording()
    }
    func promoView() -> some View {
        VStack(spacing: 15){
            if let user = authViewModel.currentUser {
                if user.elo < 2900 {
                    promoteFilter
                    if selectedFilter == .USD {
                        PromoteUSD(selection: $promotedUSD)
                    }
                    if selectedFilter == .ELO {
                        PromoteELO(days: $promotedELO, userElo: authViewModel.currentUser?.elo ?? 0)
                    }
                } else {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10).frame(width: 120, height: 45).foregroundColor(Color(UIColor.lightGray))
                        Text("Auto Promoted").font(.system(size: 15)).foregroundColor(.black).bold()
                    }.shimmering()
                }
            } else {
                promoteFilter
                if selectedFilter == .USD {
                    PromoteUSD(selection: $promotedUSD)
                }
                if selectedFilter == .ELO {
                    PromoteELO(days: $promotedELO, userElo: authViewModel.currentUser?.elo ?? 0)
                }
            }
            Spacer()
        }.padding(.top, 15)
    }
}

extension NewTweetView {
    var promoteFilter: some View {
        HStack{
            ForEach(PromoteViewModel.allCases, id: \.rawValue){ item in
                if let user = authViewModel.currentUser {
                    if item.title != "Promote ElO" || (item.title == "Promote ElO" && user.elo >= 850){
                        VStack{
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(selectedFilter == item ? .semibold: .regular)
                                .foregroundColor(selectedFilter == item ? colorScheme == .dark ? .white : .black : .gray)
                            
                            if selectedFilter == item{
                                Capsule()
                                    .foregroundColor(Color(.systemBlue))
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "filter", in: animation)
                            } else {
                                Capsule()
                                    .foregroundColor(Color(.clear))
                                    .frame(height: 3)
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut){
                                self.selectedFilter = item
                            }
                        }
                    }
                } else {
                    VStack {
                        Text(item.title)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == item ? .semibold: .regular)
                            .foregroundColor(selectedFilter == item ? colorScheme == .dark ? .white : .black : .gray)
                        
                        if selectedFilter == item{
                            Capsule()
                                .foregroundColor(Color(.systemBlue))
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "filter", in: animation)
                        } else {
                            Capsule()
                                .foregroundColor(Color(.clear))
                                .frame(height: 3)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut){
                            self.selectedFilter = item
                        }
                    }
                }

            }
        }
        .overlay(Divider().offset(x:0, y:16))
    }
}

struct CustomVideoField: View{
    let place: String
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    var body: some View{
        ZStack(alignment: .leading){
            if text.isEmpty {
                Text(place)
                    .opacity(0.5).offset(x: 15).foregroundColor(colorScheme == .dark ? .black : .white).font(.system(size: 17))
            }
            TextField("", text: $text, axis: .vertical)
                .tint(.blue)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .lineLimit(5).padding(.horizontal)
        }
    }
}

struct BasicAiButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showFixText: Bool
    @Binding var caption: String
    @Binding var showAI: Bool
    @Binding var dismissAI: Bool
    @Binding var showAlert: Int
    let viewOption: Bool
    
    var body: some View {
        ZStack {
            if viewOption {
                Button {
                    if caption.count > 15 {
                        showFixText = true
                        withAnimation(.easeInOut(duration: 0.15)){
                            showAI = false
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)){
                            showAlert = 2
                        }
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    VStack(spacing: 2){
                        ZStack {
                            Circle().foregroundStyle(.gray).opacity(0.001)
                            LottieView(loopMode: .loop, name: "finite")
                                .scaleEffect(0.04)
                                .frame(width: 22, height: 10)
                                .rotationEffect(.degrees(90.0))
                        }.frame(width: 30, height: 30)
                        Text("AI").font(.caption2).foregroundStyle(.blue)
                    }
                }
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.15)){
                        showAI = false
                    }
                    showFixText = true
                } label: {
                    HStack {
                        LottieView(loopMode: .loop, name: "finite")
                            .scaleEffect(0.05)
                            .frame(width: 25, height: 10)
                        Text("Improve caption with Hustles AI.")
                            .font(.system(size: 15)).bold()
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)){
                                showAI = false
                                dismissAI = true
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline).foregroundStyle(.blue)
                                .frame(width: 25, height: 10)
                        }
                    }
                    .padding(8)
                    .background(.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.blue, lineWidth: 1.0)
                    }
                }
            }
        }
        .sheet(isPresented: $showFixText, content: {
            RecommendTextView(oldText: $caption)
        })
    }
}

func extractHashtags(from text: String) -> [String] {
    let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
    var hashtags: [String] = []
    
    for word in words {
        if word.hasPrefix("#") {
            let hashtag = word.dropFirst()
            if hashtag.range(of: "^[a-zA-Z0-9]+$", options: .regularExpression) != nil {
                if hashtag.count < 30 {
                    hashtags.append(String(hashtag).lowercased())
                }
            }
        }
    }
    
    return hashtags
}
