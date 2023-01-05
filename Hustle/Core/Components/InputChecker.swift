import Foundation

class inputChecker {
    private var sendBack: String = ""
    private var badWords = ["fuck", "bitch", "nigger", "nigga", "pussy", "asshole", "slut", "whore"]
    
    func myInputChecker(withString mystring: String, withLowerSize size: Int, withUpperSize sizebig: Int, needsLower: Bool) -> String {
        let checkString = mystring.trimmingCharacters(in: .whitespacesAndNewlines)
        sendBack = ""
        if checkString == "" && needsLower {
            sendBack = "Field cannot be empty"
        } else if badWords.contains(where: { checkString.lowercased().contains($0) }){
            sendBack = "Cannot contain profanity"
        } else {
            if checkString.count < size && needsLower {
                sendBack = "field is too short"
            }
            if checkString.count > sizebig{
                sendBack = "field is too long"
            }
        }
        return sendBack
    }
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    func getLink(videoLink: String) -> String {
        var link = ""
        if !videoLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if videoLink.contains("youtube") || videoLink.contains("youtu.be"){
                if let youtubeID = extractYouTubeID(from: videoLink) {
                    if videoLink.contains("shorts"){
                        link = "shorts/" + youtubeID
                    } else {
                        link = youtubeID
                    }
                }
            } else {
                link = videoLink
            }
        }
        return link
    }
    func extractYouTubeID(from url: String) -> String? {
        let pattern = "(?<=youtu.be/|watch\\?v=|/videos/|embed\\/|youtu.be\\/|\\/v\\/|\\/e\\/|\\/watch\\?v=|\\/embed\\/|\\/shorts\\/|\\/youtu.be\\/|\\/v\\/|watch\\?v=|embed\\/|youtu.be\\/|\\/v\\/|\\/e\\/|\\/watch\\?v=|\\/embed\\/|\\/shorts\\/|youtu.be\\/|\\/v\\/|watch\\?v=|embed\\/|youtu.be\\/|\\/v\\/|\\/e\\/|\\/watch\\?v=|\\/embed\\/|\\/shorts\\/|youtu.be\\/|\\/v\\/|watch\\?v=|embed\\/|youtu.be\\/|\\/v\\/|\\/e\\/|\\/watch\\?v=|\\/embed\\/|\\/shorts\\/|youtu.be\\/|\\/v\\/|watch\\?v=|embed\\/|youtu.be\\/|\\/v\\/|\\/e\\/|\\/watch\\?v=|\\/embed\\/|\\/shorts\\/)([\\w-]+)(?=&.*|\\?.*|\\/.*|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: url.count)
        
        guard let result = regex?.firstMatch(in: url, range: range) else {
            return nil
        }
        
        return (url as NSString).substring(with: result.range)
    }
}

