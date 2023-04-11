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
        static let numberOfPresentingData = 8

        static let horizontalMargin: CGFloat = 20
        static let topMargin: CGFloat = 10
        static let bottomMargin: CGFloat = 10

        static let circleDotDiameter: CGFloat = 8
        static let gridStandard: CGFloat = 10
    }

    // MARK: - Properties

    private var forecastDatas: [ForecastData] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    override var isHidden: Bool {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Draw

    override func draw(_ rect: CGRect) {
//        let humidities = forecastDatas.map { Double($0.weatherDetail.humidity) }
//        drawGraphLines(rect, of: humidities, color: .white)

//        let minimumTemperatures = forecastDatas.map { $0.weatherDetail.minimumTemperature }
//        drawGraphLines(rect, of: minimumTemperatures, color: .blue)
//
        let maximumTemperatures = forecastDatas.map { $0.weatherDetail.maximumTemperature }
        print(">>> maximumTemperatures", maximumTemperatures)
        drawGraphLines(rect, of: maximumTemperatures, color: .red.withAlphaComponent(0.5))
    }

    // MARK: - Public

    func updateForecastDatas(with data: [ForecastData]) {
        guard data.count >= Constants.numberOfPresentingData else { return }
        forecastDatas = Array(data[0..<Constants.numberOfPresentingData])
    }

    // MARK: - Private

    private func drawGraphLines(_ rect: CGRect, of pointValues: [Double], color: UIColor) {
        color.setFill()
        color.setStroke()

        let graphPath = UIBezierPath()

        graphPath.lineWidth = 3

        guard let points = drawingPoints(of: pointValues, with: rect),
              let firstPoint = points.first else { return }

        // 처음 포인트는 이동
        graphPath.move(to: firstPoint)

        // 2번째 포인트부터 그림
        points.dropFirst().forEach { point in
            graphPath.addLine(to: point)
        }

        graphPath.stroke()

        drawCircleDots(of: points)

        drawGridLine(of: pointValues, with: rect)
    }

    private func drawingPoints(of pointValues: [Double], with rect: CGRect) -> [CGPoint]? {
        let width = bounds.width
        let height = bounds.height

        let graphWidth = width - (Constants.horizontalMargin * 2) //- 4
        // 특정 점의 X 좌표
        let columnXPoint = { (column: Int) -> CGFloat in
            // 점들 사이에 공간을 계산함
            let spacing = graphWidth / CGFloat(pointValues.count - 1)
            return CGFloat(column) * spacing + Constants.horizontalMargin //+ 2
        }

        let graphHeight = height - (Constants.topMargin + Constants.bottomMargin)

        let maxRange = maxRange(of: pointValues)
        let minRange = minRange(of: pointValues)

        print(">>> maxRange", maxRange)
        print(">>> minRange", minRange)

        // 특정 점의 Y 좌표
        let columnYPoint = { (column: Int) -> CGFloat in
            let graphPointValue = pointValues[column]
            print(">>> graphPointValue", graphPointValue)
            let yPoint = graphHeight * CGFloat(graphPointValue - minRange) / CGFloat(maxRange - minRange)
            print(">>> yPoint", yPoint)
            return graphHeight - yPoint + Constants.topMargin // + Constants.topBorder  // 아래가 0이고 커질수록 위로 올라가기에, - 로 뒤집어줌.
        }

        return (0..<pointValues.count).map { index in
            CGPoint(x: columnXPoint(index), y: columnYPoint(index))
        }
    }

    private func drawCircleDots(of points: [CGPoint]) {
        let circlePoints = points.map { point in
            CGPoint(
                x: point.x - Constants.circleDotDiameter / 2,
                y: point.y - Constants.circleDotDiameter / 2
            )
        }

        let circleRects = circlePoints.map { circlePoint in
            CGRect(origin: circlePoint,
                   size: CGSize(width: Constants.circleDotDiameter, height: Constants.circleDotDiameter))
        }

        let circles = circleRects.map { circleRect in
            UIBezierPath(ovalIn: circleRect)
        }

        circles.forEach { circle in
            circle.fill()
        }
    }

    private func drawGridLine(of pointValues: [Double], with rect: CGRect) {
        let width = bounds.width
        let height = bounds.height
        let graphHeight = height - (Constants.topMargin + Constants.bottomMargin)

        UIColor.gray.setFill()
        UIColor.gray.setStroke()

        let graphPath = UIBezierPath()
        graphPath.lineWidth = 1

        let maxRange = maxRange(of: pointValues)
        let minRange = minRange(of: pointValues)

        let numberOfGrid = Int((maxRange - minRange) / Constants.gridStandard + 1)

        let gridSplitValue = graphHeight / CGFloat(numberOfGrid)

        (0..<numberOfGrid).forEach { gridCount in
            let yPosition = gridSplitValue * CGFloat(gridCount) + Constants.topMargin
            graphPath.move(to: CGPoint(x: 0, y: yPosition))
            graphPath.addLine(to: CGPoint(x: width, y: yPosition))
        }

        graphPath.stroke()
    }

    private func minRange(of values: [Double]) -> Double {
        let minumumValue = values.min() ?? 0
        return (minumumValue / Constants.gridStandard).rounded() * Constants.gridStandard - Constants.gridStandard
    }

    private func maxRange(of values: [Double]) -> Double {
        let maxValue = values.max() ?? 0.0
        return (maxValue / Constants.gridStandard).rounded() * Constants.gridStandard + Constants.gridStandard
    }

}
