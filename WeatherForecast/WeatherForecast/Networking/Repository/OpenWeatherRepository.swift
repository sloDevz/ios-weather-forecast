//
//  OpenWeatherRepository.swift
//  WeatherForecast
//
//  Created by DONGWOOK SEO on 2023/03/14.
//

import UIKit

final class OpenWeatherRepository {
    
    //MARK: - Property
    
    private let deserializer: Deserializerable
    private let service: NetworkService
    
    //MARK: - LifeCycle

    init(
        deserializer: Deserializerable,
        service: NetworkService
    ) {
        self.deserializer = deserializer
        self.service = service
    }

    // MARK: - Public

    func fetchData<T: Decodable>(type: T.Type,
                                 endpoint: OpenWeatherAPIEndpoints) async throws -> T {
        guard let urlRequest = endpoint.urlRequest else { throw NetworkError.invalidURL }

        let data = try await service.performRequest(with: urlRequest)
        let decodedData = try self.deserializer.deserialize(T.self, data: data)
        return decodedData
    }


    func fetchWeatherIconImage(withID iconID: String) async throws -> UIImage {
        let urlRequest = OpenWeatherAPIEndpoints.iconImage(id: iconID).urlRequest

        if let iconImage = ImageCacheManager.shared.get(for: iconID) {
            return iconImage
        }

        let data = try await service.performRequest(with: urlRequest)
        guard let icon = UIImage(data: data) else {
            throw NetworkError.invalidImage
        }
        ImageCacheManager.shared.store(icon, for: iconID)
        return icon
    }
}
