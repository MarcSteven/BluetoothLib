Pod::Spec.new do |s|
  s.name             = "BluetoothLib"
  s.version          = "0.0.1"
  s.summary          = "iOS bluetooth library ."
  s.homepage         = "https:///github.com/ARIEnergy/BluetoothLib"
  s.license          = 'Code is MIT, then custom font licenses.'
  s.author           = { "Marc Steven" => "zhaoxinqiang328@gmail.com" }
  s.source           = { :git => "https://github.com/ARIEnergy/BluetoothLib.git", :tag => s.version }
  

  s.platform     = :ios, '11.0'
  s.ios.deployment_target = '11.0'


  s.source_files = 'BluetoothLib/Source/**/*.{swift}'
  s.swift_version = '5.0'


  

  s.frameworks = 'CoreBluetooth'
end
