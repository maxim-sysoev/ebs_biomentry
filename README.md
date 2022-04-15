# ebs_biometry

## iOS

Необходимо добавить в файл `info.plist` следующий код:

```
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>ebs</string>
</array>
```

Чтобы приложение биометрии смогло вернуть данные необходимо объявить Url scheme и передать её 
при инициализации плагина

```
  EbsBiometry.configureSdk(
    appScheme: 'testexpample',
    infoSystem: 'infoSystem',
    appTitle: 'appTitle',
  );
```

Если используется библиотека `uni_links` для открытия ссылок в приложении, то можно переопределить
функцию `application` в файле `AppDelegate.swift`, чтобы обработать callback из приложения 
биометрии.

```swift
import UIKit
import Flutter
import EbsSDK

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var sdk =  EbsSDKClient.shared

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let esiaScheme = "<scheme>";
        if (url.scheme == esiaScheme) {
            sdk.process(openUrl: url, options: options)
            return true
        }
        
        return super.application(app, open: url, options: options)
    }
}
```

## Android

`MainActivity` должен наследоваться от `FlutterFragmentActivity`

Добавить пермишен `<uses-permission android:name="ru.rtlabs.mobile.ebs.permission.VERIFICATION" />`

