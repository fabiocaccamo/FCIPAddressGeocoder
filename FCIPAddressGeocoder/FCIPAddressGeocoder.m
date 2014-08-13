//
//  FCIPAddressGeocoder.m
//
//  Created by Fabio Caccamo on 07/07/14.
//  Copyright (c) 2014 Fabio Caccamo - http://www.fabiocaccamo.com/ - All rights reserved.
//

#import "FCIPAddressGeocoder.h"

@implementation FCIPAddressGeocoder : NSObject


NSString *const kDefaultURL = @"http://freegeoip.net/";


-(id)init
{
    return [self initWithURL:kDefaultURL];
}


-(id)initWithURL:(NSString *)url
{
    self = [super init];
    
    if( self )
    {
        NSAssert(url != nil, @"invalid url. url parameter cannot be nil.");
        
        _url = [NSURL URLWithString:@"json/" relativeToURL:[NSURL URLWithString:url]];
        _request = [NSURLRequest requestWithURL:_url];
        _operationQueue = [NSOperationQueue new];
    }
    
    return self;
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
    
    [NSURLConnection sendAsynchronousRequest:_request queue:_operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
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
                    _locationCity = [_locationInfo objectForKey:@"city"];
                    _locationCountry = [_locationInfo objectForKey:@"country_name"];
                    _locationCountryCode = [_locationInfo objectForKey:@"country_code"];
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
        
        _geocoding = NO;
        
        if( _completionHandler )
        {
            _completionHandler( _error == nil );
        }
    }];
}


+(FCIPAddressGeocoder *)sharedGeocoder
{
    static FCIPAddressGeocoder *instance = nil;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}


@end