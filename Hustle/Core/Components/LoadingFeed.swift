import SwiftUI

struct LoadingFeed: View {
    let lesson: String
    
    var body: some View {
        VStack {
            HStack(alignment: .top){
                if lesson.isEmpty {
                    Circle()
                        .frame(width: 56, height: 56)
                        .foregroundColor(.gray)
                } else {
                    Image("app")
                        .resizable()
                        .frame(width: 56, height: 56)
                        .scaledToFill()
                        .clipShape(Circle())
                }
                VStack(alignment: .leading){
                    Capsule()
                        .frame(width: 110, height: 20)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                        .overlay {
                            if !lesson.isEmpty {
                                Text("@Developer").font(.subheadline).bold()
                                    .padding(.top, 3)
                            }
                        }
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: widthOrHeight(width: true) * 0.7, height: 100)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                        .overlay {
                            VStack{
                                HStack{
                                    Text(lesson)
                                        .font(.subheadline)
                                        .padding(10)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                }.padding(.leading)
                Spacer()
            }.padding(.leading)
            Divider()
                .padding(.top)
        }
    }
}
