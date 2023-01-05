import SwiftUI
import Firebase

struct PollRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let choice1: String
    let choice2: String
    let choice3: String?
    let choice4: String?
    @State var count1: Int
    @State var count2: Int
    @State var count3: Int?
    @State var count4: Int?
    @State var p1: Double = 0.0
    @State var p2: Double = 0.0
    @State var p3: Double = 0.0
    @State var p4: Double = 0.0
    let hustleID: String
    let whoVoted: [String]
    let timestamp: Timestamp
    @State var dateFinal: String = "0 days"
    @EnvironmentObject var viewModel: FeedViewModel
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        VStack(spacing: 10){
            ZStack {
                let suffix = String((auth.currentUser?.id ?? "").suffix(5))
                if viewModel.votedPosts.contains(hustleID) || whoVoted.contains(suffix) {
                    let total = 2 + (choice3 == nil ? 0 : 1) + (choice4 == nil ? 0 : 1)
                    GeometryReader(content: { geometry in
                        VStack(spacing: 5){
                            status(p: p1, choice: choice1, width: geometry.size.width)
                            status(p: p2, choice: choice2, width: geometry.size.width)
                            if let choice = choice3 {
                                status(p: p3, choice: choice, width: geometry.size.width)
                            }
                            if let choice = choice4 {
                                status(p: p4, choice: choice, width: geometry.size.width)
                            }
                        }
                    })
                    .transition(.move(edge: .trailing))
                    .frame(height: CGFloat(total * 30 + total * 5 - 5))
                    .onAppear {
                        if p1 == 0.0 && p2 == 0.0 && p3 == 0.0 && p4 == 0.0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                                getPercents()
                            }
                        }
                    }
                } else {
                    VStack(spacing: 5){
                        voteButton(choice: choice1, num: 1)
                        voteButton(choice: choice2, num: 2)
                        if let choice = choice3 {
                            voteButton(choice: choice, num: 3)
                        }
                        if let choice = choice4 {
                            voteButton(choice: choice, num: 4)
                        }
                    }
                    .transition(.move(edge: .leading))
                }
            }
            let total: Int = count1 + count2 + (count3 ?? 0) + (count4 ?? 0) + (viewModel.votedPosts.contains(auth.currentUser?.id ?? "") ? 1 : 0)
            let singleExcp: String = (total == 1) ? "Vote" : "Votes"
            HStack {
                Text("\(total) \(singleExcp) - \(dateFinal)").font(.subheadline).foregroundStyle(.gray)
                Spacer()
            }
        }
        .onAppear {
            if dateFinal == "0 days" {
                let timestamp = timestamp.dateValue()
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
                
                let timeDifference = Calendar.current.dateComponents([.year, .month, .weekOfYear, .day, .hour], from: timestamp, to: Date())
                
                if let years = timeDifference.year, years > 0 {
                    dateFinal = "\(years) year" + (years > 1 ? "s ago" : " ago")
                } else if let months = timeDifference.month, months > 0 {
                    dateFinal = "\(months) month" + (months > 1 ? "s ago" : " ago")
                } else if let weeks = timeDifference.weekOfYear, weeks > 0 {
                    dateFinal = "\(weeks) week" + (weeks > 1 ? "s ago" : " ago")
                } else if let days = timeDifference.day, days > 0 {
                    dateFinal = "\(days) day" + (days > 1 ? "s ago" : " ago")
                } else if let hours = timeDifference.hour, hours > 0 {
                    dateFinal = "\(hours) hour" + (hours > 1 ? "s ago" : " ago")
                } else {
                    dateFinal = "Less than an hour ago"
                }
            }
        }
    }
    func getPercents(){
        let total = Double(count1 + count2 + (count3 ?? 0) + (count4 ?? 0))
        
        withAnimation(.bouncy(duration: 0.25)){
            p1 = Double(count1) / total
            p2 = Double(count2) / total
            p3 = Double(count3 ?? 0) / total
            p4 = Double(count4 ?? 0) / total
        }
    }
    func status(p: Double, choice: String, width: CGFloat) -> some View {
        ZStack(alignment: .leading){
            UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: Int(p * 100.0) == 100 ? 8 : 0, topTrailingRadius: Int(p * 100.0) == 100 ? 8 : 0)
                .foregroundStyle(.gray).opacity(colorScheme == .dark ? 0.5 : 0.3)
                .frame(width: ((p * width) > 3.0) ? p * width : 3.0)
            HStack {
                Text(choice).font(.system(size: 18)).lineLimit(1).minimumScaleFactor(0.7).truncationMode(.tail)
                Spacer()
                Text("\(Int(p * 100.0))%")
            }.padding(.horizontal, 10)
        }.frame(height: 30)
    }
    func voteButton(choice: String, num: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)){
                viewModel.votedPosts.append(hustleID)
            }
            if num == 1 {
                count1 += 1
            } else if num == 2 {
                count2 += 1
            } else if num == 3 {
                count3 = (count3 ?? 0) + 1
            } else {
                count4 = (count4 ?? 0) + 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                getPercents()
            }
            TweetService().votePoll(tweetID: hustleID, count: num)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }, label: {
            Capsule()
                .stroke(.blue, lineWidth: 2)
                .frame(height: 26)
                .overlay {
                    Text(choice).font(.system(size: 16)).bold().foregroundStyle(.blue)
                        .lineLimit(1).minimumScaleFactor(0.7).truncationMode(.tail)
                }
        })
    }
}
