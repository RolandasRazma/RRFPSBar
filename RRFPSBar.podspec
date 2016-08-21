Pod::Spec.new do |spec|
  spec.name         = 'RRFPSBar'
  spec.version      = '0.0.2'
  spec.summary      = 'RRFPSBar'
  spec.source_files = 'RRFPSBar/*.{h,m}'
  spec.requires_arc = true
  spec.author  	    = { "Rolandas Razma" => "rolandas@razma.lt" }
  spec.license      = "MIT"
  spec.homepage     = "https://github.com/RolandasRazma/RRFPSBar/"
  spec.source = { :git => 'https://github.com/RolandasRazma/RRFPSBar.git', :tag => spec.version }
end