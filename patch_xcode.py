import os
import re
import uuid

def generate_id():
    # Generate a random-ish 24-character hex ID similar to Xcode
    return uuid.uuid4().hex[:24].upper()

def patch_pbxproj():
    project_path = 'ios/Runner.xcodeproj/project.pbxproj'
    if not os.path.exists(project_path):
        print("❌ Project file not found at " + project_path)
        return

    with open(project_path, 'r') as f:
        content = f.read()

    if 'PrivacyInfo.xcprivacy' in content:
        print("✅ PrivacyInfo.xcprivacy already exists in the project file.")
        return

    # 1. Generate IDs for the new entries
    file_ref_id = generate_id()
    build_file_id = generate_id()

    # 2. Add PBXBuildFile
    build_file_entry = f'\t\t{build_file_id} /* PrivacyInfo.xcprivacy in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* PrivacyInfo.xcprivacy */; }};\n'
    content = content.replace('/* Begin PBXBuildFile section */\n', '/* Begin PBXBuildFile section */\n' + build_file_entry)

    # 3. Add PBXFileReference
    file_ref_entry = f'\t\t{file_ref_id} /* PrivacyInfo.xcprivacy */ = {{isa = PBXFileReference; lastKnownFileType = text.xml; path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; }};\n'
    content = content.replace('/* Begin PBXFileReference section */\n', '/* Begin PBXFileReference section */\n' + file_ref_entry)

    # 4. Add to PBXGroup (Runner)
    group_pattern = r'(/* Runner */ = \{\s+isa = PBXGroup;\s+children = \(\s+)'
    content = re.sub(group_pattern, rf'\1\t\t\t\t{file_ref_id} /* PrivacyInfo.xcprivacy */,\n', content)

    # 5. Add to PBXResourcesBuildPhase (Resources)
    # This ensures it's actually included in the app bundle
    resource_pattern = r'(/* Resources */ = \{\s+isa = PBXResourcesBuildPhase;\s+buildActionMask = [0-9]+;\s+files = \(\s+)'
    content = re.sub(resource_pattern, rf'\1\t\t\t\t{build_file_id} /* PrivacyInfo.xcprivacy in Resources */,\n', content)

    with open(project_path, 'w') as f:
        f.write(content)
    
    print("🚀 Pbxproj patched successfully! PrivacyInfo.xcprivacy is now a project member.")

if __name__ == "__main__":
    patch_pbxproj()
