# OHNavigationKit

A tiny, pragmatic navigation layer for SwiftUI that:

- Uses **`NavigationStack`** on iOS 16+ and a **UIKit bridge** on iOS 13–15.
- Lets features **self‑register** their routes (no giant `@main` switchboard).
- Supports **programmatic** `push / pop / popToRoot / replaceStack`.
- Plays nicely with Swift Concurrency and `@MainActor`.

> On iOS 16+, screens are presented **over a root view** using `NavigationStack`. On iOS 13–15, SwiftUI screens are hosted in `UIHostingController` and pushed via `UINavigationController`.

---

## Requirements

- iOS **13** – iOS **26**
- Swift **5.4+** (Swift 6–ready; route registration is `@MainActor`)
- Xcode **15+**

---

## Installation (Swift Package Manager)

### Add via Xcode

1. **File ▸ Add Package Dependencies…**
2. Enter the package URL:
   ```text
   https://github.com/AriestaAgung/OHNavigationKit
   ```
3. Choose a version rule (tag/branch) and add it to your app target.

### Or add in `Package.swift` (for libraries/workspaces)

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/AriestaAgung/OHNavigationKit", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "OHNavigationKit", package: "OHNavigationKit")
            ]
        )
    ]
)
```

Then import where needed:

```swift
import OHNavigationKit
```

---

## Quick Start

### 1) Bootstrap the router once at the root

```swift
import SwiftUI
import OHNavigationKit

@main
struct MyApp: App {
  @StateObject private var router = OHRouter<AnyRoute>(builder: AnyRouteBuilder)

  var body: some Scene {
    WindowGroup {
      router.root { ContentView() }      // root view (not part of the path)
        .environmentObject(router)       // provide router to the tree
    }
  }
}
```

> Keep **one** navigation container at the root. Avoid nesting `NavigationStack`/`NavigationView` inside destinations.

### 2) Define a feature route that self‑registers

```swift
enum TopCoinRoute: Hashable, Codable, FeatureRoute {
  case newsList(symbol: String)

  // Runs once (Swift 6–safe): register a builder on the main actor
  @MainActor static func registerRoutes() {
    RouteRegistry.shared.registerMain(Self.self) { route in
      switch route {
      case .newsList(let symbol):
        var ctx = NewsContext(); ctx.selectedCoin = symbol
        let vm  = NewsViewModel(context: ctx)   // @MainActor view model is OK here
        return AnyView(NewsView(viewModel: vm))
      }
    }
  }
}
```

- Use `registerMain` for builders that create UI or `@MainActor` view models.
- Prefer `@StateObject` inside the destination view when the view **owns** its view model.

### 3) Push from anywhere in your SwiftUI view tree

```swift
struct ContentView: View {
  @EnvironmentObject private var router: OHRouter<AnyRoute>

  var body: some View {
    List {
      Button("Open BTC News") {
        // Auto‑registers TopCoinRoute then pushes
        router.push(TopCoinRoute.newsList(symbol: "BTC"))
      }
    }
  }
}
```

Common ops:
```swift
router.pop()
router.popToRoot()
router.replaceStack(with: [TopCoinRoute.newsList(symbol: "ETH")])
```

---

## Destination View Ownership Pattern

When the destination **creates** its view model, make the view **own** it with `@StateObject`:

```swift
struct NewsView: View {
  @StateObject private var vm: NewsViewModel

  init(viewModel: @autoclosure @escaping () -> NewsViewModel) {
    _vm = StateObject(wrappedValue: viewModel())
  }

  var body: some View {
    List(vm.articles) { article in
      Text(article.title)
    }
    .overlay {
      if vm.isLoading && vm.articles.isEmpty { ProgressView("Loading…") }
    }
    .task { await vm.requestNews() }
  }
}
```

> If you support iOS 13, you can swap `@StateObject` with a small compat wrapper (like `@StateObjectCompat`) using the same initializer pattern.

---

## iOS 13–15 (UIKit Bridge)

- OHNavigationKit hosts SwiftUI views in `UIHostingController` and pushes them on a `UINavigationController`.
- The router environment is injected into each hosted root so `@EnvironmentObject` works across pushes.
- APIs are the **same** as on iOS 16+: your code doesn’t need conditional branches.

---

## Best Practices

- Keep a **single** navigation container at the app root (`router.root { … }`).
- Use `@StateObject` for view models **owned by the view**; use `@ObservedObject` only when the owner is elsewhere.
- Keep UI work on the **main actor** (mark VMs `@MainActor` or publish via `await MainActor.run { … }`).

---

## Troubleshooting

**Blank screen with a back button**
- Ensure you call `router.push(YourFeatureRoute…)` (not `push(AnyRoute(...))`) so the feature auto‑registers *before* SwiftUI asks for the destination.
- Verify the router is injected once at the root via `.environmentObject(router)`.
- If the destination owns its VM, use `@StateObject` (not `@ObservedObject`).

**Back gesture not working or odd pops**
- Don’t nest navigation containers inside destinations. Keep one stack at the root.

---

## FAQ

**Can I decode routes (state restoration)?**  
Yes. Since `AnyRoute` is `Codable`, you can decode a saved path. Make sure the involved feature types are registered **before** decoding, or defer restoration until after registration.

**Can features register lazily?**  
Yes. The `FeatureRoute` push overload calls `ensureRegistered()` before pushing, so features can self‑register on first use.

---

## License

MIT.

---

## Credits

Built with ❤️ for teams that want small, testable navigation without wrestling the entire app through a single router.
