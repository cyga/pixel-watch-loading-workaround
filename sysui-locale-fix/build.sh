#!/usr/bin/env bash
# Собирает sysui-locale-fix.apk без Gradle: aapt2 + javac + d8 + apksigner.
set -euo pipefail
cd "$(dirname "$0")"
SDK=${ANDROID_HOME:-$HOME/Android/Sdk}
BT=$SDK/build-tools/36.1.0
AJ=$SDK/platforms/android-36/android.jar
export JAVA_HOME=${JAVA_HOME:-$HOME/Android/jdk-21}
export PATH=$JAVA_HOME/bin:$PATH

rm -rf build && mkdir -p build/classes build/dex
"$BT/aapt2" link --manifest AndroidManifest.xml -I "$AJ" -o build/base.apk
javac -Xlint:-options --release 17 -classpath "$AJ" -d build/classes $(find src -name '*.java')
"$BT/d8" --release --min-api 33 --lib "$AJ" --output build/dex $(find build/classes -name '*.class')
python3 - <<'PY'
import shutil, zipfile
shutil.copy("build/base.apk", "build/unaligned.apk")
with zipfile.ZipFile("build/unaligned.apk", "a", zipfile.ZIP_DEFLATED) as z:
    z.write("build/dex/classes.dex", "classes.dex")
PY
"$BT/zipalign" -f 4 build/unaligned.apk build/aligned.apk
if [ ! -f debug.keystore ]; then
  keytool -genkeypair -keystore debug.keystore -storepass android -keypass android \
    -alias debug -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=sysui-locale-fix" >/dev/null 2>&1
fi
"$BT/apksigner" sign --ks debug.keystore --ks-pass pass:android --out sysui-locale-fix.apk build/aligned.apk
echo "Готово: $(pwd)/sysui-locale-fix.apk"
