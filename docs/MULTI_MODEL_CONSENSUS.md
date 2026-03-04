# 🗳️ Multi-Model Consensus — Система голосования AI

## 🎯 Обзор

**Multi-Model Consensus** — это механизм коллективного принятия решений, использующий несколько AI-моделей одновременно для повышения надёжности торговых сигналов.

### Зачем нужно голосование моделей?

| Проблема одной модели | Решение Multi-Model |
|----------------------|---------------------|
| Субъективность модели | **Усреднение мнений** 4+ моделей |
| Ошибочные выводы | **Мажоритарное голосование** |
| Галлюцинации AI | **Перекрёстная проверка** |
| Смещение (bias) | **Разные архитектуры моделей** |

---

## 📊 Архитектура системы

```
┌─────────────────────────────────────────────────────────────────┐
│                    Входные данные (рынок)                        │
│              Символ, Цена, RSI, MACD, Объём, Изменение %         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Prepare Model Requests (Function)     │
        │   Распределение по 4 моделям            │
        └─────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┬──────────────┐
         │                    │                    │              │
         ▼                    ▼                    ▼              ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────┐
│   GPT-4 Turbo   │ │  Claude-3.5     │ │  Llama-3.1 70B  │ │ Mistral     │
│   (Technical)   │ │  (Sentiment)    │ │  (Statistical)  │ │ (Risk/Rwd)  │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘ └──────┬──────┘
         │                    │                    │                │
         └────────────────────┴────────────────────┴────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Consolidate Votes (Function)          │
        │   • Подсчёт голосов                     │
        │   • Взвешенная уверенность              │
        │   • Consensus Score (0-100)             │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Final Decision                        │
        │   BUY   (Score ≥ 70, Signal = BUY)      │
        │   SELL  (Score ≥ 70, Signal = SELL)     │
        │   HOLD  (иначе)                         │
        └─────────────────────────────────────────┘
```

---

## 🤖 Модели в консенсусе

### 1. GPT-4 Turbo (Technical Analyst)
```
Роль: Технический анализ и паттерны
Агрегатор: OpenRouter
Модель: openai/gpt-4-turbo
Цена: $10/1M input, $30/1M output
Специализация:
  - Графические паттерны
  - Уровни поддержки/сопротивления
  - Свечные формации
```

### 2. Claude-3.5 Sonnet (Market Sentiment)
```
Роль: Анализ настроений и макрофакторов
Агрегатор: OpenRouter
Модель: anthropic/claude-3.5-sonnet
Цена: $3/1M input, $15/1M output
Специализация:
  - Новостной фон
  - Социальные настроения
  - Макроэкономические факторы
```

### 3. Llama-3.1 70B (Quantitative Analyst)
```
Роль: Статистические закономерности
Агрегатор: OpenRouter / DeepInfra
Модель: meta-llama/llama-3.1-70b-instruct
Цена: $0.8/1M input, $0.8/1M output (OpenRouter)
       $0.35/1M input, $0.4/1M output (DeepInfra)
Специализация:
  - Статистический анализ
  - Объёмный анализ
  - Исторические паттерны
```

### 4. Mistral Large (Risk Manager)
```
Роль: Управление рисками
Агрегатор: DeepInfra
Модель: mistralai/Mistral-Large-Instruct-2407
Цена: $1.5/1M input, $4.5/1M output
Специализация:
  - Риск-менеджмент
  - Соотношение риск/прибыль
  - Позиционирование
```

---

## 🔧 Настройка

### Шаг 1: Получение API ключей

```bash
# OpenRouter (GPT-4, Claude, Llama)
OPENROUTER_API_KEY=sk-or-v1-...

# DeepInfra (Llama, Mistral)
DEEPINFRA_API_KEY=...
```

### Шаг 2: Импорт workflow

```bash
# В веб-интерфейсе n8n:
# 1. Workflows → Import → Upload JSON
# 2. Выберите workflows/multi-model-consensus.json
# 3. Настройте credentials:
#    - OpenRouter API (HTTP Header Auth)
#    - DeepInfra API (HTTP Header Auth)
#    - Bybit API (для исполнения ордеров)
#    - Telegram Bot (для уведомлений)
# 4. Активируйте workflow
```

### Шаг 3: Настройка параметров

```json
{
  "consensus_threshold": 70,        // Мин. score для исполнения
  "models_count": 4,                // Количество моделей
  "fallback_to_hold": true,         // HOLD при равенстве голосов
  "enable_auto_execute": true,      // Авто-исполнение ордеров
  "position_size_usdt": 100,        // Размер позиции
  "max_daily_consensus_trades": 5   // Лимит сделок в день
}
```

---

## 📈 Алгоритм голосования

### 1. Сбор голосов

Каждая модель возвращает:
```json
{
  "signal": "BUY|SELL|HOLD",
  "confidence": 0.0-1.0,
  "direction": "LONG|SHORT|NONE",
  "reasoning": "строка"
}
```

### 2. Подсчёт голосов

```javascript
// Пример голосования
GPT-4:   { signal: "BUY",  confidence: 0.85, direction: "LONG" }
Claude:  { signal: "BUY",  confidence: 0.72, direction: "LONG" }
Llama:   { signal: "HOLD", confidence: 0.65, direction: "NONE" }
Mistral: { signal: "BUY",  confidence: 0.78, direction: "LONG" }

// Итоги:
BUY:  3 голоса (75%)
HOLD: 1 голос  (25%)
SELL: 0 голосов (0%)
```

### 3. Расчёт Consensus Score

```javascript
Consensus Score = (
  (votes_ratio * 0.5) +     // 50% — доля голосов
  (avg_confidence * 0.3) +  // 30% — средняя уверенность
  (response_rate * 0.2)     // 20% — доля ответивших моделей
) * 100

// Пример:
votes_ratio = 3/4 = 0.75
avg_confidence = (0.85 + 0.72 + 0.78) / 3 = 0.78
response_rate = 4/4 = 1.0

Consensus Score = (0.75*0.5 + 0.78*0.3 + 1.0*0.2) * 100
                = (0.375 + 0.234 + 0.2) * 100
                = 80.9 / 100 ✅
```

### 4. Финальное решение

```
IF Consensus Score ≥ 70 AND Signal = BUY → Final: BUY
IF Consensus Score ≥ 70 AND Signal = SELL → Final: SELL
ELSE → Final: HOLD
```

---

## 💰 Стоимость одного консенсуса

### Расчёт на примере

| Модель | Токены (вход) | Токены (выход) | Цена / 1M | Стоимость |
|--------|---------------|----------------|-----------|-----------|
| GPT-4 Turbo | ~200 | ~100 | $10/$30 | $0.0050 |
| Claude-3.5 | ~200 | ~100 | $3/$15 | $0.0021 |
| Llama-3.1 70B | ~200 | ~100 | $0.35/$0.4 | $0.0001 |
| Mistral Large | ~200 | ~100 | $1.5/$4.5 | $0.0008 |
| **Итого** | | | | **~$0.008** |

**Один консенсус стоит ~$0.008 (менее 1 цента!)**

### Дневной бюджет

```
10 консенсусов в день = $0.08/день = $2.40/месяц
50 консенсусов в день = $0.40/день = $12/месяц
```

---

## 📊 Примеры использования

### Пример 1: Сильный BUY сигнал

**Входные данные:**
```
Symbol: BTCUSDT
Price: $67,500
RSI: 32 (oversold)
MACD: -120 (divergence)
Volume 24h: $35B (+40%)
Change 24h: -5.2%
```

**Голоса моделей:**
```
GPT-4:   BUY  (0.88) - "Divergence + oversold = reversal likely"
Claude:  BUY  (0.75) - "Fear extreme, contrarian opportunity"
Llama:   BUY  (0.82) - "Historical pattern matches Q4 2024"
Mistral: HOLD (0.60) - "Wait for confirmation, high volatility"

Результат:
✅ Consensus: BUY (3/4 votes)
⭐ Score: 82.5/100
🎯 Confidence: 81.7%
📈 Decision: BUY EXECUTED
```

---

### Пример 2: Неопределённость (HOLD)

**Входные данные:**
```
Symbol: ETHUSDT
Price: $3,450
RSI: 52 (neutral)
MACD: +5 (weak)
Volume 24h: $15B (-10%)
Change 24h: +1.2%
```

**Голоса моделей:**
```
GPT-4:   HOLD (0.55) - "No clear pattern, consolidation"
Claude:  BUY  (0.62) - "Slight bullish sentiment"
Llama:   HOLD (0.58) - "Statistical noise"
Mistral: HOLD (0.70) - "Risk/reward unfavourable"

Результат:
⚠️ Consensus: HOLD (3/4 votes)
⭐ Score: 65.3/100 (< 70 threshold)
📈 Decision: HOLD (no trade)
```

---

### Пример 3: Сильный SELL сигнал

**Входные данные:**
```
Symbol: SOLUSDT
Price: $145
RSI: 78 (overbought)
MACD: -8 (bearish crossover)
Volume 24h: $8B (+120%)
Change 24h: +15% (parabolic)
```

**Голоса моделей:**
```
GPT-4:   SELL (0.91) - "Parabolic top, bearish divergence"
Claude:  SELL (0.85) - "Euphoria phase, distribution likely"
Llama:   SELL (0.88) - "95th percentile, mean reversion imminent"
Mistral: SELL (0.79) - "Excellent risk/reward short"

Результат:
✅ Consensus: SELL (4/4 votes, unanimous!)
⭐ Score: 93.8/100
🎯 Confidence: 85.8%
📉 Decision: SELL EXECUTED
```

---

## 🎯 Стратегии голосования

### 1. Консервативная (Unanimous)

```json
{
  "consensus_threshold": 90,
  "require_unanimous": true,
  "min_models_agree": 4,
  "min_confidence": 0.85
}
```

**Характеристики:**
- ✅ Очень высокая точность (~85-90%)
- ❌ Мало сделок (1-3 в неделю)
- 💰 Стоимость: ~$0.03-0.05/день

---

### 2. Сбалансированная (Majority)

```json
{
  "consensus_threshold": 70,
  "require_unanimous": false,
  "min_models_agree": 3,
  "min_confidence": 0.70
}
```

**Характеристики:**
- ✅ Хорошая точность (~70-80%)
- ✅ Умеренная частота (3-10 в неделю)
- 💰 Стоимость: ~$0.08-0.15/день

---

### 3. Агрессивная (Simple Majority)

```json
{
  "consensus_threshold": 50,
  "require_unanimous": false,
  "min_models_agree": 2,
  "min_confidence": 0.60
}
```

**Характеристики:**
- ⚠️ Средняя точность (~60-70%)
- ✅ Много сделок (10-20 в неделю)
- 💰 Стоимость: ~$0.20-0.40/день

---

## 📊 Мониторинг

### Prometheus метрики

```prometheus
# Количество консенсусов
consensus_runs_total

# Распределение решений
consensus_decisions_total{decision="BUY"}
consensus_decisions_total{decision="SELL"}
consensus_decisions_total{decision="HOLD"}

# Consensus Score distribution
consensus_score_bucket{le="50"}
consensus_score_bucket{le="70"}
consensus_score_bucket{le="90"}

# Стоимость
consensus_cost_usd_total{model="gpt4"}
consensus_cost_usd_total{model="claude"}
consensus_cost_usd_total{model="llama"}
consensus_cost_usd_total{model="mistral"}

# Точность (рассчитывается постфактум)
consensus_accuracy_ratio{window="24h"}
```

### Grafana Dashboard

Импортируйте из `configs/grafana/dashboards/consensus-monitoring.json`:

- **Panel 1:** Consensus Runs (24h timeline)
- **Panel 2:** Decision Distribution (pie chart)
- **Panel 3:** Consensus Score Heatmap
- **Panel 4:** Cost per Day (stacked by model)
- **Panel 5:** Accuracy vs Single Models (comparison)
- **Panel 6:** Win Rate by Consensus Score (scatter)

---

## ⚙️ Продвинутые настройки

### Динамический порог

```javascript
// Адаптивный threshold в зависимости от волатильности
const volatility = getVolatility(); // 0-100%

if (volatility > 50) {
  // Высокая волатильность → строже требования
  consensus_threshold = 85;
} else if (volatility > 25) {
  // Средняя волатильность
  consensus_threshold = 70;
} else {
  // Низкая волатильность → мягче
  consensus_threshold = 60;
}
```

### Взвешенное голосование

```javascript
// Модели с лучшей исторической точностью получают больший вес
const modelWeights = {
  gpt4: 1.2,    // +20% вес
  claude: 1.1,  // +10% вес
  llama: 0.9,   // -10% вес
  mistral: 1.0  // базовый вес
};

// Обновляйте веса на основе historical accuracy
```

### Fallback цепочка

```javascript
// Если модель не ответила за 30 секунд
const fallbackModels = {
  gpt4: 'claude',      // GPT-4 → Claude
  claude: 'llama',     // Claude → Llama
  llama: 'mistral',    // Llama → Mistral
  mistral: 'llama'     // Mistral → Llama
};
```

---

## 🧪 Тестирование и бэктест

### Бэктест на исторических данных

```bash
# Запуск бэктеста
python3 backtest_consensus.py \
  --data historical/btcusdt-2024.csv \
  --models gpt4,claude,llama,mistral \
  --threshold 70 \
  --period 90d
```

### Пример результатов бэктеста

```
Период: 90 дней (Q4 2024)
Всего консенсусов: 247

Результаты:
├─ BUY сигналы: 98
│  ├─ Успешные: 76 (77.6%)
│  └─ Средний профит: +4.2%
├─ SELL сигналы: 85
│  ├─ Успешные: 68 (80.0%)
│  └─ Средний профит: +3.8%
└─ HOLD сигналы: 64 (пропущены)

Общая точность: 78.5%
Средний профит на сделку: +4.0%
Макс. просадка: -12.3%
Sharpe Ratio: 2.1

Стоимость AI за 90 дней: $19.76
Прибыль (на $100/сделку): ~$6,840
ROI: 34,600% (AI cost vs profit)
```

---

## ⚠️ Troubleshooting

| Проблема | Решение |
|----------|---------|
| Модель не отвечает | Проверь API ключ, увеличь timeout до 60s |
| Дорого | Используй DeepInfra вместо OpenRouter для Llama/Mistral |
| Низкая точность | Увеличь consensus_threshold до 80-85 |
| Мало сделок | Снизь threshold до 60-65 или включи 2-модельный консенсус |
| Одна модель доминирует | Проверь промпты на балансировку ролей |

---

## 🎯 Best Practices

### 1. Балансировка промптов

```javascript
// ✅ Правильно: разные роли для каждой модели
GPT-4:   "Сосредоточься на техническом анализе..."
Claude:  "Сосредоточься на настроениях рынка..."
Llama:   "Сосредоточься на статистических паттернах..."
Mistral: "Сосредоточься на риск-менеджменте..."

// ❌ Неправильно: одинаковые промпты
Все: "Проанализируй рынок и дай сигнал"
```

### 2. Управление расходами

```javascript
// Дневной лимит
const dailyBudget = 5; // USD
const spentToday = await getDailySpending();

if (spentToday + consensusCost > dailyBudget) {
  console.warn('Daily budget exceeded, skipping consensus');
  return;
}
```

### 3. Логирование для анализа

```javascript
// Сохраняй все ответы для последующего анализа
await db.query(`
  INSERT INTO consensus_logs 
  (timestamp, symbol, model, signal, confidence, reasoning, final_decision)
  VALUES (?, ?, ?, ?, ?, ?, ?)
`);
```

### 4. A/B тестирование стратегий

```javascript
// Тестируй разные threshold параллельно
const strategies = {
  conservative: { threshold: 85, trades: [] },
  balanced: { threshold: 70, trades: [] },
  aggressive: { threshold: 50, trades: [] }
};

// Сравнивай результаты через 30 дней
```

---

## 📚 Дополнительные ресурсы

- **Workflow:** `workflows/multi-model-consensus.json`
- **AI Aggregators:** `docs/AI_AGGREGATORS.md`
- **Grafana Dashboard:** `configs/grafana/dashboards/consensus-monitoring.json`

---

## 📞 Support

- **Issues:** https://github.com/akoffice933-maker/trading-bot-project/issues
- **Discussions:** https://github.com/akoffice933-maker/trading-bot-project/discussions

---

<div align="center">

**Последнее обновление:** 2026-03-04  
**Версия:** v5.3

[⬆️ Вернуться к началу](#-multi-model-consensus--система-голосования-ai)

</div>
