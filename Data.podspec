Pod::Spec.new do |s|
  s.name         = 'Data'
  s.version      = '0.1'
  s.summary      = 'Data is a Swift framework for working with data models.'
  s.homepage     = 'https://github.com/DanBrooker/Data'

  s.license      = { type: 'MIT' }
  s.author       = { 'Daniel Brooker' => 'dan@nocturnalcode.com' }
  s.ios.deployment_target = '8.0'
  # s.osx.deployment_target = '10.9'
  s.source       = { git: 'https://github.com/vikmeup/SCLAlertView-Swift.git', branch: 'master' }
  s.source_files = "Data/*.swift"
  s.requires_arc = true
  s.dependency 'YapDatabase'
end
