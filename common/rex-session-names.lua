local pinnedNames = rex.args.pinSessions and { "dotfiles", "socials", "support" } or {}

local pinnedSessions = {}

local function orderSessions()
  local position = 1
  for _, name in ipairs(pinnedNames) do
    local sessions, err = rex.call("session.list")
    if not sessions then rex.log(err); return end
    for index, session in ipairs(sessions.sessions) do
      if pinnedSessions[session.session_id] == name then
        if index ~= position then
          local result, moveErr = rex.call("session.move", {
            session_id = session.session_id,
            before_session_id = sessions.sessions[position].session_id,
          })
          if not result then rex.log(moveErr) end
        end
        position = position + 1
        break
      end
    end
  end
end

local function sync(sessionId)
  local view, err = rex.session.view{session_id = sessionId}
  if not view then
    rex.log(err)
    return
  end
  local window = (view.windows or {})[1]
  if not window then return end

  local label = window.label or ""
  if label == "" or label:match("^Window %x+$") then
    if not window.focused_block_id then return end
    local title, titleErr = rex.block.call("com.superlogical.terminal", "title", {
      session_id = sessionId,
      block_id = window.focused_block_id,
    })
    if not title then
      rex.log(titleErr)
      return
    end
    label = title.title
  end

  -- Braille animation frames are three-byte UTF-8 characters in U+2800–U+28FF.
  label = label:gsub("^%s*\226[\160-\163][\128-\191]%s*", "")
    :gsub("%s+| zupo%s*$", "")
    :gsub("%c", "")
    :match("^%s*(.-)%s*$")
  local characters = {}
  for character in label:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    if #characters == 128 then break end
    characters[#characters + 1] = character
  end
  label = table.concat(characters)
  if label ~= "" and label ~= view.label then
    local result, renameErr = rex.session.set_label{session_id = sessionId, label = label}
    if not result then rex.log(renameErr) end
  end
end

local function attach(sessionId)
  assert(rex.session.attach{session_id = sessionId})
  local view, viewErr = rex.session.view{session_id = sessionId}
  if not view then rex.log(viewErr); return end
  local windows = view.windows or {}
  for _, name in ipairs(pinnedNames) do
    for _, window in ipairs(windows) do
      if window.label == name then pinnedSessions[sessionId] = name; break end
    end
    if pinnedSessions[sessionId] then break end
  end
  if not pinnedSessions[sessionId] and windows[1] then
    for _, name in ipairs(pinnedNames) do
      if view.label == name then
        local result, labelErr = rex.call("session.set_window_label", {
          session_id = sessionId,
          window_id = windows[1].window_id,
          label = name,
        })
        if not result then rex.log(labelErr); return end
        pinnedSessions[sessionId] = name
        break
      end
    end
  end
  sync(sessionId)
  orderSessions()
end

rex.on("session_created", function(_, ev) attach(ev.session.session_id) end)
rex.on("session_view_changed", function(ctx)
  sync(ctx.session_id)
  orderSessions()
end)
rex.on("session_moved", orderSessions)
rex.on("terminal.title_changed", function(ctx) sync(ctx.session_id) end)

local sessions, err = rex.call("session.list")
assert(sessions, err)
for _, session in ipairs(sessions.sessions) do
  attach(session.session_id)
end
