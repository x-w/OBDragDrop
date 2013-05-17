Pod::Spec.new do |spec|
  spec.name = "OBDragDrop"
  spec.version = '0.0.1'
  spec.source = {:git => 'git@github.com:/Oblong/OBDragDrop.git'}
  spec.source_files = ['Classes/*.{h,m}']
  spec.requires_arc = false
end
