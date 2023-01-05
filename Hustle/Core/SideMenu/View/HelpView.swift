import SwiftUI

struct HelpView: View {
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var profileModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var reason: String = ""
    @State private var email: String = ""
    @State private var caption: String = ""
    @State var success: Bool = false
    @State private var captionError: String = ""
    @State private var reasonError: String = ""
    @State private var emailError: String = " "
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    @FocusState private var isFocusedSec: Bool
    @FocusState private var isFocusedThird: Bool
    @State private var viewIsTop = false
    var body: some View {
        VStack(alignment: .leading){
            ZStack(){
                Color(.orange).opacity(0.7).ignoresSafeArea()
                HStack{
                    Text("Contact Us by Email")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.title2)
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack(spacing: 2){
                            Image(systemName: "chevron.backward")
                                .scaleEffect(1.5)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 15, height: 15)
                            Text("back")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top)
            }.frame(height: 80)
            if !success {
                ScrollView(){
                    VStack(alignment: .center){
                        if authViewModel.currentUser == nil {
                            HStack(alignment: .bottom, spacing: 5){
                                Text("Email")
                                    .font(.title2)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .padding(.top, 20)
                                Text(emailError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.bottom, 3)
                                Spacer()
                            }
                            CustomTextField(imageName: "envelope", placeHolderText: "", text: $email)
                                .focused($isFocusedThird)
                                .onChange(of: email) { _ in
                                    if inputChecker().isValidEmail(email) {
                                        emailError = ""
                                    } else {
                                        emailError = "Email is invalid"
                                    }
                                }
                        }
                        HStack(alignment: .bottom, spacing: 5){
                            Text("Contact Reason")
                                .font(.title2)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.top, 20)
                            Text(reasonError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.bottom, 3)
                            Spacer()
                        }
                        CustomTextField(imageName: "questionmark", placeHolderText: "", text: $reason)
                            .focused($isFocusedSec)
                            .onChange(of: reason) { _ in
                                reasonError = inputChecker().myInputChecker(withString: reason, withLowerSize: 1, withUpperSize: 80, needsLower: true)
                            }
                        HStack(alignment: .bottom, spacing: 5){
                            Text("Description")
                                .font(.title2)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.top, 20)
                            Text(captionError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.bottom, 3)
                            Spacer()
                        }
                        TextArea("", text: $caption)
                            .focused($isFocused)
                            .tint(colorScheme == .dark ? .gray : .black)
                            .frame(height: 125)
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.gray, lineWidth: isFocused ? 2 : 1)
                            }
                            .onChange(of: caption) { _ in
                                captionError = inputChecker().myInputChecker(withString: caption, withLowerSize: 10, withUpperSize: 1000, needsLower: true)
                            }
                        Spacer()
                    }.padding(.horizontal, 32)
                }
                .gesture(
                    DragGesture()
                        .onChanged { _ in
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                )
                HStack{
                    Spacer()
                    Button {
                        if !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && reasonError.isEmpty && captionError.isEmpty && ((authViewModel.currentUser != nil) || emailError.isEmpty) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            success = true
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                reason = ""
                                caption = ""
                                success = false
                                presentationMode.wrappedValue.dismiss()
                            }
                            profileModel.sendEmail(body: caption, subject: reason, email: email)
                        }
                    } label: {
                        Text("Send Email")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(width: 300, height: 50)
                            .background(Color((!reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && reasonError.isEmpty && captionError.isEmpty && ((authViewModel.currentUser != nil) || emailError.isEmpty)) ? .systemOrange : .systemGray).opacity(0.7))
                            .clipShape(Capsule())
                            .padding()
                    }
                    Spacer()
                }
            } else {
                HStack{
                    Spacer()
                    successEmail()
                    Spacer()
                }.padding(.top, 50)
                Spacer()
            }
        }
        .padding(.bottom, isFocused || isFocusedSec || isFocusedThird ? 0 : 45)
        .onChange(of: success, perform: { _ in
            if success == false {
                reasonError = ""
                captionError = ""
            }
        })
        .navigationBarBackButtonHidden(true)
        .onChange(of: popRoot.tap, perform: { _ in
            if popRoot.tap == 6 && viewIsTop {
                presentationMode.wrappedValue.dismiss()
                popRoot.tap = 0
            }
        })
        .onAppear { viewIsTop = true }
        .onDisappear { viewIsTop = false }
    }
    func successEmail() -> some View{
        VStack(alignment: .center){
            LottieView(loopMode: .loop, name: "success").frame(width: 85, height: 85)
            Text("Thanks for contacting Us.")
                .bold()
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
            Text("We will be with you in 1-5 days.")
                .bold()
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
            Spacer()
        }
    }
}
