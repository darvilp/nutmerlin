# NUT `dummy-ups` starter scenarios

These are synthetic fixtures shaped around the confirmed CyberPower CP1500PFCLCD reference device. They are not an authoritative capture from the user's physical unit.

## Suggested use

Configure a source such as:

```ini
[simulated]
    driver = dummy-ups
    port = cyberpower-base.dev
    mode = dummy-once
    desc = "NUTMerlin simulated UPS"
```

The exact configuration directory and driver invocation depend on the selected NUT/Entware build.

For deterministic automated tests, start with `cyberpower-base.dev` and change listed variables through the supported `dummy-ups` control path.

For manual replay, select a `.seq` fixture in `dummy-loop` mode.

## Fixtures

- `cyberpower-base.dev` — stable online base variables.
- `short-outage.seq` — outage recovers before a typical shutdown delay.
- `long-outage.seq` — outage persists beyond the delay.
- `low-battery.seq` — progresses to low-battery.
- `power-flap.seq` — repeated short transitions.

Timers are intentionally short for development. Production timing is policy configuration, not fixture timing.
