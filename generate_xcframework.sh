# Fail and Exit if any commands fails
set -e

#-----------------------------------------------------
#  --- Script to Generate IDPal SDK (XCFramework) ---
#-----------------------------------------------------

#-----------------------------------------
# Initialising ENV variables
PROJECT_DIR=$(pwd)

PROJECTNAME="ToneListen"
FRAMEWORK_NAME="ToneListen"

# set path for iOS device archive
IOS_ARCHIVE_PATH="./Archives/iOS.xcarchive"

# XCFramework Path
XCFramework_Path="${PROJECT_DIR}/SDK/${FRAMEWORK_NAME}.xcframework"

#-----------------------------------------
# Build iOS Framework
xcodebuild archive \
    -project ToneListen.xcodeproj \
    -scheme ToneListen \
    -archivePath "${IOS_ARCHIVE_PATH}" \
    -sdk iphoneos SKIP_INSTALL=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES || exit 1

#-----------------------------------------
# Create XCFramework
xcodebuild -create-xcframework \
    -framework ${IOS_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework \
    -debug-symbols "${PROJECT_DIR}/Archives/iOS.xcarchive/dSYMs/${FRAMEWORK_NAME}.framework.dSYM" \
    -output "${XCFramework_Path}" || exit 1

#-----------------------------------------
# Cleaning Up the Archives folder
rm -rf ./Archives
