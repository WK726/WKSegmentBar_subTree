
Pod::Spec.new do |s|

  s.name         = "ios-libs-web"
  s.version      = "1.0.20"
  s.summary      = "ios-libs-web."
  s.description  = <<-DESC
      public repo for web(native js -interface included)
                DESC
  s.license      = "MIT"
  s.platform     = :ios, "8.0"
  s.authors      = "gstianfu"
  s.homepage     = "http://www.baidu.com"
  s.source       = { :git => "git@repo.gstianfu.com:client/libs/ios-libs-web.git", :tag => s.version }

  s.source_files = 'ios-libs-webview/integration/ios-libs-webview.h'
  s.public_header_files = 'ios-libs-webview/integration/ios-libs-webview.h'

  s.dependency "ios-libs-tools"
  s.dependency "MJRefresh"
  s.dependency "Masonry"

  s.requires_arc = true

  s.subspec 'protocol' do |ss|
    ss.source_files = 'ios-libs-webview/integration/protocol/*.{h,m}'
  end

  s.subspec 'web' do |ss|
    ss.source_files = 'ios-libs-webview/integration/web/*.{h,m}'
    ss.dependency "ios-libs-web/protocol"
  end


end