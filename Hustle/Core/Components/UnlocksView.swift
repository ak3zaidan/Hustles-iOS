import SwiftUI

struct UnlocksView: View {
    @State var num: Int
    @State var unlocked: String
    @State var access: [String]
    @State var nextAccess: String

    init(num: Int){
        self.num = num
        if num == 1 {
            self.unlocked = "pawn"
            self.nextAccess = "BISHOP"
            self.access = ["-1 hustle per hour", "-1 job/sale per hour", "-Create 1 Group", "-Ask Questions"]
        } else if num == 2 {
            self.unlocked = "bishop"
            self.nextAccess = "KNIGHT"
            self.access = ["**Create Unlimited Groups**", "-3 Hustles or jobs per hour", "-Answer questions", "-Cast a vote"]
        } else if num == 3 {
            self.unlocked = "knight"
            self.nextAccess = "ROOK"
            self.access = ["-Upload tips 1 per hour", "**Promote posts with ELO**", "-Unlimited Hustle/Job upload"]
        } else if num == 4 {
            self.unlocked = "rook"
            self.nextAccess = "QUEEN"
            self.access = ["-Unlimited Tip upload", "-Auto promoted Shop Posts", "-Bonus 150 ELO"]
        } else if num == 5 {
            self.unlocked = "queen"
            self.nextAccess = "KING"
            self.access = ["-no delay in collection posts", "-Auto promoted Jobs", "-Bonus 100 ELO"]
        } else {
            self.unlocked = "king"
            self.nextAccess = "COMING SOON"
            self.access = ["-Auto promoted Hustles", "-Communicate with Developers", "-Featured Comments on Posts", "-Auto promoted questions"]
        }
    }

    var body: some View {
        ZStack(alignment: .center){
            Color.gray.opacity(0.01)
            VStack{
                Spacer()
                ZStack {
                    TransparentBlurView(removeAllFilters: true)
                        .blur(radius: 9, opaque: true)
                        .background(Color(UIColor.lightGray).opacity(0.4))
                        .cornerRadius(20)
                    VStack{
                        Text("You unlocked \(unlocked.uppercased()) status")
                            .font(.title3).bold()
                            .foregroundColor(.green)
                        HStack {
                            image(num: num)
                            VStack{
                                HStack(spacing: 1){
                                    Image(systemName: "lock")
                                    Text("Unlocked Access:").font(.subheadline).bold()
                                    Spacer()
                                }.padding(.bottom, 3)
                                ForEach(access, id: \.self){ access in
                                    HStack{
                                        Text(access)
                                            .multilineTextAlignment(.leading)
                                            .font(.caption)
                                            .padding(.bottom, 1)
                                        Spacer()
                                    }
                                }.padding(.leading, 7)
                                HStack{
                                    Spacer()
                                    Text("Next Rank: \(nextAccess)")
                                        .foregroundColor(.green)
                                        .font(.subheadline).bold()
                                    Spacer()
                                }.padding(.top)
                            }
                        }.padding(.leading, 5)
                    }.padding(5)
                }.frame(width: 320, height: 250)
                Spacer()
            }
        }.ignoresSafeArea()
    }
    func image(num: Int) -> some View {
        VStack{
            if num == 1{
                Image("pawn").resizable().frame(width: 85, height: 140)
            } else if num == 2{
                Image("bishop").resizable().frame(width: 85, height: 160)
            } else if num == 3{
                Image("knight")
                    .resizable()
                    .shadow(color: .green, radius: 5, x: 0, y: 0).frame(width: 85, height: 150)
            } else if num == 4{
                Image("rook")
                    .resizable()
                    .shadow(color: .yellow, radius: 10, x: 0, y: 0)
                    .shadow(color: .yellow, radius: 5, x: 0, y: 0)
                    .shadow(color: .yellow, radius: 2, x: 0, y: 0).frame(width: 85, height: 135)
            } else if num == 5{
                Image("queen")
                    .resizable()
                    .shadow(color: .black, radius: 25, x: 0, y: 0)
                    .shadow(color: .red, radius: 5, x: 0, y: 0)
                    .shadow(color: .red, radius: 5, x: 0, y: 0).frame(width: 85, height: 160)
            } else {
                Image("king")
                    .resizable()
                    .shadow(color: .black, radius: 25, x: 0, y: 0)
                    .shadow(color: .blue, radius: 10, x: 0, y: 0)
                    .shadow(color: .blue, radius: 5, x: 0, y: 0)
                    .shadow(color: .red, radius: 3, x: 0, y: 0).frame(width: 85, height: 160)
            }
        }
    }
}
