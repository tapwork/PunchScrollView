Pod::Spec.new do |s|
  s.name         = "PunchScrollView"
  s.version      = "1.1.1"
  s.summary      = "PunchScrollView is a little UIScrollView subclass."
  s.description  = <<-DESC
                   PunchScrollView is a little UIScrollView subclass which works like the UICollectionView but with more focus on pages and infinite scrolling. PunchScrollView can be run with iOS 5.
                   DESC
  s.homepage     = "https://github.com/tapwork/PunchScrollView"
  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Christian Menschel" => "christian@tapwork.de" }
  s.social_media_url   = "http://twitter.com/cmenschel"
  s.platform     = :ios
  s.platform     = :ios, "5.0"
  s.source = {
    :git => 'https://github.com/tapwork/PunchScrollView.git',
    :tag => s.version.to_s
  }
  s.source_files = 'PunchScrollView.{h,m}'
  s.requires_arc = true
end
