# Z-Phone adatbázis jegyzet

Ez a jegyzet a z-phone SQL sémája, normalizációja és indexelése kapcsán ad rövid áttekintést, valamint egy opcionális induló scriptről szól, amely hiányzó táblák esetén felhúzza a sémát.

## Gyors puskák

- Importálj mindent innen: [vendor_free/z-phone/z-phone.sql](vendor_free/z-phone/z-phone.sql).
- Használj MySQL/MariaDB 10.4+ utf8mb4 beállítással.
- Gondoskodj a `citizenid` egységes hosszáról (most 50 vs 100 változik a táblákban).
- Indexek kiegészítése javasolt (lentebb).
- Jelenleg nincsenek foreign key-ek; ha tudod, vezesd be az engine-ben.

## Normalizálás és észrevételek

- **Kulcsmezők**: `zp_users` a `citizenid`-et használja PK-ként, de nincs FK a többi táblához. A legtöbb tábla a `citizenid`-et csak VARCHAR-ként tartalmazza.
- **Hossz inkonzisztencia**: `citizenid` hol 50, hol 100 karakter. Egységesíts (pl. 64 vagy 50) minden táblában.
- **Egyediség**: `zp_users.phone_number` csak indexelt, de nincs UNIQUE. Ha nem akarsz duplikált telefonszámokat, tegyél UNIQUE-et.
- **Anonimizálás és DND flag**: ok.
- **Loops ("social") rész**: `zp_loops_users.phone_number` nincs egyediségi kötés, és nincs FK a `zp_users`-höz (`active_loops_userid`).
- **Conversations**: nincs FK `zp_conversation_participants.conversationid` és `zp_conversation_messages.conversationid` felől; nincs cascade delete. Group admin (`admin_citizenid`) sincs kötve FK-val.
- **Tweets/comments**: hiányoznak FK-k a `loops_userid` és `tweetid` mezőknél.
- **Szolgálat környék** (`zp_service_messages`): `citizenid` és `solved_by_citizenid` nincsenek FK-kal kötve.
- **Photos/ads/news/emails**: nincsenek FK-k a `citizenid` mezőkre.

## Index javaslatok (kiegészítések)

- `zp_users`: UNIQUE (`phone_number`); UNIQUE (`iban`) ha kell; drop duplikált sima index, ha UNIQUE lesz.
- `zp_calls_histories`: index `to_citizenid`; esetleg kompozit (`citizenid`, `created_at`).
- `zp_contacts`: a `citizenid_contact_citizenid` index duplikálja a UNIQUE-et; elhagyható. Maradjon a UNIQUE és az `contact_citizenid`.
- `zp_conversation_messages`: kompozit index (`conversationid`, `created_at`) a listázáshoz.
- `zp_conversation_participants`: meglévő PK elég; ha gyakori a citizen lookup, maradhat a `citizenid` index.
- `zp_emails`: kompozit (`citizenid`, `created_at`) hasznos lehet.
- `zp_inetmax_histories`: már van kompozit (`citizenid`, `flag`).
- `zp_tweets`: index `loops_userid`, `created_at`.
- `zp_tweet_comments`: index `tweetid`, `created_at`; index `loops_userid`.

## Foreign key javaslatok (ha kompatibilis az összes szkripttel)

- Minden `citizenid` mező FK a `zp_users(citizenid)`-re `ON DELETE CASCADE` / `ON UPDATE CASCADE` szerinted.
- `zp_conversation_messages.conversationid` és `zp_conversation_participants.conversationid` FK a `zp_conversations(id)`-re (CASCADE delete).
- `zp_tweets.loops_userid` és `zp_tweet_comments.loops_userid` FK a `zp_loops_users(id)`-re; `zp_tweet_comments.tweetid` FK a `zp_tweets(id)`-re (CASCADE delete).
- `zp_calls_histories.to_citizenid` FK `zp_users(citizenid)`-re.

## Charset/Collation

- Válts egy egységes `utf8mb4_unicode_ci`-re (jobb rendezés és emoji-támogatás), a jelenlegi `utf8mb4_general_ci` helyett.

## Induló SQL futtatás minta (oxmysql)

Ha azt akarod, hogy induláskor lefusson a séma-ellenőrzés és hiányzó táblák hozzáadása, beteheted egy szerveroldali Lua-ba (pl. `server/bootstrap.sql.lua`). Ez csak egy egyszerű minta: hiányt keres, majd betölti a z-phone SQL-t.

```lua
-- server/bootstrap.sql.lua
local tables = {
    "zp_users",
    "zp_conversations",
}

local function tableMissing(name)
    local row = MySQL.single.await([[SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?]], { name })
    return not row
end

local function runSeed()
    local sql = LoadResourceFile(GetCurrentResourceName(), "z-phone.sql")
    if not sql then
        print("[z-phone] Nem találom a z-phone.sql-t, kihagyva.")
        return
    end
    print("[z-phone] Telepítem a sémát...")
    MySQL.query(sql)
    print("[z-phone] Sikeres telepítés.")
end

CreateThread(function()
    for _, tbl in ipairs(tables) do
        if tableMissing(tbl) then
            runSeed()
            break
        end
    end
end)
```

- A fenti csak akkor futtatja a teljes SQL-t, ha **bármelyik** kulcstábla hiányzik.
- Ha pontosabban szeretnéd kontrollálni (pl. csak egyes `CREATE TABLE IF NOT EXISTS` futtatás), bontsd a SQL-t táblánként vagy használj Flyway/liquibase stílusú migrációkat.
- ESX Legacy táblákhoz nem nyúl; ez csak a z-phone sémát telepíti.

## Változtatási ötletek összefoglalója

- Egységesíts `citizenid` hossz (pl. 64) és collation (utf8mb4_unicode_ci).
- Adj UNIQUE-et a telefonszámokra (legalább `zp_users.phone_number`).
- Adj indexeket az időrendi listázás kulcsokra (`created_at` + id mezők).
- Vezess be FK-kat, ha a scriptek nem támaszkodnak laza hivatkozásokra.
- Tedd be a fenti bootstrapet vagy manuális migrációkat, hogy induláskor automatikusan létrejöjjenek a táblák.
