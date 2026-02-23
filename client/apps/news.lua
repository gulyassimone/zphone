RegisterNUICallback('get-news', function(data, cb)
  Log.Debug('NUI get-news called')
  Log.Debug(('NUI payload: %s'):format(json.encode(data or {})))

  Log.Debug('Calling simi_news:getAll via lib.callback')
  lib.callback('simi_news:getAll', false, function(list)
    local count = (type(list) == 'table') and #list or 0
    Log.Debug(('simi_news:getAll returned %d items'):format(count))
    if count > 0 then
      local first = list[1]
      Log.Debug(('First item preview: %s'):format(json.encode({
        id = first.id,
        title = first.title,
        source = first.source,
        created_at = first.created_at,
      })))
    end

    local payload = { news = list or {}, streams = {} }
    Log.Debug(('Sending NUI callback payload: %s'):format(json.encode({
      newsCount = #payload.news,
      streamsCount = #payload.streams,
    })))
    cb(payload)
  end)
end)
