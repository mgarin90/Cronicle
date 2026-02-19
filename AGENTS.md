# AGENTS.md

Agent playbook for working in this Cronicle repository.

## Project Snapshot

- Runtime: Node.js (minimum v16, enforced in `lib/main.js`).
- Module system: CommonJS (`require`, `module.exports`).
- Server framework: `pixl-server` + PixlCore components/mixins.
- Frontend: legacy `pixl-webapp` + jQuery-style code in `htdocs/js`.
- Test runner: `pixl-unit`.
- Build tooling: custom Node scripts in `bin/` using `sample_conf/setup.json` build steps.

## Rule Sources Checked

- `.cursorrules`: not present.
- `.cursor/rules/`: not present.
- `.github/copilot-instructions.md`: not present.
- Result: no Cursor/Copilot-specific policy files to inherit.

## Repository Layout

- `lib/`: backend server, API layer, scheduler, queue, job logic.
- `lib/api/*.js`: API mixins mounted under `/api/app/*` namespace.
- `htdocs/`: web UI assets and page classes.
- `bin/`: operational scripts (build, debug, control, storage tools).
- `sample_conf/`: sample config + initial storage setup + build plan.
- `docs/`: canonical operational/development docs.

## Setup Commands

- Install dependencies: `npm install`
- Dev build (unbundled assets + `conf` symlink): `node bin/build.js dev`
- Dist build (bundled/minified assets + copied `conf`): `node bin/build.js dist`
- Install service boot hooks: `npm run boot`
- Remove service boot hooks: `npm run unboot`

## Run / Debug Commands

- Start daemonized service: `./bin/control.sh start`
- Stop service: `./bin/control.sh stop`
- Restart service: `./bin/control.sh restart`
- Status check: `./bin/control.sh status`
- Start in foreground debug mode: `./bin/debug.sh`
- Start debug and force master: `./bin/debug.sh --master`

## Test Commands

- Full test suite (default): `npm test`
- Equivalent direct runner: `npx pixl-unit lib/test.js`
- Verbose test output: `npx pixl-unit lib/test.js --verbose 1`
- Fail fast on first assertion: `npx pixl-unit lib/test.js --fatal 1`

## Running a Single Test (Important)

`pixl-unit` does not provide a built-in test name filter.
Use a temporary wrapper suite that filters `exports.tests` by function name.

1) Create `tmp/single-test.js` with this content:

```js
const suite = require('../lib/test.js');
const testName = process.env.TEST_NAME;
if (!testName) throw new Error('Set TEST_NAME');

suite.tests = suite.tests.filter(function(fn) {
	return fn.name === testName;
});

if (!suite.tests.length) {
	throw new Error('No test found named: ' + testName);
}

module.exports = suite;
```

2) Run one test:

`TEST_NAME=testAPIPing npx pixl-unit tmp/single-test.js --verbose 1`

3) Remove the temporary file after use.

Notes:
- Keep `--threads 1` (default), because this suite relies on shared state/order.
- Ensure no other Cronicle instance is running; test setup checks `logs/unit.pid`.

## Lint / Format Status

- No ESLint/Prettier/Biome config exists in this repo.
- No `npm run lint` or `npm run format` scripts are defined.
- Do not introduce a new formatter/linter unless explicitly requested.
- Match existing file style manually (tabs, semicolons, CommonJS patterns).

## Backend Code Style Conventions

- Use `var`, not `let`/`const`, unless the file already uses modern syntax.
- Keep `require` blocks near top; typical order is built-in, third-party, local.
- Export classes/modules via `module.exports = ...`.
- Prefer `Class.create({...})` and mixins in server components/API modules.
- Use tabs for indentation; preserve existing spacing/alignment style.
- Use semicolons consistently.
- Prefer single-quoted strings; keep existing quote style when editing nearby code.
- Use `var self = this;` when entering nested callbacks.
- Prefer callback-style async flow (`function(err, data)`) over Promises.
- Use early returns for guard clauses and failures.

## API Layer Conventions

- API method naming: `api_<name>` (e.g. `api_get_event`).
- Validate required params with `this.requireParams(...)`.
- Validate optional event-ish payloads with `this.requireValidEventData(...)`.
- Load auth context through `this.loadSession(args, cb)`.
- Enforce auth/permissions via `requireValidUser`, `requireAdmin`, `requirePrivilege`.
- Return structured errors through `this.doError(code, message, callback)`.
- Standard success payload starts with `{ code: 0, ... }`.
- For master-only APIs, call `this.requireMaster(args, callback)` first.

## Error Handling and Logging

- Follow error-first callback checks: `if (err) return ...`.
- Include useful context in error messages (`id`, `title`, operation).
- Use `this.logDebug(level, message, data)` for diagnostics.
- Use `this.logTransaction(...)` and `this.logActivity(...)` for audited mutations.
- Avoid throwing in request handlers unless handling truly fatal startup conditions.

## Data / Validation Patterns

- Keep external/API field names snake_case (e.g. `session_id`, `max_children`).
- IDs are typically alphanumeric/underscore (`/^\w+$/`) and often lowercase.
- Use `Tools.timeNow(true)` for epoch seconds where needed.
- Use `Tools.mergeHashes`, `Tools.copyHash`, `Tools.findObject` helpers.
- Keep timing/timezone validation behavior aligned with existing moment-timezone checks.

## Frontend Conventions

- Page classes use `Class.subclass( Page.Base, "Page.X", {...} )`.
- Keep jQuery-style DOM access (`$`, `.html()`, `.addClass()`, etc.).
- Existing UI often constructs HTML strings manually; follow local pattern.
- Use global helpers already present (`find_object`, `render_menu_options`, etc.).
- Preserve existing inline handler style when touching old UI code.

## Change Discipline for Agents

- Make minimal, targeted edits; avoid broad refactors unless requested.
- Do not modernize syntax wholesale (no repo-wide var->const conversion).
- Do not add new dependencies without clear need.
- Avoid changing operational scripts/paths unless task requires it.
- Update docs when behavior/commands change.

## Validation Before Finishing

- Run the narrowest relevant test(s) first, then broader suite if needed.
- For backend behavior changes, at least run `npm test` when feasible.
- For build/asset changes, run `node bin/build.js dev` (or `dist` if packaging-related).
- Include exact commands run and outcomes in your final handoff.
