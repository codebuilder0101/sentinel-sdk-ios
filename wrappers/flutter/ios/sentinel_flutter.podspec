Pod::Spec.new do |s|
  s.name             = 'sentinel_flutter'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin wrapper for Sentinel Mobile Security SDK.'
  s.description      = <<-DESC
Flutter plugin wrapper for Sentinel Mobile Security SDK.
                       DESC
  s.homepage         = 'https://sentinel-sdk.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sentinel Security' => 'support@sentinel-sdk.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'SentinelSDK'
  s.platform = :ios, '14.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
