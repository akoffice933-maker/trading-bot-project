# 🧠 AI Integration: OpenRouter & DeepInfra

## 🎯 Обзор

Начиная с версии **v5.3**, торговая система поддерживает интеграцию с **AI-агрегаторами**, предоставляя доступ к **200+ языковым моделям** через единый API.

### Зачем нужны агрегаторы?

| Проблема | Решение |
|----------|---------|
| Нужно несколько API ключей | **Один ключ** на агрегатор |
| Разные форматы API | **Единый OpenAI-compatible API** |
| Сложно сравнивать цены | **Прозрачное ценообразование** |
| Нет fallback | **Автоматический роутинг** |
| Дорогие запросы | **Доступ к дешёвым open-source моделям** |

---

## 📊 Сравнение агрегаторов

### OpenRouter

| Параметр | Значение |
|----------|----------|
| **Моделей** | 200+ |
| **API Format** | OpenAI-compatible |
| **Auth** | Bearer Token |
| **Цены** | от $0.1/1M tokens |
| **Документация** | https://openrouter.ai/docs |

**Преимущества:**
- ✅ Огромный выбор моделей (OpenAI, Anthropic, Meta, Mistral, Qwen)
- ✅ Автоматический роутинг и fallback
- ✅ Unified API для всех провайдеров
- ✅ Детальная статистика использования
- ✅ Поддержка function calling

**Популярные модели:**
```
openai/gpt-4-turbo
anthropic/claude-3.5-sonnet
meta-llama/llama-3.1-70b-instruct
mistralai/mistral-large
qwen/qwen-2.5-72b-instruct
```

---

### DeepInfra

| Параметр | Значение |
|----------|----------|
| **Моделей** | 50+ |
| **API Format** | OpenAI-compatible |
| **Auth** | Bearer Token |
| **Цены** | от $0.07/1M tokens |
| **Документация** | https://deepinfra.com/docs |

**Преимущества:**
- ✅ Очень низкие цены
- ✅ Минимальные задержки
- ✅ Фокус на open-source моделях
- ✅ Поддержка embeddings
- ✅ Fine-tuning моделей

**Популярные модели:**
```
meta-llama/Meta-Llama-3.1-70B-Instruct
mistralai/Mistral-Large-Instruct-2407
Qwen/Qwen2.5-72B-Instruct
google/gemma-2-27b-it
```

---

## 🚀 Быстрый старт

### Шаг 1: Получение API ключей

#### OpenRouter
```bash
# 1. Перейдите на https://openrouter.ai/keys
# 2. Зарегистрируйтесь
# 3. Создайте API ключ
# 4. Скопируйте ключ (начинается с sk-or-v1-)
```

#### DeepInfra
```bash
# 1. Перейдите на https://deepinfra.com/dash/api_keys
# 2. Зарегистрируйтесь
# 3. Создайте API ключ
# 4. Скопируйте ключ
```

---

### Шаг 2: Настройка переменных окружения

```bash
# Добавьте в .env файл
cat >> .env << 'EOF'

# AI Aggregators
OPENROUTER_API_KEY=sk-or-v1-your-key-here
DEEPINFRA_API_KEY=your-deepinfra-key

# Default модель (опционально)
DEFAULT_AI_MODEL=meta-llama/llama-3.1-70b-instruct
AI_AGGREGATOR=openrouter  # или deepinfra
EOF
```

---

### Шаг 3: Импорт workflow

```bash
# В веб-интерфейсе n8n:
# 1. Workflows → Import → Upload JSON
# 2. Выберите workflows/ai-sentiment-analysis.json
# 3. Настройте credentials
# 4. Активируйте workflow
```

---

## 🔧 Настройка в n8n

### HTTP Request нода для OpenRouter

```json
{
  "method": "POST",
  "url": "https://openrouter.ai/api/v1/chat/completions",
  "headers": {
    "Authorization": "Bearer {{ $credentials.openrouterApiKey }}",
    "Content-Type": "application/json",
    "HTTP-Referer": "https://yourdomain.com",
    "X-Title": "Trading Bot"
  },
  "body": {
    "model": "meta-llama/llama-3.1-70b-instruct",
    "messages": [
      {
        "role": "user",
        "content": "={{ $json.prompt }}"
      }
    ],
    "temperature": 0.3,
    "max_tokens": 500
  }
}
```

### HTTP Request нода для DeepInfra

```json
{
  "method": "POST",
  "url": "https://api.deepinfra.com/v1/openai/chat/completions",
  "headers": {
    "Authorization": "Bearer {{ $credentials.deepinfraApiKey }}",
    "Content-Type": "application/json"
  },
  "body": {
    "model": "meta-llama/Meta-Llama-3.1-70B-Instruct",
    "messages": [
      {
        "role": "user",
        "content": "={{ $json.prompt }}"
      }
    ],
    "temperature": 0.3,
    "max_tokens": 500
  }
}
```

---

## 📈 Use Cases для трейдинга

### 1. Анализ настроений новостей

**Workflow:**
```
RSS Feed / Telegram → n8n → AI Analysis → Sentiment Score → Trading Decision
```

**Промпт:**
```
Проанализируй новость и определи настроение рынка:

Новость: "{{ $json.news_text }}"

Верни JSON:
{
  "sentiment": "positive|negative|neutral",
  "confidence": 0.0-1.0,
  "impact_score": -10 до +10,
  "summary": "краткое описание"
}
```

**Модель:** `meta-llama/llama-3.1-70b-instruct`  
**Стоимость:** ~$0.001 на анализ

---

### 2. Генерация торговых сигналов

**Workflow:**
```
Индикаторы (RSI, MACD, MA) → AI → Signal → Bybit Order
```

**Промпт:**
```
На основе технических индикаторов определи сигнал:

BTCUSDT:
- RSI(14): {{ $json.rsi }}
- MACD: {{ $json.macd }}
- Price vs MA200: {{ $json.price_vs_ma }}
- Volume 24h: {{ $json.volume }}

Верни JSON:
{
  "signal": "BUY|SELL|HOLD",
  "confidence": 0.0-1.0,
  "direction": "LONG|SHORT",
  "entry_price": ...,
  "stop_loss": ...,
  "take_profit": ...,
  "reasoning": "краткое обоснование"
}
```

**Модель:** `mistralai/mistral-large`  
**Стоимость:** ~$0.002 на сигнал

---

### 3. Multi-Model роутинг

**Архитектура:**
```
Запрос → Router →
  ├─ GPT-4 Turbo (сложные задачи)
  ├─ Claude-3.5 (анализ текста)
  ├─ Llama-3 (быстрые запросы)
  └─ Qwen-2.5 (классификация)
```

**Промпт для роутера:**
```
Определи, какая модель лучше подходит для задачи:

Задача: "{{ $json.task }}"

Типы задач:
- complex_analysis → gpt-4-turbo
- text_analysis → claude-3.5-sonnet
- quick_response → llama-3.1-70b
- classification → qwen-2.5-72b
```

---

### 4. Сравнение ответов от разных моделей

**Workflow:**
```
Запрос → 
  ├─ OpenRouter (GPT-4) → Ответ 1
  ├─ OpenRouter (Claude) → Ответ 2
  └─ DeepInfra (Llama) → Ответ 3
       ↓
Consolidate → Финальное решение
```

**Использование:** Для критически важных решений

---

## 💰 Сравнение стоимости

| Модель | Агрегатор | Input / 1M | Output / 1M | Пример запроса |
|--------|-----------|------------|-------------|----------------|
| **GPT-4 Turbo** | OpenRouter | $10 | $30 | Сложный анализ |
| **Claude-3.5 Sonnet** | OpenRouter | $3 | $15 | Анализ новостей |
| **Llama-3.1 70B** | OpenRouter | $0.8 | $0.8 | Быстрые сигналы |
| **Llama-3.1 70B** | DeepInfra | $0.35 | $0.4 | Быстрые сигналы |
| **Mistral Large** | OpenRouter | $2 | $6 | Тех. анализ |
| **Mistral Large** | DeepInfra | $1.5 | $4.5 | Тех. анализ |
| **Qwen-2.5 72B** | OpenRouter | $0.4 | $0.6 | Классификация |
| **Qwen-2.5 72B** | DeepInfra | $0.2 | $0.3 | Классификация |

**Совет:** Для production используйте DeepInfra для bulk-задач, OpenRouter — для критически важных.

---

## 🔐 Безопасность

### Хранение API ключей

```bash
# ✅ Правильно: через Docker Secrets
docker secret create openrouter_api_key /path/to/key.txt

# ✅ Правильно: через .env (chmod 600)
chmod 600 .env

# ❌ Неправильно: хардкод в workflow
```

### Rate Limiting

```javascript
// В Function ноде n8n
const rateLimit = {
  openrouter: { requests: 100, period: 60000 }, // 100/мин
  deepinfra: { requests: 200, period: 60000 }   // 200/мин
};

// Проверка лимита
if (requestsThisMinute > rateLimit[provider].requests) {
  throw new Error('Rate limit exceeded');
}
```

---

## 📊 Мониторинг

### Prometheus метрики

```prometheus
# Количество запросов к AI
ai_requests_total{provider="openrouter", model="llama-3.1-70b"}

# Средняя задержка
ai_request_duration_seconds{provider="deepinfra"}

# Токены (input/output)
ai_tokens_total{type="input", provider="openrouter"}
ai_tokens_total{type="output", provider="openrouter"}

# Стоимость (USD)
ai_cost_usd_total{provider="openrouter"}
```

### Grafana Dashboard

Импортируйте дашборд из `configs/grafana/dashboards/ai-monitoring.json`:

- **Panel 1:** Requests per minute (по провайдерам)
- **Panel 2:** Average latency (heatmap)
- **Panel 3:** Token usage (input/output)
- **Panel 4:** Cost per day (stacked bar)
- **Panel 5:** Error rate (line chart)

---

## ⚠️ Troubleshooting

| Проблема | Решение |
|----------|---------|
| 401 Unauthorized | Проверь API ключ в credentials |
| 429 Too Many Requests | Увеличь delay между запросами |
| 500 Internal Error | Включи retry logic (3 попытки) |
| Пустой ответ | Увеличь `max_tokens` |
| Дорого | Используй cheaper модели (Llama/Qwen) |

---

## 🎯 Best Practices

### 1. Кэширование ответов

```javascript
// Кэширование одинаковых запросов
const cache = new Map();
const cacheKey = JSON.stringify({ model, prompt });

if (cache.has(cacheKey) && Date.now() - cache.get(cacheKey).time < 300000) {
  return cache.get(cacheKey).response;
}
```

### 2. Retry с exponential backoff

```javascript
// Retry logic
async function requestWithRetry(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(r => setTimeout(r, Math.pow(2, i) * 1000));
    }
  }
}
```

### 3. Fallback на другую модель

```javascript
// Fallback цепочка
const models = ['gpt-4-turbo', 'claude-3.5', 'llama-3.1-70b'];

for (const model of models) {
  try {
    return await callAI(model, prompt);
  } catch (error) {
    console.warn(`Model ${model} failed, trying next...`);
  }
}
```

### 4. Лимитирование расходов

```javascript
// Дневной лимит
const dailyLimit = 10; // USD
const spentToday = await getDailySpending();

if (spentToday + estimatedCost > dailyLimit) {
  throw new Error('Daily budget exceeded');
}
```

---

## 📚 Дополнительные ресурсы

- **OpenRouter Docs:** https://openrouter.ai/docs
- **DeepInfra Docs:** https://deepinfra.com/docs
- **Model Pricing:** https://openrouter.ai/models
- **n8n HTTP Request:** https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest/

---

## 📞 Support

- **Issues:** https://github.com/akoffice933-maker/trading-bot-project/issues
- **Discussions:** https://github.com/akoffice933-maker/trading-bot-project/discussions

---

<div align="center">

**Последнее обновление:** 2026-03-04  
**Версия:** v5.3

[⬆️ Вернуться к началу](#-ai-integration-openrouter--deepinfra)

</div>
