import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @State private var email = ""
    @State private var username = ""
    @State private var fullname = ""
    @State private var password = ""
    @State private var emailError = ""
    @State private var usernameError = ""
    @State private var fullnameError = ""
    @State private var passwordError = ""
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var selection = 0
    @State private var userNameLoad = false
    @State private var registerLoad = false
    @State private var showCountryPicker = false
    @State private var selectedCountry = ""
    @State private var PassedCaptcha: Bool? = nil
    
    @State private var showAgree = false
    @State private var noNeed = ""
    
    var body: some View {
        VStack {
            if selection == 0 {
                ZStack {
                    VStack{
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
                        .padding(.top, 30)
                        .padding(.trailing, 28)
                        ScrollView {
                            if colorScheme == .dark {
                                Image("logoWhiteBack")
                                    .resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 150).padding(.top)
                                    .offset(x: 2)
                            } else {
                                Image("logoblack")
                                    .scaleEffect(0.8)
                                    .offset(x: 4, y: 10)
                            }
                            CustomTextField(imageName: "person", placeHolderText: "Full Name", text: $fullname)
                                .padding(.top, 8)
                                .padding(.horizontal, 40)
                                .onChange(of: fullname) { _ in
                                    fullnameError = inputChecker().myInputChecker(withString: fullname, withLowerSize: 1, withUpperSize: 15, needsLower: true)
                                    if fullnameError.isEmpty && fullname.lowercased().contains("developer"){
                                        fullnameError = "Name cannot contain 'developer'"
                                    }
                                }
                            if !fullname.isEmpty {
                                Text(fullnameError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.top, 5)
                            }
                        }
                        .padding(.top, 5)
                        .scrollDismissesKeyboard(.immediately)
                        Spacer()
                        Button {
                            if fullnameError.isEmpty && !fullname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                selection = 1
                            }
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .frame(width: 340, height: 50)
                                .background(Color((!fullname.isEmpty && fullnameError.isEmpty && !fullname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? .systemOrange : .systemGray).opacity(0.7))
                                .clipShape(Capsule())
                                .padding()
                        }.shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 0)
                    }
                    .blur(radius: PassedCaptcha == nil ? 9 : 0)
                    .onChange(of: PassedCaptcha) { _ in
                        if !(PassedCaptcha ?? true) {
                            presentationMode.wrappedValue.dismiss()
                            PassedCaptcha = nil
                        }
                    }
                    if let passed = PassedCaptcha, !passed {
                        CaptchaView(success: $PassedCaptcha)
                    } else if PassedCaptcha == nil {
                        CaptchaView(success: $PassedCaptcha)
                    }
                }
            }
            if selection == 1 {
                VStack{
                    HStack{
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selection = 0
                        } label: {
                            Image(systemName: "arrow.left")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                    }
                    .padding(.top, 30)
                    .padding(.leading, 28)
                    ScrollView{
                        if colorScheme == .dark {
                            Image("logoWhiteBack")
                                .resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 150).padding(.top)
                                .offset(x: 2)
                        } else {
                            Image("logoblack").scaleEffect(0.8).offset(x: 4, y: 10)
                        }
                        CustomTextField(imageName: "person", placeHolderText: "Username", text: $username)
                            .padding(.top, 8)
                            .padding(.horizontal, 40)
                            .onChange(of: username) { _ in
                                usernameError = inputChecker().myInputChecker(withString: username, withLowerSize: 1, withUpperSize: 12, needsLower: true)
                                if usernameError.isEmpty {
                                    if username.lowercased().contains("developer"){
                                        usernameError = "Username cannot contain 'developer'"
                                    } else if username.trimmingCharacters(in: .whitespacesAndNewlines).contains(" "){
                                        usernameError = "Username cannot contain whitespaces"
                                    } else if username.contains("@"){
                                        usernameError = "Username cannot contain @"
                                    } else if username.contains("#"){
                                        usernameError = "Username cannot contain #"
                                    }
                                }
                            }
                        if !username.isEmpty {
                            Text(usernameError)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 5)
                        }
                    }
                    .padding(.top, 5)
                    .scrollDismissesKeyboard(.immediately)
                    Spacer()
                    Button {
                        if usernameError.isEmpty && !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            userNameLoad = true
                            viewModel.checkUserNameInUse(username: username) { success in
                                userNameLoad = false
                                if success {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    selection = 2
                                } else {
                                    usernameError = "Username is taken"
                                }
                            }
                        }
                    } label: {
                        if !userNameLoad {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .frame(width: 340, height: 50)
                                .background(Color( (!username.isEmpty && usernameError.isEmpty && !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? .systemOrange : .systemGray).opacity(0.7))
                                .clipShape(Capsule())
                                .padding()
                        } else {
                            Loader(flip: true).id("\(UUID())")
                        }
                    }.shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 0)
                }.tag(1)
            }
            if selection == 2 {
                ZStack {
                    VStack{
                        HStack{
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selection = 1
                            } label: {
                                Image(systemName: "arrow.left")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                        }
                        .padding(.top, 30)
                        .padding(.leading, 28)
                        ScrollView{
                            if colorScheme == .dark {
                                Image("logoWhiteBack")
                                    .resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 150).offset(x: 2)
                            } else {
                                Image("nobacklogo")
                                    .resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 150).offset(x: 2)
                            }
                            VStack(alignment: .leading, spacing: 2){
                                Text(emailError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                CustomTextField(imageName: "envelope", placeHolderText: "Email", text: $email)
                            }
                            .padding(.horizontal, 40)
                            VStack(alignment: .leading, spacing: 2){
                                Text(passwordError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                CustomTextField1(text: $password, displayText: $noNeed)
                                HStack {
                                    Spacer()
                                    Link("By registering an account you agree to our Terms and Privacy Policy", destination: URL(string:"https://hustle.page")!)
                                        .font(.caption).foregroundColor(.blue)
                                        .multilineTextAlignment(.center).padding(.top, 3)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                        .scrollDismissesKeyboard(.immediately)
                        Spacer()
                        Button {
                            if passwordError.isEmpty && emailError.isEmpty && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !registerLoad {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                showAgree = true
                            }
                        } label: {
                            if !registerLoad {
                                Text("Sign Up")
                                    .font(.headline)
                                    .foregroundColor(colorScheme == .dark ? .black : .white)
                                    .frame(width: 340, height: 50)
                                    .background(Color((!password.isEmpty && passwordError.isEmpty && !email.isEmpty && emailError.isEmpty && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? .systemOrange : .systemGray).opacity(0.7))
                                    .clipShape(Capsule())
                                    .padding()
                            } else {
                                Loader(flip: true).id("\(UUID())")
                            }
                        }
                        .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 0)
                        .onChange(of: viewModel.registerError) { _ in
                            registerLoad = false
                            emailError = viewModel.registerError
                        }
                        .onDisappear {
                            registerLoad = false
                        }
                        .onChange(of: email) { _ in
                            viewModel.registerError = ""
                            if !inputChecker().isValidEmail(email){
                                emailError = "Email is invalid"
                            } else {
                                emailError = ""
                            }
                        }
                        .onChange(of: password) { _ in
                            viewModel.registerError = ""
                            if password.count < 8 {
                                passwordError = "Password has to be atleast 8 characters"
                            } else {
                                passwordError = ""
                            }
                        }
                    }
                    .disabled(showCountryPicker)
                    .blur(radius: showCountryPicker ? 5 : 0)
                    .onAppear {
                        if selectedCountry.isEmpty {
                            withAnimation(.easeInOut){
                                showCountryPicker = true
                            }
                        }
                    }
                    if showCountryPicker && selectedCountry.isEmpty {
                        CountryPicker(selectedCountry: $selectedCountry, update: false, background: false, close: $showCountryPicker)
                    }
                }
            }
        }
        .dynamicTypeSize(.large)
        .navigationBarHidden(true)
        .sheet(isPresented: $showAgree) {
            agreeView().presentationDetents([.large])
        }
    }
    func agreeView() -> some View {
        VStack(alignment: .leading){
            Text("Review and Agree to Terms").font(.title).bold()
            ScrollView {
                VStack {
                    Text("We are committed to maintaining a safe and respectful community for all users. We have a zero-tolerance policy for objectionable content and abusive behavior. Any content or actions that promote hate speech, harassment, discrimination, or any form of harm towards others will not be tolerated. Violation of these guidelines may result in the immediate suspension or termination of your account.").bold().padding(2).background(.yellow.opacity(0.2))
                    
                    Text("\nBy registering a Hustler account or utilizing the platform and our products, you implicitly consent to abide by these terms and conditions. ARBITRATION NOTICE: By agreeing to our Terms of Use and Privacy Policy, you recognize that any disputes between you and our organization will be settled exclusively through individual arbitration. Furthermore, you relinquish your entitlement to initiate a collective legal action or participate in arbitration on behalf of a collective.")
                    
                    HStack {
                        Text("About Our Service:").bold().font(.system(size: 19))
                        Spacer()
                    }.padding(.top, 8)
                    
                    LinkedText("\nTo ensure the efficient operation of our Service, it is crucial for us to store, transfer, and manage data across our global systems. Our Privacy Policy offers detailed information on how you can maintain control over your data. The words “we,” “us,” and “our” refer to HUSTLER INC LLC. Your utilization and engagement with the Services or any Content entail risks that you assume responsibility for. You acknowledge and consent that the Services are made accessible to you in their present state (“AS IS”) and availability, without any warranties or guarantees. Our service may display YouTube videos; therefore, in addition to your agreement to our terms, you must also abide by YouTube’s Terms of Service outlined here: https://www.youtube.com/static?template=terms.", tip: true, isMess: nil)
                    
                    HStack {
                        Text("How We Fund Our Service:").bold().font(.system(size: 19))
                        Spacer()
                    }.padding(.top, 8)
                    
                    Text("\nBy using the Service governed by these Terms, instead of charging a fee for accessing Hustler, you acknowledge that we have the ability to show you advertisements sponsored by members of Hustler, which can include companies, organizations, or businesses. These ads may be promoted on both the Hustler platform and elsewhere. Furthermore, the revenue generated from in-app purchases, particularly the acquisition of virtual points (“ELO”), supports the funding of our Services.")
                }
                VStack {
                    HStack {
                        Text("Your Commitments:\n").bold().font(.system(size: 19))
                        Spacer()
                    }.padding(.top, 8)
                    
                    Text("By using any of our services you acknowledge the following commitments you make to us.\n\n1. Your account must not have been previously disabled and/or deleted by us due to infringements of the law or our policy.\n\n2. Hustler strictly prohibits certain actions, including assuming false identities, supplying inaccurate information, or establishing an account on behalf of another individual without their explicit consent. While revealing your identity is not obligatory to fulfill your obligations to us, it is essential to note that impersonating someone or misrepresenting your true identity is strictly forbidden.\n\n3. Participating in unlawful or unauthorized activities is strictly forbidden. This encompasses any violation of our Terms and policies. If you come across explicit or illegal content, please reach out to us.\n\n4. Engaging in actions that interfere with or disrupt the proper operation of the Hustler platform is strictly prohibited. This includes any form of misuse of our designated services, such as submitting fraudulent or unsubstantiated claims through our contact page.\n\n5. Engaging in unauthorized methods to establish accounts, access, or gather information is strictly prohibited. This encompasses the automated generation of accounts. You are granted permission to view, share, and engage with the content presented to you. However, the deliberate collection of data displayed on our service is strictly forbidden.\n\n6. Participating in the sale, licensing, or acquisition of any accounts or data sourced from us or our Service is strictly prohibited. This includes all attempts to engage in buying, selling, or transferring any portion of your account, as well as soliciting or collecting login credentials, badges, or “ELO” from fellow users. Additionally, requesting or gathering Hustler usernames or passwords is strictly forbidden.\n\n7. Sharing private or confidential information of others without permission or engaging in activities that infringe upon someone else’s rights, including intellectual property rights, is strictly prohibited. However, you may make use of someone else’s works within the exceptions or limitations to copyright and related rights as outlined by applicable law. By sharing content, you confirm that you either own the content or have obtained all the requisite rights to publish or distribute it.\n\n8. By using our platform’s content uploading feature, you hereby acknowledge and consent to refrain from posting any material that contains nudity, pornography, profanity, or any content contravening the stipulations outlined within these terms of service.")
                    
                    HStack {
                        Text("Permissions You Give to Hustler:\n").bold().font(.system(size: 19))
                        Spacer()
                    }.padding(.top, 8)
                    
                    Text("Although we do not assert ownership of the content you publish on our Service, we do require a license from you to utilize it. Your rights to your content remain intact and unaffected. You possess the liberty to share your content with anyone, anywhere, as we do not lay claim to its ownership. Nevertheless, to deliver the Service, we necessitate specific legal permissions from you, commonly known as a “license.”\n\nWhen you share, post, or upload intellectual property-protected content on or via our Service, you provide us with a worldwide license that is non-exclusive, royalty-free, transferable, and sub-licensable. This license empowers us to store, utilize, distribute, modify, delete, copy, display, translate, and share your content, all while upholding your privacy. However, once your content is deleted from our systems, this license will no longer remain in effect.\n\nAdditionally, you consent to the installation of updates to our Service on your device. In specific situations, we reserve the right to modify your selected username or identifier for your account if we deem it necessary. This action may be taken, for instance, if it violates someone’s intellectual property rights, impersonates another user, or contains explicit content.\n\nEngaging in the act of altering, generating imitative works from, decompiling, or extracting source code from our platform and products is strictly prohibited.")
                    
                    HStack {
                        Text("Additional Provisions:\n").bold().font(.system(size: 19))
                        Spacer()
                    }.padding(.top, 8)
                    
                    Text("In the event that we ascertain that the content or information you contribute to the Service violates our Terms of Use or policies, or if we are legally authorized or obligated to take action, we maintain the prerogative to eliminate said content or information. Additionally, we possess the right to refuse the provision or suspend any part or the entirety of the Service to you indefinitely. It is your responsibility to ensure the security of your account by employing a robust password and restricting its usage solely to this particular account. Any loss or damage resulting from your failure to adhere to the aforementioned guidelines is beyond our liability and we cannot be held accountable for it. In light of the fact that our platform incorporates the display of YouTube videos, it is imperative that you concomitantly provide your consent to be bound by the Terms of Service and Privacy Policy of YouTube. Our platform provides a service to view asset price data and information, and such data may be incorrect or delayed. Do not use our asset price data to influence your asset management; always visit a trusted data provider to get an up-to-date overview of your assets. We hold no responsibility of incorrect asset data displayed to you through our service as our platform is distributed “As Is.”")
                }
                
                VStack {
                    HStack {
                        Text("How Disputes are Handled:\n").bold().font(.system(size: 19))
                        Spacer()
                    }.padding(.top, 8)
                    
                    Text("By making use of our services or products, you acknowledge and accept that any legal claim or dispute arising from or related to these Terms must be resolved exclusively through individual arbitration. Group actions and collective arbitrations are explicitly prohibited. Should you choose to delete your account, it will result in the termination of these terms and agreements between us.")
                    
                    HStack {
                        Text("Changing our Terms and Policies:\n").bold().font(.system(size: 19))
                        Spacer()
                    }.padding(.top, 8)
                    
                    Text("We maintain the authority to alter our Service and regulations, as it may become essential for us to adjust these Terms in accordance with our progressing Service and regulations. Prior to implementing any modifications to these Terms, we will furnish you with advanced notification. You will be given the chance to assess the revised Terms before they take effect. By choosing to continue utilizing the Service thereafter, you signify your consent to the updated Terms. Nevertheless, if you do not desire to consent to these modified Terms, you have the alternative to delete your account.")
                    
                    HStack {
                        Text("Terms and conditions of purchase:\n").bold().font(.system(size: 19))
                        Spacer()
                    }.padding(.top, 8)
                    Text("Please be advised that you bear full responsibility for all fees, charges, and expenses related to the utilization of the Services and Content provided by Hustler Inc LLC. In this regard, you hereby grant explicit authorization to Hustler Inc LLC to charge your card for any and all charges and fees accrued in connection with the aforementioned Services or Content. Furthermore, you hereby consent to the retention of your credit card information by Hustler Inc LLC for the duration necessary to fulfill all your payment obligations. It is essential to note that payments pertaining to “ELO” or the creation of ADS are non-refundable and non-reversible. In the event that you opt to promote posts through our platform, it is imperative that any associated promoted content adheres strictly to our Terms of Service and refrains from infringing upon the rights of any individual or entity. Should such promoted content be found in violation of our terms or the rights of any party, Hustler Inc LLC reserves the right to promptly delete said content without any entitlement to a refund. By making a purchase on our platform, you explicitly acknowledge your acceptance and agreement to abide by our Purchasers Terms, thereby binding yourself to the stated terms and conditions.")
                    
                    HStack {
                        Text("Advertising Standards and Requirements:\n").bold().font(.system(size: 19))
                        Spacer()
                    }.padding(.top, 8)
                    Text("To ensure the successful review of an advertisement submitted for publication on our platform, it is imperative that your content strictly adheres to the following stipulations. The profile utilized in conjunction with the advertisement must abstain from possessing, exhibiting, or disseminating any content that propagates hate speech, engages in harassment, fosters discrimination, or promotes any form of harm towards individuals or groups. Furthermore, the textual content integrated within the advertisement must not incorporate any profanity, hate speech, or information that infringes upon the rights of any entities or individuals. Web links embedded within the advertisement must not direct users to any illicit or harmful websites, encompassing, but not confined to, websites that exhibit nudity or explicit content, sites involved in the sale of illegal substances or contraband, sites housing malicious software, sites laden with an excessive number of intrusive pop-up advertisements, or sites that pose a risk to the security and integrity of users’ devices. Moreover, any images or videos appended to the advertisement must abstain from featuring any form of nudity, profanity, hate speech, harassment, discrimination, or content that may cause harm to others. Kindly be advised that advertisements found to contravene the aforementioned guidelines will be subject to rejection, accompanied by a full refund. In the event that an advertisement, once approved, is subsequently altered in a manner that transgresses these stipulations, the advertisement will be promptly removed, and a refund shall not be issued.").padding(.bottom, 50)
                }
            }.font(.system(size: 16)).scrollIndicators(.hidden)
            Button {
                showAgree = false
                registerLoad = true
                
                let final_username = username.trimmingCharacters(in: .whitespacesAndNewlines)
                
                viewModel.register(withEmail: email, password: password,
                                   fullname: fullname, username: final_username, country: selectedCountry){ bool in
                    if bool {
                        
                    } else {
                        registerLoad = false
                    }
                }
            } label: {
                ZStack {
                    Rectangle().fill(.blue.gradient)
                    Text("Agree to Terms").bold().font(.system(size: 18))
                }
            }.padding(.horizontal).frame(height: 40)
        }.padding()
    }
}
