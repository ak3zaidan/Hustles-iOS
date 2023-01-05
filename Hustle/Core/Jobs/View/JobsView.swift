import SwiftUI
import Foundation
import Kingfisher

struct JobsView: View {
    @State private var textScale = 1.0
    @State private var screenBlur = 0.0
    @State private var switching = false
    @StateObject var PostShopViewModel = UploadShopViewModel()
    @EnvironmentObject var ShopModel: ShopViewModel
    @State var searchText: String = ""
    @State private var canRFour = true
    @State private var canFour = true
    @State private var showFind = true
    @State private var scrollTracker: Double = 0
    
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var viewModel: JobViewModel
    @StateObject var uploadViewModel = UploadJobViewModel()
    @State var isShowing: Bool = false
    @State var showFixZip: Bool = false
    @State var zipCodeBarPlaceHolder: String = ""
    static let myColor = Color("lightgray")
    let spaceName = "scroll"
    @State private var clickOne: Int = 0
    @State private var clickThree: Int = 0
    @State var scrollViewSize: CGSize = .zero
    @State var wholeSize: CGSize = .zero
    @State private var selection = 0
    @State private var selectionShop = 0
    @State private var offset: Double = 0
    @State private var canROne = true
    @State private var canRThree = true
    @State private var canOne = true
    @State private var canThree = true
    @State private var lastTab: Int = 0
    @State private var showCountryPicker = false
    @State var selectedCountry: String = ""
    @Environment(\.colorScheme) var colorScheme
    let generator = UINotificationFeedbackGenerator()
    @EnvironmentObject var ads: AdsManager
    @State var lower: [String] = ["iPhone 8", "iPhone SE"]
    @State var currentAudio: String = ""
    @Namespace private var animation
    @State var tempSet: Bool = false
    @Namespace private var newsAnimation
    
    var body: some View {
        ZStack {
            VStack {
                if (selection != 2 && selection != 3 && popRoot.Job_or_Shop) || (selectionShop == 0 && !popRoot.Job_or_Shop){
                    ZStack {
                        HStack {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut){
                                    zipCodeBarPlaceHolder = viewModel.zip
                                    isShowing.toggle()
                                }
                            } label: {
                                HStack(spacing: 1){
                                    Image(systemName: "mappin.and.ellipse").foregroundColor(.gray)
                                    Text(viewModel.zip).font(.system(size: 18)).foregroundColor(.gray).lineLimit(1).minimumScaleFactor(0.7)
                                }
                            }.frame(width: widthOrHeight(width: true) * 0.3)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Button {
                                if popRoot.Job_or_Shop {
                                    ShopModel.start(zipCode: viewModel.zip, country: auth.currentUser?.userCountry ?? "")
                                }
                                Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
                                    withAnimation(.linear(duration: 0.1)){
                                        popRoot.Job_or_Shop.toggle()
                                    }
                                    withAnimation(.linear(duration: 0.6)){ screenBlur = 0.0 }
                                }
                                withAnimation(.linear(duration: 0.6)){ screenBlur = 20.0 }
                            } label: {
                                if popRoot.Job_or_Shop {
                                    Text("Jobs").font(.title).bold().foregroundColor(.orange)
                                } else {
                                    HStack(spacing: 1){
                                        Text("4").font(.title).bold()
                                        Text("Sale").font(.title).bold().foregroundColor(.orange)
                                    }
                                }
                            }.scaleEffect(textScale)
                            Spacer()
                        }
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                                withAnimation(.linear(duration: 0.1)){ textScale = 1.2 }
                            }
                            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                withAnimation(.linear(duration: 0.1)){ textScale = 1.0 }
                            }
                            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                                withAnimation(.linear(duration: 0.1)){ textScale = 1.2 }
                            }
                            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                withAnimation(.linear(duration: 0.1)){ textScale = 1.0 }
                            }
                        }
                        HStack {
                            Spacer()
                            if popRoot.Job_or_Shop {
                                DropdownMenu(selectedOption: $viewModel.distance, placeholder: "Distance", options: DropdownMenuOption.testAllMonths)
                                    .frame(width: 110, height: 40)
                                    .onChange(of: viewModel.zip, { _, _ in
                                        if (viewModel.distance?.option != "Nearby" && viewModel.distance?.option != "Remote"){
                                            if viewModel.isValidZipCode(viewModel.zip) {
                                                viewModel.distance = DropdownMenuOption(option: "Nearby")
                                            } else {
                                                viewModel.distance = DropdownMenuOption(option: "Remote")
                                            }
                                        }
                                    })
                                    .onChange(of: viewModel.distance) { _, _ in
                                        if viewModel.distance?.option == "Nearby" {
                                            lastTab = 0
                                            if clickOne == 0 {
                                                viewModel.start(country: auth.currentUser?.userCountry ?? "", ads: ads.ads)
                                                clickOne += 1
                                            }
                                            withAnimation(.easeInOut){
                                                selection = 0
                                            }
                                        } else {
                                            lastTab = 1
                                            if clickThree == 0 {
                                                viewModel.beginRemote(ads: ads.ads)
                                                clickThree += 1
                                            }
                                            withAnimation(.easeInOut){
                                                selection = 1
                                            }
                                        }
                                    }
                                    .onAppear {
                                        if (viewModel.zip.isEmpty || viewModel.zip == "zipCode") && viewModel.distance?.option != "Remote" {
                                            viewModel.getZipCode { zip, country in
                                                if let userCountry = self.auth.currentUser?.userCountry, !country.isEmpty && userCountry != country {
                                                    self.auth.currentUser?.userCountry = country
                                                }
                                                if isValidZipCode(zip) {
                                                    viewModel.distance = DropdownMenuOption(option: "Nearby")
                                                } else {
                                                    if let zipCode = auth.currentUser?.zipCode {
                                                        if isValidZipCode(zipCode){
                                                            viewModel.zip = zipCode
                                                            viewModel.distance = DropdownMenuOption(option: "Nearby")
                                                        } else {
                                                            viewModel.distance = DropdownMenuOption(option: "Remote")
                                                        }
                                                    } else {
                                                        viewModel.distance = DropdownMenuOption(option: "Remote")
                                                    }
                                                    viewModel.menuGetLocationButton = "Update in Settings"
                                                }
                                            }
                                        } else if isValidZipCode(viewModel.zip) {
                                            if !viewModel.countryToSet.isEmpty {
                                                auth.currentUser?.userCountry = viewModel.countryToSet
                                                viewModel.countryToSet = ""
                                            }
                                            if (viewModel.distance?.option != "Nearby" && viewModel.distance?.option != "Remote"){
                                                viewModel.distance = DropdownMenuOption(option: "Nearby")
                                            }
                                        }
                                    }
                                    .onChange(of: selection, { _, _ in
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        if popRoot.Job_or_Shop {
                                            if selection == 0 {
                                                impactFeedbackgenerator.impactOccurred()
                                                viewModel.distance = DropdownMenuOption(option: "Nearby")
                                            } else if selection == 1 {
                                                impactFeedbackgenerator.impactOccurred()
                                                viewModel.distance = DropdownMenuOption(option: "Remote")
                                            }
                                        }
                                    })
                            } else {
                                DownMenu(selectedOption: $ShopModel.shopSort, placeholder: "Sort", options: MenuOption.testAllMonths)
                                    .frame(width: 110, height: 40)
                                    .onChange(of: ShopModel.shopSort) { _, _ in
                                        if ShopModel.shopSort?.option == "Closest first" {
                                            ShopModel.sortClose()
                                        } else if ShopModel.shopSort?.option == "Price: Low to High" {
                                            ShopModel.sortPriceAscend()
                                        } else if ShopModel.shopSort?.option == "Price: High to Low" {
                                            ShopModel.sortPriceDescend()
                                        } else {
                                            ShopModel.sortNew()
                                        }
                                    }
                            }
                        }
                    }.zIndex(1.0).padding(.horizontal, 5)
                }
                if !popRoot.Job_or_Shop && selectionShop == 0 {
                    ZStack{
                        SearchBar(text: $searchText, fill: "").tint(.blue)
                        HStack{
                            Spacer()
                            if ShopModel.selectedCategory == "all" {
                                TagView(ShopModel.selectedCategory, .blue, "checkmark")
                            } else {
                                Button {
                                    withAnimation {
                                        ShopModel.selectedCategory = "all"
                                    }
                                    ShopModel.getTag(tagName: "all", pass: false, totalGot: 0)
                                } label: {
                                    TagView(ShopModel.selectedCategory, .blue, "xmark")
                                }
                            }
                        }.padding(.trailing, 5)
                    }.padding(.horizontal)
                    ScrollView(.horizontal) {
                        HStack(spacing: 4) {
                            Color.clear.frame(width: 5, height: 5)
                            ForEach(ShopCategories().tags, id: \.self) { tag in
                                if tag.contains(searchText.lowercased()) || searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        if ShopModel.selectedCategory != tag {
                                            ShopModel.getTag(tagName: tag, pass: false, totalGot: 0)
                                            withAnimation {
                                                ShopModel.selectedCategory = tag
                                            }
                                        }
                                    } label: {
                                        TagView(tag, .orange, "plus")
                                    }
                                }
                            }
                        }
                    }.scrollIndicators(.hidden).frame(height: 35)
                }
                ZStack(alignment: .bottomTrailing){
                    TabView(selection: popRoot.Job_or_Shop ? $selection : $selectionShop) {
                        if popRoot.Job_or_Shop {
                            ScrollViewReader { proxy in
                                ChildSizeReader(size: $wholeSize) {
                                    ScrollView {
                                        ChildSizeReader(size: $scrollViewSize) {
                                            LazyVStack {
                                                Color.clear.frame(height: 1).id("scrolltop")
                                                if viewModel.noResultsFound {
                                                    noResults
                                                        .padding(.top, 50)
                                                } else if viewModel.shopContent.first?.close.isEmpty ?? true {
                                                    VStack {
                                                        ForEach(0..<7){ i in
                                                            LoadingFeed(lesson: "")
                                                        }
                                                    }.shimmering()
                                                } else if let item = viewModel.shopContent.first {
                                                    ForEach(item.close.indices, id: \.self) { i in
                                                        if i == item.outsideSearchIndex && item.outsideSearchIndex == 0 && !item.afterException {
                                                            outside
                                                        }
                                                        if(item.close[i].start != nil){
                                                            TweetRowView(tweet: item.close[i], edit: false, canShow: true, canSeeComments: true, map: false, currentAudio: $currentAudio, isExpanded: $tempSet, animationT: animation, seenAllStories: false, isMain: false, showSheet: $tempSet, newsAnimation: newsAnimation)
                                                                .padding(.horizontal).padding(.vertical, 6)
                                                        } else {
                                                            JobsRowView(canShowProfile: true, remote: false, job: item.close[i], is100: (i > item.outsideSearchIndex && item.outsideSearchIndex >= 0) ? true : false, canMessage: true)
                                                                .padding(.horizontal).padding(.vertical, 6)
                                                        }
                                                        if i < item.close.count - 1 && i == item.outsideSearchIndex && (item.outsideSearchIndex > 0 || item.afterException) {
                                                            outside
                                                        }
                                                    }
                                                    if offset > 400 {
                                                        ProgressView()
                                                    }
                                                }
                                                if let farElements = viewModel.farAway {
                                                    HStack {
                                                        Text(farElements.1).font(.title3).bold().foregroundStyle(Color(red: 0.5, green: 0.6, blue: 1.0))
                                                        Spacer()
                                                    }.padding(.leading).padding(.top, 30)
                                                    ForEach(farElements.0) { ele in
                                                        JobsRowView(canShowProfile: true, remote: false, job: ele, is100: true, canMessage: true)
                                                            .padding(.horizontal).padding(.vertical, 6)
                                                    }
                                                }
                                                Color.clear.frame(height: 50)
                                            }
                                            .background(GeometryReader {
                                                Color.clear.preference(key: ViewOffsetKey.self,
                                                                       value: -$0.frame(in: .named("scroll")).origin.y)
                                            })
                                            .onPreferenceChange(ViewOffsetKey.self) { value in
                                                if value > (scrollTracker + 120) {
                                                    scrollTracker = value
                                                    withAnimation {
                                                        showFind = false
                                                    }
                                                }
                                                if value < (scrollTracker - 200) || value < 20 {
                                                    scrollTracker = value
                                                    withAnimation {
                                                        showFind = true
                                                    }
                                                }
                                                offset = value
                                                if offset > 200 && canOne  {
                                                    if value > (scrollViewSize.height - wholeSize.height) - 400 {
                                                        canOne = false
                                                        viewModel.getClose(ads: ads.ads)
                                                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                                            canOne = true
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .refreshable { }
                                    .onChange(of: popRoot.tap) { _, _ in
                                        if popRoot.tap == 2 && selection == 0 {
                                            withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                                            popRoot.tap = 0
                                        }
                                    }
                                }.coordinateSpace(name: spaceName)
                            }.tag(0)
                            ScrollViewReader { proxy in
                                ChildSizeReader(size: $wholeSize) {
                                    ScrollView {
                                        ChildSizeReader(size: $scrollViewSize) {
                                            LazyVStack {
                                                Color.clear.frame(height: 1).id("scrolltop")
                                                if viewModel.jobsThree.isEmpty {
                                                    VStack {
                                                        ForEach(0..<7){ i in
                                                            LoadingFeed(lesson: "")
                                                        }
                                                    }.shimmering()
                                                } else {
                                                    ForEach(viewModel.jobsThree.indices, id: \.self) { i in
                                                        if(viewModel.jobsThree[i].start != nil){
                                                            TweetRowView(tweet: viewModel.jobsThree[i], edit: false, canShow: true, canSeeComments: true, map: false, currentAudio: $currentAudio, isExpanded: $tempSet, animationT: animation, seenAllStories: false, isMain: false, showSheet: $tempSet, newsAnimation: newsAnimation)
                                                                .padding(.horizontal)
                                                                .padding(.vertical, 6)
                                                        } else {
                                                            JobsRowView(canShowProfile: true, remote: true, job: viewModel.jobsThree[i], is100: false, canMessage: true)
                                                                .padding(.horizontal)
                                                                .padding(.vertical, 6)
                                                        }
                                                    }
                                                    if offset > 100 {
                                                        ProgressView()
                                                    }
                                                }
                                                Color.clear.frame(height: 50)
                                            }
                                            .background(GeometryReader {
                                                Color.clear.preference(key: ViewOffsetKey.self,
                                                                       value: -$0.frame(in: .named("scroll")).origin.y)
                                            })
                                            .onPreferenceChange(ViewOffsetKey.self) { value in
                                                if value > (scrollTracker + 120) {
                                                    scrollTracker = value
                                                    withAnimation {
                                                        showFind = false
                                                    }
                                                }
                                                if value < (scrollTracker - 200) || value < 20 {
                                                    scrollTracker = value
                                                    withAnimation {
                                                        showFind = true
                                                    }
                                                }
                                                offset = value
                                                if offset > 200 {
                                                    if value > (scrollViewSize.height - wholeSize.height) - 400{
                                                        if canThree && viewModel.jobsThree.count > 20{
                                                            canThree = false
                                                            viewModel.beginAddMoreRemote(lastdoc: viewModel.lastRemote, ads: ads.ads)
                                                            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                                                canThree = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .refreshable { }
                                    .onChange(of: popRoot.tap) { _, _ in
                                        if popRoot.tap == 2 && selection == 1 {
                                            withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                                            popRoot.tap = 0
                                        }
                                    }
                                }.coordinateSpace(name: spaceName)
                            }.tag(1)
                            UploadJobView(viewModel: uploadViewModel, selTab: $selection, lastTab: lastTab, isProfile: false)
                                .tag(2)
                            PromoteUploadView(viewModel: uploadViewModel, selTab: $selection, lastTab: lastTab, isProfile: false)
                                .tag(3)
                        } else {
                            ScrollViewReader { proxy in
                                ChildSizeReader(size: $wholeSize) {
                                    ScrollView {
                                        Color.clear.frame(height: 1).id("scrolltop")
                                        if ShopModel.no_results {
                                            noResults.padding(.top, 50)
                                        } else if ShopModel.shopContent.first?.display.isEmpty ?? true {
                                            ShopLoadingView()
                                        } else {
                                            ChildSizeReader(size: $scrollViewSize) {
                                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                                                    if let arr = ShopModel.shopContent.first {
                                                        ForEach(arr.display){ item in
                                                            NavigationLink{
                                                                SingleShopView(shopItem: item, disableUser: false, shouldCloseKeyboard: true)
                                                                    .onAppear {
                                                                        withAnimation(.spring()){
                                                                            self.popRoot.hideTabBar = true
                                                                        }
                                                                    }
                                                                    .onDisappear {
                                                                        withAnimation(.spring()){
                                                                            self.popRoot.hideTabBar = false
                                                                        }
                                                                    }
                                                            } label: {
                                                                ShopRowView(shopItem: item, isSheet: false)
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal, 5)
                                                .background(GeometryReader {
                                                    Color.clear.preference(key: ViewOffsetKey.self,
                                                                           value: -$0.frame(in: .named("scroll")).origin.y)
                                                })
                                                .onPreferenceChange(ViewOffsetKey.self) { value in
                                                    if value > (scrollTracker + 120) {
                                                        scrollTracker = value
                                                        withAnimation {
                                                            showFind = false
                                                        }
                                                    }
                                                    if value < (scrollTracker - 200) || value < 20 {
                                                        scrollTracker = value
                                                        withAnimation {
                                                            showFind = true
                                                        }
                                                    }
                                                    offset = value
                                                    if offset > 200 && canFour && (value > (scrollViewSize.height - wholeSize.height) - 400){
                                                        canFour = false
                                                        if ShopModel.selectedCategory == "all" {
                                                            ShopModel.getClose()
                                                        } else {
                                                            ShopModel.getTag(tagName: ShopModel.selectedCategory, pass: true, totalGot: 0)
                                                        }
                                                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                                            canFour = true
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        Color.clear.frame(height: 70)
                                    }
                                    .refreshable { }
                                    .scrollIndicators(.hidden)
                                    .gesture(DragGesture().onChanged { _ in
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    })
                                    .onChange(of: popRoot.tap) { _, _ in
                                        if popRoot.tap == 2 && selectionShop == 0 {
                                            withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                                            popRoot.tap = 0
                                        }
                                    }
                                }.coordinateSpace(name: spaceName)
                            }.tag(0)
                            UploadFirstView(viewModel: PostShopViewModel, selTab: $selectionShop, lastTab: lastTab, isProfile: false).tag(1)
                            UploadSecView(viewModel: PostShopViewModel, selTab: $selectionShop, lastTab: lastTab, isProfile: false).tag(2)
                        }
                    }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    if (selection != 2 && selection != 3 && popRoot.Job_or_Shop) || (selectionShop == 0 && !popRoot.Job_or_Shop){
                        HStack {
                            Spacer()
                            Button {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                if popRoot.Job_or_Shop { selection = 2
                                } else { selectionShop = 1 }
                            } label: {
                                Image("logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 57)
                                    .padding()
                            }
                            .shadow(color: .gray.opacity(0.6), radius: 10, x: 0, y: 0)
                            .frame(width: 75, height: 35)
                            .background(Color(.systemOrange).opacity(showFind ? 0.9 : 0.4))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            Spacer()
                        }.padding(.bottom, 105)
                    }
                    VStack(){
                        if (offset <= -70) {
                            HStack {
                                Spacer()
                                Loader(flip: true).offset(y: popRoot.Job_or_Shop ? 0 : -15)
                                Spacer()
                            }
                            .padding(.top)
                            Spacer()
                        }
                    }
                }
            }
            .onChange(of: offset) { _, newVal in
                if offset <= -90 {
                    if popRoot.Job_or_Shop {
                        if (selection == 0) && canROne {
                            viewModel.refreshClose()
                            generator.notificationOccurred(.success)
                            canROne = false
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                canROne = true
                            }
                        } else if canRThree {
                            viewModel.beginRemote(ads: ads.ads)
                            generator.notificationOccurred(.success)
                            canRThree = false
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                canRThree = true
                            }
                        }
                    } else {
                        if canRFour {
                            generator.notificationOccurred(.success)
                            ShopModel.refresh(zipCode: viewModel.zip, country: auth.currentUser?.userCountry ?? "")
                            canRFour = false
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                canRFour = true
                            }
                        }
                    }
                }
            }
            if showCountryPicker {
                CountryPicker(selectedCountry: $selectedCountry, update: true, background: true, close: $showCountryPicker)
                    .onChange(of: selectedCountry) { _, _ in
                        viewModel.AssosiatedCity = ""
                        viewModel.AssosiatedState = ""
                        showCountryPicker = false
                        if !popRoot.Job_or_Shop {
                            zipCodeBarPlaceHolder = ""
                            viewModel.zip = "zipCode"
                        }
                        withAnimation(.easeInOut){
                            isShowing = true
                        }
                    }
                
            }
        }
        .disabled(switching)
        .blur(radius: screenBlur)
        .onChange(of: showCountryPicker) { _, _ in
            if !showCountryPicker {
                withAnimation(.easeInOut){ 
                    isShowing = true
                }
            }
        }
        .onDisappear {
            if viewModel.isValidZipCode(viewModel.zip) && viewModel.menuGetLocationButton == "Update in Settings" && viewModel.zipChanged {
                viewModel.uploadZipToDatabase(withZip: viewModel.zip)
                auth.currentUser?.zipCode = viewModel.zip
                viewModel.zipChanged = false
            }
        }
        .onAppear {
            if !popRoot.Job_or_Shop {
                ShopModel.start(zipCode: viewModel.zip, country: auth.currentUser?.userCountry ?? "")
            }
            Timer.scheduledTimer(withTimeInterval: 6.5, repeats: false) { _ in
                if viewModel.zip.isEmpty && viewModel.distance?.option != "Nearby" && viewModel.distance?.option != "Remote" {
                    if let zipCode = auth.currentUser?.zipCode {
                        if viewModel.isValidZipCode(zipCode) {
                            viewModel.zip = zipCode
                        } else { viewModel.distance = DropdownMenuOption(option: "Remote") }
                    } else { viewModel.distance = DropdownMenuOption(option: "Remote") }
                    viewModel.menuGetLocationButton = "Update in Settings"
                }
            }
        }
        .onChange(of: viewModel.zip, { _, _ in
            viewModel.noResultsFound = false
            ShopModel.setCity = ""
            ShopModel.setState = ""
            ShopModel.setCountry = ""
            if !popRoot.Job_or_Shop && isValidZipCode(viewModel.zip) {
                ShopModel.start(zipCode: viewModel.zip, country: auth.currentUser?.userCountry ?? "")
            }
        })
        .sheet(isPresented: $isShowing) {
            if #available(iOS 16.4, *) {
                placePicker().presentationCornerRadius(40)
            } else {
                placePicker()
            }
        }
    }
    func isValidZipCode(_ zipCode: String) -> Bool {
        let trimmedZipCode = zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedZipCode.isEmpty && zipCode != "zipCode"
    }
    func TagView(_ tag: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 3) {
            Text(tag).font(.callout).fontWeight(.semibold)
            Image(systemName: icon)
        }
        .frame(height: 25)
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .background { Capsule().fill(color.gradient) }
    }
    func placePicker() -> some View {
        VStack {
            HStack {
                Text("Where are you searching?").foregroundColor(.black)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 8)
            
            Button {
                if viewModel.menuGetLocationButton == "Current Location" {
                    viewModel.getZipCode { zip, country in
                        if let userCountry = self.auth.currentUser?.userCountry, !country.isEmpty && userCountry != country {
                            self.auth.currentUser?.userCountry = country
                        }
                        zipCodeBarPlaceHolder = zip
                        viewModel.AssosiatedCity = ""
                        viewModel.AssosiatedState = ""
                        if !country.isEmpty { auth.currentUser?.userCountry = country }
                    }
                } else {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } label: {
                ZStack {
                    Capsule()
                        .foregroundColor(.gray)
                    Text(viewModel.menuGetLocationButton)
                        .foregroundColor(.white).bold()
                        .font(.subheadline)
                }.frame(width: 200, height: 30)
            }
            VStack {
                zipCodeBar(text: $zipCodeBarPlaceHolder)
                    .frame(width: 240, height: 70)
                    .onDisappear {
                        self.showFixZip = false
                    }
                HStack(spacing: 5){
                    if !viewModel.AssosiatedCity.isEmpty && !viewModel.AssosiatedState.isEmpty {
                        Text("\(viewModel.AssosiatedCity), \(viewModel.AssosiatedState)")
                            .font(.subheadline).bold().foregroundColor(.black)
                    } else if !viewModel.AssosiatedCity.isEmpty {
                        Text("\(viewModel.AssosiatedCity)")
                            .font(.subheadline).bold().foregroundColor(.black)
                    } else if !viewModel.AssosiatedState.isEmpty {
                        Text("\(viewModel.AssosiatedState)")
                            .font(.subheadline).bold().foregroundColor(.black)
                    }
                    if let country = auth.currentUser?.userCountry {
                        Button {
                            isShowing = false
                            withAnimation(.easeInOut){ showCountryPicker = true }
                        } label: {
                            Text(country).font(.subheadline).bold().foregroundColor(.blue).underline()
                        }
                    }
                }
            }.padding(.bottom, showFixZip ? 0 : 85)
            if showFixZip {
                Text("Enter a valid zipCode or city")
                    .font(.footnote)
                    .foregroundColor(.red).bold()
                    .padding(.bottom, 85)
            }
            VStack {
                Button {
                    if isValidZipCode(zipCodeBarPlaceHolder) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showFixZip = false
                        viewModel.zip = zipCodeBarPlaceHolder
                        viewModel.AssosiatedCity = ""
                        viewModel.AssosiatedState = ""
                        viewModel.AssosiatedCountry = ""
                        if viewModel.distance?.option == "Nearby" {
                            viewModel.start(country: auth.currentUser?.userCountry ?? "", ads: ads.ads)
                        } else {
                            clickOne = 0
                            viewModel.distance = DropdownMenuOption(option: "Nearby")
                        }
                        if viewModel.zip != auth.currentUser?.zipCode { viewModel.zipChanged = true }
                        isShowing.toggle()
                    } else {
                        showFixZip = true
                    }
                } label: {
                    Text("Apply")
                        .foregroundColor(.black).bold()
                        .font(.subheadline)
                        .frame(width: 240, height: 32)
                }
                .background(.orange.opacity(0.7))
                .mask {
                    RoundedRectangle(cornerRadius: 10)
                }
            }.padding(.bottom)
        }
        .presentationDetents([lower.contains(UIDevice.modelName) ? .fraction(0.5) : .fraction(0.4)])
        .presentationDragIndicator(.hidden)
        .background(colorScheme == .dark ? JobsView.myColor : Color(.lightGray))
    }
}

extension JobsView {
    var noResults: some View{
        VStack(alignment: .center,spacing: 20){
            Text("No search results").font(.title3)
            Text(popRoot.Job_or_Shop ? "Set a new zipcode/city to find jobs" : "Set a new zipcode/city to find items").foregroundColor(.gray).font(.subheadline)
            Button {
                isShowing.toggle()
            } label: {
                ZStack(alignment: .center){
                    Capsule().foregroundColor(.orange)
                    Text("update zipcode/city").foregroundColor(.black).font(.subheadline)
                }.frame(width: 170, height: 35)
            }
        }
    }
    var outside: some View{
        VStack(alignment: .center){
            Text("-- Results a little further --").font(.title3)
            Divider().overlay(colorScheme == .dark ? Color(red: 220/255, green: 220/255, blue: 220/255) : .gray)
                .padding(.top, 15)
        }.padding(.vertical, 15)
    }
}
