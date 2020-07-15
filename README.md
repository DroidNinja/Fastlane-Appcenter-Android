#Fastlane CI + App Center Setup

# Fastlane Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

#App Center Setup

1. Create an account and setup an organization.
2. Create two apps one for Release and one for QA.
3. Create API token for appcenter : https://appcenter.ms/settings/apitokens
4. Add below properties in local.properties file that are mandatory for Release/QA pipeline setup.

```
#Setup new token @ https://appcenter.ms/settings/apitokens
APPCENTER_API_TOKEN=<YOUR_API_TOKEN>

#Release app name created on app center
APPCENTER_RELEASE=Fastlane-Demo

#QA app name created on app center
APPCENTER_QA=Fastlane-Demo-1

#Organization name created on app center
APPCENTER_OWNER_NAME=BinaryWallLabs
```

# Commands
For Release Builds:
`fastlane appcenter buildType:release`

For QA Builds:
`fastlane appcenter buildType:qa`