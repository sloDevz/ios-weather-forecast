//
//  WeatherListViewController - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import CoreLocation

final class WeatherListViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let backgroundImageFileName = "WeatherBackgroundImage"
    }
    
    // MARK: - Properties
    
    private let repository = OpenWeatherRepository(
        deserializer: JSONDesirializer(),
        service: NetworkService()
    )

    private let locationDataManager = LocationDataManager()
    private let addressManager = AddressManager()

    private var currentWeather: CurrentWeather? = nil {
        didSet {
            updateHeaderView()
        }
    }

    private var forecastDatas: [ForecastData] = [] {
        didSet {
            updateListView()
        }
    }

    private let endRefreshingDispatchGroup = DispatchGroup()

    // MARK: - UI Components

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createCollectionViewLayout()
    )

    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationDataManager()
        setupCollectionView()
        setupViewBackground()
        setupLayout()
    }

    // MARK: - Private

    private func setupLocationDataManager() {
        locationDataManager.delegate = self

        if !locationDataManager.isAuthorized {
            locationDataManager.requestAuthorization()
        }
    }

    private func fetchLocation() {
        locationDataManager.requestLocation()
    }

    private func fetchWeather(coordinate: Coordinate) {
        Task {
            endRefreshingDispatchGroup.enter()
            let currentWeather = try await repository.fetchWeather(coordinate: coordinate)
            self.currentWeather = currentWeather
            self.endRefreshingDispatchGroup.leave()
        }
    }

    private func fetchForecast(coordinate: Coordinate) {
        Task {
            endRefreshingDispatchGroup.enter()
            let forecast = try await repository.fetchForecast(coordinate: coordinate)
            self.forecastDatas = forecast.forecastDatas
            endRefreshingDispatchGroup.leave()
        }
    }
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.register(
            WeatherCell.self,
            forCellWithReuseIdentifier: WeatherCell.identifier
        )
        collectionView.register(
            WeatherHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: WeatherHeaderView.identifier
        )

        setupRefreshControl()
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    @objc private func pullToRefresh(_ refreshControl: UIRefreshControl) {
        fetchLocation()
    }

    private func endRefreshing() {
        guard refreshControl.isRefreshing else { return }

        self.refreshControl.endRefreshing()
    }

    private func setNotifyEndRefreshingToDispatchGroup() {
        endRefreshingDispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.endRefreshing()
        }
    }

    @objc private func locationSettingButtonTapped() {
        let alert = UIAlertController(title: "위치변경", message: "날씨를 받아올 위치의 위도와 경도를 입력해주세요", preferredStyle: .alert)
        let confirm = UIAlertAction(title: "변경", style: .default) { confirm in
            guard let longitudeString = alert.textFields?.first?.text,
                  let latitudeString =  alert.textFields?.last?.text else { return }

            guard let longitude = Double(longitudeString),
                  let latitude = Double(latitudeString) else { return }

            print(longitude, latitude)
            let coordinate = Coordinate(longitude: longitude, latitude: latitude)

            self.fetchWeather(coordinate: coordinate)
            self.fetchForecast(coordinate: coordinate)

            self.addressManager.fetchAddress(of: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }

        let cancel = UIAlertAction(title: "취소", style: .cancel)

        alert.addTextField { textFieid in
            textFieid.placeholder = "위도를 입력하세요."
        }
        alert.addTextField { textFieid in
            textFieid.placeholder = "경도를 입력하세요."
        }
        alert.addAction(confirm)
        alert.addAction(cancel)

        self.present(alert, animated: true)
    }
    
    // MARK: - Layout

    private func setupViewBackground() {
        let backgroundIamgeView = UIImageView(frame: view.frame)
        backgroundIamgeView.image = UIImage(named: Constants.backgroundImageFileName)
        backgroundIamgeView.contentMode = .scaleAspectFill

        view.addSubview(backgroundIamgeView)
        view.sendSubviewToBack(backgroundIamgeView)
    }

    private func setupLayout() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func createCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
        configuration.headerMode = .supplementary
        configuration.backgroundColor = .clear
        
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    private func updateHeaderView() {
        guard let currentWeather,
              let headerView = self.collectionView.visibleSupplementaryViews(
            ofKind: UICollectionView.elementKindSectionHeader
        ).first as? WeatherHeaderView else { return }
        
        headerView.locationSettingButton.addTarget(self, action: #selector (locationSettingButtonTapped), for: .touchUpInside)

        Task {
            let image = try await repository.fetchWeatherIconImage(withID: currentWeather.weathers.first?.icon ?? "")

            headerView.configure(
                with: currentWeather.weatherDetail,
                address: self.addressManager.address,
                icon: image
            )
        }
    }

    private func updateListView() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
}

// MARK: - LocationDataManagerDelegate

extension WeatherListViewController: LocationDataManagerDelegate {

    func locationDataManager(_ locationDataManager: LocationDataManager,
                             didAuthorized isAuthorized: Bool) {
        guard isAuthorized else { return }
        fetchLocation()
    }

    func locationDataManager(_ locationDataManager: LocationDataManager,
                             didUpdateLocation location: CLLocation) {
        addressManager.fetchAddress(of: location)

        guard let coordinate = locationDataManager.currentCoordinate else { return }

        fetchWeather(coordinate: coordinate)
        fetchForecast(coordinate: coordinate)
        setNotifyEndRefreshingToDispatchGroup()
    }
    
}

// MARK: - UICollectionViewDataSource

extension WeatherListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: WeatherHeaderView.identifier,
            for: indexPath) as? WeatherHeaderView else {
            return UICollectionReusableView()
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return forecastDatas.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WeatherCell.identifier,
            for: indexPath) as? WeatherCell,
              let weather = forecastDatas[safe: indexPath.row] else {
            return UICollectionViewCell()
        }

        let date = DateFormatUtil.format(with: weather.dateString)
        let temperature = String(weather.weatherDetail.temperature)
        let iconID = weather.weathers.first?.icon ?? ""

        Task {
            let icon = try await repository.fetchWeatherIconImage(withID: iconID)
            cell.configure(icon: icon)
        }

        cell.configure(date: date, temperature: temperature)
        return cell
    }

}
