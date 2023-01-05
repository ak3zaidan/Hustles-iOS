import SwiftUI
import Kingfisher

struct FeedSideMenu: View {
    @Binding var showMenu: Bool
    @State var showSettings: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: FeedViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Binding var showCreateCommunity: Bool
    @Binding var showSearchCommunity: Bool
    @Binding var showSaved: Bool
    @Binding var showMemory: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18){
            HStack {
                ZStack(alignment: .bottomTrailing) {
                    ZStack(alignment: .center){
                        Image(systemName: "circle.fill")
                            .resizable()
                            .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray))
                            .frame(width: 40, height: 40)
                        Image(systemName: "person")
                            .foregroundColor(.white).font(.headline)
                    }
                    if let image = auth.currentUser?.profileImageUrl {
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width:40, height: 40)
                            .clipShape(Circle())
                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                    }
                    if auth.currentUser?.verified != nil {
                        Image("veriBlue")
                            .resizable()
                            .frame(width: 25, height: 20).offset(x: 3, y: 5)
                    }
                }
                .onTapGesture {
                    showProf()
                }
                Spacer()
            }
            VStack(alignment: .leading, spacing: 10){
                Button(action: {
                    showProf()
                }, label: {
                    VStack(alignment: .leading, spacing: 4){
                        Text(auth.currentUser?.fullname ?? "Hustles").font(.headline).bold().foregroundStyle(colorScheme == .dark ? .white : .black)
                        Text("@\(auth.currentUser?.username ?? "...")").foregroundStyle(.gray)
                    }
                })
                HStack(spacing: 2){
                    Text("\((auth.currentUser?.following ?? []).count)").bold().font(.system(size: 15))
                    Text("Following").bold().font(.system(size: 15))
                        .foregroundStyle(.gray).padding(.trailing, 5)
                    Text("\(auth.currentUser?.followers ?? 0)").bold().font(.system(size: 15))
                    Text("Followers").bold().font(.system(size: 15))
                        .foregroundStyle(.gray)
                    Spacer()
                }
            }.padding(.bottom, 10)
            Button(action: {
                showProf()
            }, label: {
                HStack(spacing: 26){
                    Image(systemName: "person").font(.title3).frame(width: 20)
                    Text("Profile").font(.title2)
                    Spacer()
                }.fontWeight(.semibold).padding(.bottom, 5).foregroundStyle(colorScheme == .dark ? .white : .black)
            })
            Button(action: {
                showSettings = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }, label: {
                HStack(spacing: 26){
                    Image(systemName: "gearshape").font(.title3).frame(width: 20)
                    Text("Settings").font(.title2)
                    Spacer()
                }.fontWeight(.semibold).padding(.bottom, 5).foregroundStyle(colorScheme == .dark ? .white : .black)
            })
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)){
                    showMenu = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                    showSaved = true
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }, label: {
                HStack(spacing: 26){
                    Image(systemName: "bookmark").font(.title3).frame(width: 20)
                    Text("Saved").font(.title2)
                    Spacer()
                }.fontWeight(.semibold).padding(.bottom, 5).foregroundStyle(colorScheme == .dark ? .white : .black)
            })
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)){
                    showMenu = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                    showMemory = true
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }, label: {
                HStack(spacing: 26){
                    Image("memory")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .scaledToFit()
                        .scaleEffect(1.9)
                        .brightness(colorScheme == .dark ? 0.0 : -0.1)
                    Text("Memories").font(.title2).gradientForeground(colors: [.blue, .purple])
                    Spacer()
                }.fontWeight(.semibold).padding(.bottom, 5).foregroundStyle(colorScheme == .dark ? .white : .black)
            })
            HStack(spacing: 15){
                Image(systemName: "person.2").font(.title3)
                Text("Communities").font(.title2)
                Spacer()
                Image(systemName: "chevron.down").font(.headline)
                    .fontWeight(.light)
            }.fontWeight(.semibold)
            ScrollView {
                VStack(spacing: 20){
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)){
                            showMenu = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                            showCreateCommunity = true
                        }
                    } label: {
                        HStack(spacing: 10){
                            Image(systemName: "plus").font(.title3).fontWeight(.light)
                                .frame(width: 20)
                            Text("Create").font(.headline)
                            Spacer()
                        }.foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)){
                            showMenu = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                            showSearchCommunity = true
                        }
                    } label: {
                        HStack(spacing: 10){
                            Image(systemName: "magnifyingglass").font(.title3).fontWeight(.light)
                                .frame(width: 20)
                            Text("Search").font(.headline)
                            Spacer()
                        }.foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                    Button(action: {
                        
                    }, label: {
                        commRow(image: "https://cdn.pixabay.com/photo/2016/05/05/02/37/sunset-1373171_1280.jpg", name: "ChatGPT")
                    })
                    Button(action: {
                        
                    }, label: {
                        commRow(image: "https://letsenhance.io/static/8f5e523ee6b2479e26ecc91b9c25261e/1015f/MainAfter.jpg", name: "Red Bull Racing")
                    })
                    Button(action: {
                        
                    }, label: {
                        commRow(image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLzOsXAGnBHRlP3m5OClYHGLxQHkqyJQGVI3Vxk3d6aA&s", name: "Call of Duty Moden")
                    })
                }.padding(.leading, 20)
            }
            .scrollIndicators(.hidden)
            Spacer()
        }
        .padding(.leading, 25).padding(.trailing, 5)
        .frame(width: widthOrHeight(width: true) - 110.0)
        .padding(.top, top_Inset())
        .ignoresSafeArea()
        .navigationDestination(isPresented: $showSettings) {
            AccountView().enableFullSwipePop(true)
        }
    }
    func commRow(image: String, name: String) -> some View {
        HStack(spacing: 10){
            KFImage(URL(string: image))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 20, height: 20)
                .clipShape(Circle())
                .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
            Text(name).font(.headline).foregroundStyle(colorScheme == .dark ? .white : .black)
            Spacer()
        }
    }
    func showProf(){
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)){
            showMenu = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            viewModel.showProfile = true
        }
    }
}
