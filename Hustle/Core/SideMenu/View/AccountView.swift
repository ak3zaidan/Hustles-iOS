import SwiftUI
import Firebase

struct AccountView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messageLogOut: MessageViewModel
    @EnvironmentObject var explore: ExploreViewModel
    @EnvironmentObject var ads: UploadAdViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var stocks: StockViewModel
    @EnvironmentObject var feed: FeedViewModel
    @EnvironmentObject var gc: GroupChatViewModel
    @EnvironmentObject var globe: GlobeViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var editName: Bool = false
    @State private var editNameError: String = ""
    @State private var editNameDone: Bool = false
    @State private var changePass: Bool = false
    @State private var editPassError: String = ""
    @State private var editPassDone: Bool = false
    @State private var deleteErrorSheet: Bool = false
    @State private var verifyLogIn: Bool = false
    @State private var whichRetryOperation: Bool = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var newImage: Image?
    @State private var successImage: Bool = false
    @State private var deleteError: String = ""
    @State private var oldLogInError: String = ""
    @State private var textFinal: String = ""
    @State private var viewIsTop = false
    
    @State private var bio: String = ""
    @State private var bioErr: String = " "
    
    @State private var selectedBackImage: UIImage?
    @State private var newBackImage: Image?
    @State private var showImagePickerSec = false
    @State private var showOnlineStatus = false
    @State var showFixSheet = false
    @State var showAI = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    ZStack {
                        HStack {
                            Spacer()
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                HStack{
                                    Image(systemName: "chevron.backward")
                                        .scaleEffect(1.5)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .frame(width: 15, height: 15)
                                    Text("back")
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                            }
                        }
                        .padding(.trailing, 15)
                        HStack {
                            Text("Account")
                                .bold()
                                .font(.title)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                    VStack(spacing: 20){
                        Text(textFinal).font(.subheadline).bold().foregroundColor(.gray)
                            .onAppear {
                                if let time_s = authViewModel.currentUser?.timestamp {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "MMMM d, yyyy"
                                    let dateString = dateFormatter.string(from: time_s.dateValue())
                                    textFinal = "member since \(dateString)"
                                }
                            }
                        HStack{
                            Text(authViewModel.currentUser?.fullname ?? "")
                                .font(.title3)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                editName.toggle()
                            } label: {
                                Text("Edit").foregroundColor(.blue).bold()
                            }
                        }.padding(.top)
                        Divider()
                        HStack {
                            Text("Edit Profile Picture")
                                .font(.title3)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Button {
                                showImagePicker.toggle()
                            } label: {
                                Text("Edit").foregroundColor(.blue).bold()
                            }
                        }
                        .sheet(isPresented: $showImagePicker, onDismiss: loadImage){
                            ImagePicker(selectedImage: $selectedImage)
                        }
                        Divider()
                        VStack(spacing: 8){
                            HStack {
                                Text("Edit Bio")
                                    .font(.title3)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                if showAI {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showFixSheet = true
                                    }, label: {
                                        ZStack {
                                            Circle().frame(width: 40, height: 30).foregroundColor(Color.gray).opacity(0.3)
                                            LottieView(loopMode: .loop, name: "finite")
                                                .scaleEffect(0.048)
                                                .frame(width: 25, height: 14)
                                        }
                                    }).padding(.leading).transition(.scale.combined(with: .opacity))
                                }
                                Spacer()
                                if bioErr.isEmpty && authViewModel.currentUser?.bio ?? "err-nil" != bio && !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        UserService().editBio(new: bio)
                                        authViewModel.currentUser?.bio = bio
                                        if let x = viewModel.users.firstIndex(where: { $0.user.id == authViewModel.currentUser?.id }) {
                                            viewModel.users[x].user.bio = bio
                                        }
                                    } label: {
                                        Text("Save").foregroundColor(.blue).bold()
                                    }
                                } else {
                                    Text(bioErr).foregroundColor(.red).bold().font(.subheadline)
                                }
                            }
                            HStack {
                                CustomMessageFieldAcc(placeholder: Text("Bio..."), text: $bio)
                                    .frame(width: widthOrHeight(width: true) * 0.7)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Spacer()
                            }
                        }
                        Divider()
                        HStack {
                            Text("Change Password")
                                .font(.title3)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Button {
                                changePass.toggle()
                            } label: {
                                Text("Edit").foregroundColor(.blue).bold()
                            }
                        }
                        Divider()
                        HStack {
                            Text("Online Status")
                                .font(.title3)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Button {
                                showOnlineStatus.toggle()
                            } label: {
                                Text("Edit").foregroundColor(.blue).bold()
                            }
                        }
                        Divider()
                        HStack {
                            Text("Edit Profile Background")
                                .font(.title3)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Button {
                                showImagePickerSec.toggle()
                            } label: {
                                Text("Edit").foregroundColor(.blue).bold()
                            }
                        }
                        .sheet(isPresented: $showImagePicker, onDismiss: loadImage){
                            ImagePicker(selectedImage: $selectedImage)
                        }
                        .sheet(isPresented: $showImagePickerSec, onDismiss: loadBackImage){
                            ImagePicker(selectedImage: $selectedBackImage)
                        }
                        Divider()
                        HStack {
                            Text("Delete Account")
                                .font(.title3)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Button {
                                verifyLogIn.toggle()
                            } label: {
                                Text("Delete").foregroundColor(.red).bold()
                            }
                        }
                        Divider()
                        if let users = authViewModel.currentUser?.blockedUsers, !users.isEmpty {
                            HStack {
                                Text("Blocked Users")
                                    .font(.title3)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Spacer()
                                NavigationLink {
                                    BlockedView(blocked: users)
                                } label: {
                                    Text("Go ->").foregroundColor(.blue).bold()
                                }
                            }
                            Divider()
                        }
                        if let newImage = newImage {
                            HStack(){
                                newImage
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                                Spacer()
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if let selectedImage = selectedImage, !successImage {
                                        viewModel.editPhoto(uid: authViewModel.currentUser?.id ?? "", image: selectedImage, oldimage: authViewModel.currentUser?.profileImageUrl) { string in
                                            authViewModel.currentUser?.profileImageUrl = string
                                            if let x = viewModel.users.firstIndex(where: { $0.user.id == authViewModel.currentUser?.id }) {
                                                viewModel.users[x].user.profileImageUrl = string
                                            }
                                        }
                                        successImage = true
                                        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                            self.selectedImage = nil
                                            self.newImage = nil
                                            successImage = false
                                        }
                                    }
                                } label: {
                                    if successImage {
                                        LottieView(loopMode: .playOnce, name: "image_success")
                                            .frame(width: 60, height: 60)
                                    } else {
                                        Text("Save").foregroundColor(.blue).bold()
                                    }
                                }
                            }.padding(.top)
                        }
                        if let newImage = newBackImage {
                            HStack(){
                                newImage
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                                Spacer()
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if let selectedImage = selectedBackImage, !successImage {
                                        ImageUploader.uploadImage(image: selectedImage, location: "profile_image", compression: 0.05) { url, _ in
                                            if !url.isEmpty {
                                                UserService().editBackground(newURL: url)
                                                if let url = authViewModel.currentUser?.userBackground {
                                                    ImageUploader.deleteImage(fileLocation: url) { _ in }
                                                }
                                                authViewModel.currentUser?.userBackground = url
                                                if let x = viewModel.users.firstIndex(where: { $0.user.id == authViewModel.currentUser?.id }) {
                                                    viewModel.users[x].user.userBackground = url
                                                }
                                            }
                                        }
                                        successImage = true
                                        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                            self.selectedBackImage = nil
                                            self.newBackImage = nil
                                            successImage = false
                                        }
                                    }
                                } label: {
                                    if successImage {
                                        LottieView(loopMode: .playOnce, name: "image_success").frame(width: 60, height: 60)
                                    } else {
                                        Text("Save").foregroundColor(.blue).bold()
                                    }
                                }
                            }.padding(.top)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
            .blur(radius: (editName || changePass || verifyLogIn) ? 5 : 0)
            .scrollDismissesKeyboard(.immediately)
            
            if verifyLogIn {
                ZStack(alignment: .center){
                    Color.gray.opacity(0.3).onTapGesture { verifyLogIn = false }
                    VStack{
                        Spacer()
                        ZStack(alignment: .center){
                            Rectangle().foregroundColor(.white)
                            VStack(spacing: 0){
                                Text("Verify login to Delete Account")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.black)
                                Divider().padding(.top, 5)
                                Spacer()
                                VStack(alignment: .leading, spacing: 1){
                                    Text(deleteError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    VerifyField(placeholder: Text("Email"), text: $viewModel.deleteUsername)
                                        .onChange(of: viewModel.deleteUsername) { _, _ in
                                            if inputChecker().isValidEmail(viewModel.deleteUsername) {
                                                deleteError = ""
                                            } else {
                                                deleteError = "Invalid Email"
                                            }
                                        }
                                }
                                VerifyField(placeholder: Text("Password"), text: $viewModel.deletePassword)
                                    .padding(.top, 15)
                                    .onChange(of: viewModel.deletePassword) { _, _ in
                                        if viewModel.deletePassword.count < 8 {
                                            deleteError = "Password is too short"
                                        } else {
                                            deleteError = ""
                                        }
                                    }
                                Spacer()
                                Button {
                                    if deleteError.isEmpty && !viewModel.deletePassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.deleteUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        viewModel.deleteAccount(oldImage: authViewModel.currentUser?.profileImageUrl) { result in
                                            if result {
                                                ads.myAds = []
                                                explore.avoidReplies = []
                                                explore.joinedGroups = []
                                                explore.userGroup = nil
                                                messageLogOut.chats = []
                                                messageLogOut.currentChat = nil
                                                messageLogOut.gotConversations = false
                                                messageLogOut.priv_Key_Saved = nil
                                                messageLogOut.gotNotifications = false
                                                messageLogOut.notifs = []
                                                messageLogOut.secondary_notifs = []
                                                viewModel.currentUser = nil
                                                viewModel.exeFuncToDisplay = false
                                                viewModel.isCurrentUser = false
                                                viewModel.allContacts = []
                                                viewModel.contactFriends = []
                                                viewModel.tokenToShow = ""
                                                viewModel.unlockToShow = nil
                                                viewModel.blockedUsers = []
                                                authViewModel.signOut()
                                                stocks.gotUsersData = false
                                                feed.followers = []
                                                popRoot.tab = 1
                                                popRoot.lastSeen = nil
                                                globe.option = 2
                                                gc.chats = []
                                            } else {
                                                whichRetryOperation = true
                                                deleteErrorSheet = true
                                                verifyLogIn = false
                                            }
                                        }
                                    }
                                } label: {
                                    ZStack(alignment: .center){
                                        Rectangle().foregroundColor(.black)
                                        Text("DELETE ACCOUNT")
                                            .font(.subheadline).bold()
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.bottom, 5)
                                .frame(width: 300, height: 35)
                            }.padding(5)
                        }.frame(width: 320, height: 200)
                        Spacer()
                    }
                }.offset(y: -80).ignoresSafeArea()
            }
            if editName {
                ZStack(alignment: .center){
                    Color.gray.opacity(0.3).onTapGesture { editName = false }
                    VStack{
                        Spacer()
                        ZStack(alignment: .center){
                            Rectangle()
                                .foregroundColor(.white)
                            VStack(spacing: 0){
                                Text("Enter a new name")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.black)
                                Divider()
                                    .padding(.top, 5)
                                Spacer()
                                VStack(alignment: .leading, spacing: 2){
                                    if editNameError != "" && !editNameDone{
                                        Text(editNameError)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    VerifyField(placeholder: Text(authViewModel.currentUser?.fullname ?? ""), text: $viewModel.newName)
                                        .padding(.top, (editNameError == "" || editNameDone) ? 17 : 0)
                                        .onChange(of: viewModel.newName) { _, _ in
                                            editNameError = inputChecker().myInputChecker(withString: viewModel.newName, withLowerSize: 2, withUpperSize: 18, needsLower: true)
                                            if editNameError == "" {
                                                if viewModel.newName == authViewModel.currentUser?.fullname {
                                                    editNameError = "New name cannot match old"
                                                } else if viewModel.newName.lowercased() == "developer" {
                                                    editNameError = "Name cannot contain 'Developer'"
                                                } else {
                                                    editNameError = ""
                                                }
                                            }
                                        }
                                }
                                Spacer()
                                if !editNameDone{
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        if editNameError == "" && !viewModel.newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            viewModel.editName(name: viewModel.newName)
                                            authViewModel.currentUser?.fullname = viewModel.newName
                                            editNameDone = true
                                            viewModel.newName = ""
                                            Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                                                editName = false
                                            }
                                        }
                                    } label: {
                                        ZStack(alignment: .center){
                                            Rectangle()
                                                .foregroundColor(.black)
                                            Text("Save")
                                                .font(.subheadline).bold()
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.bottom, 5)
                                    .frame(width: 300, height: 35)
                                } else {
                                    ZStack(alignment: .center){
                                        Rectangle()
                                            .foregroundColor(.black)
                                        Text("Success!")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.bottom, 5)
                                    .frame(width: 300, height: 35)
                                }
                            }.padding(5)
                        }.frame(width: 320, height: 150)
                        Spacer()
                    }
                }.offset(y: -80).ignoresSafeArea()
            }
            if changePass {
                ZStack(alignment: .center){
                    Color.gray.opacity(0.3).onTapGesture { changePass = false }
                    VStack{
                        Spacer()
                        ZStack(alignment: .center){
                            Rectangle().foregroundColor(.white)
                            VStack(spacing: 0){
                                Text("Enter a new password")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.black)
                                Divider().padding(.top, 5)
                                Spacer()
                                VStack(alignment: .leading, spacing: 1){
                                    Text(oldLogInError).font(.caption).foregroundColor(.red)
                                    VerifyField(placeholder: Text("Email"), text: $viewModel.deleteUsername)
                                        .onChange(of: viewModel.deleteUsername) { _, _ in
                                            if inputChecker().isValidEmail(viewModel.deleteUsername) {
                                                oldLogInError = ""
                                            } else { oldLogInError = "Invalid Email" }
                                        }
                                }
                                VerifyField(placeholder: Text("Current password"), text: $viewModel.deletePassword)
                                    .padding(.top, 10)
                                    .onChange(of: viewModel.deletePassword) { _, _ in
                                        if viewModel.deletePassword.count < 8{
                                            oldLogInError = "Password is too short"
                                        } else { oldLogInError = "" }
                                    }
                                VStack(alignment: .leading, spacing: 2){
                                    if editPassError != "" && !editPassDone{
                                        Text(editPassError).font(.caption).foregroundColor(.red)
                                    }
                                    VerifyField(placeholder: Text("New password"), text: $viewModel.newPass)
                                        .onChange(of: viewModel.newPass) { _, _ in
                                            if viewModel.newPass.count < 8 {
                                                editPassError = "password too short"
                                            } else if viewModel.newPass.count > 20 {
                                                editPassError = "password too long"
                                            } else {
                                                editPassError = ""
                                            }
                                        }
                                }
                                .padding(.top, (editPassError == "" || editPassDone) ? 31.5 : 15)
                                Spacer()
                                if !editPassDone {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        if editPassError == "" && !viewModel.newPass.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && oldLogInError.isEmpty {
                                            viewModel.editPass { result in
                                                if result {
                                                    editPassDone = true
                                                    viewModel.newPass = ""
                                                    viewModel.deleteUsername = ""
                                                    viewModel.deletePassword = ""
                                                    Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                                        changePass = false
                                                    }
                                                } else {
                                                    whichRetryOperation = false
                                                    changePass = false
                                                    deleteErrorSheet = true
                                                }
                                            }
                                        }
                                    } label: {
                                        ZStack(alignment: .center){
                                            Rectangle().foregroundColor(.black)
                                            Text("Save")
                                                .font(.subheadline).bold()
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.bottom, 5)
                                    .frame(width: 300, height: 35)
                                } else {
                                    ZStack(alignment: .center){
                                        Rectangle().foregroundColor(.black)
                                        Text("Success")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.bottom, 5)
                                    .frame(width: 300, height: 35)
                                }
                            }.padding(5)
                        }.frame(width: 360, height: 155)
                        Spacer()
                    }
                }.offset(y: -80).ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showFixSheet, content: {
            RecommendTextView(oldText: $bio)
        })
        .sheet(isPresented: $showOnlineStatus, content: {
            SilentEditView()
        })
        .navigationBarBackButtonHidden(true)
        .dynamicTypeSize(.large)
        .onChange(of: bio) { _, _ in
            if let orig_bio = authViewModel.currentUser?.bio {
                if orig_bio == bio {
                    bioErr = " "
                } else {
                    bioErr = inputChecker().myInputChecker(withString: bio, withLowerSize: 0, withUpperSize: 150, needsLower: false)
                }
            } else {
                bioErr = inputChecker().myInputChecker(withString: bio, withLowerSize: 0, withUpperSize: 150, needsLower: false)
            }
            
            if bio.count > 15 && !showAI {
                withAnimation(.easeInOut(duration: 0.15)){
                    showAI = true
                }
            } else if bio.count <= 15 && showAI {
                withAnimation(.easeInOut(duration: 0.15)){
                    showAI = false
                }
            }
        }
        .onChange(of: editName) { _, _ in
            if !editName{
                editNameDone = false
            }
        }
        .onChange(of: changePass) { _, _ in
            if !changePass{
                editPassDone = false
            }
        }
        .onChange(of: popRoot.tap, { _, _ in
            if popRoot.tap == 6 && viewIsTop {
                presentationMode.wrappedValue.dismiss()
                popRoot.tap = 0
            }
        })
        .onAppear { 
            viewIsTop = true
            if let orig_bio = authViewModel.currentUser?.bio {
                self.bio = orig_bio
            }
        }
        .onDisappear { viewIsTop = false }
        .sheet(isPresented: $deleteErrorSheet) {
            VStack(alignment: .center){
                HStack{
                    Spacer()
                    Button {
                        deleteErrorSheet.toggle()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(width: 15, height: 15)
                    }
                }
                .padding(.top)
                .padding(.trailing)
                Divider().padding(.top, 10)
                Spacer()
                Image("warning").resizable().frame(width: 60, height: 60)
                Text(viewModel.deleteAccountError)
                    .padding(.top)
                    .font(.system(size: 18)).bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                Button {
                    deleteErrorSheet = false
                    if whichRetryOperation {
                        verifyLogIn = true
                    } else {
                        changePass = true
                    }
                } label: {
                    ZStack(alignment: .center){
                        Rectangle()
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(width: UIScreen.main.bounds.size.width * 0.8, height: 40)
                        Text("Retry")
                            .font(.subheadline).bold()
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                    }
                }
            }.presentationDetents([.fraction(0.45)])
        }
    }
    func loadImage() {
        guard let selectedImage = selectedImage else {return}
        newImage = Image(uiImage: selectedImage)
    }
    func loadBackImage() {
        guard let selectedImage = selectedBackImage else {return}
        newBackImage = Image(uiImage: selectedImage)
    }
}

struct VerifyField: View{
    var placeholder: Text
    @Binding var text: String
    
    var body: some View{
        ZStack(alignment: .leading){
            if text.isEmpty{
                placeholder
                    .opacity(0.5)
                    .offset(x: 15)
                    .foregroundColor(.black)
                    .font(.system(size: 17))
            }
            TextField("", text: $text)
                .padding(.leading)
                .padding(.trailing, 4)
                .frame(width: 300, height: 40)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray, lineWidth: 1)
                )
                .tint(.black)
                .foregroundColor(.black)
        }
    }
}
