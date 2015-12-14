//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class TravelLocationsMapViewController: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var pins: MKMapView!
    @IBOutlet weak var mapViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var longPressGesture:UILongPressGestureRecognizer!
    var selectedPin:MapPinAnnotation? = nil
    var currentPinAnnotation:MapPinAnnotation? = nil
    var editMode:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        longPressGesture = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
        
        self.pins.addGestureRecognizer(longPressGesture)
        self.pins.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
        
        self.fetchedResultsController.delegate = self
        self.mapPinAnnotations()
        self.updateConstrainsts()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.selectedPin = nil
    }
    
    @IBAction func onEdit(sender: UIBarButtonItem) {
        if self.editMode {
            self.editButton.title = "Edit"
        } else {
            self.editButton.title = "Done"
        }
        self.editMode = !self.editMode
        
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(1.0, animations: {
            self.updateConstrainsts()
            self.view.layoutIfNeeded()
        })
    }
    
    func updateConstrainsts() {
        if self.editMode {
            self.deleteViewTopConstraint.constant = -71
            self.mapViewBottomConstraint.constant = 0
            self.mapViewBottomConstraint.priority = 750+1
        } else {
            self.deleteViewTopConstraint.constant = 0
            self.mapViewBottomConstraint.constant = -71
            self.mapViewBottomConstraint.priority = 750-1
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TravelLocationsGalleryViewController" {
            if let viewController = segue.destinationViewController as? TravelLocationsGalleryViewController {
                viewController.annotation = self.selectedPin
                self.selectedPin = nil
            }
        }
    }
    
    //MARK: - CoreData
    
    lazy var fetchedResultsController:NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    var sharedContext:NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().dataStack.managedObjectContext
    }
    
    //MARK: - NSFetchedResultsControllerDelegate
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch(type) {
            
        case NSFetchedResultsChangeType.Insert :
            if let location:Pin = anObject as? Pin {
                let annotation = MapPinAnnotation(latitude: location.latitude as Double, longitude: location.longitude as Double)
                annotation.pin = location
                
                // if user tries to add the same annotation,
                // remove the existing one and add another so
                // that no error occurs...
                self.pins.removeAnnotation(annotation)
                self.pins.addAnnotation(annotation)
            }
            break
            
        case NSFetchedResultsChangeType.Delete :
            if let location:Pin = anObject as? Pin {
                for annotation in self.pins.annotations {
                    if let pin:MapPinAnnotation = annotation as? MapPinAnnotation {
                        if pin.coordinate.latitude == location.latitude && pin.coordinate.longitude == location.longitude {
                            self.pins.removeAnnotation(pin)
                        }
                    }
                }
            }
            break
            
        default:
            break
        }
    }
    
    func createPinDetail() {
        dispatch_async(dispatch_get_main_queue()) {
            
            let pin = Pin(latitude: self.currentPinAnnotation!.coordinate.latitude, longitude: self.currentPinAnnotation!.coordinate.longitude, context: self.sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            self.currentPinAnnotation!.pin = pin
            FlickrPhotoDelegate.sharedInstance().getPhotosOfThisPin(pin)
            let newPin = CLLocation(latitude: self.currentPinAnnotation!.coordinate.latitude, longitude: self.currentPinAnnotation!.coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(newPin) { location, error in
                if error == nil {
                    // must return 1 location only
                    if location!.count == 1 {
                        let pm = location!.first
                        
                        if pm!.locality != nil {
                            dispatch_async(dispatch_get_main_queue()) {
                                PinDetail(pin: pin, locality: pm!.locality!, context: self.sharedContext)
                                CoreDataStackManager.sharedInstance().saveContext()
                            }
                        } else {
                            print("createPinDetail() error : location locality is nil")
                        }
                    } else {
                        print("createPinDetail() error : reverseGeocodeLocation method returns unsuitable array of locations")
                    }
                } else {
                    print("createPinDetail() error : " + error!.localizedDescription)
                    return
                }
            }
            self.currentPinAnnotation = nil
        }
    }
    
    func createPinAnnotation(recognizer:UIGestureRecognizer) {
        let gesturePoint = recognizer.locationInView(self.pins)
        let point2BeConverted = self.pins.convertPoint(gesturePoint, toCoordinateFromView: self.pins)
        
        self.currentPinAnnotation = MapPinAnnotation(latitude: point2BeConverted.latitude, longitude: point2BeConverted.longitude)
        self.pins.addAnnotation(self.currentPinAnnotation!)
    }
    
    // MARK: - Map Annotations
    func mapPinAnnotations() {
        if let pinAnnotations = self.fetchedResultsController.fetchedObjects as? [Pin] {
            for annotation in pinAnnotations {
                let annotation2add = MapPinAnnotation(latitude: annotation.latitude as Double, longitude: annotation.longitude as Double)
                annotation2add.pin = annotation
                self.pins.addAnnotation(annotation2add)
            }
        }
    }
    
    //MARK: - Controller
    
    func handleLongPressGesture(recognizer:UIGestureRecognizer) {
        
        if (recognizer.state == UIGestureRecognizerState.Ended) {
            if self.editMode {
                return
            }
            self.createPinDetail()
            return
        } else if (recognizer.state == UIGestureRecognizerState.Changed) {
            self.changePinForDrag(recognizer)
        } else {
            self.createPinAnnotation(recognizer)
        }
        
    }
    
    func changePinForDrag(recognizer:UIGestureRecognizer) {
        let touchPoint = recognizer.locationInView(self.pins)
        let touchMapCoordinate = self.pins.convertPoint(touchPoint, toCoordinateFromView: self.pins)
        
        self.pins.removeAnnotation(self.currentPinAnnotation!)
        self.currentPinAnnotation?.coordinate = touchMapCoordinate
        self.pins.addAnnotation(self.currentPinAnnotation!)
    }

}

extension TravelLocationsMapViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MapPinAnnotation {
            let identifier = "pin"
            var view:MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if self.editMode {
            if let pinAnnotation = view as? MKPinAnnotationView {
                let annotation = pinAnnotation.annotation as! MapPinAnnotation
                //do not allow delete while fetching photos
                if !annotation.pin!.isDownloading() {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.sharedContext.deleteObject(annotation.pin!)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }
        } else {
            self.selectedPin = view.annotation as? MapPinAnnotation
            self.performSegueWithIdentifier("TravelLocationsGalleryViewController", sender: self)
        }
    }
}