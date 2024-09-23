//
//  GMSGeocoder.swift
//
//  Created by K Gopi on 20/10/23.
//

import Foundation
import GooglePlaces
import GoogleMaps
import Combine
enum GeocodeType {
    case forward(String), reverse(CLLocationCoordinate2D), placeRecommendations(GMSPlaceField), placeid(String)
}

protocol GoogleGeocoderProtocol: AnyObject {
    func fetchData<T>(for type: GeocodeType, decodeType: T.Type) -> AnyPublisher<T, GeocodeError>
}

extension GoogleGeocoderProtocol {
    private var placeClient: GMSPlacesClient {
      return GMSPlacesClient.shared()
    }

    func fetchData<T>(for type: GeocodeType, decodeType: T.Type) -> AnyPublisher<T, GeocodeError> {
        Deferred {
            Future { [weak self] promise in
                guard let strongSelf = self else {
                    return
                }
                switch type {
                case .forward(let query):
                    strongSelf.forwardGeocode(from: query) { result in
                        promise(result)
                    }
                case .reverse(let coordinates):
                    strongSelf.reverseGeocode(for: coordinates) { result in
                        promise(result)
                    }
                case .placeRecommendations(let fields):
                    strongSelf.getPlaceRecommendations(with: fields) { result in
                        promise(result)
                    }
                case .placeid(let value):
                    strongSelf.getPlaceDetails(from: value) { result in
                        promise(result)
                    }
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func forwardGeocode<T>(from query: String, _ completion: @escaping (Result<T, GeocodeError>) -> Void) {
        let filter = GMSAutocompleteFilter()
//        filter.types = []
        filter.countries = ["IN"]
        let sessionToken = BaseApplicationDelegate.getGMSSessionToken()
        placeClient.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: sessionToken) { results, error in
            if let responseError = error {
                completion(.failure(.placeError))
                return
            }
            if let places = (results?.compactMap({ GooglePlace(prediction: $0) }) ?? []) as? T {
                completion(.success(places))
            }
        }
    }

    private func reverseGeocode<T>(for position: CLLocationCoordinate2D, _ completion: @escaping (Result<T, GeocodeError>) -> Void) {
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(position) { response, error in
            if let responseError = error {
                completion(.failure(.custom(responseError.localizedDescription)))
                return
            }
            guard let decodedResponse = response, let firstAddress = decodedResponse.firstResult() else {
                completion(.failure(.placeError))
                return
            }
            if let place = GooglePlace(address: firstAddress) as? T {
                completion(.success(place))
            }
        }
    }

    private func getPlaceRecommendations<T>(with fields: GMSPlaceField, _ completion: @escaping (Result<T, GeocodeError>) -> Void) {

        placeClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: fields) { results, error in
            if let responseError = error {
                completion(.failure(.custom(responseError.localizedDescription)))
                return
            }
            if let places = (results?.filter({ $0.likelihood >= 0.1 }).sorted(by: { $0.likelihood > $1.likelihood }).compactMap({ GooglePlace(place: $0.place) }) ?? []) as? T {
                completion(.success(places))
            }
        }

    }

    private func getPlaceDetails<T>(from id: String, _ completion: @escaping (Result<T, GeocodeError>) -> Void) {
        let sessionToken = BaseApplicationDelegate.getGMSSessionToken()
        placeClient.fetchPlace(fromPlaceID: id, placeFields: .coordinate, sessionToken: sessionToken) { place, error in
            if let responseError = error {
                completion(.failure(.custom(responseError.localizedDescription)))
                return
            }
            guard let fetchedPlace = place else {
                completion(.failure(.placeError))
                return
            }
            if let place = GooglePlace(place: fetchedPlace) as? T {
                completion(.success(place))
            }
        }
    }

}
public enum GeocodeError: Error {
    case placeError
    case custom(String)
}

extension Publisher {
  func asResult() -> AnyPublisher<Result<Output, Failure>, Never> {
    self
      .map(Result.success)
      .catch { error in
        Just(.failure(error))
      }
      .eraseToAnyPublisher()
  }
}
