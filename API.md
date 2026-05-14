# API

Server-side extension surface for compatibility patches.

Current additive surface version: `1.5.0`

## Load expectations

- register against the live `EnemyAmbush` namespace after the mod has loaded
- this is a server-side Script Extender Lua surface; do not call it from the client bootstrap path
- do not rely on any legacy pre-bootstrap queue path in `1.0`
- both `EnemyAmbush.*` and `EnemyAmbush.API.*` are supported for the documented public calls below
- `EnemyAmbush.API_VERSION` and `EnemyAmbush.API.API_VERSION` should both report `1.5.0`

## Early tester API smoke target

For API-focused beta testing, exercise only the documented stable surface:

- confirm `EnemyAmbush.API_VERSION == "1.5.0"` and `EnemyAmbush.API.API_VERSION == "1.5.0"`
- register, query, list, and unregister one enemy provider
- register, query, list, and unregister one champion provider
- call `GetAmbushState()` in a normal loaded save
- call `SetReputation()`, `GetReputation()`, and `ModifyReputation()` on a test key
- trigger one `custom_entries` one-shot ambush with `TriggerCustomAmbush(...)` in an eligible non-camp, non-combat, non-blocked area

Do not treat these as supported in this release:

- client-side API calls
- legacy pre-bootstrap queue registration
- trigger-time `pool_roll`
- non-default trigger-time `hostilityMode` or `rewardMode`
- direct reads/writes of private tables such as `EnemyAmbush._providers`, pending-state tables, or authored-service internals

## Return conventions

- registration helpers return `true` on success
- registration helpers return `false, "reason"` on invalid input or missing providers during unregister
- event `On` / `Once` return the registered callback or wrapper on success
- event `Off` returns the number of removed listeners
- query helpers return defensive copies; mutating the returned table does not update live provider state

## Events

### `EnemyAmbush.On(eventName, fn)`

Registers a listener.

### `EnemyAmbush.Once(eventName, fn)`

Registers a one-shot listener that removes itself after the first emit.

### `EnemyAmbush.Off(eventName, fn)`

Removes matching listeners for `eventName`.

### `EnemyAmbush.Emit(eventName, ...)`

Emits an event to current listeners and returns the listener count invoked.

Current public event names:

- `EnemyProvidersChanged`
- `ChampionProvidersChanged`
- `ReputationChanged`
- `XPCloneMappingsChanged`

## Enemy provider lifecycle

### `EnemyAmbush.RegisterEnemyProvider(id, entries, opts)`

Registers or replaces a provider that contributes ambush enemy entries.

Required:

- `id`: non-empty string
- `entries`: table of entry tables

Common `opts`:

- `priority`
- `enabledVar`
- `enabledDefault`
- `enabledFn`
- `requiresAllUUID`
- `requiresAnyUUID`

Registration copies the provider payload. Mutating your original `entries` or `opts` table after registration does not mutate the live runtime copy.

### XP-clone compatibility for provider templates

Provider templates are fully supported when `Ambush XP = 100%`.

When `Ambush XP < 100%`, Hunted uses generated zero-XP clone templates for native XP suppression plus manual payout. In that mode, the active pool currently requires XP-clone coverage for every spawnable template:

- built-in rows with generated clone coverage remain eligible
- external provider rows whose `template` is not present in Hunted's generated XP-clone map are skipped from the active pool
- external champion templates without generated XP-clone coverage are skipped by the champion spawn path

Current practical guidance for provider authors:

- if your compatibility patch adds new templates, tell users to keep `Ambush XP = 100%` unless Hunted has generated XP-zero clone coverage for those templates
- include `powerClass` anyway; it is still used for manual payout category selection if clone coverage is added later
- use `RegisterXPCloneMapping(...)` if your patch ships its own zero-XP clone templates

This is a deliberate safety behavior. Without clone coverage, sub-100% ambush XP could double-pay: normal kill XP from the spawned template plus Hunted's manual payout.

### `EnemyAmbush.RegisterXPCloneMapping(providerId, mapping)`

Registers one external original-template to zero-XP clone-template mapping.

Returns:

- `true` on success
- `false, "reason"` on invalid input or if another mapping already owns the original template

Required:

- `providerId`: non-empty string
- `mapping.originalTemplate` or `mapping.template`
- `mapping.cloneTemplate` or `mapping.xpCloneTemplate`

Optional metadata:

- `originalStat`
- `cloneStat`
- `originalRewardGuid`
- `rewardLevels`

Notes:

- the provider patch must ship the clone root template/stat in its own package
- this API only wires Hunted's runtime lookup and selection contract
- registering a mapping invalidates enemy/champion provider cache revisions
- mappings cannot override built-in generated Hunted clone coverage or another provider's mapping

Example:

```lua
local ok, err = EnemyAmbush.RegisterXPCloneMapping("my_pack", {
    originalTemplate = "01234567-89ab-cdef-0123-456789abcdef",
    cloneTemplate = "fedcba98-7654-3210-fedc-ba9876543210",
    originalStat = "MYMOD_OriginalEnemy",
    cloneStat = "MYMOD_EA_XP0_OriginalEnemy",
})

if not ok then
    print("[MyPatch] XP clone mapping failed:", err)
end
```

### `EnemyAmbush.UnregisterXPCloneMappings(providerId)`

Removes API-owned XP-clone mappings registered by one provider id.

Returns:

- `true, removedCount` on success
- `false, "reason"` on invalid input or if no mappings are found for that provider

### `EnemyAmbush.RegisterEnemyTemplate(providerId, entry)`

Adds one enemy entry to an existing provider. If the provider does not exist yet, it is auto-created with default `opts`.

### `EnemyAmbush.UnregisterEnemyProvider(id)`

Removes a provider and bumps the provider revision.

### `EnemyAmbush.HasEnemyProvider(id)`

Returns `true` if the provider exists.

### `EnemyAmbush.IsEnemyProviderActive(id)`

Returns `true` if the provider exists and passes its current activation gates.

### `EnemyAmbush.GetEnemyProvider(id)`

Returns a defensive copy of one provider record:

- `id`
- `entries`
- `opts`
- `priority`
- `active`
- `entryCount`

### `EnemyAmbush.ListEnemyProviders()`

Returns defensive copies of all registered enemy providers in stable registration order. Each record includes:

- `id`
- `entries`
- `opts`
- `priority`
- `active`
- `entryCount`
- `orderIndex`

### `EnemyAmbush.GetActiveEnemyEntries()`

Returns the merged active enemy-entry snapshot used by the runtime after activation-gate filtering and provider-priority sorting.

## Champion provider lifecycle

### `EnemyAmbush.RegisterChampionProvider(id, championsByType, opts)`

Registers or replaces champion templates grouped by `creatureType`.

### `EnemyAmbush.RegisterChampionTemplate(providerId, creatureType, championData)`

Adds or overrides one champion template entry for `creatureType`. If the provider does not exist yet, it is auto-created with default `opts`.

### `EnemyAmbush.UnregisterChampionProvider(id)`

Removes a champion provider and bumps the champion-provider revision.

### `EnemyAmbush.HasChampionProvider(id)`

Returns `true` if the champion provider exists.

### `EnemyAmbush.IsChampionProviderActive(id)`

Returns `true` if the champion provider exists and passes its current activation gates.

### `EnemyAmbush.GetChampionProvider(id)`

Returns a defensive copy of one champion provider record:

- `id`
- `championsByType`
- `opts`
- `priority`
- `active`
- `championCount`
- `creatureTypes`

### `EnemyAmbush.ListChampionProviders()`

Returns defensive copies of all registered champion providers in stable registration order. Each record includes:

- `id`
- `championsByType`
- `opts`
- `priority`
- `active`
- `championCount`
- `creatureTypes`
- `orderIndex`

### `EnemyAmbush.GetChampionTemplate(creatureType)`

Returns a defensive copy of the selected champion template for `creatureType`. Selection still uses the current runtime rule:

- highest provider priority wins the candidate set
- weighted random resolves inside that highest-priority set

## Runtime helpers

- `EnemyAmbush.InvalidateEnemyProviderCache(reason)`
- `EnemyAmbush.TriggerAmbush(character, isLongRest)`
- `EnemyAmbush.GetReputation(creatureType)`
- `EnemyAmbush.SetReputation(creatureType, value)`
- `EnemyAmbush.ModifyReputation(creatureType, delta)`

## Authored / custom ambush definitions (`D2-1` / `D2-2` / `D2-3`)

The current `D2` surface exposes the narrow public registry/query path plus the first safe trigger slice for authored/custom ambush definitions.

Implemented now:

- `EnemyAmbush.RegisterAmbushDefinition(id, definition)`
- `EnemyAmbush.UnregisterAmbushDefinition(id)`
- `EnemyAmbush.GetAmbushDefinition(id)`
- `EnemyAmbush.GetAmbushState()`
- `EnemyAmbush.TriggerAmbushDefinition(id, ctx)`
- `EnemyAmbush.TriggerCustomAmbush(payload)`

The new calls are available on both:

- `EnemyAmbush.*`
- `EnemyAmbush.API.*`

### `EnemyAmbush.RegisterAmbushDefinition(id, definition)`

Registers or replaces one public authored/custom ambush definition in the D2 registry.

Returns:

- `true` on success
- `false, "reason"` on invalid input or rejected ids

Current D2 behavior notes:

- ids must be non-empty strings
- ids that collide with shipped internal authored definitions are rejected
- registration stores a defensive copy of the validated public definition payload
- registration does **not** guarantee that every valid registered definition is triggerable in `D2-2`; the first trigger slice is intentionally narrower than the full v1 contract target

Supported `triggerKinds` in the registered public definition shape:

- `external`
- `rest`
- `region_entry`

Supported `spawn.mode` values:

- `pool_roll`
- `custom_entries`

Current public validation rejects:

- empty ids
- unknown `triggerKinds`
- unknown `spawn.mode`
- malformed `entries`
- malformed region keys
- invalid policy enum values

Current trigger-time entry fields used by the public `custom_entries` bridge:

- `template`
- `count`
- `displayName`
- `level`
- `creatureType`

Registered public definitions may preserve additional copied data in their stored definition snapshot, but extra per-entry fields are not part of the stable trigger-time contract. One-shot `TriggerCustomAmbush(...)` payloads are stricter and reject unsupported extra fields.

### `EnemyAmbush.UnregisterAmbushDefinition(id)`

Removes one public authored/custom ambush definition from the D2 registry.

Returns:

- `true` on success
- `false, "reason"` when the id is invalid or not found

### `EnemyAmbush.GetAmbushDefinition(id)`

Returns a defensive copy of one public authored/custom ambush definition snapshot, or `nil` if not found.

Returned fields:

- `id`
- `definition`
- `registered`
- `enabled`
- `once`
- `triggerCount`
- `lastTriggeredAtMs`
- `completed`

`D2` note:

- this getter currently addresses definitions registered through the public D2 registry
- it does not expose internal service tables or mutable runtime bags

### `EnemyAmbush.TriggerAmbushDefinition(id, ctx)`

Requests one trigger of a previously registered public ambush definition.

Returns:

- `true, resultTable` on accepted trigger success
- `false, "reason"` on invalid input, blocked context, or unsupported runtime shape

`ctx` fields currently used in `D2-2`:

- `character` required
- `flowLabel` optional
- `force` accepted but does not currently widen/bypass trigger gating
- `source` optional

Current `D2-2` behavior notes:

- the definition must exist in the public D2 registry
- the definition must include `triggerKinds = { "external", ... }`
- trigger validation currently blocks:
  - missing/empty ids
  - missing/invalid `ctx`
  - missing `character`
  - disabled definitions
  - `once=true` definitions already marked completed
  - blocked region/camp/safe-zone/combat context
- the first `D2-2` runtime bridge currently supports only:
  - `spawn.mode = "custom_entries"`
  - `policies.hostilityMode = "default"`
  - `policies.rewardMode = "default"`
  - `policies.reputationMode = "default"` or `none`
- public definitions using currently unsupported trigger-time runtime shapes return `false, "reason"` instead of exposing unstable internals
- registered `pool_roll` definitions can still be registered/query/unregistered in `D2-2`, but `TriggerAmbushDefinition(...)` currently returns `false, "unsupported spawn.mode"` for them

Minimum stable success result shape:

- `accepted = true`
- `requestId`
- `definitionId`
- `flowLabel` or `nil`
- `source`
- `queued`
- `triggerKinds`

Currently returned when naturally available:

- `character`

Minimal registered-definition smoke example:

```lua
local host = Osi.GetHostCharacter()

local ok, err = EnemyAmbush.RegisterAmbushDefinition("api_smoke:rat_external", {
    triggerKinds = { "external" },
    spawn = {
        mode = "custom_entries",
        entries = {
            {
                template = "c1ccd3e4-2864-469e-92d3-6b1d8d019fec",
                count = 1,
                displayName = "API Smoke Rat",
                level = 1,
                creatureType = "Beast",
            },
        },
    },
    policies = {
        hostilityMode = "default",
        rewardMode = "default",
        reputationMode = "none",
    },
})

if not ok then
    print("[MyPatch] RegisterAmbushDefinition failed:", err)
else
    local triggered, resultOrReason = EnemyAmbush.TriggerAmbushDefinition("api_smoke:rat_external", {
        character = host,
        source = "api_smoke",
        flowLabel = "API smoke registered",
    })
    print("[MyPatch] TriggerAmbushDefinition:", triggered, resultOrReason and resultOrReason.requestId or resultOrReason)
end
```

### `EnemyAmbush.TriggerCustomAmbush(payload)`

Requests one one-shot custom ambush without permanent registration.

Returns:

- `true, resultTable` on accepted trigger success
- `false, "reason"` on invalid input, blocked context, or unsupported runtime shape

Current `D2-3` behavior notes:

- the payload must be a table
- `character` is required
- `flowLabel` is optional
- `source` is optional
- the current one-shot path treats the payload as an external non-persistent trigger and does not create a registered public definition
- the current `D2-3` runtime bridge supports only:
  - `spawn.mode = "custom_entries"`
  - `policies.hostilityMode = "default"`
  - `policies.rewardMode = "default"`
  - `policies.reputationMode = "default"` or `none`
- if `triggerKinds` is provided, it must currently resolve to only `external`
- for `custom_entries`, the public one-shot entry shape is intentionally narrow:
  - `template` required
  - `count` optional
  - `displayName` optional
  - `level` optional
  - `creatureType` optional
- internal-only or unsupported extra entry fields such as `powerClass`, `resolvedTemplateLevel`, `minPartyLevel`, or `maxPartyLevel` are rejected instead of being silently treated as public contract
- the one-shot path does not increment `registeredDefinitionCount`
- the one-shot path returns `definitionId = nil` on success by contract

Minimum stable success result shape:

- `accepted = true`
- `requestId`
- `definitionId = nil`
- `flowLabel` or `nil`
- `source`
- `queued`
- `triggerKinds`

Currently returned when naturally available:

- `character`

Minimal one-shot smoke example:

```lua
local host = Osi.GetHostCharacter()

local ok, resultOrReason = EnemyAmbush.TriggerCustomAmbush({
    character = host,
    source = "api_smoke",
    flowLabel = "API smoke one-shot",
    spawn = {
        mode = "custom_entries",
        entries = {
            {
                template = "c1ccd3e4-2864-469e-92d3-6b1d8d019fec",
                count = 1,
                displayName = "API Smoke Rat",
                level = 1,
                creatureType = "Beast",
            },
        },
    },
    policies = {
        hostilityMode = "default",
        rewardMode = "default",
        reputationMode = "none",
    },
})

print("[MyPatch] TriggerCustomAmbush:", ok, ok and resultOrReason.requestId or resultOrReason)
```

Run this in a normal loaded save while the host character is in an eligible non-camp, non-combat, non-blocked area. Blocked context returns `false, "reason"` by design.

### `EnemyAmbush.GetAmbushState()`

Returns a read-only authored/runtime summary for UI/interop/debug use.

Returned fields:

- `activeRegion`
- `blockedSafeZone`
- `inCamp`
- `inCombat`
- `cooldownActive`
- `cooldownRemainingMs`
- `pendingAmbushCount`
- `registeredDefinitionCount`
- `timeInDangerMinutes`
- `timeInDangerRiskPct`

`D2` note:

- `registeredDefinitionCount` currently reports the size of the public D2 authored-definition registry
- this helper does not expose raw internal service tables, pending records, or mutable state bags

## Enemy entry shape

At minimum, an enemy entry needs:

- `template`

Recommended fields based on the shipped data:

- `name`
- `creatureType`
- `level`
- `weight`
- `status`
- `powerClass`
- `resolvedTemplateLevel`
- `minPartyLevel`
- `maxPartyLevel`
- optional `spawnBand`

Sub-100% XP note:

- when `Ambush XP < 100`, built-in manual payout currently uses `powerClass` first (`FODDER`, `STANDARD`, `BRUISER`, `DREAD`, `APEX`) and falls back to tier only when `powerClass` is missing or invalid
- provider registration does not enforce `powerClass`, but omitting it means the current sub-100% fallback payout logic will use tier mapping instead
- provider templates also need generated XP-clone coverage to remain eligible when `Ambush XP < 100`; otherwise they are skipped from the active pool for safety

Example:

```lua
local ok, err = EnemyAmbush.RegisterEnemyProvider("my_pack", {
    {
        template = "01234567-89ab-cdef-0123-456789abcdef",
        name = "Example Raider",
        creatureType = "Humanoid",
        level = 5,
        weight = 1.0,
        status = "",
        powerClass = "STANDARD",
        resolvedTemplateLevel = 5,
        minPartyLevel = 3,
        maxPartyLevel = 12,
    }
}, {
    priority = 100,
    requiresAnyUUID = {
        "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    }
})

if not ok then
    print("[MyPatch] Enemy provider registration failed:", err)
end
```

## Champion entry shape

Common fields:

- `template`
- `name`
- `creatureType`
- `level`
- `weight`
- `status`
- `championOnly = true`

Example:

```lua
local ok, err = EnemyAmbush.API.RegisterChampionProvider("my_pack_champions", {
    Humanoid = {
        {
            template = "fedcba98-7654-3210-fedc-ba9876543210",
            name = "Example Nemesis",
            creatureType = "Humanoid",
            level = 9,
            weight = 1,
            status = "",
            championOnly = true,
        }
    }
}, {
    priority = 100
})

if not ok then
    print("[MyPatch] Champion provider registration failed:", err)
end
```

## Notes for patch authors

- provider activation can be gated by setting keys or mod UUID checks
- higher provider priority wins candidate selection grouping
- champion selection uses weighted random inside the highest-priority candidate set
- disabling `Use Vanilla Enemy Pool` without an external provider patch can leave no valid ambush pool in the shipped payload
- if you need to inspect providers or selected data, prefer the documented query helpers instead of reading `EnemyAmbush._providers` or other private tables directly
