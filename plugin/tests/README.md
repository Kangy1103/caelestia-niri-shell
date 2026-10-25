# Native regression tests

These tests compile the real Umbriel IPC client against a local test server.
They do not connect to the running compositor or require Quickshell. The
multimedia suite also needs Qt Quick, Multimedia, Concurrent and Sql.

```sh
cmake -S plugin/tests -B /tmp/cns-ipc-tests -DCMAKE_BUILD_TYPE=Debug -DCNS_TEST_SANITIZERS=ON
cmake --build /tmp/cns-ipc-tests
ASAN_OPTIONS=detect_leaks=0 ctest --test-dir /tmp/cns-ipc-tests --output-on-failure
```

Coverage: destruction while connected, normal reconnection after a peer closes,
and destruction while a reconnect is pending. The connected-destruction case
regresses the reload crash where the socket's destructor restarted a timer
whose C++ member lifetime had already ended.

Multimedia coverage: image fitting without stretching/upscaling, lossless
cache write/reopen, missing-source propagation, and repeated image/video source
changes with both item-before-source and source-before-item teardown. It uses
the offscreen platform and temporary directories. Leak detection is disabled
for the sanitizer run because Qt/platform libraries have process-lifetime
allocations; address and undefined-behaviour checks remain enabled.
