import SwiftUI

struct StockRowView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var showForward = false
    @State var sendString: String = ""
    
    let coin: CryptoModel
    let isHoliday: Bool
    let isSaved: Bool
    let copied: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0){
            HStack {
                VStack(alignment: .leading){
                    HStack(spacing: 8){
                        Text(coin.symbol.uppercased()).font(.system(size: 18))
                        if isSaved {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green).font(.system(size: 18))
                        }
                        Spacer()
                    }
                    Text(coin.name).frame(width: 105, alignment: .leading).font(.system(size: 15)).foregroundStyle(.gray).lineLimit(1).truncationMode(.tail)
                }
                Spacer()
                GraphView().offset(x: -25)
                Spacer()
                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 75, height: 32.5)
                    .foregroundStyle(coin.price_change_day > 0 ? .green : .red)
                    .overlay {
                        Text("\(coin.price_change_day > 0 ? "+" : "")\(String(format: "%.2f", coin.price_change_day))%")
                            .font(.subheadline)
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                    }
            }
            Divider().overlay(.gray).opacity(0.3).padding(.top, 12)
        }
        .padding(.horizontal).padding(.top)
        .contentShape(Rectangle())
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendString)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .contextMenu {
            Button {
                sendString = "$\(coin.symbol.uppercased())"
                showForward = true
            } label: {
                Label("Share", systemImage: "paperplane")
            }
            Button {
                copied(coin.symbol.uppercased())
                UIPasteboard.general.string = "$\(coin.symbol.uppercased())"
            } label: {
                Label("Copy asset symbol", systemImage: "link")
            }
        } preview: {
            previewCoin().frame(width: widthOrHeight(width: true) * 0.8)
        }
    }
    @ViewBuilder
    func previewCoin() -> some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(coin.symbol.uppercased()).font(.subheadline).padding(.top, 8)
                
                if !coin.name.isEmpty {
                    Text(coin.name).font(.largeTitle.bold())
                }
                
                Text(coin.current_price.convertToCurrency(num: coin.current_price)).font(.largeTitle.bold())
                
                VStack {
                    VStack(alignment: .leading, spacing: 6) {
                        let stat = StockMarketStatus()
                        HStack(spacing: 3){
                            Image(systemName: "triangle.fill").font(.subheadline).scaleEffect(0.8).foregroundStyle(coin.price_change_day >= 0 ? .green : .red).rotationEffect(.degrees(coin.price_change_day >= 0 ? 0 : 180))
                            Text("\(abs(coin.price_change_day_dollar).convertToCurrency(num: coin.price_change_day_dollar)) (\(String(format: "%.2f", coin.price_change_day))%)").font(.subheadline).foregroundStyle(coin.price_change_day >= 0 ? .green : .red)
                            
                            if coin.isCrypto {
                                Text("Today").font(.subheadline)
                            } else {
                                if stat <= 0 {
                                    if isMonday() {
                                        Text("Last Friday").font(.subheadline)
                                    } else {
                                        Text("Yesterday").font(.subheadline)
                                    }
                                } else if stat == 1 {
                                    if coin.enoughPreMarketData {
                                        Text("Pre-Market").font(.subheadline)
                                    } else {
                                        if isMonday() {
                                            Text("Last Friday").font(.subheadline)
                                        } else {
                                            Text("Yesterday").font(.subheadline)
                                        }
                                    }
                                } else {
                                    Text("Today").font(.subheadline)
                                }
                            }
                            Spacer()
                        }
                        if !coin.isCrypto {
                            HStack(spacing: 3){
                                if let message = coin.afterHourMessage, stat >= 3 || stat <= 0 || (stat == 1 && !coin.enoughPreMarketData){
                                    Image(systemName: "triangle.fill").font(.subheadline).scaleEffect(0.8).foregroundStyle(message.0 >= 0 ? .green : .red).rotationEffect(.degrees(message.0 >= 0 ? 0 : 180))
                                    Text("\(abs(message.0).convertToCurrency(num: message.0)) (\(String(format: "%.2f", message.1))%)").font(.subheadline).foregroundStyle(message.1 >= 0 ? .green : .red)
                                    Text("After-Hours").font(.subheadline)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(.leading).padding(.top, 5)
            .frame(maxWidth: .infinity,alignment: .leading)
            
            GraphViewPreview(coin: coin).padding(.bottom, 8).padding(.top, 4)
        }
    }
    @ViewBuilder
    func GraphView()->some View {
        let prices = coin.day_prices.map { $0.0 }
        let final = prices.count < 50 ? prices : prices.enumerated().compactMap { (index, element) in
            return index % 4 == 0 ? element : nil
        }
        LineChartView(dataPoints: final, profit: coin.price_change_day > 0, isCrypto: coin.isCrypto, enough: coin.enoughPreMarketData).frame(width: widthGraph(count: final.count), height: 55)
    }
    @ViewBuilder
    func GraphViewPreview(coin: CryptoModel) -> some View {
        let prices = coin.day_prices.map { $0.0 }
        let final = prices.count < 50 ? prices : prices.enumerated().compactMap { (index, element) in
            return index % 2 == 0 ? element : nil
        }
        LineChartView(dataPoints: final, profit: coin.price_change_day > 0, isCrypto: coin.isCrypto, enough: coin.enoughPreMarketData).frame(width: getGraphWidth(), height: widthOrHeight(width: true) * 0.8)
    }
    func getGraphWidth() -> CGFloat {
        let fullSize = widthOrHeight(width: true) * 0.6
        if isHoliday { return fullSize }
        if coin.isCrypto {
            let currentDate = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: currentDate)
            let totalSecondsInADay: Double = 24 * 60 * 60
            let currentSeconds = Double(components.hour! * 3600 + components.minute! * 60 + components.second!)
            let percentageOfDay = currentSeconds / totalSecondsInADay
            return (percentageOfDay * fullSize)
        } else {
            let status = StockMarketStatus()
            if status >= 1 && status <= 3 {
                if status == 1 {
                    if !coin.enoughPreMarketData {
                        return fullSize
                    } else {
                        let untilDone = MinutesUntilFinish(whichZone: 1)
                        let elapsedRatio = (330.0 - Double(untilDone)) / 330.0
                        let preMarketWidth = elapsedRatio * (0.3 * fullSize)
                        return preMarketWidth
                    }
                } else if status == 2 {
                    let untilDone = MinutesUntilFinish(whichZone: 2)
                    let elapsedRatio = (390.0 - Double(untilDone)) / 390.0
                    let toAdd = (0.3 * fullSize)
                    let normalHoursWidth = elapsedRatio * (0.45 * fullSize)
                    return (normalHoursWidth + toAdd)
                } else {
                    let untilDone = MinutesUntilFinish(whichZone: 3)
                    let elapsedRatio = (240.0 - Double(untilDone)) / 240.0
                    let toAdd = (0.725 * fullSize)
                    let afterHoursWidth = elapsedRatio * (0.275 * fullSize)
                    return (afterHoursWidth + toAdd)
                }
            } else {
                return fullSize
            }
        }
    }
    func widthGraph(count: Int) -> CGFloat {
        let ratio = Double(count) / 100.0
        let min = 8.0
        let max = 110.0
        if (ratio * 110.0) > max {
            return max
        } else if (ratio * 110.0) < min {
            return min
        } else {
            return ratio * 110.0
        }
    }
}

struct LineChartView: View {
    @EnvironmentObject var viewModel: StockViewModel
    let dataPoints: [Double]
    let profit: Bool
    let isCrypto: Bool
    let enough: Bool
    @State var show = false
    
    var body: some View {
        GeometryReader { geometry in
            let minY = dataPoints.min() ?? 0
            let maxY = dataPoints.max() ?? 1
            ZStack {
                Path { path in
                    for (index, dataPoint) in dataPoints.enumerated() {
                        let x = CGFloat(index) * (geometry.size.width / CGFloat(dataPoints.count - 1))
                        let y = geometry.size.height - (CGFloat((dataPoint - minY) / (maxY - minY)) * geometry.size.height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }.stroke(profit ? Color.green : Color.red, lineWidth: 1)
                if show {
                    let stat = StockMarketStatus()
                    if let last = dataPoints.last, (stat >= 1 && stat <= 3 && !viewModel.holiday.0 && ((stat == 1 && enough) || stat != 1)) || isCrypto {
                        let x = CGFloat(dataPoints.count - 1) * (geometry.size.width / CGFloat(dataPoints.count - 1))
                        let y = geometry.size.height - (CGFloat((last - minY) / (maxY - minY)) * geometry.size.height)
                        PulsingView(size1: 4, size2: 40, green: profit).position(x: x, y: y)
                    }
                }
            }
        }
        .onAppear {
            self.show = true
        }
        .onDisappear {
            self.show = false
        }
    }
}

struct PulsingView: View {
    @State var animate = false
    let size1: CGFloat
    let size2: CGFloat
    let green: Bool
    var body: some View {
        ZStack {
            Circle()
                .fill(green ? Color.green.opacity(0.65) : Color.red.opacity(0.65))
                .frame(width: size2, height: size2)
                .scaleEffect(self.animate ? 1 : 0)
                .opacity(animate ? 0 : 1)
            
            Circle()
                .fill(green ? Color.green : Color.red)
                .frame(width: size1, height: size1)
        }
        .onAppear {
            self.animate = true
        }
        .onDisappear {
            self.animate = false
        }
        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: animate)
    }
}
