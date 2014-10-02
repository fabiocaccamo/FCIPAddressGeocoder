//
//  FCIPAddressGeocoder.m
//
//  Created by Fabio Caccamo on 07/07/14.
//  Copyright (c) 2014 Fabio Caccamo - http://www.fabiocaccamo.com/ - All rights reserved.
//

#import "FCIPAddressGeocoder.h"

@implementation FCIPAddressGeocoder : NSObject


static FCIPAddressGeocoderService const kDefaultService = FCIPAddressGeocoderServiceFreeGeoIP;

static NSString *const kDefaultServiceURLForFreeGeoIP = @"http://freegeoip.net/json/";
static NSString *const kDefaultServiceURLForPetabyet = @"http://api.petabyet.com/geoip/";
static NSString *const kDefaultServiceURLForSmartIP = @"http://smart-ip.net/geoip-json/";
static NSString *const kDefaultServiceURLForTelize = @"http://www.telize.com/geoip/";

static FCIPAddressGeocoderService customDefaultService;
static NSString *customDefaultServiceURL = nil;


+(NSString *)getDefaultServiceURLForService:(FCIPAddressGeocoderService)service
{
    NSString *url = nil;
    
    switch (service)
    {
        case FCIPAddressGeocoderServiceFreeGeoIP:
            
            url = kDefaultServiceURLForFreeGeoIP;
            
            break;
            
        case FCIPAddressGeocoderServicePetabyet:
            
            url = kDefaultServiceURLForPetabyet;
            
            break;
            
        case FCIPAddressGeocoderServiceSmartIP:
            
            url = kDefaultServiceURLForSmartIP;
            
            break;
            
        case FCIPAddressGeocoderServiceTelize:
            
            url = kDefaultServiceURLForTelize;
            
            break;
            
        default:
            
            break;
    }
    
    return url;
}


+(void)setDefaultService:(FCIPAddressGeocoderService)service
{
    [self setDefaultService:service andURL:[self getDefaultServiceURLForService:service]];
}


+(void)setDefaultService:(FCIPAddressGeocoderService)service andURL:(NSString *)url
{
    NSAssert([self sharedGeocoderLazy:YES] == nil, @"default service/url cannot be set after having called the shared instance.");
    NSAssert(url != nil, @"default service url cannot be nil.");
    NSAssert(customDefaultServiceURL == nil, @"default service/url can only be set once.");
    
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        customDefaultService = service;
        customDefaultServiceURL = [url copy];
    });
}


+(FCIPAddressGeocoder *)sharedGeocoder
{
    return [self sharedGeocoderLazy:NO];
}


+(FCIPAddressGeocoder *)sharedGeocoderLazy:(BOOL)lazy
{
    static FCIPAddressGeocoder *instance = nil;
    static dispatch_once_t token;
    
    if(!lazy)
    {
        dispatch_once(&token, ^{
            instance = [[self alloc] init];
        });
    }
    
    return instance;
}


-(id)init
{
    FCIPAddressGeocoderService service = (customDefaultService ? customDefaultService : kDefaultService);
    NSString *serviceURL = (customDefaultServiceURL ? customDefaultServiceURL : [FCIPAddressGeocoder getDefaultServiceURLForService:service]);
    
    self = [self initWithService:service andURL:serviceURL];
    self.canUseOtherServicesAsFallback = YES;
    return self;
}


-(id)initWithService:(FCIPAddressGeocoderService)service
{
    return [self initWithService:service andURL:[FCIPAddressGeocoder getDefaultServiceURLForService:service]];
}


-(id)initWithService:(FCIPAddressGeocoderService)service andURL:(NSString *)url
{
    self = [super init];
    
    if( self )
    {
        [self setService:service andURL:url];
        
        _servicesQueue = [[NSMutableSet alloc] init];
        [_servicesQueue addObject:[NSNumber numberWithInteger:FCIPAddressGeocoderServiceFreeGeoIP]];
        [_servicesQueue addObject:[NSNumber numberWithInteger:FCIPAddressGeocoderServicePetabyet]];
        [_servicesQueue addObject:[NSNumber numberWithInteger:FCIPAddressGeocoderServiceSmartIP]];
        [_servicesQueue addObject:[NSNumber numberWithInteger:FCIPAddressGeocoderServiceTelize]];
        [_servicesQueue removeObject:[NSNumber numberWithInteger:_service]];
        
        _operationQueue = [NSOperationQueue new];
        
        //by default can retry using another service only if url is equal to the default service url (not a custom url)
        //_canUseOtherServicesAsFallback = [url isEqualToString:[FCIPAddressGeocoder getDefaultServiceURLForService:_service]];
        _canUseOtherServicesAsFallback = NO;
    }
    
    return self;
}


-(void)setService:(FCIPAddressGeocoderService)service andURL:(NSString *)url
{
    NSAssert(url != nil, @"service url cannot be nil.");
    
    _service = service;
    _serviceURL = [NSURL URLWithString:url];
    _serviceRequest = [NSURLRequest requestWithURL:_serviceURL];
}


-(void)cancelGeocode
{
    [_operationQueue cancelAllOperations];
    
    _completionHandler = nil;
    
    _geocoding = NO;
    
    _error = nil;
    
    _locationInfo = nil;
    _location = nil;
    _locationCity = nil;
    _locationCountry = nil;
    _locationCountryCode = nil;
}


-(void)geocode:(void (^)(BOOL))completionHandler
{
    if( _location != nil && [[_location.timestamp dateByAddingTimeInterval:60] timeIntervalSinceNow] > 0 )
    {
        if( completionHandler ){
            completionHandler( YES );
            
            return;
        }
    }
    
    [self cancelGeocode];
    
    _completionHandler = completionHandler;
    
    _geocoding = YES;
    
    //NSLog(@"geocode using service url: %@", [FCIPAddressGeocoder getDefaultServiceURLForService:_service]);
    
    [NSURLConnection sendAsynchronousRequest:_serviceRequest queue:_operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if( connectionError == nil )
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if( httpResponse.statusCode == 200 )
            {
                NSError *JSONError = nil;
                NSDictionary *JSONData = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&JSONError];
                
                if( JSONError == nil )
                {
                    _locationInfo = JSONData;
                    
                    CLLocationDegrees latitude = [[_locationInfo objectForKey:@"latitude"] doubleValue];
                    CLLocationDegrees longitude = [[_locationInfo objectForKey:@"longitude"] doubleValue];
                    
                    _location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                    
                    switch (_service)
                    {
                        case FCIPAddressGeocoderServiceFreeGeoIP:
                            
                            _locationCity = [_locationInfo objectForKey:@"city"];
                            _locationCountry = [_locationInfo objectForKey:@"country_name"];
                            _locationCountryCode = [_locationInfo objectForKey:@"country_code"];
                            
                            break;
                            
                        case FCIPAddressGeocoderServicePetabyet:
                            
                            _locationCity = [_locationInfo objectForKey:@"city"];
                            _locationCountry = [_locationInfo objectForKey:@"country"];
                            _locationCountryCode = [_locationInfo objectForKey:@"country_code"];
                            
                            break;
                            
                        case FCIPAddressGeocoderServiceSmartIP:
                            
                            _locationCity = [_locationInfo objectForKey:@"city"];
                            _locationCountry = [_locationInfo objectForKey:@"countryName"];
                            _locationCountryCode = [_locationInfo objectForKey:@"countryCode"];
                            
                            break;
                            
                        case FCIPAddressGeocoderServiceTelize:
                            
                            //_locationCity = nil;
                            _locationCountry = [_locationInfo objectForKey:@"country"];
                            _locationCountryCode = [_locationInfo objectForKey:@"country_code"];
                            
                            break;
                            
                        default:
                            
                            break;
                    }
                            
                }
                else {
                    _error = JSONError;
                    //NSLog(@"JSON error");
                }
            }
            else {
                _error = [NSError errorWithDomain:@"" code:kCLErrorNetwork userInfo:nil];
                //NSLog(@"httpResponse.statusCode error (%i)\nMaybe the service is unavailable due to maintenance or high load. Check it: http://freegeoip.net/", httpResponse.statusCode);
            }
        }
        else {
            _error = connectionError;
            //NSLog(@"connection error");
        }
        
        if( _error != nil && _canUseOtherServicesAsFallback && [_servicesQueue count] > 0 )
        {
            NSNumber *serviceKey = (NSNumber *)[[_servicesQueue allObjects] firstObject];
            [_servicesQueue removeObject:serviceKey];
            
            FCIPAddressGeocoderService service = [serviceKey integerValue];
            NSString *serviceURL = [FCIPAddressGeocoder getDefaultServiceURLForService:service];
            
            [self setService:service andURL:serviceURL];
            [self geocode:_completionHandler];
        }
        else {
            
            _geocoding = NO;
            
            if( _completionHandler )
            {
                _completionHandler( _error == nil );
            }
        }
    }];
}


@end
