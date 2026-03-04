# ⚡ Quickstart — Запуск за 5 минут

> **Для кого:** Новички, которые хотят быстро запустить бота  
> **Время:** 5-10 минут  
> **Требования:** Ubuntu 22.04/24.04, 2GB+ RAM, домен

---

## 📋 Шаг 0: Подготовка

### Что нужно заранее

| Ресурс | Где получить | Время |
|--------|--------------|-------|
| **Сервер (VPS)** | Hetzner, DigitalOcean, Vultr | 5 мин |
| **Домен** | Namecheap, Cloudflare | 5 мин |
| **Telegram Bot** | [@BotFather](https://t.me/BotFather) | 2 мин |

### Минимальные требования

```
CPU: 2 ядра
RAM: 4 GB (минимум 2 GB)
Disk: 20 GB SSD
OS: Ubuntu 22.04 или 24.04 LTS
```

---

## 🚀 Шаг 1: Установка (3 команды)

```bash
# 1. Клонирование
git clone https://github.com/akoffice933-maker/trading-bot-project.git
cd trading-bot-project

# 2. Запуск установки
sudo ./install-trading-bot-v5.1.sh
```

**Что спросит скрипт:**
```
📧 Email: your@email.com          ← для SSL сертификата
🔐 Пароль n8n: YourStrongPass123! ← мин. 12 символов
🤖 Telegram Bot Token: 123456:ABC... ← от @BotFather
🌐 Домен: trading.yourcompany.com ← A-запись на IP сервера
```

---

## ⏳ Шаг 2: Ожидание (2-3 минуты)

Скрипт автоматически:
- ✅ Установит Docker и Docker Compose
- ✅ Настроит UFW firewall
- ✅ Установит Fail2Ban
- ✅ Получит SSL сертификат (Let's Encrypt)
- ✅ Запустит контейнеры (n8n, PostgreSQL, Traefik, Prometheus, Grafana)

**Индикатор готовности:**
```
✅ Installation complete!
✅ All services are running
✅ n8n available at https://trading.yourcompany.com
```

---

## 🔐 Шаг 3: Первый вход

### n8n (основной интерфейс)

```
URL: https://trading.yourcompany.com
Login: admin
Password: [ваш пароль из установки]
```

### Grafana (мониторинг)

```
URL: https://grafana.trading.yourcompany.com
Login: admin
Password: [ваш пароль из установки]
```

### Prometheus (метрики)

```
URL: https://metrics.trading.yourcompany.com
Login: admin
Password: [ваш пароль из установки]
```

---

## 📥 Шаг 4: Импорт workflow

### Вариант A: Multi-Pair Trading (рекомендуется)

1. В n8n: **Workflows** → **Import** → **Upload JSON**
2. Выберите файл: `workflows/trading-bot-main.v5.1-multi-pair.json`
3. Нажмите **Activate** (переключатель вверху)

### Вариант B: AI Sentiment Analysis

1. В n8n: **Workflows** → **Import** → **Upload JSON**
2. Выберите файл: `workflows/ai-sentiment-analysis.json`
3. Настройте credentials (OpenRouter API key)
4. Нажмите **Activate**

### Вариант C: Multi-Model Consensus (макс. точность)

1. В n8n: **Workflows** → **Import** → **Upload JSON**
2. Выберите файл: `workflows/multi-model-consensus.json`
3. Настройте credentials (OpenRouter + DeepInfra)
4. Нажмите **Activate**

---

## ✅ Шаг 5: Проверка работы

### Команды для проверки

```bash
# Статус всех сервисов
docker compose ps

# Логи n8n
docker compose logs -f n8n

# Проверка здоровья
curl https://trading.yourcompany.com/healthz
```

### Ожидаемый результат

```
NAME                    STATUS
trading-n8n             running
trading-postgres        running
trading-traefik         running
trading-prometheus      running
trading-grafana         running
```

---

## 🎯 Что дальше?

### Для тестирования

1. **Включите Testnet режим** (Bybit Testnet)
2. **Запустите на 1 паре** (BTCUSDT)
3. **Наблюдайте 24-48 часов** через Grafana

### Для production

1. **Протестируйте 7+ дней** на testnet
2. **Настройте бэкапы** (`./trading-bot backup local`)
3. **Добавьте мониторинг** в Telegram
4. **Постепенно увеличивайте** количество пар

---

## 📚 Полезные ссылки

| Документ | Описание |
|----------|----------|
| [README.md](README.md) | Полная документация |
| [AI_AGGREGATORS.md](docs/AI_AGGREGATORS.md) | Настройка AI (OpenRouter/DeepInfra) |
| [MULTI_PAIR_CONFIG.md](docs/MULTI_PAIR_CONFIG.md) | Multi-pair торговля |
| [MULTI_MODEL_CONSENSUS.md](docs/MULTI_MODEL_CONSENSUS.md) | AI голосование |
| [TESTING.md](docs/TESTING.md) | Результаты тестов |

---

## 🆘 Если что-то пошло не так

### Контейнер не запускается

```bash
# Проверьте логи
docker compose logs n8n

# Перезапустите
docker compose restart n8n
```

### SSL сертификат не получен

```bash
# Проверьте DNS
dig trading.yourcompany.com

# Должен возвращать IP вашего сервера
```

### Доступ запрещён (401/403)

```bash
# Проверьте пароль
docker compose exec n8n cat /run/secrets/n8n_password

# Сбросьте пароль
docker compose exec n8n n8n user:password --email=admin@local --password=NewPass123!
```

### Автоматическое исправление

```bash
# Запустите скрипт исправления
bash fix-trading-bot.sh
```

---

## 📞 Поддержка

- **GitHub Issues:** https://github.com/akoffice933-maker/trading-bot-project/issues
- **Discussions:** https://github.com/akoffice933-maker/trading-bot-project/discussions
- **Telegram:** @akoffice933maker

---

<div align="center">

**⚡ Quickstart завершён!**

[⬆️ Вернуться к README](README.md)

</div>
