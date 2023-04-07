//
//  WeatherHeaderView.swift
//  WeatherForecast
//
//  Created by DONGWOOK SEO on 2023/03/30.
//

import UIKit

final class WeatherHeaderView: UICollectionReusableView {

    //MARK: - Constants

    private enum Constants {
        static let addressLabelSkeletonText: String = "지역정보 받아오는 중..."
        static let temperatureRangeLabelSkeletonText: String = "최저 - °C, 최고 - °C"
        static func temperatureRangeLabelText(minimunTemperature: Double, maximumTemperature: Double) -> String {
            "최저 \(minimunTemperature) 최고 \(maximumTemperature)"
        }
        static let temperatureLabelSkeletonText: String = "- °C"
    }

    private enum Metric {
        static let headerViewHeight: CGFloat = 100
        static let weatherIconImageViewHeightSize: CGFloat = 80
        static let weatherIconImageViewWidthMultiplier: CGFloat = 1
        static let weatherIconImageViewLeadingInset: CGFloat = 16

        static let infoStackViewTopInset: CGFloat = 5
        static let infoStackViewLeadingInset: CGFloat = 20
        static let infoStackViewBottomInset: CGFloat = 5

        static let addressLabelFontSize: CGFloat = 13
        static let temperatureRangeLabelFontSize: CGFloat = 13
        static let temperatureLabelFontSize: CGFloat = 30
    }

    // MARK: - Properties

    static let identifier = "WeatherViewHeader"

    // MARK: - UI Components

    private let weatherIconImageView = UIImageView()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.addressLabelSkeletonText
        label.font = UIFont.systemFont(ofSize: Metric.addressLabelFontSize)
        return label
    }()

    private let temperatureRangeLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.temperatureRangeLabelSkeletonText
        label.font = UIFont.systemFont(ofSize: Metric.temperatureRangeLabelFontSize)
        return label
    }()

    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.temperatureLabelSkeletonText
        label.font = UIFont.systemFont(ofSize: Metric.temperatureLabelFontSize)
        return label
    }()

    private lazy var addressAndTemperutureRange: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            addressLabel,
            temperatureRangeLabel
        ])
        stackView.alignment = .leading
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var infoStackView: UIStackView =  {
        let stackView = UIStackView(arrangedSubviews: [
            addressAndTemperutureRange,
            temperatureLabel
        ])
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.axis = .vertical
        return stackView
    }()

    let locationSettingButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "location.circle"), for: .normal)
        return button
    }()

    // MARK: - LifeCycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func configure(with currentWeatherDetail: WeatherDetail, address: String, icon: UIImage) {
        temperatureLabel.text = "\(currentWeatherDetail.temperature)"
        temperatureRangeLabel.text = Constants.temperatureRangeLabelText(
            minimunTemperature: currentWeatherDetail.minimumTemperature,
            maximumTemperature: currentWeatherDetail.maximumTemperature
        )
        addressLabel.text = address
        weatherIconImageView.image = icon
    }

    // MARK: - Private

    private func setupLayout() {
        let heightLayout = self.heightAnchor.constraint(equalToConstant: Metric.headerViewHeight)
        heightLayout.priority = .defaultHigh
        heightLayout.isActive = true
        
        addSubview(weatherIconImageView)
        weatherIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            weatherIconImageView.heightAnchor.constraint(equalToConstant: Metric.weatherIconImageViewHeightSize),
            weatherIconImageView.widthAnchor.constraint(equalTo: weatherIconImageView.heightAnchor, multiplier: Metric.weatherIconImageViewWidthMultiplier),
            weatherIconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metric.weatherIconImageViewLeadingInset),
            weatherIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addSubview(infoStackView)
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoStackView.topAnchor.constraint(equalTo: topAnchor, constant: Metric.infoStackViewTopInset),
            infoStackView.leadingAnchor.constraint(equalTo: weatherIconImageView.trailingAnchor, constant: Metric.infoStackViewLeadingInset),
            infoStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Metric.infoStackViewBottomInset),
        ])

        addSubview(locationSettingButton)
        locationSettingButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationSettingButton.widthAnchor.constraint(equalToConstant: 25),
            locationSettingButton.heightAnchor.constraint(equalToConstant: 25),
            locationSettingButton.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            locationSettingButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15)
        ])
    }

}
