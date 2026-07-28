# BCExamples

A collection of standalone code examples for Microsoft Dynamics 365 Business
Central (AL) development — mostly integration, tooling, and "how does this
actually behave" experiments, each self-contained in its own folder.

## Examples

- **[SecureEndpoints](SecureEndpoints)** — connecting to external endpoints
  with higher security requirements: AAD S2S, AAD auth-code, Facebook OAuth,
  certificate-signed requests, and whitelisted/proxy endpoints, behind
  pluggable `ITokenGetter`/`IEndpoint` interfaces, exercised via an
  `EndpointTester` page.
- **[CallApiWithUserPool](CallApiWithUserPool)** — a standalone C# console
  app that rotates a pool of S2S (server-to-server) Entra client credentials
  round-robin when hammering a BC API endpoint, to work around per-app-registration
  throttling.
- **[ScheduleJobsAsS2S](ScheduleJobsAsS2S)** — triggering BC job-queue entries
  via external S2S HTTP calls, load-balanced across a pool of Entra app
  registrations (least-loaded app picked via a query) instead of enqueuing
  directly.
- **[InsertLockTimeouts](InsertLockTimeouts)** — uses BC's Performance
  Toolkit (BCPT) to concurrently insert records and surface record-locking /
  timeout behavior under load.
- **[TriggerLogger](TriggerLogger)** — two AL apps (`Core` + `Extension`)
  subscribing to essentially every insert/modify/delete/rename event and
  global-trigger variant on a demo table, logging each firing — a reference
  for understanding BC's trigger/event firing order.
- **[StringFormulaCalculator](StringFormulaCalculator)** — a runtime
  string-expression parser/evaluator written in AL (infix → postfix via
  shunting-yard, backed by a `Stack` table), exercised through a
  `CalculatorTester` page.
- **[PreprocessingSymbolCleanup](PreprocessingSymbolCleanup)** — a
  PowerShell script that strips resolved `#if [not] FLAG ... #endif`
  preprocessor blocks from AL source once a feature flag is permanently
  on/off, collapsing to the surviving branch.

## Tooling

- **[.claude/skills/rdlc-render](.claude/skills/rdlc-render)** — a Claude
  Code skill for offline-rendering a BC/NAV RDLC report layout from a
  captured dataset and diffing it pixel-by-pixel against a previous render
  or BC's own reference PDF, without a BC server in the loop. See its
  [SKILL.md](.claude/skills/rdlc-render/SKILL.md).
- **[VSCode Settings](VSCode%20Settings)** — shared AL analyzer ruleset,
  spell-check dictionary, and the Companial CodeCop analyzer used across
  these projects.

## License

[MIT](LICENSE)
