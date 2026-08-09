import XCTest

public final class AddOperationViewModelTests: XCTestCase {
    public func testSetOperationTypeUpdatesForm() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        XCTAssertEqual(vm.selectedKind, .translate)
        XCTAssertTrue(vm.isValid)
    }

    public func testSetParamsEnablesValidation() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        vm.targetLanguage = "ru"
        XCTAssertTrue(vm.isValid)
    }

    public func testValidationFailsOnEmptyLanguage() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        vm.targetLanguage = ""
        XCTAssertFalse(vm.isValid)
    }

    public func testSaveEmitsValidOperation() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .simplify
        XCTAssertTrue(vm.isValid)
        let op = vm.makeOperation()
        XCTAssertNotNil(op)
        XCTAssertEqual(op?.operation, .simplify)
    }

    public func testCancelResetsState() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .correct
        vm.cancel()
        XCTAssertNil(vm.selectedKind)
        XCTAssertFalse(vm.isValid)
    }

    public func testFieldsResetOnOperationTypeChange() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        vm.targetLanguage = "ru"
        vm.length = "9-10 sentences"
        // Смена типа
        vm.selectedKind = .simplify
        XCTAssertEqual(vm.targetLanguage, "")
        XCTAssertEqual(vm.length, "2-3 sentences")
        // Смена на translate снова
        vm.selectedKind = .translate
        XCTAssertFalse(vm.targetLanguage.isEmpty)
        XCTAssertEqual(vm.length, "2-3 sentences")
    }

    public func testDefaultSelectedKindIsNotNilAndFormIsValid() {
        let vm = AddOperationViewModel()
        XCTAssertNotNil(vm.selectedKind)
        XCTAssertTrue(vm.isValid)
    }

    /// Каждый тип обязан приходить со своими параметрами: новый тип с
    /// обязательным параметром иначе даст форму с выключенной кнопкой
    public func testEveryKindFillsItsParameters() {
        for kind in OperationFactory.allKinds {
            let vm = AddOperationViewModel(settings: Self.settings(nativeLanguage: "ru"))
            vm.selectedKind = kind
            XCTAssertTrue(vm.isValid, "форма для типа \(kind) осталась незаполненной")
        }
    }

    /// Язык перевода по умолчанию берётся из настроек, а не из начала списка,
    /// где стоит афарский
    public func testTranslateDefaultsToTheNativeLanguage() {
        let vm = AddOperationViewModel(settings: Self.settings(nativeLanguage: "ru"))
        vm.selectedKind = .translate
        XCTAssertEqual(vm.targetLanguage, "ru")
    }

    /// Незнакомый код языка не должен оставлять форму пустой
    public func testUnknownNativeLanguageFallsBackToTheList() {
        let vm = AddOperationViewModel(settings: Self.settings(nativeLanguage: "zzz"))
        vm.selectedKind = .translate
        XCTAssertEqual(vm.targetLanguage, vm.supportedLanguages.first?.code ?? "")
        XCTAssertTrue(vm.isValid)
    }

    /// Отдельное хранилище на каждый вызов, чтобы тесты не цеплялись за App Group
    private static func settings(nativeLanguage: String) -> AppSettingsManager {
        let suite = "test.craftify.add-operation.\(nativeLanguage)"
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        let settings = AppSettingsManager(suiteName: suite)
        settings.nativeLanguage = nativeLanguage
        return settings
    }

    deinit {}
}
