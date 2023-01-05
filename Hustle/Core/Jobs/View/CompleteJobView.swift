import SwiftUI
import Kingfisher

struct CompleteJobView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var userModel: MessageViewModel
    @EnvironmentObject var viewModel: JobViewModel
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedUser: User?
    let job: Tweet
    @State var showInst: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom){
            VStack(alignment: .leading, spacing: 0){
                HStack {
                    Text("From Messages").font(.system(size: 22))
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 25))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
                ScrollView(.horizontal){
                    HStack {
                        ForEach(viewModel.convoUsers){ user in
                            VStack(alignment: .center, spacing: 2) {
                                if let image = user.profileImageUrl {
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 46, height: 46)
                                        .clipShape(Circle())
                                } else {
                                    ZStack(alignment: .center){
                                        Image(systemName: "circle.fill")
                                            .resizable()
                                            .foregroundColor(.black)
                                            .frame(width: 46, height: 46)
                                        Image(systemName: "questionmark")
                                            .resizable()
                                            .foregroundColor(.white)
                                            .frame(width: 15, height: 20)
                                    }
                                }
                                Text("@\(user.username)").font(.subheadline)
                            }
                            .padding(5)
                            .background(selectedUser == user ? Color.orange.opacity(0.7) : Color.clear)
                            .onTapGesture {
                                selectedUser = user
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .frame(height: 90)
                .scrollIndicators(.hidden)
                TextField("Search...", text: $searchText)
                    .submitLabel(.search)
                    .tint(.blue)
                    .autocorrectionDisabled(true)
                    .padding(8)
                    .padding(.horizontal, 24)
                    .background(colorScheme == .dark ? .black : Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay (
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                    )
                    .onSubmit {
                        if let uid = auth.currentUser?.id, !searchText.isEmpty {
                            viewModel.searchCompleteJob(string: searchText, uid: uid)
                        }
                    }
                    .onChange(of: searchText) { _, _ in
                        viewModel.sortUsers(string: searchText)
                    }
                ScrollView {
                    VStack {
                        ForEach(viewModel.allUsers){ user in
                            HStack(alignment: .center) {
                                if let image = user.profileImageUrl {
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 46, height: 46)
                                        .clipShape(Circle())
                                        .padding(.leading, 5)
                                } else {
                                    ZStack(alignment: .center){
                                        Image(systemName: "circle.fill")
                                            .resizable()
                                            .foregroundColor(.black)
                                            .frame(width: 46, height: 46)
                                        Image(systemName: "questionmark")
                                            .resizable()
                                            .foregroundColor(.white)
                                            .frame(width: 15, height: 20)
                                    }.padding(.leading, 5)
                                }
                                Text(user.fullname).font(.system(size: 18)).padding(.leading, 15)
                                Text("@\(user.username)").font(.system(size: 12)).foregroundColor(.gray).padding(.leading, 5)
                                Spacer()
                            }
                            .padding(.vertical, 5)
                            .background(selectedUser == user ? Color.orange.opacity(0.7) : Color.clear)
                            .onTapGesture {
                                selectedUser = user
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
                .scrollDismissesKeyboard(.immediately)
                HStack{
                    Spacer()
                    if viewModel.startedComplete {
                        Loader(flip: true).id("\(UUID())")
                    } else {
                        if !viewModel.completingJobResult.isEmpty {
                            Text(viewModel.completingJobResult).font(.subheadline).foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        } else {
                            Button {
                                if let user = selectedUser {
                                    viewModel.finishJob(user: user, job: job)
                                }
                            } label: {
                                ZStack(alignment: .center){
                                    Rectangle()
                                        .foregroundColor(selectedUser != nil ? .orange.opacity(0.7) : .gray)
                                    Text("Complete").font(.subheadline).bold().foregroundColor(.white)
                                }
                            }.frame(width: 100, height: 32)
                        }
                    }
                    Spacer()
                }
                .onChange(of: selectedUser) { _, _ in
                    if selectedUser != nil && viewModel.completingJobResult.contains("..."){
                        viewModel.completingJobResult = ""
                    }
                }
            }
            if showInst {
                ToastView(message: "Select the user who completed this job to finish")
                    .padding(.bottom, 40)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation{
                                showInst = false
                            }
                        }
                    }
                
            }
        }
        .dynamicTypeSize(.large)
        .padding()
        .presentationDetents([.fraction(0.7)])
        .onAppear {
            showInst = true
            viewModel.startCompleteJob(chats: userModel.chats, following: auth.currentUser?.following ?? [], userpointer: auth.currentUser?.myMessages ?? [])
        }
        .onChange(of: viewModel.startedComplete) { _, _ in
            if !viewModel.startedComplete && viewModel.completingJobResult.isEmpty {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onDisappear {
            viewModel.completingJobResult = ""
        }
        .onChange(of: selectedUser) { _, _ in
            showInst = false
        }
    }
}
