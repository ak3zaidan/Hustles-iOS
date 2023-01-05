import SwiftUI

struct bannerView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var popRoot: PopToRoot
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: popRoot.alertImage).font(.title3)
                    .foregroundStyle(.blue)
                Text(popRoot.alertReason)
                Spacer()
            }.padding(.horizontal)
            Button(action: {
                withAnimation {
                    popRoot.showAlert = false
                }
            }, label: {
                HStack {
                    Spacer()
                    Text("Dismiss").font(.subheadline).bold()
                    Spacer()
                }
                .padding(.vertical, 7)
                .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }).padding(.horizontal).offset(y: 5)
        }
        .frame(height: 100)
        .background {
            ZStack {
                if colorScheme == .dark {
                    Color.black
                    Color.blue.opacity(0.15)
                } else {
                    Color.white
                    Color.blue.opacity(0.05)
                }
            }
        }
        .overlay(content: {
            RoundedRectangle(cornerRadius: 15)
                .stroke(.blue, lineWidth: 1.0)
        })
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 3)
        .padding(.horizontal)
        .onAppear(perform: {
            let id = UUID().uuidString
            popRoot.alertID = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if popRoot.alertID == id {
                    withAnimation {
                        popRoot.showAlert = false
                    }
                }
            }
        })
        .onChange(of: popRoot.alertReason) { _, _ in
            let id = UUID().uuidString
            popRoot.alertID = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if popRoot.alertID == id {
                    withAnimation {
                        popRoot.showAlert = false
                    }
                }
            }
        }
    }
}

struct ChatSentBanner: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var popRoot: PopToRoot
    
    var body: some View {
        HStack {
            Spacer()
            Text(popRoot.chatSentError ? "Error Sending Chat!" : "Chat Sent").bold()
            Spacer()
        }
        .padding(.horizontal).padding(.vertical, 7)
        .background {
            Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 3)
        .padding(.horizontal)
        .onAppear(perform: {
            let id = popRoot.chatAlertID
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if popRoot.chatAlertID == id {
                    withAnimation {
                        popRoot.chatSentAlert = false
                    }
                }
            }
        })
        .onChange(of: popRoot.chatAlertID) { _, _ in
            let id = UUID().uuidString
            popRoot.chatAlertID = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if popRoot.chatAlertID == id {
                    withAnimation {
                        popRoot.chatSentAlert = false
                    }
                }
            }
        }
    }
}
