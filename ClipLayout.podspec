#
# Be sure to run `pod lib lint ClipLayout.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ClipLayout'
  s.version          = '1.2.7'
  s.summary          = "Simple and performant Layout Engine. It's faster and more concise AutoLayout alternative :)"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  ClipLayout allows you to write less code for determining the size of the views and positioning them on screen.
                       DESC

  s.homepage         = 'https://github.com/DenisLitvin/ClipLayout'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Denis Litvin' => 'den.litvinn@gmail.com' }
  s.source           = { :git => 'https://github.com/DenisLitvin/ClipLayout.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.3'

  s.source_files = 'ClipLayout/Classes/**/*'
  s.swift_version = '4.1'
  # s.resource_bundles = {
  #   'ClipLayout' => ['ClipLayout/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
