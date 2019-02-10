# RxMapAnnotations

This project is an `annotation` binding to allow binding value types (such as structs) as `MKMapView` annotations.

As MKMapView enforces annotations to conform to `NSObjectProtocol` a developer has pretty much no other choice other than introduce annotations as classes in his project. However, these reference types should be avoided when dealing with Rx and thus the goal of this project is to make it possible to bind value types to `MKMapView.rx.annotations`.

NOTE: This project is just experimenting with the value type annotations. Currently at least annotation drag & drop is not supported as the binding is bidirectional. However, using this method doesn't exclude from anything; you can still add annotations to the map the traditional way.

### Usage

You need a custom type and an annotation wrapper for it:

```swift
// Your custom type you want to display on the map
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

// A subclass of MKAnnotation, to be shown on the map
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
      .drive(mapView.rx.annotations(create: PointOfInterestAnnotation.init))
      .disposed(by: disposeBag)
```

### Installation

In order to use this extension, `RxMKMapView` along with `RxSwift` and `RxCocoa` are needed. Currently the only supported way of installing is to copy the file [`RxMapAnnotations.swift`](RxMapAnnotations/RxMapAnnotations.swift) into your project.
