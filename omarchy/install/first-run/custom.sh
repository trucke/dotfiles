# change default shell to zsh 
sudo chsh -s /usr/bin/zsh $USER
# install configured dev tools
mise install
# cleanup home directory
rm -rf $HOME/go $HOME/.cargo

