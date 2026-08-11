source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
function fish_greeting
    fastfetch-custom
end

# opencode
fish_add_path /home/user/.opencode/bin


# Environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim

# Added by Antigravity CLI installer
set -gx PATH "/home/user/.local/bin" $PATH
