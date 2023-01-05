import SwiftUI
import Firebase

struct InviteBubble: View {
    let message: Message
    @State private var showTime = false
    @EnvironmentObject var viewModel: MessageViewModel
    @State var dateFinal: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack{
            if showTime {
                Text("\(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 5)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.orange).gradient.opacity(colorScheme == .dark ? 0.3 : 0.7))
                VStack{
                    VStack(spacing: 2){
                        Text("You've been Invited")
                            .font(.caption)
                            .padding(.top, 2)
                        Text(message.text?.components(separatedBy: "priv!@#$%^&*()").last ?? "")
                            .font(.title3)
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.acceptInvt(groupId: message.text?.components(separatedBy: "priv!@#$%^&*()").first ?? "", message: message)
                    } label: {
                        ZStack(alignment: .center){
                            Rectangle()
                                .cornerRadius(8, corners: [.bottomRight, .bottomLeft])
                                .foregroundColor(.blue)
                            Text("Accept")
                                .foregroundColor(.white)
                                .font(.system(size: 15).bold())
                        }
                    }.frame(width: 250, height: 27)
                }
            }
            .frame(width: 250, height: 80)
            .onTapGesture {
                showTime.toggle()
            }
            Spacer()
        }.padding(.leading).padding(.vertical, 2)
    }
}
