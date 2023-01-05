import SwiftUI
import Firebase
import Kingfisher

struct SingleShopView: View {
    @StateObject var ShopModel = ShopViewModel()
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var job: JobViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    var shopItem: Shop
    let disableUser: Bool
    let shouldCloseKeyboard: Bool
    @State var posted: String = ""
    @State var state: String = ""
    @State var city: String = ""
    @State var country: String = ""
    @State var mapID: String = "\(UUID())"
    @State var showAlert: Bool = false
    @State var showEditPrice: Bool = false
    @State var newp = ""
    @State var goodPrice = ""
    @State var newPrice = 0
    @State var showReport: Bool = false
    @State var showMessaging: Bool = false
    @State var showComplete: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0){
                HStack {
                    Spacer()
                    Button {
                        if shouldCloseKeyboard {
                            withAnimation(.spring()){
                                self.popRoot.hideTabBar = false
                            }
                        }
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 27))
                    }
                }.padding(.trailing).padding(.vertical, 10)
                ScrollView {
                    TabView {
                        ForEach(shopItem.photos, id: \.self){ url in
                            HStack {
                                Spacer()
                                KFImage(URL(string: url))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: widthOrHeight(width: true), height: widthOrHeight(width: false) * 0.4)
                                    .clipped()
                                    .onTapGesture {
                                        popRoot.image = url
                                        popRoot.showImage = true
                                    }
                                Spacer()
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: widthOrHeight(width: false) * 0.4)
                    VStack(alignment: .leading){
                        VStack {
                            HStack{
                                Text(shopItem.title).font(.system(size: 28)).bold()
                                Spacer()
                                if !job.saleDelete.contains(shopItem.id ?? "NA") {
                                    if let id = auth.currentUser?.dev, id.contains("(DWK@)2))&DNWIDN:") {
                                        Button {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            showAlert.toggle()
                                        } label: {
                                            Image(systemName: "ellipsis").font(.system(size: 25))
                                        }
                                    } else {
                                        Button {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            if auth.currentUser?.id ?? "err" == shopItem.uid {
                                                showAlert.toggle()
                                            } else {
                                                showReport.toggle()
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis").font(.system(size: 25))
                                        }
                                    }
                                }
                            }.padding(.top, 5)
                            HStack {
                                Text("$\(newPrice > 0 ? newPrice : shopItem.price)").font(.system(size: 26))
                                Spacer()
                            }
                            .padding(.top, 2)
                            .onAppear {
                                newPrice = shopItem.price
                            }
                            HStack {
                                HStack(spacing: 10) {
                                    ForEach(shopItem.tags ?? [], id: \.self){ text in
                                        Text(text)
                                            .minimumScaleFactor(0.7).lineLimit(1)
                                            .font(.callout).fontWeight(.semibold)
                                            .frame(height: 30)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 20)
                                            .background {
                                                Capsule().fill(.blue.gradient)
                                            }
                                        
                                    }
                                }
                                if let promoted = shopItem.promoted?.dateValue(), Timestamp().dateValue() <= promoted {
                                    Text("Promoted")
                                        .minimumScaleFactor(0.7).lineLimit(1)
                                        .font(.callout).fontWeight(.semibold)
                                        .frame(height: 30)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 20)
                                        .background {
                                            Capsule().fill(.orange.gradient)
                                        }
                                }
                                Spacer()
                            }.padding(.top, 5)
                            HStack {
                                Text(posted).font(.system(size: 17)).padding(.top).foregroundColor(.gray).bold().lineLimit(1).minimumScaleFactor(0.8)
                                    .onAppear { getPosted() }
                                Spacer()
                            }
                            HStack {
                                Text("Description:").font(.system(size: 20)).bold().padding(.top, 8)
                                Spacer()
                            }
                            HStack{
                                Text(shopItem.caption).font(.system(size: 18)).padding(.top, 1)
                                Spacer()
                            }
                            
                            Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray).padding(.top)
                            HStack {
                                NavigationLink {
                                    ProfileView(showSettings: false, showMessaging: false, uid: shopItem.uid, photo: shopItem.profilephoto ?? "", user: nil, expand: true, isMain: false).dynamicTypeSize(.large)
                                } label: {
                                    if let image = shopItem.profilephoto {
                                        KFImage(URL(string: image))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width:56, height: 56)
                                            .clipShape(Circle())
                                            .padding(.top, 5)
                                    } else {
                                        ZStack(alignment: .center){
                                            Image(systemName: "circle.fill")
                                                .resizable()
                                                .foregroundColor(colorScheme == .dark ? Color(UIColor.darkGray) : .black)
                                                .frame(width: 56, height: 56)
                                            Image(systemName: "questionmark")
                                                .resizable()
                                                .foregroundColor(.white)
                                                .frame(width: 17, height: 22)
                                        }.padding(.top, 5)
                                    }
                                    Text("@\(shopItem.username)").font(.system(size: 20)).bold().foregroundColor(.blue)
                                }
                                Spacer()
                                Button {
                                    showMessaging.toggle()
                                } label: {
                                    Image(systemName: "paperplane.fill")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                        .padding(6)
                                        .padding(.vertical, 2)
                                        .overlay(Circle().stroke(Color.gray,lineWidth: 0.75))
                                }
                            }.disabled(disableUser || auth.currentUser?.id ?? "NA" == shopItem.uid)
                            Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray).padding(.top, 5)
                            
                            HStack(alignment: .center){
                                Text("Seller Location:").font(.system(size: 20)).bold()
                                Text("(approximate)").font(.system(size: 15)).foregroundColor(.gray)
                                Spacer()
                            }.padding(.top)
                        }
                        MapView(city: city, state: state, country: country, is100: true)
                            .frame(height: 400).cornerRadius(15).id(mapID)
                            .onChange(of: country) { _ in
                                mapID = "\(UUID())"
                            }
                        Color.clear.frame(height: 30)
                    }.padding(.horizontal)
                }.scrollIndicators(.hidden)
            }
            .blur(radius: showEditPrice ? 5 : 0)
            .disabled(showEditPrice)
            if showEditPrice {
                priceUpdater()
            }
        }
        .sheet(isPresented: $showComplete) {
            CompleteSaleView(saleItem: shopItem)
        }
        .fullScreenCover(isPresented: $showMessaging, content: {
            MessagesView(exception: false, user: nil, uid: shopItem.uid, tabException: false, canCall: true)
        })
        .navigationBarBackButtonHidden(true)
        .alert("Post Options", isPresented: $showAlert) {
            Button("Delete Post", role: .destructive) {
                ShopModel.deletePost(id: shopItem.id ?? "", location: shopItem.location, images: shopItem.photos)
            }
            Button("Mark Sold", role: .destructive) {
                showComplete = true
            }
            Button("Edit Price", role: .destructive) {
                showAlert.toggle()
                withAnimation {
                    showEditPrice.toggle()
                }
            }
            Button("Close", role: .cancel) {}
        }
        .alert("Report this content?", isPresented: $showReport) {
            Button("Report", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if let id = shopItem.id {
                    UserService().reportContent(type: "Shop", postID: "id: \(id), Loc: \(shopItem.location)")
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    func getPosted(){
        var locString = ""
        if shopItem.location.contains(",") {
            let components = shopItem.location.components(separatedBy: ",")
            if components.count >= 3 {
                let country = components[0]
                let state = components[1]
                let city = components[2]
                self.country = country
                self.city = city
                self.state = state
                if state.isEmpty {
                   locString = city + ", " + country
                } else {
                    locString = city + ", " + state
                }
            }
        }
        let dateString = shopItem.timestamp.dateValue().formatted(.dateTime.month().day().year().hour().minute())
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
        if let date = dateFormatter.date(from:dateString){
            if Calendar.current.isDateInToday(date){
                posted = "Posted today at " + shopItem.timestamp.dateValue().formatted(.dateTime.hour().minute()) + (!locString.isEmpty ? " in \(locString)" : "")
            } else if Calendar.current.isDateInYesterday(date) {
                posted = "Posted yesterday" + (!locString.isEmpty ? " in \(locString)" : "")
            } else {
                if let dayBetween  = Calendar.current.dateComponents([.day], from: shopItem.timestamp.dateValue(), to: Date()).day{
                    posted = "Posted " + "\(dayBetween + 1) days ago" + (!locString.isEmpty ? " in \(locString)" : "")
                }
            }
        }
    }
    func priceUpdater() -> some View {
        VStack{
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundColor(.indigo)
                VStack {
                    HStack {
                        Text("New Price").font(.system(size: 25)).foregroundColor(.white).bold()
                        Spacer()
                        Button {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation {
                                showEditPrice.toggle()
                            }
                        } label: {
                            Image(systemName: "xmark").font(.system(size: 25)).foregroundColor(.white)
                        }
                    }
                    Spacer()
                    ZStack {
                        HStack{
                            Spacer()
                            if newp.isEmpty {
                                Text("Add price").font(.system(size: 25)).foregroundColor(.white).padding(.leading, 5)
                            } else {
                                Text("$").font(.system(size: 30)).foregroundColor(.white).offset(x: -60)
                            }
                            Spacer()
                        }
                        TextField("", text: $newp)
                            .minimumScaleFactor(0.8)
                            .padding(.leading, 5)
                            .foregroundColor(goodPrice.isEmpty ? .white : .red).bold()
                            .frame(width: 110)
                            .lineLimit(1).tint(.white)
                            .font(.system(size: 30))
                            .keyboardType(.numberPad)
                            .onChange(of: newp) { _ in
                                if Int(newp) ?? 0 < 1 || Int(newp) ?? 0 > 5000000 {
                                    goodPrice = "Price must be 1 - 5M"
                                } else {
                                    goodPrice = ""
                                }
                            }
                    }
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if Int(newp) ?? 0 >= 1 && Int(newp) ?? 0 <= 5000000 && Int(newp) ?? 0 != shopItem.price {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            ShopModel.editPrice(withId: shopItem.id ?? "", location: shopItem.location, newPrice: Int(newp) ?? 49)
                            withAnimation {
                                showEditPrice.toggle()
                            }
                            newPrice = Int(newp) ?? 49
                            newp = ""
                            goodPrice = ""
                        }
                    } label: {
                        Text("Save").font(.system(size: 20)).bold().foregroundColor(.white).padding(3).padding(.horizontal, 30).background(.gray).cornerRadius(5)
                    }.disabled(!goodPrice.isEmpty)
                }.padding()
            }.frame(width: 250, height: 250)
            Spacer()
        }
    }
}
