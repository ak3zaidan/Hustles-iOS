import SwiftUI
import Firebase
import Kingfisher

struct QuestionSingleView: View, KeyboardReadable {
    @EnvironmentObject var viewModel: QuestionModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var pop: PopToRoot
    @EnvironmentObject var profile: ProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    let disableUser: Bool
    @State var dateFinal: String = "Asked recently"
    @State var tooLowElo: Bool = false
    @State var tooLowEloVote: Bool = false
    @State var cantVoteMine: Bool = false
    @State var alreadyAnswered: Bool = false
    @State var showAnswerBox: Bool = false
    @State var answer: String = ""
    @State var showPostButton: Bool = false
    @State var goodAnswer: String = ""
    @State var delete: Bool = false
    @State private var offset: Double = 0
    @State private var canROne = false
    @State private var tag = ""
    @State private var target = ""
    @State private var keyBoardVisible = false
    @State var showReport: Bool = false
    let question: Question
    let isSheet: Bool
    @State var showComments: Bool = false
    @State var showFixSheet = false
    @State var showAI = false
    
    var body: some View {
        ZStack {
            VStack {
                Text(question.title ?? "").font(.system(size: 20)).bold().padding(.horizontal, 5).multilineTextAlignment(.leading)
                ScrollView {
                    if (offset <= -170) {
                        HStack {
                            Spacer()
                            Loader(flip: true)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        withAnimation {
                                            offset = 100
                                        }
                                    }
                                }
                            Spacer()
                        }
                        Spacer()
                    }
                    LazyVStack(pinnedViews: [.sectionHeaders]){
                        Section {
                            VStack {
                                ScrollView {
                                    LinkedText(question.caption, tip: false, isMess: nil)
                                        .font(.system(size: 17))
                                        .padding(5)
                                }
                                .scrollIndicators(.hidden)
                                .frame(maxHeight: 150)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5).stroke(colorScheme == .dark ? .white : .black)
                                }
                                HStack {
                                    if let x = viewModel.allQuestions.first(where: { $0.0 == question.id ?? "" }), !x.1.isEmpty {
                                        Text("\(x.1.count) Answers").font(.title3).bold()
                                    } else {
                                        Text("\(question.answersCount ?? 0) Answers").font(.title3).bold()
                                    }
                                    Spacer()
                                    Button {
                                        if let user = auth.currentUser {
                                            withAnimation {
                                                if user.elo < 600 {
                                                    tooLowElo.toggle()
                                                } else if let element = viewModel.allQuestions.first(where: { $0.0 == question.id ?? "" }), element.1.contains(where: { $0.id == user.id }) {
                                                    alreadyAnswered.toggle()
                                                } else {
                                                    showAnswerBox.toggle()
                                                }
                                            }
                                        }
                                    } label: {
                                        Text("Answer").font(.subheadline).bold().foregroundColor(.white).padding(.vertical, 4).padding(.horizontal, 6)
                                            .background {
                                                RoundedRectangle(cornerRadius: 5).fill(.blue.gradient)
                                            }
                                    }
                                    Spacer()
                                    HStack(spacing: 5){
                                        let count = viewModel.upVotes.contains(question.id ?? "") ? question.votes + 1 : viewModel.downVotes.contains(question.id ?? "") ? question.votes - 1 : question.votes
                                        Text("\(count)").font(.title).bold().foregroundColor(.blue)
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 20).foregroundColor(Color(UIColor.secondarySystemBackground))
                                            let id = auth.currentUser?.id?.suffix(4) ?? ""
                                            let upvotes = question.upvoteIds ?? []
                                            let downVotes = question.downVoteIds ?? []
                                            let downVotesContains = downVotes.contains(String(id)) || viewModel.downVotes.contains(question.id ?? "")
                                            let upVotesContains = upvotes.contains(String(id))  || viewModel.upVotes.contains(question.id ?? "")
                                            VStack {
                                                Button {
                                                    if auth.currentUser?.id ?? "" == question.uid {
                                                        cantVoteMine = true
                                                    } else if auth.currentUser?.elo ?? 0 >= 600 {
                                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                        viewModel.voteQuestion(id: question.id, val: 1)
                                                        viewModel.upVotes.append(question.id ?? "")
                                                    } else {
                                                        withAnimation {
                                                            tooLowEloVote = true
                                                        }
                                                    }
                                                } label: {
                                                    if upVotesContains {
                                                        Triangle().fill(.blue.gradient).frame(width: 30, height: 20)
                                                    } else {
                                                        Triangle().fill(.blue.gradient).opacity(0.4).frame(width: 30, height: 20)
                                                    }
                                                }.disabled(downVotesContains || upVotesContains)
                                                Spacer()
                                                Button {
                                                    if auth.currentUser?.id ?? "" == question.uid {
                                                        cantVoteMine = true
                                                    } else if auth.currentUser?.elo ?? 0 >= 600 {
                                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                        viewModel.voteQuestion(id: question.id, val: -1)
                                                        viewModel.downVotes.append(question.id ?? "")
                                                    } else {
                                                        withAnimation {
                                                            tooLowEloVote = true
                                                        }
                                                    }
                                                } label: {
                                                    if downVotesContains {
                                                        Triangle().fill(.blue.gradient).frame(width: 30, height: 20).rotationEffect(.degrees(180))
                                                    } else {
                                                        Triangle().fill(.blue.gradient).opacity(0.4).frame(width: 30, height: 20).rotationEffect(.degrees(180))
                                                    }
                                                }.disabled(downVotesContains || upVotesContains)
                                            }.padding(.vertical, 13)
                                        }.frame(width: 50, height: 80)
                                    }
                                }
                                if tooLowElo || alreadyAnswered || tooLowEloVote || cantVoteMine {
                                    ToastView(message: tooLowElo ? "You need 600+ ELO to Answer" : alreadyAnswered ? "You already answered here" : tooLowEloVote ? "You need 600+ ELO to vote" : "You cant vote your own post")
                                        .onAppear {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                withAnimation {
                                                    cantVoteMine = false
                                                    tooLowEloVote = false
                                                    tooLowElo = false
                                                    alreadyAnswered = false
                                                }
                                            }
                                        }
                                }
                                VStack(spacing: 0){
                                    if let element = viewModel.allQuestions.first(where: { $0.0 == question.id ?? "" }){
                                        ForEach(element.1) { answer in
                                            AnswerRowView(answer: answer, question: question, disableUser: disableUser)
                                                .padding(.bottom, 10)
                                        }
                                    }
                                    Color.clear.frame(height: 55)
                                }
                            }
                        } header: {
                            HStack {
                                VStack{
                                    HStack {
                                        NavigationLink {
                                            ProfileView(showSettings: false, showMessaging: true, uid: question.uid, photo: "", user: nil, expand: true, isMain: false)
                                                .dynamicTypeSize(.large)
                                        } label: {
                                            if let image = question.profilePhoto {
                                                ZStack {
                                                    personView(size: 38)
                                                    KFImage(URL(string: image))
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 38, height: 38)
                                                        .clipShape(Circle())
                                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                                }
                                            } else {
                                                personView(size: 40)
                                            }
                                        }.disabled(disableUser)
                                        VStack(alignment: .leading, spacing: 3){
                                            HStack {
                                                NavigationLink {
                                                    ProfileView(showSettings: false, showMessaging: true, uid: question.uid, photo: "", user: nil, expand: true, isMain: false)
                                                        .dynamicTypeSize(.large)
                                                } label: {
                                                    Text(question.username).font(.system(size: 18)).bold().foregroundColor(colorScheme == .dark ? .white : .black)
                                                }.disabled(disableUser)
                                                if let id = auth.currentUser?.dev, id.contains("(DWK@)2))&DNWIDN:") {
                                                    Button {
                                                        delete.toggle()
                                                    } label: {
                                                        Image(systemName: "trash").scaleEffect(0.8).foregroundColor(.red)
                                                    }.padding(.leading, 8)
                                                } else if let uid = auth.currentUser?.id, question.uid == uid {
                                                    Button {
                                                        delete.toggle()
                                                    } label: {
                                                        Image(systemName: "trash").scaleEffect(0.8).foregroundColor(.red)
                                                    }.padding(.leading, 8)
                                                } else {
                                                    Button {
                                                        showReport.toggle()
                                                    } label: {
                                                        Image(systemName: "ellipsis").font(.system(size: 25))
                                                    }.padding(.leading, 8)
                                                }
                                            }
                                            Text(dateFinal).font(.subheadline).foregroundColor(.gray)
                                        }.padding(.trailing, 20)
                                    }
                                }
                                Spacer()
                                Button {
                                    showComments.toggle()
                                } label: {
                                    Image(systemName: "ellipsis.message.fill").foregroundStyle(colorScheme == .dark ? .white : .gray).font(.title)
                                }.padding(.trailing, 10)
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Image(systemName: "xmark").font(.title).foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                            }.padding(.vertical, 5).background(isSheet ? Color(.systemBackground) : colorScheme == .dark ? .black : .white)
                        }.padding(.horizontal)
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self,
                                               value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) { value in
                        offset = value
                    }
                }
                .refreshable { }
                .scrollIndicators(.hidden)
            }
            .blur(radius: showAnswerBox ? 10 : 0)
            if showAnswerBox {
                responseView()
            }
        }
        .sheet(isPresented: $showFixSheet, content: {
            RecommendTextView(oldText: $answer)
        })
        .sheet(isPresented: $showComments, content: {
            if #available(iOS 16.4, *){
                QuestionCommentView(question: question, canShowProfile: true, imageQ: false)
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(40)
            } else {
                QuestionCommentView(question: question, canShowProfile: true, imageQ: false)
                    .presentationDetents([.medium, .large])
            }
        })
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
            keyBoardVisible = newIsKeyboardVisible
        }
        .onChange(of: tag) { _, _ in
            if !tag.isEmpty {
                if let range = answer.range(of: "@") {
                    let final = answer.replacingCharacters(in: range, with: "@\(tag) ")
                    answer = removeSecondOccurrence(of: target, in: final)
                    target = ""
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: pop.tap, { _, _ in
            if pop.tap == 4 {
                presentationMode.wrappedValue.dismiss()
                pop.tap = 0
            }
        })
        .alert("Options", isPresented: $delete) {
            Button("Delete Question", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if let element = viewModel.allQuestions.first(where: { $0.0 == question.id ?? "" }){
                    viewModel.deleteQuestion(id: question.id, count: element.1.count, image1: question.image1, image2: question.image2)
                } else {
                    viewModel.deleteQuestion(id: question.id, count: question.answersCount ?? 0, image1: question.image1, image2: question.image2)
                }
                viewModel.new.removeAll(where: { $0.id == question.id })
                viewModel.top.removeAll(where: { $0.id == question.id })
                if let uid = auth.currentUser?.id, let index = profile.users.firstIndex(where: { $0.user.id == uid }) {
                    profile.users[index].questions?.removeAll(where: { $0.id == question.id })
                }
                presentationMode.wrappedValue.dismiss()
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Report this content?", isPresented: $showReport) {
            Button("Report", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if let id = question.id {
                    UserService().reportContent(type: "Job", postID: id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onDisappear { canROne = false }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                canROne = true
            }
            viewModel.getAnswers(questionID: question.id, refresh: false, count: question.answersCount ?? 0)
            let dateString = question.timestamp.dateValue().formatted(.dateTime.month().day().year().hour().minute())
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
            if let date = dateFormatter.date(from:dateString){
                if Calendar.current.isDateInToday(date){
                    dateFinal = "Asked today at \(question.timestamp.dateValue().formatted(.dateTime.hour().minute()))"
                }
                else if Calendar.current.isDateInYesterday(date) {
                    dateFinal = "Asked Yesterday"}
                else{
                    if let dayBetween  = Calendar.current.dateComponents([.day], from: question.timestamp.dateValue(), to: Date()).day{
                        dateFinal = "Asked \(dayBetween + 1) days ago"
                    }
                }
            }
        }
        .onChange(of: offset) { _, _ in
            if offset <= -170 && canROne {
                viewModel.getAnswers(questionID: question.id, refresh: true, count: 0)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                canROne = false
                Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { _ in
                   canROne = true
                }
            }
        }
    }
    func responseView() -> some View {
        ZStack {
            Color.gray.ignoresSafeArea().opacity(0.001).onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                withAnimation {
                    showAnswerBox.toggle()
                }
            }
            VStack {
                VStack(spacing: 0){
                    HStack {
                        Text("Question").font(.system(size: 18)).bold()
                        Spacer()
                    }.padding(.leading, 5)
                    ScrollView {
                        LinkedText(question.caption, tip: false, isMess: nil)
                            .font(.system(size: 17)).padding(5)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 150)
                    .frame(width: widthOrHeight(width: true) * 0.9)
                    .background(colorScheme == .dark ? Color(UIColor.darkGray) : .white)
                    .cornerRadius(5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5).stroke(colorScheme == .dark ? .white : .black)
                    }
                    ZStack(alignment: .bottom) {
                        Rectangle().frame(width: 2, height: 60).foregroundColor(colorScheme == .dark ? .white : .black)
                        HStack {
                            Text("Answer").font(.system(size: 18)).bold()
                            Spacer()
                        }.padding(.leading, 5)
                    }
                    ZStack(alignment: .topLeading){
                        if answer.isEmpty {
                            Text("Your answer goes here").font(.system(size: 16)).foregroundColor(.gray).padding(.top, 12).padding(.leading)
                        }
                        TextField("", text: $answer, axis: .vertical)
                            .tint(.blue)
                            .lineLimit(7)
                            .padding(.leading)
                            .frame(width: widthOrHeight(width: true) * 0.9)
                            .frame(minHeight: 45)
                            .onChange(of: answer) { _, _ in
                                if !tag.isEmpty && !answer.contains("@\(tag)") {
                                    tag = ""
                                }
                                goodAnswer = inputChecker().myInputChecker(withString: answer, withLowerSize: 30, withUpperSize: 800, needsLower: true)
                                withAnimation {
                                    if goodAnswer.isEmpty {
                                        showPostButton = true
                                    } else {
                                        showPostButton = false
                                    }
                                }
                                
                                if answer.count > 30 && !showAI {
                                    withAnimation(.easeInOut(duration: 0.15)){
                                        showAI = true
                                    }
                                } else if answer.count <= 30 && showAI {
                                    withAnimation(.easeInOut(duration: 0.15)){
                                        showAI = false
                                    }
                                }
                            }
                    }
                    .background(colorScheme == .dark ? Color(UIColor.darkGray) : .white)
                    .cornerRadius(5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5).stroke(colorScheme == .dark ? .white : .black)
                    }
                    if showAI {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.15)){
                                showAI = false
                            }
                            showFixSheet = true
                        } label: {
                            HStack {
                                LottieView(loopMode: .loop, name: "finite")
                                    .scaleEffect(0.05)
                                    .frame(width: 25, height: 10)
                                Text("Improve answer with Hustles AI.")
                                    .font(.system(size: 15)).bold()
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            }
                            .padding(8)
                            .background(.ultraThickMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.blue, lineWidth: 1.0)
                            }
                        }.transition(.scale.combined(with: .opacity)).padding(.top, 5)
                    }
                    Spacer()
                    Text(goodAnswer).font(.subheadline).foregroundColor(.red).padding(.bottom)
                    if showPostButton {
                        Button {
                            if let user = auth.currentUser {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                let new = Answer(id: user.id, username: user.username, profilePhoto: user.profileImageUrl, caption: answer, votes: 0, timestamp: Timestamp())
                                if let x = viewModel.allQuestions.firstIndex(where: { $0.0 == question.id ?? "" }){
                                    viewModel.allQuestions[x].1.insert(new, at: 0)
                                }
                                viewModel.uploadAnswer(questionID: question.id, caption: answer, username: user.username, profilePhoto: user.profileImageUrl)
                                if !tag.isEmpty {
                                    pop.alertImage = "tag.fill"
                                    pop.alertReason = "Tagged user notified"
                                    withAnimation {
                                        pop.showAlert = true
                                    }
                                    viewModel.tagUserQuestion(myUsername: user.username, otherUsername: tag, message: answer, questionID: question.id)
                                    tag = ""
                                }
                                answer = ""
                                withAnimation {
                                    showAnswerBox = false
                                }
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 5).foregroundColor(.indigo)
                                .overlay {
                                    Text("Post").font(.system(size: 18)).bold()
                                }
                        }.frame(height: 40).padding(.bottom, keyBoardVisible ? 10 : 60)
                    }
                }.padding(.top, 20).padding(.horizontal)
                if keyBoardVisible && answer.contains("@") && tag.isEmpty {
                    TaggedUserView(text: $answer, target: $target, commentID: nil, newsID: nil, newsRepID: nil, questionID: question.id, groupID: nil, selectedtag: $tag)
                }
            }
        }
    }
}
