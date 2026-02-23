Q = Q or {}

Q.LoginCheckUser = "select id from zp_loops_users where username = ? and password = ?"
Q.UpdateActiveLoopsUser = "UPDATE zp_users SET active_loops_userid = ? WHERE citizenid = ?"

Q.ProfileById = [[
  SELECT
    zplu.id,
    zplu.fullname,
    zplu.username,
    zplu.avatar,
    zplu.cover,
    zplu.bio,
    DATE_FORMAT(zplu.join_at, '%d %b %Y') as join_at,
    zplu.is_verified,
    zplu.is_allow_message,
    zplu.phone_number
  FROM zp_loops_users zplu
  WHERE zplu.id = ?
]]

Q.CheckUsername = "select id from zp_loops_users where username = ?"
Q.InsertLoopsUser =
"INSERT INTO zp_loops_users (citizenid, username, password, fullname, phone_number) VALUES (?, ?, ?, ?, ?)"
Q.InsertEmail = "INSERT INTO zp_emails (institution, citizenid, subject, content) VALUES (?, ?, ?, ?)"

Q.GetActiveLoopsUser = "select active_loops_userid from zp_users where citizenid = ?"

Q.GetTweets = [[
  SELECT
    zpt.id,
    zpt.tweet,
    zpt.media,
    zplu.id as loops_userid,
    zplu.citizenid,
    zplu.fullname AS name,
    zplu.avatar,
    CONCAT("@", zplu.username) as username,
    DATEDIFF(CURDATE(), zpt.created_at) AS created_at,
    COUNT(zptc.id) AS comment,
    0 AS repost
  FROM
    zp_tweets zpt
  JOIN zp_loops_users zplu ON zplu.id = zpt.loops_userid
  LEFT JOIN zp_tweet_comments zptc ON zptc.tweetid = zpt.id
  GROUP BY zpt.id, zpt.tweet, zpt.media, zplu.avatar, zplu.username, zplu.join_at, name
  ORDER BY zpt.id DESC
  LIMIT 100
]]

Q.GetComments = [[
  SELECT
    zptc.comment,
    zplu.id as loops_userid,
    zplu.fullname AS name,
    zplu.avatar,
    CONCAT("@", zplu.username) as username,
    DATEDIFF(CURDATE(), zptc.created_at) AS created_at
  FROM
    zp_tweet_comments zptc
  JOIN zp_loops_users zplu ON zplu.id = zptc.loops_userid
  WHERE zptc.tweetid = ?
  ORDER BY zptc.id DESC
]]

Q.InsertTweet = "INSERT INTO zp_tweets (loops_userid, tweet, media) VALUES (?, ?, ?)"
Q.InsertComment = "INSERT INTO zp_tweet_comments (tweetid, loops_userid, comment) VALUES (?, ?, ?)"

Q.NotificationTargets = [[
  SELECT citizenid FROM zp_users WHERE active_loops_userid = ?
]]

Q.CheckUsernameOther = "select id from zp_loops_users where username = ? and id != ?"

Q.UpdateLoopsProfile = [[
  UPDATE zp_loops_users SET
    fullname = ?,
    username = ?,
    bio = ?,
    avatar = ?,
    cover = ?,
    is_allow_message = ?,
    phone_number = ?
  WHERE id = ?
]]

Q.ProfileWithCitizen = [[
  SELECT
    zplu.id,
    zplu.fullname,
    zplu.username,
    zplu.avatar,
    zplu.cover,
    zplu.bio,
    DATE_FORMAT(zplu.join_at, '%d %b %Y') as join_at,
    zplu.is_verified,
    zplu.is_allow_message,
    zplu.phone_number,
    zplu.citizenid
  FROM zp_loops_users zplu
  WHERE zplu.id = ?
]]

Q.TweetsByUser = [[
  SELECT
    zpt.id,
    zpt.tweet,
    zpt.media,
    zplu.id as loops_userid,
    zplu.citizenid,
    zplu.fullname AS name,
    zplu.avatar,
    CONCAT("@", zplu.username) as username,
    DATEDIFF(CURDATE(), zpt.created_at) AS created_at,
    COUNT(zptc.id) AS comment,
    0 AS repost
  FROM
    zp_tweets zpt
  JOIN zp_loops_users zplu ON zplu.id = zpt.loops_userid
  LEFT JOIN zp_tweet_comments zptc ON zptc.tweetid = zpt.id
  WHERE zpt.loops_userid = ?
  GROUP BY zpt.id, zpt.tweet, zpt.media, zplu.avatar, zplu.username, zplu.join_at, name
  ORDER BY zpt.id DESC
  LIMIT 100
]]

Q.RepliesByUser = [[
  SELECT
    zpt.id,
    zpt.tweet,
    zpt.media,
    zplu.id as loops_userid,
    zplu.citizenid,
    zplu.fullname AS name,
    zplu.avatar,
    CONCAT("@", zplu.username) as username,
    DATEDIFF(CURDATE(), zpt.created_at) AS created_at,
    COUNT(zptc.id) AS comment,
    0 AS repost
  FROM
    zp_tweets zpt
  JOIN zp_loops_users zplu ON zplu.id = zpt.loops_userid
  LEFT JOIN zp_tweet_comments zptc ON zptc.tweetid = zpt.id
  WHERE zpt.id in (SELECT zptc2.tweetid FROM zp_tweet_comments zptc2 WHERE zptc2.loops_userid = ? GROUP BY zptc2.tweetid) AND zpt.loops_userid != ?
  GROUP BY zpt.id, zpt.tweet, zpt.media, zplu.avatar, zplu.username, zplu.join_at, name
  ORDER BY zpt.id DESC
  LIMIT 100
]]

Q.Logout = [[
  UPDATE zp_users SET
    active_loops_userid = ?
  WHERE citizenid = ?
]]

return Q
