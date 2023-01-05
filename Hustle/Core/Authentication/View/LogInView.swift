import SwiftUI
import LocalAuthentication
import AuthenticationServices

struct LogInView: View {
    @State private var showReset = false
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var success = false
    @Environment(\.presentationMode) var presentationMode
    @State var displayText: String = ""
    
    var body: some View {
        ZStack(alignment: .top){
            HStack{
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.orange)
                }
            }
            .padding(.trailing, 30)
            .padding(.top, 20)
            .ignoresSafeArea(.keyboard)
            
            VStack {
                if colorScheme == .dark {
                    Image("logoWhiteBack")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
                        .offset(x: 2)
                        .padding(.top)
                } else {
                    Image("logoblack")
                        .scaleEffect(0.8)
                        .offset(x: 4, y: 10)
                }
                HStack{
                    if password.count > 7 && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.signInError.isEmpty && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            save(email: email, password: password)
                        } label: {
                            Text("Save password").font(.caption).fontWeight(.semibold).foregroundColor(Color(.systemOrange))
                                .padding(.leading, 24)
                        }
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showReset.toggle()
                    } label: {
                        Text("Forgot passowrd").font(.caption).fontWeight(.semibold).foregroundColor(Color(.systemOrange))
                            .padding(.trailing, 24)
                    }
                }.padding(.top, 10)
                VStack(spacing: 15){
                    CustomTextField2(text: $email)
                    CustomTextField1(text: $password, displayText: $displayText)
                }.padding(.horizontal, 32)
            }.padding(.top, widthOrHeight(width: false) * 0.07).ignoresSafeArea()
            
            VStack(spacing: 1){
                Spacer()
                Text(viewModel.signInError)
                    .foregroundColor(.red)
                    .font(.footnote)
                Button {
                    if password.count > 7 {
                        if inputChecker().isValidEmail(email) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if !success && viewModel.signInError.isEmpty && !email.isEmpty {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                withAnimation() {
                                    success = true
                                }
                                viewModel.login(withEmail: email, password: password)
                            }
                        } else {
                            viewModel.signInError = "Email is invalid"
                        }
                    } else {
                        viewModel.signInError = "Password is too short"
                    }
                } label: {
                    if !success {
                        Text("Sign in")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(width: 300, height: 50)
                            .background(Color((password.count > 7 && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.signInError.isEmpty && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? .systemOrange : .systemGray).opacity(0.7))
                            .clipShape(Capsule())
                            .padding()
                    } else {
                        Loader(flip: true).id("\(UUID())").padding(.bottom, 20)
                    }
                }
                .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 0)
            }
        }
        .dynamicTypeSize(.large)
        .navigationBarHidden(true)
        .onAppear(perform: authenticate)
        .fullScreenCover(isPresented: $showReset){
            ResetPassword()
        }
        .onChange(of: email) { _ in
            viewModel.signInError = ""
        }
        .onChange(of: password) { _ in
            viewModel.signInError = ""
        }
        .onChange(of: viewModel.signInError) { _ in
            success = false
        }
        .onDisappear{
            viewModel.signInError = ""
        }
        .onChange(of: showReset) { _ in
            viewModel.signInError = ""
            password = ""
        }
    }
    func save(email: String, password: String) {
        let passwordData = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "https://hustle.page",
            kSecAttrAccount as String: email,
            kSecValueData as String: passwordData
        ]
        let saveStatus = SecItemAdd(query as CFDictionary, nil)
        if saveStatus == errSecDuplicateItem {
            update(email: email, password: password)
        }
    }
    func update(email: String, password: String) {
        if let result = read(service: "https://hustle.page"){
            if result.0 == email {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: "https://hustle.page",
                    kSecAttrAccount as String: email
                ]
                let passwordData = password.data(using: .utf8)!
                let updatedData: [String: Any] = [
                    kSecValueData as String: passwordData
                ]
                
                SecItemUpdate(query as CFDictionary, updatedData as CFDictionary)
            } else {
                delete(email: result.0)
                save(email: email, password: password)
            }
        }
    }
    func delete(email: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "https://hustle.page",
            kSecAttrAccount as String: email
        ]
        SecItemDelete(query as CFDictionary)
    }
    func read(service: String) -> (String, String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let item = result as? [String: Any] {
            if let account = item[kSecAttrAccount as String] as? String,
               let passwordData = item[kSecValueData as String] as? Data,
               let password = String(data: passwordData, encoding: .utf8) {
               return (account, password)
            }
        }
        return nil
    }
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Secure Authentication."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        if let loginInfo = self.read(service: "https://hustle.page") {
                            let (email, password) = loginInfo
                            self.email = email
                            self.password = password
                            self.displayText = String(repeating: "*", count: password.count)
                        }
                    }
                }
            }
        }
    }
}

struct SecureUIKitField: UIViewRepresentable {
    @Binding var password: String
    
    func makeUIView(context: Context) -> UITextField {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true
        secureField.borderStyle = .roundedRect
        secureField.translatesAutoresizingMaskIntoConstraints = false
        return secureField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = password
        uiView.placeholder = "Password"
    }
}
