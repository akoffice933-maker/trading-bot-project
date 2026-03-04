# 📊 Multi-Pair Trading Configuration

## 🎯 Обзор

Версия **v5.2+** поддерживает торговлю несколькими торговыми парами через единый workflow с динамической фильтрацией.

---

## 📁 Структура `pairs.json`

```json
{
  "enabled": true,                    // Глобальное включение/выключение multi-pair
  "pairs": [                          // Массив торговых пар
    {
      "symbol": "BTCUSDT",            // Символ (как в Bybit API)
      "enabled": true,                // Включена ли эта пара
      "risk": {                       // Настройки риск-менеджмента
        "position_size_usdt": 100,    // Размер позиции в USDT
        "stop_loss_pct": 2.0,         // Stop-Loss в процентах
        "take_profit_pct": 4.0,       // Take-Profit в процентах
        "max_daily_trades": 5         // Максимум сделок в день
      },
      "filters": {                    // Фильтры для входа
        "min_volume_24h": 1000000,    // Мин. объем за 24ч в USDT
        "volatility_max_pct": 15.0    // Макс. волатильность в %
      }
    }
  ],
  "global_settings": {                // Глобальные настройки
    "max_total_positions": 3,         // Макс. одновременных позиций
    "max_daily_loss_usdt": 150,       // Макс. дневной убыток
    "trading_hours": {                // Ограничение по времени (опционально)
      "enabled": false,
      "start_utc": "00:00",
      "end_utc": "23:59"
    }
  }
}
```

---

## 🚀 Быстрый старт

### Шаг 1: Настройте `pairs.json`

```bash
# Отредактируйте конфигурацию
nano configs/pairs.json

# Включите нужные пары
# "enabled": true  → пара торгуется
# "enabled": false → пара игнорируется
```

### Шаг 2: Импортируйте workflow

```bash
# В веб-интерфейсе n8n:
# 1. Workflows → Import → Upload JSON
# 2. Выберите workflows/trading-bot-main.v5.1-multi-pair.json
# 3. Активируйте workflow
```

### Шаг 3: Подключите `pairs.json` к workflow

В ноде **Filter by Symbol** замените хардкод на чтение файла:

```javascript
// Вариант 1: Через Environment Variable
const pairsConfig = JSON.parse(process.env.PAIRS_CONFIG || '{}');

// Вариант 2: Через HTTP Request (если файл на сервере)
// Используйте ноду HTTP Request для GET /configs/pairs.json

// Вариант 3: Через n8n Credentials
// Сохраните JSON в credential типа "Custom JSON"
```

---

## 📈 Примеры конфигураций

### Консервативная (1 пара)
```json
{
  "enabled": true,
  "pairs": [
    {
      "symbol": "BTCUSDT",
      "enabled": true,
      "risk": {
        "position_size_usdt": 50,
        "stop_loss_pct": 1.5,
        "take_profit_pct": 3.0,
        "max_daily_trades": 3
      },
      "filters": {
        "min_volume_24h": 5000000,
        "volatility_max_pct": 10.0
      }
    }
  ],
  "global_settings": {
    "max_total_positions": 1,
    "max_daily_loss_usdt": 50
  }
}
```

### Агрессивная (5 пар)
```json
{
  "enabled": true,
  "pairs": [
    {"symbol": "BTCUSDT", "enabled": true, "risk": {"position_size_usdt": 100, "stop_loss_pct": 2.0, "take_profit_pct": 4.0, "max_daily_trades": 5}},
    {"symbol": "ETHUSDT", "enabled": true, "risk": {"position_size_usdt": 100, "stop_loss_pct": 2.5, "take_profit_pct": 5.0, "max_daily_trades": 5}},
    {"symbol": "SOLUSDT", "enabled": true, "risk": {"position_size_usdt": 50, "stop_loss_pct": 3.0, "take_profit_pct": 6.0, "max_daily_trades": 4}},
    {"symbol": "BNBUSDT", "enabled": true, "risk": {"position_size_usdt": 75, "stop_loss_pct": 2.0, "take_profit_pct": 4.5, "max_daily_trades": 4}},
    {"symbol": "XRPUSDT", "enabled": false, "risk": {"position_size_usdt": 50, "stop_loss_pct": 3.0, "take_profit_pct": 6.0, "max_daily_trades": 3}}
  ],
  "global_settings": {
    "max_total_positions": 3,
    "max_daily_loss_usdt": 200
  }
}
```

### Только скальпинг (высокая волатильность)
```json
{
  "enabled": true,
  "pairs": [
    {
      "symbol": "PEPEUSDT",
      "enabled": true,
      "risk": {
        "position_size_usdt": 25,
        "stop_loss_pct": 5.0,
        "take_profit_pct": 10.0,
        "max_daily_trades": 10
      },
      "filters": {
        "min_volume_24h": 500000,
        "volatility_max_pct": 50.0
      }
    }
  ],
  "global_settings": {
    "max_total_positions": 2,
    "max_daily_loss_usdt": 100
  }
}
```

---

## 🔧 Продвинутые настройки

### Динамическое изменение конфигурации

```bash
# API endpoint для обновления пар (требует авторизации)
curl -X POST http://localhost:5678/api/v1/trading-bot/pairs \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"symbol": "ADAUSDT", "enabled": true}'

# Перезагрузка конфигурации без рестарта
docker exec -it n8n-bot bash -c "trading-bot reload-pairs"
```

### Логирование по парам

```bash
# Логи только по BTC
docker logs n8n-bot 2>&1 | grep "BTCUSDT"

# Логи только по ошибкам
docker logs n8n-bot 2>&1 | grep "ERROR.*pair"

# Статистика по парам (через Prometheus)
curl http://localhost:9090/api/v1/query?query=trading_pairs_trades_total
```

---

## 📊 Мониторинг

### Grafana Dashboard

Импортируйте дашборд из `configs/grafana/dashboards/multi-pair-trading.json`:

- **Panel 1:** Active Pairs (сколько пар сейчас торгуется)
- **Panel 2:** Trades by Symbol (столбчатая диаграмма)
- **Panel 3:** P&L per Pair (линейный график)
- **Panel 4:** Daily Trade Count (heatmap по часам)
- **Panel 5:** Win Rate by Symbol (pie chart)

### Prometheus Metrics

```prometheus
# Количество сделок по паре
trading_pairs_trades_total{symbol="BTCUSDT"}

# Текущая позиция по паре
trading_pairs_position_size{symbol="ETHUSDT"}

# Дневной P&L по паре
trading_pairs_daily_pnl{symbol="SOLUSDT"}

# Активность пары (1 = активна, 0 = неактивна)
trading_pairs_enabled{symbol="BNBUSDT"}
```

---

## ⚠️ Важные замечания

### 1. Rate Limits Bybit

```
🔹 Один WebSocket на все пары → экономия соединений
🔹 Но: фильтрация на стороне n8n → больше CPU
🔹 Рекомендация: max 10 активных пар на один инстанс
```

### 2. Ресурсы контейнера n8n

| Кол-во пар | RAM (мин) | CPU (мин) |
|------------|-----------|-----------|
| 1-3        | 512 MB    | 0.5 core  |
| 4-7        | 1 GB      | 1 core    |
| 8-12       | 2 GB      | 2 cores   |

### 3. Отладка

```bash
# Включите debug-логирование для конкретной пары
export DEBUG_PAIRS="BTCUSDT,ETHUSDT"

# Просмотр отфильтрованных сообщений
docker logs n8n-bot 2>&1 | grep "FILTER_PASS"
```

---

## 🆙 Миграция с single-pair

Если вы использовали версию v5.1 с одной парой:

```bash
# 1. Сделайте бэкап текущей конфигурации
cp configs/pairs.json configs/pairs.json.backup

# 2. Создайте новый pairs.json с одной парой
cat > configs/pairs.json << 'EOF'
{
  "enabled": true,
  "pairs": [
    {
      "symbol": "BTCUSDT",
      "enabled": true,
      "risk": {
        "position_size_usdt": 100,
        "stop_loss_pct": 2.0,
        "take_profit_pct": 4.0,
        "max_daily_trades": 5
      },
      "filters": {
        "min_volume_24h": 1000000,
        "volatility_max_pct": 15.0
      }
    }
  ],
  "global_settings": {
    "max_total_positions": 1,
    "max_daily_loss_usdt": 100
  }
}
EOF

# 3. Импортируйте multi-pair workflow
# 4. Протестируйте на одной паре
# 5. Постепенно добавляйте новые пары
```

---

## 📞 Support

- **Issues:** https://github.com/akoffice933-maker/trading-bot-project/issues
- **Discussions:** https://github.com/akoffice933-maker/trading-bot-project/discussions
- **Documentation:** https://github.com/akoffice933-maker/trading-bot-project/tree/main/docs
