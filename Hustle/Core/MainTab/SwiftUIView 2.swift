import SwiftUI

struct SwiftUIView: View {
    @State var show = true
    var body: some View {
        if !show {
            Rectangle().fill(.red.gradient).frame(width: widthOrHeight(width: true) * 0.8, height: widthOrHeight(width: false)).transition(.moveOne)
                .onTapGesture {
                    show.toggle()
                }
        } else {
            Rectangle().fill(.blue.gradient).frame(width: widthOrHeight(width: true) * 0.8, height: widthOrHeight(width: false)).transition(.moveTwo)
                .onTapGesture {
                    show.toggle()
                }
        }
    }
}


struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
