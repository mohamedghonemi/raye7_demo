//
//  googleServices.swift
//  Rae7Demo
//
//  Created by Developer on 7/13/17.
//  Copyright © 2017 Ebda3. All rights reserved.
//

import UIKit
import PromiseKit
import GooglePlaces
import GoogleMaps

class GoogleServices: NSObject {
    
    private static let webApiKey = "AIzaSyDAQHsJF-Mq-5Ij2i2aSxscwwIVgw1kJdA"
    private static let iosApiKey = "AIzaSyD5LJT2xQnqV0amr-H-zwz0ypGeBYYtdAQ"
    
    /// This must be called before any other call to the services.
    static func initializeKeys() {
        // Override point for customization after application launch.
        GMSServices.provideAPIKey(iosApiKey)
        GMSPlacesClient.provideAPIKey(iosApiKey)
    }

    static func getPlaceInfo(for placeID: String) -> Promise<GMSPlace?> {
        return Promise { fulfill, reject in
            GMSPlacesClient.shared().lookUpPlaceID(placeID, callback: { (place, error) -> Void in
                if let error = error {
                    print("lookup place id query error: \(error.localizedDescription)")
                    reject(NSError(domain: "", code: 0, userInfo: nil))
                }
                
                if let place = place {
                    fulfill(place)
                } else {
                    print("No place details for \(String(describing: placeID))")
                    reject(NSError(domain: "", code: 0, userInfo: nil))
                    
                }
            })
        }
    }
    
    static func drawRouteBetweenTwoLocations(in googleMapView: GMSMapView, firstLocation: GMSPlace, secondLocation: GMSPlace) -> Promise<Bool> {
        return Promise { fulfill, reject in
            
            let firstMarker = GMSMarker(position: firstLocation.coordinate)
            firstMarker.title = firstLocation.name
            firstMarker.map = googleMapView
            //
            let secondMarker = GMSMarker(position: secondLocation.coordinate)
            secondMarker.title = secondLocation.name
            secondMarker.map = googleMapView
            //
            let directionsAPI = PXGoogleDirections(apiKey: webApiKey,
                                                   from: PXLocation.coordinateLocation(firstLocation.coordinate),
                                                   to: PXLocation.coordinateLocation(secondLocation.coordinate))
            
            directionsAPI.calculateDirections({ response in
                switch response {
                case let .error(_, error):
                    // Oops, something bad happened, see the error object for more information
                    print(error)
                    reject(error)
                    break
                case let .success(_, routes):
                    // Do your work with the routes object array here
                    if let path = routes[0].path  {
                        let signleLine = GMSPolyline(path: path)
                        signleLine.map = googleMapView
                        //
                        //Fit map to the path
                        var bounds = GMSCoordinateBounds()
                        
                        for index in 0...path.count() {
                            bounds = bounds.includingCoordinate(path.coordinate(at: index))
                        }
                        
                        googleMapView.animate(with: GMSCameraUpdate.fit(bounds))
                        fulfill(true)
                        break
                    }
                }
            })
        }
    }

}
