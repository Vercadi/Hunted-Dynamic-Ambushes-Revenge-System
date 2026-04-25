# Troubleshooting

## No settings menu is showing

Cause:

- `BG3MCM` is not installed or not loading

What to do:

- install or update `BG3MCM`
- reload the save after `BG3MCM` is present
- treat missing `BG3MCM` as unsupported startup, not as a no-UI fallback mode

## No ambushes are spawning

Check these first:

- `MCM_EnableSummons = ON`
- `MCM_EnableOnRest = ON`
- `MCM_SafetyChecks = ON` can block unsafe contexts
- `MCM_CampAmbushes = OFF` blocks camp ambushes by design
- cooldowns and safety gates can delay or block real spawns

Useful commands:

- `!ea_test verify`
- `!ea_test settings`
- `!ea_test region`
- `!ea_test metrics`

## I turned off the vanilla pool and nothing spawns

Cause:

- the shipped mod registers the built-in vanilla provider set
- if `Use Vanilla Enemy Pool` is off and no external provider patch is installed, the active ambush pool can become empty

What to do:

- turn `Use Vanilla Enemy Pool` back on
- or install a provider patch that registers content through the API

## Settings changes are not applying

Check:

- if using `BG3MCM`, make sure it is installed and loaded
- use `!ea_test settings` to confirm the effective runtime values
- if `BG3MCM` is absent, install it first; the old persisted-settings fallback path is no longer supported

Useful commands:

- `!ea_test settings`
- `!ea_test readiness`

## XP rewards look wrong with XP mods

Cause:

- `Ambush XP` below `100%` uses manual payout
- built-in sub-100% payout currently uses the fallback XP table with `powerClass` first and tier fallback second
- third-party XP multiplier mods may not scale that manual payout path

What to do:

- leave `Ambush XP` at `100%` if you want third-party XP multipliers to behave normally
- if you are testing sub-100% payout, check the `XP payout plan:` log line:
  - `partyMembers` should match the intended party size
  - `xpRecipientSource=db_players_party_filtered` is the current expected happy-path source for built-in tests
  - `xpRewardCategorySource=powerClass` is the current expected built-in fallback-category source when `powerClass` exists

## I uninstalled the mod and my save shows warnings

Cause:

- the mod stores persistent Script Extender variables

What to do:

- this can produce normal missing-mod warnings on existing saves
- back up saves before uninstalling
- avoid uninstalling mid-campaign unless you accept the risk of warning noise or unsupported edge cases

## Co-op behavior looks wrong

Check:

- which player initiated the rest
- whether host and non-host players were in different regions or camp states
- whether more than one ambush schedule was created for the same rest flow

Useful commands:

- `!ea_test settings`
- `!ea_test metrics`
- `!ea_test region`
