Pod::Spec.new do |s|
  s.name         = 'Data'
  s.version      = '0.1'
  s.summary      = 'Data is a Swift framework for working with data models.'
  s.homepage     = 'https://github.com/DanBrooker/Data'

  s.license      = { type: 'MIT', file: 'LICENCE' }
  s.author             = { 'Danirl Brooker' => 'dan@nocturnalcode.com' }
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.source       = { git: 'https://github.com/vikmeup/SCLAlertView-Swift.git' }
  s.source_files = "Data/*.swift"
  s.requires_arc = true
  s.dependency 'YapDatabase'
end
