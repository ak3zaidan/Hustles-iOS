import SwiftUI

struct PromoteUSD: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selection: Int
    var body: some View {
        VStack(alignment: .center,spacing: 15){
            HStack(spacing: 10){
                Button {
                    selection = 0
                } label: {
                    ZStack(alignment: .top){
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 2)
                            .background(selection == 0 ? Color.orange.opacity(0.4) : Color.clear)
                        VStack{
                            Spacer()
                            VStack{
                                Text("Promote")
                                    .foregroundColor(colorScheme == .dark ? .white : .black).bold()
                                Text("0 day")
                                    .foregroundColor(colorScheme == .dark ? .white : .black).bold()
                                    .padding(.bottom)
                            }
                            Text("$0").foregroundColor(.gray).font(.subheadline)
                        }
                    }
                }.frame(width: 90, height: 90)
                Button {
                    selection = 3
                } label: {
                    ZStack(alignment: .top){
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 2)
                            .background(selection == 3 ? Color.orange.opacity(0.4) : Color.clear)
                        VStack{
                            Spacer()
                            VStack{
                                Text("Promote")
                                    .foregroundColor(colorScheme == .dark ? .white : .black).bold()
                                Text("3 day")
                                    .foregroundColor(colorScheme == .dark ? .white : .black).bold()
                                    .padding(.bottom)
                            }
                            Text("$3.99")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                    }
                }.frame(width: 90, height: 90)
                Button {
                    selection = 1
                } label: {
                    ZStack(alignment: .top){
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 2)
                            .background(selection == 1 ? Color.orange.opacity(0.4) : Color.clear)
                        VStack{
                            Spacer()
                            VStack{
                                Text("Promote")
                                    .foregroundColor(colorScheme == .dark ? .white : .black).bold()
                                Text("1 day")
                                    .foregroundColor(colorScheme == .dark ? .white : .black).bold()
                                    .padding(.bottom)
                            }
                            Text("$1.99")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                    }
                }.frame(width: 90, height: 90)
            }
            if selection == 1 || selection == 3 {
                HStack(spacing: 5){
                    Image(systemName: "checkmark")
                        .foregroundColor(.orange)
                    Text("Double the views")
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
        }
    }
}

