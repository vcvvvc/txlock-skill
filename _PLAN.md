# TXLock Skill 实现计划

> **注意：如果你是AI Agent，请忽略本文件。这是历史规划文档，执行指令请参考 SKILL.md。**

---

## 目标
创建交互式加解密skill，支持enc/dec/verify/status操作，自动处理二进制依赖。

## Context（研究结论）

### 项目结构
- 二进制位置：`bin/txlock-{enc,dec}`
- 命令行接口：
  - enc: `-in <file> -mnemonic-env <ENV> -index <N>`
  - dec: `-in <file> -mnemonic-env <ENV> -index <N>`
- 退出码：0成功/1参数错误/2处理失败

### Skill系统规范
- 位置：`.claude/skills/<name>/SKILL.md`
- Frontmatter必需字段：name, description
- 可选字段：disable-model-invocation, allowed-tools
- 参数：通过 `$ARGUMENTS` 获取
- 动态注入：`!`command`` 在skill加载前执行

### 二进制依赖策略（熵减方案）

**原则**：Skill只负责调用工具，不负责安装工具。

1. **检测顺序**（最小复杂度）：
   - `which txlock-enc` 和 `which txlock-dec` (PATH中)
   - `./bin/txlock-enc` 和 `./bin/txlock-dec` (当前项目)

2. **找不到时的处理**：
   - 显示清晰的错误信息
   - 提供完整的安装指引
   - 不自动执行任何安装操作

3. **安装指引内容**：
   ```
   ❌ 未找到TXLock二进制文件

   请选择安装方式：

   方式1：从源码编译（推荐）
   ────────────────────────────────
   git clone https://github.com/vcvvvc/TXLock.git
   cd TXLock
   go build -o ./bin/txlock-enc ./cmd/txlock-enc
   go build -o ./bin/txlock-dec ./cmd/txlock-dec

   # 选项A：全局安装
   sudo install -m 0755 bin/txlock-enc /usr/local/bin/
   sudo install -m 0755 bin/txlock-dec /usr/local/bin/

   # 选项B：在当前项目使用
   cp TXLock/bin/txlock-* ./bin/

   方式2：下载预编译版本
   ────────────────────────────────
   # 访问 https://github.com/vcvvvc/TXLock/releases
   # 下载对应平台的二进制文件

   安装完成后，重新运行此命令。
   ```

## Checklist（执行步骤）

### Phase 1: 核心Skill文件
- [x] 创建 `SKILL.md` 主文件
  - [x] Frontmatter配置
  - [x] 参数解析逻辑
  - [x] 操作分发（enc/dec/verify/status）
  - [x] 二进制检测与安装流程

### Phase 2: 辅助文件
- [x] 创建 `README.md` 使用文档
- [x] 创建 `config.example` 配置模板
- [x] 创建 `.gitignore` 保护敏感配置
- [x] 创建 `scripts/check-env.sh` 环境检查脚本

### Phase 3: 操作实现
- [x] **enc**: 加密文件
  - [x] 参数收集（file, index）
  - [x] 环境变量检查
  - [x] 调用 txlock-enc
  - [x] 输出结果

- [x] **dec**: 解密文件
  - [x] 参数收集（file, index）
  - [x] 环境变量检查
  - [x] 调用 txlock-dec
  - [x] 输出结果

- [x] **verify**: Round-trip验证
  - [x] 加密文件
  - [x] 解密文件
  - [x] 字节级比较（cmp）
  - [x] 报告结果

- [x] **status**: 查看lockfile状态
  - [x] 列出 lockfile/lock/ 文件
  - [x] 列出 lockfile/unlock/ 文件
  - [x] 显示统计信息

### Phase 4: 二进制检测（熵减）
- [x] 实现检测函数
  - [x] 使用 `which txlock-enc` 检查PATH
  - [x] 检查 `./bin/txlock-enc` 当前项目
  - [x] 返回找到的路径或空

- [x] 实现错误提示函数
  - [x] 显示清晰的错误信息
  - [x] 提供完整安装指引（源码编译 + 预编译下载）
  - [x] 包含仓库地址：`https://github.com/vcvvvc/TXLock.git`
  - [x] 说明全局安装和项目安装两种选项

### Phase 5: 配置与交互
- [x] 配置文件支持
  - [x] 读取 config 文件
  - [x] 默认值：MNEMONIC_ENV=MNEM, DEFAULT_INDEX=777
  - [x] 命令行参数覆盖

- [x] 环境变量检测
  - [x] 检查环境变量是否已设置
  - [x] 如果未设置，显示设置指引
  - [x] 指引包含：临时export + 持久化脚本（~/.txlock-env.sh）
  - [x] **不通过CLI交互询问助记词**（安全考虑）

- [x] 交互式参数收集
  - [x] 使用 AskUserQuestion（可选增强，当前通过清晰错误提示实现）
  - [x] 文件路径选择（通过命令行参数提供）
  - [x] Index输入（使用默认值或命令行参数）
  - [x] **不询问助记词**（从环境变量读取）

### Phase 6: 测试与文档
- [ ] 测试场景（需要用户实际测试）
  - [ ] 全局安装存在
  - [ ] 项目本地存在
  - [ ] 需要自动安装
  - [ ] 各操作正常执行

- [x] 文档完善
  - [x] 使用示例（README.md，已熵减）
  - [x] 故障排查（README.md，已熵减）
  - [x] 安全提示（README.md，已熵减）

## 技术决策（熵减原则）

### 为什么只检测不安装？
- **职责单一**：Skill负责调用工具，不负责管理工具
- **最小复杂度**：避免网络、编译、权限等不可控因素
- **用户自主**：安装方式由用户根据场景决定
- **Unix哲学**：工具在PATH中，skill只负责调用

### 为什么PATH优先？
- **标准惯例**：遵循Unix/Linux工具查找规则
- **灵活性**：用户可以用任何方式安装（包管理器、手动编译等）
- **可预测**：`which` 命令行为明确，无歧义

### 为什么提供详细指引？
- **降低门槛**：新用户能快速上手
- **多种选择**：源码编译 vs 预编译，全局 vs 项目
- **自助服务**：用户根据自己的环境选择最佳方案

### 参数处理策略
- 配置文件提供默认值（可选）
- 命令行参数覆盖配置
- 缺少必要参数时交互询问
- 优先级：命令行 > 交互 > 配置 > 硬编码默认

## 安全考虑

1. **助记词保护（方案2：临时脚本）**
   - 用户创建 `~/.txlock-env.sh` 存储助记词
   - 文件权限设置为 600（仅自己可读写）
   - 不在项目目录，不提交git
   - 使用前 `source ~/.txlock-env.sh`
   - Skill只读取环境变量，不通过CLI交互询问助记词

2. **环境变量检测**
   - 检查 `$MNEM`（或config中配置的变量名）是否已设置
   - 如果未设置，显示设置指引（临时export + 持久化脚本）
   - 不在skill中输入助记词（避免命令历史、日志上传）

3. **配置文件安全**
   - `config` 文件只存储环境变量**名称**，不存储助记词
   - `config` 被gitignore保护
   - `config.example` 作为模板，不包含敏感信息

## 输出格式

### 成功示例
```
🔐 TXLock 加密操作
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
输入文件: docs/test.md
助记词环境变量: MNEM
Index: 777

✅ 加密成功
输出文件: ./lockfile/lock/test.md.lock
文件大小: 1.2 KB
```

### 需要安装示例
```
⚠️  未找到txlock二进制文件

将执行以下操作：
  1. Clone https://github.com/vcvvvc/TXLock.git 到 /tmp/TXLock
  2. 编译二进制文件
  3. 安装到 /usr/local/bin/ (需要sudo权限)
  4. 清理临时目录

是否继续？(y/N)
```

## 依赖
- Go 1.25.7+ (用于编译)
- Git (用于clone)
- sudo权限 (用于全局安装)
