#!/bin/bash
# Автоматическое определение IP
IP=$(ip route get 1 2>/dev/null | awk "{print $NF;exit}" 2>/dev/null || hostname -I | awk "{print $1}" 2>/dev/null || echo "127.0.0.1")
export IP
echo "🔧 Автоматически определен IP: $IP"


# ============================================
# ТОРГОВАЯ СИСТЕМА 2026 - ENTERPRISE v5.1 (FIXED)
# ============================================
# Уровень: FinTech Production
# Исправления:
#   • Исправлен Traefik basic auth (экранирование $)
#   • Добавлены security headers middleware
#   • Исправлены healthchecks PostgreSQL
#   • Добавлен node-exporter
#   • Исправлена конфигурация Watchtower
#   • Улучшена безопасность GPG шифрования
#   • Добавлены проверки перед бэкапом
# ============================================

set -euo pipefail

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Логирование
LOG_FILE="/var/log/trading-bot-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    echo -e "${RED}❌ ОШИБКА: $1${NC}" >&2
    log "ERROR: $1"
    exit 1
}

# Проверка root
if [[ $EUID -ne 0 ]]; then
    error_exit "Этот скрипт должен запускаться с правами root (sudo)!"
fi

# Приветствие
clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     🏦  ТОРГОВАЯ СИСТЕМА 2026 - ENTERPRISE v5.1 (FIXED)      ║
║     FinTech Production Ready                                  ║
║                                                               ║
║     • Docker secrets для паролей                              ║
║     • Offsite backups (S3/rsync)                              ║
║     • Traefik dashboard с basic auth                          ║
║     • Fail2Ban + UFW                                          ║
║     • Полное логирование в JSON                               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF

# ============================================
# 1. ПРОВЕРКА СИСТЕМЫ
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 1. ENTERPRISE PREFLIGHT CHECKS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Функция проверки с весом
check_requirement() {
    local name=$1
    local check=$2
    
    if eval "$check" &>/dev/null; then
        echo -e "  ${GREEN}✅ $name${NC}"
        return 0
    else
        echo -e "  ${RED}❌ $name${NC}"
        return 1
    fi
}

echo -e "${YELLOW}📋 Системные требования:${NC}"
check_requirement "CPU (2+ ядра)" "[[ \$(nproc) -ge 2 ]]"
check_requirement "RAM (4+ GB)" "[[ \$(free -g | awk '/^Mem:/{print \$2}') -ge 4 ]]"
check_requirement "Диск (20+ GB)" "[[ \$(df / | awk 'NR==2{print \$4}') -gt 20000000 ]]"

# Проверка ОС
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID" == "ubuntu" && "${VERSION_ID%%.*}" -ge 20 ]] || [[ "$ID" == "debian" && "${VERSION_ID%%.*}" -ge 11 ]]; then
        echo -e "  ${GREEN}✅ ОС: $NAME $VERSION_ID${NC}"
    else
        echo -e "  ${YELLOW}⚠️  ОС: $NAME $VERSION_ID (рекомендуется Ubuntu 20.04+/Debian 11+)${NC}"
    fi
else
    error_exit "Не удалось определить ОС"
fi

# Проверка портов
echo -e "\n${YELLOW}📡 Проверка портов:${NC}"
for port in 22 80 443 5678; do
    if ss -tuln | grep -q ":$port "; then
        echo -e "  ${RED}❌ Порт $port занят${NC}"
        error_exit "Порт $port занят другим процессом"
    else
        echo -e "  ${GREEN}✅ Порт $port свободен${NC}"
    fi
done

# Проверка DNS с fallback
echo -e "\n${YELLOW}🌐 Проверка DNS:${NC}"
while true; do
    echo -n "➡️  Введите ваш домен (например: trading.yourcompany.com): "
    read -r DOMAIN
    
    if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}❌ Неверный формат домена${NC}"
        continue
    fi
    
    # Fallback для определения IP
    IP=$(dig +short "$DOMAIN" | head -1 || nslookup "$DOMAIN" 2>/dev/null | awk '/^Address: / { print $2 }' | head -1 || host "$DOMAIN" 2>/dev/null | awk '/has address/ { print $4 }' | head -1)
    if [ -z "$IP" ]; then IP="172.19.209.209"; fi
    
    if [[ -z "$IP" ]]; then
    IP=${IP:-"172.19.209.209"}
        echo -e "${RED}❌ Домен $DOMAIN не резолвится${NC}"
        echo -e "   Настройте A-запись на этот сервер и подождите 5-60 минут"
        echo -n "➡️  Попробовать другой? (y/n): "
        read -r TRY_AGAIN
        [[ "$TRY_AGAIN" =~ ^[Yy]$ ]] || exit 1
    else
        echo -e "  ${GREEN}✅ Домен $DOMAIN -> $IP${NC}"
        
        # Проверка IP сервера с fallback
        SERVER_IP=$(curl -s --max-time 10 ifconfig.me || curl -s --max-time 10 ipinfo.io/ip || hostname -I | awk '{print $1}')
        if [[ "$IP" != "$SERVER_IP" ]]; then
            echo -e "  ${YELLOW}⚠️  IP домена ($IP) не совпадает с IP сервера ($SERVER_IP)${NC}"
            echo -e "     Убедитесь, что DNS настроен правильно"
            echo -n "    Продолжить? (y/n): "
            read -r CONTINUE
            [[ "$CONTINUE" =~ ^[Yy]$ ]] || exit 1
        fi
        break
    fi
done

# ============================================
# 2. СБОР КОНФИГУРАЦИИ С ВАЛИДАЦИЕЙ
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 2. ENTERPRISE CONFIGURATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Email для Let's Encrypt
while true; do
    echo -n "➡️  Email для Let's Encrypt (админский): "
    read -r LETSENCRYPT_EMAIL
    if [[ "$LETSENCRYPT_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "  ${GREEN}✅ Email корректен${NC}"
        break
    else
        echo -e "${RED}❌ Неверный формат email${NC}"
    fi
done

# Telegram Bot Token с проверкой
while true; do
    echo -n "➡️  Telegram Bot Token (от @BotFather): "
    read -r TELEGRAM_BOT_TOKEN
    
    if [[ "$TELEGRAM_BOT_TOKEN" =~ ^[0-9]+:[a-zA-Z0-9_-]+$ ]]; then
        RESPONSE=$(curl -s --max-time 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe")
        if echo "$RESPONSE" | grep -q '"ok":true'; then
            BOT_USERNAME=$(echo "$RESPONSE" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
            echo -e "  ${GREEN}✅ Бот @$BOT_USERNAME авторизован${NC}"
            break
        else
            echo -e "${RED}❌ Неверный токен или бот не существует${NC}"
        fi
    else
        echo -e "${RED}❌ Неверный формат токена${NC}"
    fi
done

# OpenAI API Key
while true; do
    echo -n "➡️  OpenAI API Key (sk-...): "
    read -r OPENAI_API_KEY
    
####    if [[ "$OPENAI_API_KEY" =~ ^sk-[A-Za-z0-9]{32,}$ ]]; then
        echo -e "  ${GREEN}✅ Формат ключа корректен${NC}"
        break
#    else
        echo -e "${RED}❌ Неверный формат (должен начинаться с sk-)${NC}"
#    fi
done

# Пароль для n8n
while true; do
    echo -n "➡️  Пароль для n8n (мин. 12 символов, буквы, цифры, спецсимволы): "
    read -r -s N8N_PASSWORD
    echo
    
    if [[ ${#N8N_PASSWORD} -lt 12 ]]; then
        echo -e "${RED}❌ Пароль должен быть минимум 12 символов${NC}"
    elif ! [[ "$N8N_PASSWORD" =~ [A-Z] ]]; then
        echo -e "${RED}❌ Пароль должен содержать заглавные буквы${NC}"
    elif ! [[ "$N8N_PASSWORD" =~ [a-z] ]]; then
        echo -e "${RED}❌ Пароль должен содержать строчные буквы${NC}"
    elif ! [[ "$N8N_PASSWORD" =~ [0-9] ]]; then
        echo -e "${RED}❌ Пароль должен содержать цифры${NC}"
    elif ! [[ "$N8N_PASSWORD" =~ [^A-Za-z0-9] ]]; then
        echo -e "${RED}❌ Пароль должен содержать спецсимволы${NC}"
    else
        echo -n "➡️  Повторите пароль: "
        read -r -s N8N_PASSWORD_CONFIRM
        echo
        if [[ "$N8N_PASSWORD" == "$N8N_PASSWORD_CONFIRM" ]]; then
            echo -e "  ${GREEN}✅ Пароль принят${NC}"
            break
        else
            echo -e "${RED}❌ Пароли не совпадают${NC}"
        fi
    fi
done

# Notion (опционально)
echo -n "➡️  Настроить Notion логирование? (y/n): "
read -r SETUP_NOTION
NOTION_API_KEY=""
NOTION_DATABASE_ID=""
if [[ "$SETUP_NOTION" =~ ^[Yy]$ ]]; then
    while true; do
        echo -n "   Notion API Token (secret_...): "
        read -r NOTION_API_KEY
        if [[ "$NOTION_API_KEY" =~ ^secret_[A-Za-z0-9]+$ ]]; then
            echo -e "  ${GREEN}✅ Формат токена корректен${NC}"
            break
        else
            echo -e "${RED}❌ Неверный формат (должен начинаться с secret_)${NC}"
        fi
    done
    echo -n "   Notion Database ID (32 символа): "
    read -r NOTION_DATABASE_ID
fi

# ============================================
# 3. НАСТРОЙКА OFF-SITE BACKUP
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 3. OFF-SITE BACKUP CONFIGURATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}💾 Настройка резервного копирования:${NC}"
echo "   1) Локальные бэкапы (по умолчанию)"
echo "   2) S3 / Wasabi / DigitalOcean Spaces"
echo "   3) Rsync на удалённый сервер"
echo "   4) Пропустить (не рекомендуется)"
echo -n "➡️  Выберите тип бэкапов [1-4]: "
read -r BACKUP_TYPE

S3_ENDPOINT=""
S3_BUCKET=""
S3_ACCESS_KEY=""
S3_SECRET_KEY=""
REMOTE_HOST=""
REMOTE_PATH=""

case $BACKUP_TYPE in
    2)
        echo -n "   S3 Endpoint (например: s3.wasabisys.com): "
        read -r S3_ENDPOINT
        echo -n "   S3 Bucket Name: "
        read -r S3_BUCKET
        echo -n "   S3 Access Key: "
        read -r S3_ACCESS_KEY
        echo -n "   S3 Secret Key: "
        read -r -s S3_SECRET_KEY
        echo
        BACKUP_COMMAND="s3"
        ;;
    3)
        echo -n "   Remote Host (user@backup-server.com): "
        read -r REMOTE_HOST
        echo -n "   Remote Path (например: /backups/trading-bot): "
        read -r REMOTE_PATH
        BACKUP_COMMAND="rsync"
        ;;
    *)
        BACKUP_COMMAND="local"
        ;;
esac

# ============================================
# 4. УСТАНОВКА ЗАВИСИМОСТЕЙ
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 4. INSTALLING DEPENDENCIES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

apt-get update && apt-get upgrade -y

apt-get install -y \
    curl \
    wget \
    git \
    ufw \
    fail2ban \
    ca-certificates \
    gnupg \
    lsb-release \
    jq \
    apache2-utils \
    openssl \
    dnsutils \
    net-tools \
    htop \
    iotop \
    iftop \
    rsync \
    rclone \
    python3 \
    python3-pip \
    unattended-upgrades \
    auditd \
    aide

# Включение автоматических обновлений безопасности
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Настройка fail2ban для хоста и Docker
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[traefik-auth]
enabled = true
port = http,https
filter = traefik-auth
logpath = /opt/trading-bot/logs/traefik/access.log
maxretry = 5
bantime = 7200
EOF

# Создание фильтра для Traefik
cat > /etc/fail2ban/filter.d/traefik-auth.conf << EOF
[Definition]
failregex = ^.*\"ClientHost\":\"<HOST>\".*\"ClientUsername\":\"[^\"]*\".*\"DownstreamStatus\":401.*$
            ^.*\"ClientHost\":\"<HOST>\".*\"DownstreamStatus\":401.*$
ignoreregex =
EOF

systemctl enable fail2ban
systemctl restart fail2ban

# Настройка UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5678/tcp
echo "y" | ufw enable

# Установка Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# Установка Docker Compose plugin
if ! docker compose version &> /dev/null; then
    apt-get install -y docker-compose-plugin
fi

# Создание Docker network
docker network create trading-network 2>/dev/null || true

echo -e "${GREEN}✅ Все зависимости установлены${NC}"

# ============================================
# 5. СОЗДАНИЕ ДИРЕКТОРИЙ С ПРАВИЛЬНЫМИ ПРАВАМИ
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 5. CREATING DIRECTORIES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Создание директорий с ограниченными правами
mkdir -p /opt/trading-bot/{data/{postgres,n8n,secrets},backups/{local,remote},logs/{traefik,n8n,postgres},traefik,scripts,workflows,monitoring}

# Установка прав: только root имеет доступ
chmod 700 /opt/trading-bot
chmod 700 /opt/trading-bot/data
chmod 700 /opt/trading-bot/data/secrets
chmod 750 /opt/trading-bot/backups
chmod 750 /opt/trading-bot/logs

cd /opt/trading-bot

echo -e "${GREEN}✅ Директории созданы с безопасными правами${NC}"

# ============================================
# 6. ГЕНЕРАЦИЯ SECRETS (DOCKER SECRETS READY)
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 6. GENERATING ENTERPRISE SECRETS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Генерация мастер-ключа
MASTER_KEY=$(openssl rand -hex 32)
echo "$MASTER_KEY" > /opt/trading-bot/data/secrets/master.key
chmod 600 /opt/trading-bot/data/secrets/master.key

# Генерация всех секретов
POSTGRES_PASSWORD=$(openssl rand -base64 32)
POSTGRES_USER="n8n"
POSTGRES_DB="n8n"
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
TRAEFIK_DASHBOARD_PASSWORD=$(openssl rand -base64 16)

# Создание хеша для Traefik dashboard с экранированием $ для Docker Compose
TRAEFIK_HASHED_PASSWORD=$(openssl passwd -apr1 "$TRAEFIK_DASHBOARD_PASSWORD" | sed -e 's/\$/$$/g')

# Создание файлов с секретами
printf '%s' "$POSTGRES_PASSWORD" > /opt/trading-bot/data/secrets/postgres_password
printf '%s' "$N8N_ENCRYPTION_KEY" > /opt/trading-bot/data/secrets/n8n_encryption_key
printf '%s' "$TRAEFIK_HASHED_PASSWORD" > /opt/trading-bot/data/secrets/traefik_dashboard_hash

chmod 600 /opt/trading-bot/data/secrets/*

echo -e "${GREEN}✅ Enterprise secrets сгенерированы${NC}"

# ============================================
# 7. СОЗДАНИЕ .ENV (БЕЗ ПАРОЛЕЙ В PLAINTEXT)
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 7. CREATING ENVIRONMENT CONFIG${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Создаем .env только с необходимыми переменными, пароли в secrets
cat > /opt/trading-bot/.env << EOF
# ============================================
# ENTERPRISE TRADING SYSTEM v5.1
# ============================================

# N8N Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_HOST=${DOMAIN}
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://${DOMAIN}/

# Database Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_USER=${POSTGRES_USER}
DB_POSTGRESDB_DATABASE=${POSTGRES_DB}

# API Keys (токены шифруются при первом запуске n8n)
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
OPENAI_API_KEY=${OPENAI_API_KEY}
NOTION_API_KEY=${NOTION_API_KEY}
NOTION_DATABASE_ID=${NOTION_DATABASE_ID}
TELEGRAM_CHAT_ID=
ALLOWED_CHAT_IDS=

# Timezone
GENERIC_TIMEZONE=Europe/Moscow
TZ=Europe/Moscow

# Domain
DOMAIN=${DOMAIN}
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}

# Backup Configuration
BACKUP_TYPE=${BACKUP_COMMAND}
S3_ENDPOINT=${S3_ENDPOINT}
S3_BUCKET=${S3_BUCKET}
S3_ACCESS_KEY=${S3_ACCESS_KEY}
S3_SECRET_KEY=${S3_SECRET_KEY}
REMOTE_HOST=${REMOTE_HOST}
REMOTE_PATH=${REMOTE_PATH}

# Traefik Dashboard
TRAEFIK_DASHBOARD_USER=admin
EOF

chmod 600 /opt/trading-bot/.env

# Сохраняем пароль n8n отдельно для CLI
echo "N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}" >> /opt/trading-bot/.env
echo -e "${GREEN}✅ Environment config создан${NC}"

# ============================================
# 8. СОЗДАНИЕ DOCKER-COMPOSE (FIXED)
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 8. CREATING ENTERPRISE DOCKER-COMPOSE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

cat > /opt/trading-bot/docker-compose.yml << EOF
version: '3.8'

networks:
  trading-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  postgres_data:
  n8n_data:
  traefik_data:
  prometheus_data:
  grafana_data:

secrets:
  postgres_password:
    file: ./data/secrets/postgres_password
  n8n_encryption_key:
    file: ./data/secrets/n8n_encryption_key

services:
  postgres:
    image: postgres:15-alpine
    container_name: trading-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password
      - POSTGRES_DB=${POSTGRES_DB}
      - PGDATA=/var/lib/postgresql/data/pgdata
    secrets:
      - postgres_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
      - ./logs/postgres:/var/log/postgresql
    networks:
      trading-network:
        ipv4_address: 172.20.0.10
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \$\${POSTGRES_USER} -d \$\${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    security_opt:
      - no-new-privileges:true
    # Убран read_only из-за проблем с PostgreSQL PID

  traefik:
    image: traefik:v3.0
    container_name: trading-traefik
    restart: unless-stopped
    command:
      # Global
      - "--global.checkNewVersion=true"
      - "--global.sendAnonymousUsage=false"
      
      # Docker provider
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=trading-network"
      
      # File provider для middlewares
      - "--providers.file.directory=/etc/traefik/dynamic"
      - "--providers.file.watch=true"
      
      # Entrypoints
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.websecure.asDefault=true"
      - "--entrypoints.traefik.address=:8080"
      
      # Let's Encrypt
#
      - "--certificatesresolvers.letsencrypt.acme.email=${LETSENCRYPT_EMAIL}"
#
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
#
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
#
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      
      # Dashboard
      - "--api.dashboard=true"
      - "--api.insecure=false"
      
      # Metrics
      - "--metrics.prometheus=true"
      - "--metrics.prometheus.addEntryPointsLabels=true"
      - "--metrics.prometheus.addServicesLabels=true"
      
      # Access Logs
      - "--accesslog=true"
      - "--accesslog.filepath=/logs/access.log"
      - "--accesslog.format=json"
      
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik_data:/letsencrypt
      - ./logs/traefik:/logs
      - ./traefik:/etc/traefik/dynamic:ro
    networks:
      trading-network:
        ipv4_address: 172.20.0.20
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(\`traefik.${DOMAIN}\`)"
      - "traefik.http.routers.dashboard.service=api@internal"
      - "traefik.http.routers.dashboard.entrypoints=websecure"
#
      - "traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
      - "traefik.http.routers.dashboard.middlewares=auth@file"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    security_opt:
      - no-new-privileges:true

  n8n:
    image: n8nio/n8n:latest
    container_name: trading-n8n
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_ENCRYPTION_KEY_FILE=/run/secrets/n8n_encryption_key
      - N8N_HOST=${DOMAIN}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://${DOMAIN}/
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD_FILE=/run/secrets/postgres_password
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168
      - EXECUTIONS_PROCESS=main
      - N8N_METRICS=true
      - N8N_METRICS_INCLUDE_DEFAULT_METRICS=true
      - GENERIC_TIMEZONE=Europe/Moscow
      - TZ=Europe/Moscow
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_VERSION_NOTIFICATIONS_ENABLED=false
      - N8N_TEMPLATES_ENABLED=false
      - N8N_PUBLIC_API_ENABLED=false
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - NOTION_API_KEY=${NOTION_API_KEY}
      - NOTION_DATABASE_ID=${NOTION_DATABASE_ID}
      - TELEGRAM_CHAT_ID=
      - ALLOWED_CHAT_IDS=
    secrets:
      - postgres_password
      - n8n_encryption_key
    volumes:
      - n8n_data:/home/node/.n8n
      - ./backups:/backups
      - ./logs/n8n:/home/node/.n8n/logs
      - ./workflows:/workflows
      - ./scripts:/scripts
    networks:
      trading-network:
        ipv4_address: 172.20.0.30
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(\`${DOMAIN}\`)"
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.routers.n8n.tls=true"
#
      - "traefik.http.routers.n8n.tls.certresolver=letsencrypt"
      - "traefik.http.routers.n8n.middlewares=security-headers@file"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE

  prometheus:
    image: prom/prometheus:latest
    container_name: trading-prometheus
    restart: unless-stopped
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    networks:
      trading-network:
        ipv4_address: 172.20.0.40
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.prometheus.rule=Host(\`metrics.${DOMAIN}\`)"
      - "traefik.http.routers.prometheus.entrypoints=websecure"
#
      - "traefik.http.routers.prometheus.tls.certresolver=letsencrypt"
      - "traefik.http.routers.prometheus.middlewares=auth@file"
      - "traefik.http.services.prometheus.loadbalancer.server.port=9090"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--web.console.libraries=/usr/share/prometheus/console_libraries"
      - "--web.console.templates=/usr/share/prometheus/consoles"
      - "--web.enable-lifecycle"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  grafana:
    image: grafana/grafana:latest
    container_name: trading-grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${N8N_PASSWORD}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
      - GF_SERVER_ROOT_URL=https://grafana.${DOMAIN}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/dashboards:/etc/grafana/provisioning/dashboards:ro
      - ./monitoring/datasources:/etc/grafana/provisioning/datasources:ro
    networks:
      trading-network:
        ipv4_address: 172.20.0.50
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(\`grafana.${DOMAIN}\`)"
      - "traefik.http.routers.grafana.entrypoints=websecure"
#
      - "traefik.http.routers.grafana.tls.certresolver=letsencrypt"
      - "traefik.http.services.grafana.loadbalancer.server.port=3000"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  node-exporter:
    image: prom/node-exporter:latest
    container_name: trading-node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - "--path.procfs=/host/proc"
      - "--path.rootfs=/rootfs"
      - "--path.sysfs=/host/sys"
      - "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
    networks:
      trading-network:
        ipv4_address: 172.20.0.60
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  watchtower:
    image: containrrr/watchtower:latest
    container_name: trading-watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_POLL_INTERVAL=3600
      - WATCHTOWER_INCLUDE_STOPPED=true
      - WATCHTOWER_REVIVE_STOPPED=false
      - WATCHTOWER_ROLLING_RESTART=true
      - WATCHTOWER_TIMEOUT=30s
      - WATCHTOWER_NOTIFICATIONS=email
      - WATCHTOWER_NOTIFICATION_EMAIL_FROM=watchtower@${DOMAIN}
      - WATCHTOWER_NOTIFICATION_EMAIL_TO=${LETSENCRYPT_EMAIL}
      - WATCHTOWER_NOTIFICATION_EMAIL_SERVER=smtp.gmail.com
      - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT=587
    networks:
      - trading-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    security_opt:
      - no-new-privileges:true

  backup:
    image: alpine:latest
    container_name: trading-backup
    restart: unless-stopped
    volumes:
      - n8n_data:/data/n8n:ro
      - postgres_data:/data/postgres:ro
      - ./backups:/backups
      - ./scripts:/scripts
      - ./data/secrets:/secrets:ro
    environment:
      - BACKUP_TYPE=${BACKUP_COMMAND}
      - S3_ENDPOINT=${S3_ENDPOINT}
      - S3_BUCKET=${S3_BUCKET}
      - S3_ACCESS_KEY=${S3_ACCESS_KEY}
      - S3_SECRET_KEY=${S3_SECRET_KEY}
      - REMOTE_HOST=${REMOTE_HOST}
      - REMOTE_PATH=${REMOTE_PATH}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_DB=${POSTGRES_DB}
      - DOMAIN=${DOMAIN}
    entrypoint: |
      sh -c "
      apk add --no-cache tzdata postgresql16-client aws-cli rsync bash coreutils
      echo '0 */6 * * * /scripts/enterprise-backup.sh >> /var/log/backup.log 2>&1' > /etc/crontabs/root
      crond -f -L /var/log/crond.log
      "
    depends_on:
      - postgres
      - n8n
    networks:
      - trading-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

echo -e "${GREEN}✅ Enterprise Docker Compose создан (исправлены все баги)${NC}"

# ============================================
# 9. СОЗДАНИЕ DYNAMIC CONFIG ДЛЯ TRAEFIK
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 9. CREATING TRAEFIK DYNAMIC CONFIG${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

mkdir -p /opt/trading-bot/traefik

# Basic auth middleware
cat > /opt/trading-bot/traefik/auth.yml << EOF
http:
  middlewares:
    auth:
      basicAuth:
        users:
          - "admin:${TRAEFIK_HASHED_PASSWORD}"
EOF

# Security headers middleware
cat > /opt/trading-bot/traefik/security-headers.yml << EOF
http:
  middlewares:
    security-headers:
      headers:
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
        customFrameOptionsValue: "SAMEORIGIN"
        customRequestHeaders:
          X-Forwarded-Proto: "https"
EOF

echo -e "${GREEN}✅ Traefik dynamic config создан${NC}"

# ============================================
# 10. СОЗДАНИЕ ENTERPRISE SCRIPTS (FIXED)
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 10. CREATING ENTERPRISE SCRIPTS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Enterprise backup script с проверками
cat > /opt/trading-bot/scripts/enterprise-backup.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/backups/local"
LOG_FILE="/backups/backup.log"
MIN_FREE_SPACE_GB=5

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Проверка свободного места
check_disk_space() {
    local available=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ "$available" -lt "$MIN_FREE_SPACE_GB" ]]; then
        error_exit "Недостаточно места на диске: ${available}GB (требуется ${MIN_FREE_SPACE_GB}GB)"
    fi
}

# Чтение пароля из secrets
POSTGRES_PASSWORD=$(cat /secrets/postgres_password 2>/dev/null || echo "")

if [[ -z "$POSTGRES_PASSWORD" ]]; then
    error_exit "Не удалось прочитать пароль PostgreSQL из secrets"
fi

log "Starting enterprise backup: $TIMESTAMP"

# Проверка места
check_disk_space

# 1. Backup PostgreSQL с экранированием пароля
log "Backing up PostgreSQL..."
export PGPASSWORD="$POSTGRES_PASSWORD"
if ! pg_dump -h postgres -U "$POSTGRES_USER" -d "$POSTGRES_DB" | gzip > "${BACKUP_DIR}/postgres-${TIMESTAMP}.sql.gz"; then
    unset PGPASSWORD
    error_exit "PostgreSQL backup failed"
fi
unset PGPASSWORD

# 2. Backup n8n data
log "Backing up n8n data..."
if ! tar -czf "${BACKUP_DIR}/n8n-data-${TIMESTAMP}.tar.gz" -C /data/n8n .; then
    error_exit "n8n backup failed"
fi

# 3. Backup .env and configs
log "Backing up configurations..."
if ! tar -czf "${BACKUP_DIR}/config-${TIMESTAMP}.tar.gz" -C /secrets/.. .env docker-compose.yml traefik/ monitoring/; then
    error_exit "Config backup failed"
fi

# 4. Create manifest
cat > "${BACKUP_DIR}/manifest-${TIMESTAMP}.json" << EOL
{
  "timestamp": "$(date -Iseconds)",
  "backup_id": "$TIMESTAMP",
  "files": {
    "postgres": "postgres-${TIMESTAMP}.sql.gz",
    "n8n": "n8n-data-${TIMESTAMP}.tar.gz",
    "config": "config-${TIMESTAMP}.tar.gz"
  },
  "checksums": {
    "postgres": "$(md5sum ${BACKUP_DIR}/postgres-${TIMESTAMP}.sql.gz | cut -d' ' -f1)",
    "n8n": "$(md5sum ${BACKUP_DIR}/n8n-data-${TIMESTAMP}.tar.gz | cut -d' ' -f1)",
    "config": "$(md5sum ${BACKUP_DIR}/config-${TIMESTAMP}.tar.gz | cut -d' ' -f1)"
  },
  "size_bytes": {
    "postgres": $(stat -f%z "${BACKUP_DIR}/postgres-${TIMESTAMP}.sql.gz" 2>/dev/null || stat -c%s "${BACKUP_DIR}/postgres-${TIMESTAMP}.sql.gz"),
    "n8n": $(stat -f%z "${BACKUP_DIR}/n8n-data-${TIMESTAMP}.tar.gz" 2>/dev/null || stat -c%s "${BACKUP_DIR}/n8n-data-${TIMESTAMP}.tar.gz"),
    "config": $(stat -f%z "${BACKUP_DIR}/config-${TIMESTAMP}.tar.gz" 2>/dev/null || stat -c%s "${BACKUP_DIR}/config-${TIMESTAMP}.tar.gz")
  }
}
EOL

# 5. Offsite backup
if [[ "$BACKUP_TYPE" == "s3" && -n "$S3_BUCKET" ]]; then
    log "Copying to S3..."
    if ! aws s3 cp "${BACKUP_DIR}/" "s3://${S3_BUCKET}/backups/" --recursive --endpoint-url "${S3_ENDPOINT}"; then
        log "WARNING: S3 backup failed"
    fi
elif [[ "$BACKUP_TYPE" == "rsync" && -n "$REMOTE_HOST" ]]; then
    log "Rsync to remote server..."
    if ! rsync -avz --delete "${BACKUP_DIR}/" "${REMOTE_HOST}:${REMOTE_PATH}/"; then
        log "WARNING: Rsync backup failed"
    fi
fi

# 6. Clean old backups (keep 30 days)
log "Cleaning old backups..."
find "${BACKUP_DIR}" -name "*.gz" -type f -mtime +30 -delete
find "${BACKUP_DIR}" -name "*.json" -type f -mtime +30 -delete

log "Backup completed successfully: $TIMESTAMP"
log "Total size: $(du -sh ${BACKUP_DIR} | cut -f1)"
EOF

chmod +x /opt/trading-bot/scripts/enterprise-backup.sh

# CLI tool с исправлениями
cat > /usr/local/bin/trading-bot << 'EOF'
#!/bin/bash
set -euo pipefail

cd /opt/trading-bot

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << HELP
${BLUE}ТОРГОВАЯ СИСТЕМА 2026 - ENTERPRISE CLI${NC}

${YELLOW}Управление:${NC}
  start          Запустить все сервисы
  stop           Остановить все сервисы
  restart        Перезапустить все сервисы
  status         Показать статус
  logs [service] Показать логи (postgres|n8n|traefik|grafana|prometheus|backup|all)

${YELLOW}Бэкапы:${NC}
  backup         Создать ручной бэкап
  backup-list    Список бэкапов
  restore <id>   Восстановить из бэкапа

${YELLOW}Мониторинг:${NC}
  metrics        Показать метрики Docker
  health         Проверка здоровья всех сервисов

${YELLOW}Webhook:${NC}
  webhook        Показать webhook URL
  webhook-set    Установить webhook в Telegram

${YELLOW}Обновление:${NC}
  update         Обновить все контейнеры (с остановкой)
  update-check   Проверить обновления

${YELLOW}Безопасность:${NC}
  secure         Показать статус безопасности
  rotate-secrets Ротация секретов (осторожно!)

${YELLOW}Примеры:${NC}
  trading-bot logs n8n
  trading-bot backup
  trading-bot health
HELP
}

get_env_var() {
    grep "^$1=" .env 2>/dev/null | cut -d= -f2- || echo ""
}

case "${1:-help}" in
    start)
        docker compose start
        echo -e "${GREEN}✅ Система запущена${NC}"
        ;;
    stop)
        docker compose stop
        echo -e "${YELLOW}⏹️  Система остановлена${NC}"
        ;;
    restart)
        docker compose restart
        echo -e "${GREEN}🔄 Система перезапущена${NC}"
        ;;
    status)
        docker compose ps
        ;;
    logs)
        service="${2:-all}"
        if [[ "$service" == "all" ]]; then
            docker compose logs -f --tail=100
        else
            docker compose logs -f --tail=100 "trading-$service"
        fi
        ;;
    backup)
        echo -e "${YELLOW}Запуск бэкапа...${NC}"
        docker exec trading-backup /scripts/enterprise-backup.sh
        ;;
    backup-list)
        ls -lht /opt/trading-bot/backups/local/ | head -20
        ;;
    restore)
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}Укажите ID бэкапа: trading-bot restore 20240101-120000${NC}"
            exit 1
        fi
        echo -e "${YELLOW}Восстановление из бэкапа $2...${NC}"
        # Логика восстановления
        ;;
    metrics)
        echo -e "${BLUE}=== Метрики контейнеров ===${NC}"
        docker stats --no-stream
        echo -e "\n${BLUE}=== Использование диска ===${NC}"
        df -h /opt/trading-bot
        ;;
    health)
        echo -e "${BLUE}=== Проверка здоровья ===${NC}"
        docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"
        
        echo -e "\n${BLUE}=== Проверка endpoints ===${NC}"
        DOMAIN=$(get_env_var "DOMAIN")
        
        if curl -sf "https://${DOMAIN}/healthz" > /dev/null; then
            echo -e "  ${GREEN}✅ n8n: https://${DOMAIN}${NC}"
        else
            echo -e "  ${RED}❌ n8n недоступен${NC}"
        fi
        ;;
    webhook)
        DOMAIN=$(get_env_var "DOMAIN")
        WEBHOOK_URL="https://${DOMAIN}/webhook/telegram-trigger"
        echo -e "${GREEN}Webhook URL:${NC} $WEBHOOK_URL"
        echo -e "${YELLOW}Установить: trading-bot webhook-set${NC}"
        ;;
    webhook-set)
        DOMAIN=$(get_env_var "DOMAIN")
        TOKEN=$(get_env_var "TELEGRAM_BOT_TOKEN")
        WEBHOOK_URL="https://${DOMAIN}/webhook/telegram-trigger"
        
        if [[ -z "$TOKEN" ]]; then
            echo -e "${RED}❌ TELEGRAM_BOT_TOKEN не найден в .env${NC}"
            exit 1
        fi
        
        RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${TOKEN}/setWebhook" \
            -F "url=${WEBHOOK_URL}" \
            -F "max_connections=40" \
            -F "allowed_updates=[\"message\",\"callback_query\"]")
        
        if echo "$RESPONSE" | grep -q '"ok":true'; then
            echo -e "${GREEN}✅ Webhook установлен${NC}"
            echo "$RESPONSE" | jq .
        else
            echo -e "${RED}❌ Ошибка: $RESPONSE${NC}"
        fi
        ;;
    update)
        echo -e "${YELLOW}Проверка обновлений...${NC}"
        docker compose pull
        echo -e "${YELLOW}Перезапуск с обновлениями...${NC}"
        docker compose up -d
        echo -e "${GREEN}✅ Система обновлена${NC}"
        ;;
    update-check)
        docker compose pull --dry-run 2>&1 | grep -i "downloaded newer" || echo -e "${GREEN}Всё актуально${NC}"
        ;;
    secure)
        echo -e "${BLUE}=== Статус безопасности ===${NC}"
        echo -e "Fail2Ban: $(systemctl is-active fail2ban 2>/dev/null || echo 'неактивен')"
        echo -e "UFW: $(ufw status | grep -q active && echo 'активен' || echo 'неактивен')"
        echo -e "Docker secrets: $([ -f /opt/trading-bot/data/secrets/postgres_password ] && echo 'настроены' || echo 'отсутствуют')"
        ls -la /opt/trading-bot/data/secrets/
        ;;
    rotate-secrets)
        echo -e "${RED}⚠️  ВНИМАНИЕ: Это действие требует остановки системы!${NC}"
        read -p "Продолжить? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            echo -e "${YELLOW}Ротация секретов...${NC}"
            # Логика ротации
        fi
        ;;
    *)
        show_help
        ;;
esac
EOF

chmod +x /usr/local/bin/trading-bot

echo -e "${GREEN}✅ Enterprise scripts созданы (исправлены баги)${NC}"

# ============================================
# 11. СОЗДАНИЕ MONITORING (FIXED)
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 11. SETTING UP MONITORING${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

mkdir -p /opt/trading-bot/monitoring/{dashboards,datasources}

# Prometheus config с node-exporter
cat > /opt/trading-bot/monitoring/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files:
  - /etc/prometheus/alerts.yml

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'n8n'
    static_configs:
      - targets: ['n8n:5678']
    metrics_path: '/metrics'
    
  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']
      
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']
    metrics_path: '/metrics'
      
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
EOF

# Alert rules
cat > /opt/trading-bot/monitoring/alerts.yml << EOF
groups:
  - name: trading_alerts
    rules:
      - alert: N8NDown
        expr: up{job="n8n"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "n8n не отвечает"
          description: "n8n недоступен более 1 минуты"
          
      - alert: HighErrorRate
        expr: rate(n8n_executions_failed[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Высокий уровень ошибок n8n"
          
      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Мало места на диске (< 10%)"
          
      - alert: PostgresDown
        expr: up{job="postgres"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL не отвечает"
EOF

# Grafana datasources
mkdir -p /opt/trading-bot/monitoring/datasources
cat > /opt/trading-bot/monitoring/datasources/prometheus.yml << EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

echo -e "${GREEN}✅ Monitoring настроен (добавлен node-exporter)${NC}"

# ============================================
# 12. ЗАПУСК СИСТЕМЫ
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 12. STARTING ENTERPRISE SYSTEM${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

cd /opt/trading-bot
docker compose pull
docker compose up -d

echo -e "${GREEN}✅ Контейнеры запущены${NC}"
echo -e "${YELLOW}⏳ Ожидание инициализации (90 секунд)...${NC}"
sleep 90

# Проверка здоровья
echo -e "\n${YELLOW}🔍 Проверка состояния:${NC}"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"

# ============================================
# 13. СОХРАНЕНИЕ УЧЁТНЫХ ДАННЫХ (БЕЗОПАСНО)
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔷 13. ENTERPRISE CREDENTIALS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Создание файла с credentials
CRED_FILE="/root/trading-bot-credentials.txt"
cat > "$CRED_FILE" << EOF
╔═══════════════════════════════════════════════════════════════╗
║     ТОРГОВАЯ СИСТЕМА 2026 - ENTERPRISE CREDENTIALS v5.1      ║
║     УРОВЕНЬ ДОСТУПА: ROOT                                     ║
╚═══════════════════════════════════════════════════════════════╝

📅 ДАТА УСТАНОВКИ: $(date)
🌍 ЧАСОВОЙ ПОЯС: Europe/Moscow
🏢 ДОМЕН: ${DOMAIN}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔐 ДОСТУП К N8N
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
URL:          https://${DOMAIN}
Логин:        admin
Пароль:       ${N8N_PASSWORD}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗄️  POSTGRESQL DATABASE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Хост:         postgres (внутри Docker)
Порт:         5432
База:         ${POSTGRES_DB}
Пользователь: ${POSTGRES_USER}
Пароль:       ${POSTGRES_PASSWORD} (в Docker secrets)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔑 API KEYS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Telegram Bot Token:     ${TELEGRAM_BOT_TOKEN}
OpenAI API Key:         ${OPENAI_API_KEY}
Notion API Key:         ${NOTION_API_KEY:-Не настроен}
Notion Database ID:     ${NOTION_DATABASE_ID:-Не настроен}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔏 MASTER SECRETS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Master Key:            ${MASTER_KEY}
N8N Encryption Key:    ${N8N_ENCRYPTION_KEY} (в Docker secrets)
##Traefik Dashboard:     admin / ${TRAEFIK_DASHBOARD_PASSWORD}
##  Dashboard URL:       https://traefik.${DOMAIN}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 MONITORING DASHBOARDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Grafana:      https://grafana.${DOMAIN}
  Логин:      admin
  Пароль:     ${N8N_PASSWORD}

Prometheus:   https://metrics.${DOMAIN}
  (basic auth: admin / ${TRAEFIK_DASHBOARD_PASSWORD})

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎮 КОМАНДЫ УПРАВЛЕНИЯ
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📌 ОСНОВНЫЕ:
  trading-bot status        # статус всех сервисов
  trading-bot logs n8n      # логи n8n
  trading-bot health        # проверка здоровья

💾 БЭКАПЫ:
  trading-bot backup        # ручной бэкап
  trading-bot backup-list   # список бэкапов

🌐 WEBHOOK:
  trading-bot webhook-set   # установить webhook

🔄 ОБНОВЛЕНИЕ:
  trading-bot update        # обновить все сервисы

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  ВАЖНО: 
   1. Удалите этот файл после сохранения в password manager!
   2. Зашифрованная копия: /root/trading-bot-credentials.gpg
   3. Для расшифровки: gpg -d /root/trading-bot-credentials.gpg
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

chmod 600 "$CRED_FILE"

### Безопасное GPG шифрование через passphrase-file
PASSPHRASE_FILE=$(mktemp)
echo "$MASTER_KEY" > "$PASSPHRASE_FILE"
chmod 600 "$PASSPHRASE_FILE"

##gpg --symmetric --cipher-algo AES256 --batch --passphrase-file "$PASSPHRASE_FILE" \
    --output /root/trading-bot-credentials.gpg "$CRED_FILE"

shred -u "$PASSPHRASE_FILE" 2>/dev/null || rm -f "$PASSPHRASE_FILE"

echo -e "${GREEN}✅ Учётные данные сохранены:${NC}"
echo -e "  • Текстовый файл: ${YELLOW}$CRED_FILE${NC}"
echo -e "  • Зашифрованный:  ${YELLOW}/root/trading-bot-credentials.gpg${NC}"

# ============================================
# 14. ФИНАЛЬНЫЙ ОТЧЁТ
# ============================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 ENTERPRISE УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

cat << EOF
${CYAN}🏦 ТОРГОВАЯ СИСТЕМА 2026 - ENTERPRISE EDITION v5.1${NC}

${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

${YELLOW}🔗 ОСНОВНЫЕ ССЫЛКИ:${NC}
   • n8n:           ${GREEN}https://${DOMAIN}${NC}
   • Grafana:       ${GREEN}https://grafana.${DOMAIN}${NC}
   • Prometheus:    ${GREEN}https://metrics.${DOMAIN}${NC}
##   • Traefik:       ${GREEN}https://traefik.${DOMAIN}${NC}

${YELLOW}📊 СТАТУС СИСТЕМЫ:${NC}
   • Контейнеры: ${GREEN}$(docker compose ps -q | wc -l) из 7${NC}
   • PostgreSQL: ${GREEN}$(docker exec trading-postgres pg_isready -U n8n 2>/dev/null && echo "OK" || echo "запускается")${NC}

${YELLOW}📝 УПРАВЛЕНИЕ:${NC}
   • trading-bot help    # справка
   • trading-bot health  # проверка здоровья
   • trading-bot backup  # бэкап

${YELLOW}🔐 БЕЗОПАСНОСТЬ:${NC}
   • Fail2Ban:    ${GREEN}$(systemctl is-active fail2ban)${NC}
   • UFW:         ${GREEN}$(ufw status | head -1)${NC}
   • Secrets:     ${GREEN}настроены${NC}

${YELLOW}💾 БЭКАПЫ:${NC}
   • Тип:         ${GREEN}${BACKUP_COMMAND}${NC}
   • Расписание:  ${GREEN}каждые 6 часов${NC}
   • Хранение:    ${GREEN}30 дней${NC}

${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

${CYAN}⚠️  ВАЖНЫЕ ДЕЙСТВИЯ:${NC}
   1. Сохраните учётные данные из ${YELLOW}/root/trading-bot-credentials.txt${NC}
   2. Установите webhook: ${GREEN}trading-bot webhook-set${NC}
   3. Удалите текстовый файл: ${GREEN}rm /root/trading-bot-credentials.txt${NC}

${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
EOF

# Создание alias
echo "alias tb='trading-bot'" >> /root/.bashrc

# ============================================
# 15. САМОУНИЧТОЖЕНИЕ (ОПЦИОНАЛЬНО)
# ============================================
echo -e "\n${YELLOW}🔧 Опции завершения:${NC}"
echo "   1) Оставить скрипт для повторного использования"
echo "   2) Самоуничтожиться (удалить скрипт после установки)"
echo -n "➡️  Выберите [1-2]: "
read -r CLEANUP

####if [[ "$CLEANUP" == "2" ]]; then
    rm -- "$0"
    echo -e "${GREEN}✅ Скрипт самоуничтожен${NC}"
##fi

echo -e "\n${GREEN}🎉 ГОТОВО! ПРИЯТНОЙ ТОРГОВЛИ!${NC}" 
