require "json"

package = JSON.parse(File.read(File.join(__dir__, "../package.json")))

Pod::Spec.new do |s|
  s.name         = "SentinelReactNative"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = "https://sentinel-sdk.dev"
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "14.0" }
  s.source       = { :git => "https://github.com/codebuilder0101/sentinel-sdk-ios.git", :tag => "#{s.version}" }

  s.source_files = "*.{h,m,swift}"
  s.dependency "React-Core"
  s.dependency "SentinelSDK"
end
