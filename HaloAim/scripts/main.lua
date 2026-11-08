--[[
    Crab Champions - HaloAim
    Halo-style lowered crosshair: the reticle sits below screen centre and
    shots go exactly where it points.

    How: shots follow the camera (ShotDirType::CameraDir), so the camera is
    left alone. Instead the rendered image is shifted with an off-centre
    projection (PlayerCameraManager.ViewTarget.POV.OffCenterProjectionOffset).
    The camera's aim point is drawn offset_y pixels lower, right under the
    moved crosshair widget.

    KEYS
      F7 / F8  offset -/+ step
      F9       reset offset
      F10      toggle image shift (for A/B testing)
      F6       re-apply + status dump (for debugging purposes)
--]]

local TAG = "[HaloAim]"

local CONFIG = {
    offset_y = 90.0,      -- UMG units (= pixels at 1080p); positive = down
    step = 10.0,
    -- UMG scales with the shortest screen side relative to 1080 by default,
    -- so offset_y / (reference_height / 2) is the NDC shift at any resolution.
    reference_height = 1080.0,
    projection_sign = 1.0, -- flip to -1.0 if the image moves the wrong way
    -- minimum seconds between BeginPlay-driven re-applies
    beginplay_throttle = 0.5,
}

local offset_y = CONFIG.offset_y
local shift_enabled = true

local function log(fmt, ...)
    print(TAG .. " " .. string.format(fmt, ...) .. "\n")
end

local function valid(o)
    if not o then return false end
    local ok, v = pcall(function() return o:IsValid() end)
    return ok and v == true
end

local function fullName(o)
    local ok, n = pcall(function() return o:GetFullName() end)
    return ok and n or "?"
end

-- ---- crosshair ---------------------------------------------------------

local logged = {} -- full names only, for one-time log lines

local function logOnce(key, fmt, ...)
    if logged[key] then return end
    logged[key] = true
    log(fmt, ...)
end

local function applyWidgets()
    local list = FindAllOf("CrabCrosshairUI")
    if not list then return end
    for _, w in ipairs(list) do
        if valid(w) then
            local name = fullName(w)
            if string.find(name, "/Engine/Transient", 1, true) then
                -- live widget: goes through Slate
                local ok, err = pcall(function()
                    w:SetRenderTranslation({ X = 0.0, Y = offset_y })
                end)
                if ok then
                    logOnce(name, "crosshair moved: %s", name)
                else
                    log("crosshair move failed: %s", tostring(err))
                end
            else
                -- template: plain property write, copied into new HUDs
                local ok, err = pcall(function()
                    local t = w.RenderTransform.Translation
                    if math.abs(t.Y - offset_y) > 0.01 or math.abs(t.X) > 0.01 then
                        t.X = 0.0
                        t.Y = offset_y
                    end
                end)
                if ok then
                    logOnce("tpl:" .. name, "template patched: %s", name)
                else
                    log("template patch failed: %s", tostring(err))
                end
            end
        end
    end
end

-- ---- view shift --------------------------------------------------------

local function ndcShift()
    if not shift_enabled then return 0.0 end
    return CONFIG.projection_sign * offset_y / (CONFIG.reference_height * 0.5)
end

local function writeOffset(off, want)
    if math.abs(off.Y - want) > 1e-5 or math.abs(off.X) > 1e-5 then
        off.X = 0.0
        off.Y = want
    end
end

local function applyShift()
    local pc = FindFirstOf("CrabPC")
    if not valid(pc) then return end
    local pcm = pc.PlayerCameraManager
    if not valid(pcm) then return end
    local want = ndcShift()
    pcall(function() writeOffset(pcm.ViewTarget.POV.OffCenterProjectionOffset, want) end)
    -- the pending target replaces ViewTarget when a camera blend ends
    pcall(function() writeOffset(pcm.PendingViewTarget.POV.OffCenterProjectionOffset, want) end)
end

local function applyAll()
    pcall(applyWidgets)
    pcall(applyShift)
end

local function status()
    log("---- status ----")
    log("offset_y=%.1f shift_enabled=%s ndc=%.4f", offset_y, tostring(shift_enabled), ndcShift())
    pcall(function()
        local o = FindFirstOf("CrabPC").PlayerCameraManager.ViewTarget.POV.OffCenterProjectionOffset
        log("ViewTarget.POV.OffCenterProjectionOffset=(%.4f, %.4f)", o.X, o.Y)
    end)
    for _, w in ipairs(FindAllOf("CrabCrosshairUI") or {}) do
        pcall(function()
            log("widget Y=%.1f %s", w.RenderTransform.Translation.Y, fullName(w))
        end)
    end
    log("----------------")
end

-- ---- game-thread triggers ----------------------------------------------

RegisterInitGameStatePostHook(applyAll)

local last_beginplay = 0.0
RegisterBeginPlayPostHook(function()
    local now = os.clock()
    if now - last_beginplay < CONFIG.beginplay_throttle then return end
    last_beginplay = now
    applyAll()
end)

-- ---- keys: one game-thread hop per press -------------------------------

local function onKey(fn)
    return function()
        ExecuteInGameThread(function()
            pcall(fn)
            applyAll()
        end)
    end
end

RegisterKeyBind(Key.F7, onKey(function()
    offset_y = offset_y - CONFIG.step
    log("offset_y = %.1f", offset_y)
end))
RegisterKeyBind(Key.F8, onKey(function()
    offset_y = offset_y + CONFIG.step
    log("offset_y = %.1f", offset_y)
end))
RegisterKeyBind(Key.F9, onKey(function()
    offset_y = CONFIG.offset_y
    log("offset_y = %.1f", offset_y)
end))
RegisterKeyBind(Key.F10, onKey(function()
    shift_enabled = not shift_enabled
    log("image shift %s", shift_enabled and "ON" or "OFF")
end))
RegisterKeyBind(Key.F6, onKey(status))

log("loaded (offset_y=%.1f)", offset_y)
