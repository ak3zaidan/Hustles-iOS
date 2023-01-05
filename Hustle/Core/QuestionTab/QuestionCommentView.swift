import SwiftUI
import Firebase
import Kingfisher

struct QuestionCommentView: View, KeyboardReadable {
    @State private var reply: String = ""
    @EnvironmentObject var copy: ExploreViewModel
    @EnvironmentObject var viewModel: QuestionCommentModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    var question: Question?
    var answer: Answer?
    @State var scrollViewSize: CGSize = .zero
    @State var wholeSize: CGSize = .zero
    @State private var canOne = true
    @State private var tag = ""
    @State private var target = ""
    @State private var keyBoardVisible = true
    @Environment(\.colorScheme) var colorScheme
    @State private var replyTo: (String, String)? = nil
    @FocusState var isEditing
    let canShowProfile: Bool
    let imageQ: Bool
    @State private var noData = false
    @State var showAI = false
    
    var body: some View {
        VStack(spacing: 0){
            let count = (answer != nil ? answer?.commentsCount : question?.commentsCount) ?? 0
            let toAdd = (count == 1) ? "Comment" : "Comments"
            
            Text("\(count) \(toAdd)")
                .font(.system(size: 18)).bold()
                .padding(.vertical)
                .padding(.top, 5)
            Divider().overlay(colorScheme == .dark ? Color(UIColor.lightGray) : .gray).padding(.horizontal)

//            if copy.showCopyTip {
//                ToastView(message: "Text Copied")
//                    .scaleEffect(0.75)
//                    .onAppear {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                            withAnimation{
//                                copy.showCopyTip = false
//                            }
//                        }
//                    }
//                
//            }
            if let index = viewModel.currentHustle {
                ChildSizeReader(size: $wholeSize) {
                    ScrollView {
                        ChildSizeReader(size: $scrollViewSize) {
                            LazyVStack(alignment: .leading){
                                if viewModel.comments[index].comments.isEmpty && (answer?.commentsCount ?? question?.commentsCount ?? 0) > 0  && !noData {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        ProgressView().scaleEffect(1.2)
                                        Spacer()
                                    }
                                    Spacer()
                                } else if !viewModel.comments[index].comments.isEmpty {
                                    ForEach(viewModel.comments[index].comments, id: \.self) { comment in
                                        QuestionCommentRowView(comment: comment, replyTo: $replyTo, canShowProfile: canShowProfile, qID: question?.id ?? "", aID: answer?.id ?? "").padding(.top, 7)
                                    }
                                } else if noData {
                                    Spacer()
                                    HStack{
                                        Spacer()
                                        Text("No comments yet...").font(.headline).bold()
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(GeometryReader {
                                Color.clear.preference(key: ViewOffsetKey.self,
                                                       value: -$0.frame(in: .named("scroll")).origin.y)
                            })
                            .onPreferenceChange(ViewOffsetKey.self) { value in
                                if let count = answer != nil ? answer?.commentsCount : question?.commentsCount {
                                    if viewModel.comments[index].comments.count < count {
                                        if value > (scrollViewSize.height - wholeSize.height) - 350 {
                                            if value > 200 {
                                                if canOne {
                                                    canOne = false
                                                    viewModel.getCommentsMore()
                                                    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                                        canOne = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }.coordinateSpace(name: "scroll")
            }
            Spacer()
            if let rep = replyTo {
                HStack {
                    Text("Replying to @\(rep.1)").font(.system(size: 17)).foregroundStyle(colorScheme == .dark ? .white : Color(UIColor.darkGray))
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        replyTo = nil
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundStyle(colorScheme == .dark ? .white : Color(UIColor.darkGray))
                    }
                }.padding(.horizontal, 8).frame(height: 35).background(.ultraThinMaterial)
            }
            if keyBoardVisible && reply.contains("@") && tag.isEmpty {
                TaggedUserView(text: $reply, target: $target, commentID: answer != nil ? answer?.id : question?.id, newsID: nil, newsRepID: nil, questionID: nil, groupID: nil, selectedtag: $tag)
            }
            ZStack {
                if colorScheme == .light {
                    Color.white.frame(height: 50)
                } else {
                    Color.clear.frame(height: 50)
                }
                HStack(alignment: .center){
                    if let user = auth.currentUser {
                        if showAI {
                            SimpleAIView(text: $reply).transition(.scale.combined(with: .opacity))
                        } else {
                            ZStack {
                                personView(size: 35)
                                if let image = user.profileImageUrl {
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 35, height: 35)
                                        .clipShape(Circle())
                                        .shadow(color: .gray, radius: 1)
                                }
                            }.transition(.scale.combined(with: .opacity))
                        }

                        CustomMessageField(placeholder: replyTo == nil ? Text("Comment...") : Text("Reply..."), text: $reply)
                            .focused($isEditing)
                            .frame(width: widthOrHeight(width: true) * 0.7)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .background(colorScheme == .dark ? .black : Color("gray"))
                            .cornerRadius(20)
                        
                        Button {
                            if let index = viewModel.currentHustle, !reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                if let rep = replyTo {
                                    viewModel.uploadReply(text: reply, username: user.username, userPhoto: user.profileImageUrl ?? "", commentID: rep.0, userID: user.id ?? "")
                                    replyTo = nil
                                } else {
                                    let id1 = (user.id ?? "") + String("\(UUID())".prefix(4))
                                    let new = Comment(id: id1, text: reply, timestamp: Timestamp(date: Date()), username: user.username, profilephoto: user.profileImageUrl)
                                    viewModel.comments[index].comments.insert(new, at: 0)
                                    
                                    viewModel.sendComment(text: reply, username: user.username, userPhoto: user.profileImageUrl ?? "", commentID: id1, questionID: question?.id ?? "", answerID: answer?.id ?? "", isAnswer: answer != nil)
                                }
                                if !tag.isEmpty {
                                    popRoot.alertImage = "tag.fill"
                                    popRoot.alertReason = "Tagged user notified"
                                    withAnimation {
                                        popRoot.showAlert = true
                                    }
                                    
                                    viewModel.tagUserComment(myUsername: auth.currentUser?.username ?? "", otherUsername: tag, message: reply, questionID: question?.id, imageQ: imageQ)
                                    tag = ""
                                }
                                reply = ""
                            }
                        } label: {
                            ZStack {
                                Circle().frame(width: 35, height: 35)
                                    .foregroundStyle(Color.orange.opacity(0.7))
                                Image(systemName: "paperplane.fill")
                                    .rotationEffect(.degrees(45.0)).offset(x: -2)
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: replyTo?.0, { _, _ in
            if replyTo != nil {
                isEditing = true
            }
        })
        .dynamicTypeSize(.large)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                noData = true
            }
            if let id = answer != nil ? answer?.id : question?.id {
                viewModel.getComments(videoID: id)
            }
        }
        .onDisappear {
            viewModel.currentHustle = nil
            reply = ""
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
            keyBoardVisible = newIsKeyboardVisible
        }
        .onChange(of: tag) { _, _ in
            if !tag.isEmpty {
                if let range = reply.range(of: "@") {
                    let final = reply.replacingCharacters(in: range, with: "@\(tag) ")
                    reply = removeSecondOccurrence(of: target, in: final)
                    target = ""
                }
            }
        }
        .onChange(of: reply) { _, _ in
            if !tag.isEmpty && !reply.contains("@\(tag)") {
                tag = ""
            }
            
            if reply.count > 30 && !showAI {
                withAnimation(.easeInOut(duration: 0.15)){
                    showAI = true
                }
            } else if reply.count <= 30 && showAI {
                withAnimation(.easeInOut(duration: 0.15)){
                    showAI = false
                }
            }
        }
    }
}
