//
//  ViewController.swift
//  RxMapAnnotations
//
//  Created by Mikko Välimäki on 2019-01-08.
//  Copyright © 2019 Mikko. All rights reserved.
//

import UIKit
import MapKit
import RxSwift
import RxCocoa
import RxMKMapView

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let points = loadPointsOfInterest()
            .asObservable()
            .share(replay: 1)

        /// Map region change and search into an array of Annotations
        /// and bind these annotations directly into the Map View.
        mapView.rx.region
            .withLatestFrom(points) { ($1, $0) }
            .map { points, region -> [PointOfInterest] in
                return points.filter(region.contains(poi:))
            }
            .asDriver(onErrorJustReturn: [])
            .drive(mapView.rx.annotations)
            .disposed(by: disposeBag)
    }
}

extension ViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let pin = mapView.dequeueReusableAnnotationView(withIdentifier: "MapAnnotation") as? MKPinAnnotationView {
            pin.annotation = annotation
            //pin.animatesDrop = true
            return pin
        } else {
            let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "MapAnnotation")
            //pin.animatesDrop = true
            return pin
        }
    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        print("")
    }

    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
        return MKClusterAnnotation(memberAnnotations: memberAnnotations)
    }
}

func loadPointsOfInterest() -> Single<[PointOfInterest]> {
    print("Loading POIs...")
    guard let path = Bundle.main.path(forResource: "simplemaps-worldcities-basic", ofType: "csv") else {
        fatalError("Missing Sample Data")
    }

    do {
        let data = try String(contentsOfFile: path, encoding: .utf8)
        let lines = data.components(separatedBy: .newlines)
        let cities = lines.compactMap { line -> PointOfInterest? in
            let csv = line.components(separatedBy: ",")

            guard csv.count > 3,
                let lat = Double(csv[2]),
                let lon = Double(csv[3]),
                let population = Double(csv[4]) else {
                    return nil
            }

            let name = csv[0]
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let subtitle = "Population \(population)"
            return PointOfInterest(title: name, subtitle: subtitle, coordinate: coord)
        }

        print("Found \(cities.count) POIs")
        return Single.just(cities)
    } catch let error {
        return Single.error(error)
    }
}

// MARK: - Map Annotation and Helpers

struct PointOfInterest: IdentifiableAnnotation {
    var id: String = UUID().uuidString

    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}

extension MKCoordinateRegion {
    func contains(poi: PointOfInterest) -> Bool {
        return abs(self.center.latitude - poi.coordinate.latitude) <= self.span.latitudeDelta / 2.0
            && abs(self.center.longitude - poi.coordinate.longitude) <= self.span.longitudeDelta / 2.0
    }
}
