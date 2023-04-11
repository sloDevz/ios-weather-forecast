//
//  ForecastGraphView.swift
//  WeatherForecast
//
//  Created by DONGWOOK SEO on 2023/04/11.
//

import UIKit

class ForecastGraphView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let margin: CGFloat = 20.0
        static let topBorder: CGFloat = 60
        static let bottomBorder: CGFloat = 50
    }

    // MARK: - Properties

    private var forecastDatas: [ForecastData] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - Draw

    override func draw(_ rect: CGRect) {
        let humidities = forecastDatas.map { Double($0.weatherDetail.humidity) }
        drawGraphLines(rect, of: humidities, color: .white)

        let minimumTemperatures = forecastDatas.map { $0.weatherDetail.minimumTemperature }
        drawGraphLines(rect, of: minimumTemperatures, color: .blue)

        let maximumTemperatures = forecastDatas.map { $0.weatherDetail.maximumTemperature }
        drawGraphLines(rect, of: maximumTemperatures, color: .red.withAlphaComponent(0.5))
    }

    // MARK: - Public

    func updateForecastDatas(with data: [ForecastData]) {
        forecastDatas = data
    }

    // MARK: - Private

    private func drawGraphLines(_ rect: CGRect, of graphPoints: [Double], color: UIColor) {
        color.setFill()
        color.setStroke()

        let graphPath = UIBezierPath()

        graphPath.lineWidth = 5

        guard let points = drawingPoints(of: graphPoints, with: rect),
              let firstPoint = points.first else { return }

        // 처음 포인트는 이동
        graphPath.move(to: firstPoint)

        // 2번째 포인트부터 그림
        points.dropFirst().forEach { point in
            graphPath.addLine(to: point)
        }

        graphPath.stroke()
    }

    private func drawingPoints(of graphPoints: [Double], with rect: CGRect) -> [CGPoint]? {
        let width = rect.width
        let height = rect.height

        let graphWidth = width - (Constants.margin * 2) - 4
        // 특정 점의 X 좌표
        let columnXPoint = { (column: Int) -> CGFloat in
            // 점들 사이에 공간을 계산함
            let spacing = graphWidth / CGFloat(graphPoints.count - 1)
            return CGFloat(column) * spacing + Constants.margin + 2
        }

        let graphHeight = height - Constants.topBorder - Constants.bottomBorder
        guard let maxValue = graphPoints.max() else { return nil }  // 최대값의 y지점을 가장 상단으로 놓기 위해 (그래프 최고치의 기준점)

        // 특정 점의 Y 좌표
        let columnYPoint = { (column: Int) -> CGFloat in
            let graphPointValue = graphPoints[column]
            let yPoint = CGFloat(graphPointValue) / CGFloat(maxValue) * graphHeight
            return graphHeight + Constants.topBorder - yPoint // 아래가 0이고 커질수록 위로 올라가기에, - 로 뒤집어줌.
        }

        return (0..<graphPoints.count).map { index in
            CGPoint(x: columnXPoint(index), y: columnYPoint(index))
        }
    }

}
