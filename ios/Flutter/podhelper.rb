# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

require 'json'

# Minimum CocoaPods Ruby version is 2.0.
# Don't depend on features newer than that.

# Hook for Podfile setup, installation settings.
#
# @example
# flutter_ios_podfile_setup
# target 'Runner' do
# ...
# end
# @param [String] ios_application_path Path of the iOS directory of the Flutter app.
#                                      Optional, defaults to the Podfile directory.
def flutter_ios_podfile_setup(ios_application_path = nil)
  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  ios_application_path ||= File.dirname(defined_in_file.realpath) if respond_to?(:defined_in_file)
  raise 'Could not find iOS application path' unless ios_application_path
end

# Same as flutter_ios_podfile_setup for macOS.
def flutter_macos_podfile_setup(mac_application_path = nil)
  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  mac_application_path ||= File.dirname(defined_in_file.realpath) if respond_to?(:defined_in_file)
  raise 'Could not find macOS application path' unless mac_application_path
end

# Determine whether the target depends on Flutter (including transitive dependency)
def depends_on_flutter(target, engine_pod_name)
  target.dependencies.any? do |dependency|
    if dependency.name == engine_pod_name
      return true
    end
    # Transitive dependencies are not easily accessible here without a full project graph.
    # For now, we only check direct dependencies.
  end
  return false
end

# Add iOS build settings to pod targets.
def flutter_additional_ios_build_settings(target)
  return unless target.platform_name == :ios

  target.build_configurations.each do |build_configuration|
    build_configuration.build_settings['ENABLE_BITCODE'] = 'NO'
    build_configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  end
end

# Install pods needed to embed Flutter iOS engine and plugins.
def flutter_install_all_ios_pods(ios_application_path = nil)
  flutter_install_ios_engine_pod(ios_application_path)
  flutter_install_plugin_pods(ios_application_path, '.symlinks', 'ios')
end

# Install iOS Flutter engine pod.
def flutter_install_ios_engine_pod(ios_application_path = nil)
  ios_application_path ||= File.dirname(defined_in_file.realpath) if respond_to?(:defined_in_file)
  podspec_directory = File.join(ios_application_path, 'Flutter')
  copied_podspec_path = File.expand_path('Flutter.podspec', podspec_directory)

  # Generate a fake podspec to represent the Flutter framework.
  File.open(copied_podspec_path, 'w') do |podspec|
    podspec.write <<~EOF
      Pod::Spec.new do |s|
        s.name             = 'Flutter'
        s.version          = '1.0.0'
        s.summary          = 'A UI toolkit for beautiful and fast apps.'
        s.homepage         = 'https://flutter.dev'
        s.license          = { :type => 'BSD' }
        s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
        s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
        s.ios.deployment_target = '13.0'
        s.vendored_frameworks = 'path/to/nothing'
      end
    EOF
  end

  pod 'Flutter', :path => 'Flutter'
end

# Install Flutter plugin pods.
def flutter_install_plugin_pods(application_path = nil, relative_symlink_dir, platform)
  application_path ||= File.dirname(defined_in_file.realpath) if respond_to?(:defined_in_file)
  plugins_file = File.join(application_path, '..', '.flutter-plugins-dependencies')
  return unless File.exist? plugins_file
  
  dependencies_hash = JSON.parse(File.read(plugins_file))
  plugin_pods = dependencies_hash.dig('plugins', platform) || []

  plugin_pods.each do |plugin_hash|
    plugin_name = plugin_hash['name']
    plugin_path = plugin_hash['path']
    next unless plugin_name && plugin_path
    
    # Use relative path from Podfile to plugin ios directory
    relative_path = Pathname.new(plugin_path).relative_path_from(Pathname.new(application_path)).to_s
    pod plugin_name, :path => File.join(relative_path, 'ios')
  end
end
