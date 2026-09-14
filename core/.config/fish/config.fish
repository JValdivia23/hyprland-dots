# Source CachyOS fish defaults if available
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# Fastfetch greeting
function fish_greeting
    if command -v fastfetch-custom &>/dev/null
        fastfetch-custom
    end
end

# Opencode path
if test -d "$HOME/.opencode/bin"
    fish_add_path "$HOME/.opencode/bin"
end

# Environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim

# Local bin path
fish_add_path "$HOME/.local/bin"
