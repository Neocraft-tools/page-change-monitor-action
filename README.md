# Page Change Monitor GitHub Action: website change detection and diff alerts

[![GitHub release](https://img.shields.io/github/v/release/Neocraft-tools/page-change-monitor-action)](https://github.com/Neocraft-tools/page-change-monitor-action/releases)
[![Apify Actor](https://img.shields.io/badge/Apify-page--change--monitor-blue)](https://apify.com/neocraft/page-change-monitor)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Watch any web page from a scheduled workflow: competitor pricing, terms of service, documentation, job pages, government notices. Each run compares the page with the previous run and returns **what changed** (text diff, extracted prices and numbers, optional before/after screenshots). Cookie banners, timestamps and other noise are filtered, and changes are re-checked before being reported.

This action is a thin, dependency-free wrapper (bash + curl + jq) around the Apify Actor
[neocraft/page-change-monitor](https://apify.com/neocraft/page-change-monitor). It starts a run in **your own Apify account**, waits for it, saves the results as JSON,
writes a readable job summary and exposes the key values as step outputs.

## Quick start

1. Create a free Apify account at <https://apify.com> and copy your API token (**Console → Settings → API & Integrations**).
2. In your GitHub repository: **Settings → Secrets and variables → Actions → New repository secret**, name `APIFY_TOKEN`.
3. Add a step to a workflow:

```yaml
    steps:
      - uses: Neocraft-tools/page-change-monitor-action@v1
        with:
          apify-token: ${{ secrets.APIFY_TOKEN }}
          urls: |
            https://competitor.example.com/pricing
            https://example.com/terms
          fail-on-change: true   # the failed run = GitHub e-mail alert
```

A complete workflow is in [`examples/daily-change-alert.yml`](examples/daily-change-alert.yml).

## Pricing (pay per event, billed by Apify to your account)

**$0.0005 per page check (HTTP)**, **$0.002 per page check with a browser** (JavaScript pages), **$0.01 per confirmed change**, plus **$0.001 per run start**. The first check of a page (baseline) and failed checks are free. Watching 5 pages once a day in HTTP mode costs about $0.11 per month (150 checks + 30 starts) plus $0.01 per real change.

Prices are those of the [Apify Store page](https://apify.com/neocraft/page-change-monitor) when this README was written; the Store page is the reference.
Platform usage is included in these prices. Apify's free plan includes a monthly credit that covers light use.
Every run is started with a hard spend cap (`max-total-charge-usd`): the Actor stops charging when the cap is reached.
This GitHub Action itself is free and open source; nothing is billed by Neocraft outside Apify.

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `apify-token` | yes |  | Your Apify API token (store it as a secret). Runs are billed to this Apify account. |
| `urls` | yes |  | Pages to watch, separated by commas or new lines. |
| `monitor-name` | no |  | Name of the monitor. The last snapshot of each page is stored under this name in your Apify account. Defaults to the repository name. |
| `selector` | no |  | Optional CSS selector: only watch this part of the page (e.g. '#pricing'). |
| `ignore-selectors` | no |  | Optional CSS selectors to ignore (comma or new-line separated), e.g. '.ads, #footer'. |
| `mode` | no | `auto` | Fetch mode: auto, http (cheapest) or browser (JavaScript pages). |
| `screenshots` | no | `false` | Store before/after screenshots of changed pages. |
| `fail-on-change` | no | `false` | Fail the step when at least one page changed (useful to get GitHub's failure e-mail as the alert). |
| `fail-on-error` | no | `false` | Fail the step when a page could not be checked. |
| `extra-input` | no |  | Optional JSON object merged into the Actor input (any field of neocraft/page-change-monitor). |
| `max-total-charge-usd` | no | `0.10` | Hard spend cap for the run in USD. |
| `timeout-secs` | no | `600` | Maximum run time of the Actor in seconds. |
| `output-file` | no | `page-changes.json` | Where to save the full JSON results (a Markdown diff is written next to it). |

## Outputs

| Name | Description |
|---|---|
| `changed` | true when at least one page changed since the previous run. |
| `changed-count` | Number of changed pages. |
| `error-count` | Number of pages that could not be checked. |
| `changes` | JSON array of changed pages (url, summary, extracted values, diff counts). |
| `diff-file` | Path of a Markdown file with the full diff of changed pages. |
| `results-file` | Path of the full JSON results. |
| `run-url` | Apify Console URL of the run. |

Every run also sets `run-id`, `run-status` and `item-count`.

## Notes

* The previous snapshot of each page is stored in **your** Apify account under `monitor-name` (default: the repository name). The first run only records a baseline (`status: baseline`, free).
* Outputs: `changed` (true/false), `changes` (JSON), `diff-file` (Markdown diff), and the full JSON results.
* Use `selector` to watch one block only (e.g. `#pricing`) and `ignore-selectors` to drop noisy parts.
* The step needs `curl` and `jq`, which are preinstalled on GitHub-hosted Ubuntu and macOS runners.
* Your token is only sent to `api.apify.com`. Keep it in a secret; never paste it in a workflow file.

## Related

* Apify Actor: [page-change-monitor](https://apify.com/neocraft/page-change-monitor) (also usable from the Apify Console, API, Python/Node clients, Make, Zapier, MCP/AI agents).
* More examples (Python, Node.js, curl, AI agents): [Neocraft-tools/apify-examples](https://github.com/Neocraft-tools/apify-examples).
* Other Neocraft actions: [website-audit-action](https://github.com/Neocraft-tools/website-audit-action), [website-screenshot-action](https://github.com/Neocraft-tools/website-screenshot-action), [company-profile-action](https://github.com/Neocraft-tools/company-profile-action), [hiring-tracker-action](https://github.com/Neocraft-tools/hiring-tracker-action).

## Self-test (maintainers)

[`examples/self-test.yml`](examples/self-test.yml) runs this action on cheap inputs (a few cents at most). To enable it,
copy it to `.github/workflows/self-test.yml`, add an `APIFY_TOKEN` secret, and start it from the **Actions** tab
(it only runs on `workflow_dispatch`).

## Support

Open an issue in this repository. Maintained by Xiaoli, an AI assistant, for Neocraft.

## License

[MIT](LICENSE)
