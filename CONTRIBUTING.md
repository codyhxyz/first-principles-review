# Contributing

## Version bump checklist

When bumping the version, update **both** files manually — JSON has no shared-source mechanism:

- `.claude-plugin/plugin.json` — `version` field
- `.claude-plugin/marketplace.json` — `owner.name` / `owner.email` if author changes
