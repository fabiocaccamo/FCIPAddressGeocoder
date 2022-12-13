Pod::Spec.new do |spec|
  spec.name         = 'FCIPAddressGeocoder'
  spec.version      = '1.3.0'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/fabiocaccamo/FCIPAddressGeocoder'
  spec.authors      = { 'Fabio Caccamo' => 'fabio.caccamo@gmail.com' }
  spec.summary      = 'iOS Geocoder for geocode device IP Address location using GeoIP service(s) and a block-based syntax.'
  spec.source       = { :git => 'https://github.com/fabiocaccamo/FCIPAddressGeocoder.git', :tag => '1.3.0' }
  spec.source_files = 'FCIPAddressGeocoder/*.{h,m}'
  spec.platform     = :ios, '5.0'
  spec.framework    = 'Foundation', 'UIKit', 'CoreLocation'
  spec.requires_arc = true
end
