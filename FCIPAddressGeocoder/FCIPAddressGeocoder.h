//
//  FCIPAddressGeocoder.h
//
//  Created by Fabio Caccamo on 07/07/14.
//  Copyright (c) 2014 Fabio Caccamo - http://www.fabiocaccamo.com/ - All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef enum : NSUInteger {
    FCIPAddressGeocoderServiceFreeGeoIP,
    FCIPAddressGeocoderServicePetabyet,
    FCIPAddressGeocoderServiceSmartIP,
    FCIPAddressGeocoderServiceTelize
    
} FCIPAddressGeocoderService;

@interface FCIPAddressGeocoder : NSObject
{
    FCIPAddressGeocoderService _service;
    NSURL *_serviceURL;
    NSURLRequest *_serviceRequest;
    NSMutableSet *_servicesQueue;
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

@property (nonatomic) BOOL canUseOtherServicesAsFallback;

-(void)cancelGeocode;
-(void)geocode:(void(^)(BOOL success))completionHandler;

-(id)initWithService:(FCIPAddressGeocoderService)service;
-(id)initWithService:(FCIPAddressGeocoderService)service andURL:(NSString *)url;

+(void)setDefaultService:(FCIPAddressGeocoderService)service;
+(void)setDefaultService:(FCIPAddressGeocoderService)service andURL:(NSString *)url;

+(FCIPAddressGeocoder *)sharedGeocoder;

@end