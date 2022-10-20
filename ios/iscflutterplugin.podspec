#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint iscflutterplugin.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'iscflutterplugin'
  s.version          = '0.0.1'
  s.summary          = '海康isc播放插件'
  s.description      = <<-DESC
海康isc播放插件
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.vendored_frameworks = 'Framework/*.framework'
  s.resource = 'Resources/com.hri.hpc.mobile.ios.player.metallib'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
