# Pixel Watch: «Loading…» во время тренировки на русском языке

Обходное решение для бага Wear OS на Pixel Watch: если язык часов русский, во время
тренировки экран зависает на «Loading…» («Загрузка…»).

*English summary: on Pixel Watch with the Russian UI language, Wear SystemUI crash-loops
while showing the workout live update, because the Russian translation of an accessibility
string contains unescaped double quotes. Forcing `en-US` for SystemUI only works around it.
This repo contains an adb script and a tiny Wear OS app that re-applies the override after
every reboot and allows user to apply the fix without configuring adb anymore.*

## Проблема

Во время тренировки (Fitbit Exercise, Strava и другие) часы показывают «живое» уведомление
о текущей активности. Каждый раз, когда SystemUI (`com.google.android.wearable.sysui`)
пытается его обновить, он падает и перезапускается — примерно раз в 5 секунд. Между
перезапусками виден экран «Loading…».

В `adb logcat`:

```
KoruException: GLUI: parse_template_literal_string.c:214: Error 22
Error setting item data: 'aria-expression'
```

## Причина

Текст для экранного диктора SystemUI подставляет в выражение как строку в двойных кавычках.
В русском переводе (`PixelWatchSysUi.apk`) название приложения само взято в кавычки,
и они не экранированы:

```
Уведомление из приложения "%1$s": текущее
```

Строка обрывается на середине, разбор падает. В английском (`%1$s notification: Ongoing`)
и датском (`%1$s-notifikation: Igangværende`) вариантах кавычек нет, там всё работает.
Исправить это может только Google.

## Обход

Переключить на `en-US` **только SystemUI**. Язык самих часов и приложений остаётся русским,
по-английски станут только системные элементы (шторка, уведомления).

Подвох: после перезагрузки часов настройка формально сохраняется
(`get-app-locales` показывает `[en-US]`), но процесс SystemUI снова поднимается с `ru_RU`.
Иногда это происходит даже без перезагрузки.
Поэтому её нужно применять заново после каждой перезагрузки или сброса — скриптом или приложением.

Проверено на Pixel Watch 4 (сборка CP3A.260905.002, SystemUI 7.2.8.14) и Pixel Watch 5, Wear OS на Android 17.

## Что нужно

- компьютер с `adb` ([Android platform-tools](https://developer.android.com/tools/releases/platform-tools));
- на часах режим разработчика и «Отладка по Wi-Fi», часы и компьютер в одной сети.

### Подключение к часам

1. На часах: Настройки → Система → О часах → Версии → 7 раз нажать на «Номер сборки».
2. Настройки → Для разработчиков → включить «Отладка по ADB» и «Отладка по Wi-Fi».
3. Пара (один раз): «Отладка по Wi-Fi» → «Подключить новое устройство», затем
   ```
   adb pair IP:PORT_FOR_PAIR КОД
   ```
   Если ответ `protocol fault (couldn't read status message)` — просто повторите команду.
4. Подключение (порт другой — с основного экрана «Отладка по Wi-Fi», меняется после перезагрузки):
   ```
   adb connect IP:PORT
   adb devices -l
   ```

## Вариант 1: скрипт

```
./fix-watch-loading.sh            # сам найдёт часы в сети
./fix-watch-loading.sh IP:PORT    # или по адресу
./fix-watch-loading.sh --undo     # снять переопределение
```

Нужно запускать после каждой перезагрузки часов. Для автопоиска нужен `avahi-browse` (Linux).

## Вариант 2: приложение на часах

`sysui-locale-fix/` — маленькое Wear OS-приложение «SysUI EN»: кнопка «Применить en-US»
и автоматический запуск примерно через 20 секунд после каждой загрузки. adb нужен только
один раз — для установки и выдачи разрешения.

Приложение вызывает `LocaleManager.setApplicationLocales()` для SystemUI. Для чужого пакета
нужно разрешение `android.permission.CHANGE_CONFIGURATION`; обычному приложению оно
недоступно, но у него уровень `development`, поэтому его можно выдать через `pm grant`.

### Сборка

Без Gradle и Android Studio: нужны JDK 17+, Android SDK `platforms;android-36`
и `build-tools;36.1.0`.

```
cd sysui-locale-fix
./build.sh        # → sysui-locale-fix.apk
```

Пути можно переопределить через `ANDROID_HOME` и `JAVA_HOME`
(по умолчанию `~/Android/Sdk` и `~/Android/jdk-21`). При первой сборке создаётся
`debug.keystore` — сохраните его: обновлять приложение поверх (`install -r`) можно
только APK с тем же ключом.

### Установка

```
./install.sh IP:PORT
```

или вручную:

```
adb -s IP:PORT install -r sysui-locale-fix.apk
adb -s IP:PORT shell pm grant dev.sasha.sysuilocale android.permission.CHANGE_CONFIGURATION
```

После установки **один раз откройте «SysUI EN» на часах** — иначе Android не пришлёт
приложению событие загрузки. Разрешение сохраняется при перезагрузках и обновлениях,
но пропадает, если удалить приложение.

## Проверка

```
adb -s IP:PORT shell dumpsys activity processes com.google.android.wearable.sysui | grep -m1 -o 'Configuration={[^]]*]'
```

- `[ru_RU]` — баг будет, нужно применить обход;
- `[en_US,ru_RU]` — всё в порядке.

`cmd locale get-app-locales …` показывает только сохранённую настройку, а не то,
с чем реально работает процесс, — после перезагрузки они расходятся.

## Откат

```
./fix-watch-loading.sh --undo
adb -s IP:PORT uninstall dev.sasha.sysuilocale
```

## Ссылки

- [Reddit: Pixel Watch 5 loading screen during workout](https://www.reddit.com/r/PixelWatch/comments/1woukvw/pixel_watch_5_loading_screen_during_workout/) — откуда взят обход с `set-app-locales`
- [Обсуждение на 4PDA](https://4pda.to/forum/index.php?showtopic=1123993#entry145000337)
