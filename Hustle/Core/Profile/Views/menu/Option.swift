import Foundation

struct Option: Identifiable, Hashable {
    let id = UUID().uuidString
    let option: String
}
extension Option {
    static let pawn: [Option] = [
        Option(option: "+100 upload a ✅HUSTLE"),
        Option(option: "+200 to complete a JOB"),
        Option(option: "+500 LeaderBoard Post")
    ]
    static let bishop: [Option] = [
        Option(option: "+75 to upload a ✅HUSTLE"),
        Option(option: "+150 to complete a JOB"),
        Option(option: "+250 LeaderBoard Post"),
        Option(option: "+10 accepted answer")
    ]
    static let knight: [Option] = [
        Option(option: "+50 to upload a ✅HUSTLE"),
        Option(option: "+100 to complete a JOB"),
        Option(option: "+75 to Upload a ✅Tip"),
        Option(option: "+10 accepted answer")
    ]
    static let rook: [Option] = [
        Option(option: "+25 to upload a ✅HUSTLE"),
        Option(option: "+50 to complete a JOB"),
        Option(option: "+300ELO per 10k likes"),
        Option(option: "+10 accepted answer")
    ]
    static let queen: [Option] = [
        Option(option: "+12 to upload a ✅HUSTLE"),
        Option(option: "+25 to complete a JOB"),
        Option(option: "+99 Popular News Opinion"),
        Option(option: "+10 accepted answer")
    ]
    static let king: [Option] = [
        Option(option: "+6 to upload a ✅HUSTLE"),
        Option(option: "+12 to complete a JOB"),
        Option(option: "+99 Suggest chosen News"),
        Option(option: "+10 accepted answer")
    ]
}
