import SwiftUI
import UIKit

struct PromoteUploadView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @State private var selectedFilter: PromoteViewModel = .USD
    @ObservedObject var viewModel: UploadJobViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var storeKit = StoreKitManager()
    @State var purchaseFailed: Bool = false
    
    @State private var tooManyInOneHour = ""
    @State private var startTimer = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var jobImage: Image?
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
                    withAnimation(.easeIn(duration: 0.2)){
                        selTab = 2
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                        .scaleEffect(1.5)
                        .frame(width: 15, height: 15)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                Spacer()
            }
            .padding(.leading, 35)
            .padding(.top)

            ScrollView {
                VStack(alignment: .trailing, spacing: 0){
                    Button {
                        showImagePicker.toggle()
                    } label: {
                        if let jobImage = jobImage{
                            HStack(spacing: 20){
                                jobImage
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 250, maxHeight: 250)
                                    .cornerRadius(5)
                                    .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
                                        .onEnded { value in
                                            selectedImage = nil
                                            self.jobImage = nil
                                        })
                                VStack(spacing: 10){
                                    HStack{
                                        Image(systemName: "pencil").foregroundColor(.gray)
                                        Text("Tap to replace").font(.subheadline)
                                        Spacer()
                                    }
                                    HStack{
                                        Image(systemName: "pencil").foregroundColor(.gray)
                                        Text("Swipe left to remove").font(.subheadline)
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }.padding(.leading, 35)
                        } else {
                            Spacer()
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
                            Spacer()
                        }
                    }
                    .sheet(isPresented: $showImagePicker, onDismiss: loadImage){
                        ImagePicker(selectedImage: $selectedImage)
                            .tint(colorScheme == .dark ? .white : .black)
                    }
                }
                .padding(.bottom, (selectedImage != nil) ?  66 : 160)
                .padding(.top, 40)
                VStack(spacing: 15){
                    if let user = authViewModel.currentUser {
                        if user.elo < 2000 {
                            promoteFilter
                            if selectedFilter == .USD {
                                PromoteUSD(selection: $promotedUSD)
                            }
                            if selectedFilter == .ELO {
                                PromoteELO(days: $promotedELO, userElo: authViewModel.currentUser?.elo ?? 0)
                            }
                        } else {
                            ZStack{
                                RoundedRectangle(cornerRadius: 10).frame(width: 120, height: 45).foregroundColor(Color(UIColor.lightGray))
                                Text("Auto Promoted").font(.system(size: 15)).foregroundColor(.black).bold()
                            }.shimmering()
                        }
                    } else {
                        promoteFilter
                        if selectedFilter == .USD {
                            PromoteUSD(selection: $promotedUSD)
                        }
                        if selectedFilter == .ELO {
                            PromoteELO(days: $promotedELO, userElo: authViewModel.currentUser?.elo ?? 0)
                        }
                    }
                }
            }.scrollIndicators(.hidden)
            Text("*Promoted jobs appear at the top").font(.subheadline).padding(.top, 10)
            Spacer()
            Text(viewModel.uploadError).font(.subheadline).foregroundColor(.red)
            if tooManyInOneHour.isEmpty {
                Button {
                    if !uploaded && !viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (viewModel.selected || viewModel.isValidZipCode(viewModel.zipCode)) {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        if let user = authViewModel.currentUser {
                            var go = 0
                            let user2 = profile.users.first(where: { $0.user.username == user.username })
                            if let posts = user2?.listJobs?.prefix(7) {
                                let arr = Array(posts)
                                arr.forEach { element in
                                    if calculateCosineSimilarity(viewModel.caption, element.job.caption) > 0.6 {
                                        viewModel.uploadError = "This job matches another, please make it unique."
                                        go = 1
                                    }
                                }
                            }
                            if go == 0 {
                                if promotedELO > 0 {
                                    viewModel.uploadJobImage(withImage: selectedImage, withPro: promotedELO, photo: user.profileImageUrl ?? "", username: user.username, jobPointer: user.jobPointer, userCounry: user.userCountry)
                                    uploaded = true
                                } else if promotedUSD > 0 {
                                    Task {
                                        if promotedUSD == 3{
                                            if let product = storeKit.storeProducts.first(where: { $0.id == "3Day" }){
                                                do {
                                                    let result = try await storeKit.purchase(product)
                                                    if result {
                                                        viewModel.uploadJobImage(withImage: selectedImage, withPro: 3, photo: user.profileImageUrl ?? "", username: user.username, jobPointer: user.jobPointer, userCounry: user.userCountry)
                                                        startTimer = true
                                                    } else { purchaseFailed = true }
                                                } catch { purchaseFailed = true }
                                            }
                                        } else {
                                            if let product = storeKit.storeProducts.first(where: { $0.id == "1Day" }){
                                                do {
                                                    let result = try await storeKit.purchase(product)
                                                    if result {
                                                        viewModel.uploadJobImage(withImage: selectedImage, withPro: 1, photo: user.profileImageUrl ?? "", username: user.username, jobPointer: user.jobPointer, userCounry: user.userCountry)
                                                        startTimer = true
                                                    } else { purchaseFailed = true }
                                                } catch { purchaseFailed = true }
                                            }
                                        }
                                    }
                                } else {
                                    viewModel.uploadJobImage(withImage: selectedImage, withPro: kingPro, photo: user.profileImageUrl ?? "", username: user.username, jobPointer: user.jobPointer, userCounry: user.userCountry)
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
                            .background(!viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (viewModel.selected || viewModel.isValidZipCode(viewModel.zipCode)) ? .orange : .gray).opacity(0.7)
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
        .alert("Purchase failed", isPresented: $purchaseFailed) {
            Button("Close", role: .cancel) {}
        }
        .onDisappear{ tooManyInOneHour = "" }
        .onReceive(viewModel.$didUploadJob) { success in
            if success {
                if promotedELO > 0 {
                    UserService().editElo(withUid: nil, withAmount: (promotedELO * -50)) {}
                }
                viewModel.caption = ""
                viewModel.zipCode = ""
                viewModel.title = ""
                viewModel.link = ""
                viewModel.selected = false
                viewModel.didUploadJob = false
                selectedImage = nil
                jobImage = nil
                if !viewModel.locationToAdd.isEmpty {
                    authViewModel.currentUser?.jobPointer.append(viewModel.locationToAdd)
                    viewModel.locationToAdd = ""
                }
                if isProfile {
                    presentationMode.wrappedValue.dismiss()
                    selTab = lastTab
                    uploaded = false
                } else {
                    withAnimation(.easeIn(duration: 0.2)){
                        selTab = lastTab
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
            viewModel.uploadError = ""
            tooManyInOneHour = ""
            if let user = authViewModel.currentUser {
                if user.elo >= 2000 { kingPro = 4 }
                if user.elo >= 850 { return }
                else {
                    let hustles = profile.users.first(where: { $0.user.username == user.username })
                    if let posts = hustles?.listJobs {
                        var x = 0
                        let currentDate = Date()
                        posts.forEach { item in
                            let date = item.job.timestamp.dateValue()
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
            if selTab == 3 && popRoot.tap == 2 {
                withAnimation(.easeIn(duration: 0.2)){
                    selTab = 2
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
    func loadImage() {
        guard let selectedImage = selectedImage else {return}
        jobImage = Image(uiImage: selectedImage)
    }
}
extension PromoteUploadView{
    var promoteFilter: some View {
        HStack{
            ForEach(PromoteViewModel.allCases, id: \.rawValue){ item in
                if let user = authViewModel.currentUser {
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
        }
        .overlay(Divider().offset(x:0, y:16))
    }
}
