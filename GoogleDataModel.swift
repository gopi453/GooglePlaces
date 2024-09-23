//
//  GoogleDataModel.swift
//
//  Created by K Gopi on 03/11/23.
//

import Foundation
import GooglePlaces
import GoogleMaps

public struct GooglePlace {
    let id: String?
    let address: String?
    let coordinates: CLLocationCoordinate2D?
    let name: String?
    let postalCode: String?
    var state: String?
    var city: String?
    var country: String?

    init(id: String? = nil, address: String? = nil, coordinates: CLLocationCoordinate2D? = nil, name: String? = nil, postalCode: String? = nil) {
        self.id = id
        self.address = address
        self.coordinates = coordinates
        self.name = name
        self.postalCode = postalCode
    }

    init(address: GMSAddress) {
        self.id = nil
        self.address = address.lines?.first ?? ""
        self.name = address.thoroughfare ?? address.locality ?? address.administrativeArea
        self.coordinates = address.coordinate
        self.postalCode = address.postalCode
        self.country = address.country
    }

    init(place: GMSPlace) {
        self.id = place.placeID
        self.address = place.formattedAddress ?? ""
        self.name = place.name
        self.coordinates = place.coordinate
        self.postalCode = nil
    }

    init(prediction: GMSAutocompletePrediction) {
        self.id = prediction.placeID
        self.address = prediction.attributedFullText.string
        self.name = prediction.attributedPrimaryText.string
        self.coordinates = nil
        self.postalCode = nil
    }

    static func getDefaultPlace() -> GooglePlace {
        let place = GooglePlace(address: "Enable location services", name: "Use Current Location")
        return place
    }
}
extension GooglePlace: Equatable {
    public static func ==(lhs: GooglePlace, rhs: GooglePlace) -> Bool {
        lhs.address == rhs.address && lhs.id == rhs.id && lhs.coordinates == rhs.coordinates && lhs.name == rhs.name
    }
}

extension Array where Self.Element == GMSMarker {
    func getPlaces() -> [GooglePlace] {
        return self.compactMap({
            ($0.iconView as? MarkerInfoWindowView)?.place
        })
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    func rounded(toPlaces places: Int) -> CLLocationCoordinate2D {
        let lat = self.latitude.rounded(toPlaces: places)
        let long = self.longitude.rounded(toPlaces: places)
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }

    public static func fallback() -> CLLocationCoordinate2D {
        .init(latitude: 0, longitude: 0)
    }

}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
