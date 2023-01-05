import SwiftUI
import Firebase

struct SocialLinksView: View {
    let allPossible = ["Instagram", "Facebook", "YouTube", "WhatsApp", "TikTok", "Snapchat", "Twitter", "Pinterest", "Reddit", "LinkedIn", "Telegram", "Cash App", "Venmo", "Twitch", "Spotify", "Discord", "Shopify"]
    @State var showAdd: Bool = false
    @State var selected: String = ""
    @State var myLink: String = ""
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    })
                    Spacer()
                }
                HStack {
                    Spacer()
                    Text("Add Social Link").font(.title2).bold()
                    Spacer()
                }
            }.padding(.horizontal).padding(.top)
            Divider().overlay(.gray).padding(.bottom, 10)
            TagLayout(alignment: .center, spacing: 8) {
                ForEach(allPossible, id: \.self) { element in
                    Button {
                        selected = element
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAdd = true
                        }
                    } label: {
                        TagView(element)
                    }
                }
            }
            Spacer()
        }
        .presentationDetents([.medium])
        .overlay {
            if showAdd {
                VStack {
                    ZStack {
                        HStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAdd = false
                                }
                            }, label: {
                                Image(systemName: "arrow.left")
                                    .font(.title3)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            })
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Text("Add Social Link").font(.title2).bold()
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAdd = false
                                }
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                upload(platform: selected, link: myLink)
                                myLink = ""
                                selected = ""
                            }, label: {
                                Text("Save").font(.headline).padding(.horizontal, 8).padding(.vertical, 3).background(!myLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .blue : .gray.opacity(0.6))
                                    .clipShape(Capsule())
                            })
                        }
                    }.padding(.horizontal).padding(.top)
                    Divider().overlay(.gray)
                    HStack {
                        TagView(selected)
                        Spacer()
                    }.padding()
                    TextField("Link", text: $myLink)
                        .tint(.blue)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                    Spacer()
                }
                .ignoresSafeArea()
                .background(.ultraThickMaterial)
                .transition(.move(edge: .trailing))
            }
        }
    }
    @ViewBuilder
    func TagView(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Image(tag).resizable().aspectRatio(contentMode: .fit).frame(height: 25)
            Text(tag).font(.callout).fontWeight(.semibold)
        }
        .foregroundStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 35)
        .padding(.horizontal, 7)
        .background {
            Capsule().fill(Color.gray.gradient).opacity(0.3)
        }
    }
    func upload(platform: String, link: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let final = "\(platform):\(link)"
        if let x = viewModel.users.firstIndex(where: { $0.user.id ?? "" == uid }) {
            if var newAll = viewModel.users[x].user.socials {
                for i in 0..<newAll.count {
                    if newAll[i].contains(platform) {
                        newAll[i] = final
                        Firestore.firestore().collection("users").document(uid)
                            .updateData(["socials": newAll ]) { _ in }
                        viewModel.users[x].user.socials = newAll
                        return
                    }
                }
            }
            Firestore.firestore().collection("users").document(uid)
                .updateData(["socials": FieldValue.arrayUnion([final])]) { _ in }
            if viewModel.users[x].user.socials == nil {
                viewModel.users[x].user.socials = [final]
            } else {
                viewModel.users[x].user.socials?.append(final)
            }
        }
    }
}
