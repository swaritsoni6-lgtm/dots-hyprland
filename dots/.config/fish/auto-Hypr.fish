# Auto start Hyprland on tty1
if status is-login
    if test -z "$WAYLAND_DISPLAY" -a -z "$DISPLAY"
        if test (tty) = "/dev/tty1" -o "$XDG_VTNR" = 1
            mkdir -p ~/.cache
            exec start-hyprland > ~/.cache/hyprland.log 2>&1
        end
    end
end

