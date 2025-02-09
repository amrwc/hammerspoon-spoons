-- Quake Mode - show/hide an application with with a key binding.
-- Named after the game console toggled by ~ (tilde key) in Quake.
--
-- Usage inside the main `init.lua`:
-- hs.loadSpoon("QuakeMode")
-- spoon.QuakeMode:bind({
--     hotkey = {
--         modifiers = { "control", },
--         key = "`",
--     },
--     bundleId = "com.mitchellh.ghostty",
--     launchIfNeeded = true,
-- })

local SPOON = {}
SPOON.__index = SPOON

-- Metadata
SPOON.name = "QuakeMode"
SPOON.version = "1.1.0"
SPOON.author = "amrwc"
SPOON.homepage = "https://github.com/amrwc/hammerspoon-spoons"
SPOON.license = "MIT - https://opensource.org/licenses/MIT"

local logger = hs.logger.new(SPOON.name)
logger.setLogLevel("info")

local function log_info(content)
    logger.i(SPOON.name .. ": " .. content)
end
local function log_debug(content)
    logger.d(SPOON.name .. ": " .. content)
end
local function log_warn(content)
    logger.w(SPOON.name .. ": " .. content)
end
local function log_error(content)
    logger.e(SPOON.name .. ": " .. content)
end

local function validate_config_or_throw(config)
    local errors = {}
    local function append_missing_or_empty(prop)
        table.insert(errors, prop .. " missing or empty")
    end
    if not config.hotkey then
        append_missing_or_empty("hotkey")
    elseif not config.hotkey.key or #config.hotkey.key == 0 then
        append_missing_or_empty("hotkey.key")
    end
    if not config.bundleId or #config.bundleId == 0 then
        append_missing_or_empty("bundleId")
    end
    if #errors ~= 0 then
        error("Config validation failed, errors: " .. hs.inspect(errors))
    end
end

local function find_app_by_bundle_id(bundleId)
    local foundApps = hs.application.applicationsForBundleID(bundleId)
    if #foundApps == 0 then
        log_warn("No " .. bundleId .. " window was not found")
        return nil
    end
    return foundApps[1]
end

local function maybe_launch(bundleId)
    log_debug("Launching or focusing " .. bundleId)
    local succeeded = hs.application.launchOrFocusByBundleID(bundleId)
    if not succeeded then
        log_error("Failed to launch " .. bundleId)
    end
end

local function maybe_activate(app)
    log_debug("Activating " .. app:bundleID())
    local activationSucceeded = app:activate(true)
    if not activationSucceeded then
        log_error("Failed to activate " .. app:bundleID())
    end
end

local function maybe_hide(app)
    log_debug("Hiding " .. app:bundleID())
    local hidingSucceeded = app:hide()
    -- NOTE: Ignoring the success boolean because, for some reason,
    --       it returns false even when it works.
    -- if not hidingSucceeded then
    --     log_error("Failed to hide " .. app:bundleID())
    -- end
end

local function callback(config)
    local app = find_app_by_bundle_id(config.bundleId)
    if not app then
        if config.launchIfNeeded then
            log_info(config.bundleId .. " not running, launching it")
            maybe_launch(config.bundleId)
        end
        return
    end

    local frontmostApp = hs.application.frontmostApplication()
    if app:bundleID() == frontmostApp:bundleID() then
        log_debug(app:bundleID() .. " is the frontmost application, hiding it")
        maybe_hide(app)
        return
    end

    maybe_activate(app)
end

-- `config` example:
-- { hotkey = { modifiers = { "control", }, key = "`" }, bundleId = "com.mitchellh.ghostty", launchIfNeeded = true }
-- `modifiers` in `hotkey` is optional.
function SPOON:bind(config)
    validate_config_or_throw(config)
    hs.hotkey.bind(
        config.hotkey.modifiers,
        config.hotkey.key,
        function() callback(config) end
    )
end

function SPOON:init()
end

return SPOON

-- Changelog
--
-- 1.1.0:
-- - Define an validate the configuration passed in.
-- - Make launching the app configurable.
--
-- 1.0.0:
-- - Implement a working solution for focusing (showing) and hiding the given application’s windows.
