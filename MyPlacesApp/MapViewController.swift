//
//  MapViewController.swift
//  MyPlacesApp
//
//  Created by  Aleksandr Afrikanov on 19.03.2021.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var place: Place!
    let annotationIdentifier = "annotationIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configurePlacemark()
        self.mapView.delegate = self
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
            
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
        })
    }

}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "annotationIdentifier")
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
}
