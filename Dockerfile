FROM ghcr.io/wojciechmuraszko/xcodegen:2.38.0-xcode15.3 AS builder

# Установка CLI-инструментов через Homebrew
RUN brew install xcodegen swiftlint swiftformat xcbeautify swiftgen

WORKDIR /app
COPY . .

# Генерация проекта
RUN xcodegen

# Проверка линтера и форматтера
RUN swiftlint --strict
RUN swiftformat . --lint

# Сборка и тесты
RUN xcodebuild -scheme CraftifyShared -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' build test

CMD ["/bin/bash"]