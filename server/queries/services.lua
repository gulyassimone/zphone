Q = Q or {}

Q.GetServices = [[
  SELECT
    zpsm.service,
    zpu.phone_number,
    zpsm.citizenid,
    MAX(zpsm.id) AS id,
    GROUP_CONCAT(zpsm.message ORDER BY zpsm.id SEPARATOR '\n') AS message,
    GROUP_CONCAT(COALESCE(zpsm.cord, '') ORDER BY zpsm.id SEPARATOR '\n') AS cord,
    DATE_FORMAT(MAX(zpsm.created_at), '%d/%m/%Y %H:%i') AS created_at
  FROM zp_service_messages zpsm
  JOIN zp_users zpu ON zpu.citizenid = zpsm.citizenid
  WHERE zpsm.service = ? AND zpsm.solved_by_citizenid IS NULL
  GROUP BY zpsm.citizenid, zpsm.service, zpu.phone_number
  ORDER BY MAX(zpsm.id) DESC LIMIT 100
]]

Q.ListServiceJobs = [[
  SELECT name, label, type, whitelisted
  FROM jobs
  WHERE is_service = 1 and whitelisted = 0
  ORDER BY name ASC
]]

Q.InsertServiceMessage = "INSERT INTO zp_service_messages (citizenid, message, service, cord) VALUES (?, ?, ?, ?)"

Q.SolveServiceMessage = [[
  UPDATE zp_service_messages
  SET solved_by_citizenid = ?, solved_reason = ?
  WHERE citizenid = ? AND service = ? AND solved_by_citizenid IS NULL
]]

return Q
