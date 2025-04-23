# Примеры использования CraftifyShared

## AuthManager (Keychain)

```swift
import CraftifyShared

let authManager: AuthManaging = AuthManager()

// Сохранить ключ
try await authManager.setAPIKey("sk-...yourkey...")

// Получить ключ
let key = try await authManager.getAPIKey()

// Маскировать ключ для логирования
let masked = authManager.maskedAPIKey(key)

// Удалить ключ
try await authManager.deleteAPIKey()
```

## LogManagerShared (NDJSON)

```swift
import CraftifyShared

let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dev.korchasa.Craftify")!
let logger: LogManagerShared = LogManagerSharedNDJSON(appGroupContainerURL: appGroupURL)

// Записать лог
logger.log(LogEntry(level: .info, module: "ShareExt", message: "Started", metadata: [:]))

// Получить все логи
let logs = logger.getLogs()

// Экспортировать логи в JSON
let exported = try logger.exportLogs()

// Очистить логи
logger.clearLogs()
```

## In-memory stub для тестов

```swift
import CraftifyShared

let authStub = AuthManagerStub()
try await authStub.setAPIKey("sk-testkey12345678")
let testKey = try await authStub.getAPIKey()

let logStub = LogManagerSharedInMemory()
logStub.log(LogEntry(level: .debug, module: "Test", message: "Test log", metadata: [:]))
let testLogs = logStub.getLogs()
```