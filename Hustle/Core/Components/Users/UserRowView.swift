import SwiftUI
import Kingfisher

struct UserRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let user: User
    let showFullName: Bool
    let showMessaging: Bool
    let showSeenNow: Bool
    let seen: String
    let now: Bool
    let excep: Bool

    var body: some View {
        NavigationLink {
            ProfileView(showSettings: false, showMessaging: showMessaging, uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, expand: true, isMain: false)
                .dynamicTypeSize(.large).enableFullSwipePop(true)
        } label: {
            HStack(spacing: 8){
                if let image = user.profileImageUrl {
                    ZStack {
                        personView(size: excep ? 45 : (showFullName ? 50 : 46))
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: excep ? 45 : (showFullName ? 50 : 46), height: excep ? 45 : (showFullName ? 50 : 46))
                            .clipShape(Circle())
                    }
                } else {
                    personView(size: excep ? 45 : (showFullName ? 50 : 46))
                }
                if showSeenNow {
                    VStack(alignment: .leading, spacing: 2){
                        HStack(spacing: 3){
                            if let silent = user.silent {
                                if silent == 1 {
                                    Circle().foregroundStyle(.green).frame(width: 7, height: 7)
                                } else if silent == 2 {
                                    Image(systemName: "moon.fill").foregroundStyle(.yellow).font(.headline)
                                } else if silent == 3 {
                                    Image(systemName: "slash.circle.fill").foregroundStyle(.red).font(.headline)
                                } else {
                                    Image("ghostMode")
                                        .resizable().scaledToFit().frame(width: 14, height: 14).scaleEffect(1.3)
                                }
                            } else if now {
                                Circle().foregroundStyle(.green).frame(width: 7, height: 7)
                            }
                            
                            Text(user.fullname)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.headline).bold().lineLimit(1).minimumScaleFactor(0.8)
                            Spacer()
                        }
                        Text(seen).font(.caption).lineLimit(1).minimumScaleFactor(0.6)
                    }
                } else {
                    if showFullName {
                        Text(user.fullname)
                            .lineLimit(1).minimumScaleFactor(0.9)
                            .font(.headline).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("@\(user.username)")
                            .font(.subheadline).bold()
                            .lineLimit(1).minimumScaleFactor(0.9)
                    }
                }
            }
        }
    }
}

struct UserRowViewSec: View {
    @Environment(\.colorScheme) var colorScheme
    let generator = UINotificationFeedbackGenerator()
    let user: User
    let showFullName: Bool
    let showMessaging: Bool
    @State var showProfile: Bool = false
    var body: some View {
        VStack {
            Button {
                generator.notificationOccurred(.success)
                showProfile.toggle()
            } label: {
                HStack(spacing: 10){
                    if let image = user.profileImageUrl {
                        ZStack {
                            personView(size: showFullName ? 50 : 46)
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: showFullName ? 50 : 46, height: showFullName ? 50 : 46)
                                .clipShape(Circle())
                        }
                    } else {
                        personView(size: showFullName ? 50 : 46)
                    }
                    if showFullName {
                        Text(user.fullname)
                            .font(.headline).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("@\(user.username)").font(.subheadline).bold()
                    }
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileSheetView(uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, username: .constant(nil))
            }.presentationDetents([.large])
        }
    }
}

struct UserRowViewThird: View {
    @Environment(\.colorScheme) var colorScheme
    let user: User
    @State var showProfile: Bool = false
    var body: some View {
        VStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showProfile.toggle()
            } label: {
                HStack(spacing: 10){
                    if let image = user.profileImageUrl {
                        ZStack {
                            personView(size: 46)
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 46, height: 46)
                                .clipShape(Circle())
                        }
                    } else {
                        personView(size: 46)
                    }
                    Text("@\(user.username)").font(.subheadline).bold().foregroundStyle(colorScheme == .dark ? .white : .black)
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileSheetView(uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user, username: .constant(nil))
            }.presentationDetents([.large])
        }
    }
}

struct gcUserRow: View {
    @Environment(\.colorScheme) var colorScheme
    let user: User
    
    var body: some View {
        HStack(spacing: 10){
            if let image = user.profileImageUrl {
                ZStack {
                    personView(size: 50)
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
            } else {
                personView(size: 50)
            }
            VStack(alignment: .leading, spacing: 4){
                HStack {
                    Text(user.fullname).font(.headline).bold()
                    Spacer()
                }
                HStack {
                    Text("@\(user.username)").font(.caption)
                    Spacer()
                }
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            Spacer()
            Text("\(user.elo)").font(.caption)
        }
    }
}
