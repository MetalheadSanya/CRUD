Pod::Spec.new do |spec|
  spec.name = 'CRUD'
  spec.version = '1.1.2'
  spec.summary = 'Simple framework for work with REST API in ActiveRecord style'
  spec.homepage = 'https://github.com/MetalheadSanya/CRUD'
  spec.license = { type: 'BSD', file: 'LICENSE.md' }
  spec.authors = { "Alexander Zalutskiy" => 'metalhead.sanya@gmail.com' }

  spec.platform = :ios, '9.0'
  spec.requires_arc = true
  spec.source = { git: 'https://github.com/MetalheadSanya/CRUD.git', tag: "#{spec.version}", submodules: true }
  spec.source_files = "CRUD/Source/*.{h,swift}"

  spec.dependency 'Gloss', '~> 1.0.0'
  spec.dependency 'Alamofire', '~> 4.0.1'
  spec.dependency 'When', '~> 2.0.0'
end
