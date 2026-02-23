Q = Q or {}

Q.GetProfile = [[
  select
    zpu.name,
    zpu.citizenid,
    zpu.phone_number,
    zpu.created_at,
    zpu.last_seen,
    zpu.avatar,
    zpu.unread_message_service,
    zpu.unread_message,
    zpu.wallpaper,
    zpu.is_anonim,
    zpu.is_donot_disturb,
    zpu.frame,
    zpu.iban,
    zpu.active_loops_userid,
    zpu.inetmax_balance,
    zpu.phone_height
  from zp_users zpu WHERE zpu.citizenid = ? LIMIT 1
]]

Q.InsertUser = "INSERT INTO zp_users (citizenid, name, phone_number, iban, inetmax_balance) VALUES (?, ?, ?, ?, ?)"

Q.UpdateAvatar = 'UPDATE zp_users SET avatar = ? WHERE citizenid = ?'
Q.UpdateWallpaper = 'UPDATE zp_users SET wallpaper = ? WHERE citizenid = ?'
Q.UpdateAnon = 'UPDATE zp_users SET is_anonim = ? WHERE citizenid = ?'
Q.UpdateDnd = 'UPDATE zp_users SET is_donot_disturb = ? WHERE citizenid = ?'
Q.UpdateFrame = 'UPDATE zp_users SET frame = ? WHERE citizenid = ?'
Q.UpdatePhoneHeight = 'UPDATE zp_users SET phone_height = ? WHERE citizenid = ?'

return Q
