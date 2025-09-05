#!/bin/bash
# EasyTier 管理脚本 - et.sh
# 功能：启动 / 停止 / 查看状态 / 修改配置

CONFIG_FILE="/etc/easytier.conf"
ET_BIN="easytier"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# 读取配置
load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  else
    ET_USER=""
    ET_PASS=""
    ET_ADDR=""
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

# 修改配置
set_config() {
  load_config
  echo -e "⚙️  ${YELLOW}设置 EasyTier 参数${NC}"

  read -p "用户名 [当前: $ET_USER]: " input
  ET_USER=${input:-$ET_USER}

  read -s -p "密码 [当前: $ET_PASS]: " input
  echo
  ET_PASS=${input:-$ET_PASS}

  read -p "共享节点 [当前: $ET_ADDR]: " input
  ET_ADDR=${input:-$ET_ADDR}

  read -p "固定IP (留空则自动分配): " input
  ET_IP=${input:-""}

  save_config
  echo -e "${GREEN}✅ 配置已保存${NC}"
}

# 启动 EasyTier
start_et() {
  load_config
  if pgrep -x "$ET_BIN" >/dev/null; then
    echo -e "${YELLOW}⚠️ EasyTier 已经在运行${NC}"
    return
  fi

  CMD="$ET_BIN --user $ET_USER --password $ET_PASS --server $ET_ADDR"
  if [ -n "$ET_IP" ]; then
    CMD="$CMD --ip $ET_IP"
  fi

  nohup $CMD >/var/log/easytier.log 2>&1 &
  echo -e "${GREEN}🚀 EasyTier 已启动${NC}"
}

# 停止 EasyTier
stop_et() {
  pkill -x "$ET_BIN" && echo -e "${RED}🛑 EasyTier 已停止${NC}" || echo -e "${YELLOW}⚠️ EasyTier 未运行${NC}"
}

# 查看状态
status_et() {
  if pgrep -x "$ET_BIN" >/dev/null; then
    echo -e "${GREEN}✅ EasyTier 正在运行${NC}"
    ps -ef | grep "$ET_BIN" | grep -v grep
  else
    echo -e "${RED}❌ EasyTier 未运行${NC}"
  fi
}

# 主菜单
menu() {
  clear
  echo -e "${CYAN}========= EasyTier 管理脚本 =========${NC}"
  echo -e "1. 启动 EasyTier"
  echo -e "2. 停止 EasyTier"
  echo -e "3. 查看状态"
  echo -e "4. 修改配置"
  echo -e "0. 退出"
  echo -e "${CYAN}====================================${NC}"
  read -p "请选择操作: " choice

  case $choice in
    1) start_et ;;
    2) stop_et ;;
    3) status_et ;;
    4) set_config ;;
    0) exit 0 ;;
    *) echo -e "${RED}❌ 无效选择${NC}" ;;
  esac
}

# 循环菜单
while true; do
  menu
  read -p "按回车键继续..." enter
done
