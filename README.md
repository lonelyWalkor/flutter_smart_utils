# smart_utils

## webview 页面参数
|  key   | 值  | 默认值 | 是否必填 | 备注 |
|  ----  | ----  | ---- | ---- | ---- |
| initialUrl | <url> | | 是 |
| userAgent | String | | 否 |
| channelName | String | NativeFun | 否 |
| processColor | Color | | 否 |
| safeAreaBg | Color | | 否 |


### jsChannel 方法说明
|  方法名   | 说明  | 请求参数 | 响应 | 备注 |
|  ----  | ----  | ---- | ---- | ---- |
| Toaster | toast提示 | String msg | null |
| CloseApp | 退出app | 
| StartPosition | 启动位置监听 | int interval | String success / fail | interval 定位间隔时间 |
| StopPosition | 停止位置监听 |
| ChooseMedia| 选择媒体文件 | 见：mediaOption | Array<String base64Image> |
| setStatusBarColor| 设置状态栏颜色 | String color | String success / fail | color 不带#号 例：000000 |
| Wakelock | 设置屏幕常亮 | bool state | String success / fail | state true 开启屏幕常亮 false关闭屏幕常亮 |
| WakelockState | 获取当前的屏幕常量锁的状态 | | bool true / false | |
| GetVolume | 获取音量大小 | | double 4.002 |
| SetVolume | 设置音量大小 | double volume | String success / fail |  |
| Speak | 语音读文字 | String text | string success / fail | |
| WechatShare| 微信分享 | 见 WechatShareOptions |
| Scan | 跳转到扫描二维码页面 |
| LaunchJPush| 启动极光推送 | appKey channel |
| NotificationEnabled |
| OpenNotificationSetting |
| SetJPushTags | 设置极光推送的tags |
| GetJPushTags | 获取极光推送的tags | | {"tags":\["Shop5909"\]} |
| StopJPush | 停止极光推送 |
| ResumeJPush | 重启极光推送 |
| ScanBlue | 扫描蓝牙 |
| ConnectBlue | 链接蓝牙 | name, address, type, alias |
| DisConnectBlue | 断开蓝牙 | name, address, type, alias |
| ConnectedItem | 蓝牙链接设备 | alias |
| PrintTicket | 打印小票 | url , alias, pageSize |
| TestPrintTicket | 打印测试小票 | alias |


### flutter 调用 web 方法说明
|  方法名   | 说明  | data | flag | 备注 |
|  ----  | ----  | ---- | ---- | ---- |
| positionChanged | 位置改变的时候回调 | 位置的map信息 |  | {"callbackTime":"2022-06-17 14:40:30","locationTime":"2022-06-17 14:29:54","locationType":4,"latitude":30.535718,"longitude":104.060842,"accuracy":44.0,"altitude":0.0,"bearing":0.0,"speed":0.0,"country":"中国","province":"四川省","city":"成都市","district":"武侯区","street":"吉泰路","streetNumber":"12号","cityCode":"028","adCode":"510107","address":"四川省成都市武侯区吉泰路12号靠近高新区灵均幼儿园","description":"在高新区灵均幼儿园附近"} |
| volumeChanged | 系统音量改变的时候调用 |  
| receiveJPushMessage | 收到极光的推送消息 | Map jPushMessage | '' |

### mediaOption
|  key   | 可选值 | 默认值 | 备注 | 备注 |
|  ----  | ----  | ---- | ---- | ---- |
| type | image video | image | 选择的文件类型 | |
| source | photo camera | photo | 文件来源，相册/相机 |


### WechatShareOptions
|  key   | 值 | 默认值 | 备注 | 备注 |
|  ----  | ----  | ---- | ---- | ---- |
| shareType | int |  | 1 web页面 2 小程序 | |
| scene | int | | scene 0 1 2 聊天界面 朋友圈 收藏 |
| webpageUrl |  | | 必填 |
| title |  | | 必填 |
| description | | | 必填 |
| imgUrl | | | 必填 |
| miniappId | | | 小程序分享必填 |
| path | | | 小程序分享必填 |


android
```
minSdkVersion 21
```

ios 
```
OSX version: 10.15
```