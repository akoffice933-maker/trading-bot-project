# 📊 Multi-Pair Trading — Шпаргалка

## ⚡ Быстрый старт (30 секунд)

```bash
# 1. Отредактируйте пары
nano configs/pairs.json

# 2. Включите нужные пары (enabled: true)

# 3. Импортируйте workflow в n8n
# workflows/trading-bot-main.v5.1-multi-pair.json

# 4. Активируйте и готово!
```

---

## 🎯 Примеры конфигураций

### Консервативная (BTC только)
```json
{
  "enabled": true,
  "pairs": [
    {
      "symbol": "BTCUSDT",
      "enabled": true,
      "risk": {"position_size_usdt": 50, "stop_loss_pct": 1.5, "take_profit_pct": 3.0}
    }
  ],
  "global_settings": {"max_total_positions": 1, "max_daily_loss_usdt": 50}
}
```

### Сбалансированная (3 пары)
```json
{
  "enabled": true,
  "pairs": [
    {"symbol": "BTCUSDT", "enabled": true, "risk": {"position_size_usdt": 100, "stop_loss_pct": 2.0, "take_profit_pct": 4.0}},
    {"symbol": "ETHUSDT", "enabled": true, "risk": {"position_size_usdt": 100, "stop_loss_pct": 2.5, "take_profit_pct": 5.0}},
    {"symbol": "SOLUSDT", "enabled": false, "risk": {"position_size_usdt": 50, "stop_loss_pct": 3.0, "take_profit_pct": 6.0}}
  ],
  "global_settings": {"max_total_positions": 2, "max_daily_loss_usdt": 150}
}
```

### Агрессивная (5+ пар)
```json
{
  "enabled": true,
  "pairs": [
    {"symbol": "BTCUSDT", "enabled": true, "risk": {"position_size_usdt": 100, "stop_loss_pct": 2.0, "take_profit_pct": 4.0}},
    {"symbol": "ETHUSDT", "enabled": true, "risk": {"position_size_usdt": 100, "stop_loss_pct": 2.5, "take_profit_pct": 5.0}},
    {"symbol": "SOLUSDT", "enabled": true, "risk": {"position_size_usdt": 75, "stop_loss_pct": 3.0, "take_profit_pct": 6.0}},
    {"symbol": "BNBUSDT", "enabled": true, "risk": {"position_size_usdt": 75, "stop_loss_pct": 2.0, "take_profit_pct": 4.5}},
    {"symbol": "XRPUSDT", "enabled": true, "risk": {"position_size_usdt": 50, "stop_loss_pct": 3.0, "take_profit_pct": 6.0}}
  ],
  "global_settings": {"max_total_positions": 3, "max_daily_loss_usdt": 200}
}
```

---

## 🔧 Управление

### Включить/выключить пару
```json
// В configs/pairs.json измените:
"enabled": true   // ← включить
"enabled": false  // ← выключить
```

### Изменить размер позиции
```json
// В объекте pair.risk:
"risk": {
  "position_size_usdt": 150  // ← новый размер
}
```

### Изменить SL/TP
```json
"risk": {
  "stop_loss_pct": 2.5,     // ← Stop-Loss %
  "take_profit_pct": 5.0    // ← Take-Profit %
}
```

### Дневной лимит сделок
```json
"risk": {
  "max_daily_trades": 5  // ← максимум сделок в день
}
```

---

## 📊 Мониторинг

### Логи по паре
```bash
# BTCUSDT
docker logs n8n-bot 2>&1 | grep "BTCUSDT"

# ETHUSDT
docker logs n8n-bot 2>&1 | grep "ETHUSDT"
```

### Статус всех пар
```bash
# Просмотр активной конфигурации
cat configs/pairs.json | jq '.pairs[] | select(.enabled == true) | .symbol'
```

### Перезагрузка конфигурации
```bash
# Без рестарта контейнера
docker exec n8n-bot trading-bot reload-pairs
```

---

## ⚠️ Чеклист перед запуском

- [ ] Проверил `pairs.json` на синтаксис (JSON valid)
- [ ] Включил только 1-3 пары для теста
- [ ] Установил адекватные SL/TP (не 0%!)
- [ ] Проверил `max_daily_loss_usdt` (риск-менеджмент)
- [ ] Убедился, что `max_total_positions` < кол-ва активных пар
- [ ] Запустил на demo/testnet сначала

---

## 🚨 Troubleshooting

| Проблема | Решение |
|----------|---------|
| Пары не торгуются | Проверь `enabled: true` в pairs.json |
| Слишком много сделок | Уменьши `max_daily_trades` |
| Большой убыток | Увеличь `stop_loss_pct` или уменьши `position_size_usdt` |
| Workflow падает | Проверь логи: `docker logs n8n-bot \| grep ERROR` |
| Не видно пар в workflow | Импортируй `trading-bot-main.v5.1-multi-pair.json` |

---

## 📈 Рекомендуемые настройки для старта

| Пара | Размер позиции | SL | TP | Макс. сделок/день |
|------|---------------|----|----|-------------------|
| BTCUSDT | 50-100 USDT | 2% | 4% | 5 |
| ETHUSDT | 50-100 USDT | 2.5% | 5% | 5 |
| SOLUSDT | 25-50 USDT | 3% | 6% | 4 |
| BNBUSDT | 50-75 USDT | 2% | 4.5% | 4 |

**Совет:** Начни с 1-2 пар, протестируй неделю, затем добавляй остальные.

---

## 🔗 Полезные ссылки

- 📖 [Полная документация](MULTI_PAIR_CONFIG.md)
- 🐛 [Сообщить об ошибке](https://github.com/akoffice933-maker/trading-bot-project/issues)
- 💬 [Обсуждение](https://github.com/akoffice933-maker/trading-bot-project/discussions)
