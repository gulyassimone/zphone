Q = Q or {}

Q.GetNews = [[
  SELECT
    id,
    reporter,
    company,
    image,
    title,
    body,
    stream,
    is_stream,
    DATE_FORMAT(created_at, '%d %b %Y %H:%i') as created_at
  FROM zp_news WHERE is_stream = ? ORDER BY id DESC
]]

Q.InsertNews =
"INSERT INTO zp_news (citizenid, reporter, company, image, title, body, stream, is_stream) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"

return Q
