mkdir -p ~/.config
stow --restow --dir="${OMARCHY_PATH}" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}" zshrc
#sudo chsh -s /usr/bin/zsh $USER
