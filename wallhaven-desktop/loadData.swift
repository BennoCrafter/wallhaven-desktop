import SwiftUI

func loadDataFromURL(url: URL, completion: @escaping ([Wallpaper]?, Error?) -> Void) {
    // Create a URLSession data task to load data
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        // Handle errors
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let data = data else {
            completion(nil, NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data found"]))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let cobbles = try decoder.decode([Wallpaper].self, from: data)
            completion(cobbles, nil)
        } catch let decodingError {
            completion(nil, decodingError)
        }
    }
    
    task.resume()
}
