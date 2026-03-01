#!/bin/bash
# TXLock 环境检查脚本
# Why: 在执行加解密操作前，验证所有必需的依赖和配置是否就绪

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查结果标志
ALL_OK=true

echo "🔍 TXLock 环境检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. 检查 txlock-enc 二进制
echo "1. 检查 txlock-enc..."
if command -v txlock-enc &> /dev/null; then
    ENC_PATH=$(which txlock-enc)
    echo -e "   ${GREEN}✓${NC} 找到: $ENC_PATH"
elif [ -x "./bin/txlock-enc" ]; then
    echo -e "   ${GREEN}✓${NC} 找到: ./bin/txlock-enc (项目本地)"
else
    echo -e "   ${RED}✗${NC} 未找到 txlock-enc"
    ALL_OK=false
fi

# 2. 检查 txlock-dec 二进制
echo "2. 检查 txlock-dec..."
if command -v txlock-dec &> /dev/null; then
    DEC_PATH=$(which txlock-dec)
    echo -e "   ${GREEN}✓${NC} 找到: $DEC_PATH"
elif [ -x "./bin/txlock-dec" ]; then
    echo -e "   ${GREEN}✓${NC} 找到: ./bin/txlock-dec (项目本地)"
else
    echo -e "   ${RED}✗${NC} 未找到 txlock-dec"
    ALL_OK=false
fi

# 3. 读取配置文件（如果存在）
MNEMONIC_ENV="MNEM"
CONFIG_FILE=".claude/skills/txlock/config"

if [ -f "$CONFIG_FILE" ]; then
    echo "3. 读取配置文件..."
    echo -e "   ${GREEN}✓${NC} 找到配置: $CONFIG_FILE"

    # 读取 MNEMONIC_ENV
    if grep -q "^MNEMONIC_ENV=" "$CONFIG_FILE"; then
        MNEMONIC_ENV=$(grep "^MNEMONIC_ENV=" "$CONFIG_FILE" | cut -d'=' -f2)
        echo "   环境变量名: $MNEMONIC_ENV"
    fi
else
    echo "3. 配置文件..."
    echo -e "   ${YELLOW}⚠${NC}  未找到配置文件（使用默认值）"
    echo "   环境变量名: $MNEMONIC_ENV (默认)"
fi

# 4. 检查助记词环境变量
echo "4. 检查助记词环境变量..."
if [ -n "${!MNEMONIC_ENV:-}" ]; then
    MNEM_LENGTH=${#!MNEMONIC_ENV}
    echo -e "   ${GREEN}✓${NC} 环境变量 \$$MNEMONIC_ENV 已设置 (长度: $MNEM_LENGTH)"
else
    echo -e "   ${RED}✗${NC} 环境变量 \$$MNEMONIC_ENV 未设置"
    ALL_OK=false
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 输出最终结果
if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}✅ 环境检查通过，可以使用 TXLock${NC}"
    exit 0
else
    echo -e "${RED}❌ 环境检查失败，请按照以下指引修复${NC}"
    echo ""

    # 提供修复指引
    if ! command -v txlock-enc &> /dev/null && [ ! -x "./bin/txlock-enc" ]; then
        echo "📦 安装 TXLock 二进制："
        echo ""
        echo "方式1：从源码编译（推荐）"
        echo "────────────────────────────────"
        echo "git clone https://github.com/vcvvvc/TXLock.git"
        echo "cd TXLock"
        echo "go build -o ./bin/txlock-enc ./cmd/txlock-enc"
        echo "go build -o ./bin/txlock-dec ./cmd/txlock-dec"
        echo ""
        echo "# 选项A：全局安装"
        echo "sudo install -m 0755 bin/txlock-enc /usr/local/bin/"
        echo "sudo install -m 0755 bin/txlock-dec /usr/local/bin/"
        echo ""
        echo "# 选项B：在当前项目使用"
        echo "mkdir -p ./bin"
        echo "cp TXLock/bin/txlock-* ./bin/"
        echo ""
        echo "方式2：下载预编译版本"
        echo "────────────────────────────────"
        echo "访问 https://github.com/vcvvvc/TXLock/releases"
        echo ""
    fi

    if [ -z "${!MNEMONIC_ENV:-}" ]; then
        echo "🔐 设置助记词环境变量："
        echo ""
        echo "临时设置（当前会话）："
        echo "────────────────────────────────"
        echo "export $MNEMONIC_ENV=\"your twelve word mnemonic phrase here\""
        echo ""
        echo "持久化设置（推荐）："
        echo "────────────────────────────────"
        echo "# 创建 ~/.txlock-env.sh"
        echo "cat > ~/.txlock-env.sh << 'EOF'"
        echo "#!/bin/bash"
        echo "export $MNEMONIC_ENV=\"your twelve word mnemonic phrase here\""
        echo "EOF"
        echo ""
        echo "# 设置权限"
        echo "chmod 600 ~/.txlock-env.sh"
        echo ""
        echo "# 使用前加载"
        echo "source ~/.txlock-env.sh"
        echo ""
    fi

    exit 1
fi
