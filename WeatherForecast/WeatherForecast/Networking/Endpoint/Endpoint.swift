//
//  Endpoint.swift
//  WeatherForecast
//
//  Created by Mason Kim on 2023/04/10.
//

import Foundation

struct Endpoint {
    let baseURL: String
    let path: String
    let queryItems: [URLQueryItem]?
    let httpMethod: HTTPMethodType

    init(baseURL: String,
         path: String,
         queryItems: [URLQueryItem]? = nil,
         httpMethod: HTTPMethodType = .get) {
        self.baseURL = baseURL
        self.path = path
        self.queryItems = queryItems
        self.httpMethod = httpMethod
    }
}
