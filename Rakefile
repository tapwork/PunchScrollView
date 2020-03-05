desc "Bootstraps the repo"
task :bootstrap do
  sh 'export LANG=en_US.UTF-8'
  sh 'bundle'
  sh 'cd ExampleProject && bundle exec pod install'
end

desc "Runs the specs"
task :spec do
  sh 'xcodebuild -workspace ExampleProject/PunchUIScrollView.xcworkspace -scheme \'PunchUIScrollView\' -destination \'platform=iOS Simulator,name=iPhone 11 Pro Max,OS=13.3\' clean test -sdk iphonesimulator | xcpretty -tc && exit ${PIPESTATUS[0]}'
end
