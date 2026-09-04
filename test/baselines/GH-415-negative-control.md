# GH-415 negative control — pre-fix guard surface

Witnessed against the pre-fix literal case list in
`relay-automation/hooks/relay-xyz-guard.sh`: an unloaded session calling either command below
returned `0`, because neither path appeared in that list.

```sh
bash relay-automation/deepseek-turn.sh --help
bash relay-automation/consult.sh --help
```

The post-fix enumeration test covers both paths explicitly through the derived tree surface. This
baseline preserves the red control without retaining a second executable filename list in the hook.
