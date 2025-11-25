
# BLE Module — Issue & Task Tracker (AI-Agent-Friendly)

Target: Flutter Android app using `flutter_blue_plus` to connect to ESP32-C3 and send JSON over BLE.

Reviewed files:

- `ble.dart`
- `ble_manager.dart`
- `models/ble_device_info.dart`
- `models/ble_device_connection.dart`
- `models/ble_gatt_info.dart`
- `models/ble_json_connection.dart`


## Critical / Highest Priority

---

### [C1] Make JSON writes MTU-aware with chunking and newline-terminated messages

**Problem**

`BleJsonConnection.sendJsonString` currently writes the entire JSON payload as a single BLE write:

```dart
final bytes = utf8.encode(jsonString + '\n');
await characteristic.write(bytes, withoutResponse: false);
````

But BLE GATT payload for a single attribute write is limited by the negotiated ATT MTU. With the default MTU of 23 bytes, only 20 bytes are available for payload; larger payloads must be fragmented into multiple packets.([Punch Through][1])

We want a protocol where:

* JSON is UTF-8 encoded.
* Messages are terminated by a newline `\n`, where **newline marks the end of the logical JSON message**.
* If JSON is “too big” (e.g. ≥ ~512 bytes or simply > MTU payload), we **must split the buffer into multiple chunks**.
* The **final chunk** of the transmission must contain the terminating `\n`.

**Task**

Implement explicit chunking in `BleJsonConnection`:

* Introduce an internal method for sending a JSON message:

  ```dart
  Future<void> _sendJsonInternal(String json, {required int mtuPayload});
  ```

  where `mtuPayload` is an internal maximum chunk size (e.g. `mtu - 3` or a safe constant) that **must not exceed** the current ATT payload size.
* Algorithm requirements:

  * Build the message as `final msg = jsonString + '\n';`.
  * Encode once: `final bytes = utf8.encode(msg);`.
  * If `bytes.length <= mtuPayload`, send as a single write.
  * If `bytes.length > mtuPayload`, send in **multiple sequential writes**:

    * Split `bytes` into slices of at most `mtuPayload` bytes.
    * The **last slice** will naturally contain the `\n` (since you added it before splitting).
    * No extra framing bytes beyond the terminating newline.
* All JSON BLE writes in `BleJsonConnection` must go through this chunking method.
* Keep the MTU / payload value configurable:

  * Either computed from negotiated MTU (if accessible),
  * Or passed in from outside via constructor / config.
* Wrap any BLE write errors in a dedicated error type (e.g. `BleWriteError` from [H2]).

**Acceptance Criteria (AI-verifiable)**

* Static code inspection confirms:

  * There is a single internal helper responsible for splitting and sending JSON messages in chunks.
  * No call sites write `utf8.encode(jsonString + '\n')` directly to a BLE characteristic anymore; instead, they call the new helper.
* The helper:

  * Appends `'\n'` **before** splitting into chunks.
  * Uses a clearly defined `mtuPayload` (or `chunkSize`) to bound each chunk’s length.
* A unit test suite (or several tests) for `BleJsonConnection` exists and verifies:

  * For a short JSON whose encoded length + 1 (`\n`) ≤ `mtuPayload`, **exactly one chunk** is produced and sent.
  * For a long JSON (e.g. 512–600 bytes after encoding plus `\n`):

    * Multiple chunks are produced.
    * Each chunk length is ≤ `mtuPayload`.
    * The **final chunk ends with the newline byte** (`\n`), and earlier chunks do **not** require any newline.
  * For edge cases where JSON length is an exact multiple of `mtuPayload - 1`:

    * The algorithm still produces valid chunking with a final chunk that ends with `\n`.
* `flutter analyze` passes with no new issues.
* The project builds successfully after these changes (`flutter build` or equivalent CI step passes).

---

### [C2] Fix connection state mapping (connecting/disconnecting must not be treated as errors)

**Problem**

The mapping from `BluetoothConnectionState` to `BleConnectionState` currently treats `connecting` and `disconnecting` as `error`, and never emits `BleConnectionState.connecting`.

**Task**

* Extend `BleConnectionState` enum (if needed) to include `connecting` (and optionally `disconnecting`).
* Update the mapping logic in all places that convert `BluetoothConnectionState` → `BleConnectionState`:

  * `connected` → `BleConnectionState.connected`
  * `disconnected` → `BleConnectionState.disconnected`
  * `connecting` → `BleConnectionState.connecting`
  * `disconnecting` → an explicit transient value (e.g. `BleConnectionState.disconnecting`) or other documented mapping.
* Ensure `BleConnectionState.error` is only used for true error paths (exceptions, unexpected conditions).

**Acceptance Criteria (AI-verifiable)**

* Enum `BleConnectionState` contains values that cover all required phases (`connecting`, `connected`, `disconnected`, `error`; optionally `disconnecting`).
* All `switch`/`if` statements mapping from `BluetoothConnectionState`:

  * Explicitly handle `connecting` and `disconnecting`,
  * Do **not** map normal states to `error` via a `default` branch.
* At least one unit test:

  * Simulates each `BluetoothConnectionState` via a fake/adapter,
  * Asserts that the mapping returns expected `BleConnectionState` for each value.
* `flutter analyze` and project compilation succeed without new warnings/errors related to the mapping changes.

## High Priority

---

### [H1] Update `connect()` usage to match current FlutterBluePlus API and license requirements

**Problem**

`connect()` is currently called without the required `license` parameter and without explicitly configuring MTU or `autoConnect`, which may not compile or may behave unexpectedly on newer `flutter_blue_plus` versions.

**Task**

* Decide and document a minimal supported `flutter_blue_plus` version for this module.
* Update all `connect()` usages to:

  * Provide a valid `license` value.
  * Optionally set MTU (to align with [C1]’s chunking logic).
  * Explicitly set `autoConnect` to the desired behavior.
* Add comments or documentation referencing the chosen plugin version and license expectations.

**Acceptance Criteria (AI-verifiable)**

* `pubspec.yaml` specifies a `flutter_blue_plus` version (or version range) compatible with the updated `connect()` signature.
* Every call to `connect()`:

  * Passes a `license` parameter,
  * Doesn’t rely on deprecated/removed parameters.
* The project compiles with that `flutter_blue_plus` version in a clean environment.
* At least one test (with a fake/mocked adapter or wrapper) validates that:

  * The wrapper passes `license`, MTU and `autoConnect` into the underlying adapter as expected.
* `flutter analyze` and `flutter build` pass.

---

### [H2] Introduce a typed error model for BLE operations

**Problem**

The module currently uses generic `Exception` strings and leaks low-level exceptions, making structured error handling difficult.

**Task**

* Define a `BleError` hierarchy with subclasses like:

  * `BlePermissionError`
  * `BleUnsupportedError`
  * `BleDeviceNotFoundError`
  * `BleNotConnectedError`
  * `BleGattError`
  * `BleWriteError`
* Replace string-based `Exception` throws with appropriate `BleError` subclasses across:

  * Permission checks
  * Connect/disconnect
  * GATT discovery
  * JSON connection creation and writes
* Wrap lower-level plugin exceptions into `BleError` subclasses as needed.

**Acceptance Criteria (AI-verifiable)**

* Static code search shows:

  * BLE-related paths throw only `BleError` (or subclasses), not raw `Exception`/`String`.
* Tests simulate conditions like:

  * “device not found”,
  * “not connected”,
  * “permission denied”,
    and assert that the corresponding `BleError` subtype is thrown.
* `flutter analyze` passes with no unused error classes or related dead code.
* Project builds successfully with the new error model.

---

### [H3] Add pairing/bonding support and make it configurable

**Problem**

The code does not explicitly handle pairing/bonding flows, despite the possibility that some devices/characteristics require a bonded connection.

**Task**

* Introduce a configuration flag (e.g., `requireBonding`) in the public API for connection.
* Implement bonding flow (through the adapter) where supported:

  * After `connect`, and when `requireBonding == true`, initiate bonding.
  * Convert bonding failures into a `BleBondingError` (or similar).
* Keep the bonding logic inside an abstraction layer rather than directly in UI code.

**Acceptance Criteria (AI-verifiable)**

* The public connection API exposes an option to require bonding.
* Implementation shows:

  * A conditional bonding step that runs only when bonding is required.
  * A dedicated error type for bonding failures.
* Tests using a fake BLE adapter:

  * Simulate successful bonding and ensure no error is thrown.
  * Simulate bonding failure and assert that `BleBondingError` (or equivalent) is thrown.
* `flutter analyze` and project build pass.

---

### [H4] Make scanning idempotent and manage scanning lifecycle explicitly

**Problem**

`scan()` can be called when a scan is already running, `_scanSubscription` is unused, and scanning lifecycle is not explicitly managed.

**Task**

* Introduce an internal scanning state (`_isScanning` or adapter query).
* Ensure `scan()`:

  * Either no-ops when already scanning, **or**
  * Stops the previous scan before starting a new one (documented behavior).
* Either:

  * Use `_scanSubscription` to manage scan results and cancel it in `stopScan()`/`dispose()`, **or**
  * Remove `_scanSubscription` entirely if unused.
* Optionally expose a read-only `isScanning` flag/stream.

**Acceptance Criteria (AI-verifiable)**

* Codebase contains:

  * A single authoritative scanning state flag/property.
  * Proper use or removal of `_scanSubscription` (no unused fields).
* Tests with a fake adapter:

  * Call `scan()` multiple times in succession,
  * Verify the underlying adapter’s “start scan” method is invoked according to the chosen policy.
  * Verify `stopScan()` triggers the adapter’s “stop scan” and cancels any subscriptions.
* `flutter analyze` and project build pass without warnings about unused fields or unhandled futures.

---

### [H5] Allow connecting using persisted device IDs (no hard dependency on last scan)

**Problem**

`BleManager.connect` currently relies on `lastScanResults` and `connectedDevices` and cannot reconstruct a device solely from its ID for reconnect scenarios.

**Task**

* Extend connection logic to:

  * First try `lastScanResults` and `connectedDevices`.
  * Then create a BLE device instance from its ID (e.g., using a `fromId`-style API in the adapter) if not found.
* Document that `BleDeviceInfo.id` is the ID used for reconstruction.
* Ensure connection failure for this reconstructed device yields a structured `BleDeviceNotFoundError` (or similar).

**Acceptance Criteria (AI-verifiable)**

* Code contains a clear fallback path based on device ID.
* Tests with a fake adapter:

  * Simulate absence of the device in scan/connected lists but presence via `fromId`,
  * Assert that the adapter’s `fromId` (or equivalent) is called,
  * Assert that if the adapter reports “not found”, `BleDeviceNotFoundError` is thrown.
* `flutter analyze` and build pass with the new logic.

---

### [H6] Make connection lifecycle cleanup robust (avoid dangling controllers/subscriptions)

**Problem**

Connection cleanup hinges on receiving a `disconnected` state; if that event never arrives, controllers/subscriptions may leak. There’s no central per-connection dispose routine.

**Task**

* Introduce an internal structure that holds, per connection:

  * Public `BleDeviceConnection`,
  * Its state `StreamController`,
  * All relevant subscriptions (e.g., connection state).
* Implement `disposeConnection(deviceId)` that:

  * Cancels all subscriptions,
  * Closes the controller if not yet closed,
  * Removes the connection entry.
* Ensure `disconnect()` and connection-state listeners always call `disposeConnection` on both normal and error paths.
* In `BleManager.dispose()`, call `disposeConnection` for all active connections.

**Acceptance Criteria (AI-verifiable)**

* Codebase includes a `disposeConnection` (or similar) method.
* All disconnect/error paths that should release a connection:

  * Call `disposeConnection` (verified by static inspection).
* Tests:

  * Construct a fake connection record with mock subscriptions and controller,
  * Call `disposeConnection`,
  * Assert the record is removed, controller is closed, and mock subscriptions recorded a `cancel` call.
* `flutter analyze` and project build succeed without new warnings about unclosed streams/subscriptions (where detectable).

## Medium Priority

---

### [M1] Improve permission handling for different Android API levels and permanent denials

**Problem**

Permission handling does not distinguish between temporary vs. permanent denials and does not clearly express platform/version-specific behavior.

**Task**

* Enhance permission checks to:

  * Detect and mark `permanentlyDenied` (and similar non-recoverable states),
  * Convey this via `BlePermissionError` (e.g., `requiresSettings` flag).
* Optionally adjust which permissions are requested depending on Android API level.
* Ensure errors differentiate between “can be re-requested” and “must go to settings”.

**Acceptance Criteria (AI-verifiable)**

* Permission handling logic:

  * Branches explicitly on `PermissionStatus` values, including `permanentlyDenied`.
  * Uses `BlePermissionError` to carry recoverability info.
* Tests with mocked permission responses:

  * Simulate `denied`, `permanentlyDenied`, etc.,
  * Assert correct `BlePermissionError` type/flags are produced.
* `flutter analyze` and build pass with no new issues.

---

### [M2] Decouple `discoverGatt()` result from `createJsonConnection` hidden state

**Problem**

`createJsonConnection` relies on internal `servicesList` state populated by `discoverGatt()`, rather than using the explicit `BleGattInfo` it returns.

**Task**

* Decide on one of:

  * Enforce a documented precondition and throw a typed `BleGattNotDiscoveredError` if GATT isn’t discovered, **or**
  * Change `createJsonConnection` to accept `BleGattInfo` (or `GattServiceInfo`/`GattCharInfo`) as parameters and stop relying on `servicesList`.
* Update the implementation accordingly.
* Deprecate or remove any confusing entry points that hide this dependency.

**Acceptance Criteria (AI-verifiable)**

* Public API/Docs clearly explain:

  * Either that `discoverGatt` must be called before `createJsonConnection`,
  * Or that `createJsonConnection` takes explicit GATT info parameters.
* Internal usage of `device.servicesList`:

  * Is removed from `createJsonConnection`, or
  * Is limited to a well-documented internal helper.
* Tests:

  * Call `createJsonConnection` without prior discovery and assert `BleGattNotDiscoveredError` (if keeping precondition), **or**
  * Supply fake `BleGattInfo` and assert correct service/char resolution and error behavior.
* `flutter analyze` and build run successfully.

---

### [M3] Provide basic de-duplication and enrichment of scan results

**Problem**

`scanResults` emits one `BleDeviceInfo` per advertisement without de-duplication or `lastSeen` metadata, pushing extra work to the consumer.

**Task**

* Either:

  * Implement an internal registry (`Map<String, BleDeviceInfo>`) that:

    * Updates `rssi` and `lastSeen` on new advertisements,
    * Exposes a deduplicated `Stream<List<BleDeviceInfo>>`, **or**
  * Keep current low-level behavior but clearly document that it is per-advertisement and not deduplicated.
* Optionally extend `BleDeviceInfo` with `DateTime lastSeen` and/or `bool isConnected`.

**Acceptance Criteria (AI-verifiable)**

* If registry-based:

  * Registry structure and update logic exist.
  * A deduplicated stream/list interface is provided.
* If doc-only:

  * Public doc-comments explicitly say `scanResults` is per-advertisement and not deduplicated.
* Tests for registry-based approach:

  * Feed multiple advertisements for the same device ID,
  * Assert only a single device entry in the resulting list, with updated `rssi` and `lastSeen`.
* `flutter analyze` and build pass.

---

### [M4] Add basic unit tests around mapping & GATT discovery

**Problem**

Mapping and GATT discovery code currently has no explicit tests, risking regressions.

**Task**

* Add unit tests for:

  * `_mapToDeviceInfo` (name, RSSI, ID mapping),
  * GATT discovery (`discoverGatt`),
  * JSON characteristic selection (`createJsonConnection`).

**Acceptance Criteria (AI-verifiable)**

* Test files exist for:

  * Device info mapping,
  * GATT discovery,
  * JSON connection creation.
* Tests cover:

  * Empty vs non-empty device name handling,
  * Different characteristic property combinations (read/write/notify),
  * Missing/wrong service/characteristic UUIDs,
  * Non-writable characteristic scenarios.
* `flutter test` passes in CI.
* Coverage reports (if used) show non-trivial coverage of mapping & GATT logic.

## Low Priority (Nice to Have)

---

### [L1] Improve data class ergonomics (equality, copy, debug)

**Problem**

Data classes lack value-based equality and cloning helpers, complicating state management and testing.

**Task**

* Implement `==` and `hashCode` (or use `equatable`) for:

  * `BleDeviceInfo`
  * `GattCharInfo`
  * `GattServiceInfo`
  * `BleGattInfo`
* Optionally add `copyWith` methods for convenience.

**Acceptance Criteria (AI-verifiable)**

* Static code inspection confirms:

  * Each class overrides `==`/`hashCode` or uses a value-based helper library.
* Tests:

  * Assert equal instances compare equal and have the same hash code.
  * Assert unequal instances compare not equal.
* `flutter analyze` and build succeed; no unused `copyWith` methods remain.

---

### [L2] Clarify newline-terminated JSON protocol in docs

**Problem**

The use of newline as a frame delimiter for JSON is a hidden protocol detail at the moment.

**Task**

* Add doc-comments and a small documentation section describing:

  * JSON is sent as UTF-8,
  * Messages are terminated by a single newline `\n`,
  * Receiver is expected to parse by newline.

**Acceptance Criteria (AI-verifiable)**

* `BleJsonConnection` (and any related public APIs) includes doc-comments mentioning:

  * UTF-8 encoding,
  * newline termination.
* Repository docs (README/USAGE) contain a short section describing this protocol.
* Any markdown lint / analyze checks continue to pass.

---

### [L3] Optional: abstract `FlutterBluePlus` behind an interface for easier testing / future swap

**Problem**

`BleManager` depends directly on `FlutterBluePlus` static API, making testing and future replacements harder.

**Task**

* Define a `BleAdapter` interface (or similar) encapsulating BLE operations.
* Implement a concrete adapter that wraps `FlutterBluePlus`.
* Inject the adapter into `BleManager` instead of calling `FlutterBluePlus` statics directly.

**Acceptance Criteria (AI-verifiable)**

* Codebase contains:

  * A `BleAdapter` interface (or similar),
  * A `FlutterBluePlus` implementation of that interface.
* `BleManager` no longer imports/uses `FlutterBluePlus` statically.
* Tests:

  * Use a fake adapter to drive `BleManager` and assert correct behavior when adapter returns specific values/errors.
* `flutter analyze` and project build pass without circular dependencies or unused adapter implementations.

---

### [L4] Improve inline documentation and usage examples

**Problem**

Public APIs lack concise usage examples and explicit description of the intended call order.

**Task**

* Add a small usage guide (e.g. `USAGE.md` or README section) that shows:

  * Permissions → scan → pick device → connect → discover GATT → create JSON connection → send JSON.
* Add doc-comments on key public APIs documenting expected order and responsibilities.

**Acceptance Criteria (AI-verifiable)**

* Repo contains a markdown file or README section explaining:

  * The canonical flow to scan and connect to a BLE device and send JSON messages.
* Public methods of `BleManager`/`BleJsonConnection` have doc-comments that:

  * Describe parameters and preconditions (e.g., whether GATT discovery is required).
* Any documentation tooling / lint plus `flutter analyze` and build all pass successfully.

```

::contentReference[oaicite:1]{index=1}
```

[1]: https://punchthrough.com/maximizing-ble-throughput-part-2-use-larger-att-mtu/?utm_source=chatgpt.com "Maximizing BLE Throughput Part 2: Use Larger ATT MTU"
