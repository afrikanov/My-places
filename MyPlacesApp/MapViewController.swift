//
//  MapViewController.swift
//  MyPlacesApp
//
//  Created by  Aleksandr Afrikanov on 19.03.2021.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func getAddress(address: String)
}

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var locationPin: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var routeButton: UIButton!
    
    var delegate: MapViewControllerDelegate?
    var place: Place!
    let annotationIdentifier = "annotationIdentifier"
    var locationManager = CLLocationManager()
    var incomeSegueIdentifier = ""
    var regionInMeters = 1000.0
    var placeCoordinates: CLLocationCoordinate2D?
    var previousLocation: CLLocation? {
        didSet {
            self.startTrackingUserLocation()
        }
    }
    var directionsArray: [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        self.locationManager.delegate = self
        self.checkLocation()
        if self.incomeSegueIdentifier == "openPlaceLocation" {
            self.configureOpenLocation()
            self.configurePlacemark()
        } else if self.incomeSegueIdentifier == "choosePlaceLocation" {
            self.configureChooseLocation()
            self.showUserLocation()
        }
    }
    
    func configureOpenLocation() {
        self.saveButton.alpha = 0
        self.locationPin.alpha = 0
        self.addressLabel.alpha = 0
        self.routeButton.alpha = 1
    }
    
    func configureChooseLocation() {
        self.saveButton.alpha = 1
        self.locationPin.alpha = 1
        self.addressLabel.alpha = 1
        self.routeButton.alpha = 0
    }
    
    @IBAction func exitMap(_ segue: UIStoryboardSegue) {
        dismiss(animated: true)
    }
    
    func configurePlacemark() {
        guard let location = place.location else {
            return
        }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location, completionHandler: { (placemarks, error) in
            if error != nil {
                return
            }
            
            guard let placemark = placemarks?.first else {
                return
            }
            let annotation = MKPointAnnotation()
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            guard let placemarkLocation = placemark.location else {
                return
            }
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinates = placemarkLocation.coordinate
            
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
        })
    }
    
    private func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        for direction in directionsArray {
            direction.cancel()
        }
        directionsArray.removeAll()
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {() in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            
            alert.addAction(okAction)
            self.present(alert, animated: true)
        })
    }
    
    private func checkLocationAuthorization() {
        switch self.locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            self.mapView.showsUserLocation = true
            if incomeSegueIdentifier == "choosePlaceLocation" {
                self.showUserLocation()
            }
            break
        case .denied:
            self.showAlert(title: "Your location is not available", message: "Go to Settings -> MyPlacesApp -> Location")
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            self.showAlert(title: "Your location is not available", message: "")
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("")
        }
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func checkLocation() {
        if CLLocationManager.locationServicesEnabled() {
            self.setupLocationManager()
            self.checkLocationAuthorization()
        } else {
            self.showAlert(title: "Location services are disabled", message: "Go to Settings -> Privacy -> Location Services")
        }
    }
    
    @IBAction func userLocationButtonAction(_ sender: UIButton) {
        self.showUserLocation()
    }
    
    func showUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: self.regionInMeters,
                                            longitudinalMeters: self.regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func startTrackingUserLocation() {
        guard let previousLocation = self.previousLocation else {
            return
        }
        let center = CLLocation(latitude: self.mapView.centerCoordinate.latitude, longitude: self.mapView.centerCoordinate.longitude)
        guard center.distance(from: previousLocation) > 50 else {
            return
        }
        self.previousLocation = center
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            self.showUserLocation()
        })
    }
    
    @IBAction func saveLocationButtonAction(_ sender: Any) {
        self.delegate?.getAddress(address: self.addressLabel.text!)
        dismiss(animated: true)
    }
    
    private func getRoutes() {
        guard let location = self.locationManager.location?.coordinate else {
            self.showAlert(title: "Error", message: "Current location not found")
            return
        }
        locationManager.startUpdatingLocation()
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        guard let request = createRoutesRequest(from: location) else {
            self.showAlert(title: "Error", message: "Destination not found")
            return
        }
        
        let directions = MKDirections(request: request)
        self.resetMapView(withNew: directions)
        directions.calculate(completionHandler: {(response, error) in
            if let error = error {
                print(error)
                return
            }
            guard let response = response else {
                self.showAlert(title:"Error", message: "Routes are not found")
                return
            }
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                let distance = String(format: "%.1f", route.distance / 1000)
                let time = route.expectedTravelTime
                
                print("Distance : ", distance)
                print("Time : ", time)
            }
        })
    }
    
    private func createRoutesRequest(from coordinates: CLLocationCoordinate2D) -> MKDirections.Request? {
        guard let destinationCoordinates = self.placeCoordinates else {
            return nil
        }
        let startPoint = MKPlacemark(coordinate: coordinates)
        let finishPoint = MKPlacemark(coordinate: destinationCoordinates)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startPoint)
        request.destination = MKMapItem(placemark: finishPoint)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        return request
    }
    
    @IBAction func routeButtonAction(_ sender: Any) {
        self.getRoutes()
    }
    
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: self.annotationIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: self.annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
            let image = UIImage(data: imageData)
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = image
            annotationView?.leftCalloutAccessoryView = imageView
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: center.latitude, longitude: center.longitude), completionHandler: { (placemarks, error) in
            if error != nil {
                return
            }
            
            if self.incomeSegueIdentifier == "openPlaceLocation" && self.previousLocation != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    self.showUserLocation()
                })
            }
            
            geoCoder.cancelGeocode()
            
            guard let placemark = placemarks?.first else {
                return
            }
            let streetName = placemark.thoroughfare != nil ? placemark.thoroughfare! : ""
            let buildNumber = placemark.subThoroughfare != nil ? ", " + placemark.subThoroughfare! : ""
            
            self.addressLabel.text = "\(streetName)\(buildNumber)"
//            self.addressLabel.backgroundColor = .white
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                self.addressLabel.backgroundColor = .clear
//            }
            
        })
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.checkLocationAuthorization()
    }
    
}
