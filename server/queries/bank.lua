Q = Q or {}

Q.GetCitizenByIban = "select citizenid from zp_users where iban = ?"
Q.InsertEmail = "INSERT INTO zp_emails (institution, citizenid, subject, content) VALUES (?, ?, ?, ?)"

return Q
