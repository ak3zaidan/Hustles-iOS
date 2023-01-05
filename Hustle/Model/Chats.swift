import Foundation
import SwiftUI

struct Chats: Identifiable, Equatable {
    let id: String
    var chatText: String = ""
    var user: User
    var convo: Convo
    var lastM: Message?
    var messages: [Message]?
    var lastN: String?
    var color: Color = .randomLightColor
}
