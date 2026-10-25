# Monitor power with external idle managers

CNS exposes compositor-independent monitor power IPC commands:

```sh
cns shell compositor powerOffMonitors
cns shell compositor powerOnMonitors
```

They use the active backend: Niri's `PowerOffMonitors`/`PowerOnMonitors` actions,
or Umbriel's `dpms-off`/`dpms-on`. An idle manager used with CNS can therefore
keep the same commands in both sessions. CNS must be running for its IPC calls.

For example, preserve the existing timeouts in Stasis and use:

```text
dpms:
  timeout 1800
  command "cns shell compositor powerOffMonitors"
  resume_command "cns shell compositor powerOnMonitors"
end
```

Reload Stasis after changing its configuration. `true` from the CNS call means
the native IPC client accepted the action; inspect compositor output power state
when verifying an actual power cycle.
