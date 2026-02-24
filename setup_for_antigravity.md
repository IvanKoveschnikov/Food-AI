# Настройка окружения для Antigravity

Ниже приведен список всех установленных расширений, зависимостей и навыков, необходимых для разработки проекта `food_AI`.

## 1. VS Code Extensions (Плагины IDE)
Скопируйте этот список и установите расширения в VS Code / Trae:

```bash
code --install-extension dart-code.flutter
code --install-extension dart-code.dart-code
code --install-extension felixangelov.bloc
code --install-extension nash.awesome-flutter-snippets
code --install-extension alexisvt.flutter-snippets
code --install-extension circlecodesolution.ccs-flutter-color
code --install-extension usernamehw.errorlens
code --install-extension eamodio.gitlens
code --install-extension donjayamanne.githistory
code --install-extension gruntfuggly.todo-tree
code --install-extension pkief.material-icon-theme
code --install-extension ms-ceintl.vscode-language-pack-ru
code --install-extension ms-vscode.powershell
code --install-extension jeroen-meijer.pubspec-assist
code --install-extension aaron-bond.better-comments
code --install-extension bracketpaircolordlw.bracket-pair-color-dlw
code --install-extension matthiesen-technology.yaml-with-script
```

## 2. Project Dependencies (Flutter/Dart)
Эти пакеты используются в проекте (см. `pubspec.yaml`).
Для установки выполните: `flutter pub get`

**Core:**
- `flutter`: SDK
- `go_router`: ^14.6.2 (Навигация)
- `flutter_riverpod`: ^2.6.1 (State Management)
- `intl`: ^0.20.2 (Локализация/Форматирование)

**Backend & Data:**
- `supabase_flutter`: ^2.8.0 (База данных, Auth, Realtime)
- `http`: ^1.2.2 (Сетевые запросы)

**UI & Assets:**
- `cupertino_icons`: ^1.0.8
- `image_picker`: ^1.1.2 (Выбор фото)
- `table_calendar`: ^3.1.2 (Календарь)
- `flutter_native_splash`: ^2.4.7 (Splash Screen)
- `flutter_launcher_icons`: ^0.14.4 (Иконки запуска)

## 3. MCP & Skills (Инструменты ИИ)
Активные навыки и контекстные инструменты, используемые в сессии:

**Skills:**
- `Agent Prompt Chain Designer`: Проектирование цепочек промптов
- `skill-creator`: Создание новых навыков

**Integrations:**
- **Supabase Integration**: Подключен аккаунт Supabase (через Trae profile) для прямого доступа к БД, таблицам и логам.
- **Terminal Access**: PowerShell 7+

## 4. Environment Setup (Настройки среды)
**Flutter SDK:** 3.10.1+
**Android SDK:** API 34+ (Рекомендуется API 34/35 для стабильности эмулятора)
**Emulator:** Pixel 7 Pro (Android 16 Preview / Android 14 Stable)

**Supabase Config:**
- Проект настроен на работу с таблицами: `saved_dishes`, `products`, `dish_products`, `dish_templates`.
- Realtime включен для таблицы `saved_dishes`.

## 5. Рекомендации по AI Модели
Для разработки (Flutter + Supabase) рекомендуется использовать **Gemini-3-Pro-Preview** или **Claude 3.5 Sonnet** (через Trae/Cursor), так как они лучше всего понимают контекст Dart/Flutter и SQL-схемы Supabase.
