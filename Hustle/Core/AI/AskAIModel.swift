import Foundation

enum Constants {
    static let openAIApiKey = "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"
}

struct ChatStreamCompletionResponse: Decodable {
    let id: String
    let choices: [ChatStreamChoice]
}

struct ChatStreamChoice: Decodable {
    let delta: ChatStreamContent
}

struct ChatStreamContent: Decodable {
    let content: String
}

struct MessageAI: Decodable, Hashable {
    let id: String
    let role: SenderRole
    let content: String
    let createAt: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct OpenAIChatBody: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
    let stream: Bool
}

struct OpenAIChatMessage: Codable {
    let role: SenderRole
    let content: String
}

enum SenderRole: String, Codable {
    case system
    case user
    case assistant
}

struct datesQ: Hashable {
    let place: Int
    let name: String
}

struct randomQ: Hashable {
    let one: String
    let two: String
}

struct AIStorage {
    let id: String
    let text1: String
    let text2: String
    let date: Date
    let hasImage: Bool
}

struct iterateMessages: Identifiable {
    let id: String
    let parentID: String
    var question: String
    var answer: String
    var date: Date
    var hasImage: Bool
}

struct AllMessages: Identifiable {
    let id: String
    var allM: [MessageRow]
}

struct AttributedOutput {
    let string: String
    let results: [ParserResult]
}

enum MessageRowType {
    case attributed(AttributedOutput)
    case rawText(String)
    
    var text: String {
        switch self {
        case .attributed(let attributedOutput):
            return attributedOutput.string
        case .rawText(let string):
            return string
        }
    }
}

struct MessageRow: Identifiable {
    let id = UUID()
    var isInteracting: Bool

    var send: MessageRowType
    var sendText: String {
        send.text
    }

    var response: MessageRowType?
    var responseText: String? {
        response?.text
    }
    var responseError: String?
}

enum ChatGPTModel: String, Identifiable, CaseIterable {
    var id: Self { self }
    case gpt3Turbo = "gpt-3.5-turbo"
    case gpt4 = "gpt-4"
    
    var text: String {
        switch self {
        case .gpt3Turbo:
            return "GPT-3.5"
        case .gpt4:
            return "GPT-4"
        }
    }
}

struct Message1: Codable {
    let role: String
    let content: String
}

extension Array where Element == Message1 {
    var contentCount: Int { reduce(0, { $0 + $1.content.count })}
}

struct Request: Codable {
    let model: String
    let temperature: Double
    let messages: [Message1]
    let stream: Bool
}

struct ErrorRootResponse: Decodable {
    let error: ErrorResponse
}

struct ErrorResponse: Decodable {
    let message: String
    let type: String?
}

struct StreamCompletionResponse: Decodable {
    let choices: [StreamChoice]
}

struct CompletionResponse: Decodable {
    let choices: [Choice]
    let usage: Usage?
}

struct Usage: Decodable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
}

struct Choice: Decodable {
    let message: Message1
    let finishReason: String?
}

struct StreamChoice: Decodable {
    let finishReason: String?
    let delta: StreamMessage
}

struct StreamMessage: Decodable {
    let role: String?
    let content: String?
}
