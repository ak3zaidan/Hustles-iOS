import SwiftUI
import Kingfisher

struct BlockedView: View {
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var viewIsTop = false
    @Environment(\.colorScheme) var colorScheme
    let blocked: [String]
    var body: some View {
        VStack {
            ZStack(alignment: .leading){
                Color(.orange).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20){
                    HStack{
                        Text("Blocked Users").font(.title)
                        Spacer()
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack(spacing: 2){
                                Image(systemName: "chevron.backward")
                                    .scaleEffect(1.5)
                                    .frame(width: 15, height: 15)
                                Text("back").font(.subheadline)
                            }
                        }
                    }.padding(.horizontal, 25).padding(.top)
                }
            }.frame(height: 80)
            VStack {
                if let user = auth.currentUser, let blocked = user.blockedUsers {
                    if blocked.isEmpty {
                        VStack {
                            Spacer()
                            Text("No Blocked Users.").font(.title2).bold()
                            Spacer()
                        }
                    } else if !profile.blockedUsers.isEmpty {
                        ScrollView {
                            ForEach(profile.blockedUsers) { user in
                                HStack {
                                    if let image = user.profileImageUrl {
                                        KFImage(URL(string: image))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width:56, height: 56)
                                            .clipShape(Circle())
                                    } else {
                                        ZStack(alignment: .center){
                                            Image(systemName: "circle.fill")
                                                .resizable()
                                                .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                                                .frame(width: 56, height: 56)
                                            Image(systemName: "questionmark")
                                                .resizable()
                                                .foregroundColor(.white)
                                                .frame(width: 17, height: 22)
                                        }
                                    }
                                    Text(user.username).font(.system(size: 18)).foregroundColor(.blue)
                                    Spacer()
                                    Button {
                                        profile.blockedUsers.removeAll(where: { $0.id == user.id })
                                        auth.currentUser?.blockedUsers?.removeAll(where: { $0 == user.id ?? "" })
                                        UserService().unblockUser(uid: user.id ?? "")
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    } label: {
                                        ZStack {
                                            Rectangle().fill(.blue.gradient)
                                            Text("Unblock").font(.system(size: 16)).foregroundColor(.white)
                                        }
                                    }.frame(width: 90, height: 40)
                                }
                            }
                            Color.clear.frame(height: 40)
                        }.scrollIndicators(.hidden)
                    } else {
                        VStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("No Blocked Users.").font(.title2).bold()
                        Spacer()
                    }
                }
            }.padding()
        }
        .navigationBarBackButtonHidden(true)
        .padding(.bottom, 45)
        .onChange(of: popRoot.tap, perform: { _ in
            if popRoot.tap == 6 && viewIsTop {
                presentationMode.wrappedValue.dismiss()
                popRoot.tap = 0
            }
        })
        .onAppear {
            viewIsTop = true
            if profile.blockedUsers.isEmpty {
                profile.getBlocked(uid: blocked)
            }
        }
        .onDisappear { viewIsTop = false }
    }
}
