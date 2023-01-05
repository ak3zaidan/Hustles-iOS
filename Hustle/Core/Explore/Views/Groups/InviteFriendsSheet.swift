import SwiftUI
import Firebase

struct InviteFriendsSheet: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: GroupViewModel
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var jobModel: JobViewModel
    @State var searchText: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0){
            Text("Invite a friend").font(.title2).bold()
            Divider().overlay(Color(UIColor.lightGray)).padding(.vertical)
            VStack(spacing: 8){
                SearchBarGroup(text: $searchText, fill: "friends")
                    .onSubmit {
                        if let uid = auth.currentUser?.id, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            jobModel.searchCompleteJob(string: searchText, uid: uid)
                        }
                    }
                    .onChange(of: searchText) { _, _ in
                        jobModel.sortUsers(string: searchText)
                    }
                ScrollView {
                    LazyVStack(spacing: 30){
                        if jobModel.convoUsers.isEmpty && jobModel.allUsers.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 18){
                                    Text("Invite users in the Hustles community!")
                                        .gradientForeground(colors: [.blue, .purple])
                                        .font(.headline).bold()
                                    LottieView(loopMode: .playOnce, name: "nofound")
                                        .scaleEffect(0.3)
                                        .frame(width: 100, height: 100)
                                }
                                Spacer()
                            }.padding(.top, 70)
                        }
                        if !jobModel.convoUsers.isEmpty {
                            VStack(spacing: 8){
                                HStack {
                                    Text("From Messages").font(.body).bold()
                                    Spacer()
                                }
                                VStack(spacing: 10){
                                    ForEach(jobModel.convoUsers) { user in
                                        HStack {
                                            UserRowViewThird(user: user).disabled(true)
                                            Spacer()
                                            if popRoot.invitedFriends.contains(user.id ?? "NA") {
                                                Text("Sent").foregroundStyle(.white).font(.subheadline)
                                                    .padding(.horizontal, 9).padding(.vertical, 4)
                                                    .background(Color.green).clipShape(Capsule())
                                            } else {
                                                Button(action: {
                                                    if let id = user.id {
                                                        popRoot.invitedFriends.append(id)
                                                    }
                                                    if let index = viewModel.currentGroup {
                                                        var hidden = ""
                                                        if viewModel.groups[index].1.publicstatus {
                                                            hidden = "\(viewModel.groups[index].1.id)pub!@#$%^&*()\(viewModel.groups[index].1.title)"
                                                        } else {
                                                            hidden = "\(viewModel.groups[index].1.id)priv!@#$%^&*()\(viewModel.groups[index].1.title)"
                                                        }
                                                        let uid = Auth.auth().currentUser?.uid ?? ""
                                                        let uid_prefix = String(uid.prefix(5))
                                                        
                                                        let mess_id = uid_prefix + String("\(UUID())".prefix(15))
                                                        messageModel.sendInvt(myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: user.id ?? "", withText: hidden, messageID: mess_id)
                                                    }
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                }, label: {
                                                    Text("Invite").foregroundStyle(.green).font(.subheadline)
                                                        .padding(.horizontal, 9).padding(.vertical, 4)
                                                        .background(Color.gray).clipShape(Capsule())
                                                })
                                            }
                                        }
                                        if user != jobModel.convoUsers.last {
                                            Divider().overlay(colorScheme == .dark ? Color.white : Color.gray)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.lightGray).opacity(0.2))
                                .cornerRadius(10, corners: .allCorners)
                            }.padding(.horizontal)
                        }
                        if !jobModel.allUsers.isEmpty {
                            VStack(spacing: 8){
                                HStack {
                                    Text("All Users").font(.body).bold()
                                    Spacer()
                                }
                                VStack(spacing: 10){
                                    ForEach(jobModel.allUsers) { user in
                                        HStack {
                                            UserRowViewThird(user: user).disabled(true)
                                            Spacer()
                                            if popRoot.invitedFriends.contains(user.id ?? "NA") {
                                                Text("Sent").foregroundStyle(.white).font(.subheadline)
                                                    .padding(.horizontal, 9).padding(.vertical, 4)
                                                    .background(Color.green).clipShape(Capsule())
                                            } else {
                                                Button(action: {
                                                    if let id = user.id {
                                                        popRoot.invitedFriends.append(id)
                                                    }
                                                    if let index = viewModel.currentGroup {
                                                        var hidden = ""
                                                        if viewModel.groups[index].1.publicstatus {
                                                            hidden = "\(viewModel.groups[index].1.id)pub!@#$%^&*()\(viewModel.groups[index].1.title)"
                                                        } else {
                                                            hidden = "\(viewModel.groups[index].1.id)priv!@#$%^&*()\(viewModel.groups[index].1.title)"
                                                        }
                                                        let uid = Auth.auth().currentUser?.uid ?? ""
                                                        let uid_prefix = String(uid.prefix(5))
                                                        
                                                        let mess_id = uid_prefix + String("\(UUID())".prefix(15))
                                                        messageModel.sendInvt(myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: user.id ?? "", withText: hidden, messageID: mess_id)
                                                    }
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                }, label: {
                                                    Text("Invite").foregroundStyle(.green).font(.subheadline)
                                                        .padding(.horizontal, 9).padding(.vertical, 4)
                                                        .background(Color.gray).clipShape(Capsule())
                                                })
                                            }
                                        }
                                        if user != jobModel.allUsers.last {
                                            Divider().overlay(colorScheme == .dark ? Color.white : Color.gray)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.lightGray).opacity(0.2))
                                .cornerRadius(10, corners: .allCorners)
                            }.padding(.horizontal)
                        }
                    }
                    Color.clear.frame(height: 40)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .padding(.top)
        .presentationDetents([.large])
        .onAppear {
            jobModel.startCompleteJob(chats: messageModel.chats, following: auth.currentUser?.following ?? [], userpointer: auth.currentUser?.myMessages ?? [])
        }
    }
}
