Q = Q or {}

Q.GetUserByPhone = [[
  SELECT zpu.* FROM zp_users zpu WHERE zpu.phone_number = ? LIMIT 1
]]

Q.GetContactName = [[
  SELECT zpc.contact_name FROM zp_contacts zpc WHERE zpc.citizenid = ? AND zpc.contact_citizenid = ?
]]

Q.InsertHistory = "INSERT INTO zp_calls_histories (citizenid, to_citizenid, flag, is_anonim) VALUES (?, ?, ?, ?)"

Q.GetHistories = [[
  SELECT
    CASE
      WHEN zpc.contact_name IS NULL THEN
        ""
      ELSE zpu.avatar
    END AS avatar,
    IFNULL(zpc.contact_name, zpu.phone_number) AS to_person,
    DATE_FORMAT(zpch.created_at, '%d %b %Y %H:%i') as created_at,
    zpch.flag,
    zpch.is_anonim
  FROM zp_calls_histories zpch
  LEFT JOIN zp_users zpu ON zpu.citizenid = zpch.to_citizenid
  LEFT JOIN zp_contacts zpc ON zpc.contact_citizenid = zpch.to_citizenid
  WHERE zpch.citizenid = ? ORDER BY zpch.id DESC LIMIT 100
]]

return Q
