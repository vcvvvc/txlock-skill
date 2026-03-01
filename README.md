# TXLock Skill 使用文档

基于BIP39/44助记词的离线加解密工具，通过Claude Code skill机制提供交互式操作。

## 安装

### 1. 编译二进制

```bash
git clone https://github.com/vcvvvc/TXLock.git
cd TXLock
go build -o ./bin/txlock-enc ./cmd/txlock-enc
go build -o ./bin/txlock-dec ./cmd/txlock-dec

# 全局安装
sudo install -m 0755 bin/txlock-{enc,dec} /usr/local/bin/

# 或项目本地
mkdir -p ./bin && cp TXLock/bin/txlock-* ./bin/
```

### 2. 配置助记词

创建`~/.txlock-env.sh`：

```bash
#!/bin/bash
export MNEM="your twelve word mnemonic phrase here"
```

设置权限并加载：

```bash
chmod 600 ~/.txlock-env.sh
source ~/.txlock-env.sh
```

## 使用

```bash
/txlock enc <file> [-index N]    # 加密（默认index=777）
/txlock dec <file> [-index N]    # 解密
/txlock verify <file> [-index N] # Round-trip验证
/txlock status                   # 查看lockfile状态
```

## 安全原则

### ✅ 必须

1. 助记词存储在`~/.txlock-env.sh`（权限600）
2. 通过`source`加载，不在命令行输入
3. 记录每个文件的index（丢失=无法解密）
4. 加密后用`verify`验证

### ❌ 禁止

1. 命令行直接输入助记词（shell history泄露）
2. 助记词存储在项目目录（git提交风险）
3. 相同index加密不同文件（安全性降低）
4. 忘记记录index

## 故障排查

### 未找到二进制

```bash
which txlock-enc txlock-dec  # 检查PATH
ls -l ./bin/txlock-*         # 检查项目本地
```

### 环境变量未设置

```bash
export MNEM="..."            # 临时设置
source ~/.txlock-env.sh      # 或加载脚本
```

### 解密失败

可能原因：Index错误、助记词错误、文件损坏

## 协议

v1协议（已冻结）：
- 路径：`m/44'/60'/0'/0/{index}`
- KDF：HKDF-SHA256
- AEAD：AES-256-GCM
- 格式：HTML注释块

保证10年后可恢复。

## 链接

- [项目](https://github.com/vcvvvc/TXLock)
- [协议文档](https://github.com/vcvvvc/TXLock/blob/main/docs/protocol.md)
- [问题反馈](https://github.com/vcvvvc/TXLock/issues)
