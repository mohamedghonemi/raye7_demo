//
//  ViewController.swift
//  Rae7Demo
//
//  Created by Developer on 7/10/17.
//  Copyright © 2017 Ebda3. All rights reserved.
//

import UIKit
import GoogleMaps
import MapKit
import PromiseKit
import Alamofire

import GooglePlaces

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    
    @IBOutlet weak var googleMapView: GMSMapView!
    
    var fromAutocompleteView: LUAutocompleteView! = nil
    var toAutocompleteView: LUAutocompleteView! = nil
        
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var goButton: UIButton!
    
    var fetcher: GMSAutocompleteFetcher?
    var placesClient = GMSPlacesClient()
    
    var searchResults = [GMSAutocompletePrediction]()
    var fromPrediction: GMSAutocompletePrediction? = nil
    var toPrediction: GMSAutocompletePrediction? = nil
    
    var currentLocation: CLLocation? = nil
    
    var currentTextField: UITextField? = nil
    
    func initializeAddressSearch() {
        let neBoundsCorner = CLLocationCoordinate2D(latitude: 50,
                                                    longitude: 50)
        let swBoundsCorner = CLLocationCoordinate2D(latitude: 20,
                                                    longitude: 20)
        let bounds = GMSCoordinateBounds(coordinate: neBoundsCorner,
                                         coordinate: swBoundsCorner)
        
        // Set up the autocomplete filter.
        let filter = GMSAutocompleteFilter()
        filter.type = .noFilter
        
        // Create the fetcher.
        fetcher = GMSAutocompleteFetcher(bounds: bounds, filter: filter)
        fetcher?.delegate = self
    }
    
    func setupGoogleMap(with location:CLLocationCoordinate2D) {
        // Create a GMSCameraPosition that tells the map to display the
        let camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: 6.0)
        googleMapView.camera = camera
        
        // Creates a marker in the center of the map.
//        let marker = GMSMarker()
//        marker.position = location
//        marker.map = googleMapView
    }
    
    func initializeUI() {
        toTextField.delegate = self
        fromTextField.delegate = self
        //
        fromAutocompleteView = LUAutocompleteView()
        fromAutocompleteView.isAutoUpdated = false
        view.addSubview(fromAutocompleteView)
        
        fromAutocompleteView.textField = fromTextField
        fromAutocompleteView.dataSource = self
        fromAutocompleteView.delegate = self
        
        //
        toAutocompleteView = LUAutocompleteView()
        toAutocompleteView.isAutoUpdated = false
        view.addSubview(toAutocompleteView)
        
        toAutocompleteView.textField = toTextField
        toAutocompleteView.dataSource = self
        toAutocompleteView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        initializeUI()
        //
        indicator.isHidden = false
        //Request location authorization
        _ = CLLocationManager.requestAuthorization().then { status in
            return  CLLocationManager.promise()
            }.then { location -> Void in
                //Update the local
                self.currentLocation = location
                self.setupGoogleMap(with: location.coordinate)
                
            }.catch { error in
                //Handle error here
            }.always {
                self.indicator.stopAnimating()
        }
        
        initializeAddressSearch()
    }
    
    
    @IBAction func goAction(_ sender: Any) {
        //Remove old markers
        googleMapView.clear()
        //
        if let fromPrediction = fromPrediction, let toPrediction = toPrediction {
            indicator.startAnimating()
            //Get the details of places
            //Here I use "when" function from promisekit, it ensure that both promises are executed before returning
            when(resolved: GoogleServices.getPlaceInfo(for: fromPrediction.placeID!), GoogleServices.getPlaceInfo(for: toPrediction.placeID!)).then { results -> Promise<Bool> in
                
                var firstPlace: GMSPlace? = nil
                var secondPlace: GMSPlace? = nil
                
                //The results is array of two Result object, one for each promise
                switch results[0] {
                    case .fulfilled(let value):
                        firstPlace = value
                        break
                    case .rejected:
                        break
                }
                switch results[1] {
                    case .fulfilled(let value):
                        secondPlace = value
                        break
                    case .rejected:
                        break
                }
                
                if firstPlace != nil && secondPlace != nil {
                    return GoogleServices.drawRouteBetweenTwoLocations(in: self.googleMapView, firstLocation: firstPlace!, secondLocation: secondPlace!)
                } else {
                    return Promise(error: NSError(domain: "", code: 0, userInfo: nil))
                }
                }.then { result -> Void in
                    
                }.catch { error in
                    //Handle Error here
                }.always {
                    //Hide activity
                    self.indicator.stopAnimating()
            }
          }
    }
    
    ///Used to get the address search results of the typed text
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        currentTextField = textField
        fetcher?.sourceTextHasChanged(textField.text!)
        return true
    }
}

// MARK: - GMSAutocompleteFetcherDelegate methods

extension ViewController: GMSAutocompleteFetcherDelegate {
    func didAutocomplete(with predictions: [GMSAutocompletePrediction]) {
        let resultsStr = NSMutableString()
        searchResults.removeAll()
        for prediction in predictions {
            resultsStr.appendFormat("%@\n", prediction.attributedPrimaryText)
            searchResults.append(prediction)
        }
        if currentTextField == fromTextField {
            fromAutocompleteView.reloadList()
        } else {
            toAutocompleteView.reloadList()
        }
    }
    
    func didFailAutocompleteWithError(_ error: Error) {
        print(error.localizedDescription)
        searchResults.removeAll()
    }
}

// MARK: - LUAutocompleteViewDataSource

extension ViewController: LUAutocompleteViewDataSource {
    func autocompleteView(_ autocompleteView: LUAutocompleteView, elementsFor text: String, completion: @escaping ([String]) -> Void) {
        let elementsThatMatchInput = searchResults.filter { $0.attributedPrimaryText.string.lowercased().contains(text.lowercased())}.map {$0.attributedPrimaryText.string}
        completion(elementsThatMatchInput)
    }
}

// MARK: - LUAutocompleteViewDelegate

extension ViewController: LUAutocompleteViewDelegate {
    
    func autocompleteView(_ autocompleteView: LUAutocompleteView, didSelect index: Int) {
        if currentTextField == fromTextField {
            fromPrediction = searchResults[index]
        } else {
            toPrediction = searchResults[index]
        }
    }
    
}

