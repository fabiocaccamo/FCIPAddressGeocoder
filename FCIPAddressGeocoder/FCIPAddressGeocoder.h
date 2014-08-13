//
//  FCIPAddressGeocoder.h
//
//  Created by Fabio Caccamo on 07/07/14.
//  Copyright (c) 2014 Fabio Caccamo - http://www.fabiocaccamo.com/ - All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface FCIPAddressGeocoder : NSObject
{
    NSURL *_url;
    NSURLRequest *_request;
    NSOperationQueue *_operationQueue;
    void (^_completionHandler)(BOOL success);
}

@property (nonatomic, readonly, getter = isGeocoding) BOOL geocoding;

@property (nonatomic, readonly, strong) NSError *error;

@property (nonatomic, readonly, copy) NSDictionary *locationInfo;
@property (nonatomic, readonly, copy) CLLocation *location;
@property (nonatomic, readonly, copy) NSString *locationCity;
@property (nonatomic, readonly, copy) NSString *locationCountry;
@property (nonatomic, readonly, copy) NSString *locationCountryCode;

-(id)initWithURL:(NSString *)url;

-(void)cancelGeocode;
-(void)geocode:(void(^)(BOOL success))completionHandler;

+(FCIPAddressGeocoder *)sharedGeocoder;

@end