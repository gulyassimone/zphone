Q = Q or {}

Q.GetContacts = [[
  select
    zpc.contact_name as name,
    DATE_FORMAT(zpc.created_at, '%d/%m/%Y %H:%i') as add_at,
    zpc.contact_citizenid,
    zpu.avatar,
    zpu.phone_number
  from zp_contacts zpc
  JOIN zp_users zpu ON zpu.citizenid = zpc.contact_citizenid
  WHERE zpc.citizenid = ? ORDER BY zpc.contact_name ASC
]]

Q.DeleteContact = [[
  DELETE FROM zp_contacts WHERE citizenid = ? and contact_citizenid = ?
]]

Q.UpdateContact = [[
  UPDATE zp_contacts SET contact_name = ? WHERE contact_citizenid = ? AND citizenid = ?
]]

Q.GetUserByPhone = [[
  select zpu.* from zp_users zpu WHERE zpu.phone_number = ? LIMIT 1
]]

Q.CheckDuplicate = [[
  select zpc.* from zp_contacts zpc WHERE zpc.contact_citizenid = ? and zpc.citizenid = ? LIMIT 1
]]

Q.InsertContact = "INSERT INTO zp_contacts (citizenid, contact_citizenid, contact_name) VALUES (?, ?, ?)"

Q.GetContactRequests = [[
  SELECT
    zpcr.id,
    zpu.avatar,
    zpu.phone_number AS name,
    DATE_FORMAT(zpcr.created_at, '%d %b %Y %H:%i') as request_at
  FROM zp_contacts_requests zpcr
  LEFT JOIN zp_users zpu ON zpu.citizenid = zpcr.from_citizenid
  WHERE zpcr.citizenid = ? ORDER BY zpcr.id DESC
]]

Q.InsertContactRequest = "INSERT INTO zp_contacts_requests (citizenid, from_citizenid) VALUES (?, ?)"

Q.DeleteContactRequest = "DELETE FROM zp_contacts_requests WHERE id = ?"

return Q
