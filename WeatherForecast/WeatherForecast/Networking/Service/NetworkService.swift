//
//  NetworkService.swift
//  WeatherForecast
//
//  Created by Mason Kim on 2023/03/20.
//

import Foundation

final class NetworkService {

    func performRequest(with urlRequest: URLRequest?) async throws -> Data {
        guard let urlRequest else {
            log(.network, error: NetworkError.invalidURL)
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            log(.network, error: NetworkError.response)
            throw NetworkError.response
        }

        return data
    }

}
