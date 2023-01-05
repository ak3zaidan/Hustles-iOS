import SwiftUI
import Kingfisher
import Firebase

struct ImageQuestionRow: View {
    @Environment(\.colorScheme) var colorScheme
    let question: Question
    let bottomPad: Bool
    @State var dateFinal: String = "Asked recently"
    var body: some View {
        VStack {
            VStack(spacing: 3){
                Color.clear.frame(height: 3)
                if let url = question.image1 {
                    HStack {
                        HStack(alignment: .top){
                            if let image = question.profilePhoto {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width:35, height: 35)
                                    .clipShape(Circle())
                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                            } else {
                                ZStack(alignment: .center){
                                    Image(systemName: "circle.fill")
                                        .resizable()
                                        .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                                        .frame(width: 35, height: 35)
                                    Image(systemName: "questionmark")
                                        .resizable()
                                        .foregroundColor(.white)
                                        .frame(width: 14, height: 17)
                                }
                            }
                            VStack(alignment: .leading, spacing: 10){
                                Text(question.username).font(.system(size: 18)).bold()
                                Text("\(question.answersCount ?? 0) answers").foregroundColor(.gray).font(.subheadline)
                                Text("\(question.votes) votes").foregroundColor(.gray).font(.subheadline)
                            }.padding(.top, 4)
                            Spacer()
                        }.padding(.leading)
                        Spacer()
                        ZStack(alignment: .bottomTrailing){
                            if let url2 = question.image2 {
                                HStack {
                                    KFImage(URL(string: url2))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: widthOrHeight(width: true) * 0.4, height: widthOrHeight(width: true) * 0.4)
                                        .clipped()
                                        .cornerRadius(15)
                                        .rotationEffect(.degrees(-3))
                                }.padding(.bottom, 10).padding(.trailing, 15)
                            }
                            KFImage(URL(string: url))
                                .resizable()
                                .scaledToFill()
                                .frame(width: widthOrHeight(width: true) * 0.4, height: widthOrHeight(width: true) * 0.4)
                                .clipped()
                                .cornerRadius(15)
                            VStack {
                                Text("Promoted")
                                    .font(.system(size: 11)).fontWeight(.semibold)
                                    .frame(height: 18)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 3)
                                    .background { Capsule().fill(.orange.gradient) }
                            }.padding(7)
                        }
                    }.padding(.trailing, 8)
                }
                HStack {
                    Text(question.caption)
                        .font(.system(size: 16)).multilineTextAlignment(.leading)
                        .lineLimit(3).truncationMode(.tail)
                    Spacer()
                }.padding(.horizontal, 7)
                HStack {
                    Spacer()
                    Text(dateFinal).font(.caption).bold().foregroundColor(.gray)
                }.padding(.trailing)
                Color.clear.frame(height: 2)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .padding(10)
            Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray)
                .padding(.top, bottomPad ? 5 : 0).padding(.horizontal)
        }
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
