import SwiftUI
import Firebase
import Kingfisher

struct AnswerRowView: View {
    @EnvironmentObject var viewModel: QuestionModel
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    let answer: Answer
    let question: Question
    let disableUser: Bool
    @State var delete: Bool = false
    @State var showApprove: Bool = false
    @State var dateFinal: String = "Answered recently"
    @State var showComments: Bool = false
    
    var body: some View {
        VStack(spacing: 8){
            HStack {
                LinkedText(answer.caption, tip: false, isMess: nil).font(.system(size: 16))
                Spacer()
            }
            HStack {
                HStack {
                    NavigationLink {
                        ProfileView(showSettings: false, showMessaging: true, uid: answer.id ?? "", photo: answer.profilePhoto ?? "", user: nil, expand: true, isMain: false)
                            .dynamicTypeSize(.large)
                    } label: {
                        if let image = answer.profilePhoto {
                            ZStack {
                                personView(size: 30)
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width:30, height: 30)
                                    .clipShape(Circle())
                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                            }
                        } else {
                            personView(size: 32)
                        }
                    }.disabled(disableUser)
                    VStack(alignment: .leading, spacing: 3){
                        HStack {
                            NavigationLink {
                                ProfileView(showSettings: false, showMessaging: true, uid: answer.id ?? "", photo: answer.profilePhoto ?? "", user: nil, expand: true, isMain: false)
                                    .dynamicTypeSize(.large)
                            } label: {
                                Text(answer.username).font(.subheadline).bold()
                            }.disabled(disableUser)
                            if let id = answer.id, question.acceptedAnswer ?? "" != id {
                                if let uid = auth.currentUser?.id, id == uid {
                                    if !viewModel.goodAnswers.contains(where: { $0.0 == question.id ?? "" && $0.1 == id }) {
                                        Button {
                                            delete.toggle()
                                        } label: {
                                            Image(systemName: "trash").scaleEffect(0.8).foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            if let id = auth.currentUser?.dev, id.contains("(DWK@)2))&DNWIDN:") {
                                Button {
                                    delete.toggle()
                                } label: {
                                    Image(systemName: "trash").scaleEffect(0.8).foregroundColor(.red)
                                }
                            }
                            Spacer()
                            Button {
                                showComments.toggle()
                            } label: {
                                Image(systemName: "ellipsis.message.fill").foregroundStyle(colorScheme == .dark ? .white : .gray)
                            }
                            Spacer()
                        }
                        Text(dateFinal).font(.caption).fontWeight(.semibold).foregroundColor(.gray)
                    }
                }
                Spacer()
                HStack(spacing: 5){
                    VStack {
                        if let id = question.acceptedAnswer, let id2 = answer.id, id == id2 {
                            Image(systemName: "checkmark").foregroundColor(.green).bold().font(.title)
                        } else if viewModel.goodAnswers.contains(where: { $0.0 == question.id ?? "" && $0.1 == answer.id ?? "" }) {
                            Image(systemName: "checkmark").foregroundColor(.green).bold().font(.title)
                        } else if let id = auth.currentUser?.id, id == question.uid, question.acceptedAnswer == nil {
                            Button {
                                showApprove.toggle()
                            } label: {
                                Image(systemName: "checkmark").foregroundColor(.gray).bold().font(.title)
                            }
                        }
                        let down = viewModel.votedDownAnswers.contains(where: { $0.0 == question.id ?? "" && $0.1 == answer.id ?? "" })
                        let up = viewModel.votedUpAnswers.contains(where: { $0.0 == question.id ?? "" && $0.1 == answer.id ?? "" })
                        if down {
                            Text("\((answer.votes ?? 0) - 1)").font(.title).bold().foregroundColor(.blue)
                        } else if up {
                            Text("\((answer.votes ?? 0) + 1)").font(.title).bold().foregroundColor(.blue)
                        } else {
                            Text("\(answer.votes ?? 0)").font(.title).bold().foregroundColor(.blue)
                        }
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 20).foregroundColor(Color(UIColor.secondarySystemBackground))
                        VStack {
                            let id = auth.currentUser?.id?.suffix(4) ?? ""
                            let downVoteIds = answer.downVoteIds ?? []
                            let upVoteIds = answer.upvoteIds ?? []
                            let downVotesContains = downVoteIds.contains(String(id)) || viewModel.votedDownAnswers.contains(where: { $0.0 == question.id ?? "" && $0.1 == answer.id ?? "" })
                            let upVotesContains = upVoteIds.contains(String(id)) || viewModel.votedUpAnswers.contains(where: { $0.0 == question.id ?? "" && $0.1 == answer.id ?? "" })
                            Button {
                                if auth.currentUser?.elo ?? 0 >= 600 && auth.currentUser?.id ?? "" != answer.id ?? "" {
                                    viewModel.voteAnswer(id: question.id, id2: answer.id, value: 1)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    viewModel.votedUpAnswers.append((question.id ?? "", answer.id ?? ""))
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
                                if auth.currentUser?.elo ?? 0 >= 600 && auth.currentUser?.id ?? "" != answer.id ?? "" {
                                    viewModel.voteAnswer(id: question.id, id2: answer.id, value: -1)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    viewModel.votedDownAnswers.append((question.id ?? "", answer.id ?? ""))
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
            Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray).padding(.top, 2)
        }
        .sheet(isPresented: $showComments, content: {
            if #available(iOS 16.4, *){
                QuestionCommentView(question: question, answer: answer, canShowProfile: true, imageQ: false)
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(40)
            } else {
                QuestionCommentView(question: question, answer: answer, canShowProfile: true, imageQ: false)
                    .presentationDetents([.medium, .large])
            }
        })
        .alert("Options", isPresented: $delete) {
            Button("Delete Answer", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.deleteAnswer(id: question.id, id2: answer.id, image: answer.image)
                if let index = viewModel.allQuestions.firstIndex(where: { $0.0 == question.id }) {
                    viewModel.allQuestions[index].1.removeAll(where: { $0.id == answer.id })
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Confirm to accept this answer, this action is not reversable", isPresented: $showApprove) {
            Button("Confirm", role: .destructive) {
                viewModel.acceptAnswer(id: question.id, id2: answer.id)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if let id1 = question.id, let id2 = answer.id {
                    viewModel.goodAnswers.append((id1, id2))
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            let dateString = answer.timestamp.dateValue().formatted(.dateTime.month().day().year().hour().minute())
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
            if let date = dateFormatter.date(from:dateString){
                if Calendar.current.isDateInToday(date){
                    dateFinal = "Answered today at \(answer.timestamp.dateValue().formatted(.dateTime.hour().minute()))"
                }
                else if Calendar.current.isDateInYesterday(date) {
                    dateFinal = "Answered Yesterday"}
                else{
                    if let dayBetween  = Calendar.current.dateComponents([.day], from: answer.timestamp.dateValue(), to: Date()).day{
                        dateFinal = "Answered \(dayBetween + 1) days ago"
                    }
                }
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}
