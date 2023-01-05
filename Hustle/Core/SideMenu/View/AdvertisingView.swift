import SwiftUI
import UIKit
import Firebase

struct AdvertisingView: View {
    @State private var showLoader: Bool = false
    @State private var goodVideo: Bool = true
    @State private var video: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var adImage: Image?
    @State private var uploaded: Bool = false
    @State private var error_upload: Bool = false
    @State private var reload_active: Bool = true
    @State private var showMy: Bool = false
    @State private var adText: String = ""
    @State private var start = Date().addingTimeInterval(48 * 60 * 60)
    @State private var end = Date().addingTimeInterval(72 * 60 * 60)
    @State private var adWebLink: String = ""
    @State private var appName: String = ""
    @State private var goodCaption: Bool = false
    @State private var goodCaptionS: String = ""
    @State private var viewIsTop = false
    @State private var showPreview = false
    
    @Environment(\.presentationMode) var presentationMode
    @Namespace var animation
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedFilter: AdViewModel = .plus
    @EnvironmentObject var viewModel: UploadAdViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @StateObject var storeKit = StoreKitManager()
    @State var purchaseFailed: Bool = false
    @State var currentAudio: String = ""
    @State var tempSet: Bool = false
    @Namespace private var newsAnimation
    
    var body: some View {
        VStack(alignment: .leading){
            HStack(alignment: .center){
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                        .scaleEffect(1.5)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .frame(width: 15, height: 15)
                }.padding(.horizontal, 20)
                Spacer()
                Text("Ads Manager")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.title).bold()
                Spacer()
                Button {
                    showMy.toggle()
                } label: {
                    HStack(spacing: 1){
                        Text("myAds")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.callout)
                        Image(systemName: "arrow.up.forward")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
            }.ignoresSafeArea().padding(.horizontal)
            
            AdFilter.padding(.top)
            
            ScrollView {
                LazyVStack {
                    if selectedFilter == .plus {
                        reachPlusSub
                    } else {
                        reachSub
                    }
                    reach
                }
                .background(GeometryReader {
                    Color.clear.preference(key: ViewOffsetKey.self,
                                           value: -$0.frame(in: .named("scroll")).origin.y)
                })
            }
            .scrollIndicators(.hidden)
            .gesture(
                DragGesture()
                    .onChanged { _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
            .sheet(isPresented: $showPreview, content: {
                ScrollView {
                    VStack {
                        if !video.isEmpty && goodVideo {
                            let videoLink = inputChecker().getLink(videoLink: video)
                            AdTestRow(plus: selectedFilter == .plus ? true : false, caption: adText, image: nil, video: videoLink, link: !adWebLink.isEmpty ? adWebLink : nil, appName: !appName.isEmpty ? appName : nil)
                        } else if let image = adImage {
                            AdTestRow(plus: selectedFilter == .plus ? true : false, caption: adText, image: image, video: nil, link: !adWebLink.isEmpty ? adWebLink : nil, appName: !appName.isEmpty ? appName : nil)
                        } else {
                            AdTestRow(plus: selectedFilter == .plus ? true : false, caption: adText, image: nil, video: nil, link: !adWebLink.isEmpty ? adWebLink : nil, appName: !appName.isEmpty ? appName : nil)
                        }
                    }.padding(.horizontal).padding(.vertical, 40)
                }
                .scrollIndicators(.hidden)
                .presentationDetents([.fraction(0.75)])
                .background(colorScheme == .dark ? .black : .white).edgesIgnoringSafeArea(.all)
                .presentationDragIndicator(.visible)
            })
            .sheet(isPresented: $showImagePicker, onDismiss: loadImage){
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $uploaded) {
                success
            }
            .sheet(isPresented: $showMy) {
                myAds
            }
            .onReceive(viewModel.$didUploadAd) { success in
                showLoader = false
                if success {
                    selectedImage = nil
                    adImage = nil
                    adText = ""
                    start = Date().addingTimeInterval(48 * 60 * 60)
                    end = Date().addingTimeInterval(72 * 60 * 60)
                    adWebLink = ""
                    appName = ""
                    adWebLink = ""
                    video = ""
                    viewModel.didUploadAd = false
                    uploaded.toggle()
                    goodCaption = false
                    goodCaptionS = ""
                }
            }
            .onChange(of: viewModel.uploadError, { _, _ in
                if viewModel.uploadError == "error" {
                    showLoader = false
                    error_upload = true
                    viewModel.uploadError = ""
                }
            })
            .onAppear {
                if viewModel.myAds.isEmpty {
                    viewModel.getAds()
                }
            }
        }
        .tint(.blue)
        .padding(.top, 8)
        .navigationBarBackButtonHidden(true)
        .alert("Error uploading, try again later or contact customer service", isPresented: $error_upload) {
            Button("close", role: .cancel) { }
        }
        .alert("Purchase failed", isPresented: $purchaseFailed) { Button("Close", role: .cancel) {} }
        .onChange(of: popRoot.tap, { _, _ in
            if popRoot.tap == 6 && viewIsTop {
                presentationMode.wrappedValue.dismiss()
                popRoot.tap = 0
            }
        })
        .onAppear { viewIsTop = true }
        .onDisappear { viewIsTop = false }
    }
    func calculateBalance() -> Int {
        let calendar = Calendar.current
        let diffInDays = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end))
        let balance = ((selectedFilter == .normal) ? (diffInDays.day ?? 1) * 300 : (diffInDays.day ?? 1) * 500)
        return balance > 1000 ? 1000 : balance
    }
    func loadImage() {
        guard let selectedImage = selectedImage else {return}
        adImage = Image(uiImage: selectedImage)
    }
}

extension AdvertisingView{
    var AdFilter: some View{
        HStack{
            ForEach(AdViewModel.allCases, id: \.rawValue){ item in
                VStack{
                    if item == .plus{
                        HStack(alignment: .center, spacing: 3){
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(selectedFilter == item ? .semibold: .regular)
                                .foregroundColor(selectedFilter == item ? (colorScheme == .dark ? .white : .black) : .gray)
                            ZStack{
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.orange.opacity(0.7))
                                    .frame(width: 38, height: 18)
                                Text("New")
                                    .font(.subheadline).bold()
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                        }
                    } else {
                        Text(item.title)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == item ? .semibold: .regular)
                            .foregroundColor(selectedFilter == item ? (colorScheme == .dark ? .white : .black) : .gray)
                    }
                    if selectedFilter == item{
                        Capsule()
                            .foregroundColor(Color(.systemBlue))
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "filter", in: animation)
                    } else {
                        Capsule()
                            .foregroundColor(Color(.clear))
                            .frame(height: 3)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut){
                        self.selectedFilter = item
                    }
                }
            }
        }
        .overlay(Divider().offset(x:0, y:16))
    }
    var reach: some View {
        VStack{
            HStack{
                Spacer()
                ZStack(alignment: .top){
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
                    VStack{
                        HStack{
                            Text("Create")
                                .font(.title2).bold()
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                        }
                        .padding(.top)
                        .padding(.leading)
                        VStack(spacing: 0){
                            VStack(alignment: .leading, spacing: 1){
                                Text(goodCaptionS)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 6)
                                TextArea("Ad Description (Required)", text: $adText)
                                    .frame(height: 170)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 1)
                                            .stroke(.blue, lineWidth: 1)
                                    }
                                    .onChange(of: adText) { _, newValue in
                                        goodCaptionS = inputChecker().myInputChecker(withString: newValue, withLowerSize: 1, withUpperSize: 250, needsLower: true)
                                        if goodCaptionS == "" {
                                            goodCaption = true
                                        }
                                    }
                            }
                            DatePicker("start date", selection: $start, in: Date().addingTimeInterval(48 * 60 * 60)..., displayedComponents: .date)
                                .padding(.leading, 26)
                                .padding(.trailing)
                                .frame(height: 40)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 1)
                                        .stroke(.blue, lineWidth: 1)
                                }
                                .onChange(of: start) { _, _ in
                                    end = start.addingTimeInterval(24 * 60 * 60)
                                }
                            if selectedFilter == .plus {
                                DatePicker("end date", selection: $end, in: start.addingTimeInterval(24 * 60 * 60)...start.addingTimeInterval(48 * 60 * 60), displayedComponents: .date)
                                    .padding(.leading, 26)
                                    .padding(.trailing)
                                    .frame(height: 40)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 1)
                                            .stroke(.blue, lineWidth: 1)
                                    }
                            } else {
                                DatePicker("end date", selection: $end, in: start.addingTimeInterval(24 * 60 * 60)...start.addingTimeInterval(72 * 60 * 60), displayedComponents: .date)
                                    .padding(.leading, 26)
                                    .padding(.trailing)
                                    .frame(height: 40)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 1)
                                            .stroke(.blue, lineWidth: 1)
                                    }
                            }
                            TextField("Website Link", text: $adWebLink)
                                .padding(.leading, 26)
                                .frame(height: 40)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 1)
                                        .stroke(.blue, lineWidth: 1)
                                }
                            TextField("AppStore Link? include app name", text: $appName)
                                .padding(.leading, 26)
                                .frame(height: 40)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 1)
                                        .stroke(.blue, lineWidth: 1)
                                }
                            TextField("Video link (youtube or web video)", text: $video)
                                .padding(.leading, 26)
                                .frame(height: 40)
                                .disabled(adImage != nil ? true : false)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 1)
                                        .stroke(goodVideo ? .blue : .red, lineWidth: 1)
                                }
                                .onChange(of: video) { _, _ in
                                    if video.isEmpty {
                                        goodVideo = true
                                    } else {
                                        if let url = URL(string: video), UIApplication.shared.canOpenURL(url) {
                                            goodVideo = true
                                        } else {
                                            goodVideo = false
                                        }
                                    }
                                }
                        }
                        if let adImage = adImage {
                            HStack(spacing: 20){
                                Button {
                                    showImagePicker.toggle()
                                } label: {
                                    adImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 125, height: 125)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
                                            .onEnded { value in
                                                selectedImage = nil
                                                self.adImage = nil
                                            })
                                    VStack(spacing: 10){
                                        HStack{
                                            Image(systemName: "pencil")
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text("Tap pic to replace")
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .font(.subheadline)
                                            Spacer()
                                        }
                                        HStack{
                                            Image(systemName: "pencil")
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text("swipe to delete")
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .font(.subheadline)
                                            Spacer()
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.top, 5)
                                .padding(.leading, 10)
                            }
                        } else {
                            VStack(spacing: 15){
                                HStack{
                                    Button {
                                        showImagePicker.toggle()
                                    } label: {
                                        Text("Add photo")
                                            .font(.title3)
                                            .frame(width: 100, height: 32)
                                            .foregroundColor(.blue)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 5)
                                                    .stroke(.blue, lineWidth: 1)
                                            }
                                    }.disabled(video.isEmpty ? false : true)
                                    Spacer()
                                }
                            }
                            .padding(.leading, 30)
                            .padding(.top, 30)
                        }
                    }
                }
                .frame(height: 580)
                .padding()
                Spacer()
            }
            VStack {
                HStack {
                    Spacer()
                    Button {
                        if goodCaption {
                            showPreview.toggle()
                        }
                    } label: {
                        Text("Preview")
                            .foregroundColor(.white)
                            .font(.system(size: 19)).bold().padding(.horizontal, 15).frame(height: 35)
                            .background {
                                Capsule().fill(goodCaption ? Color.blue.gradient : Color.gray.gradient)
                            }
                    }
                    Spacer()
                }
            }.padding(.vertical).padding(.bottom, 20)
            HStack {
                Spacer()
                ZStack(alignment: .top){
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
                    VStack(spacing: 15){
                        VStack(spacing: 4){
                            HStack{
                                Text("Payment:")
                                    .font(.title2).bold()
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Spacer()
                            }
                            Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray)
                        }.padding(.top)
                        HStack{
                            VStack(spacing: 3){
                                HStack(spacing: 1){
                                    Text("Current Balance: $")
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .font(.title3)
                                    Text("\(calculateBalance())")
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .font(.title3).bold()
                                    Spacer()
                                }
                                HStack {
                                    if selectedFilter == .normal{
                                        Text("*This plan is billed 300 USD per day, rejected Ads WILL be refunded.")
                                            .font(.caption).foregroundColor(.gray)
                                    } else {
                                        Text("*This plan is billed 500 USD per day, rejected Ads WILL be refunded.")
                                            .font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    Link("By posting this AD you agree to our Terms and conditions of purchase.", destination: URL(string:"https://hustle.page/terms-of-use/")!)
                                        .font(.caption).bold().foregroundColor(.blue).multilineTextAlignment(.center)
                                    Spacer()
                                }.padding(.top, 10)
                            }
                        }.padding(.bottom, 5)
                    }.padding(.horizontal)
                }.padding(.horizontal).frame(height: 185)
                Spacer()
            }
            .padding(.bottom, 20)
            if showLoader {
                Loader(flip: true).id("\(UUID())").padding(.bottom, 10)
            } else {
                Button {
                    if let user = auth.currentUser, goodCaption && goodVideo {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        let calendar = Calendar.current
                        let diffInDays = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end))
                        if let intDays = diffInDays.day {
                            Task {
                                if selectedFilter == .plus {
                                    if let product = storeKit.storeProducts.first(where: { ($0.id == "OneDayBoostPlus" && intDays == 1) || ($0.id == "TwoDayBoostPlus" && intDays == 2) }){
                                        do {
                                            let result = try await storeKit.purchase(product)
                                            if result {
                                                viewModel.uploadAd(caption: adText, start: start, end: end, webLink: adWebLink, appName: appName, image: selectedImage, plus: true, photo: user.profileImageUrl ?? "", username: user.username, video: video)
                                                showLoader = true
                                            } else { purchaseFailed = true }
                                        } catch { purchaseFailed = true }
                                    } else { error_upload = true }
                                } else {
                                    if let product = storeKit.storeProducts.first(where: { ($0.id == "OneDayBoost" && intDays == 1) || ($0.id == "TwoDayBoost" && intDays == 2) || ($0.id == "ThreeDayBoost" && intDays == 3) }){
                                        do {
                                            let result = try await storeKit.purchase(product)
                                            if result {
                                                viewModel.uploadAd(caption: adText, start: start, end: end, webLink: adWebLink, appName: appName, image: selectedImage, plus: false, photo: user.profileImageUrl ?? "", username: user.username, video: video)
                                                showLoader = true
                                            } else { purchaseFailed = true }
                                        } catch { purchaseFailed = true }
                                    } else { error_upload = true }
                                }
                            }
                        } else { error_upload = true }
                    } else { error_upload = true }
                } label: {
                    Text("Pay + Submit for Review")
                        .bold()
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background((goodCaption && goodVideo) ? .blue : .gray)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .clipShape(Capsule())
                        .shadow(color: .gray.opacity(0.6), radius: 10, x: 0, y: 0)
                }.padding(.bottom, 10)
            }
            Color.clear.frame(height: 60)
        }
    }
    var reachSub: some View{
        VStack{
            HStack{
                Spacer()
                ZStack(alignment: .top){
                    RoundedRectangle(cornerRadius: 15).stroke(.gray, lineWidth: 1)
                    VStack{
                        Image("tree").resizable().frame(width: 100, height: 100)
                        Text("Reach").bold().foregroundColor(colorScheme == .dark ? .white : .black)
                        VStack(spacing: 2){
                            Text("Wide Audience").font(.subheadline).foregroundColor(.gray)
                            Text("Cheaper Rates.").font(.subheadline).foregroundColor(.gray)
                            Text("More likes, and clicks,").font(.subheadline).foregroundColor(.gray)
                        }.padding(.top, 4)
                    }
                }
                .frame(width: 200, height: 225)
                .padding(.horizontal)
                .padding(.top)
                Spacer()
            }
        }
    }
    var reachPlusSub: some View{
        VStack(spacing: 0){
            HStack{
                Spacer()
                ZStack(alignment: .top){
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.blue, lineWidth: 1)
                    VStack{
                        Image("earth").resizable().frame(width: 115, height: 115)
                        Text("Reach Plus").bold()
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        VStack(spacing: 2){
                            Text("Visible to Everyone").font(.subheadline).foregroundColor(.gray)
                            Text("Max Traffic. More views,").font(.subheadline).foregroundColor(.gray)
                            Text("likes, and clicks,").font(.subheadline).foregroundColor(.gray)
                        }.padding(.top, 4)
                    }
                }
                .frame(width: 200, height: 225)
                .padding(.horizontal)
                .padding(.top)
                Spacer()
            }
        }
    }
    var success: some View{
        VStack(alignment: .center){
            LottieView(loopMode: .loop, name: "success")
                .frame(width: 85, height: 85)
            Text("Your ad has been uploaded for review. If it does not meet our ad standards located in our Terms, we will reach out to you via email. You will have the option to revise your ad or accept a full refund. Please allow 1-2 business days for the review.")
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(10)
        .presentationDetents([.fraction(0.4)])
    }
    var myAds: some View{
        VStack {
            HStack{
                Spacer()
                Button {
                    if reload_active {
                        reload_active = false
                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                            reload_active = true
                        }
                        viewModel.getAds()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 22))
                }
            }.padding()
            if !viewModel.myAds.isEmpty {
                ScrollView {
                    LazyVStack{
                        ForEach(viewModel.myAds){ ad in
                            TweetRowView(tweet: ad, edit: true, canShow: false, canSeeComments: true, map: false,  currentAudio: $currentAudio, isExpanded: $tempSet, animationT: animation, seenAllStories: false, isMain: false, showSheet: $tempSet, newsAnimation: newsAnimation)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }.padding(.vertical, 10)
            }
            if viewModel.myAds.isEmpty{
                HStack(spacing: 5){
                    Image(systemName: "folder")
                        .scaleEffect(1.5)
                        .foregroundColor(.gray)
                    Text("You do not have any current Ads")
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding(.vertical, 30)
            }
            Spacer()
        }
        .dynamicTypeSize(.large)
        .background(viewModel.myAds.isEmpty ? .clear : colorScheme == .dark ? .black : .white).edgesIgnoringSafeArea(.all)
        .presentationDragIndicator(.visible)
        .presentationDetents([viewModel.myAds.isEmpty ? .fraction(0.3) : .fraction(0.8)])
    }
}

