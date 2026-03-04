# 🤝 Contributing to Trading Bot Project

Спасибо за интерес к проекту! Этот документ поможет вам внести вклад в развитие.

---

## 📋 Содержание

- [Как сообщить о баге](#-как-сообщить-о-баге)
- [Как предложить улучшение](#-как-предложить-улучшение)
- [Pull Request Guidelines](#-pull-request-guidelines)
- [Code Style](#-code-style)
- [Development Setup](#-development-setup)
- [Release Process](#-release-process)

---

## 🐛 Как сообщить о баге

### Перед созданием issue

1. ✅ Проверьте [существующие issues](https://github.com/akoffice933-maker/trading-bot-project/issues)
2. ✅ Проверьте [документацию](docs/)
3. ✅ Попробуйте `fix-trading-bot.sh` для автоматического исправления

### Шаблон issue

```markdown
### Описание проблемы
Краткое описание проблемы

### Воспроизведение
Шаги для воспроизведения:
1. ...
2. ...
3. ...

### Ожидаемое поведение
Что должно было произойти

### Скриншоты/Логи
```bash
# Приложите логи
docker compose logs n8n | tail -50
```

### Окружение
- OS: Ubuntu 22.04 / 24.04
- Docker: [версия]
- Version: v5.3.0

### Дополнительная информация
Любые другие детали
```

**Создать issue:** https://github.com/akoffice933-maker/trading-bot-project/issues/new

---

## ✨ Как предложить улучшение

### Формат предложения

```markdown
### Проблема
Какую проблему решает улучшение?

### Решение
Описание предлагаемого решения

### Альтернативы
Рассмотренные альтернативы

### Дополнительный контекст
Скриншоты, примеры кода, референсы
```

### Категории улучшений

| Категория | Примеры |
|-----------|---------|
| 🆕 Функции | Новые workflow, интеграции |
| 📈 Производительность | Оптимизация запросов, кэширование |
| 🔐 Безопасность | Новые меры защиты |
| 📖 Документация | Исправления, дополнения, переводы |
| 🧪 Тесты | CI/CD, автотесты |

---

## 🔄 Pull Request Guidelines

### Перед отправкой PR

```bash
# 1. Fork и clone
git clone https://github.com/YOUR_USERNAME/trading-bot-project.git

# 2. Создайте ветку
git checkout -b feature/your-feature-name

# 3. Внесите изменения
# ...

# 4. Проверьте изменения
git diff

# 5. Закоммитьте
git commit -m "feat: Add your feature

Detailed description of changes

Fixes #123"

# 6. Отправьте
git push origin feature/your-feature-name
```

### Требования к PR

- ✅ **Один PR = одна фича/исправление**
- ✅ **Следуйте code style** (см. ниже)
- ✅ **Обновите документацию** если нужно
- ✅ **Добавьте тесты** если применимо
- ✅ **Проверьте локально** перед отправкой

### Название PR

| Префикс | Описание | Пример |
|---------|----------|--------|
| `feat:` | Новая функция | `feat: Add multi-pair support` |
| `fix:` | Исправление | `fix: Fix SSL certificate renewal` |
| `docs:` | Документация | `docs: Add QUICKSTART guide` |
| `style:` | Форматирование | `style: Fix indentation` |
| `refactor:` | Рефакторинг | `refactor: Simplify backup logic` |
| `test:` | Тесты | `test: Add CI workflow tests` |
| `chore:` | Вспомогательное | `chore: Update dependencies` |

---

## 📝 Code Style

### Shell scripts

```bash
#!/bin/bash
# ✅ Используйте set -e для выхода при ошибке
set -e

# ✅ Именуйте переменные в UPPER_CASE
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/config.env"

# ✅ Проверяйте наличие зависимостей
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is required but not installed"
    exit 1
fi

# ✅ Используйте функции для повторяющейся логики
log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
}

# ✅ Обрабатывайте ошибки
cleanup() {
    rm -f /tmp/temp_file
}
trap cleanup EXIT
```

### JSON (workflow/configs)

```json
{
  "name": "Example Workflow",
  "nodes": [
    {
      "parameters": {},
      "id": "unique-id",
      "name": "Node Name",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4,
      "position": [250, 300]
    }
  ],
  "connections": {},
  "active": false,
  "settings": {
    "executionOrder": "v1"
  }
}
```

**Валидация:**
```bash
# Проверка JSON
python3 -m json.tool configs/pairs.json > /dev/null

# Проверка workflow
for file in workflows/*.json; do
  python3 -m json.tool "$file" > /dev/null || echo "Invalid: $file"
done
```

### Markdown (документация)

```markdown
# ✅ Заголовки с одним #
## ✅ Подзаголовки с ##

### ✅ Используйте таблицы

| Параметр | Значение |
|----------|----------|
| CPU | 2 ядра |

### ✅ Код в блоках

```bash
# Команды
docker compose ps
```

### ✅ Списки
- ✅ Пункты с дефисом
- ✅ Или с плюсом

### ✅ Ссылки
[Текст](URL)

### ✅ Изображения
![Описание](URL)
```

---

## 🛠️ Development Setup

### Локальная разработка

```bash
# 1. Fork репозитория
# https://github.com/akoffice933-maker/trading-bot-project/fork

# 2. Clone
git clone https://github.com/YOUR_USERNAME/trading-bot-project.git
cd trading-bot-project

# 3. Установите зависимости
sudo apt update
sudo apt install docker.io docker-compose

# 4. Запустите локально
docker compose up -d

# 5. Проверьте
docker compose ps
```

### Тестирование изменений

```bash
# Тест установки (в VM)
multipass launch --name test-ubuntu --memory 4G --disk 25G
multipass shell test-ubuntu

# Внутри VM
git clone <your-fork>
cd trading-bot-project
sudo ./install-trading-bot-v5.1.sh

# Проверка
docker compose ps
curl http://localhost:5678/healthz
```

---

## 📦 Release Process

### Версионирование

Проект следует [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └─ Совместимые исправления
  │     └─────── Новые функции (обратно совместимые)
  └───────────── Критические изменения (несовместимые)
```

### Подготовка релиза

```bash
# 1. Обновите CHANGELOG.md
# Добавьте секцию [VERSION] - DATE

# 2. Обновите версию в README
# # Trading Bot Enterprise v5.3.1

# 3. Закоммитьте изменения
git commit -m "chore: Prepare release v5.3.1"

# 4. Создайте тег
git tag -a v5.3.1 -m "Release v5.3.1 - Bug fixes and improvements"

# 5. Отправьте
git push origin main
git push origin v5.3.1
```

### GitHub Release

1. Перейдите: https://github.com/akoffice933-maker/trading-bot-project/releases/new
2. Выберите тег
3. Заполните описание (используйте CHANGELOG)
4. Нажмите **Publish Release**

---

## 📊 Метрики вклада

| Тип вклада | Примеры |
|------------|---------|
| 🥇 Gold | Новая функция, workflow, интеграция |
| 🥈 Silver | Исправление багов, оптимизация |
| 🥉 Bronze | Документация, тесты, переводы |

---

## 🎯 Идеи для вклада

### Для новичков

- [ ] Исправление опечаток в документации
- [ ] Перевод на другие языки
- [ ] Примеры workflow для популярных стратегий
- [ ] Скриншоты для QUICKSTART

### Для опытных

- [ ] CI/CD улучшения
- [ ] Новые интеграции (биржи, сервисы)
- [ ] Оптимизация производительности
- [ ] Grafana dashboard шаблоны
- [ ] Автотесты для install.sh

---

## 📞 Контакты

- **Issues:** https://github.com/akoffice933-maker/trading-bot-project/issues
- **Discussions:** https://github.com/akoffice933-maker/trading-bot-project/discussions
- **Email:** akoffice933maker@gmail.com

---

## 🙏 Благодарности

Спасибо всем контрибьюторам за вклад в развитие проекта! 🚀

---

<div align="center">

[⬆️ Вернуться к началу](#-contributing-to-trading-bot-project)

</div>
