import SwiftUI

struct PromoteELO: View {
    @State var numDays = 0
    @Binding var days: Int
    @State var eloAmount = 0
    var userElo: Int
    
    var body: some View {
        VStack {
            HStack{
                Spacer()
                Text("You'd have \(userElo - (50 * days)) ELO").font(.subheadline).foregroundColor(.gray)
            }
            HStack(spacing: 40){
                Button {
                    if days > 0 {
                        withAnimation{
                            eloAmount -= 50
                            days = eloAmount / 50
                        }
                    }
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10).frame(width: 35, height: 35).foregroundColor(.blue)
                        Image(systemName: "minus").bold()
                    }
                }
                ZStack {
                    Circle()
                        .trim(from: 0, to: Double(days * 90) / 360)
                        .stroke(Color.green, lineWidth: 10)
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90.0))
                    VStack {
                        Text("\(days) day").bold()
                        Text("Promotion").bold()
                    }
                }
                Button {
                    if (userElo - (eloAmount - 50) > 0) && days < 4 {
                        withAnimation{
                            eloAmount += 50
                            days = eloAmount / 50
                        }
                    }
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10).frame(width: 35, height: 35).foregroundColor(.blue)
                        Image(systemName: "plus").bold()
                    }
                }
            }.padding(.top, 10)
        }
        .dynamicTypeSize(.large)
        .padding()
    }
}
