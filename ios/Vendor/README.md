# Vendor binaries

## `lsl.xcframework`

Official Lab Streaming Layer (liblsl) xcframework from [sccn/liblsl v1.17.7](https://github.com/sccn/liblsl/releases/tag/v1.17.7)
(`lsl.xcframework.1.17.zip`).

Module maps were added under each slice’s `Modules/` so Swift can `import lsl`.
Code signatures were removed so Xcode can process the modified local xcframework.

To refresh from upstream:

```bash
curl -L -o /tmp/lsl.xcframework.1.17.zip \
  https://github.com/sccn/liblsl/releases/download/v1.17.7/lsl.xcframework.1.17.zip
rm -rf ios/Vendor/lsl.xcframework
unzip -o /tmp/lsl.xcframework.1.17.zip -d ios/Vendor
# re-add Modules/module.modulemap to each slice and strip _CodeSignature if needed
```
