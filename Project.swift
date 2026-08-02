import ProjectDescription

/// Main Tuist project manifest for Craftify. Defines all targets, packages, settings, and schemes.
public let project = Project(
    name: "Craftify",
    organizationName: "dev.korchasa",
    packages: [
        .remote(url: "https://github.com/scinfu/SwiftSoup.git", requirement: .upToNextMajor(from: "2.4.3")),
        .remote(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", requirement: .upToNextMajor(from: "2.2.2")),
        .remote(url: "https://github.com/mattgallagher/CwlCatchException.git", requirement: .upToNextMajor(from: "2.2.1")),
        .remote(url: "https://github.com/nalexn/ViewInspector.git", requirement: .upToNextMajor(from: "0.9.0"))
    ],
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "78M3ZDR5UH",
            "SWIFT_VERSION": "5.9",
            "CODE_SIGN_STYLE": "Automatic",
            "ENABLE_BITCODE": "NO",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
            "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES",
            "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
            "MARKETING_VERSION": "2.0.0",
            "CURRENT_PROJECT_VERSION": "4",
            "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES"
        ],
        configurations: [
            .debug(name: "Debug", xcconfig: "Configs/Debug.xcconfig"),
            .release(name: "Release", xcconfig: "Configs/Release.xcconfig")
        ]
    ),
    targets: [
        .target(
            name: "MainApp",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "dev.korchasa.Craftify",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("Craftify"),
                "CFBundleIconName": .string("AppIcon"),
                "UILaunchStoryboardName": .string("LaunchScreen"),
                "UIRequiresFullScreen": .boolean(true),
                "UISupportedInterfaceOrientations": .array([
                    .string("UIInterfaceOrientationPortrait"),
                    .string("UIInterfaceOrientationLandscapeLeft"),
                    .string("UIInterfaceOrientationLandscapeRight")
                ]),
                "CFBundleShortVersionString": .string("$(MARKETING_VERSION)"),
                "CFBundleVersion": .string("$(CURRENT_PROJECT_VERSION)")
            ]),
            sources: [
                "src/Common/Sources/**",
                "src/MainApp/Sources/**",
                "src/MainApp/Resources/Generated/Strings.swift"
            ],
            resources: [
                "src/MainApp/Resources/en.lproj/**",
                "src/MainApp/Resources/ru.lproj/**",
                "src/MainApp/Resources/uk.lproj/**",
                "src/MainApp/Resources/es.lproj/**",
                "src/MainApp/Resources/pt.lproj/**",
                "src/MainApp/Resources/de.lproj/**",
                "src/MainApp/Resources/fr.lproj/**",
                "src/MainApp/Resources/it.lproj/**",
                "src/MainApp/Resources/bg.lproj/**",
                "src/MainApp/Resources/ja.lproj/**",
                "src/MainApp/Resources/zh-Hans.lproj/**",
                "src/MainApp/Resources/Assets.xcassets",
                "src/MainApp/Resources/AppIcon.icon"
            ],
            entitlements: "src/MainApp/Config/Craftify.entitlements",
            dependencies: [
                .package(product: "SwiftSoup"),
                .target(name: "ShareExtension")
            ],
            settings: .settings(base: [
                "CODE_SIGN_STYLE": "Manual",
                "PRODUCT_BUNDLE_IDENTIFIER": "dev.korchasa.Craftify",
                "APP_GROUPS": "group.dev.korchasa.Craftify",
                "KEYCHAIN_ACCESS_GROUPS": "78M3ZDR5UH.*",
                "PROVISIONING_PROFILE_SPECIFIER": "Craftify MainApp"
            ])
        ),
        .target(
            name: "MainAppUnitTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "dev.korchasa.CraftifyUnitTests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "src/Common/Sources/**",
                "src/MainApp/UnitTests/**",
                "src/MainApp/Sources/**",
                "src/MainApp/Resources/Generated/Strings.swift"
            ],
            dependencies: [
                .target(name: "MainApp"),
                .package(product: "CwlPreconditionTesting"),
                .package(product: "CwlCatchException"),
                .package(product: "ViewInspector"),
                .package(product: "SwiftSoup")
            ],
            settings: .settings(base: [
                "GENERATE_INFOPLIST_FILE": "YES",
                "ENABLE_TESTING_SEARCH_PATHS": "YES",
                "SDKROOT": "iphonesimulator",
                "OTHER_LDFLAGS": [
                    "-weak_framework",
                    "XCTest",
                    "-weak-lXCTestSwiftSupport"
                ]
            ])
        ),
        .target(
            name: "MainAppUITests",
            destinations: [.iPhone, .iPad],
            product: .uiTests,
            bundleId: "dev.korchasa.CraftifyUITests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "src/MainApp/UITests/**"
            ],
            dependencies: [
                .target(name: "MainApp")
            ],
            settings: .settings(base: [
                "GENERATE_INFOPLIST_FILE": "YES",
                "TEST_TARGET_NAME": "MainApp"
            ])
        ),
        .target(
            name: "ShareExtension",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "dev.korchasa.Craftify.ShareExtension",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("Craftify Share"),
                "CFBundleShortVersionString": .string("$(MARKETING_VERSION)"),
                "CFBundleVersion": .string("$(CURRENT_PROJECT_VERSION)"),
                "NSExtension": .dictionary([
                    "NSExtensionAttributes": .dictionary([
                        "NSExtensionActivationRule": .dictionary([
                            "NSExtensionActivationSupportsText": .boolean(true),
                            "NSExtensionActivationSupportsWebURLWithMaxCount": .integer(1),
                            "NSExtensionActivationSupportsURLWithMaxCount": .integer(1)
                        ])
                    ]),
                    "NSExtensionPointIdentifier": .string("com.apple.share-services"),
                    "NSExtensionPrincipalClass": .string("$(PRODUCT_MODULE_NAME).ShareExtensionViewController")
                ])
            ]),
            sources: [
                "src/Common/Sources/**",
                "src/ShareExtension/Sources/**",
                "src/ShareExtension/Resources/Generated/Strings.swift"
            ],
            resources: [
                "src/ShareExtension/Resources/en.lproj/**",
                "src/ShareExtension/Resources/ru.lproj/**",
                "src/ShareExtension/Resources/uk.lproj/**",
                "src/ShareExtension/Resources/es.lproj/**",
                "src/ShareExtension/Resources/pt.lproj/**",
                "src/ShareExtension/Resources/de.lproj/**",
                "src/ShareExtension/Resources/fr.lproj/**",
                "src/ShareExtension/Resources/it.lproj/**",
                "src/ShareExtension/Resources/bg.lproj/**",
                "src/ShareExtension/Resources/ja.lproj/**",
                "src/ShareExtension/Resources/zh-Hans.lproj/**",
                "src/ShareExtension/Resources/Assets.xcassets"
            ],
            entitlements: "src/ShareExtension/Config/ShareExtension.entitlements",
            dependencies: [
                .package(product: "SwiftSoup")
            ],
            settings: .settings(base: [
                "CODE_SIGN_STYLE": "Manual",
                "ENABLE_TESTING_SEARCH_PATHS": "NO",
                "APP_GROUPS": "group.dev.korchasa.Craftify",
                "KEYCHAIN_ACCESS_GROUPS": "78M3ZDR5UH.*",
                "PROVISIONING_PROFILE_SPECIFIER": "Craftify Share Extension"
            ])
        ),
        .target(
            name: "ShareExtensionUnitTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "dev.korchasa.Craftify.ShareExtensionUnitTests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "src/Common/Sources/**",
                "src/ShareExtension/UnitTests/**",
                "src/ShareExtension/Sources/**",
                "src/ShareExtension/Resources/Generated/Strings.swift"
            ],
            dependencies: [
                .package(product: "CwlPreconditionTesting"),
                .package(product: "CwlCatchException"),
                .package(product: "ViewInspector"),
                .package(product: "SwiftSoup")
            ],
            settings: .settings(base: [
                "GENERATE_INFOPLIST_FILE": "YES",
                "ENABLE_TESTING_SEARCH_PATHS": "YES",
                "SDKROOT": "iphonesimulator",
                "OTHER_LDFLAGS": [
                    "-weak_framework",
                    "XCTest",
                    "-weak-lXCTestSwiftSupport"
                ]
            ])
        ),
        .target(
            name: "CommonUnitTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "dev.korchasa.Craftify.CommonUnitTests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "src/Common/Sources/**",
                "src/Common/UnitTests/**",
                "src/MainApp/Resources/Generated/Strings.swift",
                "src/MainApp/Sources/ViewConstants.swift"
            ],
            dependencies: [
                .package(product: "CwlPreconditionTesting"),
                .package(product: "CwlCatchException"),
                .package(product: "SwiftSoup")
            ],
            settings: .settings(base: [
                "GENERATE_INFOPLIST_FILE": "YES",
                "ENABLE_TESTING_SEARCH_PATHS": "YES",
                "SDKROOT": "iphonesimulator",
                "OTHER_LDFLAGS": [
                    "-weak_framework",
                    "XCTest",
                    "-weak-lXCTestSwiftSupport"
                ]
            ])
        )
    ],
    schemes: [
        .scheme(
            name: "AllTests",
            shared: true,
            buildAction: .buildAction(targets: ["MainApp", "ShareExtension"]),
            testAction: .targets(["MainAppUnitTests", "ShareExtensionUnitTests", "CommonUnitTests"])
        ),
        .scheme(
            name: "MainApp",
            shared: true,
            buildAction: .buildAction(targets: ["MainApp", "ShareExtension"])
        ),
        .scheme(
            name: "UITests",
            shared: true,
            buildAction: .buildAction(targets: ["MainApp"]),
            testAction: .targets(["MainAppUITests"])
        ),
        .scheme(
            name: "ShareExtension",
            shared: true,
            buildAction: .buildAction(targets: ["ShareExtension"])
        )
    ]
)
