Q = Q or {}

Q.GetPhotos = [[
  select
    zpp.id,
    zpp.media as photo,
    DATE_FORMAT(zpp.created_at, '%d/%m/%Y %H:%i') as created_at
  from zp_photos zpp
  WHERE zpp.citizenid = ? ORDER BY zpp.id DESC
]]

Q.InsertPhoto = "INSERT INTO zp_photos (citizenid, media, location) VALUES (?, ?, ?)"

Q.DeletePhoto = "DELETE from zp_photos WHERE id = ? AND citizenid = ?"

return Q
