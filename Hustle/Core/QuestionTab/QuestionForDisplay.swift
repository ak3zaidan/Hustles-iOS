import SwiftUI
import Kingfisher
import Firebase

struct QuestionForDisplay: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: QuestionModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    let question: Question
    let disableUser: Bool
    @State var dateFinal: String = "Asked recently"
    @State var caption: String = ""
    @State var show = false
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedImage: UIImage?
    @State private var questionImage: Image?
    @State var showImagePicker = false
    @State private var delete = false
    @State var tooLowElo: Bool = false
    @State var tooLowEloVote: Bool = false
    @State var cantVoteMine: Bool = false
    @State var alreadyAnswered: Bool = false
    @State var showReport: Bool = false
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("Asked by:").font(.system(size: 18))
                    NavigationLink {
                        ProfileView(showSettings: false, showMessaging: true, uid: question.uid, photo: "", user: nil, expand: true, isMain: false).dynamicTypeSize(.large)
                    } label: {
                        Text(question.username).foregroundColor(.blue).font(.system(size: 18)).bold()
                        if let image = question.profilePhoto {
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width:30, height: 30)
                                .clipShape(Circle())
                                .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                        } else {
                            ZStack(alignment: .center){
                                Image(systemName: "circle.fill")
                                    .resizable()
                                    .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                                    .frame(width: 35, height: 35)
                                Image(systemName: "questionmark")
                                    .resizable()
                                    .foregroundColor(.white)
                                    .frame(width: 12, height: 15)
                            }
                        }
                    }.disabled(disableUser)
                    if let uid = auth.currentUser?.id, question.uid == uid {
                        Button {
                            delete.toggle()
                        } label: {
                            Image(systemName: "trash").foregroundColor(.red)
                        }.padding(.leading)
                    }
                    if let id = auth.currentUser?.dev, id.contains("(DWK@)2))&DNWIDN:") {
                        Button {
                            delete.toggle()
                        } label: {
                            Image(systemName: "trash").scaleEffect(0.8).foregroundColor(.red)
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
                }.padding(.top, 20).padding(.horizontal)
                HStack {
                    Text(dateFinal).foregroundColor(.gray).font(.subheadline)
                    Spacer()
                }.padding(.horizontal)
                VStack {
                    HStack {
                        Text("Question Description:").bold().font(.system(size: 19))
                        Spacer()
                    }
                    LinkedText(question.caption, tip: false, isMess: nil).padding()
                        .background(.orange.opacity(0.3)).cornerRadius(20)
                }.padding(.horizontal, 20).padding(.top)
                HStack {
                    if auth.currentUser?.id ?? "NA" != question.uid {
                        Button {
                            showReport.toggle()
                        } label: {
                            Image(systemName: "ellipsis").font(.system(size: 25))
                        }
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
                                    show.toggle()
                                }
                            }
                        }
                    } label: {
                        Text("Answer").font(.subheadline).foregroundColor(.white)
                            .padding(.horizontal).padding(.vertical, 8).background(.blue).cornerRadius(12)
                    }
                }.padding(.horizontal).padding(.top)
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
                if show {
                    Divider().overlay(colorScheme == .dark ? .white : .gray).padding(.horizontal).padding(.vertical, 30)
                    HStack {
                        TextArea("answer...", text: $caption)
                            .frame(height: 130)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10) .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
                            }
                    }.padding(.horizontal)
                    HStack {
                        Button {
                            if selectedImage != nil {
                                selectedImage = nil
                                questionImage = nil
                            } else {
                                showImagePicker.toggle()
                            }
                        } label: {
                            if let image = questionImage {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(10)
                                    .clipped()
                            } else {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .frame(width: 100, height: 100)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue, lineWidth: 1)
                                    }
                            }
                        }
                        Button {
                            if let user = auth.currentUser {
                                let tempCap = caption
                                let tampPhoto = selectedImage
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                viewModel.uploadAnswerImage(image: tampPhoto, questionID: question.id, caption: tempCap, username: user.username, profilePhoto: user.profileImageUrl) { loc in
                                    var new = Answer(id: user.id, username: user.username, profilePhoto: user.profileImageUrl, caption: tempCap, timestamp: Timestamp())
                                    if !loc.isEmpty { new.image = loc }
                                    if let x = viewModel.allQuestions.firstIndex(where: { $0.0 == question.id ?? "" }){
                                        viewModel.allQuestions[x].1.insert(new, at: 0)
                                    }
                                }
                                selectedImage = nil
                                questionImage = nil
                                caption = ""
                                withAnimation {
                                    show = false
                                }
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 10).foregroundColor(.indigo)
                                .overlay {
                                    Text("Post").font(.system(size: 18)).bold().foregroundColor(selectedImage == nil && caption.count < 50 ? .gray : .white)
                                }
                        }
                        .frame(width: 100, height: 100)
                        .disabled(selectedImage == nil && caption.count < 50)
                    }
                }
                Spacer()
            }
        }
        .gesture (
            DragGesture()
                .onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showImagePicker, onDismiss: loadImage){
            ImagePicker(selectedImage: $selectedImage)
                .tint(colorScheme == .dark ? .white : .black)
        }
        .alert("Options", isPresented: $delete) {
            Button("Delete Question", role: .destructive) {
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
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Report this content?", isPresented: $showReport) {
            Button("Report", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if let id = question.id {
                    UserService().reportContent(type: "Question", postID: id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
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
    }
    func loadImage() {
        guard let selectedImage = selectedImage else {return}
        questionImage = Image(uiImage: selectedImage)
    }
}
