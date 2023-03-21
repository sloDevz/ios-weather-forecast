//
//  LocationDataManager.swift
//  WeatherForecast
//
//  Created by Mason Kim on 2023/03/20.
//

import Foundation
import OSLog
import CoreLocation

protocol LocationDataManagerDelegate: AnyObject {

    func locationDataManager(_ locationDataManager: LocationDataManager,
                             didUpdateLocation location: CLLocation)
    func locationDataManager(_ locationDataManager: LocationDataManager,
                             didAuthorized isAuthorized: Bool)
    func locationDataManager(_ locationDataManager: LocationDataManager,
                             didUpdateAddress placemark: CLPlacemark)

}

final class LocationDataManager: NSObject, CLLocationManagerDelegate {

    // MARK: - Properties

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    weak var delegate: LocationDataManagerDelegate?
    var isAuthorized: Bool {
        locationManager.authorizationStatus == .authorizedWhenInUse
    }
    
    // MARK: - Lifecycle

    override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - Public

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        delegate?.locationDataManager(self, didUpdateLocation: location)
        fetchAddress(of: location)
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        os_log(.error, log: .location, "%@", error.localizedDescription)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        delegate?.locationDataManager(self, didAuthorized: isAuthorized)
    }
    
    
    
    
    func fetchAddress(of location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [self] placemarks, error in
            guard error == nil else { return }

            guard let placemark = placemarks?.first else { return }
            delegate?.locationDataManager(self, didUpdateAddress: placemark)
        }
       
    }

}
