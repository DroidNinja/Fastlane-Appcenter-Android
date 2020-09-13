# This file contains the fastlane.tools configuration
# You can find the documentation at https://docs.fastlane.tools
#
# For a list of all available actions, check out
#
#     https://docs.fastlane.tools/actions
#
# For a list of all available plugins, check out
#
#     https://docs.fastlane.tools/plugins/available-plugins
#

# Uncomment the line if you want fastlane to automatically update itself
# update_fastlane

default_platform(:android)

platform :android do
   before_all do
      properties = load_properties("../local.properties")

      #--------------------------------------------
      #Setup App Center keys
      #--------------------------------------------

      ENV['APPCENTER_API_TOKEN']=properties['APPCENTER_API_TOKEN']
      ENV['APPCENTER_RELEASE']=properties['APPCENTER_RELEASE']
      ENV['APPCENTER_QA']=properties['APPCENTER_QA']
      ENV['APPCENTER_OWNER_NAME']=properties['APPCENTER_OWNER_NAME']

  end

 lane :appcenter do |values|
           if ENV['APPCENTER_API_TOKEN'] == nil || ENV['APPCENTER_RELEASE'] == nil || ENV['APPCENTER_QA'] == nil || ENV['APPCENTER_OWNER_NAME'] == nil
                UI.abort_with_message!('Please setup these properties in your local.properties file: APPCENTER_API_TOKEN, APPCENTER_RELEASE, APPCENTER_QA, APPCENTER_OWNER_NAME')
           end

            # Get flavor value
            buildType = values[:buildType]

            puts "#--------------------------------------------"
            puts "# Build type: " + buildType
            puts "#--------------------------------------------"

            #This command will list down JIRA Ids from commit messages if you use JIRA in your organization
            #You can also use "sh "git log `git describe --tags --abbrev=0 HEAD^`..HEAD --format=%s" command to add your commit msgs to your release notes
            # Or you can `get_release_notes_input` method for release notes input from command line
            release_notes = sh "git log `git describe --tags --abbrev=0 HEAD^`..HEAD --format=%s | grep -Eo '([A-Z]{3,}-)([0-9]+)' | sort | uniq"

            #These are names of different feature related to your product if you want to give separate builds for different features
            featureName = UI.select("Select your feature: ", ["Feature1", "Default"])

            if featureName == 'Default'
                 if buildType == 'release'
                  #AppCenter release app name
                      featureName = ENV['APPCENTER_RELEASE']
                 else
                  #AppCenter QA app name
                      featureName = ENV['APPCENTER_QA']
                 end
             end

            begin
                versionInfo = get_last_build_version(featureName)
                if versionInfo != nil
                    puts "#--------------------------------------------"
                    puts "# Last Uploaded Build Version for "+ featureName +": " + versionInfo['version']
                    puts "#--------------------------------------------"
                end
            rescue => ex
                UI.error ex
            end


            #--------------------------------------------
            #Take version cide or use build.gradle value
            #--------------------------------------------

            versionCode = UI.input("Version code?")
            if versionCode == ''
                versionCode = get_app_version_code
            end

            puts "#--------------------------------------------"
            puts "# Version code: " + versionCode
            puts "#--------------------------------------------"

            #--------------------------------------------
            #Take version name or use build.gradle value
            #--------------------------------------------

            versionName = UI.input("Version name?")
            if versionName == ''
                versionName = get_app_version_name
            end

            puts "#--------------------------------------------"
            puts "# Version name: " + versionName
            puts "#--------------------------------------------"

            #--------------------------------------------
            # Build release app
            #--------------------------------------------

            build_app_release_flavor(buildType, versionCode, versionName)

            # Get APK path
            apkPath = get_apk_file_path(buildType,versionCode, versionName)
            puts "#--------------------------------------------"
            puts "# APK path: " + apkPath
            puts "#--------------------------------------------"

            upload_to_appcenter(featureName, apkPath, release_notes)
end

# Upload to appcenter
def upload_to_appcenter(appName, apkPath, release_notes)
 appcenter_upload(
      api_token: ENV['APPCENTER_API_TOKEN'],
      owner_name: ENV['APPCENTER_OWNER_NAME'],
      owner_type: "organization",
      app_name: appName,
      file: apkPath,
      release_notes: release_notes,
      notify_testers: true
    )
end

# Get last uploaded build version for a particular feature
def get_last_build_version(appName)
    appcenter_fetch_version_number(
      api_token: ENV['APPCENTER_API_TOKEN'],
      owner_name: ENV['APPCENTER_OWNER_NAME'],
      app_name: appName
    )
end

# Get version name from root level build.gradle
def get_app_version_name()
  return get_version_code(
    #app_folder_name:"project"
    gradle_file_path:"build.gradle",
    ext_constant_name:"versionName"
  )
end

# Get version code from root level build.gradle
def get_app_version_code()
  return get_version_code(
    #app_folder_name:"project"
    gradle_file_path:"build.gradle",
    ext_constant_name:"versionCode"
  )
end

# APK path based on name convention, you have configured in your gradle configuration i.e. append "-qa" in case of QA builds
def get_apk_file_path(buildType, versionCode, versionName)
  if buildType == 'qa'
      suffix = "-qa"
  else
      suffix = ""
  end
  return "app/build/outputs/apk/"+buildType+ "/"+"app_"+versionCode+"_"+versionName + suffix +".apk"
end

# In case you want to enter release on command line
def get_release_notes_input()
releaseNotes = prompt(
            text: "Do you want to add any release notes?",
            multi_line_end_keyword: "END",
            ci_input: ''
          )
return releaseNotes
end

  # Get file content
def get_file_as_string(filename, htmlTag)
      data = ''
      f = File.open(filename, "r")
      f.each_line do |line|
          data +=  line + htmlTag
      end

      return  data
  end

# This method returns an array
def get_recipients(file_path)
  data = ''
      f = File.open(file_path, "r")
      f.each_line do |line|
          data +=  line
      end

      data_arry = data.split(",")
      return data_arry
 end


# Gradle Build configuration
def build_app_release_flavor(type, versionCode, versionName)
   gradle(
          task: "assemble",
          build_type: type,
          properties: {
    "VERSION_CODE" => versionCode.to_i,
    "VERSION_NAME" => versionName
  }
         )
      end
end

#Load properties from file
def load_properties(properties_filename)
    properties = {}
    File.open(properties_filename, 'r') do |properties_file|
      properties_file.read.each_line do |line|
        line.strip!
        if (line[0] != ?# and line[0] != ?=)
          i = line.index('=')
          if (i)
            properties[line[0..i - 1].strip] = line[i + 1..-1].strip
          else
            properties[line] = ''
          end
        end
      end
    end
    return properties
  end