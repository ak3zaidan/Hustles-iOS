import SwiftUI

struct WelcomeView: View {
    let impact = UIImpactFeedbackGenerator(style: .light)
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.orange, .white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center){
                Text("Welcome to").font(.system(size: 40))
                Text("Hustles").font(.system(size: 40)).bold()
                Text("The everything app that will help you grow.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                    .padding(.top, 15)
                Spacer()
                HStack {
                    NavigationLink {
                        RegistrationView()
                    } label: {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 130, height: 40)
                            .background(Color(.systemOrange).opacity(0.7))
                            .clipShape(Capsule())
                            .padding()
                    }.shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 0)
                    NavigationLink {
                        LogInView()
                    } label: {
                        Text("Log In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 130, height: 40)
                            .background(Color(.systemOrange).opacity(0.7))
                            .clipShape(Capsule())
                            .padding()
                    }.shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 0)
                }
            }
            .padding(.bottom, 40)
            .padding(.top, 75)
        }
    }
}

