Q = Q or {}

Q.GetTopups = [[
  SELECT
    total,
    flag,
    label,
    DATE_FORMAT(created_at, '%d %b %Y') as created_at
  FROM zp_inetmax_histories WHERE citizenid = ? AND flag = ? ORDER BY id desc limit 50
]]

Q.GetUsageGroup =
"SELECT label as app, total FROM zp_inetmax_histories WHERE flag = 'USAGE' and citizenid = ? GROUP BY label"

Q.InsertHistory = "INSERT INTO zp_inetmax_histories (citizenid, flag, label, total) VALUES (?, ?, ?, ?)"

Q.UpdateBalanceAdd = [[
  UPDATE zp_users SET inetmax_balance = inetmax_balance + ? WHERE citizenid = ?
]]

Q.UpdateBalanceSubtract = [[
  UPDATE zp_users SET inetmax_balance = inetmax_balance - ? WHERE citizenid = ?
]]

Q.InsertEmail = "INSERT INTO zp_emails (institution, citizenid, subject, content) VALUES (?, ?, ?, ?)"

return Q
