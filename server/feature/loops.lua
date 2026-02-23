lib.callback.register('z-phone:server:LoopsLogin', function(source, body)
  local Player = xCore.GetPlayerBySource(source)

  if Player ~= nil then
    local citizenid = Player.citizenid
    local id = MySQL.scalar.await(Q.LoginCheckUser, {
      body.username,
      body.password,
    })

    if not id then
      return {
        is_valid = false,
        message = "Incorrect username or password",
      }
    end

    MySQL.update.await(Q.UpdateActiveLoopsUser, {
      id,
      citizenid
    })

    local profile = MySQL.single.await(Q.ProfileById, {
      id
    })

    return {
      is_valid = true,
      message = "Welcome back @" .. body.username,
      profile = profile
    }
  end

  return {
    is_valid = false,
    message = "Try again later!",
  }
end)

lib.callback.register('z-phone:server:LoopsSignup', function(source, body)
  local Player = xCore.GetPlayerBySource(source)

  if Player ~= nil then
    local citizenid = Player.citizenid
    local duplicateUsername = MySQL.scalar.await(Q.CheckUsername, {
      body.username
    })

    if duplicateUsername then
      return {
        is_valid = false,
        message = "@" .. body.username .. " not available",
      }
    end

    local id = MySQL.insert.await(Q.InsertLoopsUser, {
      citizenid,
      body.username,
      body.password,
      body.fullname,
      body.phone_number,
    })

    if id then
      TriggerClientEvent("z-phone:client:sendNotifInternal", Player.source, {
        type = "Notification",
        from = "Loops",
        message = "Awesome, let's signin!"
      })
      local content = [[
Welcome aboard! \
\
Username: @%s \
Fullname : %s \
Password : %s \
Phone Number : %s \
\
We're thrilled to have you join our community. Your Loops account signup was successful created, and you’re now all set to explore everything. \
To get started, log in to your account and check out all tweets. \
\
We're excited to see you dive in and start exploring. Welcome to the Loopsverse!
    ]]
      MySQL.single.await(Q.InsertEmail, {
        "loops",
        Player.citizenid,
        "Your account " .. body.username .. " Has Been Created",
        string.format(content, body.username, body.fullname, body.password, body.phone_number),
      })
      return {
        is_valid = true,
        message = "Loops " .. body.username .. " Has Been Created",
      }
    else
      return {
        is_valid = false,
        message = "Find others username!",
      }
    end
  end

  return {
    is_valid = false,
    message = "Try again later!",
  }
end)

lib.callback.register('z-phone:server:GetTweets', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid
    local result = MySQL.query.await(Q.GetTweets)

    if result then
      return result
    else
      return {}
    end
  end
  return {}
end)

lib.callback.register('z-phone:server:GetComments', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid
    local result = MySQL.query.await(Q.GetComments, { body.tweetid })

    if result then
      return result
    else
      return {}
    end
  end
  return {}
end)

lib.callback.register('z-phone:server:SendTweet', function(source, body)
  local Player = xCore.GetPlayerBySource(source)

  if Player ~= nil then
    local citizenid = Player.citizenid

    local loopsUserID = MySQL.scalar.await(Q.GetActiveLoopsUser, {
      citizenid
    })

    if loopsUserID == 0 then
      TriggerClientEvent("z-phone:client:sendNotifInternal", Player.source, {
        type = "Notification",
        from = "Loops",
        message = "Please re-login to post tweet!"
      })
      return
    end

    local id = MySQL.insert.await(Q.InsertTweet, {
      loopsUserID,
      body.tweet,
      body.media
    })

    if id then
      TriggerClientEvent("z-phone:client:sendNotifInternal", Player.source, {
        type = "Notification",
        from = "Loops",
        message = "Tweet posted!"
      })
      return true
    else
      return false
    end
  end
  return false
end)

lib.callback.register('z-phone:server:SendTweetComment', function(source, body)
  local Player = xCore.GetPlayerBySource(source)

  if Player ~= nil then
    local citizenid = Player.citizenid
    local loopsUserID = MySQL.scalar.await(Q.GetActiveLoopsUser, {
      citizenid
    })

    if loopsUserID == 0 then
      TriggerClientEvent("z-phone:client:sendNotifInternal", Player.source, {
        type = "Notification",
        from = "Loops",
        message = "Please re-login to comment tweet!"
      })
      return
    end

    local id = MySQL.insert.await(Q.InsertComment, {
      body.tweetid,
      loopsUserID,
      body.comment
    })

    if id then
      local notifications = MySQL.query.await(Q.NotificationTargets, { body.loops_userid })

      if not notifications then
        return true
      end

      for i, v in pairs(notifications) do
        local TargetPlayer = xCore.GetPlayerByIdentifier(v.citizenid)
        if TargetPlayer ~= nil and TargetPlayer.source ~= source then
          TriggerClientEvent("z-phone:client:sendNotifInternal", TargetPlayer.source, {
            type = "Notification",
            from = "Loops",
            message = "@" .. body.comment_username .. " reply on your tweet"
          })
        end
      end
      return true
    else
      return false
    end
  end
  return false
end)

lib.callback.register('z-phone:server:UpdateLoopsProfile', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid

    local duplicateUsername = MySQL.scalar.await(Q.CheckUsernameOther, {
      body.username,
      body.id,
    })

    if duplicateUsername then
      return {
        is_valid = false,
        message = "@" .. body.username .. " not available",
      }
    end

    local activeLoopsUserID = MySQL.scalar.await(Q.GetActiveLoopsUser, {
      citizenid,
    })

    if activeLoopsUserID == 0 then
      return {
        is_valid = false,
        message = "Please re-login to update profile!"
      }
    end

    local affectedRow = MySQL.update.await(Q.UpdateLoopsProfile, {
      body.fullname,
      body.username,
      body.bio,
      body.avatar,
      body.cover,
      body.is_allow_message,
      body.phone_number,
      activeLoopsUserID,
    })

    if affectedRow then
      local profile = MySQL.single.await(Q.ProfileById, {
        activeLoopsUserID
      })

      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Loops",
        message = "Success update account!"
      })
      return {
        is_valid = true,
        message = "Success update account!",
        profile = profile
      }
    end

    return {
      is_valid = false,
      message = "Please try again later!",
    }
  end
  return {
    is_valid = false,
    message = "Please try again later!",
  }
end)

lib.callback.register('z-phone:server:GetLoopsProfile', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid
    if body.id == 0 then
      return {
        is_me = false,
        profile = {},
        tweets = {},
        replies = {}
      }
    end

    local activeLoopsUserID = MySQL.scalar.await(Q.GetActiveLoopsUser, {
      citizenid,
    })

    if activeLoopsUserID == 0 then
      return {
        is_me = false,
        profile = {},
        tweets = {},
        replies = {}
      }
    end

    local profile = MySQL.single.await(Q.ProfileWithCitizen, {
      body.id
    })

    if not profile then
      return {
        is_me = false,
        profile = {},
        tweets = {},
        replies = {}
      }
    end

    local tweets = MySQL.query.await(Q.TweetsByUser, {
      body.id
    })

    local replies = MySQL.query.await(Q.RepliesByUser, {
      body.id,
      body.id,
    })

    return {
      is_me = activeLoopsUserID == profile.id,
      profile = profile,
      tweets = tweets,
      replies = replies
    }
  end

  return {
    is_me = false,
    profile = {},
    tweets = {},
    replies = {}
  }
end)

lib.callback.register('z-phone:server:UpdateLoopsLogout', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid

    local affectedRow = MySQL.update.await(Q.Logout, {
      0,
      citizenid
    })
    return true
  end

  return true
end)
