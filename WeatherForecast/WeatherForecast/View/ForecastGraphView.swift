//
//  ForecastGraphView.swift
//  WeatherForecast
//
//  Created by DONGWOOK SEO on 2023/04/11.
//

import UIKit

final class ForecastGraphView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let numberOfPresentingData = 8

        static let horizontalMargin: CGFloat = 20
        static let topMargin: CGFloat = 10
        static let bottomMargin: CGFloat = 10

        static let circleDotDiameter: CGFloat = 8
        static let gridStandard: CGFloat = 5
    }

    private enum Mode {
        case temperature
        case humidity

        var color: UIColor {
            switch self {
            case .temperature:
                return .gray
            case .humidity:
                return .white
            }
        }

        var prefixText: String {
            switch self {
            case .temperature:
                return "℃"
            case .humidity:
                return "%"
            }
        }
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
        resetTemperatureLabels()

        let humidities = forecastDatas.map { Double($0.weatherDetail.humidity) }
        let minimumTemperatures = forecastDatas.map { $0.weatherDetail.minimumTemperature }
        let maximumTemperatures = forecastDatas.map { $0.weatherDetail.maximumTemperature }

        drawGridLine(of: humidities, with: rect, mode: .humidity)
        drawGridLine(of: minimumTemperatures, with: rect, mode: .temperature)
        drawGridLine(of: maximumTemperatures, with: rect, mode: .temperature)

        drawGraphLines(of: humidities, with: rect, color: .white, mode: .humidity)
        drawGraphLines(of: minimumTemperatures, with: rect, color: .blue, mode: .temperature)
        drawGraphLines(of: maximumTemperatures, with: rect, color: .red.withAlphaComponent(0.5), mode: .temperature)

        drawTemperatureLabels(of: humidities, with: rect, color: .white, mode: .humidity)
        drawTemperatureLabels(of: minimumTemperatures, with: rect, color: .blue, mode: .temperature)
        drawTemperatureLabels(of: maximumTemperatures, with: rect, color: .red, mode: .temperature)
        print(">>> humidities", humidities)
        print(">>> maximumTemperatures", maximumTemperatures)

        drawBackGroundLineForDebug()
    }

    // MARK: - Public

    func updateForecastDatas(with data: [ForecastData]) {
        guard data.count >= Constants.numberOfPresentingData else { return }
        forecastDatas = Array(data[0..<Constants.numberOfPresentingData])
    }

    // MARK: - Private

    private func resetTemperatureLabels() {
        subviews.forEach { view in
            view.removeFromSuperview()
        }
    }

    private func drawTemperatureLabels(of pointValues: [Double], with rect: CGRect, color: UIColor, mode: Mode) {
        guard let points = drawingPoints(of: pointValues, with: rect, mode: mode) else { return }

        zip(pointValues, points).forEach { (value, point) in
            let originPoint = CGPoint(x: point.x - 20, y: point.y)
            let label = UILabel(frame: CGRect(origin: originPoint, size: CGSize(width: 80, height: 30)))
            addSubview(label)
            label.textColor = mode.color
            label.font = .preferredFont(forTextStyle: .caption1)
            label.text = "\(value)\(mode.prefixText)"
        }
    }

    private func drawGraphLines(of pointValues: [Double], with rect: CGRect, color: UIColor, mode: Mode) {

        color.setFill()
        color.setStroke()

        let graphPath = UIBezierPath()

        graphPath.lineWidth = 3

        guard let points = drawingPoints(of: pointValues, with: rect, mode: mode),
              let firstPoint = points.first else { return }

        // 처음 포인트는 이동
        graphPath.move(to: firstPoint)

        // 2번째 포인트부터 그림
        points.dropFirst().forEach { point in
            graphPath.addLine(to: point)
        }

        graphPath.stroke()

        drawCircleDots(of: points)
    }

    private func drawingPoints(of pointValues: [Double], with rect: CGRect, mode: Mode) -> [CGPoint]? {
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

        let maxRange = maxRange(of: pointValues, mode: mode)
        let minRange = minRange(of: pointValues, mode: mode)

        // 특정 점의 Y 좌표
        let columnYPoint = { (column: Int) -> CGFloat in
            let graphPointValue = pointValues[column]
            let yPoint = graphHeight * CGFloat(graphPointValue - minRange) / CGFloat(maxRange - minRange)
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

    private func drawGridLine(of pointValues: [Double], with rect: CGRect, mode: Mode) {
        let width = bounds.width
        let height = bounds.height
        let graphHeight = height - (Constants.topMargin + Constants.bottomMargin)

        mode.color.setFill()
        mode.color.setStroke()

        let graphPath = UIBezierPath()
        graphPath.lineWidth = 1

        let maxRange = maxRange(of: pointValues, mode: mode)
        let minRange = minRange(of: pointValues, mode: mode)

        let numberOfGrid = mode == .humidity ? 5 : Int((maxRange - minRange) / Constants.gridStandard)

        let gridSplitValue = graphHeight / CGFloat(numberOfGrid)

        (0..<numberOfGrid).forEach { gridCount in
            let yPosition = gridSplitValue * CGFloat(gridCount) + Constants.topMargin
            graphPath.move(to: CGPoint(x: 0, y: yPosition))
            graphPath.addLine(to: CGPoint(x: width, y: yPosition))
        }

        graphPath.stroke()
    }

    private func minRange(of values: [Double], mode: Mode) -> Double {
        if mode == .humidity {
            return 0
        }
        let minumumValue = values.min() ?? 0
        return (minumumValue / Constants.gridStandard).rounded() * Constants.gridStandard - Constants.gridStandard
    }

    private func maxRange(of values: [Double], mode: Mode) -> Double {
        if mode == .humidity {
            return 100
        }
        let maxValue = values.max() ?? 0.0
        return (maxValue / Constants.gridStandard).rounded() * Constants.gridStandard + Constants.gridStandard
    }


    private func drawBackGroundLineForDebug() {
        UIColor.black.setFill()
        UIColor.black.setStroke()

        let graphPath = UIBezierPath()

        let width = bounds.width
        let height = bounds.height
        graphPath.lineWidth = 2
        graphPath.move(to: CGPoint(x: Constants.horizontalMargin, y: Constants.topMargin))
        graphPath.addLine(to: CGPoint(x: width - Constants.horizontalMargin, y: Constants.topMargin))
        graphPath.addLine(to: CGPoint(x: width - Constants.horizontalMargin, y: height - Constants.bottomMargin))
        graphPath.addLine(to: CGPoint(x: Constants.horizontalMargin, y: height - Constants.bottomMargin))
        graphPath.addLine(to: CGPoint(x: Constants.horizontalMargin, y: Constants.topMargin))
        graphPath.stroke()
    }
}
