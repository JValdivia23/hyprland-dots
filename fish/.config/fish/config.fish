source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
function fish_greeting
    fastfetch-custom
end

# opencode
fish_add_path "$HOME/.opencode/bin"

# Environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim

# Local bin path
fish_add_path "$HOME/.local/bin"
