-- CachyOS Hyprland Modular Master Configuration
-- 3-Tier Architecture: Core + Hardware Profile + Dynamic Personalization

-- 1. Universal Core Modules
require("config.animations")
require("config.colors")
require("config.decorations")
require("config.variables")
require("config.misc")
require("config.windowrules")
require("config.workspaces")
require("config.binds")

-- 2. Base Fallback Configurations (Safe defaults for any PC)
require("config.environment")
require("config.inputs")
require("config.monitors")
require("config.autostart")

-- 3. Hardware Profile Overrides (dynamically loaded if active profile provides them)
pcall(require, "config.profile.environment")
pcall(require, "config.profile.monitors")
pcall(require, "config.profile.inputs")
pcall(require, "config.profile.autostart")
pcall(require, "config.profile.binds")
