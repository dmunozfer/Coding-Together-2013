//
//  LatestFlickrPhotosTVC.m
//  Shutterbug
//
//  Created by David Muñoz Fernández on 02/05/13.
//  Copyright (c) 2013 David Muñoz Fernández. All rights reserved.
//

#import "LatestFlickrPhotosTVC.h"
#import "FlickrFetcher.h"

@interface LatestFlickrPhotosTVC ()

@end

@implementation LatestFlickrPhotosTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadLatestPhotosFromFlickr];
    [self.refreshControl addTarget:self
                            action:@selector(loadLatestPhotosFromFlickr)
                  forControlEvents:UIControlEventValueChanged];
}

- (IBAction)loadLatestPhotosFromFlickr
{
    // start the animation if it's not already going
    [self.refreshControl beginRefreshing];
    // fork off the Flickr fetch into another thread
    dispatch_queue_t loaderQ = dispatch_queue_create("flickr latest loader", NULL);
    dispatch_async(loaderQ, ^{
        // call Flickr
        NSArray *latestPhotos = [FlickrFetcher latestGeoreferencedPhotos];
        // when we have the results, use main queue to display them
        dispatch_async(dispatch_get_main_queue(), ^{
            self.photos = latestPhotos; // makes UIKit calls, so must be main thread
            [self.refreshControl endRefreshing];  // stop the animation
        });
    });
}

@end
