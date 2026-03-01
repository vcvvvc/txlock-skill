#!/bin/bash
# TXLock 环境检查脚本
# Why: 在执行加解密操作前，验证所有必需的依赖和配置是否就绪

set -euo pipefail

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' N='\033[0m'
ALL_OK=true

# Why: 抽取重复的二进制检查逻辑，减少代码重复
check_bin() {
    local name=$1
    echo "$2. 检查 $name..."
    if command -v "$name" &>/dev/null; then
        echo -e "   ${G}✓${N} $(which "$name")"
    elif [ -x "./bin/$name" ]; then
        echo -e "   ${G}✓${N} ./bin/$name"
    else
        echo -e "   ${R}✗${N} 未找到 $name"
        ALL_OK=false
    fi
}

echo "🔍 TXLock 环境检查"
check_bin txlock-enc 1
check_bin txlock-dec 2

# Why: 从配置文件读取环境变量名，无配置则用默认值
MNEMONIC_ENV="MNEM"
CFG=".claude/skills/txlock/config"
[ -f "$CFG" ] && MNEMONIC_ENV=$(grep "^MNEMONIC_ENV=" "$CFG" 2>/dev/null | cut -d'=' -f2 || echo "MNEM")

echo "3. 检查助记词环境变量 \$$MNEMONIC_ENV..."
if [ -n "${!MNEMONIC_ENV:-}" ]; then
    echo -e "   ${G}✓${N} 已设置 (${#!MNEMONIC_ENV} 字符)"
else
    echo -e "   ${R}✗${N} 未设置"
    ALL_OK=false
fi

# Why: 简洁输出结果，失败时仅提供核心修复命令
if [ "$ALL_OK" = true ]; then
    echo -e "\n${G}✅ 环境就绪${N}"
    exit 0
fi

echo -e "\n${R}❌ 环境缺失${N}"
command -v txlock-enc &>/dev/null || echo "修复: go build -o ./bin/txlock-enc ./cmd/txlock-enc"
command -v txlock-dec &>/dev/null || echo "修复: go build -o ./bin/txlock-dec ./cmd/txlock-dec"
[ -z "${!MNEMONIC_ENV:-}" ] && echo "修复: export $MNEMONIC_ENV=\"your mnemonic phrase\""
exit 1
