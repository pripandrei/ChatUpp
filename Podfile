# Uncomment the next line to define a global platform for your project
# platform :ios, '16.2'

target 'ChatUpp' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ChatUpp

pod 'Firebase/Core'

	# pod 'Firebase/Crashlytics'
	
pod 'Firebase/Auth'
pod 'Firebase/Database'
pod 'FirebaseFirestore'
pod 'IQKeyboardManagerSwift'
pod 'FirebaseFirestoreSwift'
pod 'GoogleSignIn'
pod 'GoogleSignInSwift'
pod 'AlgoliaSearchClient', '~> 8.0'
pod 'SkeletonView'
pod 'Firebase/Storage'
pod 'YYText'


post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
            end
        end
    end
end

end
