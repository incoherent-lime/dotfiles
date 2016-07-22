# Lime's Linux Look-alike of DesnudoPenguino's Dotfiles!
Currently a set of vim and tmux files, more will be added probably as time goes on.

I made this so I can have all my dev environments be the same. Make sure you set the terminal in your bash profile, or whatever profile you are using! This .tmux.conf is set up to run under *BSD so BASH is found in a different location.

Step 1. Clone this repo

git clone https://github.com/desnudopenguino/dotfiles.git dotfiles

Step 2. Run the install script

cd dotfiles && ./install.sh

Step 3. Update the TMUX plugins

tmux source ~/.tmux.conf
(inside TMUX) prefix + I (capital i, I)

Dependencies (and goodies used):
feh (for setting the background)
i3 (tiled WM)
Fluxbox (another WM)
Vim (text editer)
tmux (terminal multiplexer)
rxvt-unicode-256colors (terminal)
pcmanfm (file manager)
cadaver (dav CLI client)
git (of course!)
expect (automated CLI tool for in-program interaction)
ksh
NOTE: Make sure you have a full color term if you are planning on using 256-color stuff!
