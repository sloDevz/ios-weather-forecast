//
//  DateFormatUtil.swift
//  WeatherForecast
//
//  Created by Mason Kim on 2023/04/03.
//

import Foundation

enum DateFormatUtil {
    
    // MARK: - Properties

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd(EEE) HH시"
        return formatter
    }()
    
    // MARK: - Public
    
    static func format(with timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))

        let formattedDate = dateFormatter.string(from: date)
        return formattedDate
    }

}
