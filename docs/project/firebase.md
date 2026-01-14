# Firebase

## App Distribution

### App Distributionでkey.storeの設定
keytoolsコマンドを使って作成し、SHA-1/SHA256の値をFirebase側で設定する必要がある。
```bash
sudo apt install openjdk-21-jre-headless
keytool -genkey -v -keystore release.keystore -alias eno49study_testingapp -keyalg RSA -keysize 2048 -validity 10000
```

パスワードを聞かれるので設定（この後環境変数で設定）。
ファイルの中身をgithub actions上で設定するため、エンコード:
```bash
base64 release.keystore | tr -d '\n' > release.keystore.base64
```

SHA-1/SHA256の値を確認するコマンド:
```bash
keytool -list -v -keystore ./app/release.keystore -alias eno49study_testingapp -storepass xxx -keypass xxx
```

### SHA1フィンガープリント

#### デバッグ用のSHA-1を出力する場合
```bash
cd android
.\gradlew signingReport
```

#### リリース用のSHA-1を出力する場合
```sh
keytool -keystore /mnt/c/Users/Administrator/.android/debug.keystore  -list -v
```

## App Links

### assetlinks.jsonの配置
1. `firebase.json`の設定を行う（[対象コミット](https://github.com/eno-conan/flutter-starbucks-clone/commit/e1013367cf33e307dd60007212dfe34e3348578d#diff-3f7c92e2669f851959cda8776100cf4e921faefe7dff0061c0e21f7d2ac65122)）
2. 以下コマンドで設定を反映
```sh
    firebase deploy --only hosting
```

### 検証

#### apktoolによる`AndroidManifest.xml`の確認
```bash
apktool d build/app/outputs/flutter-apk/app-release.apk -o decoded_apk
```

#### キャッシュをクリア
```shell
adb shell pm list packages | grep testingapp
adb shell pm clear com.enoconan.testingappv2
```

### 動作確認
リクエスト作成。ローカルアプリケーション起動した状態で別ターミナルで実行する。

私の場合は、これで新規会員登録画面が開く。（後々他画面でも適用予定）
トークンの値は、`pre_signup_users`テーブルに投入済のデータの値と同じ。
```shell
# v2
adb shell am start -W -a android.intent.action.VIEW -d "testingapp:///register?token=7RRtXNgRpCiWpaakdKs9yGmCFh0x7B99" com.enoconan.testingappv2
# v1
adb shell am start -W -a android.intent.action.VIEW -d "http://local.com/register?token=7RRtXNgRpCiWpaakdKs9yGmCFh0x7B99" com.enoconan.testingappv2
```

本登録したユーザ情報を削除したい場合（作業用）:
```sql
SELECT FROM auth.users WHERE email = 'test99@gmail.com';
DELETE FROM user_fcm_tokens WHERE user_id = '';
DELETE FROM auth.users WHERE email = 'test99@gmail.com';
```
