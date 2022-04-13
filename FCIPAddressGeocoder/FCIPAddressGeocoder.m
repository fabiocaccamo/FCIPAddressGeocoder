//
//  FCIPAddressGeocoder.m
//
//  Created by Fabio Caccamo on 07/07/14.
//  Copyright (c) 2014-present, Fabio Caccamo - fabio.caccamo@gmail.com - https://fabiocaccamo.com/ - All rights reserved.
//

#import "FCIPAddressGeocoder.h"

@implementation FCIPAddressGeocoder : NSObject


static FCIPAddressGeocoderService const kDefaultService = FCIPAddressGeocoderServiceFreeGeoIP;

static NSString *const kDefaultServiceURLForAbstractAPI = @"https://ipgeolocation.abstractapi.com/v1/?api_key=6b61e693a91649348c591a976478e61c";
static NSString *const kDefaultServiceURLForFreeGeoIP = @"https://freegeoip.live/json/";
static NSString *const kDefaultServiceURLForCDNService = @"https://geoip.cdnservice.eu/api/";
static NSString *const kDefaultServiceURLForIPInfo = @"https://ipinfo.io/json/";

static FCIPAddressGeocoderService customDefaultService;
static NSString *customDefaultServiceURL = nil;


+(NSString *)getDefaultServiceURLForService:(FCIPAddressGeocoderService)service
{
    NSString *url = nil;

    switch (service)
    {
        case FCIPAddressGeocoderServiceAbstractAPI:
            url = kDefaultServiceURLForAbstractAPI;
            break;

        case FCIPAddressGeocoderServiceFreeGeoIP:
            url = kDefaultServiceURLForFreeGeoIP;
            break;

        case FCIPAddressGeocoderServiceCDNService:
            url = kDefaultServiceURLForCDNService;
            break;

        case FCIPAddressGeocoderServiceIPInfo:
            url = kDefaultServiceURLForIPInfo;
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

    if (!lazy) {
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

    if (self) {
        [self setService:service andURL:url];

        _servicesQueue = [[NSMutableSet alloc] init];
        [_servicesQueue addObject:[NSNumber numberWithInteger:FCIPAddressGeocoderServiceAbstractAPI]];
        [_servicesQueue addObject:[NSNumber numberWithInteger:FCIPAddressGeocoderServiceFreeGeoIP]];
        [_servicesQueue addObject:[NSNumber numberWithInteger:FCIPAddressGeocoderServiceIPInfo]];
        [_servicesQueue addObject:[NSNumber numberWithInteger:FCIPAddressGeocoderServiceCDNService]];
        [_servicesQueue removeObject:[NSNumber numberWithInteger:_service]];

        _operationQueue = [NSOperationQueue new];

        // by default can retry using another service only if url is equal to the default service url (not a custom url)
        // _canUseOtherServicesAsFallback = [url isEqualToString:[FCIPAddressGeocoder getDefaultServiceURLForService:_service]];
        _canUseOtherServicesAsFallback = NO;
    }

    return self;
}


-(void)setService:(FCIPAddressGeocoderService)service andURL:(NSString *)url
{
    NSAssert(url != nil, @"service url cannot be nil.");

    _service = service;
    _serviceTimeoutInterval = 10;
    _serviceURL = [NSURL URLWithString:url];
    _serviceRequest = [NSURLRequest requestWithURL:_serviceURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:_serviceTimeoutInterval];
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
    if (_location != nil && [[_location.timestamp dateByAddingTimeInterval:60] timeIntervalSinceNow] > 0) {
        if (completionHandler) {
            completionHandler(YES);

            return;
        }
    }

    [self cancelGeocode];

    _completionHandler = completionHandler;

    _geocoding = YES;

    //NSLog(@"geocode using service url: %@", [FCIPAddressGeocoder getDefaultServiceURLForService:_service]);
    [NSURLConnection sendAsynchronousRequest:_serviceRequest queue:_operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

        if (connectionError == nil) {

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            if (httpResponse.statusCode == 200) {

                NSError *JSONError = nil;
                NSDictionary *JSONData = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&JSONError];

                if (JSONError == nil) {

                    NSDictionary *data = JSONData;
                    NSNumber *dataLatitude = nil;
                    NSNumber *dataLongitude = nil;
                    NSString *dataIP = nil;
                    NSString *dataCity = nil;
                    NSString *dataCountry = nil;
                    NSString *dataCountryCode = nil;

                    switch (self->_service)
                    {
                        case FCIPAddressGeocoderServiceAbstractAPI: {

                            dataIP = [data objectForKey:@"ip_address"];
                            dataLatitude = [data objectForKey:@"latitude"];
                            dataLongitude = [data objectForKey:@"longitude"];
                            dataCity = [data objectForKey:@"city"];
                            dataCountry = [data objectForKey:@"country"];
                            dataCountryCode = [data objectForKey:@"country_code"];

                            break;
                        }
                        case FCIPAddressGeocoderServiceFreeGeoIP: {

                            dataIP = [data objectForKey:@"ip"];
                            dataLatitude = [data objectForKey:@"latitude"];
                            dataLongitude = [data objectForKey:@"longitude"];
                            dataCity = [data objectForKey:@"city"];
                            dataCountry = [data objectForKey:@"country_name"];
                            dataCountryCode = [data objectForKey:@"country_code"];

                            break;
                        }
                        case FCIPAddressGeocoderServiceCDNService: {

                            dataIP = [data objectForKey:@"ip"];
                            dataLatitude = [[data objectForKey:@"location"] objectForKey:@"latitude"];
                            dataLongitude = [[data objectForKey:@"location"] objectForKey:@"longitude"];
                            dataCity = [data objectForKey:@"city"];
                            dataCountry = [[data objectForKey:@"country"] objectForKey:@"name"];
                            dataCountryCode = [[data objectForKey:@"country"] objectForKey:@"code"];

                            break;
                        }
                        case FCIPAddressGeocoderServiceIPInfo: {

                            dataIP = [data objectForKey:@"ip"];
                            NSString *dataLocation = [data objectForKey:@"loc"];
                            NSArray *dataCoords = [dataLocation componentsSeparatedByString:@","];
                            dataLatitude = [NSNumber numberWithFloat:[dataCoords[0] floatValue]];
                            dataLongitude = [NSNumber numberWithFloat:[dataCoords[1] floatValue]];
                            dataCity = [data objectForKey:@"city"];
                            dataCountryCode = [data objectForKey:@"country"];
                            dataCountry = [[NSLocale systemLocale] displayNameForKey:NSLocaleCountryCode value:dataCountryCode];

                            break;
                        }
                        default: {

                            break;
                        }
                    }

                    CLLocationDegrees latitude = [dataLatitude doubleValue];
                    CLLocationDegrees longitude = [dataLongitude doubleValue];

                    self->_location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                    self->_locationCity = dataCity;
                    self->_locationCountry = dataCountry;
                    self->_locationCountryCode = dataCountryCode;

                    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];

                    if (data != nil) {
                        [info setObject:data forKey:@"raw"];
                    }
                    if (dataIP != nil) {
                        [info setObject:dataIP forKey:@"ip"];
                    }
                    if (dataLatitude != nil) {
                        [info setObject:dataLatitude forKey:@"latitude"];
                    }
                    if (dataLongitude != nil) {
                        [info setObject:dataLongitude forKey:@"longitude"];
                    }
                    if (dataCity != nil) {
                        [info setObject:dataCity forKey:@"city"];
                    }
                    if (dataCountry != nil) {
                        [info setObject:dataCountry forKey:@"country"];
                    }
                    if (dataCountryCode != nil) {
                        [info setObject:dataCountryCode forKey:@"countryCode"];
                    }

                    self->_locationInfo = [NSDictionary dictionaryWithDictionary:info];
                }
                else {
                    self->_error = JSONError;
                    //NSLog(@"JSON error");
                }
            }
            else {
                self->_error = [NSError errorWithDomain:@"" code:kCLErrorNetwork userInfo:nil];
            }
        }
        else {
            self->_error = connectionError;
            //NSLog(@"connection error: %@", _error.localizedDescription);
        }

        if (self->_error != nil && self->_canUseOtherServicesAsFallback && [self->_servicesQueue count] > 0) {

            NSNumber *serviceKey = (NSNumber *)[[self->_servicesQueue allObjects] objectAtIndex:0];
            [self->_servicesQueue removeObject:serviceKey];

            FCIPAddressGeocoderService service = [serviceKey integerValue];
            NSString *serviceURL = [FCIPAddressGeocoder getDefaultServiceURLForService:service];

            [self setService:service andURL:serviceURL];
            [self geocode:self->_completionHandler];
        }
        else {
            self->_geocoding = NO;
            if (self->_completionHandler) {
                self->_completionHandler(self->_error == nil);
            }
        }
    }];
}

@end
