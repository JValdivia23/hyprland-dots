-- Enable adjacent files in directory
swayimg.imagelist.enable_adjacent(true)

-- Reset built-in default keybindings
swayimg.viewer.bind_reset()

-- Allow dragging window with left mouse button
swayimg.viewer.set_drag_button("MouseLeft")

-- Exit shortcuts
swayimg.viewer.on_key("space", function() swayimg.exit() end)
swayimg.viewer.on_key("Escape", function() swayimg.exit() end)
swayimg.viewer.on_key("q", function() swayimg.exit() end)

-- Arrow key & Vim key navigation (Next image)
swayimg.viewer.on_key("Right", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("right", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("Down", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("down", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("l", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("j", function() swayimg.viewer.switch_image("next") end)

-- Arrow key & Vim key navigation (Previous image)
swayimg.viewer.on_key("Left", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("left", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("Up", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("up", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("h", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("k", function() swayimg.viewer.switch_image("prev") end)
