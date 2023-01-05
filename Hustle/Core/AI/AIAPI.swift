import Foundation
import Alamofire

class ChatGPTAPI {
    private let endpointUrl = "https://api.openai.com/v1/chat/completions"
    private var currentStreamRequest: DataStreamRequest?
    
    func parseStreamData(_ data: String) -> [ChatStreamCompletionResponse] {
        let responseStrings = data.split(separator: "data:").map({$0.trimmingCharacters(in: .whitespacesAndNewlines)}).filter({!$0.isEmpty})
        let jsonDecoder = JSONDecoder()
        
        return responseStrings.compactMap { jsonString in
            guard let jsonData = jsonString.data(using: .utf8), let streamResponse = try? jsonDecoder.decode(ChatStreamCompletionResponse.self, from: jsonData) else {
                return nil
            }
            return streamResponse
        }
    }

    func sendStreamMessage(messages: [MessageAI]) -> DataStreamRequest {
        let openAIMessages = messages.map({OpenAIChatMessage(role: $0.role, content: $0.content)})
        let body = OpenAIChatBody(model: "gpt-3.5-turbo", messages: openAIMessages, stream: true)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIApiKey)"
        ]

        let streamRequest = AF.streamRequest(endpointUrl, method: .post, parameters: body, encoder: .json, headers: headers)
        currentStreamRequest = streamRequest
        return streamRequest
    }
    
    func sendNormalMessage(messages: [MessageAI], completion: @escaping (Result<String, Error>) -> Void) {
        let openAIMessages = messages.map { OpenAIChatMessage(role: $0.role, content: $0.content) }
        let body = OpenAIChatBody(model: "gpt-3.5-turbo", messages: openAIMessages, stream: false)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIApiKey)"
        ]
        
        AF.request(endpointUrl, method: .post, parameters: body, encoder: .json, headers: headers).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                    if let content = chatResponse.choices.first?.message.content {
                        completion(.success(content))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content found in response"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func cancelStream(){
        currentStreamRequest?.cancel()
        currentStreamRequest = nil
    }
}

struct ChatResponse: Decodable {
    let choices: [ChoiceAI]
}

struct ChoiceAI: Decodable {
    let message: MesAI
}

struct MesAI: Decodable {
    let content: String
}
