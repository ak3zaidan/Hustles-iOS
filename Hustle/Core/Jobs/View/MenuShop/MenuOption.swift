import Foundation

struct MenuOption: Identifiable, Hashable {
    let id = UUID().uuidString
    let option: String
}

extension MenuOption {
    static let testAllMonths: [MenuOption] = [
        MenuOption(option: "Closest first"),
        MenuOption(option: "Newest first"),
        MenuOption(option: "Price: Low to High"),
        MenuOption(option: "Price: High to Low")
    ]
}


