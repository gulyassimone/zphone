Q = Q or {}

Q.GetAds = [[
  select
    zpa.content,
    zpa.media,
    zpa.citizenid,
    DATE_FORMAT(zpa.created_at, '%d/%m/%Y %H:%i') as time,
    zpu.avatar,
    zpu.phone_number,
    zpu.name as name
  from zp_ads zpa
  JOIN zp_users zpu ON zpu.citizenid = zpa.citizenid
  ORDER BY zpa.id DESC
  LIMIT 100
]]

Q.InsertAd = "INSERT INTO zp_ads (citizenid, media, content) VALUES (?, ?, ?)"

return Q
