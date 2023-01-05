import SwiftUI
import Kingfisher
import Firebase
import AVFoundation

struct TweetRowView: View {
    @StateObject var viewModel = TweetRowViewModel()
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var feed: FeedViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var exploreModel: ExploreViewModel
    @Environment(\.colorScheme) var colorScheme
    @Namespace var animation
    @State var dateFinal: String = ""
    @State private var showComments: Bool = false
    @State private var showEditAd: Bool = false
    @State private var showPost: Bool = false
    @State var initialContent: uploadContent? = nil
    @State var place: myLoc? = nil
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State var currentLoc: myLoc? = nil
    @State var selectedAsset: String? = nil
    @State var showOptions: Bool = false
    @State private var blockUser = false
    @State private var showForward = false
    @State var sendLink: String = ""
    @State private var showViewSheet = false
    @State var saved = false
    @State var liked = false
    @State private var selectionNew = 0
    @State var adStatus: String = ""
    @State var tempSheetUser: String? = nil
    @State var ad: Bool = false
    @State var showProfileSheet: Bool = false
    
    let tweet: Tweet
    let edit: Bool
    let canShow: Bool
    let canSeeComments: Bool
    let map: Bool
    @Binding var currentAudio: String
    @Binding var isExpanded: Bool
    let animationT: Namespace.ID
    let seenAllStories: Bool
    let isMain: Bool
    @Binding var showSheet: Bool
    let newsAnimation: Namespace.ID
    @State var tabID: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: 10){
            ZStack {
                if let tid = tweet.id, isMain && hasStories() {
                    StoryRingView(size: 45.0, active: seenAllStories, strokeSize: 1.8)
                        .scaleEffect(1.24)
                    
                    let mid = tid + "UpStory" + (tabID ?? "")
                    let size = isExpanded && profile.mid == mid ? 200.0 : 45.0
                    GeometryReader { _ in
                        profileSlide(size: size)
                            .opacity(isExpanded && profile.mid == mid ? 0.0 : 1.0)
                    }
                    .matchedGeometryEffect(id: mid, in: animationT, anchor: .topLeading)
                    .frame(width: 45.0, height: 45.0)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if map {
                            showSheet = false
                        }
                        setupStory()
                        profile.mid = mid
                        withAnimation(.easeInOut(duration: 0.15)){
                            popRoot.hideTabBar = true
                            isExpanded = true
                        }
                    }
                } else if canShow {
                    NavigationLink {
                        ProfileView(showSettings: false, showMessaging: true, uid: tweet.uid, photo: tweet.profilephoto ?? "", user: nil, expand: true, isMain: false)
                            .dynamicTypeSize(.large)
                    } label: {
                        profileSlide(size: 45.0)
                    }
                } else {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showProfileSheet = true
                    } label: {
                        profileSlide(size: 45.0)
                    }
                }
            }

            VStack(spacing: 3){
                HStack(spacing: 4){
                    if canShow {
                        NavigationLink {
                            ProfileView(showSettings: false, showMessaging: true, uid: tweet.uid, photo: tweet.profilephoto ?? "", user: nil, expand: true, isMain: false)
                                .dynamicTypeSize(.large)
                        } label: {
                            Text(tweet.fullname ?? tweet.username).font(.system(size: 19)).bold()
                        }
                    } else {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showProfileSheet = true
                        } label: {
                            Text(tweet.fullname ?? tweet.username).font(.system(size: 19)).bold()
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                    }
                    if tweet.veriUser ?? false || ad {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.blue)
                            .font(.system(size: 16))
                    }
                    if canShow {
                        NavigationLink {
                            ProfileView(showSettings: false, showMessaging: true, uid: tweet.uid, photo: tweet.profilephoto ?? "", user: nil, expand: true, isMain: false)
                                .dynamicTypeSize(.large)
                        } label: {
                            Text("\(dateFinal) - @\(tweet.username)").font(.system(size: 16))
                                .lineLimit(1).minimumScaleFactor(0.8).truncationMode(.tail)
                                .foregroundStyle(.gray)
                        }
                    } else {
                        Text("\(dateFinal) - @\(tweet.username)").font(.system(size: 16))
                            .lineLimit(1).minimumScaleFactor(0.8).truncationMode(.tail)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    menuTweet()
                }
                
                if let city = tweet.sLoc, let country = tweet.bLoc, let long = tweet.long, let lat = tweet.lat {
                    if map {
                        HStack(spacing: 8){
                            Image(systemName: "mappin.and.ellipse")
                            Text("\(city), \(country)")
                            Spacer()
                        }.font(.subheadline).foregroundStyle(.blue).padding(.vertical, 3)
                    } else {
                        NavigationLink {
                            MapFeedView(loc: $currentLoc)
                        } label: {
                            HStack(spacing: 8){
                                Image(systemName: "mappin.and.ellipse")
                                Text("\(city), \(country)")
                                Spacer()
                            }.font(.subheadline).foregroundStyle(.blue).padding(.vertical, 3)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            if !city.isEmpty {
                                feed.fetchLocation(city: city, country: country)
                            }
                            popRoot.tempCurrentAudio = popRoot.currentAudio
                            popRoot.currentAudio = ""
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            currentLoc = myLoc(country: country, state: "", city: city, lat: lat, long: long)
                        })
                    }
                }
                
                if !tweet.caption.isEmpty {
//                    HustleInlineLink(tweet.caption)
//                        .font(.body)
//                        .multilineTextAlignment(.leading)
                    
                    Text(tweet.caption)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }

//                if let all = tweet.contentArray, !all.isEmpty {
//                    TabView(selection: $selectionNew) {
//                        ForEach(Array(all.enumerated()), id: \.offset) { index, content in
//                            if content.contains("hustlesImages") {
//                                KFImage(URL(string: content))
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                                    .tag(index)
//                                    .frame(height: 400)
//                                    .clipShape(RoundedRectangle(cornerRadius: 15))
//                                    .contentShape(RoundedRectangle(cornerRadius: 15))
//                                    .overlay(content: {
//                                        RoundedRectangle(cornerRadius: 15)
//                                            .stroke(Color.gray.opacity(0.6), lineWidth: 1.0)
//                                    })
//                                    .contextMenu {
//                                        Button(action: {
//                                            initialContent = uploadContent(isImage: true, imageURL: content)
//                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                            showPost = true
//                                        }, label: {
//                                            Label(
//                                                title: { Text("Post Photo") },
//                                                icon: { Image(systemName: "photo") }
//                                            )
//                                        })
//                                        Button(action: {
//                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                            downloadAndSaveImage(url: content)
//                                        }, label: {
//                                            Label(
//                                                title: { Text("Download Image") },
//                                                icon: { Image(systemName: "square.and.arrow.down") }
//                                            )
//                                        })
//                                        Button(action: {
//                                            popRoot.alertImage = "link"
//                                            popRoot.alertReason = "Link Copied"
//                                            withAnimation {
//                                                popRoot.showAlert = true
//                                            }
//                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                            UIPasteboard.general.string = content
//                                        }, label: {
//                                            Label(
//                                                title: { Text("Copy Link") },
//                                                icon: { Image(systemName: "link") }
//                                            )
//                                        })
//                                    } preview: {
//                                        KFImage(URL(string: content)).resizable()
//                                    }
//                                    .padding(.vertical, 4).padding(.horizontal, 1)
//                            } else if let url = URL(string: content) {
//                                MessageVideoPlayerNoFrameWidth(url: url, height: 400.0, cornerRadius: 15.0, viewID: tweet.id ?? "", currentAudio: $currentAudio)
//                                    .tag(index)
//                                    .contextMenu {
//                                        Button(action: {
//                                            initialContent = uploadContent(isImage: false, videoURL: url)
//                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                            showPost = true
//                                        }, label: {
//                                            Label(
//                                                title: { Text("Post Video") },
//                                                icon: { Image(systemName: "video") }
//                                            )
//                                        })
//                                        Button(action: {
//                                            popRoot.alertImage = "square.and.arrow.down.fill"
//                                            popRoot.alertReason = "Video Saved"
//                                            withAnimation {
//                                                popRoot.showAlert = true
//                                            }
//                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                            saveVideoToCameraRoll(urlStr: url.absoluteString)
//                                        }, label: {
//                                            Label(
//                                                title: { Text("Download Video") },
//                                                icon: { Image(systemName: "square.and.arrow.down") }
//                                            )
//                                        })
//                                        Button(action: {
//                                            popRoot.alertImage = "link"
//                                            popRoot.alertReason = "Video Link Copied"
//                                            withAnimation {
//                                                popRoot.showAlert = true
//                                            }
//                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                            UIPasteboard.general.string = url.absoluteString
//                                        }, label: {
//                                            Label(
//                                                title: { Text("Copy Link") },
//                                                icon: { Image(systemName: "link") }
//                                            )
//                                        })
//                                    }
//                                    .padding(.vertical, 4)
//                                    .padding(.horizontal, 1)
//                            }
//                        }
//                    }
//                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//                    .frame(height: 410)
//                    .overlay(alignment: .bottom){
//                        if all.count > 1 {
//                            HStack(spacing: 4){
//                                ForEach(Array(all.enumerated()), id: \.offset) { index, _ in
//                                    Circle().frame(width: 6, height: 6)
//                                        .foregroundStyle(index == selectionNew ? .white : .gray)
//                                }
//                            }
//                            .padding(10)
//                            .background {
//                                TransparentBlurView(removeAllFilters: true)
//                                    .blur(radius: 7, opaque: true)
//                                    .background(.gray.opacity(0.6))
//                            }
//                            .clipShape(Capsule())
//                            .padding(.bottom)
//                        }
//                    }
//                    .onChange(of: selectionNew) { _, new in
//                        if let id = tweet.id, new < all.count {
//                            feed.firstVideo[id] = all[new]
//                        }
//                    }
//                } else if let tweetAudio = tweet.audioURL, let url = URL(string: tweetAudio) {
//                    VoiceStreamView(audioUrl: url, currentAudio: $currentAudio, hustleID: tweet.id ?? "")
//                        .contextMenu {
//                            Button(action: {
//                                // add initial content
//                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                showPost = true
//                            }, label: {
//                                Label (
//                                    title: { Text("Post Audio") },
//                                    icon: { Image(systemName: "speaker.plus") }
//                                )
//                            })
//                            Button(action: {
//                                popRoot.alertImage = "square.and.arrow.down.fill"
//                                popRoot.alertReason = "Audio Saved"
//                                withAnimation {
//                                    popRoot.showAlert = true
//                                }
//                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                downloadAudio(from: url)
//                            }, label: {
//                                Label(
//                                    title: { Text("Download Audio") },
//                                    icon: { Image(systemName: "square.and.arrow.down") }
//                                )
//                            })
//                            Button(action: {
//                                popRoot.alertImage = "link"
//                                popRoot.alertReason = "Audio Link Copied"
//                                withAnimation {
//                                    popRoot.showAlert = true
//                                }
//                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                UIPasteboard.general.string = url.absoluteString
//                            }, label: {
//                                Label(
//                                    title: { Text("Copy Link") },
//                                    icon: { Image(systemName: "link") }
//                                )
//                            })
//                        }
//                } else if let link = tweet.video {
//                    if !link.contains(".") && !link.contains("https://") && !link.contains("com") && link.contains("shorts"){
//                        YouTubeView(link: link, short: true).scaledToFill().frame(maxHeight: 350)
//                    } else if !link.contains(".") && !link.contains("https://") && !link.contains("com"){
//                        YouTubeView(link: link, short: false)
//                            .scaledToFit().frame(height: 250).padding(.top, 5)
//                    } else {
//                        WebVideoView(link: link)
//                            .padding(.vertical, 8)
//                            .offset(x: 5)
//                            .frame(width: widthOrHeight(width: true) * 0.88, height: widthOrHeight(width: false) * 0.23)
//                    }
//                }
//                
//                if let place = tweet.yelpID, !place.isEmpty {
//                    HStack {
//                        YelpRowView(placeID: place, isChat: false, isGroup: false, otherPhoto: nil).padding(.top, 10)
//                        Spacer()
//                    }
//                }
//                if let newsID = tweet.newsID, !newsID.isEmpty {
//                    HStack {
//                        if let news = exploreModel.news.first(where: { $0.id == newsID }) {
//                            if popRoot.tab == 1 && !map && isMain {
//                                let mid = (news.id ?? "") + (tweet.id ?? "NA") + "feedRow" + (tabID ?? "")
//                                
//                                if !popRoot.isNewsExpanded || popRoot.newsMid != mid {
//                                    NewsRowView(news: news, isRow: true)
//                                        .matchedGeometryEffect(id: mid, in: newsAnimation)
//                                        .onTapGesture(perform: {
//                                            popRoot.selectedNewsID = news.id ?? "NANID"
//                                            popRoot.newsMid = mid
//                                            withAnimation(.easeInOut(duration: 0.25)){
//                                                popRoot.isNewsExpanded = true
//                                            }
//                                        })
//                                } else {
//                                    NewsRowView(news: news, isRow: true).opacity(0.0).disabled(true)
//                                }
//                            } else {
//                                NavigationLink {
//                                    TopNewsView(animation: newsAnimation, newsMid: news.id ?? "NANID", animate: false, news: news)
//                                } label: {
//                                    NewsRowView(news: news, isRow: true)
//                                }
//                            }
//                        } else {
//                            LoadingNews().shimmering()
//                                .onAppear {
//                                    if exploreModel.news.first(where: { $0.id == newsID }) == nil {
//                                        exploreModel.getSingleNews(id: newsID) { _ in }
//                                    }
//                                }
//                        }
//                        Spacer()
//                    }
//                }
//                
//                if let c1 = tweet.choice1, let c2 = tweet.choice2 {
//                    let c3 = tweet.choice3
//                    let c4 = tweet.choice4
//                    
//                    let count1 = tweet.count1 ?? 0
//                    let count2 = tweet.count2 ?? 0
//                    let count3 = tweet.count3 ?? 0
//                    let count4 = tweet.count4 ?? 0
//                    
//                    PollRowView(choice1: c1, choice2: c2, choice3: c3, choice4: c4, count1: count1, count2: count2, count3: count3, count4: count4, hustleID: tweet.id ?? "", whoVoted: tweet.voted ?? [], timestamp: tweet.timestamp)
//                        .contextMenu {
//                            Button(action: {
//                                // add initial content
//                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                showPost = true
//                            }, label: {
//                                Label(
//                                    title: { Text("Repost Poll") },
//                                    icon: { Image(systemName: "chart.line.uptrend.xyaxis") }
//                                )
//                            })
//                            Button(action: {
//                                popRoot.alertImage = "link"
//                                popRoot.alertReason = "Poll Link Copied"
//                                withAnimation {
//                                    popRoot.showAlert = true
//                                }
//                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                UIPasteboard.general.string = "https://hustle.page/post/\(tweet.id ?? "")/"
//                            }, label: {
//                                Label (
//                                    title: { Text("Copy Link") },
//                                    icon: { Image(systemName: "link") }
//                                )
//                            })
//                        }
//                        .padding(.top, 10)
//                }
//
//                if ad && tweet.tag != "" {
//                    HStack {
//                        Spacer()
//                        ZStack(alignment: .top){
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
//                            VStack{
//                                HStack{
//                                    VStack(spacing: 3){
//                                        HStack{
//                                            Text(tweet.tag ?? "").font(.headline).bold()
//                                            Spacer()
//                                        }
//                                        HStack(spacing: 0.5){
//                                            ForEach(1...5, id: \.self) { index in
//                                                if Double(index) <= (tweet.stars ?? 5) {
//                                                    Image(systemName: "star.fill")
//                                                        .resizable()
//                                                        .frame(width: 15, height: 15)
//                                                        .foregroundColor(.gray)
//                                                } else if Double(index - 1) < (tweet.stars ?? 5) {
//                                                    Image(systemName: "star.leadinghalf.filled")
//                                                        .resizable()
//                                                        .frame(width: 15, height: 15)
//                                                        .foregroundColor(.gray)
//                                                } else {
//                                                    Image(systemName: "star")
//                                                        .resizable()
//                                                        .frame(width: 15, height: 15)
//                                                        .foregroundColor(.gray)
//                                                }
//                                            }
//                                            Text("Rated \(String(format: "%.1f", (tweet.stars ?? 5.0))) of 5")
//                                                .foregroundColor(.gray).font(.subheadline).padding(.leading)
//                                            Spacer()
//                                        }
//                                    }
//                                    Spacer()
//                                }
//                                HStack{
//                                    Spacer()
//                                    Button {
//                                        if let url = URL(string: "itms-apps://apps.apple.com/app/id\(tweet.appIdentifier ?? "")") {
//                                            UIApplication.shared.open(url)
//                                        }
//                                    } label: {
//                                        ZStack(alignment: .center){
//                                            RoundedRectangle(cornerRadius: 10)
//                                                .frame(width: 180, height: 24)
//                                                .foregroundColor(.blue)
//                                            Text("Download")
//                                                .bold()
//                                                .foregroundColor(.white)
//                                                .font(.subheadline)
//                                        }
//                                    }
//                                    Spacer()
//                                }
//                            }
//                            .padding(.leading, 6)
//                            .padding(.vertical, 3)
//                        }
//                        .padding(.top, 3)
//                        .frame(width: 270, height: 60)
//                        Spacer()
//                    }.padding(.vertical, 10)
//                }
//                
//                let allStocks = extractWordsStartingWithDollar(input: tweet.caption)
//                if !allStocks.isEmpty {
//                    HStack {
//                        cards(cards: allStocks, left: true)
//                        Spacer()
//                    }.padding(.bottom, 5)
//                }
                
//                HStack {
//                    Button(action: {
//                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                        showComments = true
//                    }, label: {
//                        HStack(spacing: 6){
//                            Image(systemName: "message")
//                            Text("\(tweet.comments ?? 0)")
//                        }.foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray)).font(.subheadline)
//                    }).disabled(!canSeeComments)
//                    Spacer()
//                    
//                    let status = auth.currentUser?.likedHustles.contains(tweet.id ?? "") ?? false
//                    HStack(spacing: 6){
//                        CustomButton(systemImage: "circle.fill", status: status, activeTint: .red, inActiveTint: colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray)) {
//                            liked.toggle()
//                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//                            
//                            if auth.currentUser?.likedHustles.contains(tweet.id ?? "") ?? false {
//                                viewModel.unlikeTweet(tweet: tweet)
//                                auth.currentUser?.likedHustles.removeAll(where: { $0 == tweet.id ?? "" })
//                            } else {
//                                viewModel.likeTweet(tweet: tweet)
//                                if let tweetId = tweet.id {
//                                    auth.currentUser?.likedHustles.append(tweetId)
//                                }
//                            }
//                        }
//                        
//                        let count = tweet.likes?.count ?? 0
//                        let array = tweet.likes ?? []
//                        let didLike = auth.currentUser?.likedHustles.contains(tweet.id ?? "") ?? false
//                        let finalArr: [String] = didLike ? (array + [auth.currentUser?.id ?? ""]) : array
//                        NavigationLink {
//                            LikedView(likes: finalArr, tid: tweet.id ?? "")
//                        } label: {
//                            Text("\(status ? count + 1 : count)")
//                                .foregroundColor(status ? .red : colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray)).font(.subheadline)
//                        }
//                    }
//
//                    Spacer()
//                    Button(action: {
//                        showViewSheet = true
//                    }, label: {
//                        HStack(spacing: 3){
//                            Image(systemName: "chart.bar")
//                            Text("\(tweet.views ?? 0)")
//                        }.foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray)).font(.subheadline)
//                    })
//                    Spacer()
//                    Button {
//                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                        if let id = tweet.id {
//                            sendLink = "https://hustle.page/post/\(id)/"
//                            showForward = true
//                        }
//                    } label: {
//                        HStack(spacing: 3){
//                            Image(systemName: "arrowshape.turn.up.right")
//                            Text("51k")
//                        }.foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray)).font(.subheadline)
//                    }
//                    Spacer()
//                    let r_saved = (auth.currentUser?.savedPosts ?? []).contains(tweet.id ?? "NA")
//                    Button {
//                        if r_saved {
//                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                            auth.currentUser?.savedPosts?.removeAll(where: { $0 == (tweet.id ?? "") })
//                            UserService().removePostSave(id: tweet.id)
//                            
//                            popRoot.alertImage = "bookmark.slash.fill"
//                            popRoot.alertReason = "Post removed from your Bookmarks"
//                            withAnimation {
//                                popRoot.showAlert = true
//                            }
//                        } else {
//                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
//                            auth.currentUser?.savedPosts = (auth.currentUser?.savedPosts ?? []) + [(tweet.id ?? "")]
//                            UserService().addPostSave(id: tweet.id)
//                            
//                            popRoot.alertImage = "bookmark.fill"
//                            popRoot.alertReason = "Post added to your Bookmarks"
//                            withAnimation {
//                                popRoot.showAlert = true
//                            }
//                            if let first = tweet.contentArray?.first(where: { $0.contains("hustlesImages") }) {
//                                popRoot.saveImageAnim = first
//                            }
//                        }
//                        saved.toggle()
//                    } label: {
//                        Label("", systemImage: r_saved ? "bookmark.fill" : "bookmark")
//                            .foregroundStyle(r_saved ? .blue : colorScheme == .dark ? Color(UIColor.lightGray) : Color(UIColor.darkGray))
//                    }
//                    .symbolEffect(.bounce, value: saved)
//                    Spacer()
//                    if let dateTo = tweet.promoted, dateTo.dateValue() > Date() {
//                        Text("Promoted").font(.caption).foregroundStyle(.white)
//                            .padding(4).bold()
//                            .background(Color.orange.gradient)
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                    }
//                }.padding(.top, 8)
            }
        }
        .onAppear(perform: {
//            let date = tweet.timestamp.dateValue()
//
//            if Calendar.current.isDateInToday(date){
//                dateFinal = tweet.timestamp.dateValue().formatted(.dateTime.hour().minute())
//            } else if Calendar.current.isDateInYesterday(date) {
//                dateFinal = "Yesterday"
//            } else if let dayBetween  = Calendar.current.dateComponents([.day], from: tweet.timestamp.dateValue(), to: Date()).day {
//                dateFinal = String(dayBetween + 1) + "d"
//            }
        })
        .alert("Block or Report this User", isPresented: $blockUser) {
            Button("Block", role: .destructive) {
                let uid = tweet.uid
                if auth.currentUser?.blockedUsers == nil {
                    auth.currentUser?.blockedUsers = []
                }
                auth.currentUser?.blockedUsers?.append(uid)
                UserService().blockUser(uid: uid)
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showProfileSheet, content: {
            ProfileSheetView(uid: tweet.uid, photo: "", user: nil, username: $tempSheetUser)
        })
        .fullScreenCover(isPresented: $showPost, content: {
            NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent)
                .onDisappear {
                    place = nil
                }
        })
        .fullScreenCover(isPresented: $showEditAd, content: {
            EditAdView(tweet: tweet).dynamicTypeSize(.large)
        })
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .sheet(isPresented: $showViewSheet, content: {
            VStack(alignment: .leading, spacing: 20){
                Text("Views").font(.title).bold()
                Text("Times this post has been seen.").font(.subheadline).foregroundStyle(.gray)
                Button {
                    showViewSheet = false
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(.gray, lineWidth: 1).frame(height: 35)
                        Text("Dismiss").font(.headline)
                    }
                }
                Spacer()
            }
            .padding().padding(.top, 10).padding(.leading, 8)
            .presentationCornerRadius(40.0)
            .presentationDetents([.height(200.0)])
        })
        .sheet(isPresented: $showComments, content: {
            CommentView(tweet: tweet, canShowProfile: canShow)
                .presentationDetents((tweet.comments ?? 0 > 5) ? [.large] : [.medium, .large])
                .presentationCornerRadius(40)
        })
        .alert("Are you sure you want to delete this post", isPresented: $showOptions) {
            Button("Delete", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.deleteHustle(tweet: tweet)
                popRoot.show = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .background {
            HStack {
                Color.yellow.opacity(0.001)
                    .frame(width: 50)
                    .onTapGesture(count: 1){
                        if canSeeComments {
                            showComments = true
                        }
                    }
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contextMenu {
            if tweet.uid == (auth.currentUser?.id ?? "Not") {
                Button(action: {
                    showOptions = true
                }, label: {
                    Label(
                        title: { Text("Delete") },
                        icon: { Image(systemName: "trash") }
                    )
                })
            }
            if let id = auth.currentUser?.dev, id.contains("(DWK@)2))&DNWIDN:") {
                Button("User ID", role: .destructive) {
                    UIPasteboard.general.string = tweet.uid
                }
                Button("Hustle ID", role: .destructive) {
                    UIPasteboard.general.string = tweet.id ?? ""
                }
                Button("Delete", role: .destructive) {
                    viewModel.deleteHustle(tweet: tweet)
                }
                Button("verify", role: .destructive) {
                    viewModel.verify(good: true, elo: auth.currentUser?.elo, tweet: tweet)
                }
                Button("!verify", role: .destructive) {
                    viewModel.verify(good: false, elo: auth.currentUser?.elo, tweet: tweet)
                }
            }
            Button {
                let uid = tweet.uid
                if let following = auth.currentUser?.following {
                    if following.contains(uid){
                        popRoot.alertImage = "person.fill.badge.minus"
                        popRoot.alertReason = "Unfollowed @\(tweet.username)"
                        withAnimation {
                            popRoot.showAlert = true
                        }
                        profile.unfollow(withUid: uid)
                        auth.currentUser?.following.removeAll(where: { $0 == uid })
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else {
                        popRoot.alertImage = "person.fill.badge.plus"
                        popRoot.alertReason = "Followed @\(tweet.username)"
                        withAnimation {
                            popRoot.showAlert = true
                        }
                        profile.follow(withUid: uid)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        auth.currentUser?.following.append(uid)
                        if !profile.startedFollowing.contains(uid) {
                            profile.startedFollowing.append(uid)
                            if let myUID = auth.currentUser?.id, let name = auth.currentUser?.fullname {
                                profile.sendNotif(taggerName: name, taggerUID: myUID, taggedUID: uid)
                            }
                        }
                    }
                }
            } label: {
                let following = auth.currentUser?.following ?? []
                if following.contains(tweet.uid) {
                    Label(
                        title: { Text("Unfollow @\(tweet.username)") },
                        icon: { Image(systemName: "person.badge.minus") }
                    )
                } else {
                    Label(
                        title: { Text("Follow @\(tweet.username)") },
                        icon: { Image(systemName: "person.badge.plus") }
                    )
                }
            }
            Button(action: {
                if let id = tweet.id {
                    popRoot.alertReason = "Post URL copied"
                    popRoot.alertImage = "link"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                    UIPasteboard.general.string = "https://hustle.page/post/\(id)/"
                }
            }, label: {
                Label (
                    title: { Text("Copy Link") },
                    icon: { Image(systemName: "link") }
                )
            })
            Button(action: {
                blockUser = true
            }, label: {
                Label(
                    title: { Text("Block @\(tweet.username)") },
                    icon: { Image(systemName: "person.badge.minus") }
                )
            })
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                UIPasteboard.general.string = tweet.caption
            }, label: {
                Label(
                    title: { Text("Copy Text") },
                    icon: { Image(systemName: "link") }
                )
            })
            Button(action: {
                popRoot.alertImage = "flag.fill"
                popRoot.alertReason = "Post Reported"
                withAnimation {
                    popRoot.showAlert = true
                }
                if let id = tweet.id {
                    UserService().reportContent(type: "hustle", postID: id)
                }
            }, label: {
                Label(
                    title: { Text("Report Post") },
                    icon: { Image(systemName: "flag") }
                )
            })
            if edit {
                Button {
                    showEditAd.toggle()
                } label: {
                    Label(
                        title: { Text("Edit") },
                        icon: { Image(systemName: "slider.horizontal.3") }
                    )
                }
            }
        }
    }
    func hasStories() -> Bool {
        let uid = tweet.uid
        return !(profile.users.first(where: { $0.user.id == uid })?.stories ?? []).isEmpty
    }
    func setupStory() {
        let uid = tweet.uid
        if let stories = profile.users.first(where: { $0.user.id == uid })?.stories {
            profile.selectedStories = stories
        }
    }
    func menuTweet() -> some View {
        Menu {
            Button {
                let uid = tweet.uid
                if let following = auth.currentUser?.following {
                    if following.contains(uid){
                        profile.unfollow(withUid: uid)
                        auth.currentUser?.following.removeAll(where: { $0 == uid })
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else {
                        profile.follow(withUid: uid)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        auth.currentUser?.following.append(uid)
                        if !profile.startedFollowing.contains(uid) {
                            profile.startedFollowing.append(uid)
                            if let myUID = auth.currentUser?.id, let name = auth.currentUser?.fullname {
                                profile.sendNotif(taggerName: name, taggerUID: myUID, taggedUID: uid)
                            }
                        }
                    }
                }
            } label: {
                let following = auth.currentUser?.following ?? []
                if following.contains(tweet.uid) {
                    Label(
                        title: { Text("Unfollow @\(tweet.username)") },
                        icon: { Image(systemName: "person.badge.minus") }
                    )
                } else {
                    Label(
                        title: { Text("Follow @\(tweet.username)") },
                        icon: { Image(systemName: "person.badge.plus") }
                    )
                }
            }
            Button(action: {
                if let id = tweet.id {
                    sendLink = "https://hustle.page/post/\(id)/"
                    showForward = true
                }
            }, label: {
                Label (
                    title: { Text("Share") },
                    icon: { Image(systemName: "paperplane.fill") }
                )
            })
            Button(action: {
                if let id = tweet.id {
                    popRoot.alertReason = "Post URL copied"
                    popRoot.alertImage = "link"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                    UIPasteboard.general.string = "https://hustle.page/post/\(id)/"
                }
            }, label: {
                Label (
                    title: { Text("Copy Link") },
                    icon: { Image(systemName: "link") }
                )
            })
            if edit {
                Button {
                    showEditAd.toggle()
                } label: {
                    Label(
                        title: { Text("Edit") },
                        icon: { Image(systemName: "slider.horizontal.3") }
                    )
                }
            }
            if tweet.uid != (auth.currentUser?.id ?? "") {
                Button(role: .destructive, action: {
                    blockUser = true
                }) {
                    Label (
                        title: { Text("Block @\(tweet.username)") },
                        icon: { Image(systemName: "person.badge.minus") }
                    )
                }
                Button(role: .destructive, action: {
                    if let id = tweet.id {
                        UserService().reportContent(type: "hustle", postID: id)
                    }
                }) {
                    Label(
                        title: { Text("Report Post") },
                        icon: { Image(systemName: "flag") }
                    )
                }
            } else {
                Button(role: .destructive, action: {
                    showOptions = true
                }) {
                    Label(
                        title: { Text("Delete") },
                        icon: { Image(systemName: "trash") }
                    )
                }
            }
        } label: {
            ZStack {
                Rectangle().frame(width: 15, height: 15).foregroundStyle(.gray).opacity(0.001)
                Image(systemName: "ellipsis").font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
    }
    @ViewBuilder
    func CustomButton(systemImage: String, status: Bool, activeTint: Color, inActiveTint: Color, onTap: @escaping () -> ()) -> some View {
        Button(action: onTap) {
            let isLiked = (auth.currentUser?.likedHustles.contains(tweet.id ?? "") ?? false)
            
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .particleEffectLike (
                    systemImage: systemImage,
                    font: .body,
                    status: status,
                    activeTint: activeTint,
                    inActiveTint: inActiveTint,
                    direction: true
                )
                .symbolEffect(.bounce, value: liked)
                .foregroundColor(status ? activeTint : inActiveTint).font(.subheadline)
        }
    }
    func profileSlide(size: CGFloat) -> some View {
        ZStack {
            if let image = tweet.profilephoto, image.isEmpty {
                personView(size: size)
                KFImage(URL(string: image))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width:size, height: size)
                    .clipShape(Circle())
                    .contentShape(Circle())
                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
            } else {
                personView(size: size)
            }
        }
    }
}

extension View {
    @ViewBuilder
    func particleEffectLike(systemImage: String, font: Font, status: Bool, activeTint: Color, inActiveTint: Color, direction: Bool) -> some View {
        self
            .modifier (
                ParticleModifierLike(status: status, direction: direction)
            )
        
    }
}

fileprivate struct ParticleModifierLike: ViewModifier {
    var status: Bool
    var direction: Bool
    @State private var particles: [Particle] = []
    @State private var negative_particles: [Negative_Particle360] = []
    let allC: [Color] = [.red, .blue, .green, .purple, .pink]
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                ZStack {
                    if direction {
                        ForEach(particles) { particle in
                            Circle()
                                .frame(width: 6)
                                .foregroundStyle(status ? allC.randomElement() ?? .orange : .gray)
                                .scaleEffect(particle.scale)
                                .offset(x: particle.randomX / 3.0, y: particle.randomY / 3.0)
                                .opacity(particle.opacity)
                                .opacity(status ? 1 : 0)
                                .animation(.none, value: status)
                        }
                    } else {
                        ForEach(negative_particles) { particle in
                            Circle()
                                .frame(width: 6)
                                .foregroundStyle(status ? .red : .gray)
                                .scaleEffect(particle.scale)
                                .offset(x: particle.randomX / 3.0, y: particle.randomY / 3.0)
                                .opacity(particle.opacity)
                                .opacity(status ? 1 : 0)
                                .animation(.none, value: status)
                        }
                    }
                }
                .onChange(of: status) { _, newValue in
                    if !newValue {
                        if direction {
                            for index in particles.indices {
                                particles[index].reset()
                            }
                        } else {
                            for index in negative_particles.indices {
                                negative_particles[index].reset()
                            }
                        }
                    } else {
                        if direction {
                            if particles.isEmpty {
                                for _ in 1...15 {
                                    let particle = Particle()
                                    particles.append(particle)
                                }
                            }
                        } else {
                            if negative_particles.isEmpty {
                                for _ in 1...15 {
                                    let particle = Negative_Particle360()
                                    negative_particles.append(particle)
                                }
                            }
                        }
                        if direction {
                            for index in particles.indices {
                                let total: CGFloat = CGFloat(particles.count)
                                let progress: CGFloat = CGFloat(index) / total
                                
                                let angle: CGFloat = progress * 2 * .pi
                                
                                let radius: CGFloat = 75
                                let centerX: CGFloat = 0
                                let centerY: CGFloat = 0
                                
                                let randomX: CGFloat = radius * cos(angle) + centerX
                                let randomY: CGFloat = radius * sin(angle) + centerY
                                let randomScale: CGFloat = .random(in: 0.35...1)
                                
                                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7)) {
                                    let extraRandomX: CGFloat = .random(in: -10...10)
                                    let extraRandomY: CGFloat = .random(in: 0...40)
                                    
                                    particles[index].randomX = randomX + extraRandomX
                                    particles[index].randomY = randomY + extraRandomY
                                }
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    particles[index].scale = randomScale
                                }
                                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7)
                                    .delay(0.25 + (Double(index) * 0.005))) {
                                        particles[index].scale = 0.001
                                }
                            }
                        } else {
                            for index in negative_particles.indices {
                                let randomScale: CGFloat = .random(in: 0.8...1)
                                let targetX: CGFloat = .random(in: -5...5)
                                let targetY: CGFloat = .random(in: -5...5)
                                withAnimation(.easeIn(duration: 0.3)) {
                                    negative_particles[index].randomX = targetX
                                    negative_particles[index].randomY = targetY
                                    negative_particles[index].scale = randomScale
                                }
                                withAnimation(.easeIn(duration: 0.5).delay(0.2)) {
                                        negative_particles[index].scale = 0.001
                                }
                            }
                        }
                    }
                }
            }
        
    }
}
