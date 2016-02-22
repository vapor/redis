Pod::Spec.new do |s|

  s.name         = "Redbird"
  s.version      = "0.2.3"
  s.summary      = "Pure-Swift Redis client. OS X and Linux ready."

  s.description  = <<-DESC
                  Pure-Swift implementation of a Redis client from the original protocol spec. OS X + Linux compatible.
                   DESC

  s.homepage     = "https://github.com/czechboy0/Redbird"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Honza Dvorsky" => "https://honzadvorsky.com" }
  s.social_media_url   = "http://twitter.com/czechboy0"

  s.osx.deployment_target = "10.9"
  s.ios.deployment_target = "8.0"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/czechboy0/Redbird.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/Redbird/*.swift"
  
end
