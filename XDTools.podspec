#
# Be sure to run `pod lib lint XDTools.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XDTools'
  s.version          = '0.1.0'
  s.summary          = 'XDTools about funny'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://baidu.com'
  s.license          = 'MIT'
  s.author           = { 'JsonF17' => 'fei122603@outlook.com' }
  s.source           = { :git => 'https://github.com/JsonF17/XDTools.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  s.requires_arc = true
  
  s.source_files = 'XDTools/Classes/**/*' 
  
  # s.resource_bundles = {
  #   'XDTools' => ['XDTools/Assets/*.png']
  # }

  # s.public_header_files = 'XDTools/**/*'
  s.frameworks = 'UIKit','Foundation'
  
  s.dependency 'GDataXMLNode2', '2.0.1'
  s.dependency 'GCDWebServer', '3.5.4'
  s.dependency 'CocoaAsyncSocket', '7.6.5'
end
