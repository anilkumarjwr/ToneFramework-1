#
#  Be sure to run `pod spec lint ToneListen.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name         = 'ToneListen'
  spec.version      = '1.0.2'
  spec.summary      = 'SamplePod enables businesses to detect atmospheric frequencies securely and efficiently.'
 
  spec.description  = 'SamplePod is a tone detection solution that enables businesses to utilize it for detecting any frequencies received on the atmosphere simply, securely and conveniently... SamplePod is a tone detection solution that enables businesses to utilize it for detecting any frequencies received on the atmosphere simply, securely and conveniently...'

  spec.homepage     = "https://github.com/Anilkumar18/ToneFramework"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Venkatesh S" => "anilkumarunni@gmail.com" }
  spec.source       = { :git => "https://github.com/Anilkumar18/ToneFramework.git", :tag => spec.version.to_s }
  spec.ios.deployment_target = '14.0'
  spec.dependency 'AudioKit', '5.1.0'
  spec.dependency 'SwiftLocation/Core', '5.1.0'
  spec.ios.vendored_frameworks = "Sources/ToneListen.xcframework"

end