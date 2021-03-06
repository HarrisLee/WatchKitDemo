//
//  ViewController.m
//  WatchKitDemo
//
//  Created by Chris Beauchamp on 3/25/15.
//  Copyright (c) 2015 Crittercism. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "ViewController.h"

#import "Crittercism.h"

@interface ViewController ()

// make sure we conform to the location delegate
<CLLocationManagerDelegate>

// if we are currently tracking location
@property (nonatomic, assign) BOOL tracking;

// our location manager
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ViewController

- (NSDictionary*) getSerializedLocation
{
    // get the latest location from our GPS
    CLLocation *location = _locationManager.location;
    
    // extract the coordinate
    CLLocationCoordinate2D coordinate = location.coordinate;
    
    // return a serialized dictionary with the current location attributes
    return @{
             @"latitude":   [NSNumber numberWithDouble:coordinate.latitude],
             @"longitude":  [NSNumber numberWithDouble:coordinate.longitude],
             @"altitude":   [NSNumber numberWithDouble:location.altitude],
             @"speed":      [NSNumber numberWithDouble:location.speed]
             };
}

#pragma mark - Setters

// we override the setter here to make it easier to align our variable w/
// our button status
- (void) setTracking:(BOOL)tracking
{
    _tracking = tracking;
    
    NSString *title = _tracking ? @"Stop Tracking Location" : @"Start Tracking Location";
    [_trackLocationButton setTitle:title forState:UIControlStateNormal];
    
    // leave a breadcrumb to help debug any issues
    [Crittercism leaveBreadcrumb:[NSString stringWithFormat:@"Tracking set to: %d", _tracking]];
}

#pragma mark - View Methods

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up our persistent location manager
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    
    // leave a breadcrumb to verify we completed the viewDidLoad
    [Crittercism leaveBreadcrumb:@"ViewController didLoad"];
}

#pragma mark - Location Delegates

- (void) locationManager:(CLLocationManager *)manager
        didFailWithError:(NSError *)error
{
    // print the error to log
    NSLog(@"Error retrieving location: %@", error);

    // Log the error with Crittercism so you can spot it remotely
    [Crittercism logError:error];
}

- (void) locationManager:(CLLocationManager*)manager
     didUpdateToLocation:(CLLocation*)newLocation
            fromLocation:(CLLocation*)oldLocation
{
    // update our labels with the info from the new location
    _latitudeLabel.text = [NSString stringWithFormat:@"%g", newLocation.coordinate.latitude];
    _longitudeLabel.text = [NSString stringWithFormat:@"%g", newLocation.coordinate.longitude];
    _altitudeLabel.text = [NSString stringWithFormat:@"%g", newLocation.altitude];
    _speedLabel.text = [NSString stringWithFormat:@"%g", newLocation.speed];
}


- (void) locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // print to console
    NSLog(@"Location authorization status changed: %d", status);
    
    // leave a breadcrumb to help debug any issues remotely
    [Crittercism leaveBreadcrumb:[NSString stringWithFormat:@"Location authorization status changed: %d", status]];

    // if we are not authorized, stop tracking (in case we were)
    if(status < kCLAuthorizationStatusAuthorizedAlways) {
        self.tracking = FALSE;
        [_locationManager stopUpdatingLocation];
    }
    
    // we are authorized, go ahead and start tracking
    else {
        self.tracking = TRUE;
        [_locationManager startUpdatingLocation];
    }
}

# pragma mark - Interface Actions

- (IBAction)toggleLocationTracking:(id)sender {
    
    // check to see if we have access yet
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        
        // we don't, so ask the user for it
        if([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_locationManager requestAlwaysAuthorization];
        }
        
        // (same thing as the if-statement, just geared toward different API versions)
        else {
            self.tracking = TRUE;
            [_locationManager startUpdatingLocation];
        }
    }
    
    // the user denied it or shut it off via settings
    else if([CLLocationManager authorizationStatus] < kCLAuthorizationStatusAuthorizedAlways) {
        
        // tell the user to go to settings
        NSString *msg = @"Location access is not available. Ensure your Location Services are on and go to your iPhone Settings > Privacy > Location Services and find this app. Make sure the 'Allow Location Access' is set to 'Always'";
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:msg
                                   delegate:nil
                          cancelButtonTitle:@"Okay"
                          otherButtonTitles:nil] show];
    }
    
    // we have access, fire it
    else {
        
        // if we're already tracking, shut it down
        if(self.tracking) {
            [_locationManager stopUpdatingLocation];
        }
        
        // otherwise, turn it on
        else {
            [_locationManager startUpdatingLocation];
        }
        
        // toggle our variable to keep track
        self.tracking = !self.tracking;
    }
    
}

@end
