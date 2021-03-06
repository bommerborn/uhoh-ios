//
//  ViewController.swift
//  Uh oh!
//
//  Created by Richard Matheson on 30/08/2014.
//  Copyright (c) 2014 Richard Matheson. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet var panicButton: UIButton!
    @IBOutlet var worryButton: UIButton!
    @IBOutlet weak var worryLabel: UILabel!
  
    var locationManager:CLLocationManager!
    var callQueue = CallQueue()
    var _inCall = false
  
    var pref:Preferences = Preferences()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func MakeCall(sender: AnyObject) {
        var speaker = AVSpeechSynthesizer()

        if callQueue.isPlaying() {
          callQueue._handler.player.stop()
        }
        worryButton.setImage(UIImage(named: "delete_message-128.png"), forState: UIControlState.Normal)
        worryLabel.text = "I'm safe"
        if !_inCall {
          self.sendBackupData("emergency")
        }
        _inCall = true
      
        callQueue.callQueue = ["", "", ""]
        callQueue.makeCalls()
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if (segue.identifier == "segueTest") {
            var svc = segue!.destinationViewController as myTableViewController2;
            svc.pref = self.pref
        }
    }
    
    
    @IBAction func Worry(sender: AnyObject) {
      if callQueue.isPlaying() {
        callQueue._handler.player.stop()
        worryButton.setImage(UIImage(named: "chat-128.png"), forState: UIControlState.Normal)
        worryLabel.text = "Talk to me"
      }
      else if _inCall {
        _inCall = false
        worryButton.setImage(UIImage(named: "chat-128.png"), forState: UIControlState.Normal)
        worryLabel.text = "Talk to me"
        self.sendBackupData("OK")
      }
      else {
        callQueue.playMP3()
        worryButton.setImage(UIImage(named: "delete_message-128.png"), forState: UIControlState.Normal)
        worryLabel.text = "I'm safe"
        self.sendBackupData("alert")
      }
    }
    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        
        CLGeocoder().reverseGeocodeLocation(manager.location, completionHandler: {(placemarks, error)->Void in
            
            if error != nil {
                println("Reverse geocoder failed with error" + error.localizedDescription)
                return
            }
            
            if placemarks.count > 0 {
                let pm = placemarks[0] as CLPlacemark
                self.pref.location = manager.location.coordinate
                self.displayLocationInfo(pm)
            } else {
                println("Problem with the data received from geocoder")
            }
        })

    }
    
    func displayLocationInfo(placemark: CLPlacemark) {
        
        //stop updating location to save battery life
        locationManager.stopUpdatingLocation()
        var res = " "
        if placemark.thoroughfare != nil {res += placemark.thoroughfare + ", "}
        if placemark.subThoroughfare != nil {res += placemark.subThoroughfare + ", "}
        if placemark.locality != nil {res += placemark.locality + ", "}
        if placemark.postalCode != nil {res += placemark.postalCode + ", "}
        if placemark.country != nil {res += placemark.country + ", "}
        
        println(placemark.thoroughfare)
        println(placemark.subThoroughfare)
        println(placemark.locality)
        println(placemark.postalCode)
        println(placemark.administrativeArea)
        println(placemark.country)
        
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("Error while updating location " + error.localizedDescription)
    }
  
    func sendBackupData(mode: String) {
        // create the request & response
        var request = NSMutableURLRequest(URL: NSURL(string: "http://uhoh.herokuapp.com/uhoh"), cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 5)
        var response: NSURLResponse?
        var error: NSError?
        var coordinate:CLLocationCoordinate2D = self.pref.location
        
        let jsonObject: AnyObject =
        [
            "mode": mode,
            "gpsCoords": [coordinate.latitude, coordinate.longitude,],
            "from": ["name": "Richard", "num": "+44"],
            "numbersToCall":
            [
                ["name": "Benno", "num": "+44"],
                ["name": "Liudas", "num": "+44"],
                ["name": "Joseph", "num": "+44"]
            ]
        ]
        func JSONStringify(jsonObj: AnyObject) -> String {
            var e: NSError?
            let jsonData: NSData! = NSJSONSerialization.dataWithJSONObject(
                jsonObj,
                options: NSJSONWritingOptions(0),
                error: &e)
            if e != nil {
                return ""
            } else {
                return NSString(data: jsonData, encoding: NSUTF8StringEncoding)
            }
        }
        let jsonString = JSONStringify(jsonObject)
        println(jsonString)
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.HTTPMethod = "POST"
        request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        
        
        // send the request
        NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
        
        // look at the response
        if let httpResponse = response as? NSHTTPURLResponse {
            println("HTTP response: \(httpResponse.statusCode)")
        } else {
            println("No HTTP response")
        }
    }
    
    func tableViewControllerDidFinish(tableViewController:myTableViewController2, preferences:Preferences) {
        pref = preferences
    }
    
    
}

