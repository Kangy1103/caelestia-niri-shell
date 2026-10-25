# IPC lifecycle regression tests

These tests compile the real Umbriel IPC client against a local test server.
They do not connect to the running compositor or require Quickshell.

```sh
cmake -S plugin/tests -B /tmp/cns-ipc-tests -DCMAKE_BUILD_TYPE=Debug -DCNS_TEST_SANITIZERS=ON
cmake --build /tmp/cns-ipc-tests
ctest --test-dir /tmp/cns-ipc-tests --output-on-failure
```

Coverage: destruction while connected, normal reconnection after a peer closes,
and destruction while a reconnect is pending. The connected-destruction case
regresses the reload crash where the socket's destructor restarted a timer
whose C++ member lifetime had already ended.
