Pod::Spec.new do |spec|

  spec.name         = "ToneListen"
  spec.version      = "1.0.3"
  spec.summary      = "TONE Telegenics is a business content sharing and streaming platform"
  spec.description  = "TONE Telegenics is a TONE-Enabled content sharing and streaming platform for businesses to exchange marketing and mobile engagement concepts"
  spec.homepage     = "https://github.com/The-TONE-Knows-Inc"
  spec.license      = "MIT"
  spec.author             = { "Tone Telegenics" => "devops@thetoneknows.com" }
  spec.platform     = :ios, "14.0"
  spec.source       = { :git => "https://github.com/Anilkumar18/ToneListen-iOS-Framework.git", :tag => spec.version.to_s }
  spec.source_files  = "ToneListen/*.{swift}"
  spec.swift_version  = "5.0"
end
