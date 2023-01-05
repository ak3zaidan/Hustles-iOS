import SwiftUI
import Lottie

struct ResetPassword: View {
    @State var success = false
    @State var showHelp = false
    @State private var email = ""
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.orange)
                }
            }
            .padding(.trailing, 25)
            .padding(.top)
            if colorScheme == .dark {
                Image("logoWhiteBack")
                    .resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 150).offset(x: 2)
            } else {
                Image("nobacklogo")
                    .resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 150).offset(x: 4)
            }
            HStack{
                Spacer()
                Button {
                    showHelp.toggle()
                } label: {
                    Text("Contact Us")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.systemOrange))
                        .padding(.trailing, 24)
                }
            }.padding(.top, 15)
            CustomTextField(imageName: "envelope", placeHolderText: "Account Email", text: $email)
                .padding(.horizontal, 32)
                .onChange(of: email) { _ in
                    if inputChecker().isValidEmail(email){
                        viewModel.resetError = ""
                    } else {
                        viewModel.resetError = "Email is invalid"
                    }
                }
            Text(viewModel.resetError)
                .foregroundColor(.red)
                .font(.subheadline)
            Spacer()
            Button {
                if !success {
                    viewModel.resetPassword(email: email) { success in
                        if success{
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            viewModel.resetError = ""
                            self.success = true
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                self.success = false
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            } label: {
                if !success{
                    Text("Send email reset link")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: 340, height: 50)
                        .background(Color((!email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? .systemOrange : .systemGray))
                        .clipShape(Capsule())
                        .padding()
                } else {
                    HStack(alignment: .center, spacing: 20){
                        Text("Check your email").foregroundColor(colorScheme == .dark ? .white : .black)
                        LottieView(loopMode: .playOnce, name: "image_success").frame(width: 60, height: 60)
                    }
                }
            }
            .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 0)
        }
        .dynamicTypeSize(.large)
        .navigationBarHidden(true)
        .onChange(of: email) { _ in
            viewModel.resetError = ""
        }
        .onDisappear{
            viewModel.resetError = ""
        }
        .fullScreenCover(isPresented: $showHelp){
            HelpView()
        }
    }
}
