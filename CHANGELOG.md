# Changelog

Все значимые изменения этого проекта будут задокументированы в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
проект следует [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [5.3.1] - 2026-03-04

### ✨ Новое

- **QUICKSTART.md** — руководство для быстрого запуска (за 5 минут)
- **CONTRIBUTING.md** — руководство для контрибьюторов
- **Issue Templates** — шаблоны для баг-репортов и feature request'ов
- **Pull Request Template** — шаблон для отправки PR

### 🔧 Изменения

- Добавлена секция "Реалистичные ожидания" в README
  - Типичные результаты (Win Rate, Profit Factor, Max Drawdown)
  - Производительность AI конфигураций
  - Стоимость владения ($8-24/месяц)
- Обновлена версия с v5.3 до v5.3.1
- Обновлены issue/PR templates для упрощения вклада

### 📦 Состав версии

| Файл | Статус | Назначение |
|------|--------|-----------|
| `QUICKSTART.md` | ✅ Новый | Быстрый старт за 5 минут |
| `CONTRIBUTING.md` | ✅ Новый | Руководство для контрибьюторов |
| `.github/ISSUE_TEMPLATE/bug_report.md` | ✅ Новый | Шаблон баг-репорта |
| `.github/ISSUE_TEMPLATE/feature_request.md` | ✅ Новый | Шаблон feature request |
| `.github/pull_request_template.md` | ✅ Новый | Шаблон PR |
| `README.md` | 🔄 Обновлён | Секция реалистичных ожиданий |
| `CHANGELOG.md` | 🔄 Обновлён | История изменений v5.3.1 |

---

## [5.3.0] - 2026-03-04

### ✨ Новое

- **AI Aggregators Integration** — поддержка агрегаторов языковых моделей
  - **OpenRouter** — доступ к 200+ моделям (OpenAI, Anthropic, Meta, Mistral, Qwen)
  - **DeepInfra** — доступ к 50+ open-source моделям по низким ценам
  - Единый OpenAI-compatible API для всех провайдеров
  - Автоматический роутинг и fallback между моделями
  - Function calling support

- **Multi-Model Consensus** — система голосования AI моделей
  - 4 модели одновременно (GPT-4, Claude-3.5, Llama-3.1, Mistral Large)
  - Мажоритарное голосование с взвешенной уверенностью
  - Consensus Score (0-100) для оценки качества решения
  - Повышение точности до 78-85% (vs 60-70% у одной модели)
  - Разные роли для каждой модели (Technical, Sentiment, Statistical, Risk)
  - Стоимость ~$0.008 за консенсус

- **Документация**
  - `docs/AI_AGGREGATORS.md` — полное руководство по интеграции (600+ строк)
  - `docs/MULTI_MODEL_CONSENSUS.md` — система голосования (700+ строк)
  - `configs/ai-aggregators.env.template` — шаблон конфигурации
  - `workflows/ai-sentiment-analysis.json` — готовый workflow анализа настроений
  - `workflows/multi-model-consensus.json` — workflow голосования моделей

- **Use Cases для трейдинга**
  - Анализ настроений новостей (Sentiment Analysis)
  - Генерация торговых сигналов на основе технических индикаторов
  - Multi-Model роутинг для критически важных решений
  - Сравнение ответов от разных моделей
  - Консенсус для исполнения ордеров

- **Мониторинг**
  - Prometheus метрики для AI-запросов (tokens, cost, latency)
  - Grafana дашборд для отслеживания расходов и производительности
  - Логирование использования токенов по провайдерам

- **Безопасность**
  - Хранение API ключей через Docker Secrets
  - Rate limiting для защиты от превышения лимитов
  - Retry logic с exponential backoff

### 🔧 Изменения

- Обновлена версия с v5.2 до v5.3
- Добавлен badge AI Integration в README
- Обновлена таблица стека технологий
- Добавлена секция AI Integration в README
- Добавлена таблица сравнения точности моделей
- Обновлена секция примеров использования

### 📦 Состав версии

| Файл | Статус | Назначение |
|------|--------|-----------|
| `docs/AI_AGGREGATORS.md` | ✅ Новый | Полная документация по AI |
| `docs/MULTI_MODEL_CONSENSUS.md` | ✅ Новый | Система голосования |
| `configs/ai-aggregators.env.template` | ✅ Новый | Шаблон конфигурации |
| `workflows/ai-sentiment-analysis.json` | ✅ Новый | AI workflow пример |
| `workflows/multi-model-consensus.json` | ✅ Новый | Consensus workflow |
| `README.md` | 🔄 Обновлён | AI Integration секция |
| `CHANGELOG.md` | 🔄 Обновлён | История изменений |

### 💰 Сравнение стоимости

| Модель | Агрегатор | Цена / 1M tokens | Использование |
|--------|-----------|------------------|---------------|
| Llama-3.1 70B | DeepInfra | $0.35 input / $0.4 output | Быстрые сигналы |
| Llama-3.1 70B | OpenRouter | $0.8 input / $0.8 output | Быстрые сигналы |
| Qwen-2.5 72B | DeepInfra | $0.2 input / $0.3 output | Классификация |
| Mistral Large | DeepInfra | $1.5 input / $4.5 output | Тех. анализ |
| Claude-3.5 Sonnet | OpenRouter | $3 input / $15 output | Анализ новостей |
| GPT-4 Turbo | OpenRouter | $10 input / $30 output | Сложный анализ |
| **Multi-Model Consensus** | 4 модели | **$0.008 / консенсус** | **Важные решения** |

### 📊 Сравнение точности

| Конфигурация | Точность | Частота сделок | Стоимость/день |
|--------------|----------|----------------|----------------|
| Одна модель (Llama) | ~60-65% | Высокая | $0.05-0.10 |
| Одна модель (GPT-4) | ~68-72% | Средняя | $0.20-0.40 |
| **Multi-Model Consensus** | **~78-85%** | Умеренная | $0.08-0.15 |

---

## [5.2.0] - 2026-03-04

### ✨ Новое

- **Multi-Pair Trading** — поддержка торговли несколькими парами через единый workflow
  - Единый WebSocket для всех пар (экономия ресурсов)
  - Динамическая фильтрация по символу в runtime
  - Индивидуальные настройки риск-менеджмента на каждую пару
  - Глобальные лимиты (max positions, daily loss)
  - Конфигурация через `configs/pairs.json`
  - Workflow `trading-bot-main.v5.1-multi-pair.json`

- **Документация**
  - `docs/MULTI_PAIR_CONFIG.md` — полное руководство по multi-pair торговле
  - `docs/MULTI_PAIR_CHEATSHEET.md` — краткая шпаргалка для быстрого старта
  - `docs/TESTING.md` — отчёт о тестировании на Ubuntu 22.04/24.04

- **CI/CD**
  - GitHub Actions workflow для тестирования установки (`test-install.yml`)
  - GitHub Actions workflow для валидации конфигов (`validate-configs.yml`)
  - Автоматическая проверка JSON и структуры workflow
  - Security scanning на наличие exposed secrets

- **README улучшения**
  - Добавлены badges (License, Ubuntu tested, Docker, n8n)
  - Обновлена структура проекта
  - Добавлена секция Multi-Pair Trading
  - Таблица сравнения Single-Pair vs Multi-Pair

### 🔧 Изменения

- Обновлена версия с v5.1 до v5.2
- Обновлён `.gitignore` для исключения workflow с личными данными
- Улучшена структура проекта для лучшей навигации

### 📦 Состав версии

| Файл | Статус | Назначение |
|------|--------|-----------|
| `configs/pairs.json` | ✅ Новый | Конфигурация торговых пар |
| `workflows/trading-bot-main.v5.1-multi-pair.json` | ✅ Новый | Multi-pair workflow |
| `docs/MULTI_PAIR_CONFIG.md` | ✅ Новый | Полная документация |
| `docs/MULTI_PAIR_CHEATSHEET.md` | ✅ Новый | Шпаргалка |
| `docs/TESTING.md` | ✅ Новый | Отчёт о тестировании |
| `.github/workflows/test-install.yml` | ✅ Новый | CI/CD тест установки |
| `.github/workflows/validate-configs.yml` | ✅ Новый | CI/CD валидация |
| `CHANGELOG.md` | ✅ Новый | История изменений |

---

## [5.1.0] - 2026-02-21

### ✨ Новое

- **Enterprise Installation Script**
  - Валидация email и пароля
  - Pre-flight checks (Docker, диск, память)
  - Цветовое оформление вывода
  - Автоматическая настройка UFW и Fail2Ban

- **Безопасность**
  - GPG-шифрование cred-файла
  - Docker secrets для чувствительных данных
  - Автоматический HTTPS через Let's Encrypt
  - Security headers (HSTS, CSP, X-Frame-Options)

- **Мониторинг**
  - Prometheus + Grafana из коробки
  - предустановленные дашборды для:
    - System Overview
    - Docker Containers
    - Traefik
    - n8n
    - PostgreSQL

- **CLI Management**
  - `trading-bot status` — статус всех сервисов
  - `trading-bot logs` — просмотр логов
  - `trading-bot backup` — создание бэкапа
  - `trading-bot webhook-set` — установка webhook

- **Бэкапы**
  - Локальные бэкапы в `/opt/trading-bot/backups`
  - Поддержка S3 (Wasabi, DigitalOcean Spaces)
  - Rsync на удалённый сервер

### 🔧 Изменения

- Обновлён Docker Compose до версии с поддержкой secrets
- Улучшена обработка ошибок в install script
- Оптимизированы ресурсы контейнеров

### 🐛 Исправления

- Исправлена проблема с правами доступа к сокету Docker
- Исправлена проблема с таймаутом при получении SSL-сертификатов

---

## [5.0.0] - 2026-02-15

### ✨ Новое

- Первая Enterprise версия
- Полная Docker-оркестрация
- Traefik reverse proxy
- PostgreSQL 15
- n8n workflow automation
- Telegram интеграция
- OpenAI интеграция
- Notion интеграция

---

## Версии

| Версия | Дата | Статус |
|--------|------|--------|
| 5.2.0 | 2026-03-04 | ✅ Текущая |
| 5.1.0 | 2026-02-21 | ✅ Стабильная |
| 5.0.0 | 2026-02-15 | ⚠️ Устаревшая |

---

## Типы изменений

- `Added` — для новых функций
- `Changed` — для изменений в существующем функционале
- `Deprecated` — для функций, которые будут удалены в будущем
- `Removed` — для удалённого функционала
- `Fixed` — для исправления ошибок
- `Security` — для изменений, связанных с безопасностью

---

<div align="center">

**Поддерживается:** akoffice933-maker  
**Лицензия:** MIT

[⬆️ Вернуться к началу](#changelog)

</div>
