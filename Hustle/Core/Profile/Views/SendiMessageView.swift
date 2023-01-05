import SwiftUI
import MessageUI
import Contacts
import Kingfisher

struct matchFriends: Identifiable, Hashable {
    let id: UUID = UUID()
    let user: User
    let number: String?
}

struct Friends: Hashable {
    var name: String
    var phoneNumber: String
    var image: Data?

    init(name: String, phoneNumber: String, image: Data? = nil) {
        self.name = name
        self.phoneNumber = phoneNumber
        self.image = image
    }

    func getImage() -> Image? {
        if let imageData = image {
            if let ui_temp = UIImage(data: imageData) {
                return Image(uiImage: ui_temp)
            }
            return nil
        }
        return nil
    }
}

struct FindFriendsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @State private var isShowingMessages = false
    @State private var recipients: [String] = []
    @State private var message = "Download Hustles, the leading social media and entrepreneurship platform. https://apps.apple.com/us/app/hustles/id6452946210"
    @FocusState private var focusField: FocusedField?
    @State private var viewIsTop = false
        
    var body: some View {
        VStack {
            ZStack {
                VStack(spacing: 4){
                    HStack {
                        Spacer()
                        Text("Add Friends").font(.title2).bold()
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Circle().frame(width: 5).foregroundStyle(.green)
                        Text("99+ suggestions were active in the last day!")
                            .foregroundStyle(.gray).font(.caption)
                        Spacer()
                    }
                }
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        if let current = auth.currentUser, !profile.fetching {
                            profile.fetching = true
                            profile.start(uid: current.id ?? "", currentUser: current, optionalUser: nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                profile.fetching = false
                            }
                        }
                    }, label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .font(.title3).bold()
                    })
                    Spacer()
                }.padding(.leading)
            }
            
            TextField("Search", text: $viewModel.searchText)
                .tint(.blue)
                .autocorrectionDisabled(true)
                .padding(8)
                .padding(.horizontal, 24)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .focused($focusField, equals: .one)
                .onSubmit {
                    focusField = .two
                    if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.UserSearch(userId: auth.currentUser?.id ?? "")
                        viewModel.submitted = true
                    }
                }
                .onChange(of: viewModel.searchText) { _, _ in
                    viewModel.noUsersFound = false
                    viewModel.UserSearchBestFit()
                    viewModel.submitted = false
                }
                .overlay (
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        Spacer()
                        if viewModel.loading {
                            ProgressView().padding(.trailing, 10)
                        } else if !viewModel.searchText.isEmpty {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.searchText = ""
                            }, label: {
                                ZStack {
                                    Circle().foregroundStyle(.gray).opacity(0.001)
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.gray).font(.headline).bold()
                                }.frame(width: 40, height: 40)
                            })
                        }
                    }.padding(.leading, 8)
                )
                .padding(.horizontal, 15).padding(.top, 12)
            
            ScrollView {
                VStack(spacing: 15){
                    if !viewModel.matchedUsers.isEmpty {
                        VStack(spacing: 5){
                            HStack {
                                Text("Search Results")
                                    .font(.system(size: 17)).bold()
                                Spacer()
                            }
                            VStack(spacing: 10){
                                ForEach(viewModel.matchedUsers){ user in
                                    NavigationLink {
                                        ProfileView(showSettings: false, showMessaging: true, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: true, isMain: false)
                                    } label: {
                                        userRow(user: user, phone: user.phoneNumber)
                                    }
                                    if let last = viewModel.matchedUsers.last, last != user {
                                        Divider().overlay(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    if !profile.contactFriends.isEmpty {
                        VStack(spacing: 5){
                            HStack {
                                Text("Members from Contacts")
                                    .font(.system(size: 17)).bold()
                                Spacer()
                            }
                            VStack(spacing: 10){
                                ForEach(profile.contactFriends){ contact in
                                    NavigationLink {
                                        ProfileView(showSettings: false, showMessaging: true, uid: contact.user.id ?? "", photo: contact.user.profileImageUrl ?? "", user: contact.user, expand: true, isMain: false)
                                    } label: {
                                        userRow(user: contact.user, phone: contact.number)
                                    }
                                    if let last = profile.contactFriends.last, last.user != contact.user {
                                        Divider().overlay(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    if !profile.allContacts.isEmpty {
                        VStack(spacing: 5){
                            HStack {
                                Text("Invite from Contacts")
                                    .font(.system(size: 17)).bold()
                                Spacer()
                            }
                            HStack {
                                Circle().frame(width: 4).foregroundStyle(.green)
                                Text("Bonus 15 ELO per Invite")
                                    .font(.system(size: 14)).bold()
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                            VStack(spacing: 10){
                                ForEach(profile.allContacts, id: \.self){ contact in
                                    if !profile.contactFriends.contains(where: { $0.number ?? "NA" == contact.phoneNumber }) && !contact.name.isEmpty && !contact.phoneNumber.isEmpty {
                                        
                                        userRowInvite(name: contact.name, phone: contact.phoneNumber, image: contact.getImage())
                                        
                                        if let last = profile.allContacts.last, last != contact {
                                            Divider().overlay(.gray)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }.padding(.horizontal, 15).padding(.top)
                Color.clear.frame(height: 100)
            }
        }
        .onAppear(perform: {
            viewIsTop = true
        })
        .onDisappear(perform: {
            viewIsTop = false
        })
        .onChange(of: popRoot.tap, { _, _ in
            if viewIsTop {
                presentationMode.wrappedValue.dismiss()
                popRoot.tap = 0
                if let current = auth.currentUser, !profile.fetching {
                    profile.fetching = true
                    profile.start(uid: current.id ?? "", currentUser: current, optionalUser: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        profile.fetching = false
                    }
                }
            }
        })
        .padding(.top, top_Inset())
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .sheet(isPresented: self.$isShowingMessages) {
            MessageUIView(recipients: $recipients, body: $message, completion: handleCompletion(_:))
        }
    }
    func userRow(user: User, phone: String?) -> some View {
        HStack {
            if let image = user.profileImageUrl {
                KFImage(URL(string: image))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width:40, height: 40)
                    .clipShape(Circle())
                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
            } else {
                ZStack(alignment: .center){
                    Image(systemName: "circle.fill")
                        .resizable()
                        .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                        .frame(width: 40, height: 40)
                    Image(systemName: "person").font(.headline).foregroundStyle(.white)
                }
            }
            VStack {
                HStack {
                    Text(user.fullname).font(.headline).bold()
                    Spacer()
                }
                HStack {
                    if let new = phone, !new.isEmpty {
                        Text("@\(user.username) - \(new)")
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .font(.subheadline).bold()
                            .foregroundStyle(.gray)
                    } else {
                        Text("@\(user.username)")
                            .font(.subheadline).bold()
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
            }
            Spacer()
            Button(action: {
                if let curr = auth.currentUser, let id = user.id, curr.following.contains(id) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    auth.currentUser?.following.removeAll(where: { $0 == id })
                    UserService().unfollow(withUid: id) { }
                    if let x = profile.users.firstIndex(where: { $0.user.id == curr.id }) {
                        profile.users[x].user.following.removeAll(where: { $0 == id })
                    }
                } else if let id = user.id {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    auth.currentUser?.following.append(id)
                    UserService().follow(withUid: id) { }
                    if let curr = auth.currentUser {
                        if let x = profile.users.firstIndex(where: { $0.user.id == curr.id }) {
                            profile.users[x].user.following.append(id)
                        }
                    }
                }
            }, label: {
                if let curr = auth.currentUser, let id = user.id, curr.following.contains(id) {
                    Text("Following").font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text("Follow").font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            })
        }
    }
    func userRowInvite(name: String, phone: String, image: Image?) -> some View {
        HStack {
            ZStack {
                Image(systemName: "circle.fill")
                    .resizable()
                    .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                    .frame(width: 40, height: 40)
                Image(systemName: "person").font(.headline).foregroundStyle(.white)
                if let newI = image {
                    newI
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
            }
            VStack {
                HStack {
                    Text(name).font(.headline).bold()
                    Spacer()
                }
                HStack {
                    Text(phone)
                        .font(.subheadline).bold()
                        .foregroundStyle(.gray)
                    Spacer()
                }
            }
            Spacer()
            Button(action: {
                if !profile.invited.contains(phone) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    recipients = [phone]
                    isShowingMessages = true
                }
            }, label: {
                if !profile.invited.contains(phone) {
                    Text("Invite").font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text("Invited").font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            })
        }
    }
    func handleCompletion(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            break
        case .sent:
            if let first = recipients.first {
                profile.invited.append(first)
                auth.currentUser?.elo += 15
                if let curr = auth.currentUser {
                    if let x = profile.users.firstIndex(where: { $0.user.id == curr.id }) {
                        profile.users[x].user.elo += 15
                    }
                }
                UserService().editElo(withUid: nil, withAmount: 15) { }
            }
            break
        case .failed:
            break
        @unknown default:
            break
        }
    }
}

struct addPhoneNumber: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State var newPhone: String = ""
    @State var error: String = ""
    @EnvironmentObject var auth: AuthViewModel
    @Binding var showFriends: Bool
    @EnvironmentObject var viewModel: ProfileViewModel
        
    var body: some View {
        VStack(spacing: 15){
            Text("Enter your Phone Number")
                .font(.title2).bold()
            Text("Hustles needs one time access to find freinds from your contacts.").font(.caption).multilineTextAlignment(.center).foregroundStyle(.gray)
            Divider().overlay(.gray)
            TextField("Phone Number...", text: $newPhone)
                .tint(.blue)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.15))
                .clipShape(Capsule())
                .padding(.horizontal)
                .padding(.top)
                .onChange(of: newPhone) { _, _ in
                    if !containsOnlyDigits(newPhone) {
                        error = "Phone number can only contain digits."
                    } else if newPhone.count < 5 || newPhone.count > 15 {
                        error = "Incorrect length."
                    } else {
                        error = ""
                    }
                }
            Text(error).foregroundStyle(.red).font(.subheadline)
            Spacer()
            Button {
                if error.isEmpty && !newPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    UserService().addNumber(new: newPhone)
                    auth.currentUser?.phoneNumber = newPhone
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    if viewModel.allContacts.isEmpty {
                        fetchContacts { final in
                            self.viewModel.allContacts = final
                            self.viewModel.getContacts()
                            presentationMode.wrappedValue.dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showFriends = true
                            }
                        }
                    } else {
                        self.viewModel.getContacts()
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showFriends = true
                        }
                    }
                }
            } label: {
                Text("Save").foregroundStyle(.white).bold()
                    .font(.headline)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 100)
                    .background(error.isEmpty && !newPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .blue : .gray)
                    .clipShape(Capsule())
            }.padding(.bottom)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium])
        .padding(.top)
    }
    func containsOnlyDigits(_ input: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[0-9]+$")
        return regex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count)) != nil
    }
}

func fetchContacts(completion: @escaping([Friends]) -> Void) {
    var friendsArray = [Friends]()

    let contactStore = CNContactStore()

    contactStore.requestAccess(for: .contacts, completionHandler: { (granted, error) in
        if granted {
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])

            do {
                try contactStore.enumerateContacts(with: request, usingBlock: { (contact, stop) in
                    let givenName = contact.givenName
                    let familyName = contact.familyName
                    let phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
                    let imageData = contact.imageData

                    let friend = Friends(name: "\(givenName) \(familyName)", phoneNumber: phoneNumbers.first ?? "", image: imageData)
                    friendsArray.append(friend)
                })
                completion( friendsArray.sorted(by: { one, two in
                    return one.name < two.name
                }) )
            } catch {
                completion(friendsArray)
                print("Error fetching contacts: \(error.localizedDescription)")
            }
        } else {
            completion(friendsArray)
            print("Access to contacts denied.")
        }
    })
}

protocol MessagessViewDelegate {
    func messageCompletion (result: MessageComposeResult)
}

class MessagesViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    var delegate: MessagessViewDelegate?
    var recipients: [String]?
    var body: String?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func displayMessageInterface() {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self

        // Configure the fields of the interface.
        composeVC.recipients = self.recipients ?? []
        composeVC.body = body ?? ""

        // Present the view controller modally.
        if MFMessageComposeViewController.canSendText() {
            self.present(composeVC, animated: true, completion: nil)
        } else {
            self.delegate?.messageCompletion(result: MessageComposeResult.failed)
        }
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
        self.delegate?.messageCompletion(result: result)
    }
}

struct MessageUIView: UIViewControllerRepresentable {
    // To be able to dismiss itself after successfully finishing with the MessagesUI
    @Environment(\.presentationMode) var presentationMode
    @Binding var recipients: [String]
    @Binding var body: String
    var completion: ((_ result: MessageComposeResult) -> Void)

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MessagesViewController {
        let controller = MessagesViewController()
        controller.delegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }

    func updateUIViewController(_ uiViewController: MessagesViewController, context: Context) {
        uiViewController.recipients = recipients
        uiViewController.displayMessageInterface()
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, MessagessViewDelegate {
        var parent: MessageUIView

        init(_ controller: MessageUIView) {
            self.parent = controller
        }

        func messageCompletion(result: MessageComposeResult) {
            self.parent.presentationMode.wrappedValue.dismiss()
            self.parent.completion(result)
        }
    }
}
