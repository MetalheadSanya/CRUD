Pod::Spec.new do |spec|
  spec.name = 'CRUD'
  spec.version = '1.0.4'
  spec.summary = 'Simple framework for work with REST API in ActiveRecord style'
  spec.homepage = 'https://github.com/MetalheadSanya/CRUD'
  spec.license = { type: 'BSD', file: 'LICENSE.md' }
  spec.authors = { "Alexander Zalutskiy" => 'metalhead.sanya@gmail.com' }

  spec.platform = :ios, '8.0'
  spec.requires_arc = true
  spec.source = { git: 'https://github.com/MetalheadSanya/CRUD.git', tag: "#{spec.version}", submodules: true }
  spec.source_files = "CRUD/Source/*.{h,swift}"

  spec.dependency 'Gloss', '~> 0.7'
  spec.dependency 'Alamofire', '~> 3.4'
  spec.dependency 'When', '~> 1.0.4'
end