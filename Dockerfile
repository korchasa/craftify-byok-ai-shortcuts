FROM ghcr.io/wojciechmuraszko/xcodegen:2.38.0-xcode15.3 AS builder

# Установка Mint, SwiftLint, SwiftFormat
RUN brew install mint && \
    mint install realm/SwiftLint && \
    mint install nicklockwood/SwiftFormat/SwiftFormat

WORKDIR /app
COPY . .

# Генерация проекта
RUN xcodegen

# Проверка линтера и форматтера
RUN mint run swiftlint --strict
RUN mint run swiftformat . --lint

# Сборка и тесты
RUN xcodebuild -scheme CraftifyShared -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' build test

CMD ["/bin/bash"]