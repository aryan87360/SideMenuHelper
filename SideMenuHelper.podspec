Pod::Spec.new do |s|
  s.name             = 'SideMenuHelper'
  s.version          = '1.0.0'
  s.summary          = 'A helper class for presenting side menus.'
  s.description      = 'SideMenuHelper is a customizable utility for presenting side menus in iOS applications.'
  s.homepage         = 'https://github.com/yourusername/SideMenuHelper'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'youremail@example.com' }
  s.source           = { :git => 'https://github.com/aryan87360/SideMenuHelper.git', :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'
  s.source_files     = 'SideMenuHelperFramework/**/*.{swift,h,m}'
  s.frameworks       = 'UIKit'
end

