import SwiftUI
import Firebase

struct SendEloBubble: View {
    @Binding var time: Bool
    let message: Message
    let displayTime: Bool
    let recieved: Bool
    @State private var showTime = false
    var body: some View {
        HStack{
            if displayTime{
                if recieved{
                    if showTime {
                        Text("\(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 5)
                    }
                } else {
                    Spacer()
                }
            }
            ZStack(alignment: .center){
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 100,height: 70)
                    .foregroundColor(.gray).opacity(0.7)
                VStack{
                    HStack{
                        Text("$ELO")
                            .font(.system(size: 10))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.leading, 8)
                    Spacer()
                }
                VStack{
                    Spacer()
                    Text(message.elo ?? "0")
                        .font(.system(size: 21)).bold()
                        .foregroundColor(.black)
                    Spacer()
                }
            }
            .frame(width: 100,height: 70)
            .onTapGesture {
                showTime.toggle()
                time.toggle()
            }
            if displayTime{
                if !recieved {
                    if showTime {
                        Text("\(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 5)
                    }
                } else {
                    Spacer()
                }
            }
        }
    }
}

struct SendEloBubbleSec: View {
    let amount: String
    var body: some View {
        ZStack(alignment: .center){
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 100,height: 70)
                .foregroundColor(.gray).opacity(0.7)
            VStack{
                HStack{
                    Text("$ELO")
                        .font(.system(size: 10))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.leading, 8)
                Spacer()
            }
            VStack{
                Spacer()
                Text(amount)
                    .font(.system(size: 21)).bold()
                    .foregroundColor(.black)
                Spacer()
            }
        }.frame(width: 100,height: 70)
    }
}

