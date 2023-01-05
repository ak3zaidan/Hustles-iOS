import SwiftUI

struct NotificationRow: View {
    @Environment(\.colorScheme) var colorScheme
    let notif: Notification
    @State var dateFinal: String = ""
    var body: some View {
        HStack(alignment: .top){
            Image("nobackorange").resizable().frame(width: 25, height: 38)
                .scaleEffect(1.2)
            VStack {
                HStack {
                    if notif.type == "Comment" {
                        Text("Comment").font(.subheadline).foregroundColor(.white)
                    } else if notif.type == "Group" {
                        Text("Group tag").font(.subheadline).foregroundColor(.white)
                    } else if notif.type == "News" {
                        Text("News tag").font(.subheadline).foregroundColor(.white)
                    } else if notif.type == "Question" {
                        Text("Question tag").font(.subheadline).foregroundColor(.white)
                    } else {
                        Text("Profile Follow").font(.subheadline).foregroundColor(.white)
                    }
                    Spacer()
                    Text(dateFinal).font(.system(size: 16)).foregroundColor(.white)
                    Image(systemName: "envelope").foregroundColor(.blue)
                }
                HStack {
                    if notif.type == "Comment" {
                        NavigationLink {
                            HustleTaggedView(hustleID: notif.tweetID ?? "")
                        } label: {
                            Text("\(notif.tagger) tagged you in a post and said:").font(.system(size: 18)).foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0)).multilineTextAlignment(.leading).bold()
                        }
                    } else if notif.type == "Group" {
                        Text("\(notif.tagger) tagged you in a group (\(notif.groupName ?? "")) and said:").font(.system(size: 18)).multilineTextAlignment(.leading).foregroundColor(.white).bold()
                    } else if notif.type == "News" {
                        Text("\(notif.tagger) tagged you in a news article (\(notif.newsName ?? "")) and said:").font(.system(size: 18)).multilineTextAlignment(.leading).foregroundColor(.white).bold()
                    } else if notif.type == "Question" {
                        NavigationLink {
                            QuestionTaggedView(qID: notif.questionID ?? "")
                        } label: {
                            Text("\(notif.tagger) tagged you in a question and said:").font(.system(size: 18)).foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0)).multilineTextAlignment(.leading).bold()
                        }
                    } else if notif.type == "Question Image" {
                        NavigationLink {
                            QuestionImageTaggedView(qID: notif.questionID ?? "")
                        } label: {
                            Text("\(notif.tagger) tagged you in a question's comments and said:").font(.system(size: 18)).foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0)).multilineTextAlignment(.leading).bold()
                        }
                    } else if notif.type == "Question Text" {
                        NavigationLink {
                            QuestionTaggedView(qID: notif.questionID ?? "")
                        } label: {
                            Text("\(notif.tagger) tagged you in a question's comments and said:").font(.system(size: 18)).foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0)).multilineTextAlignment(.leading).bold()
                        }
                    } else {
                        NavigationLink {
                            ProfileView(showSettings: false, showMessaging: true, uid: notif.taggerUID ?? "", photo: "", user: nil, expand: false, isMain: false)
                        } label: {
                            Text("\(notif.tagger) started following you! Give them a follow back.").font(.system(size: 18)).foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0)).multilineTextAlignment(.leading).bold()
                        }
                    }
                    Spacer()
                }.padding(.top, 2)
                HStack {
                    Text(notif.caption).font(.system(size: 16)).foregroundColor(.gray).multilineTextAlignment(.leading)
                    Spacer()
                }.padding(.top, 1)
            }.padding(.top, 8)
        }
        .onAppear {
            let dateString = notif.timestamp.dateValue().formatted(.dateTime.month().day().year().hour().minute())
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
            if let date = dateFormatter.date(from:dateString){
                if Calendar.current.isDateInToday(date){
                    dateFinal = notif.timestamp.dateValue().formatted(.dateTime.hour().minute())}
                else if Calendar.current.isDateInYesterday(date) { dateFinal = "Yesterday"}
                else{
                    if let dayBetween  = Calendar.current.dateComponents([.day], from: notif.timestamp.dateValue(), to: Date()).day{
                        dateFinal = String(dayBetween + 1) + "d"
                    }
                }
            }
        }
    }
}

struct NotificationRowColor: View {
    @Environment(\.colorScheme) var colorScheme
    let notif: Notification
    @State var dateFinal: String = ""
    var body: some View {
        HStack(alignment: .top){
            Image("nobackorange").resizable().frame(width: 25, height: 38)
                .scaleEffect(1.2)
            VStack {
                HStack {
                    if notif.type == "Comment" {
                        Text("Comment").font(.subheadline)
                    } else if notif.type == "Group" {
                        Text("Group tag").font(.subheadline)
                    } else if notif.type == "News" {
                        Text("News tag").font(.subheadline)
                    } else if notif.type == "Question" {
                        Text("Question tag").font(.subheadline)
                    } else {
                        Text("Profile Follow").font(.subheadline)
                    }
                    Spacer()
                    Text(dateFinal).font(.system(size: 16))
                    Image(systemName: "envelope").foregroundColor(.blue)
                }
                HStack {
                    if notif.type == "Comment" {
                        NavigationLink {
                            HustleTaggedView(hustleID: notif.tweetID ?? "")
                        } label: {
                            Text("\(notif.tagger) tagged you in a post and said:").font(.system(size: 18)).foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0)).multilineTextAlignment(.leading).bold()
                        }
                    } else if notif.type == "Group" {
                        Text("\(notif.tagger) tagged you in a group (\(notif.groupName ?? "")) and said:").font(.system(size: 18)).multilineTextAlignment(.leading).bold()
                    } else if notif.type == "News" {
                        Text("\(notif.tagger) tagged you in a news article (\(notif.newsName ?? "")) and said:").font(.system(size: 18)).multilineTextAlignment(.leading).bold()
                    } else if notif.type == "Question" {
                        NavigationLink {
                            QuestionTaggedView(qID: notif.questionID ?? "")
                        } label: {
                            Text("\(notif.tagger) tagged you in a question and said:").font(.system(size: 18)).foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0)).multilineTextAlignment(.leading).bold()
                        }
                    } else if notif.type == "Question Image" {
                        NavigationLink {
                            QuestionImageTaggedView(qID: notif.questionID ?? "")
                        } label: {
                            Text("\(notif.tagger) tagged you in a question's comments and said:").font(.system(size: 18)).foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0)).multilineTextAlignment(.leading).bold()
                        }
                    } else if notif.type == "Question Text" {
                        NavigationLink {
                            QuestionTaggedView(qID: notif.questionID ?? "")
                        } label: {
                            Text("\(notif.tagger) tagged you in a question's comments and said:").font(.system(size: 18)).foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0)).multilineTextAlignment(.leading).bold()
                        }
                    } else {
                        NavigationLink {
                            ProfileView(showSettings: false, showMessaging: true, uid: notif.taggerUID ?? "", photo: "", user: nil, expand: false, isMain: false)
                        } label: {
                            Text("\(notif.tagger) started following you! Give them a follow back.").font(.system(size: 18)).foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0)).multilineTextAlignment(.leading).bold()
                        }
                    }
                    Spacer()
                }.padding(.top, 2)
                HStack {
                    Text(notif.caption).font(.system(size: 16)).foregroundColor(.gray).multilineTextAlignment(.leading)
                    Spacer()
                }.padding(.top, 1)
            }.padding(.top, 8)
        }
        .onAppear {
            let dateString = notif.timestamp.dateValue().formatted(.dateTime.month().day().year().hour().minute())
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
            if let date = dateFormatter.date(from:dateString){
                if Calendar.current.isDateInToday(date){
                    dateFinal = notif.timestamp.dateValue().formatted(.dateTime.hour().minute())}
                else if Calendar.current.isDateInYesterday(date) { dateFinal = "Yesterday"}
                else{
                    if let dayBetween  = Calendar.current.dateComponents([.day], from: notif.timestamp.dateValue(), to: Date()).day{
                        dateFinal = String(dayBetween + 1) + "d"
                    }
                }
            }
        }
    }
}

struct QuestionTaggedView: View {
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State var question: Question? = nil
    let qID: String
    var body: some View {
        VStack {
            if let question = question {
                QuestionSingleView(disableUser: false, question: question, isSheet: false)
            } else {
                Loader(flip: true).id("\(UUID())")
            }
        }
        .navigationBarBackButtonHidden(question == nil ? false : true)
        .onAppear {
            if !qID.isEmpty {
                if let id = auth.currentUser?.id, let profile = profile.users.first(where: { $0.user.id ?? "" == id }){
                    if let element = profile.questions?.first(where: { $0.id ?? "" == qID }) {
                        question = element
                    }
                }
                if question == nil {
                    MessageService().get_question_tag(id: qID) { quest in
                        self.question = quest
                    }
                }
            }
        }
    }
}

struct QuestionImageTaggedView: View {
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State var question: Question? = nil
    let qID: String
    
    var body: some View {
        VStack {
            if let question = question {
                ImageQuestionView(question: question, disableUser: false, shouldShowTab: true)
                    .onAppear {
                        withAnimation {
                            self.popRoot.hideTabBar = true
                        }
                    }
                    .onDisappear {
                        withAnimation {
                            self.popRoot.hideTabBar = false
                        }
                    }
            } else {
                Loader(flip: true).id("\(UUID())")
            }
        }
        .navigationBarBackButtonHidden(question == nil ? false : true)
        .onAppear {
            if !qID.isEmpty {
                if let id = auth.currentUser?.id, let profile = profile.users.first(where: { $0.user.id ?? "" == id }){
                    if let element = profile.questions?.first(where: { $0.id ?? "" == qID }) {
                        question = element
                    }
                }
                if question == nil {
                    MessageService().get_question_tag(id: qID) { quest in
                        self.question = quest
                    }
                }
            }
        }
    }
}

struct HustleTaggedView: View {
    @Namespace private var animation
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var newsAnimation
    @State var hustle: Tweet? = nil
    let hustleID: String
    
    var body: some View {
        VStack {
            if let post = hustle {
                TweetRowView(tweet: post, edit: false, canShow: true, canSeeComments: true, map: false, currentAudio: .constant(""), isExpanded: .constant(false), animationT: animation, seenAllStories: false, isMain: false, showSheet: .constant(false), newsAnimation: newsAnimation).padding()
                Spacer()
            } else {
                Loader(flip: true).id("\(UUID())")
            }
        }
        .onAppear {
            if !hustleID.isEmpty {
                if let id = auth.currentUser?.id, let profile = profile.users.first(where: { $0.user.id ?? "" == id }){
                    if let element = profile.tweets?.first(where: { $0.id ?? "" == id }) {
                        hustle = element
                    }
                }
                if hustle == nil {
                    MessageService().get_hustle_tag(id: hustleID) { element in
                        hustle = element
                    }
                }
            }
        }
    }
}
