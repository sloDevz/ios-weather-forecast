//
//  Forecast.swift
//  WeatherForecast
//
//  Created by DONGWOOK SEO on 2023/03/13.
//

import Foundation

struct Forecast: Decodable {
    let numberOfDays: Int
    let forecastData: [ForecastData]
    let city: City

    enum CodingKeys: String, CodingKey {
        case numberOfDays = "cnt"
        case forecastData = "list"
        case city
    }
}
