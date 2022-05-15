Pod::Spec.new do |s|
  s.name             = 'JustTrack'
  s.version          = ENV['LIB_VERSION']
  s.summary          = 'The Just Eat solution to better manage the analytics tracking on iOS and improve the relationship with your BI team.'

  s.description      = <<-DESC
At Just Eat, tracking events is a fundamental part of our business analysis and the information we collect informs our technical and strategic decisions. To collect the information required we needed a flexible, future-proof and easy to use tracking system that enables us to add, remove and swap the underlying integrations with analytical systems and services with minimal impact on our applications' code. We also wanted to solve the problem of keeping the required event metadata up-to-date whenever the requirements change.
JustTrack is the event tracking solution we built for that.
                       DESC

  s.homepage         = 'https://github.com/JustEat/JustTrack'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = 'Just Eat Takeaway iOS Team'
  s.source           = { :git => 'https://github.com/justeat/JustTrack.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/justeat_tech'
  
  s.swift_version = '5.0'
  s.ios.deployment_target = '13.0'

  s.source_files = 'JustTrack/Classes/**/*'
  s.preserve_paths = 'JustTrack/EventsGenerator/*'

  s.test_spec 'UnitTests' do |test_spec|
    test_spec.source_files = 'JustTrack/UnitTests/*'
  end
end
