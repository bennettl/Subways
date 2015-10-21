//
//  ViewController.m
//  MapProject
//
//  Created by Bennett Lee on 10/21/15.
//  Copyright © 2015 Bennett Lee. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <AFNetworking/AFNetworking.h>

#define REUSE_IDENTIFIER @"PlaceCell"

@interface ViewController () <CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet MKMapView *myMap;
@property (strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UITextField *searchTF;
@property (nonatomic, strong) NSArray *places;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    self.places     = [[NSArray alloc] init];
    _locationManager = [[CLLocationManager alloc]init]; // initializing locationManager
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest; // setting the accuracy
    [_locationManager requestWhenInUseAuthorization]; // iOS 8 MUST
    [_locationManager startUpdatingLocation];  //requesting location updates
    
    self.myMap.showsUserLocation = YES;
}

#pragma mark - UIMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    
    [_myMap setRegion:[_myMap regionThatFits:region] animated:YES];
    
}

// When the user taps search button
- (IBAction)searchButtonDidTapped:(UIButton *)sender {
    
    AFHTTPRequestOperationManager *manager  = [AFHTTPRequestOperationManager manager];
    NSString *baseUrl                       = @"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=33.900858,-118.392212";

    NSDictionary *params = @{
                             @"key":    @"AIzaSyBJhzW_NCFarbrMBD1m70bDiYN7nvHFX84",
                             @"radius": @(10000),
                             @"types":  @"food",
                             @"name":   self.searchTF.text
                             };
    
    // Execute GET request to fetch places
    [manager GET:baseUrl parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", operation.request.URL.standardizedURL);
        
        // Convert results into formattedResults
        NSMutableArray *formattedResults = [[NSMutableArray alloc] init];
        
        for (NSDictionary *result in responseObject[@"results"]){
            NSMutableDictionary *formattedResult    = [[NSMutableDictionary alloc] init];
            NSDictionary *coor                      = result[@"geometry"][@"location"];
            formattedResult[@"lat"]                 = coor[@"lat"];
            formattedResult[@"lng"]                 = coor[@"lng"];
            formattedResult[@"title"]               = result[@"vicinity"];

            // Add to formattedResults
            [formattedResults addObject:formattedResult];
            
            // Create annotation view
            MKPointAnnotation *annotation   = [[MKPointAnnotation alloc] init];
            annotation.coordinate           =  CLLocationCoordinate2DMake([coor[@"lat"] floatValue], [coor[@"lng"] floatValue]);
            [self.myMap addAnnotation:annotation];
        }
        
        // Set places property
        self.places = formattedResults;

        // Get back on main thread to refresh table view
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            
            MKCoordinateRegion region       = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(33.900858, -118.392212), 11000, 11000);
            
            [_myMap setRegion:[_myMap regionThatFits:region] animated:YES];
        });
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark UITablviewDataSOurce

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.places.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:REUSE_IDENTIFIER];

    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE_IDENTIFIER];
    }
    
    cell.textLabel.text = self.places[indexPath.row][@"title"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *place             = self.places[indexPath.row];
    CLLocationCoordinate2D clCoor   = CLLocationCoordinate2DMake([place[@"lat"] floatValue], [place[@"lng"] floatValue]);
    MKCoordinateRegion region       = MKCoordinateRegionMakeWithDistance(clCoor, 800, 800);

    [_myMap setRegion:[_myMap regionThatFits:region] animated:YES];
}

@end
