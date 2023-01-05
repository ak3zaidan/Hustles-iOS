import SwiftUI

struct CaptchaView: View {
    @StateObject var model = CaptchaModel()
    @Environment(\.colorScheme) var colorScheme
    @State var offsetArr: [CGSize] = [CGSize.zero, CGSize.zero, CGSize.zero, CGSize.zero, CGSize.zero, CGSize.zero, CGSize.zero]
    @State var rotationArr: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    @State var myString = ""
    @State var badInput = false
    @Binding var success: Bool?
    var body: some View {
        ZStack(alignment: .center){
            Color.gray.opacity(0.001)
                .onTapGesture {
                    success = false
                }
            ZStack {
                RoundedRectangle(cornerRadius: 10).foregroundColor(Color(UIColor.darkGray))
                VStack {
                    HStack(spacing: 20){
                        ForEach(0..<7, id: \.self) { index in
                            Text(String(model.currentCaptcha[model.currentCaptcha.index(model.currentCaptcha.startIndex, offsetBy: index)])).font(.title).foregroundColor(.white)
                                .offset(x: offsetArr[index].width, y: offsetArr[index].height)
                                .rotationEffect(.degrees(rotationArr[index]))
                                .blur(radius: 2)
                        }
                    }
                    Spacer()
                    HStack {
                        Text("Enter text:").font(.title2).foregroundColor(badInput ? .red : .white)
                        CaptchaField(text: $myString)
                    }
                    Spacer()
                    HStack {
                        Text("0/1 Correct").foregroundColor(.white).font(.system(size: 13))
                        Spacer()
                        Button {
                            model.generateNew()
                            myString = ""
                        } label: {
                            Text("Skip").foregroundColor(.white).padding(.horizontal, 15).padding(.vertical, 2).background(.ultraThinMaterial)
                        }
                    }
                }.padding(10).padding(.top, 25)
            }.frame(width: widthOrHeight(width: true) * 0.8, height: 230)
        }
        .onChange(of: myString, perform: { _ in
            if myString.count == 7 {
                if myString == model.currentCaptcha {
                    myString = ""
                    model.generateNew()
                    success = true
                } else {
                    badInput = true
                }
            }
            if myString.count < 7 {
                badInput = false
            } else if myString.count > 7 {
                badInput = true
            }
        })
        .onAppear {
            withAnimation{
                rotationArr = rotationArr.map { _ in
                   Double.random(in: -60...60)
                }
                offsetArr = offsetArr.map { _ in
                   CGSize(width: CGFloat.random(in: 0...20), height: CGFloat.random(in: 0...20))
                }
                offsetArr = offsetArr.map { _ in
                   CGSize(width: CGFloat.random(in: -20...0), height: CGFloat.random(in: -20...0))
                }
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { _ in
                withAnimation{
                    rotationArr = rotationArr.map { _ in
                       Double.random(in: -60...60)
                    }
                    offsetArr = offsetArr.map { _ in
                       CGSize(width: CGFloat.random(in: 0...20), height: CGFloat.random(in: 0...20))
                    }
                    offsetArr = offsetArr.map { _ in
                       CGSize(width: CGFloat.random(in: -20...0), height: CGFloat.random(in: -20...0))
                    }
                }
            }
        }
    }
}

class CaptchaModel: ObservableObject {
    @Published var currentCaptcha: String = ""
    
    init(){
        generateNew()
    }
    
    func generateNew(){
        let lettersAndNumbers = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKMNOPQRSTUVWXYZ0123456789"
        let temp = (0..<6).map { _ in
            lettersAndNumbers.randomElement()!
        }
        self.currentCaptcha = "R" + String(temp)
    }
}

struct CaptchaField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    var body: some View {
        HStack{
            ZStack {
                if text.isEmpty {
                    Text("Caps sensitive").font(.subheadline).foregroundColor(.white)
                }
                TextField("", text: $text)
                    .tint(.white)
                    .padding(.leading, 7)
                    .padding(.vertical, 4)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: isFocused ? 2 : 1))
    }
}
