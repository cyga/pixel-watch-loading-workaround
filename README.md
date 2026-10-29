# Links

* [reddit set en only for sys UI](https://www.reddit.com/r/PixelWatch/comments/1woukvw/pixel_watch_5_loading_screen_during_workout/?solution=225eedc5bda71677225eedc5bda71677&js_challenge=1&jsc_token=2824be10929bdc604753c70a67a1c3313c7d963f041b989e7e07b0abc3c34410&jsc_orig_r=&hl=ru-RU)
* [discussion](https://4pda.to/forum/index.php?showtopic=1123993#entry145000337)

# HOWTO

```bash
adb pair IP_PAIR:PORT_PAIR CODE
# should be successfull

# connect variant (differs from pairing)
IP=""
PORT=""

adb connect "$IP:$PORT" CODE

adb devices -l
# List of devices attached
# 192.168.0.158:35017    offline product:meridian_btwifi model:Pixel_Watch_4 device:meridian_btwifi transport_id:10

# check:
adb -s "$IP:$PORT" shell dumpsys activity processes com.google.android.wearable.sysui | grep -m1 -o 'Configuration={[^]]*]'
adb -s "$IP:$PORT"  shell cmd locale get-app-locales com.google.android.wearable.sysui
# Locales for com.google.android.wearable.sysui for user 0 are [en-US]

./fix-watch-loading.sh
# detect address
# Часы не найдены в сети. Включите отладку по Wi-Fi или укажите адрес: ./fix-watch-loading.sh IP:PORT
# Documents/Health/pixels ❯ adb -s "192.168.0.34:33351" shell cmd locale get-app-locales com.google.android.wearable.sysui                                                 took 5s
# Documents/Health/pixels ❯ ./fix-watch-loading.sh
# detect address
# connecting...
# wait for device
# reset locale
# set locale to en-US
# Локаль процесса SystemUI: [en_US,ru_RU]
# OK — можно запускать тренировку
```
```
