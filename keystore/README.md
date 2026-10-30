# 签名说明

`android/key.properties` 里的 `storeFile` 是**相对于 `android/` 目录**的路径（Gradle 用 `rootProject.file()` 解析）。
所以密钥放在 `android/keystore/` 下时写：

```properties
storeFile=keystore/paper-todo.jks
```

放在仓库根目录的 `keystore/` 下时写：

```properties
storeFile=../keystore/paper-todo.jks
```

`android/keystore/`、`key.properties`、`*.jks` 都已在 `.gitignore` 里，不会被提交。