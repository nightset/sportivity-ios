//
//  MapViewController.swift
//  Sportivity
//
//  Created by Andrzej Frankowski on 08/06/2017.
//  Copyright © 2017 Sportivity. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MapKit

private struct MapViewControllerConstants {
    static let clusterAnnotationReuseId = "cluster"
    static let placeAnnotationReuseId = "place"
    static let clusteringEnabled = true
    static let useApplePins = true
}

private typealias C = MapViewControllerConstants

class MapViewController: UIViewController, ViewControllerProtocol, Configurable  {

    /// Tag of the view
    let viewTag : ViewTag = .events
    /// Main `DisposeBag` of the `ViewController`
    let disposeBag = DisposeBag()
    /// Observable that informs that `Router` should route to the `Route`
    let onRouteTo : Observable<Route> = PublishSubject<Route>()

    @IBOutlet fileprivate weak var mapView: MKMapView!
    fileprivate let clusterManager = ClusterManager()
    var viewModel: MapViewModel! = MapViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let center = CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122)
        let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        let region = MKCoordinateRegionMake(center, span)
        mapView.setRegion(region, animated: false)
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

private extension MapViewController {
    func bind() {
        viewModel
            .placeAnnotations
            .asObservable()
            .subscribeNext { [unowned self] (annotations) in
                if C.clusteringEnabled {
                    self.clusterManager.add(annotations)
                } else {
                    self.mapView.addAnnotations(annotations)
                }
            }
            .addDisposableTo(disposeBag)
    }
}

extension MapViewController : MKMapViewDelegate {
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if C.clusteringEnabled {
            self.clusterManager.mapViewChanged(mapView, visibleMapRect: mapView.visibleMapRect)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let color = R.color.sportivity.sunsetOrange()
        
        var view: MKAnnotationView!
        guard let annotation = annotation as? MapAnnotation else {
            assert(false)
            return nil
        }
        
        switch annotation.type {
        case .pin:
            if C.useApplePins {
                view = mapView.dequeueReusableAnnotationView(withIdentifier: C.placeAnnotationReuseId) as? MKPinAnnotationView
            } else {
                view = mapView.dequeueReusableAnnotationView(withIdentifier: C.placeAnnotationReuseId) as? PlaceAnnotationView
            }
            if let view = view {
                view.annotation = annotation
            } else {
                if C.useApplePins {
                    let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: C.placeAnnotationReuseId)
                    if #available(iOS 9.0, *) {
                        pinView.pinTintColor = color
                    } else {
                        pinView.pinColor = .red
                    }
                    view = pinView
                } else {
                    let placeView = PlaceAnnotationView(annotation: annotation, reuseIdentifier: C.placeAnnotationReuseId)
                    view = placeView
                }
            }
        case .cluster(_):
            view = mapView.dequeueReusableAnnotationView(withIdentifier: C.clusterAnnotationReuseId)
            if let view = view {
                view.annotation = annotation
            } else {
                view = ClusterAnnotationView(annotation: annotation, reuseIdentifier: C.clusterAnnotationReuseId, color: color)
            }
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if C.clusteringEnabled {
            clusterManager.mapViewChanged(mapView, visibleMapRect: mapView.visibleMapRect)
        }
    }
}
