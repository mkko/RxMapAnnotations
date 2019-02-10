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

import MapKit
import RxSwift
import RxCocoa
import RxMKMapView

public protocol IdentifiableAnnotation {

    associatedtype AnnotationID: Hashable

    /// The identity of the annotation. This will be used to determine whether
    /// a given annotation is the same instance.
    var annotationID: AnnotationID { get }
}

public extension Reactive where Base: MKMapView {

    public func annotations<
        A: RxAnnotation,
        O: ObservableType>
        (create: @escaping (A.Annotation) -> A)
        -> (_ source: O)
        -> Disposable
        where O.E == [A.Annotation] {
            return { source in
                let ds = RxMapViewIdentifiableAnnotationDataSource<A>(create: create)
                return self.annotations(dataSource: ds)(source)
            }
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

public class RxMapViewIdentifiableAnnotationDataSource<A: RxAnnotation>: RxMapViewDataSourceType {

    init(create: @escaping (A.Annotation) -> A) {
        self.create = create
    }

    var create: (A.Annotation) -> A

    var current: [A.Annotation.AnnotationID: A] = [:]

    public func mapView(_ mapView: MKMapView, observedEvent: Event<[A.Annotation]>) {
        Binder(self) { _, newAnnotations in
            DispatchQueue.main.async {
                //let _start = CFAbsoluteTimeGetCurrent()

                var next: [A.Annotation.AnnotationID: A] = [:]
                var toAdd = [A]()
                var toRemove = self.current

                for a in newAnnotations {
                    let boxed: A
                    if let existing = toRemove.removeValue(forKey: a.annotationID) {
                        boxed = existing
                        boxed.update(from: a)
                    } else {
                        boxed = self.create(a)
                        toAdd.append(boxed)
                    }
                    next[a.annotationID] = boxed
                }

                self.current = next

                //let _diff = CFAbsoluteTimeGetCurrent() - _start
                //print("Elapsed time: \(_diff) seconds")

                mapView.addAnnotations(toAdd)
                mapView.removeAnnotations(Array(toRemove.values))
            }
            }.on(observedEvent)
    }
}

public protocol RxAnnotation: MKAnnotation {

    associatedtype Annotation: IdentifiableAnnotation

    var box: Annotation { get }

    func update(from annotation: Annotation)
}
