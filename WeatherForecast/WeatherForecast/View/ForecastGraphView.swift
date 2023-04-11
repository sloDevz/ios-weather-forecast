//
//  ForecastGraphView.swift
//  WeatherForecast
//
//  Created by DONGWOOK SEO on 2023/04/11.
//

import UIKit

class ForecastGraphView: UIView {
    private var forecastDatas: [ForecastData] = []

    func updateForecastDatas(with data: [ForecastData]) {
        forecastDatas = data
    }
}
