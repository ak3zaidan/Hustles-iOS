import SwiftUI
import Kingfisher
import Firebase

struct TitleRow: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @EnvironmentObject var viewModel: ProfileViewModel
    @State private var dateFinal: String = ""
    @State private var textFinal: String = ""
    @State private var active: Bool = false
    @State var seen: Bool = true
    @State var received: Bool = false
    @State var user: User
    @Binding var message: Message
    @State var is_uid_one: Bool
    @Binding var isExpanded: Bool
    let animation: Namespace.ID
    let convoID: String
    let bubbleColor: Color
    let seenAllStories: Bool
    @Binding var updateRowView: Bool
    
    var body: some View {
        HStack(spacing: 15){
            ZStack {
                if hasStories() {
                    StoryRingView(size: 59.0, active: seenAllStories, strokeSize: 1.8)
                        .scaleEffect(1.19)
                    
                    let mid = convoID + "UpStory"
                    let size = isExpanded && viewModel.mid == mid ? widthOrHeight(width: true) : 59.0
                    GeometryReader { _ in
                        ZStack {
                            personLetterViewColor(size: size, letter: String(user.fullname.first ?? user.username.first ?? Character("")), color: bubbleColor)
                            if let image = user.profileImageUrl {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .scaledToFill()
                                    .clipShape(Circle())
                                    .frame(width: size, height: size)
                            }
                        }.opacity(isExpanded && viewModel.mid == mid ? 0.0 : 1.0)
                    }
                    .matchedGeometryEffect(id: mid, in: animation, anchor: .topLeading)
                    .frame(width: 59.0, height: 59.0)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        setupStory()
                        viewModel.mid = mid
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded = true
                        }
                    }
                } else {
                    GeometryReader { _ in
                        ZStack {
                            personLetterViewColor(size: 59, letter: String(user.fullname.first ?? user.username.first ?? Character("")), color: bubbleColor)
                            
                            if let image = user.profileImageUrl {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .scaledToFill()
                                    .clipShape(Circle())
                                    .frame(width: 58, height: 58)
                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                            }
                        }
                    }.frame(width: 59, height: 59)
                }
            }
            
            VStack(alignment: .leading, spacing: 5){
                HStack(spacing: 5) {
                    if active {
                        Circle().foregroundStyle(.green).frame(width: 9, height: 9)
                    }
                    Text(user.fullname)
                        .font(seen ? .headline : .headline.bold())
                        .foregroundColor(seen ? (colorScheme == .dark ? .white : .black) : .blue)
                    Spacer()
                    if !dateFinal.isEmpty {
                        Text(dateFinal).font(.subheadline).foregroundColor(.gray)
                    }
                }
                
                if received {
                   if seen {
                       (Text(Image(systemName: "message")).foregroundColor(.blue).font(.subheadline) + Text("  Recieved - ").font(.caption).foregroundColor(.gray) + Text(textFinal).font(.caption).foregroundColor(.gray)).multilineTextAlignment(.leading)
                   } else {
                       (Text(Image(systemName: "message.fill")).foregroundColor(.blue).font(.subheadline) + Text("  New Chat - ").font(.caption).foregroundColor(.blue).bold() + Text(textFinal).font(.caption).foregroundColor(.gray)).multilineTextAlignment(.leading)
                   }
               } else {
                   if message.seen_by_reciever {
                       (Text(Image(systemName: "arrowshape.turn.up.forward")).foregroundColor(.red).font(.subheadline) + Text("  Opened - ").font(.caption).foregroundColor(.gray) + Text(textFinal).font(.caption).foregroundColor(.gray)).multilineTextAlignment(.leading)
                   } else {
                       (Text(Image(systemName: "arrowshape.turn.up.forward.fill")).foregroundColor(.blue).font(.subheadline) + Text("  Delivered - ").font(.caption).foregroundColor(.gray) + Text(textFinal).font(.caption).foregroundColor(.gray)).multilineTextAlignment(.leading)
                   }
               }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 75)
        .onAppear {
            setUp()
        }
        .onChange(of: updateRowView) { _, _ in
            setUp()
        }
    }
    func hasStories() -> Bool {
        return !(viewModel.users.first(where: { $0.user.id == self.user.id })?.stories ?? []).isEmpty
    }
    func setupStory() {
        if let stories = viewModel.users.first(where: { $0.user.id == self.user.id })?.stories {
            viewModel.selectedStories = stories
        }
    }
    func setUp() {
        self.received = is_uid_one && message.uid_one_did_recieve || !is_uid_one && !message.uid_one_did_recieve
        self.seen = received ? message.seen_by_reciever : true
        
        self.dateFinal = getMessageTime(date: message.timestamp.dateValue())
        
        if let lastTime = user.lastSeen {
            let date = lastTime.dateValue()
            let currentDate = Date()
            let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: currentDate)
            
            if let oneHourAgo = oneHourAgo {
                if date >= oneHourAgo && date <= currentDate {
                    active = true
                } else {
                    active = false
                }
            } else {
                active = false
            }
        } else {
            active = false
        }
        
        if let text = message.text {
            if text.contains(")(*&^%$#@!"){
                if received {
                    textFinal = "Join request for " + String(text.components(separatedBy: ")(*&^%$#@!").last ?? "")
                } else {
                    textFinal = "You sent a reqest"
                }
            } else if text.contains("pub!@#$%^&*()"){
                textFinal = "Check out " + String(text.components(separatedBy: "pub!@#$%^&*()").last ?? "")
            } else if text.contains("priv!@#$%^&*()"){
                if received {
                    textFinal = "You've been invited, check out " + String(text.components(separatedBy: "priv!@#$%^&*()").last ?? "")
                } else {
                    textFinal = "You sent an invite"
                }
            } else if text.contains("https://hustle.page/profile/"){
                if received {
                    textFinal = "You recieved a profile"
                } else {
                    textFinal = "You sent a profile"
                }
            } else if text.contains("https://hustle.page/post/"){
                if received {
                    textFinal = "You recieved a post"
                } else {
                    textFinal = "You sent a post"
                }
            } else if text.contains("https://hustle.page/story/"){
                if let result = extractTextEmojiFromStoryURL(urlStr: text), result.emoji != nil || result.text != nil {
                    if let emoji = result.emoji {
                        if received {
                            textFinal = "\(getEmojiFromAsset(assetName: emoji)) Reacted to your story"
                        } else {
                            textFinal = "\(getEmojiFromAsset(assetName: emoji)) You reacted"
                        }
                    } else if let text = result.text {
                        var newText = text
                        if newText.count > 40 {
                            newText = String(newText.dropLast(newText.count - 40)) + "..."
                        }
                        if received {
                            textFinal = "Reacted to your story: \(newText)"
                        } else {
                            textFinal = "You reacted: \(newText)"
                        }
                    }
                } else {
                    if received {
                        textFinal = "You recieved a story"
                    } else {
                        textFinal = "You sent a story"
                    }
                }
            } else if text.contains("https://hustle.page/location/"){
                if received {
                    textFinal = "You recieved a location"
                } else {
                    textFinal = "You sent a location"
                }
            } else if text.contains("https://hustle.page/news/"){
                if received {
                    textFinal = "You recieved news"
                } else {
                    textFinal = "You sent news"
                }
            } else if text.contains("https://hustle.page/memory/"){
                if received {
                    textFinal = "You recieved a memory"
                } else {
                    textFinal = "You sent a memory"
                }
            } else if text.contains("https://hustle.page/yelp/"){
                if received {
                    textFinal = "You recieved a place recommendation"
                } else {
                    textFinal = "You sent a place recommendation"
                }
            } else if message.pinmap != nil && text.isEmpty {
                if received {
                    textFinal = "A pin was added to the chat map"
                } else {
                    textFinal = "You added a pin to the chat map"
                }
            } else {
                if text.count > 77 {
                    let length = text.count - 77
                    textFinal = String(text.dropLast(length)) + "..."
                } else {
                    textFinal = text
                }
            }
        } else if message.elo != nil {
            if received {
                textFinal = "You've recieved ELO"
            } else {
                textFinal = "You sent ELO"
            }
        } else if message.imageUrl != nil {
            if received {
                textFinal = "You've recieved an image"
            } else {
                textFinal = "You sent an image"
            }
        } else if message.sentAImage != nil {
            textFinal = "You sent an image"
        } else if message.file != nil {
            if received {
                textFinal = "You've recieved a file"
            } else {
                textFinal = "You sent a file"
            }
        } else if message.audioURL != nil {
            if received {
                textFinal = "You've recieved audio"
            } else {
                textFinal = "You sent audio"
            }
        } else if message.videoURL != nil {
            if received {
                textFinal = "You've recieved a video"
            } else {
                textFinal = "You sent a video"
            }
        } else if message.lat != nil {
            if received {
                textFinal = "You've recieved a location"
            } else {
                textFinal = "You sent a location"
            }
        } else {
            if received {
                textFinal = "You've recieved a message"
            } else {
                textFinal = "You sent a message"
            }
        }
    }
}

struct GroupTitleRow: View {
    let group: GroupX
    @State private var dateFinal: String = ""
    @State private var textFinal: String = ""
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @EnvironmentObject var vModel: GroupViewModel
    let uid: String
    @Binding var updateRowView: Bool
    
    var body: some View {
        HStack(spacing: 20){
            ZStack {
                personView(size: 58)
                KFImage(URL(string: group.imageUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 58, height: 58)
                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
            }
            VStack(alignment: .leading, spacing: 5){
                Text(group.title).font(.headline)
                if !textFinal.isEmpty {
                    HStack(spacing: 7){
                        if textFinal.contains("Recieved from") {
                            Image(systemName: "message").foregroundStyle(.blue).font(.caption)
                        } else {
                            Image(systemName: "arrowshape.turn.up.forward").foregroundStyle(.blue).font(.caption)
                        }
                        Text("\(textFinal) - \(dateFinal)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                    }
                } else {
                    Text("\(group.membersCount) members")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.gray).font(.headline).padding(.trailing, 5)
        }
        .frame(height: 75)
        .onAppear {
            setUp()
        }
        .onChange(of: updateRowView) { _, _ in
            setUp()
        }
    }
    func setUp() {
        if let all = vModel.groups.first(where: { $0.1.id == group.id })?.1.messages {
            var components = DateComponents()
            components.year = 2001
            let calendar = Calendar.current
            let date = calendar.date(from: components)
            var newest: Tweet = Tweet(caption: "", timestamp: Timestamp(date: date!), uid: "", username: "", video: nil, verified: nil, veriUser: nil)
            
            all.forEach { element in
                if let newestTweet = element.messages.max(by: { $0.timestamp.dateValue() < $1.timestamp.dateValue() }) {
                    if newestTweet.timestamp.dateValue() > newest.timestamp.dateValue() {
                        newest = newestTweet
                    }
                }
            }
            
            if !newest.username.isEmpty {
                if uid == newest.uid {
                    textFinal = "Delivered"
                } else {
                    textFinal = "Recieved from \(newest.username)"
                }
                
                self.dateFinal = getMessageTime(date: newest.timestamp.dateValue())
            }
        }
    }
}
