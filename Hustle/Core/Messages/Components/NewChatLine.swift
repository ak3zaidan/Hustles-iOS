import SwiftUI

struct NewChatLine: View {
    var body: some View {
        HStack {
            Rectangle().frame(height: 1).overlay(Color.orange)
            Text("New Messages")
                .lineLimit(1).frame(width: 140)
                .font(.system(size: 17)).fontWeight(.semibold)
            Rectangle().frame(height: 1).overlay(Color.orange)
        }
        .padding(.horizontal, 5)
        .padding(.vertical)
    }
}
