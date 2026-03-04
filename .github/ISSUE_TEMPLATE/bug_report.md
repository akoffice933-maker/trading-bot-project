---
name: 🐛 Bug Report
description: Сообщить об ошибке
title: "[BUG] "
labels: ["bug", "triage"]
assignees: []
---

## Описание проблемы

<!-- Краткое описание проблемы -->

## Воспроизведение

Шаги для воспроизведения:

1. ...
2. ...
3. ...

## Ожидаемое поведение

<!-- Что должно было произойти -->

## Логи и скриншоты

```bash
# Логи n8n
docker compose logs n8n | tail -50

# Логи traefik
docker compose logs traefik | tail -50
```

<!-- Приложите скриншоты если применимо -->

## Окружение

- **OS:** Ubuntu 22.04 / 24.04
- **Docker version:** [вывод `docker --version`]
- **Docker Compose version:** [вывод `docker compose version`]
- **Version проекта:** v5.3.0

## Дополнительная информация

<!-- Любые другие детали, которые могут помочь -->

## Чеклист

- [ ] Я проверил [существующие issues](https://github.com/akoffice933-maker/trading-bot-project/issues)
- [ ] Я проверил [документацию](https://github.com/akoffice933-maker/trading-bot-project/tree/main/docs)
- [ ] Я запустил `fix-trading-bot.sh` для попытки автоматического исправления
- [ ] Я предоставил достаточно информации для воспроизведения
