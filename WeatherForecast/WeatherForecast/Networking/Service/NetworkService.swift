//
//  NetworkService.swift
//  WeatherForecast
//
//  Created by Mason Kim on 2023/03/20.
//

import Foundation

final class NetworkService {

    func performRequest(with url: URL?, httpMethodType: HTTPMethodType) async throws -> Data {
        guard let url else {
            log(.network, error: NetworkError.invalidURL)
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethodType.rawValue

        URLSession.shared.dataTask(with: urlRequest)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            log(.network, error: NetworkError.response)
            throw NetworkError.response
        }

        return data
    }

//    func performRequest(with url: URL?,
//                        httpMethodType: HTTPMethodType,
//                        completion: @escaping (Result<Data, NetworkError>) -> Void) {
//        guard let url else {
//            completion(.failure(.invalidURL))
//            log(.network, error: NetworkError.invalidURL)
//            return
//        }
//
//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = httpMethodType.rawValue
//
//        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
//            guard error == nil else {
//                completion(.failure(.networking))
//                log(.network, error: NetworkError.networking)
//                return
//            }
//
//            guard let httpResponse = response as? HTTPURLResponse,
//                  (200...299).contains(httpResponse.statusCode) else {
//                completion(.failure(.response))
//                log(.network, error: NetworkError.response)
//                return
//            }
//
//            guard let data else {
//                completion(.failure(.invalidData))
//                log(.network, error: NetworkError.invalidData)
//                return
//            }
//
//            completion(.success(data))
//        }
//        task.resume()
//    }
}
