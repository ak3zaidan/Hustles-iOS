import SwiftUI
import Photos
import Kingfisher

struct PostPartView: View {
    let fullURL: String
    let leading: Bool
    @State var currentTweet: Tweet? = nil
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: FeedViewModel
    @EnvironmentObject var auth: AuthViewModel
    @State private var showPost: Bool = false
    @State var initialContent: uploadContent? = nil
    @State var place: myLoc? = nil
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State private var saved = false
    @Environment(\.colorScheme) var colorScheme
    @State var sendLink: String = ""
    @State private var showForward = false
    @State var noFound: Bool = false
    @Binding var currentAudio: String
    
    var body: some View {
        HStack(spacing: 10){
            if let tweet = currentTweet {
                if leading && !noFound {
                    optionButtons()
                }
                NavigationLink {
                    HustleTaggedView(hustleID: tweet.id ?? "").enableFullSwipePop(true)
                } label: {
                    if let all = tweet.contentArray {
                        if let first = all.first(where: { $0.contains("hustlesImages") }) {
                            imagePart(image: first)
                        } else if let first = all.first, let url = URL(string: first) {
                            videoPart(video: url)
                        }
                    } else if let audio = tweet.audioURL, let url = URL(string: audio) {
                        VoiceStreamView(audioUrl: url, currentAudio: $currentAudio, hustleID: tweet.id ?? "")
                            .frame(width: 260)
                            .contextMenu {
                                Button(action: {
                                    popRoot.alertImage = "square.and.arrow.down.fill"
                                    popRoot.alertReason = "Audio Saved to Documents"
                                    withAnimation {
                                        popRoot.showAlert = true
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    downloadAudio(from: url)
                                }, label: {
                                    Label(
                                        title: { Text("Download Audio") },
                                        icon: { Image(systemName: "square.and.arrow.down") }
                                    )
                                })
                                Button(action: {
                                    popRoot.alertImage = "link"
                                    popRoot.alertReason = "Audio Link Copied"
                                    withAnimation {
                                        popRoot.showAlert = true
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    UIPasteboard.general.string = url.absoluteString
                                }, label: {
                                    Label(
                                        title: { Text("Copy Link") },
                                        icon: { Image(systemName: "link") }
                                    )
                                })
                            }
                    } else if let c1 = tweet.choice1, let c2 = tweet.choice2 {
                        let c3 = tweet.choice3
                        let c4 = tweet.choice4
                        
                        let count1 = tweet.count1 ?? 0
                        let count2 = tweet.count2 ?? 0
                        let count3 = tweet.count3 ?? 0
                        let count4 = tweet.count4 ?? 0

                        VStack(spacing: 10){
                            VStack(spacing: 5){
                                HStack(spacing: 10){
                                    ZStack {
                                        personView(size: 40)
                                        if let photo = currentTweet?.profilephoto {
                                            KFImage(URL(string: photo))
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 40.0, height: 40.0)
                                                .clipShape(Circle())
                                                .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                        }
                                    }
                                    Text(tweet.username).font(.system(size: 18)).bold()
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    if tweet.verified ?? false == true {
                                        Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(.blue)
                                    }
                                    Spacer()
                                }
                                HStack {
                                    Text(tweet.caption).foregroundStyle(colorScheme == .dark ? .white : .black).multilineTextAlignment(.leading)
                                    Spacer()
                                }
                            }
                            PollRowView(choice1: c1, choice2: c2, choice3: c3, choice4: c4, count1: count1, count2: count2, count3: count3, count4: count4, hustleID: tweet.id ?? "", whoVoted: tweet.voted ?? [], timestamp: tweet.timestamp)
                        }
                        .padding(10)
                        .frame(maxWidth: widthOrHeight(width: true) * 0.75)
                        .background(content: {
                            Color.gray.opacity(0.1)
                        })
                        .overlay(content: {
                            RoundedRectangle(cornerRadius: 10).stroke(.gray, lineWidth: 1)
                        })
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else if let yelpID = tweet.yelpID {
                        YelpRowView(placeID: yelpID, isChat: false, isGroup: false, otherPhoto: nil)
                    } else if !tweet.caption.isEmpty {
                        VStack(alignment: .leading, spacing: 10){
                            HStack(alignment: .top, spacing: 10){
                                ZStack {
                                    personView(size: 45)
                                    if let photo = currentTweet?.profilephoto {
                                        KFImage(URL(string: photo))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 45.0, height: 45.0)
                                            .clipShape(Circle())
                                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                    }
                                }
                                VStack(alignment: .leading){
                                    HStack {
                                        Text(tweet.username).font(.system(size: 18)).bold()
                                        if tweet.verified ?? false == true {
                                            Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(.blue)
                                        }
                                    }
                                    Text("Public").font(.system(size: 16)).foregroundStyle(.gray)
                                }
                                Spacer()
                            }

                            let trunText = tweet.caption.count > 270 ? (tweet.caption.prefix(270) + "...") : tweet.caption
                             
                            Text(trunText).truncationMode(.tail).multilineTextAlignment(.leading)
                        }
                        .padding(10)
                        .frame(width: 260)
                        .background(.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                if !leading && !noFound {
                    optionButtons()
                }
            } else if noFound {
                VStack(spacing: 8){
                    HStack {
                        Text("Message unavailable").font(.headline)
                        Spacer()
                    }
                    Text("This content may have been deleted by its owner or hidden by their privacy settings. Check your connection to ensure content can be loaded.").font(.caption)
                }
                .frame(width: widthOrHeight(width: true) * 0.55)
                .padding(8)
                .background(.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    popRoot.alertReason = "Post not found"
                    popRoot.alertImage = "exclamationmark.magnifyingglass"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                }
            } else {
                HStack(spacing: 10){
                    personView(size: 45)
                    VStack(alignment: .leading){
                        HStack {
                            Text("------").font(.system(size: 18)).bold()
                            Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(.blue)
                        }
                        Text("-----------").font(.system(size: 16)).foregroundStyle(.gray)
                    }
                    Color.clear.frame(width: 20, height: 10)
                    ZStack {
                        Circle()
                            .foregroundStyle(.ultraThickMaterial)
                            .frame(width: 40, height: 40)
                        ProgressView()
                    }
                }
                .padding(8)
                .background(.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    popRoot.alertReason = "Post not found"
                    popRoot.alertImage = "exclamationmark.magnifyingglass"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                }
            }
        }
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .onAppear(perform: {
            let postId = extractVariable(from: fullURL) ?? ""
            
            if let first = popRoot.randomTweets.first(where: { $0.id == postId }) {
                currentTweet = first
                noFound = false
            } else if let first = viewModel.new.first(where: { $0.id == postId }) {
                currentTweet = first
                noFound = false
            } else if let first = viewModel.followers.first(where: { $0.id == postId }) {
                currentTweet = first
                noFound = false
            } else {
                UserService().fetchTweet(id: postId) { tweet in
                    if let tweet = tweet {
                        currentTweet = tweet
                        noFound = false
                        self.popRoot.randomTweets.append(tweet)
                    } else {
                        noFound = true
                    }
                }
            }
        })
        .fullScreenCover(isPresented: $showPost, content: {
            NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent)
                .onDisappear {
                    place = nil
                }
        })
    }
    func optionButtons() -> some View {
        VStack(spacing: 10){
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let id = currentTweet?.id {
                    sendLink = "https://hustle.page/post/\(id)/"
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
            let r_saved = (auth.currentUser?.savedPosts ?? []).contains(currentTweet?.id ?? "")
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if r_saved {
                    auth.currentUser?.savedPosts?.removeAll(where: { $0 == (currentTweet?.id ?? "") })
                    UserService().removePostSave(id: currentTweet?.id ?? "")
                    
                    popRoot.alertImage = "bookmark.slash.fill"
                    popRoot.alertReason = "Post removed from your Bookmarks"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                } else {
                    auth.currentUser?.savedPosts = (auth.currentUser?.savedPosts ?? []) + [(currentTweet?.id ?? "")]
                    UserService().addPostSave(id: currentTweet?.id ?? "")
                    
                    popRoot.alertImage = "bookmark.fill"
                    popRoot.alertReason = "Post added to your Bookmarks"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                }
                saved.toggle()
            }, label: {
                Image(systemName: r_saved ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(r_saved ? .blue : (colorScheme == .dark ? .white : .black))
                    .symbolEffect(.bounce, value: saved)
                    .frame(width: 18, height: 18)
                    .scaleEffect(y: 0.7).font(.headline)
                    .padding(8)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            })
            Button(action: {
                popRoot.alertReason = "Post URL copied"
                popRoot.alertImage = "link"
                withAnimation {
                    popRoot.showAlert = true
                }
                if let id = currentTweet?.id {
                    UIPasteboard.general.string = "https://hustle.page/post/\(id)/"
                }
            }, label: {
                Image(systemName: "link")
                    .frame(width: 18, height: 18)
                    .font(.headline)
                    .padding(8).foregroundStyle(.blue)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            })
        }
    }
    func imagePart(image: String) -> some View {
        KFImage(URL(string: image))
            .resizable()
            .scaledToFill()
            .frame(width: widthOrHeight(width: true) * 0.75, height: 370)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .contentShape(RoundedRectangle(cornerRadius: 15))
            .overlay(content: {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1.0)
            })
            .padding(.top, 4)
            .overlay(alignment: .leading, content: {
                VStack(alignment: .leading){
                    if let name = currentTweet?.username {
                        HStack(spacing: 5){
                            ZStack {
                                personView(size: 30)
                                if let photo = currentTweet?.profilephoto {
                                    KFImage(URL(string: photo))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 30.0, height: 30.0)
                                        .clipShape(Circle())
                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                }
                            }
                            Text(name).bold().font(.headline)
                        }
                        .padding(3)
                        .background {
                            TransparentBlurView()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                    }
                    Spacer()
                }.padding(.vertical, 10).padding(.horizontal, 5)
            })
            .contextMenu {
                Button(action: {
                    initialContent = uploadContent(isImage: true, imageURL: image)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showPost = true
                }, label: {
                    Label(
                        title: { Text("Post Photo") },
                        icon: { Image(systemName: "photo") }
                    )
                })
                Button(action: {
                    popRoot.alertImage = "square.and.arrow.down.fill"
                    popRoot.alertReason = "Image Saved"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    downloadAndSaveImage(url: image)
                }, label: {
                    Label(
                        title: { Text("Download Image") },
                        icon: { Image(systemName: "square.and.arrow.down") }
                    )
                })
                Button(action: {
                    popRoot.alertImage = "link"
                    popRoot.alertReason = "Image Link Copied"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    UIPasteboard.general.string = image
                }, label: {
                    Label(
                        title: { Text("Copy Link") },
                        icon: { Image(systemName: "link") }
                    )
                })
            }
    }
    func videoPart(video: URL) -> some View {
        MessageVideoPlayer(url: video, width: widthOrHeight(width: true) * 0.75, height: 370.0, cornerRadius: 15.0, viewID: nil, currentAudio: $currentAudio)
            .overlay(alignment: .leading, content: {
                VStack(alignment: .leading){
                    HStack(spacing: 5){
                        if let name = currentTweet?.username {
                            ZStack {
                                personView(size: 30)
                                if let photo = currentTweet?.profilephoto {
                                    KFImage(URL(string: photo))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 30.0, height: 30.0)
                                        .clipShape(Circle())
                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                }
                            }
                            Text(name).bold().font(.headline)
                        }
                    }
                    .padding(3)
                    .background {
                        TransparentBlurView()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    Spacer()
                }.padding(.vertical, 10).padding(.horizontal, 5)
            })
            .contextMenu {
                Button(action: {
                    initialContent = uploadContent(isImage: false, videoURL: video)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showPost = true
                }, label: {
                    Label(
                        title: { Text("Post Video") },
                        icon: { Image(systemName: "video.fill") }
                    )
                })
                Button(action: {
                    popRoot.alertImage = "square.and.arrow.down.fill"
                    popRoot.alertReason = "Video Saved"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    saveVideoToCameraRoll(urlStr: video.absoluteString)
                }, label: {
                    Label(
                        title: { Text("Download Video") },
                        icon: { Image(systemName: "square.and.arrow.down") }
                    )
                })
                Button(action: {
                    popRoot.alertImage = "link"
                    popRoot.alertReason = "Video Link Copied"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    UIPasteboard.general.string = video.absoluteString
                }, label: {
                    Label(
                        title: { Text("Copy Link") },
                        icon: { Image(systemName: "link") }
                    )
                })
            }
    }
    func extractVariable(from urlString: String) -> String? {
        let components = urlString.components(separatedBy: "/")

        if let index = components.firstIndex(of: "post"), index + 1 < components.count {
            return components[index + 1]
        }
        
        return nil
    }
}

func saveVideoToCameraRoll(urlStr: String) {
    DispatchQueue.global(qos: .background).async {
        if let url = URL(string: urlStr),
            let urlData = NSData(contentsOf: url) {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
            let filePath="\(documentsPath)/tempFile.mp4"
            DispatchQueue.main.async {
                urlData.write(toFile: filePath, atomically: true)
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                }) { completed, error in
                    if completed {
                        print("Video is saved!")
                    }
                }
            }
        }
    }
}

struct ProfilePartView: View {
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var exploreModel: ExploreViewModel
    let fullURL: String
    @State var currentUser: User? = nil
    
    var body: some View {
        ZStack {
            if let user = currentUser {
                NavigationLink {
                    ProfileView(showSettings: false, showMessaging: true, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: false, isMain: false).enableFullSwipePop(true)
                } label: {
                    if let photo = user.profileImageUrl, !photo.isEmpty {
                        VStack(spacing: 0){
                            HStack(spacing: 10){
                                ZStack {
                                    personView(size: 45)
                                    KFImage(URL(string: photo))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 45.0, height: 45.0)
                                        .clipShape(Circle())
                                }
                                VStack(alignment: .leading){
                                    HStack {
                                        Text(user.username).font(.system(size: 18)).bold().lineLimit(1)
                                        if user.verified != nil {
                                            Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(.blue).lineLimit(1)
                                        }
                                    }
                                    Text(user.fullname).font(.system(size: 16)).foregroundStyle(.gray)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .frame(width: 250.0)
                            .background(.gray.opacity(0.2))
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 15, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 15))
                            
                            KFImage(URL(string: photo))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 250.0, height: 170.0)
                                .overlay(content: {
                                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 15, bottomTrailingRadius: 15, topTrailingRadius: 0).stroke(style: StrokeStyle())
                                })
                                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 15, bottomTrailingRadius: 15, topTrailingRadius: 0))
                                .overlay(alignment: .bottomTrailing){
                                    Button(action: {
                                        popRoot.alertReason = "Profile URL copied"
                                        popRoot.alertImage = "link"
                                        withAnimation {
                                            popRoot.showAlert = true
                                        }
                                        UIPasteboard.general.string = fullURL
                                    }, label: {
                                        ZStack {
                                            Circle()
                                                .foregroundStyle(.ultraThickMaterial)
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "link").foregroundStyle(.blue).bold()
                                        }.padding(7)
                                    })
                                }
                            
                        }
                    } else {
                        HStack(spacing: 10){
                            personView(size: 45)
                            VStack(alignment: .leading){
                                HStack {
                                    Text(user.username).font(.system(size: 18)).bold()
                                    if user.verified != nil {
                                        Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(.blue).lineLimit(1)
                                    }
                                }
                                Text(user.fullname).font(.system(size: 16)).foregroundStyle(.gray).lineLimit(1)
                            }
                            Color.clear.frame(width: 20, height: 10)
                            Button(action: {
                                popRoot.alertReason = "Profile URL copied"
                                popRoot.alertImage = "link"
                                withAnimation {
                                    popRoot.showAlert = true
                                }
                                UIPasteboard.general.string = fullURL
                            }, label: {
                                ZStack {
                                    Circle()
                                        .foregroundStyle(.ultraThickMaterial)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "link").foregroundStyle(.blue).bold()
                                }
                            })
                        }
                        .padding(8)
                        .background(.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else {
                HStack(spacing: 10){
                    personView(size: 45)
                    VStack(alignment: .leading){
                        HStack {
                            Text("------").font(.system(size: 18)).bold()
                            Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(.blue)
                        }
                        Text("-----------").font(.system(size: 16)).foregroundStyle(.gray)
                    }
                    Color.clear.frame(width: 20, height: 10)
                    ZStack {
                        Circle()
                            .foregroundStyle(.ultraThickMaterial)
                            .frame(width: 40, height: 40)
                        ProgressView()
                    }
                }
                .padding(8)
                .background(.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    popRoot.alertReason = "User not found"
                    popRoot.alertImage = "exclamationmark.magnifyingglass"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                }
            }
        }
        .onAppear(perform: {
            let uid = extractVariable(from: fullURL)
            if let id = uid, !id.isEmpty && currentUser == nil {
                if let first = popRoot.randomUsers.first(where: { $0.id == id }) {
                    self.currentUser = first
                } else if let first = messageModel.chats.first(where: { $0.user.id == id })?.user {
                    self.currentUser = first
                } else if let first = exploreModel.searchU.first(where: { $0.id == id }) {
                    self.currentUser = first
                } else if let first = messageModel.following.first(where: { $0.id == id }) {
                    self.currentUser = first
                } else if let first = messageModel.searchUsers.first(where: { $0.id == id }) {
                    self.currentUser = first
                } else {
                    UserService().fetchUser(withUid: id) { user in
                        self.currentUser = user
                        self.popRoot.randomUsers.append(user)
                    }
                }
            }
        })
    }
    func extractVariable(from urlString: String) -> String? {
        let components = urlString.components(separatedBy: "/")

        if let index = components.firstIndex(of: "profile"), index + 1 < components.count {
            return components[index + 1]
        }
        
        return nil
    }
}
