# RxMapAnnotations

This project is an `annotation` binding to allow binding value types (such as structs) as `MKMapView` annotations.

As MKMapView enforces annotations to conform to `NSObjectProtocol` a developer has pretty much no other choice other than introduce annotations as classes in his project. However, these reference types should be avoided when dealing with Rx and thus the goal of this project is to make it possible to bind value types to `MKMapView.rx.annotations`.

NOTE: This project is just experimenting with the value type annotations. Currently at least annotation drag & drop is not supported.

### Installation

In order to use this extension, `RxMKMapView` along with `RxSwift` and `RxCocoa` are needed. Currently the only supported way of installing is to copy the file [RxMapAnnotations.swift](RxMapAnnotations/RxMapAnnotations.swift) into your project.
