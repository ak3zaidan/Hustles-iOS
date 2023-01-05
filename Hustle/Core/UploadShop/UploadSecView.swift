import SwiftUI
import UIKit
import Photos

struct UploadSecView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @State private var selectedFilter: PromoteViewModel = .USD
    @ObservedObject var viewModel: UploadShopViewModel
    @EnvironmentObject var auth: AuthViewModel
    @StateObject var storeKit = StoreKitManager()
    @State var purchaseFailed: Bool = false
    @State var showPicker: Bool = false
    @State private var tooManyInOneHour = ""
    @State private var startTimer = false
    @State private var kingPro: Int = 0
    @State private var promotedELO: Int = 0
    @State private var promotedUSD: Int = 0
    @Namespace var animation
    @Binding var selTab: Int
    @State private var uploaded = false
    @State var myTimer: Timer?
    let lastTab: Int
    let isProfile: Bool
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation(.easeIn(duration: 0.2)){ selTab = 1 }
                } label: {
                    Image(systemName: "chevron.backward")
                        .scaleEffect(1.5)
                        .frame(width: 15, height: 15)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                Spacer()
            }.padding(.leading, 35).padding(.top)
            
            ScrollView {
                if viewModel.pickedImages.isEmpty {
                    Button {
                        viewModel.updateImages()
                        showPicker.toggle()
                    } label: {
                        HStack(spacing: 2){
                            Image(systemName: "photo").foregroundColor(colorScheme == .dark ? .white : .black)
                            Text("Upload image").foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        .padding(.horizontal, 83)
                        .padding(.vertical, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }.padding(.top, 40)
                } else {
                    TabView {
                        ForEach(viewModel.pickedImages, id: \.self){ image in
                            HStack {
                                Spacer()
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 250)
                                    .cornerRadius(15)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top)
                    .frame(height: 250)
                    .tabViewStyle(.page(indexDisplayMode: viewModel.pickedImages.isEmpty ? .never : .always))
                    .onTapGesture {
                        viewModel.updateImages()
                        showPicker.toggle()
                    }
                }
                Spacer()
                VStack(spacing: 15){
                    if let user = auth.currentUser {
                        if user.elo < 1300 {
                            promoteShopFilter
                            if selectedFilter == .USD {
                                PromoteUSD(selection: $promotedUSD)
                            }
                            if selectedFilter == .ELO {
                                PromoteELO(days: $promotedELO, userElo: auth.currentUser?.elo ?? 0)
                            }
                        } else {
                            ZStack{
                                RoundedRectangle(cornerRadius: 10).frame(width: 120, height: 45).foregroundColor(Color(UIColor.lightGray))
                                Text("Auto Promoted").font(.system(size: 15)).foregroundColor(.black).bold()
                            }.shimmering()
                        }
                    } else {
                        promoteShopFilter
                        if selectedFilter == .USD {
                            PromoteUSD(selection: $promotedUSD)
                        }
                        if selectedFilter == .ELO {
                            PromoteELO(days: $promotedELO, userElo: auth.currentUser?.elo ?? 0)
                        }
                    }
                }.padding(.top, viewModel.pickedImages.isEmpty ? 200 : 100)
            }.scrollIndicators(.hidden)
            Text("*Promoted items appear at the top").font(.subheadline).padding(.top, 10)
            Spacer()
            Text(viewModel.uploadError).font(.subheadline).foregroundColor(.red)
            if tooManyInOneHour.isEmpty {
                Button {
                    if !uploaded && !viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Int(viewModel.price) ?? 0 >= 1 && Int(viewModel.price) ?? 0 <= 5000000 && !viewModel.zipCode.isEmpty && !viewModel.tags.isEmpty && !viewModel.pickedImages.isEmpty {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        if let user = auth.currentUser {
                            var go = 0
                            let user2 = profile.users.first(where: { $0.user.username == user.username })
                            if let posts = user2?.forSale?.prefix(7) {
                                let arr = Array(posts)
                                arr.forEach { element in
                                    if calculateCosineSimilarity(viewModel.caption, element.caption) > 0.6 {
                                        viewModel.uploadError = "This item matches another, please make it unique."
                                        go = 1
                                    }
                                }
                            }
                            if go == 0 {
                                if promotedELO > 0 {
                                    viewModel.uploadShop(promoted: promotedELO, profilePhoto: auth.currentUser?.profileImageUrl, username: auth.currentUser?.username, shopPointer: auth.currentUser?.shopPointer, userCounry: auth.currentUser?.userCountry)
                                    uploaded = true
                                } else if promotedUSD > 0 {
                                    Task {
                                        if let product = storeKit.storeProducts.first(where: { $0.id == "3Day" }), promotedUSD == 3 {
                                            do {
                                                let result = try await storeKit.purchase(product)
                                                if result {
                                                    viewModel.uploadShop(promoted: 3, profilePhoto: auth.currentUser?.profileImageUrl, username: auth.currentUser?.username, shopPointer: auth.currentUser?.shopPointer, userCounry: auth.currentUser?.userCountry)
                                                    startTimer = true
                                                } else { purchaseFailed = true }
                                            } catch { purchaseFailed = true }
                                        } else if let product = storeKit.storeProducts.first(where: { $0.id == "1Day" }) {
                                            do {
                                                let result = try await storeKit.purchase(product)
                                                if result {
                                                    viewModel.uploadShop(promoted: 1, profilePhoto: auth.currentUser?.profileImageUrl, username: auth.currentUser?.username, shopPointer: auth.currentUser?.shopPointer, userCounry: auth.currentUser?.userCountry)
                                                    startTimer = true
                                                } else { purchaseFailed = true }
                                            } catch { purchaseFailed = true }
                                        }
                                    }
                                } else {
                                    viewModel.uploadShop(promoted: kingPro, profilePhoto: auth.currentUser?.profileImageUrl, username: auth.currentUser?.username, shopPointer: auth.currentUser?.shopPointer, userCounry: auth.currentUser?.userCountry)
                                    uploaded = true
                                }
                            }
                        } else { viewModel.uploadError = "An error occured: validate input, or try again later." }
                    }
                } label: {
                    if uploaded {
                        Loader(flip: true).padding(.bottom).id("\(UUID())")
                    } else {
                        Text(promotedUSD > 0 ? "Pay + Upload" : "Upload")
                            .bold()
                            .font(.title2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 5)
                            .frame(width: 300)
                            .background(!viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Int(viewModel.price) ?? 0 >= 1 && Int(viewModel.price) ?? 0 <= 5000000 && !viewModel.zipCode.isEmpty && !viewModel.tags.isEmpty && !viewModel.pickedImages.isEmpty ? .orange : .gray).opacity(0.7)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: colorScheme == .dark ? .gray : .black.opacity(0.6), radius: 10, x: 0, y: 0)
                            .padding(.bottom, 20)
                    }
                }.padding(.bottom, 40)
            } else {
                Text(tooManyInOneHour).font(.subheadline).foregroundColor(.red).padding(.bottom, 40)
            }
        }
        .popupImagePicker(viewModel: viewModel, show: $showPicker) { assets in
            let manager = PHCachingImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            DispatchQueue.global(qos: .userInteractive).async {
                assets.forEach { asset in
                    manager.requestImage(for: asset, targetSize: .init(), contentMode: .default, options: options) { image, _ in
                        guard let image = image else { return }
                        DispatchQueue.main.async {
                            self.viewModel.pickedImages.append(image)
                        }
                    }
                }
            }
        }
        .alert("Purchase failed", isPresented: $purchaseFailed) {
            Button("Close", role: .cancel) {}
        }
        .onDisappear { tooManyInOneHour = "" }
        .onReceive(viewModel.$didUploadShop) { success in
            if success {
                if promotedELO > 0 {
                    UserService().editElo(withUid: nil, withAmount: (promotedELO * -50)) {}
                }
                viewModel.caption = ""
                viewModel.zipCode = ""
                viewModel.title = ""
                viewModel.price = ""
                viewModel.tags = []
                viewModel.pickedImages = []
                viewModel.selectedImages = []
                viewModel.pickedImagesIDS = []
                viewModel.didUploadShop = false
                if !viewModel.locationToAdd.isEmpty {
                    auth.currentUser?.shopPointer.append(viewModel.locationToAdd)
                    viewModel.locationToAdd = ""
                }
                if isProfile {
                    presentationMode.wrappedValue.dismiss()
                    selTab = 1
                    uploaded = false
                } else {
                    withAnimation(.easeIn(duration: 0.2)){
                        selTab = 0
                        uploaded = false
                    }
                }
            }
        }
        .onChange(of: viewModel.uploadError) { _, _ in
            if viewModel.uploadError == "Could not find location" || viewModel.uploadError == "Could not Upload at this time"{
                uploaded = false
            }
        }
        .onAppear {
            if viewModel.fetchedImages.isEmpty {
                viewModel.fetchImages()
            }
            viewModel.uploadError = ""
            tooManyInOneHour = ""
            if let user = auth.currentUser {
                if user.elo >= 1300 { kingPro = 4 }
                if user.elo >= 850 { return }
                else {
                    let hustles = profile.users.first(where: { $0.user.username == user.username })
                    if let posts = hustles?.forSale {
                        var x = 0
                        let currentDate = Date()
                        posts.forEach { item in
                            let date = item.timestamp.dateValue()
                            let calendar = Calendar.current
                            if calendar.isDate(date, equalTo: currentDate, toGranularity: .hour) {
                                x += 1
                            }
                        }
                        if (x == 1 && user.elo < 600) || (x == 3 && user.elo < 850) {
                            tooManyInOneHour = "max uploads for this hour"
                        }
                    } else { return }
                }
            }
        }
        .onChange(of: popRoot.tap) { _, _ in
            if selTab == 2 && popRoot.tap == 2{
                withAnimation(.easeInOut){
                    selTab = 1
                }
                popRoot.tap = 0
            }
        }
        .onChange(of: promotedELO) { _, _ in
            if promotedELO > 0 {
                promotedUSD = 0
            }
        }
        .onChange(of: promotedUSD) { _, _ in
            if promotedUSD > 0 {
                promotedELO = 0
            }
        }
        .onChange(of: startTimer) { _, _ in
            if startTimer {
                uploaded = true
                myTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                    uploaded = false
                    viewModel.uploadError = "Action took too long"
                }
            }
        }
    }
}
extension UploadSecView {
    var promoteShopFilter: some View {
        HStack {
            ForEach(PromoteViewModel.allCases, id: \.rawValue){ item in
                if let user = auth.currentUser {
                    if item.title != "Promote ElO" || (item.title == "Promote ElO" && user.elo >= 850){
                        VStack{
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(selectedFilter == item ? .semibold: .regular)
                                .foregroundColor(selectedFilter == item ? colorScheme == .dark ? .white : .black : .gray)
                            
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
                } else {
                    VStack{
                        Text(item.title)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == item ? .semibold: .regular)
                            .foregroundColor(selectedFilter == item ? colorScheme == .dark ? .white : .black : .gray)
                        
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
        }.overlay(Divider().offset(x:0, y:16))
    }
}


struct PopupImagePickerView: View {
    @ObservedObject var imagePickerModel: UploadShopViewModel
    @Environment(\.self) var env
    var onEnd: ()->()
    var onSelect: ([PHAsset])->()
    var body: some View {
        VStack(spacing: 0){
            HStack {
                Text("Select Images").font(.system(size: 20)).bold()
                Text("max 5 photos").font(.caption).bold().foregroundColor(.red).padding(.leading, 5)
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onEnd()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }.padding([.horizontal,.top]).padding(.bottom,10)
            if !imagePickerModel.fetchedImages.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(),spacing: 10), count: 4),spacing: 12) {
                        ForEach($imagePickerModel.fetchedImages){ $imageAsset in
                            GridContent(imageAsset: imageAsset)
                                .onAppear {
                                    if imageAsset.thumbnail == nil {
                                        let manager = PHCachingImageManager.default()
                                        manager.requestImage(for: imageAsset.asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: nil) { image, _ in
                                            imageAsset.thumbnail = image
                                        }
                                    }
                                }
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        var final: [ImageAsset] = []
                        imagePickerModel.selectedImages.forEach { asset in
                            if !imagePickerModel.pickedImagesIDS.contains(asset.id){
                                final.append(asset)
                                imagePickerModel.pickedImagesIDS.append(asset.id)
                            }
                        }
                        let imageAssets = final.compactMap { imageAsset -> PHAsset? in
                            return imageAsset.asset
                        }
                        onSelect(imageAssets)
                    } label: {
                        Text("Add\(imagePickerModel.selectedImages.isEmpty ? "" : " \(imagePickerModel.selectedImages.count) Images")")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal,30)
                            .padding(.vertical,10)
                            .background{
                                Capsule()
                                    .fill(.blue)
                            }
                    }
                    .disabled(imagePickerModel.selectedImages.isEmpty)
                    .opacity(imagePickerModel.selectedImages.isEmpty ? 0.6 : 1)
                    .padding(.vertical)
                }
            } else {
                VStack(spacing: 10){
                    Spacer()
                    Text("Allow access to photos").font(.system(size: 18)).bold()
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        ZStack {
                            Capsule().foregroundColor(.gray)
                            Text("Settings").foregroundColor(.white).bold().font(.subheadline)
                        }.frame(width: 80, height: 30)
                    }
                    Spacer()
                }
            }
        }
        .frame(height: widthOrHeight(width: false) / 1.8)
        .frame(maxWidth: (widthOrHeight(width: true) - 40) > 350 ? 350 : (widthOrHeight(width: true) - 40))
        .background{
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(env.colorScheme == .dark ? .black : Color(UIColor.lightGray))
        }
        .frame(width: widthOrHeight(width: true), height: widthOrHeight(width: false), alignment: .center)
    }
    
    @ViewBuilder
    func GridContent(imageAsset: ImageAsset)->some View {
        GeometryReader{ proxy in
            let size = proxy.size
            ZStack{
                if let thumbnail = imageAsset.thumbnail{
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }else{
                    ProgressView()
                        .frame(width: size.width, height: size.height, alignment: .center)
                }
                
                ZStack{
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.black.opacity(0.1))
                    
                    Circle()
                        .fill(.white.opacity(0.25))
                    
                    Circle()
                        .stroke(.white,lineWidth: 1)
                    
                    if let index = imagePickerModel.selectedImages.firstIndex(where: { asset in
                        asset.id == imageAsset.id
                    }){
                        Circle()
                            .fill(.blue)
                        Text("\(imagePickerModel.selectedImages[index].assetIndex + 1)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 20, height: 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(5)
            }
            .clipped()
            .onTapGesture {
                withAnimation(.easeInOut){
                    if let index = imagePickerModel.selectedImages.firstIndex(where: { asset in
                        asset.id == imageAsset.id
                    }){
                        if let x = imagePickerModel.pickedImagesIDS.firstIndex(where: { $0 == imageAsset.id }){
                            imagePickerModel.pickedImagesIDS.remove(at: x)
                            if imagePickerModel.pickedImages.count > x {
                                imagePickerModel.pickedImages.remove(at: x)
                            }
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        imagePickerModel.selectedImages.remove(at: index)
                        imagePickerModel.selectedImages.enumerated().forEach { item in
                            imagePickerModel.selectedImages[item.offset].assetIndex = item.offset
                        }
                    } else {
                        if imagePickerModel.selectedImages.count < 5 {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            var newAsset = imageAsset
                            newAsset.assetIndex = imagePickerModel.selectedImages.count
                            imagePickerModel.selectedImages.append(newAsset)
                        }
                    }
                }
            }
        }
        .frame(height: 70)
    }
}

extension View {
    @ViewBuilder
    func popupImagePicker(viewModel: UploadShopViewModel, show: Binding<Bool>,transition: AnyTransition = .move(edge: .bottom),onSelect: @escaping ([PHAsset])->())->some View{
        self
            .overlay {
                ZStack{
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(show.wrappedValue ? 1 : 0)
                        .onTapGesture {
                            show.wrappedValue = false
                        }
                    
                    if show.wrappedValue {
                        PopupImagePickerView(imagePickerModel: viewModel){
                            show.wrappedValue = false
                        } onSelect: { assets in
                            onSelect(assets)
                            show.wrappedValue = false
                        }
                        .transition(transition)
                    }
                }
                .frame(width: widthOrHeight(width: true) * 0.8, height: widthOrHeight(width: false) * 0.6)
                .animation(.easeInOut, value: show.wrappedValue)
            }
    }
}
