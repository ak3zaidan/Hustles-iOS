import Foundation

class CallViewModel: ObservableObject {
    func getTokenFromServer(uid: Int, channel: String, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = "https://hustles-3e34a4a2709c.herokuapp.com/process_data?x=\(uid)&y=\(channel)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        let request = URLRequest(url: url)
        let session = URLSession.shared

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
                return
            }

            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let token = json["token"] as? String {
                completion(.success(token))
            } else {
                completion(.failure(NSError(domain: "Invalid response data", code: 0, userInfo: nil)))
            }
        }
        task.resume()
    }
}
