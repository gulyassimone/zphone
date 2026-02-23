# Z-Phone quick review (perf + usability)

## Observed issues / risks
- Ox call flow relies on pma-voice `addPlayerToCall/removePlayerFromCall` only; no retry or timeouts on voice join failures. If pma-voice fails to start, calls appear connected but no audio.
- No guard for duplicate phone numbers or index on `zp_users.phone_number`; large tables will cause slow lookups on `StartCall`.
- Database schema lacks foreign keys and consistent citizenid length; referential errors may accumulate and slow queries.
- InetMax balance checks use random per-action costs from config at runtime; amount differs per call per session, hard to predict.
- Signal zones default off; if enabled, every call/message consults zone checks without caching; could add simple memoization.
- Photo/gallery, ads, tweets store URLs without validation; missing size/type checks could bloat DB or UI load time.
- Server uses many `SELECT ... LIMIT 1` per interaction without batching; under load this will increase query count.
- No rate-limiting for message send, ads post, calls, or services; susceptible to spam causing DB and NUI spam.

## Usability gaps
- No in-phone indicator for own number beyond Profile; quick-copy or share button missing.
- No radio/VOIP channel picker; only phone call audio via pma-voice call channel.
- No offline voicemail or missed-call SMS; caller just gets “not answered”.
- No contact import/export; contacts local to character only.
- No settings for ringtones/volumes per contact; single global sound.
- Camera/photos do not compress or limit resolution; could stall slower clients on heavy usage.

## Performance suggestions
- Add UNIQUE index on `zp_users(phone_number)` and `zp_calls_histories(to_citizenid)`; consider FK to `zp_users(citizenid)`.
- Cache zone lookups per tick when Signal is enabled; avoid repeated vec3 distance per frame.
- Batch DB queries where possible (contacts, histories) and cap list sizes (e.g., paginate histories).
- Add server-side rate limits (per source per minute) for calls/messages/ads.
- Validate URL length and content-type for uploads/links; reject oversize payloads.

## Missing / integration
- **Radio**: nincs beépített rádió UI; csak telefonhívás (pma-voice call channel). Ha rádió kell, külön resource (pl. pma-voice radio UI) vagy custom app.
- No billing/invoice push to phone when ESX billing is used (banking shows history only).
- No 2FA/pin lock beyond lockscreen; no theft-protection if phone item stolen.

## Quick checklist to improve
- Telepíts UNIQUE indexet és FK-kat a z-phone.sql-ben (vagy migrációval): phone_number, citizenid hosszt egységesíteni.
- Adj rate limitet és hibaüzenetet spamekhez (calls/messages/ads).
- Rakj be url/size validációt a media mezőkre; opc. képtömörítés kamera feltöltésnél.
- Ha rádió kell: külön VOIP app vagy integráció pma-voice radio channel API-val.
- Cache-eld a signal zone és inetmax usage számításokat; vedd ki a runtime randomot, használd fix értéket a configból.
