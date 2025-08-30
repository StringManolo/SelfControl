# SelfControl

[Youtube Demo](https://youtube.com/watch?v=4BiNTJSltBQ)

Control your Android device programatically without root. 
Binds a tcp local server to port 5000. 
You can send **"commands"** to the server with any network client.
It uses JSON format  

## Important
This sofrware is under early development. If u read this message means that the app is not ready for estable usage. You can play with it and should work, but probably has bugs.

If you don't know how to stoo the service from running, just disable accesibility for the app. Or just uninstall it and reinstall it after.

#### **Commands**
```bash
echo '{"action":"tap","x":500,"y":1000}' | ncat 127.0.0.1 5000
```

### SECURITY
There is no malware or backdoors in this app. Make sure you get it from this repo and nowhere else. 

The app opens the local port number 5000. If you have it exposed to the network, an attacker can find it and bruteforce taps to understand how to get full control of your device. 

Also be carefull where the fuck u send the clicks. You might uninstall or delete stuff in your phone by accident. 

Ask me any questions at t.me/stringmanolo
