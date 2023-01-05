import SwiftUI
import Firebase

struct SilentEditView: View {
    @State var isSilent: Int = 1
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Change Online Status").font(.title3).bold()
                Spacer()
            }
            VStack(spacing: 5){
                HStack {
                    Text("Online Status").font(.subheadline).foregroundStyle(Color(UIColor.lightGray))
                    Spacer()
                }
                VStack(spacing: 14){
                    HStack(spacing: 12){
                        Circle().foregroundStyle(.green).frame(width: 18, height: 18)
                        Text("Online").font(.headline).bold()
                        Spacer()
                        if isSilent == 1 {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                            }, label: {
                                ZStack {
                                    Circle().foregroundStyle(Color(red: 0.5, green: 0.6, blue: 1.0)).frame(width: 20, height: 20)
                                    Circle().frame(width: 8, height: 8)
                                }
                            })
                        } else {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                                updateDB(silent: 1)
                            }, label: {
                                Circle().stroke(colorScheme == .dark ? .white : .black, lineWidth: 3).frame(width: 20, height: 20)
                            })
                        }
                    }
                    Divider().overlay(.gray)
                    HStack(spacing: 12){
                        Image(systemName: "moon.fill").foregroundStyle(.yellow).frame(width: 18, height: 18)
                        Text("Silent").font(.headline).bold()
                        Spacer()
                        if isSilent == 2 {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                            }, label: {
                                ZStack {
                                    Circle().foregroundStyle(Color(red: 0.5, green: 0.6, blue: 1.0)).frame(width: 20, height: 20)
                                    Circle().frame(width: 8, height: 8)
                                }
                            })
                        } else {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                                updateDB(silent: 2)
                            }, label: {
                                Circle().stroke(colorScheme == .dark ? .white : .black, lineWidth: 3).frame(width: 20, height: 20)
                            })
                        }
                    }
                    Divider().overlay(.gray)
                    HStack(spacing: 12){
                        Image(systemName: "slash.circle.fill").foregroundStyle(.red).frame(width: 18, height: 18)
                        Text("Do Not Disturb").font(.headline).bold()
                        Spacer()
                        if isSilent == 3 {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                            }, label: {
                                ZStack {
                                    Circle().foregroundStyle(Color(red: 0.5, green: 0.6, blue: 1.0)).frame(width: 20, height: 20)
                                    Circle().frame(width: 8, height: 8)
                                }
                            })
                        } else {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                                updateDB(silent: 3)
                            }, label: {
                                Circle().stroke(colorScheme == .dark ? .white : .black, lineWidth: 3).frame(width: 20, height: 20)
                            })
                        }
                    }
                    Divider().overlay(.gray)
                    HStack(spacing: 12){
                        Image("ghostMode")
                            .resizable().scaledToFit().frame(width: 18, height: 18).scaleEffect(1.35)
                        Text("Ghost Mode").font(.headline).bold()
                        Spacer()
                        if isSilent == 4 {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                            }, label: {
                                ZStack {
                                    Circle().foregroundStyle(Color(red: 0.5, green: 0.6, blue: 1.0)).frame(width: 20, height: 20)
                                    Circle().frame(width: 8, height: 8)
                                }
                            })
                        } else {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                                updateDB(silent: 4)
                            }, label: {
                                Circle().stroke(colorScheme == .dark ? .white : .black, lineWidth: 3).frame(width: 20, height: 20)
                            })
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.lightGray).opacity(0.2))
                .cornerRadius(10, corners: .allCorners)
            }.padding(.top, 10).padding(.horizontal)
            Spacer()
        }
        .padding(.top)
        .presentationDetents([.height(290)])
        .onAppear {
            isSilent = auth.currentUser?.silent ?? 1
        }
    }
    func updateDB(silent: Int){
        auth.currentUser?.silent = silent
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if let x = viewModel.users.firstIndex(where: { $0.user.id == uid }) {
            viewModel.users[x].user.silent = silent
        }
        Firestore.firestore().collection("users").document(uid).updateData(["silent": silent]) { _ in }
    }
}
