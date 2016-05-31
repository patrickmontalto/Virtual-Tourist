//
//  MKMapView.swift
//  Virtual Tourist
//
//  Created by Patrick on 5/31/16.
//  Copyright © 2016 swift. All rights reserved.
//

import MapKit

// Adapted from Coderwall: removeAnnotation: animated:
extension MKMapView {
    func removeAnnotation(annotation: MKAnnotation, animated shouldAnimate: Bool) {
        // Check if we should animate the annotation removal, otherwise, animate
        if !shouldAnimate {
            self.removeAnnotation(annotation)
        }
        else {
            // Get the annotationView for the annotation (pin)
            let annotationView: MKAnnotationView = self.viewForAnnotation(annotation)!
            // Set endFrame to the current frame
            var endFrame: CGRect = annotationView.frame
            // Modify the endFrame: same X, width, and height, but change the origin y - the height of the mapView
            endFrame = CGRectMake(annotationView.frame.origin.x, annotationView.frame.origin.y - self.bounds.size.height, annotationView.frame.size.width, annotationView.frame.size.height)
            // Begin animation with a 0.3 second duration
            UIView.animateWithDuration(0.3, delay: 0.0, options: .AllowUserInteraction, animations: {() -> Void in
                // Move the annotationView's frame to the endFrame (move origin.y off screen)
                annotationView.frame = endFrame
                }, completion: {(finished: Bool) -> Void in
                    // remove annotation from mapView
                    self.removeAnnotation(annotation)
            })
        }
    }
}
