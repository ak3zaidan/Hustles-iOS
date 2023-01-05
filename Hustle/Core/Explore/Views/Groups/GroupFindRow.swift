import SwiftUI
import Kingfisher

struct GroupFindRow: View {
    @State var online: Int = 1
    @Environment(\.colorScheme) var colorScheme
    let group: GroupX
    var body: some View {
        VStack(spacing: 0){
            ZStack(alignment: .topTrailing){
                KFImage(URL(string: group.imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: widthOrHeight(width: true) * 0.45, height: 130)
                    .clipped()
                Image(systemName: group.publicstatus ? "lock.open" : "lock").foregroundStyle(.green).bold()
                    .font(.subheadline).padding(8).background(.ultraThinMaterial).clipShape(Circle()).padding(4)
            }
            VStack(spacing: 3){
                HStack {
                    Text(group.title).font(.title3).bold()
                    Spacer()
                }.padding(.top, 22).padding(.leading, 5)
                HStack {
                    if group.desc.isEmpty {
                        Text("The official group for \(group.title)").font(.system(size: 13))
                    } else {
                        Text(group.desc).font(.system(size: 13)).lineLimit(3).truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }.padding(.horizontal, 5)
                Spacer()
                HStack {
                    Circle().frame(width: 8)
                    if group.members.count == 1 {
                        Text("\(group.members.count) Member").font(.system(size: 12))
                    } else {
                        Text("\(group.members.count) Members").font(.system(size: 12))
                    }
                    Spacer()
                }.padding(.horizontal, 5)
                HStack {
                    Circle().foregroundStyle(.green).frame(width: 8)
                    Text("\(online) Online").font(.system(size: 12))
                    Spacer()
                }.padding(.leading, 5).padding(.bottom, 10)
            }
            .frame(height: 155)
            .background(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray).opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .frame(width: widthOrHeight(width: true) * 0.45)
        .overlay {
            VStack {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15).frame(width: 48, height: 48).foregroundStyle((colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray)))
                        KFImage(URL(string: group.imageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    Spacer()
                }.padding(.leading, 13).offset(y: 105)
                Spacer()
            }
        }
        .onAppear {
            let top = max(1, group.members.count)
            online = Int.random(in: 0...top)
        }
    }
}
