//
//  RxMapAnnotations.swift
//  RxMapAnnotations
//
//  Created by Mikko Välimäki on 2019-01-08.
//  Copyright © 2019 Mikko. All rights reserved.
//

import MapKit
import RxSwift
import RxCocoa
import RxMKMapView

public protocol IdentifiableAnnotation {

    var id: String { get }

    var coordinate: CLLocationCoordinate2D { get }

    var title: String? { get }

    var subtitle: String? { get }
}

extension Reactive where Base: MKMapView {

    //

    public func annotations<
        A: IdentifiableAnnotation,
        O: ObservableType>
        (_ source: O)
        -> Disposable
        where O.E == [A] {
            let ds = RxMapViewIdentifiableAnnotationDataSource<A>()
            return self.annotations(dataSource: ds)(source)
    }

    public func annotations<
        DataSource: RxMapViewDataSourceType,
        O: ObservableType>
        (dataSource: DataSource)
        -> (_ source: O)
        -> Disposable
        where O.E == [DataSource.Element],
        DataSource.Element: IdentifiableAnnotation {
            return { source in
                return source
                    .subscribe({ event in
                        dataSource.mapView(self.base, observedEvent: event)
                    })
            }
    }
}


public class RxMapViewIdentifiableAnnotationDataSource<S: IdentifiableAnnotation>
: RxMapViewDataSourceType {
    public typealias Element = S

    var current: [String: RxAnnotationBox] = [:]

    public func mapView(_ mapView: MKMapView, observedEvent: Event<[Element]>) {
        Binder(self) { _, newAnnotations in
            DispatchQueue.main.async {
                let _start = CFAbsoluteTimeGetCurrent()

                var next: [String: RxAnnotationBox] = [:]
                var toAdd = [RxAnnotationBox]()
                var toRemove = self.current

                for a in newAnnotations {
                    let boxed: RxAnnotationBox
                    if let existing = toRemove.removeValue(forKey: a.id) {
                        boxed = existing
                        boxed.update(from: a)
                    } else {
                        boxed = RxAnnotationBox(original: a)
                        toAdd.append(boxed)
                    }
                    next[a.id] = boxed
                }

                self.current = next

                let _diff = CFAbsoluteTimeGetCurrent() - _start
                print("Elapsed time: \(_diff) seconds")

                mapView.addAnnotations(toAdd)
                mapView.removeAnnotations(Array(toRemove.values))
            }
            }.on(observedEvent)
    }
}

public class RxAnnotationBox: NSObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D
    
    public private(set) var title: String?

    public private(set) var subtitle: String?

    public private(set) var box: IdentifiableAnnotation

    init(original: IdentifiableAnnotation) {
        self.box = original
        self.coordinate = original.coordinate
        self.title = original.title
        self.subtitle = original.subtitle
    }
}

fileprivate extension RxAnnotationBox {

    func update(from annotation: IdentifiableAnnotation) {
        self.box = annotation
        self.coordinate = box.coordinate
        self.title = box.title
        self.subtitle = box.subtitle
    }
}
