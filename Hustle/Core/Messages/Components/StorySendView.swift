import SwiftUI
import Photos
import Kingfisher
        
struct StorySendView: View {
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var profile: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme
    @State var showPost: Bool = false
    @State var initialContent: uploadContent? = nil
    @State var place: myLoc? = nil
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State var showForward = false
    @State var sendLink: String = ""
    @State var fetchingAll: Bool = false
    
    @State var currentTweet: Story
    let leading: Bool
    @Binding var currentAudio: String
    let text: String?
    let emoji: String?
    let reaction: String?
    @Binding var isExpanded: Bool
    let animation: Namespace.ID
    @Binding var addPadding: Bool
    let parentID: String

    var body: some View {
        ZStack(alignment: !leading ? (emoji != nil ? .bottomTrailing : .bottomLeading) : (emoji != nil ? .bottomLeading : .bottomTrailing)){
            HStack(spacing: 10){
                if leading {
                    optionButtons()
                }
                
                let mid = currentTweet.id ?? "" + parentID
                
                if !isExpanded || profile.mid != mid {
                    ZStack {
                        if let image = currentTweet.imageURL {
                            storyImagePart(mid: mid, animation: animation, image: image)
                                .frame(width: 240, height: 350.0)
                                .onTapGesture {
                                    if !fetchingAll {
                                        getAllUser()
                                    }
                                }
                        } else if let video = currentTweet.videoURL, let url = URL(string: video) {
                            storyVideoPart(mid: mid, animation: animation, image: popRoot.previewStory[video], video: url)
                                .frame(width: 240, height: 350.0)
                                .onTapGesture {
                                    if !fetchingAll {
                                        getAllUser()
                                    }
                                }
                                .onAppear(perform: {
                                    if popRoot.previewStory[video] == nil {
                                        extractImageAt(f_url: url, time: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) { thumbnail in
                                            popRoot.previewStory[video] = Image(uiImage: thumbnail)
                                        }
                                    }
                                })
                        } else {
                            RoundedRectangle(cornerRadius: 15.0)
                                .foregroundStyle(.gray).opacity(0.3).frame(width: 240, height: 350.0)
                            ProgressView()
                        }
                    }
                    .overlay(content: {
                        if let text = currentTweet.text, !text.isEmpty {
                            VStack {
                                let position = min(1.0, currentTweet.textPos ?? 0.6)
                                let finalPos = max(60, 350.0 * position)
                                
                                Text(text.count > 75 ? "\(text.prefix(50))..." : text)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 6)
                                    .font(.caption).foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: 240.0)
                                    .background {
                                        TransparentBlurView(removeAllFilters: true)
                                            .blur(radius: 9, opaque: true).background(.black.opacity(0.4))
                                    }
                                    .offset(y: finalPos)
                                
                                Spacer()
                            }
                        }
                    })
                    .overlay(alignment: .leading, content: {
                        VStack(alignment: .leading){
                            HStack(spacing: 5){
                                ZStack {
                                    personView(size: 30)
                                    if let photo = currentTweet.profilephoto {
                                        KFImage(URL(string: photo))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 30.0, height: 30.0)
                                            .clipShape(Circle())
                                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                    }
                                }
                                Text(currentTweet.username).bold().font(.headline)
                            }
                            .padding(3)
                            .background {
                                TransparentBlurView()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            Spacer()
                        }.padding(.vertical, 10).padding(.horizontal, 5)
                    })
                    .overlay(alignment: .topTrailing, content: {
                        if let reaction {
                            ZStack {
                                if reaction == "questionmark" {
                                    Image(systemName: "questionmark").font(.subheadline).padding(8).foregroundStyle(colorScheme == .dark ? .white : .black).background(.ultraThickMaterial).clipShape(Circle())
                                } else {
                                    Text(reaction).font(.subheadline).padding(8).background(.ultraThickMaterial).clipShape(Circle())
                                }
                            }.padding(10)
                        }
                    })
                } else {
                    RoundedRectangle(cornerRadius: 15.0)
                        .foregroundStyle(.gray).opacity(0.3).frame(width: 240, height: 350.0)
                }
                
                if !leading {
                    optionButtons()
                }
            }
            .offset(x: (text == nil) ? 0 : (!leading ? 20 : -20))
            
    
            if let emoji {
                Text(getEmojiFromAsset(assetName: emoji))
                    .font(.system(size: 45))
                    .offset(x: !leading ? -25 : 25, y: 14)
            } else if let text {
                LinkedText(text, tip: false, isMess: true)
                    .disabled(true)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 80)
                    .background(leading ? Color(UIColor.orange).gradient.opacity(colorScheme == .dark ? 0.3 : 0.7) : Color(UIColor.gray).gradient.opacity(0.6))
                    .background(content: {
                        ZStack {
                            if colorScheme == .dark {
                                Color.black
                            } else {
                                Color.white
                            }
                        }
                    })
                    .clipShape(ChatBubbleShape(direction: !leading ? .left : .right))
                    .offset(y: 14)
            }
        }
        .padding(.bottom, ((text != nil || emoji != nil)) ? 18 : 0)
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .fullScreenCover(isPresented: $showPost, content: {
            NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent)
                .onDisappear {
                    place = nil
                }
        })
    }
    func getAllUser(){
        if !fetchingAll {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.15)){
                fetchingAll = true
            }
            
            profile.getUpdatedStoriesUser(user: nil, uid: currentTweet.uid) { stories in
                withAnimation(.easeInOut(duration: 0.15)){
                    fetchingAll = false
                }
                
                addPadding = true
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
                if stories.isEmpty {
                    profile.selectedStories = [currentTweet]
                } else {
                    var temp = stories
                    temp.removeAll(where: { $0.id == currentTweet.id })
                    profile.selectedStories = [currentTweet] + temp
                }
                
                profile.mid = currentTweet.id ?? "" + parentID
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded = true
                    }
                }
            }
        }
    }
    func optionButtons() -> some View {
        VStack(spacing: 10){
            if fetchingAll {
                ProgressView()
                    .frame(width: 18, height: 18)
                    .padding(8)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
                    .transition(.scale)
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let id = currentTweet.id {
                        sendLink = "https://hustle.page/story/\(id)/"
                        showForward = true
                    }
                }, label: {
                    Image(systemName: "paperplane")
                        .frame(width: 18, height: 18)
                        .font(.headline)
                        .padding(8)
                        .background(.gray.opacity(0.2))
                        .clipShape(Circle())
                }).transition(.scale)
                Button(action: {
                    popRoot.alertReason = "Story URL copied"
                    popRoot.alertImage = "link"
                    withAnimation {
                        popRoot.showAlert = true
                    }
                    if let id = currentTweet.id {
                        UIPasteboard.general.string = "https://hustle.page/story/\(id)/"
                    }
                }, label: {
                    Image(systemName: "link")
                        .frame(width: 18, height: 18)
                        .font(.headline)
                        .padding(8).foregroundStyle(.blue)
                        .background(.gray.opacity(0.2))
                        .clipShape(Circle())
                }).transition(.scale)
                Button(action: {
                    if let image = currentTweet.imageURL {
                        initialContent = uploadContent(isImage: true, imageURL: image)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showPost = true
                    } else if let video = currentTweet.videoURL, let url = URL(string: video) {
                        initialContent = uploadContent(isImage: false, videoURL: url)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showPost = true
                    }
                }, label: {
                    Image(systemName: "plus")
                        .frame(width: 18, height: 18)
                        .font(.headline)
                        .padding(8)
                        .background(.gray.opacity(0.2))
                        .clipShape(Circle())
                }).transition(.scale)
            }
        }
    }
}

struct storyImagePart: View {
    let mid: String
    let animation: Namespace.ID
    let image: String
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            KFImage(URL(string: image))
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .overlay(content: {
                    RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.4), lineWidth: 1.0)
                })
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .contentShape(RoundedRectangle(cornerRadius: 15))
        }
        .matchedGeometryEffect(id: mid, in: animation)
    }
}

struct storyFeedImagePart: View {
    let mid: String
    let animation: Namespace.ID
    let image: String
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            KFImage(URL(string: image))
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .overlay(content: {
                    RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1.0)
                })
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .matchedGeometryEffect(id: mid, in: animation)
    }
}

struct storyVideoPart: View {
    let mid: String
    let animation: Namespace.ID
    let image: Image?
    let video: URL
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ZStack {
                RoundedRectangle(cornerRadius: 15.0)
                    .foregroundStyle(.gray).opacity(0.3).frame(width: size.width, height: size.height)
                    
                ProgressView()
                
                if let image {
                    image
                        .resizable().scaledToFill().frame(width: size.width, height: size.height)
                        .overlay(content: {
                            RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.4), lineWidth: 1.0)
                        })
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .contentShape(RoundedRectangle(cornerRadius: 15))
                   
                    Image(systemName: "play.fill").foregroundStyle(.white).font(.title).bold()
                        .scaleEffect(1.1)
                }
            }
        }.matchedGeometryEffect(id: mid, in: animation)
    }
}

func extractStoryID(from urlString: String) -> String? {
    let components = urlString.components(separatedBy: "/")

    if let index = components.firstIndex(of: "story"), index + 1 < components.count {
        return components[index + 1]
    }
    
    return nil
}

struct StoryErrorView: View {
    var body: some View {
        VStack(spacing: 8){
            HStack {
                Text("Story unavailable").font(.headline)
                Spacer()
            }
            Text("This content may have been deleted by its owner or expired. Check your connection to ensure content can be loaded.").font(.caption).multilineTextAlignment(.leading)
        }
        .frame(width: 180.0).padding(8)
        .background(.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
