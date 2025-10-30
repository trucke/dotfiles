if ! command -v git &>/dev/null; then
    sudo pacman -S -q --needed --noconfirm git >/dev/null
fi

if ! command -v paru &>/dev/null; then
    temp_dir=$(mktemp -d)
    trap "rm -rf \"$temp_dir\"" EXIT
    cd "$temp_dir"
    git clone --quiet https://aur.archlinux.org/paru-bin.git
    cd paru-bin
    makepkg -si --noconfirm
    paru --gendb
    paru -Syu --devel --noconfirm >/dev/null
    echo "AUR helper 'paru' installed"
fi
