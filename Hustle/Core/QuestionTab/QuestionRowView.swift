import SwiftUI
import Firebase
import Kingfisher

struct QuestionRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let question: Question
    let bottomPad: Bool
    @State var dateFinal: String = "Asked recently"
    var body: some View {
        VStack(alignment: .leading){
            Text(question.title ?? "").font(.system(size: 17)).multilineTextAlignment(.leading)
            HStack {
                VStack(alignment: .leading, spacing: 6){
                    Text("\(question.answersCount ?? 0) answers").foregroundColor(.gray).font(.subheadline)
                    Text("\(question.votes) votes").foregroundColor(.gray).font(.subheadline)
                }
                Spacer()
                VStack{
                    HStack {
                        if let image = question.profilePhoto {
                            ZStack {
                                personView(size: 30)
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width:30, height: 30)
                                    .clipShape(Circle())
                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                            }
                        } else {
                            personView(size: 30)
                        }
                        VStack(alignment: .leading, spacing: 3){
                            Text(question.username).font(.subheadline).bold()
                            Text(dateFinal).font(.caption).fontWeight(.semibold).foregroundColor(.gray)
                        }.padding(.trailing, 20)
                    }
                }
            }
            HStack {
                HStack(spacing: 10) {
                    ForEach(question.tags ?? [], id: \.self){ text in
                        Text(text)
                            .minimumScaleFactor(0.7).lineLimit(1)
                            .font(.caption).fontWeight(.semibold)
                            .frame(height: 20)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .background {
                                RoundedRectangle(cornerRadius: 5).fill(.blue.gradient)
                            }
                        
                    }
                }
                if let promoted = question.promoted?.dateValue(), Timestamp().dateValue() <= promoted {
                    Text("Promoted")
                        .minimumScaleFactor(0.7).lineLimit(1)
                        .font(.caption).fontWeight(.semibold)
                        .frame(height: 20)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .background {
                            RoundedRectangle(cornerRadius: 5).fill(.orange.gradient)
                        }
                }
                Spacer()
            }
            Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray)
                .padding(.top, bottomPad ? 5 : 0)
        }
        .padding(.horizontal)
        .onAppear {
            let dateString = question.timestamp.dateValue().formatted(.dateTime.month().day().year().hour().minute())
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
            if let date = dateFormatter.date(from:dateString){
                if Calendar.current.isDateInToday(date){
                    dateFinal = "Asked today at \(question.timestamp.dateValue().formatted(.dateTime.hour().minute()))"
                }
                else if Calendar.current.isDateInYesterday(date) {
                    dateFinal = "Asked Yesterday"}
                else{
                    if let dayBetween  = Calendar.current.dateComponents([.day], from: question.timestamp.dateValue(), to: Date()).day{
                        dateFinal = "Asked \(dayBetween + 1) days ago"
                    }
                }
            }
        }
    }
}
