import SwiftUI
import Kingfisher
import Firebase

struct GroupChatRowView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var viewModel: GroupChatViewModel
    @State private var seen: Bool = true
    @State private var received: Bool = false
    @Binding var group: GroupConvo
    @State private var dateFinal: String = ""
    @State private var textFinal: String = ""
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @Binding var updateRowView: Bool
    
    init(group: Binding<GroupConvo>, updateRowView: Binding<Bool>){
        self._group = group
        self._updateRowView = updateRowView
    }
    
    var body: some View {
        HStack(spacing: 15){
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color(UIColor.darkGray).gradient : Color(UIColor.lightGray).gradient)
                    .frame(width: 58, height: 58)
                Image(systemName: "person.2.fill")
                    .foregroundColor(.white).font(.headline)
                if let image = group.photo {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 58, height: 58)
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                }
            }
            VStack(alignment: .leading, spacing: 5){
                HStack(spacing: 5){
                    if let title = group.groupName, !title.isEmpty {
                        Text(title)
                            .font((seen || !received) ? .headline : .headline.bold())
                            .foregroundColor((seen || !received) ? (colorScheme == .dark ? .white : .black) : .blue)
                            .lineLimit(1).truncationMode(.tail)
                    } else {
                        let users = group.users ?? []
                        let usernamesString = users.map { $0.username }.joined(separator: ", ")
                        Text(usernamesString)
                            .font((seen || !received) ? .headline : .headline.bold())
                            .foregroundColor((seen || !received) ? (colorScheme == .dark ? .white : .black) : .blue)
                            .lineLimit(1).truncationMode(.tail)
                    }
                    Spacer()
                }
                
                if received {
                   if seen {
                       (Text(Image(systemName: "message")).foregroundColor(.blue).font(.subheadline) + Text("  Recieved - ").font(.caption).foregroundColor(.gray) + Text(textFinal).font(.caption).foregroundColor(.gray)).multilineTextAlignment(.leading)
                   } else {
                       (Text(Image(systemName: "message.fill")).foregroundColor(.blue).font(.subheadline) + Text("  New Chat - ").font(.caption).foregroundColor(.blue).bold() + Text(textFinal).font(.caption).foregroundColor(.gray)).multilineTextAlignment(.leading)
                   }
               } else {
                   if seen {
                       (Text(Image(systemName: "arrowshape.turn.up.forward")).foregroundColor(.red).font(.subheadline) + Text("  Opened - ").font(.caption).foregroundColor(.gray) + Text(textFinal).font(.caption).foregroundColor(.gray)).multilineTextAlignment(.leading)
                   } else {
                       (Text(Image(systemName: "arrowshape.turn.up.forward.fill")).foregroundColor(.blue).font(.subheadline) + Text("  Delivered - ").font(.caption).foregroundColor(.gray) + Text(textFinal).font(.caption).foregroundColor(.gray)).multilineTextAlignment(.leading)
                   }
               }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            VStack(alignment: .trailing, spacing: 4){
                if !dateFinal.isEmpty {
                    Text(dateFinal).font(.caption2).foregroundColor(.gray).scaleEffect(1.3)
                }
                Image(systemName: "bell.slash.fill").foregroundStyle(.gray).font(.headline)
            }.padding(.trailing, 5)
        }
        .frame(height: 75)
        .onAppear {
            setDate()
            setText()
        }
        .onChange(of: updateRowView) { _, _ in
            setDate()
            setText()
        }
    }
    func setDate(){
        if let mytime = group.lastM?.timestamp {
            self.dateFinal = getMessageTime(date: mytime.dateValue())
        }
    }
    func setText(){
        if let id = group.lastM?.id {
            received = !(id.hasPrefix((auth.currentUser?.id ?? "").prefix(6)))
            seen = group.lastM?.seen ?? false
        } else {
            received = false
            seen = true
        }
        
        var person = ""
        if let id = group.lastM?.id {
            let prefix = id.prefix(6)
            if let user = group.users?.first(where: { ($0.id ?? "").hasPrefix(prefix) }) {
                person = user.username
            }
        }
        
        if let text = group.lastM?.text {
            if text.contains("pub!@#$%^&*()"){
                textFinal = "Check out " + String(text.components(separatedBy: "pub!@#$%^&*()").last ?? "")
            } else if group.lastM?.normal != nil {
                if text.contains("left") || text.contains("started chatting"){
                    textFinal = text
                } else {
                    let split = text.components(separatedBy: " ")
                    let first = split.first ?? ""
                    let last = split.last ?? ""
                    textFinal = (first == (auth.currentUser?.username ?? "")) ? "You added \(last)" : "\(first) added \(last)"
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
                if received {
                    textFinal = "You recieved a story"
                } else {
                    textFinal = "You sent a story"
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
            } else if group.lastM?.choice1 != nil {
                if received {
                    textFinal = "You recieved a Poll"
                } else {
                    textFinal = "You sent a Poll"
                }
            } else if text.contains("https://hustle.page/yelp/"){
                if received {
                    textFinal = "You recieved a place recommendation"
                } else {
                    textFinal = "You sent a place recommendation"
                }
            } else if group.lastM?.pinmap != nil && text.isEmpty {
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
        } else if group.lastM?.imageUrl != nil || viewModel.imageMessages.first(where: { $0.0 == group.lastM?.id }) != nil {
            if received {
                textFinal = person.isEmpty ? "You've recieved an image" : "\(person) sent an image"
            } else {
                textFinal = "You sent an image"
            }
        } else if group.lastM?.file != nil || group.lastM?.async != nil {
            if received {
                textFinal = person.isEmpty ? "You've recieved a file" : "\(person) sent a file"
            } else {
                textFinal = "You sent a file"
            }
        } else if group.lastM?.audioURL != nil || viewModel.audioMessages.first(where: { $0.0 == group.lastM?.id }) != nil {
            if received {
                textFinal = person.isEmpty ? "You've recieved audio" : "\(person) sent a voice recording"
            } else {
                textFinal = "You sent audio"
            }
        } else if group.lastM?.videoURL != nil {
            if received {
                textFinal = person.isEmpty ? "You've recieved a video" : "\(person) sent a video"
            } else {
                textFinal = "You sent a video"
            }
        } else if group.lastM?.lat != nil {
            if received {
                textFinal = person.isEmpty ? "You've recieved a location" : "\(person) sent a location"
            } else {
                textFinal = "You sent a location"
            }
        } else {
            if received {
                textFinal = person.isEmpty ? "You've recieved a chat" : "\(person) sent a chat"
            } else {
                textFinal = "You sent a message"
            }
        }
    }
}
