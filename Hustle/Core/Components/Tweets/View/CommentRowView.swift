import SwiftUI
import Kingfisher

struct CommentRowView: View {
    @EnvironmentObject var viewModel: CommentViewModel
    @EnvironmentObject var auth: AuthViewModel
    var comment: Comment
    @State var dateFinal: String = ""
    @Environment(\.colorScheme) var colorScheme
    @State var showDelete: Bool = false
    @Binding var replyTo: (String, String)?
    @State var showReplies: Bool = false
    @State var showProfile: Bool = false
    let canShowProfile: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 12) {
                VStack {
                    if canShowProfile {
                        Button(action: {
                            showProfile.toggle()
                        }, label: {
                            if let image = comment.profilephoto {
                                ZStack {
                                    personView(size: 35)
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width:35, height: 35)
                                        .clipShape(Circle())
                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                }
                            } else {
                                personView(size: 35)
                            }
                        })
                    } else {
                        if let image = comment.profilephoto {
                            ZStack {
                                personView(size: 35)
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width:35, height: 35)
                                    .clipShape(Circle())
                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                            }
                        } else {
                            personView(size: 35)
                        }
                    }
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 3){
                    HStack(spacing: 20){
                        if canShowProfile {
                            Button(action: {
                                showProfile.toggle()
                            }, label: {
                                Text("@\(comment.username)").font(.system(size: 18)).bold()
                            })
                        } else {
                            Text("@\(comment.username)").font(.system(size: 18)).bold()
                        }
                        Text(dateFinal)
                            .foregroundColor(.gray)
                            .font(.caption)
                            .onAppear {
                                self.dateFinal = getMessageTime(date: comment.timestamp.dateValue())
                            }
                        if (auth.currentUser?.username ?? "" == comment.username && !comment.username.isEmpty) || (((auth.currentUser?.dev?.contains("(DWK@)2))&DNWIDN:")) != nil)) {
                            HStack(spacing: 10){
                                Spacer()
                                Button {
                                    showDelete.toggle()
                                } label: {
                                    Image(systemName: "trash").scaleEffect(0.8).foregroundColor(.red)
                                }.padding(.trailing)
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if let id = comment.id {
                                        withAnimation {
                                            replyTo = (id, comment.username)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.turn.up.left").scaleEffect(1.2).foregroundColor(.gray)
                                }.padding(.trailing)
                            }
                        } else {
                            Spacer()
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if let id = comment.id {
                                    withAnimation {
                                        replyTo = (id, comment.username)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.turn.up.left").scaleEffect(1.2).foregroundColor(.gray)
                            }.padding(.trailing)
                        }
                    }
                    LinkedText(comment.text, tip: true, isMess: nil)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                    if let index = viewModel.currentHustle, let element = viewModel.comments[index].comments.first(where: { $0.id == comment.id }), let actions = element.replies, actions > 0 {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if showReplies {
                                withAnimation { showReplies = false }
                            } else {
                                let id = comment.id ?? "NA"
                                if let x = viewModel.commentReplies.firstIndex(where: { $0.0 == id }) {
                                    if viewModel.commentReplies[x].1.isEmpty {
                                        viewModel.getReplies(commentID: id)
                                    }
                                } else {
                                    viewModel.getReplies(commentID: id)
                                }
                                withAnimation { showReplies = true }
                            }
                        } label: {
                            HStack(spacing: 4){
                                Rectangle().frame(width: 60, height: 1).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : .gray)
                                if showReplies {
                                    Text("Hide replies").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : .gray)
                                } else {
                                    Text("View \(actions) replies").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : .gray)
                                }
                            }
                        }.padding(.vertical, 10)
                        if let elements = viewModel.commentReplies.first(where: { $0.0 == comment.id ?? "NA" })?.1, !elements.isEmpty && showReplies {
                            LazyVStack(alignment: .leading){
                                ForEach(elements) { comment in
                                    CommentRowViewReply(comment: comment, parentID: self.comment.id ?? "", canShowProfile: canShowProfile).padding(.top, 7)
                                }
                                if (elements.count + 2) < actions {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        viewModel.getReplies(commentID: comment.id ?? "")
                                    } label: {
                                        HStack(spacing: 4){
                                            Rectangle().frame(width: 55, height: 1).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : .gray)
                                            Text("View \(actions - elements.count) more replies").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : .gray)
                                        }
                                    }.padding(.top, 8)
                                } else if elements.count > 16 {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation { showReplies = false }
                                    } label: {
                                        HStack(spacing: 4){
                                            Rectangle().frame(width: 60, height: 1).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : .gray)
                                            Text("Hide replies").font(.subheadline).foregroundStyle(colorScheme == .dark ? Color(UIColor.lightGray) : .gray)
                                        }
                                    }.padding(.top, 8)
                                }
                                Color.clear.frame(height: 15)
                            }
                        }
                    }
                }
            }
        }
        .alert("Are you sure you want to delete this comment", isPresented: $showDelete) {
            Button("Confirm", role: .destructive) {
                viewModel.deleteComment(commentID: comment.id, hasReps: (comment.replies ?? 0) > 0)
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileSheetView(uid: String(comment.id?.dropLast(4) ?? ""), photo: comment.profilephoto ?? "", user: nil, username: .constant(nil)).dynamicTypeSize(.large).ignoresSafeArea(.keyboard)
            }.presentationDetents([.large])
        }
    }
}


struct CommentRowViewReply: View {
    @EnvironmentObject var viewModel: CommentViewModel
    @EnvironmentObject var auth: AuthViewModel
    let comment: Comment
    let parentID: String
    @State var dateFinal: String = ""
    @Environment(\.colorScheme) var colorScheme
    @State var showDelete: Bool = false
    @State var showProfile: Bool = false
    let canShowProfile: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 12) {
                VStack {
                    if canShowProfile {
                        Button(action: {
                            showProfile.toggle()
                        }, label: {
                            if let image = comment.profilephoto {
                                ZStack {
                                    personView(size: 35)
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width:35, height: 35)
                                        .clipShape(Circle())
                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                }
                            } else {
                                personView(size: 35)
                            }
                        })
                    } else {
                        if let image = comment.profilephoto {
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width:35, height: 35)
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
                                    .frame(width: 10, height: 15)
                            }
                        }
                    }
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 3){
                    HStack(spacing: 20){
                        if canShowProfile {
                            Button(action: {
                                showProfile.toggle()
                            }, label: {
                                Text("@\(comment.username)").font(.system(size: 17)).bold()
                            })
                        } else {
                            Text("@\(comment.username)").font(.system(size: 17)).bold()
                        }
                        Text(dateFinal)
                            .foregroundColor(.gray)
                            .font(.caption)
                            .onAppear {
                                self.dateFinal = getMessageTime(date: comment.timestamp.dateValue())
                            }
                        if (auth.currentUser?.username ?? "" == comment.username && !comment.username.isEmpty) || (((auth.currentUser?.dev?.contains("(DWK@)2))&DNWIDN:")) != nil)) {
                            Spacer()
                            Button {
                                showDelete.toggle()
                            } label: {
                                Image(systemName: "trash").scaleEffect(0.8).foregroundColor(.red)
                            }.padding(.trailing)
                        }
                    }
                    LinkedText(comment.text, tip: true, isMess: nil)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .alert("Are you sure you want to delete this comment", isPresented: $showDelete) {
            Button("Confirm", role: .destructive) {
                viewModel.deleteReply(commentID: parentID, replyID: comment.id ?? "")
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileSheetView(uid: String(comment.id?.dropLast(4) ?? ""), photo: comment.profilephoto ?? "", user: nil, username: .constant(nil)).dynamicTypeSize(.large).ignoresSafeArea(.keyboard)
            }.presentationDetents([.large])
        }
    }
}
