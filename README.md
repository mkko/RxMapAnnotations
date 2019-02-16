# Using value types with `MKMapView`

This project is an addition to `annotation` binding enabling value types (such as structs, enums) as `MKMapView` annotations.

### Background

As MKMapView enforces annotations to conform to `NSObjectProtocol` a developer has pretty much no other choice other than make annotations derive from `NSObject` in his project. However, these reference types are good to be avoided when dealing with Rx and thus the goal of this project is to make value type binding possible.

### Usage

You need a custom type and an annotation wrapper for it:

```swift
/// A custom type to be bound to the map.
struct PointOfInterest: IdentifiableAnnotation {

    var annotationID = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}

/// A subclass of MKAnnotation, to be shown on the map.
class PointOfInterestAnnotation: NSObject, RxAnnotation {

    @objc var coordinate: CLLocationCoordinate2D

    var box: PointOfInterest

    var title: String? {
        return self.box.title
    }

    init(_ annotation: PointOfInterest) {
        self.box = annotation
        self.coordinate = annotation.coordinate
    }

    func update(from annotation: PointOfInterest) {
        self.box = annotation
        self.coordinate = annotation.coordinate
    }
}

```

With these two types, you create the binding and you're good to go.

```swift
    mapView.rx.region
        .withLatestFrom(points) { ($1, $0) }
        .map { (points, region) in points.filter(region.contains(poi:)) }
        .asDriver(onErrorJustReturn: [])
        .drive(mapView.rx.items(create: PointOfInterestAnnotation.init))
        .disposed(by: disposeBag)
```

In order to get get the selection from the map, you need to use `selectedItem(ofMappedType:)` which gives you the original type. 

```swift
    mapView.rx.didSelectItem(ofMappedType: PointOfInterestAnnotation.self)
        .debug("didSelectItem", trimOutput: true)
        .subscribe()
        .disposed(by: disposeBag)
```

### Installation

In order to use this extension, `RxMKMapView` along with `RxSwift` and `RxCocoa` are needed. Just copy the file [RxMapAnnotations.swift](RxMapAnnotations/RxMapAnnotations.swift) into your project.
