-- CachyOS Hyprland Modular Master Configuration
-- 3-Tier Architecture: Core + Hardware Profile + Dynamic Personalization

-- 1. Universal Core Variables & Optional Profile Variable Overrides
require("config.variables")
pcall(require, "config.profile.variables")

-- 2. Universal Core Modules
require("config.animations")
require("config.colors")
require("config.decorations")
require("config.misc")
require("config.windowrules")
require("config.workspaces")
require("config.binds")

-- 3. Base Fallback Configurations (Safe defaults for any PC)
require("config.environment")
require("config.inputs")
require("config.monitors")
require("config.autostart")

-- 4. Hardware Profile Overrides (dynamically loaded if active profile provides them)
pcall(require, "config.profile.environment")
pcall(require, "config.profile.monitors")
pcall(require, "config.profile.inputs")
pcall(require, "config.profile.autostart")
pcall(require, "config.profile.binds")
