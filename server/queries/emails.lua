Q = Q or {}

Q.GetEmails = [[
  SELECT
    id,
    institution,
    citizenid,
    subject,
    content,
    is_read,
    DATE_FORMAT(created_at, '%d %b %Y %H:%i') as created_at
  FROM zp_emails WHERE citizenid = ? ORDER BY id DESC LIMIT 100
]]

return Q
