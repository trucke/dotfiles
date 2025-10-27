if ! command -v paru &>/dev/null; then
    echo "Install AUR helper: paru"
    temp_dir=$(mktemp -d)
    pushd "$temp_dir"

    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin
    makepkg -si --noconfirm

    popd
    rm -rf "$temp_dir" && paru --gendb
    paru -Syu --devel --noconfirm
fi
