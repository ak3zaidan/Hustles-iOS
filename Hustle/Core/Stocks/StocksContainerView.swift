import SwiftUI

func extractWordsStartingWithDollar(input: String) -> [String] {
    let words = input.components(separatedBy: .whitespacesAndNewlines)
    let filteredWords = words.filter { word in
        word.hasPrefix("$") && word.count >= 2 && word.count <= 8
    }
    let finalWords = filteredWords.map { word in
        String(word.dropFirst())
    }
    let final = Array(Set(finalWords))

    return Array(final.prefix(10))
}

struct StocksContainerView: View {
    let symbol: String
    @EnvironmentObject var appModel: StockViewModel
    @State var up: Bool? = nil
    
    var body: some View {
        VStack {
            if let coin = appModel.coinsSec.first(where: { $0.symbol == symbol }) {
                VStack {
                    HStack {
                        Text(coin.symbol.uppercased()).font(.title3).bold()
                        Text(coin.current_price.convertToCurrency(num: coin.current_price))
                            .font(.title.bold()).gradientForeground(colors: coin.price_change_day >= 0 ? [.green, .blue] : [.red, .orange])
                        Spacer()
                    }
                    stat()
                }
                GraphView(coin: coin)
                    .onAppear {
                        up = coin.price_change_day >= 0
                    }
            } else {
                VStack {
                    HStack {
                        Text(symbol.uppercased()).font(.title3).bold()
                        Text("$0.0")
                            .font(.title.bold()).foregroundStyle(.green)
                        Spacer()
                    }
                    HStack(spacing: 3){
                        Image(systemName: "triangle.fill").font(.subheadline).scaleEffect(0.8).foregroundStyle(.green)
                        Text("$0.0 (0.0%)").font(.subheadline).foregroundStyle(.green)
                        Text("Today").font(.subheadline)
                        Spacer()
                    }
                }
                let all: [Double] = [
                    100.0, 101.5, 102.3, 104.0, 103.2, 105.5, 104.7, 106.2, 107.1, 108.5,
                    107.8, 109.3, 110.2, 111.6, 112.3, 113.0, 112.5, 113.7, 115.2, 116.0,
                    114.8, 116.5, 118.0, 119.3, 120.0, 121.5, 120.8, 122.3, 123.6, 124.2,
                    125.0, 123.8, 122.5, 121.7, 120.3, 119.5, 118.0, 117.2, 118.5, 119.8,
                    120.5, 121.3, 122.0, 121.2, 122.6, 123.8, 124.5, 125.0, 126.3, 127.0,
                    125.5, 126.8, 127.5, 128.2, 129.0, 130.2, 131.0, 132.5,
                    131.8, 130.9, 130.3, 129.7, 129.2, 128.5, 129.1, 128.3, 127.5, 126.8,
                    126.0, 125.5, 124.8, 124.3, 123.9, 124.5, 124.0, 123.5, 123.0, 123.6,
                    124.2, 124.8, 125.5, 125.0, 124.5, 124.0, 123.5, 124.0, 124.5, 125.0,
                    125.5, 126.0, 125.5, 125.0, 124.5, 125.0, 125.5, 126.0, 126.5, 127.0,
                    127.5, 128.0, 128.5, 129.0, 128.5, 128.0, 127.5, 127.0, 126.5, 126.0,
                    125.5, 125.0, 124.5, 124.0, 123.5, 123.0, 122.5, 122.0, 122.5, 123.0,
                    123.5, 124.0, 124.5, 125.0, 125.5, 126.0, 126.5, 127.0, 127.5, 128.0,
                    128.5, 128.0, 127.5, 127.0, 126.5, 126.0, 125.5, 125.0, 124.5, 124.0,
                    123.5, 123.0, 123.5, 124.0, 124.5, 125.0, 125.5, 126.0, 126.5, 127.0,
                    126.5, 126.0, 125.5, 125.0, 124.5, 124.0, 123.5, 123.0, 122.5, 122.0,
                    121.5, 121.0, 121.5, 122.0, 122.5, 123.0, 123.5, 124.0, 124.5, 125.0,
                    125.5, 126.0, 125.5, 125.0, 124.5, 124.0, 123.5, 123.0, 122.5, 122.0,
                    121.5, 121.0, 120.5, 120.0, 120.5, 121.0, 121.5, 122.0, 122.5, 123.0,
                    123.5, 124.0, 124.5, 125.0, 125.5, 126.0, 126.5, 126.0, 125.5, 125.0,
                    124.5, 124.0, 123.5, 123.0, 122.5, 122.0, 121.5, 121.0, 120.5, 120.0,
                    119.5, 119.0, 119.5, 120.0, 120.5, 121.0, 121.5, 122.0, 122.5, 123.0,
                    123.5, 124.0, 124.5, 125.0, 125.5, 126.0, 126.5, 126.0, 125.5, 125.0,
                    124.5, 124.0, 123.5, 123.0, 122.5, 122.0, 121.5, 121.0, 120.5, 120.0,
                    119.5, 119.0, 118.5, 118.0, 118.5, 119.0, 119.5, 120.0, 120.5, 121.0,
                    121.5, 122.0, 122.5, 123.0, 123.5, 124.0, 124.5, 125.0, 125.5, 126.0,
                    126.5, 126.0, 125.5, 125.0, 124.5, 124.0, 123.5, 123.0, 122.5, 122.0,
                    121.5, 121.0, 120.5, 120.0, 119.5, 119.0, 118.5, 118.0, 117.5, 117.0,
                    116.5, 116.0, 116.5, 117.0, 117.5, 118.0, 118.5, 119.0, 119.5, 120.0,
                    120.5, 121.0, 121.5, 122.0, 122.5, 123.0]
                LineChartView(dataPoints: all, profit: true, isCrypto: false, enough: true).frame(width: widthGraph(count: all.count), height: 55)
            }
        }
        .padding(8)
        .background(up == nil ? Color.clear : (up ?? false) == false ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        .background(.ultraThickMaterial)
        .overlay(content: {
            RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1)
        })
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onAppear {
            appModel.getIndexSec(symbol: symbol)
        }
        .overlay(alignment: .topTrailing){
            if appModel.coinsSec.first(where: { $0.symbol == symbol }) == nil {
                ProgressView().padding(12)
            }
        }
    }
    @ViewBuilder
    func GraphView(coin: CryptoModel) -> some View {
        let prices = coin.day_prices.map { $0.0 }
        let final = prices.count < 50 ? prices : prices.enumerated().compactMap { (index, element) in
            return index % 4 == 0 ? element : nil
        }
        LineChartView(dataPoints: final, profit: coin.price_change_day > 0, isCrypto: coin.isCrypto, enough: coin.enoughPreMarketData).frame(width: widthGraph(count: final.count), height: 55)
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
    func stat() -> some View {
        HStack(spacing: 3){
            let stat = StockMarketStatus()
            if let index = appModel.coinsSec.firstIndex(where: { $0.symbol == symbol }) {
                Image(systemName: "triangle.fill").font(.subheadline).scaleEffect(0.8).foregroundStyle(appModel.coinsSec[index].price_change_day >= 0 ? .green : .red).rotationEffect(.degrees(appModel.coinsSec[index].price_change_day >= 0 ? 0 : 180))
                Text("\(abs(appModel.coinsSec[index].price_change_day_dollar).convertToCurrency(num: appModel.coinsSec[index].price_change_day_dollar)) (\(String(format: "%.2f", appModel.coinsSec[index].price_change_day))%)").font(.subheadline).foregroundStyle(appModel.coinsSec[index].price_change_day >= 0 ? .green : .red)
                
                if stat <= 0 {
                    if isMonday() {
                        Text("Last Friday").font(.subheadline)
                    } else {
                        Text("Yesterday").font(.subheadline)
                    }
                } else if stat == 1 {
                    if appModel.coinsSec[index].enoughPreMarketData {
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
    }
}
