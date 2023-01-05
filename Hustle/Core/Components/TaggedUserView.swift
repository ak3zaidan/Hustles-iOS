import SwiftUI
import Kingfisher

struct TaggedUserView: View {
    
    struct UserData: Hashable {
        let photo: String?
        let name: String
        let username: String
    }
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var message: MessageViewModel
    @EnvironmentObject var group: GroupViewModel
    @EnvironmentObject var comment: CommentViewModel
    @EnvironmentObject var comment2: VideoCommentModel
    @EnvironmentObject var comment3: QuestionCommentModel
    @EnvironmentObject var news: ExploreViewModel
    @EnvironmentObject var ask: QuestionModel
    @Binding var text: String
    @Binding var target: String
    @State var tag_arr: [UserData] = []
    let commentID: String?
    let newsID: String?
    let newsRepID: String?
    let questionID: String?
    let groupID: String?
    
    @Binding var selectedtag: String
    
    var body: some View {
        VStack {
            if !tag_arr.isEmpty || !target.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        if tag_arr.isEmpty {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                selectedtag = target
                            } label: {
                                Text("Tag \(target)?").font(Font.system(size: 15, weight: Font.Weight.medium, design: Font.Design.default)).padding(5)
                            }.background(.blue.gradient.opacity(0.5)).cornerRadius(10)
                        } else {
                            if tag_arr.first(where: { $0.username == target }) == nil && !target.isEmpty {
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    selectedtag = target
                                } label: {
                                    Text("Tag \(target)?").font(Font.system(size: 15, weight: Font.Weight.medium, design: Font.Design.default)).padding(5)
                                }.background(.blue.gradient.opacity(0.5)).cornerRadius(10)
                            }
                            ForEach(tag_arr, id: \.self) { tag in
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    selectedtag = tag.username
                                } label: {
                                    userCover(photo: tag.photo, name: tag.name, username: tag.username)
                                }
                            }
                        }
                    }.padding(.horizontal)
                }
                .frame(height: 55)
                .background(.ultraThinMaterial)
                .scrollIndicators(.hidden)
            }
        }
        .onAppear {
            getPossibleUsers()
        }
        .onChange(of: text) { _, _ in
            find()
        }
    }
    func find(){
        var searching = ""
        if let range = text.range(of: "@(\\S+)", options: .regularExpression) {
            let matchedSubstring = text[range]
            searching = String(matchedSubstring.dropFirst(1)).lowercased()
        }
        target = searching
        
        var has: [UserData] = []
        var doesnt: [UserData] = []
        tag_arr.forEach { element in
            if element.name.lowercased().contains(searching) || element.username.lowercased().contains(searching){
                has.append(element)
            } else {
                doesnt.append(element)
            }
        }
        tag_arr = has + doesnt
    }
    func getPossibleUsers(){
        if let id = groupID {
            if let element = group.groups.first(where: { $0.1.id == id }) {
                element.1.messages?.forEach({ message in
                    message.messages.forEach { text in
                        if !tag_arr.contains(where: { $0.username == text.username }) && text.uid != auth.currentUser?.id ?? "" {
                            tag_arr.append(UserData(photo: text.profilephoto, name: "", username: text.username))
                        }
                    }
                })
            } else if let element = group.groupsDev.first(where: { $0.id == id }){
                element.messages?.forEach({ message in
                    if !tag_arr.contains(where: { $0.username == message.username }) && message.uid != auth.currentUser?.id ?? "" {
                        tag_arr.append(UserData(photo: message.profilephoto, name: "", username: message.username))
                    }
                })
            }
        }
        if let id = questionID, let question = ask.new.first(where: { $0.id ?? "NA" == id }){
            if question.uid != auth.currentUser?.id ?? "" {
                if !tag_arr.contains(where: { $0.username == question.username }) {
                    tag_arr.append(UserData(photo: question.profilePhoto, name: "", username: question.username))
                }
            }
        }
        if let id = questionID, let question = ask.top.first(where: { $0.id ?? "NA" == id }){
            if question.uid != auth.currentUser?.id ?? "" {
                if !tag_arr.contains(where: { $0.username == question.username }) {
                    tag_arr.append(UserData(photo: question.profilePhoto, name: "", username: question.username))
                }
            }
        }
        if let id = questionID, let question = ask.allQuestions.first(where: { $0.0 == id}){
            question.1.forEach { answer in
                if answer.id ?? "" != auth.currentUser?.id ?? "" {
                    if !tag_arr.contains(where: { $0.username == answer.username }) {
                        tag_arr.append(UserData(photo: answer.profilePhoto, name: "", username: answer.username))
                    }
                }
            }
        }
        if let id = newsID, let element = news.NewsGroups.first(where: { $0.0 == id }) {
            element.1.forEach { reply in
                if !tag_arr.contains(where: { $0.username == reply.username }) {
                    tag_arr.append(UserData(photo: nil, name: "", username: reply.username ?? ""))
                }
            }
        }
        if let id = newsRepID, let element = news.opinion_Reply.first(where: { $0.0 == id }){
            element.1.forEach { reply in
                if !tag_arr.contains(where: { $0.username == reply.username }) {
                    tag_arr.append(UserData(photo: nil, name: "", username: reply.username ?? ""))
                }
            }
        }
        if let id = commentID {
            if let element = comment.comments.first(where: { $0.id == id }) {
                element.comments.forEach { comment in
                    if !tag_arr.contains(where: { $0.username == comment.username }) {
                        tag_arr.append(UserData(photo: comment.profilephoto, name: "", username: comment.username))
                    }
                }
            }
            if let element = comment2.comments.first(where: { $0.id == id }) {
                element.comments.forEach { comment in
                    if !tag_arr.contains(where: { $0.username == comment.username }) {
                        tag_arr.append(UserData(photo: comment.profilephoto, name: "", username: comment.username))
                    }
                }
            }
            if let element = comment3.comments.first(where: { $0.id == id }) {
                element.comments.forEach { comment in
                    if !tag_arr.contains(where: { $0.username == comment.username }) {
                        tag_arr.append(UserData(photo: comment.profilephoto, name: "", username: comment.username))
                    }
                }
            }
        }
        message.chats.forEach { chat in
            if !tag_arr.contains(where: { $0.username == chat.user.username }) {
                tag_arr.append(UserData(photo: chat.user.profileImageUrl, name: chat.user.fullname, username: chat.user.username))
            }
        }
        profile.users.forEach { element in
            if (auth.currentUser?.id ?? "") != (element.user.id ?? "") {
                if !tag_arr.contains(where: { $0.username == element.user.username }) {
                    tag_arr.append(UserData(photo: element.user.profileImageUrl, name: element.user.fullname, username: element.user.username))
                }
            }
        }
    }
    func userCover(photo: String?, name: String, username: String) -> some View {
        HStack(spacing: 4){
            if let photo = photo {
                KFImage(URL(string: photo))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width:36, height: 36)
                    .clipShape(Circle())
            } else {
                ZStack(alignment: .center){
                    Image(systemName: "circle.fill")
                        .resizable()
                        .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                        .frame(width: 36, height: 36)
                    Image(systemName: "questionmark")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 11, height: 15)
                }
            }
            VStack(spacing: 2){
                HStack {
                    Text("@\(username)").font(.system(size: 18)).foregroundColor(.blue)
                    Spacer()
                }
                if !name.isEmpty {
                    HStack {
                        Text(name).font(.system(size: 15)).foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct personView: View {
    let size: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .center){
            Circle()
                .fill(colorScheme == .dark ? Color(UIColor.darkGray).gradient : Color(UIColor.lightGray).gradient)
                .frame(width: size, height: size)
            Image(systemName: "person.fill")
                .foregroundColor(.white).font(.headline)
        }
    }
}

struct personLetterView: View {
    let size: CGFloat
    let letter: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .center){
            Circle()
                .fill(colorScheme == .dark ? Color(UIColor.darkGray).gradient : Color(UIColor.lightGray).gradient)
                .frame(width: size, height: size)
            Text(letter.uppercased())
                .foregroundColor(.white).font(.title3).bold()
        }
    }
}

struct personLetterViewColor: View {
    let size: CGFloat
    let letter: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .center){
            Circle()
                .fill(color.gradient)
                .frame(width: size, height: size)
            Text(letter.uppercased())
                .foregroundColor(.white).font(.title2).bold()
        }
    }
}

extension Color {
    static let lightBlue = Color(red: 173/255, green: 216/255, blue: 230/255) // Light Blue
    static let lightGreen = Color(red: 144/255, green: 238/255, blue: 144/255) // Light Green
    static let lightPurple = Color(red: 216/255, green: 191/255, blue: 216/255) // Light Purple
    static let lightTurquoise = Color(red: 175/255, green: 238/255, blue: 238/255) // Light Turquoise
    static let lightPink = Color(red: 255/255, green: 182/255, blue: 193/255) // Light Pink
    static let lightOrange = Color(red: 255/255, green: 218/255, blue: 185/255) // Light Orange
    static let lightRuby = Color(red: 229/255, green: 115/255, blue: 115/255) // Light Ruby
    static let lightMagenta = Color(red: 255/255, green: 119/255, blue: 255/255) // Light Magenta
    static let lightCoral = Color(red: 240/255, green: 128/255, blue: 128/255) // Light Coral
    static let lightSalmon = Color(red: 255/255, green: 160/255, blue: 122/255) // Light Salmon
    static let lightSeaGreen = Color(red: 32/255, green: 178/255, blue: 170/255) // Light Sea Green
    static let lightSteelBlue = Color(red: 176/255, green: 196/255, blue: 222/255) // Light Steel Blue

    static var randomLightColor: Color {
        let colors: [Color] = [
            .lightBlue,
            .lightGreen,
            .lightPurple,
            .lightTurquoise,
            .lightPink,
            .lightOrange,
            .lightRuby,
            .lightMagenta,
            .lightCoral,
            .lightSalmon,
            .lightSeaGreen,
            .lightSteelBlue
        ]
        let randomIndex = Int(arc4random_uniform(UInt32(colors.count)))
        return colors[randomIndex]
    }
}
