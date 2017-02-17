FCIPAddressGeocoder ![Pod version](http://img.shields.io/cocoapods/v/FCIPAddressGeocoder.svg) ![Pod platforms](http://img.shields.io/cocoapods/p/FCIPAddressGeocoder.svg) ![Pod license](http://img.shields.io/cocoapods/l/FCIPAddressGeocoder.svg)
===================

iOS Geocoder for **geocode device IP Address location using GeoIP service(s)** and a block-based syntax.

##Supported Services
- [FreeGeoIP](http://freegeoip.net/) - [GitHub](https://github.com/fiorix/freegeoip)
- [IP-Api](http://ip-api.com/)
- [Nekudo](http://geoip.nekudo.com/)
- [Petabyet](https://www.petabyet.com/api/)
- [~~Smart-IP~~](http://smart-ip.net/)
- [Telize](http://www.telize.com/) *(this service is not free anymore, you can spin up your own instance or subscribe to a paid plan)*

*(feel free to suggest other services to support)*

##Requirements & Dependecies
- iOS >= 5.0
- ARC enabled
- CoreLocation Framework

##Installation

####CocoaPods:
`pod 'FCIPAddressGeocoder'`

####Manual install:
Copy `FCIPAddressGeocoder.h` and `FCIPAddressGeocoder.m` to your project.

##Usage
```objective-c
//the service used by default is FreeGeoIP, but you can set the default service to another one
//this method will affect the default service/url of all instances, included the shared one
//if you need to change the default service/url it's recommended to do it application:didFinishLaunching
[FCIPAddressGeocoder setDefaultService:FCIPAddressGeocoderServiceFreeGeoIP];

//some services like FreeGeoIP are open-source, and you could need to use an instance of it running on your own server
[FCIPAddressGeocoder setDefaultService:FCIPAddressGeocoderServiceFreeGeoIP andURL:@"http://127.0.0.1/"];
```
```objective-c
//you can use the shared instance
FCIPAddressGeocoder *geocoder = [FCIPAddressGeocoder sharedGeocoder];

//or create a new geocoder
FCIPAddressGeocoder *geocoder = [FCIPAddressGeocoder new];

//or create a new geocoder which uses a custom instance of the FreeGeoIP service installed on your own server
FCIPAddressGeocoder *geocoder = [[FCIPAddressGeocoder alloc] initWithService:FCIPAddressGeocoderServiceFreeGeoIP andURL:@"http://127.0.0.1/"];
```
```objective-c
//set if the geocoder can use all available services in case of failure of the default one
//very useful since 3rd party services are not depending by us and could be temporary unavailable or no more active
//by default this property value is set to YES only if you use the shared geocoder or if you create a geocoder without specifing its service/url
geocoder.canUseOtherServicesAsFallback = YES;
```
```objective-c
//IP Address geocoding (geocoding results are cached for 1 minute)
[geocoder geocode:^(BOOL success) {

    if(success)
    {
        //you can access the location info-dictionary containing all informations using 'geocoder.locationInfo'
        //you can access the location using 'geocoder.location'
        //you can access the location city using 'geocoder.locationCity' (it could be nil)
        //you can access the location country using 'geocoder.locationCountry'
        //you can access the location country-code using 'geocoder.locationCountryCode'
    }
    else {
        //you can debug what's going wrong using: 'geocoder.error'
    }
}];
```
```objective-c
//check if geocoding
[geocoder isGeocoding]; //returns YES or NO
```
```objective-c
//cancel geocoding
[geocoder cancelGeocode];
```

##License
Released under [MIT License](LICENSE).
