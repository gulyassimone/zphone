Q = Q or {}

Q.GetUserByPhone = [[
  select zpu.* from zp_users zpu WHERE zpu.phone_number = ? LIMIT 1
]]

Q.GetConversationId = [[
  WITH ConversationParticipants AS (
    SELECT conversationid
    FROM zp_conversation_participants
    WHERE citizenid IN (?, ?)
    GROUP BY conversationid
    HAVING COUNT(DISTINCT citizenid) = 2
  ),
  InvalidConversations AS (
    SELECT conversationid
    FROM zp_conversation_participants
    GROUP BY conversationid
    HAVING COUNT(DISTINCT citizenid) > 2
  )
  SELECT
    CASE
      WHEN EXISTS (SELECT 1 FROM InvalidConversations) THEN NULL
      ELSE (SELECT conversationid FROM ConversationParticipants)
    END AS conversationid
]]

Q.InsertConversation = "INSERT INTO zp_conversations (is_group) VALUES (?)"
Q.InsertParticipant = "INSERT INTO zp_conversation_participants (conversationid, citizenid) VALUES (?, ?)"

Q.GetChatting = [[
  SELECT
    from_user.avatar,
    from_user.citizenid,
    from_user.phone_number,
    CASE
      WHEN c.is_group = 0 THEN
        COALESCE(
          contact.contact_name,
          from_user.phone_number
        )
      ELSE c.name
    END AS conversation_name,
    DATE_FORMAT(from_user.last_seen, '%d/%m/%Y %H:%i') as last_seen,
    0 as is_read,
    c.id as conversationid,
    c.is_group
  FROM
    zp_conversations c
  JOIN
    zp_conversation_participants p
      ON c.id = p.conversationid
  LEFT JOIN
    zp_conversation_participants other_participant
      ON c.id = other_participant.conversationid
      AND other_participant.citizenid != p.citizenid
  LEFT JOIN
    zp_users from_user
      ON other_participant.citizenid = from_user.citizenid
  LEFT JOIN
    zp_contacts contact
      ON contact.citizenid = p.citizenid
      AND contact.contact_citizenid = other_participant.citizenid
  WHERE
    c.id = ? and p.citizenid = ?
  LIMIT 1
]]

Q.UpdateLastSeen = 'UPDATE zp_users SET last_seen = now() WHERE citizenid = ?'

Q.GetChats = [[
  WITH LatestMessages AS (
    SELECT
      conversationid,
      content,
      created_at,
      is_deleted,
      ROW_NUMBER() OVER (PARTITION BY conversationid ORDER BY created_at DESC) AS rn
    FROM
      zp_conversation_messages
  )
  SELECT
    from_user.avatar,
    from_user.citizenid,
    CASE
      WHEN c.is_group = 0 THEN
        COALESCE(
          contact.contact_name,
          from_user.phone_number
        )
      ELSE c.name
    END AS conversation_name,
    from_user.phone_number,
    DATE_FORMAT(from_user.last_seen, '%d/%m/%Y %H:%i') as last_seen,
    0 as isRead,
    CASE
      WHEN last_msg.is_deleted = 1 THEN
        'This message was deleted'
      WHEN last_msg.content = '' THEN
        'media'
      ELSE last_msg.content
    END AS last_message,
    DATE_FORMAT(last_msg.created_at, '%H:%i') AS last_message_time,
    c.id as conversationid,
    c.is_group
  FROM
    zp_conversations c
  JOIN
    zp_conversation_participants p
      ON c.id = p.conversationid
  LEFT JOIN
    zp_conversation_participants other_participant
      ON c.id = other_participant.conversationid
      AND other_participant.citizenid != p.citizenid
  LEFT JOIN
    zp_users from_user
      ON other_participant.citizenid = from_user.citizenid
  LEFT JOIN
    zp_contacts contact
      ON contact.citizenid = p.citizenid
      AND contact.contact_citizenid = other_participant.citizenid
  LEFT JOIN
    LatestMessages last_msg
      ON c.id = last_msg.conversationid AND last_msg.rn = 1
  WHERE
    p.citizenid = ?
  GROUP BY conversation_name
  ORDER BY
    last_msg.created_at DESC
]]

Q.GetChatMessages = [[
  SELECT
    *
  FROM
    (
      SELECT
        zpcm.id,
        zpcm.content as message,
        zpcm.media,
        DATE_FORMAT(zpcm.created_at, '%d %b %Y %H:%i') as time,
        zpcm.sender_citizenid,
        zpcm.is_deleted,
        TIMESTAMPDIFF(MINUTE, zpcm.created_at, NOW()) AS minute_diff
      FROM
        zp_conversation_messages zpcm
      WHERE
        conversationid = ?
      ORDER BY
        id DESC
      LIMIT 200
    ) AS subquery
  ORDER BY
    id ASC;
]]

Q.InsertMessage =
"INSERT INTO zp_conversation_messages (conversationid, sender_citizenid, content, media) VALUES (?, ?, ?, ?)"

Q.GetContactName = [[
  SELECT
    COALESCE(
      (SELECT contact_name FROM zp_contacts WHERE citizenid = ? and contact_citizenid = ?),
      (SELECT phone_number FROM zp_users WHERE citizenid = ?)
    ) AS name
]]

Q.GetParticipants = [[
  SELECT * FROM zp_conversation_participants WHERE conversationid = ?
]]

Q.DeleteMessage = [[
  UPDATE zp_conversation_messages SET is_deleted = 1 WHERE id = ? and sender_citizenid = ?
]]

Q.GetUsersByPhones = [[
  SELECT * FROM zp_users WHERE phone_number IN (?)
]]

Q.InsertGroupConversation = "INSERT INTO zp_conversations (name, is_group, admin_citizenid) VALUES (?, ?, ?)"

Q.InsertGroupMessage =
"INSERT INTO zp_conversation_messages (conversationid, sender_citizenid, content) VALUES (?, ?, ?)"

return Q
