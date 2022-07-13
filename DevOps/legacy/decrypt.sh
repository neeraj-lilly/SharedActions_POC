#!/bin/sh

# Decrypt the files
# --batch to prevent interactive command --yes to assume "yes" for questions
if [[ "$BUILD_ENV" == "development" ]]; then

# Install the provisioning profiles
  mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
  echo "Copying Provisioning Profiles development"
  cp ./.github/secrets/development/*.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
  echo "List Profiles"
  ls ~/Library/MobileDevice/Provisioning\ Profiles/
# Install the signing certificates
  echo "Import Signing Certificates"
  echo "$CERT_IOS_LILLY_APPSTORE_DEVELOP" > ./.github/secrets/lilly_testflight/Certificates.pem
  openssl pkcs12 -export -out ./.github/secrets/lilly_testflight/Certificates.p12 -in ./.github/secrets/lilly_testflight/Certificates.pem -passin pass:"$CERT_IOS_LILLY_APPSTORE_DEVELOP_PASSWORD" -passout pass:"$CERT_IOS_LILLY_APPSTORE_DEVELOP_PASSWORD"
  sudo security import ./.github/secrets/lilly_testflight/Certificates.p12 -t agg -k /Library/Keychains/System.keychain -P "$CERT_IOS_LILLY_APPSTORE_DEVELOP_PASSWORD" -A

elif [[ "$BUILD_ENV" == "testflight" ]]; then

  # Install the provisioning profiles
  mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
  echo "Copying Provisioning Profiles"
# cp ./.github/secrets/lilly_testflight/*.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
  echo "List Profiles"
  ls ~/Library/MobileDevice/Provisioning\ Profiles/
# Install the signing certificates
  echo "Import Signing Certificates"
  echo "$CERT_IOS_LILLY_APPSTORE_DEVELOP" > ./.github/secrets/lilly_testflight/Certificates.pem
  openssl pkcs12 -export -out ./.github/secrets/lilly_testflight/Certificates.p12 -in ./.github/secrets/lilly_testflight/Certificates.pem -passin pass:"$CERT_IOS_LILLY_APPSTORE_DEVELOP_PASSWORD" -passout pass:"$CERT_IOS_LILLY_APPSTORE_DEVELOP_PASSWORD"
  sudo security import ./.github/secrets/lilly_testflight/Certificates.p12 -t agg -k /Library/Keychains/System.keychain -P "$CERT_IOS_LILLY_APPSTORE_DEVELOP_PASSWORD" -A
  echo "Import Signing Certificates"
  echo "$CERT_IOS_DELOITTE_DEVELOP" > ./.github/secrets/development/Certificates.pem
  openssl pkcs12 -export -out ./.github/secrets/development/Certificates.p12 -in ./.github/secrets/development/Certificates.pem -passin pass:"$CERT_IOS_DELOITTE_DEVELOP_PASSWORD" -passout pass:"$CERT_IOS_DELOITTE_DEVELOP_PASSWORD"
  sudo security import ./.github/secrets/development/Certificates.p12 -t agg -k /Library/Keychains/System.keychain -P "$CERT_IOS_DELOITTE_DEVELOP_PASSWORD" -A
elif [[ "$BUILD_ENV" == "alpha" ]]; then

  # Install the provisioning profiles
  mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
  echo "Copying Provisioning Profiles"
  cp ./.github/secrets/lilly_alpha/*.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
  echo "List Profiles"
  ls ~/Library/MobileDevice/Provisioning\ Profiles/
# Install the signing certificates
  echo "Import Signing Certificates"
  echo "$CERT_IOS_LILLY_ENTERPRISE_DEVELOP" > ./.github/secrets/lilly_alpha/Certificates.pem
  openssl pkcs12 -export -out ./.github/secrets/lilly_alpha/Certificates.p12 -in ./.github/secrets/lilly_alpha/Certificates.pem -passin pass:"$CERT_IOS_LILLY_ENTERPRISE_DEVELOP_PASSWORD" -passout pass:"$CERT_IOS_LILLY_ENTERPRISE_DEVELOP_PASSWORD"
  sudo security import ./.github/secrets/lilly_alpha/Certificates.p12 -t agg -k /Library/Keychains/System.keychain -P "$CERT_IOS_LILLY_ENTERPRISE_DEVELOP_PASSWORD" -A

elif [[ "$BUILD_ENV" == "appstore" ]]; then

  # Install the provisioning profiles
  mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
  echo "Copying Provisioning Profiles"
  cp ./.github/secrets/lilly_appstore/*.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
  echo "List Profiles"
  ls ~/Library/MobileDevice/Provisioning\ Profiles/
# Install the signing certificates
  echo "Import Signing Certificates"
  echo "$CERT_IOS_LILLY_APPSTORE_DEVELOP" > ./.github/secrets/lilly_appstore/Certificates.pem
  openssl pkcs12 -export -out ./.github/secrets/lilly_appstore/Certificates.p12 -in ./.github/secrets/lilly_appstore/Certificates.pem -passin pass:"$CERT_IOS_LILLY_APPSTORE_DEVELOP_PASSWORD" -passout pass:"$CERT_IOS_LILLY_APPSTORE_DEVELOP_PASSWORD"
  sudo security import ./.github/secrets/lilly_appstore/Certificates.p12 -t agg -k /Library/Keychains/System.keychain -P "$CERT_IOS_LILLY_APPSTORE_DEVELOP_PASSWORD" -A

else
  echo "App Distribution not found"
  exit -1
fi

