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

    // MARK: Binding annotation to the Map
    public func annotations2<
        A: IdentifiableAnnotation,
        O: ObservableType>
        (_ source: O)
        -> Disposable
        where O.E == [A] {
            let ds = RxMapViewReactiveDataSource2<A>()
            return self.annotations2(dataSource: ds)(source)
    }

    public func annotations2<
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


public class RxMapViewReactiveDataSource2<S: IdentifiableAnnotation>
: RxMapViewDataSourceType {
    public typealias Element = S

    var current: [String: BoxedAnnotation] = [:]

    public func mapView(_ mapView: MKMapView, observedEvent: Event<[Element]>) {
        Binder(self) { _, newAnnotations in
            DispatchQueue.main.async {
                let _start = CFAbsoluteTimeGetCurrent()

                var next: [String: BoxedAnnotation] = [:]
                var toAdd = [BoxedAnnotation]()
                var toRemove = self.current

                for a in newAnnotations {
                    let boxed: BoxedAnnotation
                    if let existing = toRemove.removeValue(forKey: a.id) {
                        boxed = existing
                    } else {
                        boxed = BoxedAnnotation(original: a)
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

public class BoxedAnnotation: NSObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D
    
    public var title: String?

    public var subtitle: String?

    var original: IdentifiableAnnotation

    init(original: IdentifiableAnnotation) {
        self.original = original
        self.coordinate = original.coordinate
        self.title = original.title
        self.subtitle = original.subtitle
    }
}
