Pod::Spec.new do |s|
  
  s.name         = "ReadiumShared"
  s.version      = "3.0.0-alpha.1"
  s.license      = "BSD 3-Clause License"
  s.summary      = "Readium Shared"
  s.homepage     = "http://readium.github.io"
  s.author       = { "Readium" => "contact@readium.org" }
  s.source       = { :git => 'https://github.com/readium/swift-toolkit.git', :tag => "3.0.0-alpha.1" }
  s.exclude_files = ["Sources/Shared/Toolkit/Archive/ZIPFoundation.swift"]
  s.requires_arc = true
  s.resource_bundles = {
    "ReadiumShared" => ["Sources/Shared/Resources/**"],
  }
  s.source_files  = "Sources/Shared/**/*.{m,h,swift}"
  s.platform     = :ios
  s.ios.deployment_target = "11.0"
  s.frameworks   = "CoreServices"
  s.libraries =  "xml2"
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  
  s.dependency 'Fuzi', '~> 3.0'
  s.dependency 'Minizip', '~> 1.0'
  s.dependency 'SwiftSoup', '<= 2.5.3' # From 2.6.0, Xcode 14 is required
  s.dependency 'ReadiumInternal'

end
