#!/bin/sh

UPLOADER_VERSION=1.09

# Put your TestFairy API_KEY here. Find it in your TestFairy account settings.
TESTFAIRY_API_KEY=$2

# Your Keystore, Storepass and Alias, the ones you use to sign your app.
KEYSTORE=
STOREPASS=
ALIAS=

# Tester Groups that will be notified when the app is ready. Setup groups in your TestFairy account testers page.
# This parameter is optional, leave empty if not required
TESTER_GROUPS=$3

# Should email testers about new version. Set to "off" to disable email notifications.
NOTIFY="on"

# If AUTO_UPDATE is "on" all users will be prompt to update to this build next time they run the app
AUTO_UPDATE="on"

# The maximum recording duration for every test.
MAX_DURATION="10m"

# Is video recording enabled for this build
VIDEO="on"

# Add a TestFairy watermark to the application icon?
ICON_WATERMARK="on"

# Comment text will be included in the email sent to testers
COMMENT=""

# locations of various tools
CURL=curl
ZIP=zip
KEYTOOL=keytool
ZIPALIGN=zipalign
JARSIGNER=jarsigner

SERVER_ENDPOINT=http://app.testfairy.com

usage() {
	echo "Usage: testfairy-upload.sh APK_FILENAME TestFairyKey TestFairyGroup"
	echo
}

verify_settings() {

	if [ -z "${TESTFAIRY_API_KEY}" ]; then
		usage
		echo "Please update API_KEY with your private API key, as noted in the Settings page"
		exit 1
	fi
}

if [ $# -ne 3 ]; then
	echo $1 $2 $3
	usage
	exit 1
fi

# before even going on, make sure all tools work
verify_settings

APK_FILENAME=$1

echo $TESTFAIRY_API_KEY
echo $APK_FILENAME
echo $TESTER_GROUPS

if [ ! -f "${APK_FILENAME}" ]; then
	usage
	echo "Can't find file: ${APK_FILENAME}"
	exit 2
fi

# temporary file paths
DATE=`date`
TMP_FILENAME=.testfairy.upload.apk
ZIPALIGNED_FILENAME=.testfairy.zipalign.apk
rm -f "${TMP_FILENAME}" "${ZIPALIGNED_FILENAME}"

/bin/echo -n "Uploading ${APK_FILENAME} to TestFairy.. "
JSON=$( ${CURL} -s ${SERVER_ENDPOINT}/api/upload -F api_key=${TESTFAIRY_API_KEY} -F apk_file="@${APK_FILENAME}" -F icon-watermark="${ICON_WATERMARK}" -F video="${VIDEO}" -F max-duration="${MAX_DURATION}" -F comment="${COMMENT}" -A "TestFairy Command Line Uploader ${UPLOADER_VERSION}" -F testers-groups="${TESTER_GROUPS}" -F auto-update="${AUTO_UPDATE}" -F notify="${NOTIFY}")

URL=$( echo ${JSON} | sed 's/\\\//\//g' | sed -n 's/.*"instrumented_url"\s*:\s*"\([^"]*\)".*/\1/p' )
if [ -z "${URL}" ]; then
	echo "FAILED!"
	echo
	echo "Upload failed, please check your settings"
	exit 1
fi

URL="${URL}?api_key=${TESTFAIRY_API_KEY}"

echo "OK!"
