# Market Empire

Русскоязычный мобильный экономический симулятор магазина на Godot 4.3.

## Запуск в Codespaces

Установите Godot 4.3 и соответствующие export templates. Затем:

```bash
git pull
godot --headless --path . --editor --import --quit
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python -m http.server 8000 --bind 0.0.0.0 --directory build/web
```

Откройте порт 8000. Для обновлений остановите сервер и повторите команды.

## Возможности

- 12 товаров, строительство прилавков и расширение магазина.
- Покупатели, продавцы, грузчики, уборщики и поставщики.
- Цены, зарплаты, аренда, репутация, реклама, достижения.
- 3D-сцена, камера, локальное сохранение и настройки звука/графики.

Проект находится в разработке. Android-экспорт и публикация пока не настроены.

## Игровые модели

Перед импортом Godot выполните `python scripts/install_assets.py`. Скрипт скачивает оригинальные GLB-модели Kenney Mini Market, Mini Characters и Food Kit (CC0). При отсутствии моделей игра использует встроенную графику. Архивы и лицензии сохраняются локально; исходный код не зависит от сетевого доступа во время игры.

Источники: https://kenney.nl/assets/mini-market · https://kenney.nl/assets/mini-characters · https://kenney.nl/assets/food-kit
