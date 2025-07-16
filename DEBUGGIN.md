# Whitenoise flutter app debugging

## Analyzing rust logs

### For IOS

```bash
cd $HOME/Library/Developer/CoreSimulator/Devices/<DEVICE_ID>/data/Containers/Data/Application
# For instance IOS 16 Plus had a device id of `AB5EA81D-B9D8-4608-9CFB-DC125C0BA585`
log_path=$(find . -type f -name "whitenoise.<YYYY>-<MM>-<DD>.log")
tail -f $log_path
```