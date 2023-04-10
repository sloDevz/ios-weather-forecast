//
//  OpenWeatherAPIEndpoints.swift
//  WeatherForecast
//
//  Created by Mason Kim on 2023/04/10.
//

import Foundation

enum OpenWeatherAPIEndpoints {
    case weather(coordinate: Coordinate)
    case forecast(coordinate: Coordinate)
    case iconImage(id: String)
}

extension OpenWeatherAPIEndpoints {
    var endpoint: Endpoint {
        switch self {
        case .weather(let coordinate):
            return Endpoint(baseURL: "https://api.openweathermap.org",
                            path: "/data/2.5/weather",
                            queryItems: generateQueryItems(coordinate: coordinate))
        case .forecast(let coordinate):
            return Endpoint(baseURL: "https://api.openweathermap.org",
                            path: "/data/2.5/forecast",
                            queryItems: generateQueryItems(coordinate: coordinate))
        case .iconImage(let id):
            return Endpoint(baseURL: "https://openweathermap.org",
                            path: "/img/wn/\(id)@2x.png")
        }
    }

    var urlRequest: URLRequest? {
        var urlComponents = URLComponents(string: endpoint.baseURL)

        urlComponents?.path = endpoint.path
        urlComponents?.queryItems = endpoint.queryItems

        guard let url = urlComponents?.url else { return nil }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod.rawValue

        return urlRequest
    }

    enum QueryConstant {
        static let latitudeQueryName = "lat"
        static let longitudeQueryName = "lon"
        static let appIdQueryName = "appid"
        static let languageQueryName = "lang"
        static let koreanLanguageQueryValue = "kr"
        static let unitsQueryName = "units"
        static let celsiusUnitsQueryValue = "metric"
    }

    private func generateQueryItems(coordinate: Coordinate) -> [URLQueryItem] {
        return [
            QueryConstant.latitudeQueryName: "\(coordinate.latitude)",
            QueryConstant.longitudeQueryName: "\(coordinate.longitude)",
            QueryConstant.appIdQueryName: Bundle.main.apiKey,
            QueryConstant.languageQueryName: QueryConstant.koreanLanguageQueryValue,
            QueryConstant.unitsQueryName: QueryConstant.celsiusUnitsQueryValue
        ].map {
            URLQueryItem(name: $0, value: $1)
        }
    }

}
