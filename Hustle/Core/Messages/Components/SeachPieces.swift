import SwiftUI
import Kingfisher

struct CallRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let call: callInfo
    
    var body: some View {
        VStack {
            
        }
    }
}

struct userViewOne: View {
    @Environment(\.colorScheme) var colorScheme
    let user: User

    var body: some View {
        VStack {
            HStack {
                if let image = user.profileImageUrl {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    ZStack(alignment: .center){
                        Image(systemName: "circle.fill")
                            .resizable()
                            .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                            .frame(width: 40, height: 40)
                        Image(systemName: "questionmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 12, height: 17)
                    }
                }
                VStack(alignment: .leading){
                    Text(user.fullname).lineLimit(1).font(.system(size: 16))
                    Text("@\(user.username)").foregroundStyle(.gray).font(.caption)
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 3)
        }
        .frame(height: 50)
        .background(colorScheme == .dark ? .black : .white)
        .cornerRadius(8, corners: .allCorners)
        .shadow(color: .gray, radius: 4)
    }
}

struct userViewTwo: View {
    @Environment(\.colorScheme) var colorScheme
    let user: User
    
    var body: some View {
        VStack {
            VStack {
                if let image = user.profileImageUrl {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    ZStack(alignment: .center){
                        Image(systemName: "circle.fill")
                            .resizable()
                            .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                            .frame(width: 50, height: 50)
                        Image(systemName: "questionmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 15, height: 20)
                    }
                }
                VStack {
                    Text(user.fullname).lineLimit(1).font(.system(size: 15))
                    Spacer()
                    Text("Chat").foregroundStyle(.gray).font(.caption)
                        .padding(.vertical, 3).padding(.horizontal, 12).background(.gray.opacity(0.2))
                        .cornerRadius(8, corners: .allCorners)
                }.padding(.vertical, 3)
            }
            .padding(.vertical, 8)
        }
        .frame(width: 98, height: 120)
        .background(colorScheme == .dark ? .black : .white)
        .cornerRadius(8, corners: .allCorners)
        .shadow(color: .gray, radius: 4)
    }
}

struct userViewThree: View {
    @Environment(\.colorScheme) var colorScheme
    let user: User
    @State var randomA: Int = 5
    
    var body: some View {
        VStack {
            HStack {
                if let image = user.profileImageUrl {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    ZStack(alignment: .center){
                        Image(systemName: "circle.fill")
                            .resizable()
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                        Image(systemName: "questionmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 12, height: 17)
                    }
                }
                VStack(alignment: .leading){
                    Text(user.fullname).lineLimit(1).font(.system(size: 16))
                    Text("@\(user.username)").foregroundStyle(.gray).font(.caption)
                }
                Spacer()
                Text("\(randomA)+ mutal friends").font(.caption)
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal, 10).padding(.vertical, 3)
        }
        .frame(height: 50)
        .onAppear {
            randomA = Int.random(in: 0..<100)
        }
    }
}

struct groupView: View {
    @Environment(\.colorScheme) var colorScheme
    let group: GroupX
    
    var body: some View {
        VStack {
            HStack {
                KFImage(URL(string: group.imageUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                VStack(alignment: .leading){
                    Text(group.title).lineLimit(1).font(.system(size: 16))
                    Text("\(group.members.count) members").foregroundStyle(.gray).font(.caption)
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 3)
        }
        .frame(height: 50)
        .background(colorScheme == .dark ? .black : .white)
        .cornerRadius(8, corners: .allCorners)
        .shadow(color: .gray, radius: 4)
    }
}

struct userViewOneX: View {
    @Environment(\.colorScheme) var colorScheme
    let user: User
    let selected: Bool

    var body: some View {
        VStack {
            HStack {
                if let image = user.profileImageUrl {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    ZStack(alignment: .center){
                        Image(systemName: "circle.fill")
                            .resizable()
                            .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                            .frame(width: 40, height: 40)
                        Image(systemName: "questionmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 12, height: 17)
                    }
                }
                VStack(alignment: .leading){
                    Text(user.fullname).lineLimit(1).font(.system(size: 16))
                        .foregroundStyle(selected ? .blue : colorScheme == .dark ? .white : .black)
                    Text("@\(user.username)").foregroundStyle(selected ? .blue : .gray).font(.caption)
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 3)
        }
        .frame(height: 50)
        .background(colorScheme == .dark ? .black : .white)
        .cornerRadius(8, corners: .allCorners)
        .shadow(color: .gray, radius: 4)
    }
}

struct userViewTwoX: View {
    @Environment(\.colorScheme) var colorScheme
    let user: User
    let selected: Bool
    
    var body: some View {
        VStack {
            VStack {
                if let image = user.profileImageUrl {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    ZStack(alignment: .center){
                        Image(systemName: "circle.fill")
                            .resizable()
                            .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                            .frame(width: 50, height: 50)
                        Image(systemName: "questionmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 15, height: 20)
                    }
                }
                VStack {
                    Text(user.fullname).lineLimit(1).font(.system(size: 14))
                        .foregroundStyle(selected ? .blue : colorScheme == .dark ? .white : .black)
                    Spacer()
                    if selected {
                        ZStack {
                            Circle().frame(width: 20, height: 20).foregroundStyle(.blue)
                            Image(systemName: "checkmark").foregroundStyle(.white).font(.subheadline)
                        }
                    } else {
                        Circle().stroke(.gray, lineWidth: 1).frame(width: 20, height: 20)
                    }
                }.padding(.vertical, 3)
            }
            .padding(.vertical, 8)
        }
        .frame(width: 98, height: 120)
        .background(colorScheme == .dark ? .black : .white)
        .cornerRadius(8, corners: .allCorners)
        .shadow(color: .gray, radius: 4)
    }
}

struct userViewThreeX: View {
    @Environment(\.colorScheme) var colorScheme
    let user: User
    let selected: Bool
    
    var body: some View {
        VStack {
            HStack {
                if let image = user.profileImageUrl {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    ZStack(alignment: .center){
                        Image(systemName: "circle.fill")
                            .resizable()
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                        Image(systemName: "questionmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 12, height: 17)
                    }
                }
                VStack(alignment: .leading){
                    Text(user.fullname).lineLimit(1).font(.system(size: 16))
                        .foregroundStyle(selected ? .blue : colorScheme == .dark ? .white : .black)
                    Text("@\(user.username)").foregroundStyle(selected ? .blue : .gray).font(.caption)
                }
                Spacer()
                if selected {
                    ZStack {
                        Circle().frame(width: 25, height: 25).foregroundStyle(.blue)
                        Image(systemName: "checkmark").foregroundStyle(.white).font(.headline)
                    }
                } else {
                    Circle().stroke(.gray, lineWidth: 1).frame(width: 25, height: 25)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 3)
        }
        .frame(height: 50)
    }
}

struct groupViewX: View {
    @Environment(\.colorScheme) var colorScheme
    let group: GroupX
    let selected: Bool
    
    var body: some View {
        VStack {
            HStack {
                KFImage(URL(string: group.imageUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                VStack(alignment: .leading){
                    Text(group.title).lineLimit(1).font(.system(size: 16))
                        .foregroundStyle(selected ? .blue : colorScheme == .dark ? .white : .black)
                    Text("\(group.members.count) members").font(.caption)
                        .foregroundStyle(selected ? .blue : .gray)
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 3)
        }
        .frame(height: 50)
        .background(colorScheme == .dark ? .black : .white)
        .cornerRadius(8, corners: .allCorners)
        .shadow(color: .gray, radius: 4)
    }
}

struct groupViewThreeX: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let photo: String?
    let selected: Bool
    
    var body: some View {
        VStack {
            HStack {
                if let image = photo {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    ZStack(alignment: .center){
                        Image(systemName: "circle.fill")
                            .resizable()
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                        Image(systemName: "questionmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 12, height: 17)
                    }
                }
                VStack(alignment: .leading){
                    Text(title).lineLimit(1).font(.system(size: 16)).truncationMode(.tail)
                        .foregroundStyle(selected ? .blue : colorScheme == .dark ? .white : .black)
                    Text("GroupChat").foregroundStyle(.gray).font(.caption)
                }
                Spacer()
                if selected {
                    ZStack {
                        Circle().frame(width: 25, height: 25).foregroundStyle(.blue)
                        Image(systemName: "checkmark").foregroundStyle(.white).font(.headline)
                    }
                } else {
                    Circle().stroke(.gray, lineWidth: 1).frame(width: 25, height: 25)
                }
            }.padding(.horizontal, 10).padding(.vertical, 3)
        }.frame(height: 50)
    }
}

struct groupViewThreeSearch: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let photo: String?
    
    var body: some View {
        VStack {
            HStack {
                if let image = photo {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    ZStack(alignment: .center){
                        Image(systemName: "circle.fill")
                            .resizable()
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                        Image(systemName: "questionmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 12, height: 17)
                    }
                }
                VStack(alignment: .leading){
                    Text(title).lineLimit(1).font(.system(size: 16)).truncationMode(.tail)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    Text("GroupChat").foregroundStyle(.gray).font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.gray).font(.headline)
            }.padding(.horizontal, 10).padding(.vertical, 3)
        }.frame(height: 50)
    }
}

struct mapViewSearchRowUser: View {
    @Environment(\.colorScheme) var colorScheme
    let name: String
    let photo: String?
    let info: String?
    
    var body: some View {
        VStack {
            HStack {
                ZStack {
                    let first = name.first ?? Character("M")
                    personLetterView(size: 45, letter: String(first))
                    if let image = photo {
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                    }
                }
                VStack(alignment: .leading){
                    Text(name).lineLimit(1).font(.system(size: 16)).truncationMode(.tail)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    Text(info ?? "Click to see on map").foregroundStyle(.gray).font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.gray).font(.headline)
            }.padding(.horizontal, 10).padding(.vertical, 3)
        }.frame(height: 50)
    }
}
