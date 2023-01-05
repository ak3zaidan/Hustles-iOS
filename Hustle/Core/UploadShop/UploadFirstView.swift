import SwiftUI
import Kingfisher
import UIKit

class ShopCategories: ObservableObject {
    var tags: [String] = ["all", "cars", "trucks", "home", "kitchen", "garden", "games", "sporting", "tools", "free", "wanted","phones", "furniture", "toys", "Sneakers", "clothes", "motorcycles", "motorcycle parts", "auto parts", "bikes", "bike parts", "boats", "books", "business", "computers", "electronics", "garage", "equipment", "jewelry", "music", "video", "cameras", "tickets", "atv/sno", "wheels", "tires", "appliances", "collectibles", "antiques", "baby", "beauty"]
}

struct UploadFirstView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @ObservedObject var viewModel: UploadShopViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var goodTitle: String = ""
    @State private var goodDesc: String = ""
    @State private var goodZip: Bool = true
    @State private var goodPrice: String = ""
    @Binding var selTab: Int
    let lastTab: Int
    @State private var showCountryPicker = false
    @State private var closeCountryPicker = false
    @State var selectedCountry: String = ""
    
    @State private var showAddTags = false
    @Namespace private var animation
    let isProfile: Bool
    @State var showFixSheet = false
    @State var showAI = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack(){
                    Text("Sell Something").bold().font(.title).padding(.leading).padding(.top, 25)
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if isProfile {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            withAnimation(.easeInOut){
                                selTab = 0
                            }
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("Cancel")
                            .bold()
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(.blue).opacity(0.7)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .scaleEffect(0.9)
                    }.padding(.trailing).padding(.top, 25)
                }.frame(height: 55)
                ZStack{
                    if colorScheme == .dark {
                        LinearGradient(
                            gradient: Gradient(colors: [.black, .blue.opacity(0.7), .black]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .blue.opacity(0.7), .white]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    }
                    ScrollView{
                        VStack {
                            ZStack(alignment: .center){
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                VStack(spacing: 0){
                                    HStack{
                                        Text("Title").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                        Text(goodTitle).font(.caption).foregroundColor(.red).bold()
                                        Spacer()
                                    }.padding()
                                    CustomVideoField(place: "Add a title", text: $viewModel.title)
                                        .padding(.bottom)
                                        .onChange(of: viewModel.title) { _, _ in
                                            goodTitle = inputChecker().myInputChecker(withString: viewModel.title, withLowerSize: 4, withUpperSize: 60, needsLower: true)
                                            if viewModel.title.isEmpty {
                                                goodTitle = ""
                                            }
                                        }
                                    Spacer()
                                }.padding(5)
                            }
                            .frame(width: widthOrHeight(width: true) * 0.95, height: 130)
                            .padding(.top)
                            ZStack(alignment: .center){
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                VStack(spacing: 0){
                                    HStack{
                                        Text("Description").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                        Text(goodDesc).font(.caption).foregroundColor(.red).bold()
                                        Spacer()
                                        if showAI {
                                            Button(action: {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                showFixSheet = true
                                            }, label: {
                                                ZStack {
                                                    Capsule().frame(width: 45, height: 26).foregroundColor(Color.gray).opacity(0.3)
                                                    LottieView(loopMode: .loop, name: "finite")
                                                        .scaleEffect(0.05)
                                                        .frame(width: 25, height: 14)
                                                }
                                            }).transition(.scale.combined(with: .opacity))
                                        }
                                    }.padding()
                                    CustomVideoField(place: "Add a description", text: $viewModel.caption)
                                        .padding(.bottom)
                                        .onChange(of: viewModel.caption, { _, new in
                                            goodDesc = inputChecker().myInputChecker(withString: viewModel.caption, withLowerSize: 30, withUpperSize: 500, needsLower: true)
                                            if viewModel.caption.isEmpty {
                                                goodDesc = ""
                                            }
                                            if viewModel.caption.count > 30 && !showAI {
                                                withAnimation(.easeInOut(duration: 0.15)){
                                                    showAI = true
                                                }
                                            } else if viewModel.caption.count <= 30 && showAI {
                                                withAnimation(.easeInOut(duration: 0.15)){
                                                    showAI = false
                                                }
                                            }
                                        })
                                    Spacer()
                                }.padding(5)
                            }
                            .frame(width: widthOrHeight(width: true) * 0.95, height: 175)
                            .padding(.top)
                            ZStack(alignment: .center){
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                VStack(spacing: 0){
                                    HStack{
                                        HStack(spacing: 5){
                                            Text("Price").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                            Text(goodPrice).font(.caption).foregroundColor(.red).bold().offset(y: 3)
                                        }
                                        Spacer()
                                        ZStack {
                                            HStack{
                                                if viewModel.price.isEmpty {
                                                    Text("Add price").font(.system(size: 15)).foregroundColor(colorScheme == .dark ? .black : .white).padding(.leading)
                                                } else {
                                                    Text("$").font(.system(size: 18)).foregroundColor(colorScheme == .dark ? .black : .white)
                                                }
                                                Spacer()
                                            }
                                            TextField("", text: $viewModel.price)
                                                .padding(.leading)
                                                .foregroundColor(.blue).bold()
                                                .frame(width: 100)
                                                .lineLimit(1).tint(.blue)
                                                .minimumScaleFactor(0.7)
                                                .font(.system(size: 22))
                                                .keyboardType(.numberPad)
                                                .onChange(of: viewModel.price) { _, _ in
                                                    if Int(viewModel.price) ?? 0 < 1 || Int(viewModel.price) ?? 0 > 5000000 {
                                                        goodPrice = "Price must be 1 - 5M"
                                                    } else {
                                                        goodPrice = ""
                                                    }
                                                }
                                                .onAppear { if viewModel.price.isEmpty { goodPrice = "" } }
                                        }.frame(width: 100)
                                    }.padding()
                                }.padding(5)
                            }
                            .frame(width: widthOrHeight(width: true) * 0.95, height: 85)
                            .padding(.top)
                            ZStack(alignment: .center){
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                VStack(spacing: 0){
                                    HStack{
                                        Text("ZipCode").font(.system(size: 22)).foregroundColor(goodZip ? colorScheme == .dark ? .black : .white : .red).bold()
                                        Spacer()
                                        CustomVideoField(place: "zipCode/City", text: $viewModel.zipCode)
                                            .lineLimit(1)
                                            .frame(width: 125)
                                            .onChange(of: viewModel.zipCode) { _, _ in
                                                if viewModel.zipCode.isEmpty {
                                                    goodZip = false
                                                } else {
                                                    goodZip = true
                                                }
                                            }
                                            .onAppear { goodZip = true }
                                        Spacer()
                                        if let country = auth.currentUser?.userCountry {
                                            Button {
                                                withAnimation(.easeInOut){ showCountryPicker = true }
                                            } label: {
                                                Text(country).font(.footnote).foregroundColor(.blue).underline()
                                            }
                                        }
                                    }.padding()
                                }.padding(5)
                            }
                            .frame(width: widthOrHeight(width: true) * 0.95, height: 85)
                            .padding(.top)
                            ZStack(alignment: .center){
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                VStack(spacing: 0){
                                    HStack{
                                        HStack(spacing: 5){
                                            Text("Tags:").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                        }
                                        Spacer()
                                        HStack(spacing: 5){
                                            ForEach(viewModel.tags, id: \.self){ text in
                                                TagView(text, .blue, "")
                                            }
                                        }
                                        Spacer()
                                        Button {
                                            showAddTags.toggle()
                                        } label: {
                                            Image(systemName: "plus").font(.system(size: 20)).foregroundColor(.blue).padding(6).background(.white).cornerRadius(20)
                                        }
                                    }.padding()
                                }.padding(5)
                            }
                            .frame(width: widthOrHeight(width: true) * 0.95, height: 85)
                            .padding(.top)
                            Button {
                                if goodDesc.isEmpty && goodTitle.isEmpty && !viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Int(viewModel.price) ?? 0 >= 1 && Int(viewModel.price) ?? 0 <= 5000000 && !viewModel.zipCode.isEmpty && !viewModel.tags.isEmpty {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    withAnimation(.easeInOut){
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        selTab = 2
                                    }
                                }
                            } label: {
                                ZStack(alignment: .center){
                                    RoundedRectangle(cornerRadius: 25).foregroundColor(.white)
                                    if goodDesc.isEmpty && goodTitle.isEmpty && !viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Int(viewModel.price) ?? 0 >= 1 && Int(viewModel.price) ?? 0 <= 5000000 && !viewModel.zipCode.isEmpty && !viewModel.tags.isEmpty {
                                        RoundedRectangle(cornerRadius: 25).foregroundColor(.orange).opacity(0.7)
                                    } else {
                                        RoundedRectangle(cornerRadius: 25).foregroundColor(.black).opacity(colorScheme == .dark ? 0.2 : 0.4)
                                    }
                                    VStack(spacing: 0){
                                        HStack{
                                            Text("Continue").font(.system(size: 22)).foregroundColor(colorScheme == .dark ? .black : .white).bold()
                                        }.padding()
                                    }.padding(5)
                                }.frame(width: widthOrHeight(width: true) * 0.95, height: 70)
                            }.padding(.top, 5)
                            Color.clear.frame(height: 47)
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            if showCountryPicker {
                CountryPicker(selectedCountry: $selectedCountry, update: true, background: true, close: $showCountryPicker)
                    .onChange(of: selectedCountry) { _, _ in
                        withAnimation {
                            showCountryPicker = false
                        }
                    }
                
            }
        }
        .sheet(isPresented: $showFixSheet, content: {
            RecommendTextView(oldText: $viewModel.caption)
        })
        .ignoresSafeArea()
        .onChange(of: popRoot.tap) { _, _ in
            if popRoot.tap == 2 && selTab == 1 {
                popRoot.tap = 0
                withAnimation(.easeInOut){
                    selTab = 0
                }
            }
        }
        .sheet(isPresented: $showAddTags) {
            VStack {
                VStack(spacing: 0) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.tags, id: \.self) { tag in
                                TagView(tag, .orange, "checkmark")
                                    .matchedGeometryEffect(id: tag, in: animation)
                                    .onTapGesture {
                                        withAnimation {
                                            viewModel.tags.removeAll(where: { $0 == tag })
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 15)
                        .frame(height: 35)
                        .padding(.vertical, 15)
                    }.scrollIndicators(.hidden).zIndex(1)
                    
                    ScrollView(.vertical) {
                        TagLayout(alignment: .center, spacing: 8) {
                            ForEach(ShopCategories().tags.filter { !viewModel.tags.contains($0) }, id: \.self) { tag in
                                TagView(tag, .blue, "plus")
                                    .matchedGeometryEffect(id: tag, in: animation)
                                    .onTapGesture {
                                        withAnimation {
                                            if viewModel.tags.count < 2 {
                                                viewModel.tags.insert(tag, at: 0)
                                            } else {
                                                viewModel.tags.removeLast()
                                                viewModel.tags.insert(tag, at: 0)
                                            }
                                        }
                                    }
                                
                            }
                        }.padding(.vertical, 15).padding(.horizontal, 5)
                    }
                    .scrollIndicators(.hidden)
                    .zIndex(0)
                }
                Spacer()
                Text("Add up to 2 tags").bold().padding(.vertical)
                Button {
                    showAddTags.toggle()
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10).fill(.blue.gradient)
                            .frame(height: 44)
                        Text("Done").font(.system(size: 20)).bold()
                    }.padding(.horizontal)
                }.padding(.bottom, 15).disabled(viewModel.tags.count == 0)
            }
            .edgesIgnoringSafeArea(.horizontal)
            .presentationDetents([.fraction(0.75)])
        }
    }
    @ViewBuilder
    func TagView(_ tag: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .fontWeight(.semibold)
            if !icon.isEmpty {
                Image(systemName: icon)
            }
        }
        .frame(height: 35)
        .foregroundStyle(.white)
        .padding(.horizontal, 15)
        .background {
            Capsule()
                .fill(color.gradient)
        }
    }
}

struct TagLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat = 10
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var height: CGFloat = 0
        let rows = generateRows(maxWidth, proposal, subviews)
        
        for (index, row) in rows.enumerated() {
            if index == (rows.count - 1) {
                height += row.maxHeight(proposal)
            } else {
                height += row.maxHeight(proposal) + spacing
            }
        }
        
        return .init(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        let maxWidth = bounds.width
        
        let rows = generateRows(maxWidth, proposal, subviews)
        
        for row in rows {
            let leading: CGFloat = bounds.maxX - maxWidth
            let trailing = bounds.maxX - (row.reduce(CGFloat.zero) { partialResult, view in
                let width = view.sizeThatFits(proposal).width
                
                if view == row.last {
                    return partialResult + width
                }
                return partialResult + width + spacing
            })
            let center = (trailing + leading) / 2
            
            origin.x = (alignment == .leading ? leading : alignment == .trailing ? trailing : center)
            
            for view in row {
                let viewSize = view.sizeThatFits(proposal)
                view.place(at: origin, proposal: proposal)
                origin.x += (viewSize.width + spacing)
            }
        
            origin.y += (row.maxHeight(proposal) + spacing)
        }
    }
    
    func generateRows(_ maxWidth: CGFloat, _ proposal: ProposedViewSize, _ subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var row: [LayoutSubviews.Element] = []
        var rows: [[LayoutSubviews.Element]] = []
        
        var origin = CGRect.zero.origin
        
        for view in subviews {
            let viewSize = view.sizeThatFits(proposal)
            
            if (origin.x + viewSize.width + spacing) > maxWidth {
                rows.append(row)
                row.removeAll()
                origin.x = 0
                row.append(view)
                origin.x += (viewSize.width + spacing)
            } else {
                row.append(view)
                origin.x += (viewSize.width + spacing)
            }
        }

        if !row.isEmpty {
            rows.append(row)
            row.removeAll()
        }
        
        return rows
    }
}
