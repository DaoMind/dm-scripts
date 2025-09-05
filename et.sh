#!/bin/bash
# EasyTier 一键部署脚本

APP_DIR="/srv/app/easytier"
SCRIPT_NAME="et.sh"
SCRIPT_PATH="$APP_DIR/$SCRIPT_NAME"
CONFIG_FILE="$APP_DIR/easytier.conf"
LOG_FILE="/var/log/easytier.log"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 初始化目录并自复制
init_dir() {
    if [ ! -d "$APP_DIR" ]; then
        echo -e "${YELLOW}📦 正在创建目录: $APP_DIR${NC}"
        mkdir -p "$APP_DIR"
    fi

    if [ "$(realpath "$0")" != "$SCRIPT_PATH" ]; then
        echo -e "${YELLOW}➡️  正在复制脚本到 $SCRIPT_PATH${NC}"
        cp "$0" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        echo -e "${GREEN}✅ 已复制，重新执行新脚本...${NC}"
        exec "$SCRIPT_PATH" "$@"
    fi
}

# 加载配置
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        ET_USER="test8888"
        ET_PASS="12345678"
        ET_ADDR="tcp://turn.js.629957.xyz:11012"
        ET_IP=""
    fi
}

# 保存配置
save_config() {
    cat > "$CONFIG_FILE" <<EOF
ET_USER="$ET_USER"
ET_PASS="$ET_PASS"
ET_ADDR="$ET_ADDR"
ET_IP="$ET_IP"
EOF
}

# 配置
config_et() {
    load_config
    echo -e "${YELLOW}⚙️ 当前配置:${NC}"
    echo "用户名: $ET_USER"
    echo "密码:   $ET_PASS"
    echo "地址:   $ET_ADDR"
    echo "IP:     $ET_IP"

    read -p "用户名 [默认: $ET_USER]: " input
    ET_USER=${input:-$ET_USER}

    read -p "密码 [默认: $ET_PASS]: " input
    ET_PASS=${input:-$ET_PASS}

    read -p "服务器地址 [默认: $ET_ADDR]: " input
    ET_ADDR=${input:-$ET_ADDR}

    read -p "虚拟IP [默认: 自动分配]: " input
    ET_IP=${input:-$ET_IP}

    save_config
    echo -e "${GREEN}✅ 配置已保存${NC}"
}

# 启动
start_et() {
    load_config
    CMD="docker run -d --name easytier \
        --restart unless-stopped \
        -e ET_USER=$ET_USER \
        -e ET_PASS=$ET_PASS \
        -e ET_ADDR=$ET_ADDR"

    [ -n "$ET_IP" ] && CMD="$CMD -e ET_IP=$ET_IP"

    CMD="$CMD containrrr/easytier"

    echo -e "${YELLOW}🚀 启动 EasyTier...${NC}"
    $CMD >>"$LOG_FILE" 2>&1

    sleep 2
    status_et
}

# 停止
stop_et() {
    docker rm -f easytier >/dev/null 2>&1 \
        && echo -e "${RED}🛑 EasyTier 已停止${NC}" \
        || echo -e "${RED}⚠️ EasyTier 未运行${NC}"
}

# 状态
status_et() {
    if docker ps | grep -q easytier; then
        echo -e "${GREEN}✅ EasyTier 正在运行${NC}"
        docker exec easytier ip addr show tun0 2>/dev/null | grep "inet " || \
            echo -e "${RED}⚠️ 未获取虚拟 IP${NC}"
    else
        echo -e "${RED}❌ EasyTier 未运行${NC}"
    fi
}

# 查看日志
logs_et() {
    [ -f "$LOG_FILE" ] \
        && tail -n 30 "$LOG_FILE" \
        || echo -e "${RED}⚠️ 无日志文件${NC}"
}

# 入口
init_dir "$@"

case "$1" in
    -cf|config) config_et ;;
    -up|up) start_et ;;
    -st|status|-ck) status_et ;;
    -lg|logs) logs_et ;;
    -stop|stop) stop_et ;;
    "" ) config_et && start_et ;; # 第一次运行
    *) echo -e "${YELLOW}用法: $0 [参数]${NC}
  无参数      初始化配置并启动
  -cf|config 修改配置
  -up|up     手动启动
  -st|-ck    查看状态
  -lg|logs   查看日志
  -stop      停止容器"
    ;;
esac

