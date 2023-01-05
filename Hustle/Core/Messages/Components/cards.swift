import SwiftUI

struct cards: View {
    @State var cards: [String]
    let left: Bool
    @State var offset: CGSize = .zero
    @State var showAsset: Bool = false
    @State var selectedAsset: String? = nil
    @State var idV: String = "\(UUID())"
    @EnvironmentObject var popRoot: PopToRoot
    @State private var showForward = false
    @State var sendLink: String = ""
    
    var body: some View {
        ZStack {
            ForEach(cards.indices, id: \.self) { index in
                StocksContainerView(symbol: cards[index])
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedAsset = cards[index]
                        showAsset = true
                    }
                    .offset(x: left ? Double(((cards.count - 1) - index) * 3) : -Double(((cards.count - 1) - index) * 3), y: -Double(((cards.count - 1) - index) * 2))
                    .offset(x: index == (cards.count - 1) ? offset.width : 0.0, y: index == (cards.count - 1) ? offset.height : 0.0)
                    .highPriorityGesture(DragGesture()
                        .onChanged({ value in
                            let horizontalMovement = value.translation.width
                            let verticalMovement = value.translation.height
                            let total = abs(offset.width) + abs(offset.height)
                            if abs(horizontalMovement) > abs(verticalMovement) || total > 25.0 {
                                if cards.count > 1 {
                                    offset = value.translation
                                }
                            }
                        })
                        .onEnded({ value in
                            if cards.count > 1 {
                                if abs(value.translation.width) > 45.0 {
                                    ended()
                                } else {
                                    withAnimation(.bouncy(duration: 0.3)){
                                        offset = .zero
                                    }
                                }
                            }
                        })
                    )
                    .contextMenu {
                        Button {
                            sendLink = "$\(cards[index].uppercased())"
                            showForward = true
                        } label: {
                            Label("Share \(cards[index].uppercased())", systemImage: "paperplane")
                        }
                        Button {
                            popRoot.alertReason = "\(cards[index].uppercased()) copied"
                            popRoot.alertImage = "link"
                            withAnimation {
                                popRoot.showAlert = true
                            }
                            UIPasteboard.general.string = "$\(cards[index].uppercased())"
                        } label: {
                            Label("Copy asset symbol", systemImage: "link")
                        }
                    }
            }
        }
        .id(idV)
        .padding(.top, CGFloat(self.cards.count * 2))
        .sheet(isPresented: $showAsset, content: {
            AllStockView(symbol: selectedAsset ?? "", name: "", selected: $selectedAsset, isSheet: true)
                .dynamicTypeSize(.large)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        })
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
    }
    func ended(){
        withAnimation(.bouncy(duration: 0.3)){
            let element = cards.removeLast()
            cards.insert(element, at: 0)
            offset = .zero
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4){
                idV = UUID().uuidString
            }
        }
    }
}
