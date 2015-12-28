//
//  TravelLocationsGalleryViewController.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 06/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.

import Foundation
import UIKit
import MapKit
import CoreData

class TravelLocationsGalleryViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, FlickrDelegate, ImageLoadDelegate {
    
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noPhotosLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!

    var annotation:MapPinAnnotation!
    var selectedPhotoIndexes = [NSIndexPath]()
    
    var indexPaths2Insert: [NSIndexPath]!
    var indexPaths2Delete: [NSIndexPath]!
    var indexPaths2Update: [NSIndexPath]!
    
    var shouldFetch:Bool = false
    var activityView:VTActivityViewController?
    var recognizer:UITapGestureRecognizer!
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.recognizer = UITapGestureRecognizer(target: self, action: "tapGesture:")
        self.collectionView.addGestureRecognizer(self.recognizer)
        
        noPhotosLabel.hidden = true
        
        if FlickrPhotoDelegate.sharedInstance().isInProgress(annotation.pin!) {
            self.shouldFetch = true
            self.updateToolBar(false)
            FlickrPhotoDelegate.sharedInstance().addDelegate(annotation.pin!, delegate: self)
            self.collectionView.hidden = true
            self.activityView = VTActivityViewController()
            self.activityView?.show(self, text: "Processing...")
        } else {
            self.performFetch()
            if self.annotation.pin!.isDownloading() {
                for next in annotation.pin!.photos {
                    if let downloadWorker = PhotoQueue.sharedInstance().downloadsInProgress[next.description.hashValue] as? PhotoDownloadWorker {
                        downloadWorker.imageLoadDelegate.append(self)
                    }
                }
            } else {
                self.updateToolBar(annotation.pin!.photos.count > 0)
            }
        }
        
        if let details = self.annotation.pin!.details {
            self.navigationItem.title = details.locality
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotation(self.annotation)
        
        self.navigationItem.backBarButtonItem?.title = "Back"
        
        let region:MKCoordinateRegion = MKCoordinateRegion(center: self.annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
        self.mapView.setRegion(region, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.collectionViewLayout = getCollectionLayout()
    }
    
    //MARK: - Controller
    
    func tapGesture(recognizer:UITapGestureRecognizer) {
        if (recognizer.state != UIGestureRecognizerState.Ended) {
            return
        }
        
        let point = recognizer.locationInView(self.collectionView)
        if let indexPath = self.collectionView.indexPathForItemAtPoint(point) {
            if let cell = self.collectionView.cellForItemAtIndexPath(indexPath) as? PhotoCell {
                if let photo = cell.photo {
                    dispatch_async(dispatch_get_main_queue()) {
                        photo.pin = nil
                        photo.image = nil
                        self.sharedContext.deleteObject(photo)
                        dispatch_async(dispatch_get_main_queue()) {
                            CoreDataManager.sharedInstance().saveContext()
                        }
                    }
                }
            }
        }
    }
    
    func getCollectionLayout() -> UICollectionViewFlowLayout {
        let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        return layout
    }
    
    func didFinishSearchingPinPhotos(success: Bool, pin: Pin, photos: [Photo]?, errorString:String?, context: NSManagedObjectContext) {
        for next in annotation.pin!.photos {
            if let downloadWorker = PhotoQueue.sharedInstance().downloadsInProgress[next.description.hashValue] as? PhotoDownloadWorker {
                downloadWorker.imageLoadDelegate.append(self)
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            let noPhotos = self.annotation.pin!.photos.count == 0
            self.noPhotosLabel.hidden = !noPhotos
            self.activityView?.closeView()
            self.activityView = nil
            self.collectionView.hidden = false
            if (self.shouldFetch) {
                self.shouldFetch = false
                self.performFetch()
            }
            
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.view.layoutIfNeeded()
            if (photos?.count > 0) {
                UIView.animateWithDuration(1.0, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    func updateToolBar(enabled:Bool) {
        self.newCollectionButton.enabled = enabled
    }
    
    @IBAction func newCollection(sender: UIBarButtonItem) {
        for photo in self.annotation.pin!.photos {
            dispatch_async(dispatch_get_main_queue()) {
                photo.pin = nil
                photo.image = nil
                self.sharedContext.deleteObject(photo)
            }
        }
        self.searchPhotosForLocation()
        CoreDataManager.sharedInstance().saveContext()
    }
    
    func searchPhotosForLocation() {
        FlickrPhotoDelegate.sharedInstance().getPhotosOfThisPin(self.annotation.pin!)
        self.collectionView.hidden = true
        self.newCollectionButton.enabled = false;
        self.view.layoutIfNeeded()
        self.updateToolBar(false)
        FlickrPhotoDelegate.sharedInstance().addDelegate(annotation.pin!, delegate: self)
        self.activityView = VTActivityViewController()
        self.activityView?.show(self, text: "Processing...")
        
    }
    
    //MARK: - Image Load Delegate
    
    func progress(progress:CGFloat) {
        //do nothings
    }
    
    func didFinishLoad() {
        let downloading = self.annotation.pin!.isDownloading()
        dispatch_async(dispatch_get_main_queue()) {
            self.updateToolBar(!downloading)
        }
    }
    
    //MARK: - Configure Cell
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath:NSIndexPath) {
        let photo = self.fetchedResultsViewController.objectAtIndexPath(indexPath) as! Photo
        
        cell.photo = photo
    }
    
    //MARK: - CoreData
    
    lazy var fetchedResultsViewController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imagePath", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.annotation.pin!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: "photos")
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    lazy var sharedContext:NSManagedObjectContext = {
        return CoreDataManager.sharedInstance().managedObjectContext!
    }()
    
    private func performFetch() {
        var error:NSError?
        NSFetchedResultsController.deleteCacheWithName("photos")
        
        do {
            try self.fetchedResultsViewController.performFetch()
        } catch let performFetchError as NSError {
            error = performFetchError
        }
        
        let sectionNumber = self.fetchedResultsViewController.sections!.first!
        
        if sectionNumber.numberOfObjects == 0 {
            noPhotosLabel.hidden = self.activityView == nil ? false : true
            collectionView.hidden = true
        } else {
            noPhotosLabel.hidden = true
            collectionView.hidden = false
        }
    }
    
    //MARK: - UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // if section count is nil then return 0 otherwise return section count
        return self.fetchedResultsViewController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsViewController.sections![section]
        
        if let photos = self.annotation!.pin?.photos where photos.count == 0 && self.isViewLoaded() && self.view.window != nil && self.newCollectionButton.enabled && !FlickrPhotoDelegate.sharedInstance().isInProgress(annotation.pin!) {
            noPhotosLabel.hidden = false
            collectionView.hidden = true
            dispatch_async(dispatch_get_main_queue()) {
                self.searchPhotosForLocation()
            }
        }
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        indexPaths2Insert = [NSIndexPath]()
        indexPaths2Delete = [NSIndexPath]()
        indexPaths2Update = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            self.indexPaths2Insert.append(newIndexPath!)
            break
        case .Delete:
            self.indexPaths2Delete.append(indexPath!)
            break
        case .Update:
            self.indexPaths2Delete.append(indexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.collectionView.performBatchUpdates({() -> Void in
            
            if self.indexPaths2Insert.count > 0 {
                self.collectionView.insertItemsAtIndexPaths(self.indexPaths2Insert)
            }
            if self.indexPaths2Delete.count > 0 {
                self.collectionView.deleteItemsAtIndexPaths(self.indexPaths2Delete)
            }
            if self.indexPaths2Update.count > 0 {
                self.collectionView.reloadItemsAtIndexPaths(self.indexPaths2Update)
            }
            
            }, completion: nil)
    }
}