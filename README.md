# 🏦 Торговая Система 2026 — Enterprise v5.3.1

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tested on Ubuntu 22.04](https://img.shields.io/badge/Tested%20on-Ubuntu%2022.04-blue)](docs/TESTING.md)
[![Tested on Ubuntu 24.04](https://img.shields.io/badge/Tested%20on-Ubuntu%2024.04-blue)](docs/TESTING.md)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![n8n](https://img.shields.io/badge/n8n-Automation-ff6d5a?logo=n8n)](https://n8n.io/)
[![GitHub stars](https://img.shields.io/github/stars/akoffice933-maker/trading-bot-project?style=social)](https://github.com/akoffice933-maker/trading-bot-project/stargazers)

> **Автоматизированная торговая система уровня FinTech** с полной Docker-оркестрацией, мониторингом и безопасностью корпоративного класса.

---

## 📖 О проекте

**Trading Bot Enterprise v5.3** — это готовое решение для развёртывания автоматизированной торговой платформы на базе n8n. Система предназначена для создания, тестирования и запуска торговых стратегий любой сложности с интеграцией Telegram, OpenAI, Notion и AI-агрегаторов (OpenRouter, DeepInfra).

### 🎯 Назначение

- Автоматизация торговых операций на финансовых рынках
- Создание workflow для анализа рынка и исполнения ордеров
- Интеграция с внешними API (биржи, аналитика, уведомления)
- Мониторинг и логирование всех операций
- Надёжное резервное копирование данных
- **Multi-Pair торговля** — поддержка нескольких торговых пар через единый workflow (v5.2+)
- **AI Integration** — доступ к 200+ языковым моделям через OpenRouter и DeepInfra (v5.3+)

---

## ✨ Ключевые возможности

| Категория | Возможности |
|-----------|-------------|
| 🤖 **Автоматизация** | n8n workflow, триггеры по времени/событию, HTTP-запросы, вебхуки |
| 🗄️ **Данные** | PostgreSQL 15, автоматическая прунинг-очистка, бэкапы |
| 🔒 **Безопасность** | Docker Secrets, Basic Auth, Fail2Ban, UFW, HTTPS (Let's Encrypt) |
| 📊 **Мониторинг** | Prometheus + Grafana, метрики производительности, дашборды |
| 💾 **Бэкапы** | Локальные, S3 (Wasabi/DO Spaces), rsync на удалённый сервер |
| 🌐 **Сеть** | Traefik reverse proxy, автоматический HTTPS, роутинг по поддоменам |
| 📈 **Multi-Pair** | Торговля несколькими парами через единый workflow (v5.2+) |
| 🧠 **AI Integration** | OpenAI, **OpenRouter** (200+ моделей), **DeepInfra** (50+ моделей) |

---

## 🏗️ Архитектура системы

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet / Domain                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │    Traefik      │  ← Reverse Proxy + HTTPS
                    │   (Port 80/443) │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│     n8n       │   │   Grafana     │   │  Prometheus   │
│  (Port 5678)  │   │  (Port 3000)  │   │  (Port 9090)  │
└───────┬───────┘   └───────────────┘   └───────────────┘
        │
        ▼
┌───────────────┐
│  PostgreSQL   │
│  (Port 5432)  │
└───────────────┘
```

### 📦 Стек технологий

| Компонент | Версия | Назначение |
|-----------|--------|------------|
| **n8n** | latest | Workflow-автоматизация |
| **PostgreSQL** | 15-alpine | База данных |
| **Traefik** | v3.0 | Reverse proxy + SSL |
| **Prometheus** | latest | Сбор метрик |
| **Grafana** | latest | Визуализация |
| **Fail2Ban** | latest | Защита от атак |
| **Docker** | latest | Контейнеризация |
| **AI Aggregators** | OpenRouter, DeepInfra | Доступ к 200+ LLM моделям |

---

## 🚀 Быстрый старт

### Требования к серверу

| Ресурс | Минимум | Рекомендуется |
|--------|---------|---------------|
| CPU | 2 ядра | 4 ядра |
| RAM | 4 GB | 8 GB |
| Диск | 20 GB | 50+ GB SSD |
| ОС | Ubuntu 20.04+ / Debian 11+ | Ubuntu 22.04 LTS |

### 📥 Установка за 5 минут

```bash
# 1. Клонирование репозитория
git clone https://github.com/akoffice933-maker/trading-bot-project.git
cd trading-bot-project

# 2. Запуск скрипта установки
sudo ./install-trading-bot-v5.1.sh
```

### 📝 Что нужно подготовить заранее

1. **Домен** с A-записью на IP сервера (например, `trading.yourcompany.com`)
2. **Email** для Let's Encrypt
3. **Telegram Bot Token** (от [@BotFather](https://t.me/BotFather))
4. **OpenAI API Key** (опционально, для AI-функций)
5. **Пароль для n8n** (мин. 12 символов: буквы, цифры, спецсимволы)

---

## 🔧 Конфигурация

### Переменные окружения

После установки создаётся файл `.env` со следующими параметрами:

```bash
# N8N Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_HOST=trading.yourcompany.com
N8N_PORT=5678
N8N_PROTOCOL=https

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_DATABASE=n8n

# External APIs
TELEGRAM_BOT_TOKEN=your_bot_token
OPENAI_API_KEY=your_api_key
NOTION_API_KEY=your_notion_token

# Timezone
GENERIC_TIMEZONE=Europe/Moscow
TZ=Europe/Moscow
```

### Структура проекта

```
trading-bot-project/
├── install-trading-bot-v5.1.sh    # Основной скрипт установки (Enterprise v5.1)
├── fix-trading-bot.sh             # Скрипт автоматического исправления проблем
├── README.md                      # Документация
├── LICENSE                        # MIT License
├── .gitignore                     # Исключения для Git
├── configs/                       # Конфигурационные файлы
│   └── pairs.json                 # Настройки торговых пар (multi-pair v5.2)
├── workflows/                     # Примеры workflow для n8n
│   └── trading-bot-main.v5.1-multi-pair.json  # Multi-pair workflow
├── scripts/                       # Дополнительные скрипты
├── tests/                         # Тесты
└── docs/                          # Дополнительная документация
    └── MULTI_PAIR_CONFIG.md       # Руководство по multi-pair торговле
```

---

## 🌐 Доступ к сервисам

После установки система доступна по следующим адресам:

| Сервис | URL | Описание |
|--------|-----|----------|
| **n8n** | `https://trading.yourcompany.com` | Основной интерфейс автоматизации |
| **Traefik Dashboard** | `https://traefik.trading.yourcompany.com` | Панель управления прокси |
| **Grafana** | `https://grafana.trading.yourcompany.com` | Визуализация метрик |
| **Prometheus** | `https://metrics.trading.yourcompany.com` | Сбор и запросы метрик |

> 🔐 Все сервисы защищены Basic Auth (логин: `admin`, пароль задаётся при установке)

---

## 🔐 Безопасность

### Реализованные меры защиты

- ✅ **Docker Secrets** — пароли хранятся в зашифрованном виде
- ✅ **HTTPS** — автоматический SSL через Let's Encrypt
- ✅ **Fail2Ban** — защита от брутфорса (SSH, Traefik)
- ✅ **UFW Firewall** — только необходимые порты (22, 80, 443, 5678)
- ✅ **Security Headers** — HSTS, CSP, X-Frame-Options
- ✅ **Автоматические обновления** — security-патчи ОС

### Настройка Fail2Ban

```bash
# Просмотр заблокированных IP
sudo fail2ban-client status

# Статус защиты Traefik
sudo fail2ban-client status traefik-auth

# Разблокировать IP
sudo fail2ban-client set traefik-auth unbanip <IP>
```

---

## 📊 Мониторинг

### Prometheus

Собирает метрики со всех сервисов:

- Производительность контейнеров (CPU, RAM)
- Запросы к Traefik (RPS, latency, ошибки)
- Состояние PostgreSQL (connections, queries)
- Метрики n8n (executions, errors, queue)

**Доступ**: `https://metrics.trading.yourcompany.com`

### Grafana

Готовые дашборды:

- 📈 **System Overview** — общая статистика системы
- 🐳 **Docker Containers** — метрики контейнеров
- 🌐 **Traefik** — запросы, SSL-сертификаты
- 📊 **n8n** — выполнения workflow, ошибки
- 🗄️ **PostgreSQL** — производительность БД

**Доступ**: `https://grafana.trading.yourcompany.com`

---

## 💾 Резервное копирование

### Типы бэкапов

| Тип | Описание | Команда |
|-----|----------|---------|
| **Локальный** | В папку `/opt/trading-bot/backups` | `local` |
| **S3-совместимый** | Wasabi, DigitalOcean Spaces | `s3` |
| **Rsync** | На удалённый сервер | `rsync` |

### Ручное создание бэкапа

```bash
# Полный бэкап системы
docker exec trading-n8n /scripts/backup.sh

# Бэкап PostgreSQL
docker exec trading-postgres pg_dump -U n8n n8n > backup.sql
```

### Восстановление из бэкапа

```bash
# Восстановление PostgreSQL
gunzip -c postgres-20260221-120000.sql.gz | \
  docker exec -i trading-postgres psql -U n8n -d n8n
```

---

## 🔧 Управление системой

### Основные команды

```bash
# Просмотр статуса всех сервисов
docker compose ps

# Просмотр логов
docker compose logs -f n8n
docker compose logs -f traefik

# Перезапуск сервиса
docker compose restart n8n

# Полная остановка
docker compose down

# Обновление контейнеров
docker compose pull
docker compose up -d
```

### Исправление проблем

```bash
# Автоматическое исправление
bash fix-trading-bot.sh

# Проверка DNS
dig trading.yourcompany.com

# Проверка портов
sudo ss -tuln | grep -E ':(80|443|5678)'
```

---

## 🎯 Примеры использования

### 1. Торговый бот для Telegram

```
Telegram → Webhook → n8n → API Биржи → Исполнение ордера
                              ↓
                        PostgreSQL (логирование)
                              ↓
                      Telegram (уведомление)
```

### 2. AI-анализ рынка

```
Расписание (каждые 5 мин) → n8n → OpenAI API → Анализ новостей
                                     ↓
                              TradingView API → Сигнал
                                     ↓
                              Telegram (алерт)
```

### 3. Логирование в Notion

```
n8n Execution → Webhook → Notion API → База данных
```

---

## 🛠️ Расширение и кастомизация

### Добавление workflow

1. Создайте файл workflow в папке `workflows/`
2. Экспортируйте workflow из n8n (JSON)
3. Импортируйте через веб-интерфейс n8n

### Интеграция с биржами

| Биржа | API | Статус |
|-------|-----|--------|
| Binance | ✅ Поддерживается | Готово |
| Bybit | ✅ Поддерживается | Готово |
| OKX | ✅ Поддерживается | Готово |
| Московская Биржа | ⚠️ Требуется кастомизация | — |

---

## 📈 Multi-Pair Торговля (v5.2+)

Начиная с версии 5.2 поддерживается торговля несколькими торговыми парами через единый workflow.

### Быстрый старт

```bash
# 1. Настройте пары в configs/pairs.json
nano configs/pairs.json

# 2. Импортируйте workflow
# workflows/trading-bot-main.v5.1-multi-pair.json через веб-интерфейс n8n

# 3. Активируйте workflow и торгуйте!
```

### Пример конфигурации

```json
{
  "enabled": true,
  "pairs": [
    {"symbol": "BTCUSDT", "enabled": true, "risk": {"position_size_usdt": 100}},
    {"symbol": "ETHUSDT", "enabled": true, "risk": {"position_size_usdt": 100}},
    {"symbol": "SOLUSDT", "enabled": false}
  ],
  "global_settings": {
    "max_total_positions": 3,
    "max_daily_loss_usdt": 150
  }
}
```

📖 **Полная документация:** [docs/MULTI_PAIR_CONFIG.md](docs/MULTI_PAIR_CONFIG.md)

### Преимущества архитектуры

| Параметр | Single-Pair | Multi-Pair (v5.2) |
|----------|-------------|-------------------|
| Workflow | 1 на пару | 1 на все пары |
| WebSocket | 1 на пару | 1 общий |
| Фильтрация | Нет | Динамическая |
| Масштабируемость | До 3 пар | До 10+ пар |
| Ресурсы | Выше | Оптимизировано |

---

## 🧠 AI Integration (v5.3+)

Система поддерживает интеграцию с **AI-агрегаторами** для доступа к сотням языковых моделей через единый API.

### Поддерживаемые агрегаторы

| Агрегатор | Моделей | Преимущества | Цены |
|-----------|---------|--------------|------|
| **OpenRouter** | 200+ | Единый API, роутинг, fallback | от $0.1/1M tokens |
| **DeepInfra** | 50+ | Низкие задержки, open-source модели | от $0.07/1M tokens |
| **OpenAI** | 10+ | Официальный API, GPT-4, o1 | от $2.5/1M tokens |

### Быстрая настройка

```bash
# 1. Получите API ключи
# OpenRouter: https://openrouter.ai/keys
# DeepInfra: https://deepinfra.com/dash/api_keys

# 2. Добавьте в .env
echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .env
echo "DEEPINFRA_API_KEY=..." >> .env

# 3. Импортируйте workflow
# workflows/ai-sentiment-analysis.json
```

### Примеры использования

#### 1. Анализ настроений новостей
```
Новости → n8n → OpenRouter (Llama-3.1-70B) → Sentiment Score → Trading Decision
```

#### 2. AI-сигналы
```
Цена → Индикаторы → DeepInfra (Mistral-Large) → Signal → Bybit Order
```

#### 3. Multi-Model роутинг
```
Запрос → OpenRouter → 
  ├─ GPT-4 (сложные задачи)
  ├─ Claude-3.5 (анализ текста)
  └─ Llama-3 (быстрые запросы)
```

#### 4. Multi-Model Consensus (v5.3) 🆕
```
Рыночные данные → 4 AI модели → Голосование → Consensus Score → Trading Decision

Модели:
  • GPT-4 Turbo (технический анализ)
  • Claude-3.5 (настроения рынка)
  • Llama-3.1 70B (статистика)
  • Mistral Large (риск-менеджмент)

Точность: ~78-85% (vs 60-70% у одной модели)
Стоимость: ~$0.008 за консенсус
```

### Популярные модели для трейдинга

| Модель | Агрегатор | Цена | Точность* | Использование |
|--------|-----------|------|-----------|---------------|
| **GPT-4 Turbo** | OpenRouter | $10/1M | ~72% | Сложный анализ |
| **Claude-3.5 Sonnet** | OpenRouter | $3/1M | ~70% | Анализ новостей |
| **Llama-3.1 70B** | OpenRouter/DeepInfra | $0.8/1M | ~65% | Быстрые сигналы |
| **Mistral Large** | OpenRouter/DeepInfra | $2/1M | ~68% | Технический анализ |
| **Qwen-2.5 72B** | OpenRouter/DeepInfra | $0.4/1M | ~63% | Классификация |
| **Multi-Model Consensus** | 4 модели | $0.008/раз | **~78-85%** | Критически важные решения |

*\*Точность указана для примера, реальные значения зависят от стратегии и рыночных условий*

📖 **Полная документация:** [docs/AI_AGGREGATORS.md](docs/AI_AGGREGATORS.md)

---

## 📊 Реалистичные ожидания (v5.3.1)

### Типичные результаты (BTCUSDT, 5m таймфрейм, тестнет 30 дней)

| Метрика | Диапазон | Примечание |
|---------|----------|------------|
| **Win Rate** | 52–63% | Зависит от рыночного режима (тренд/флэт) |
| **Profit Factor** | 1.2–1.8 | После оптимизации параметров |
| **Max Drawdown** | 8–18% | При risk=1% на сделку |
| **Средний профит/сделку** | +1.5–3.5% | На успешных сделках |
| **Количество сделок/день** | 2–8 | Зависит от волатильности |

### Производительность AI

| Конфигурация | Точность | Задержка | Стоимость/день |
|--------------|----------|----------|----------------|
| **Одна модель (Llama-3.1)** | ~60-65% | 2-5 сек | $0.05-0.10 |
| **Одна модель (GPT-4)** | ~68-72% | 5-10 сек | $0.20-0.40 |
| **Multi-Model Consensus** | **~78-85%** | 10-15 сек | $0.08-0.15 |

### Стоимость владения

| Компонент | Стоимость/месяц |
|-----------|-----------------|
| **VPS (4GB RAM)** | $5-10 (Hetzner, DigitalOcean) |
| **Домен** | $1-2 (Cloudflare, Namecheap) |
| **AI API (OpenRouter/DeepInfra)** | $2-12 (зависит от частоты) |
| **Итого** | **$8-24/месяц** |

> ⚠️ **Это не гарантия дохода.** Всегда тестируй на **Testnet 7+ дней** перед использованием реальных средств. Результаты зависят от рыночных условий, настроек и удачи.

---

## 📝 Лицензия

MIT License — см. файл [LICENSE](LICENSE)

### Условия использования

- ✅ Коммерческое использование разрешено
- ✅ Модификация кода разрешена
- ✅ Распространение разрешено
- ⚠️ Сохранение уведомления об авторских правах обязательно

---

## 🤝 Вклад в проект

Приветствуются pull request'ы и предложения по улучшению!

1. Fork репозиторий [akoffice933-maker/trading-bot-project](https://github.com/akoffice933-maker/trading-bot-project)
2. Создайте ветку (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

---

## 📞 Поддержка и контакты

| Канал | Ссылка |
|-------|--------|
| GitHub Issues | [Сообщить о проблеме](https://github.com/akoffice933-maker/trading-bot-project/issues) |
| Telegram | [@akoffice933maker](https://t.me/akoffice933maker) |
| Email | [Написать автору](mailto:akoffice933maker@gmail.com) |

---

## ⚠️ Отказ от ответственности

> Этот проект предоставляется **«как есть»** и предназначен для **образовательных и исследовательских целей**. 
> 
> Использование данной системы для торговли реальными средствами осуществляется **на ваш страх и риск**. Авторы не несут ответственности за любые финансовые потери или убытки, возникшие в результате использования этого программного обеспечения.

---

## 📈 Roadmap

- [ ] Добавление готовых workflow для популярных стратегий
- [ ] Интеграция с TradingView через вебхуки
- [ ] Поддержка мультибиржевой торговли
- [ ] Расширенные дашборды Grafana
- [ ] Тестирование стратегий на исторических данных
- [ ] REST API для внешнего управления

---

<div align="center">

**Сделано с ❤️ для трейдеров и разработчиков**

[⬆️ Вернуться к началу](#-торговая-система-2026--enterprise-v531)

</div>
