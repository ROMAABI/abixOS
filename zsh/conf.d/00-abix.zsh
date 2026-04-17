#!/usr/bin/env zsh

#! ██████╗░░█████╗░  ███╗░░██╗░█████╗░████████╗  ███████╗██████╗░██╗████████╗
#! ██╔══██╗██╔══██╗  ████╗░██║██╔══██╗╚══██╔══╝  ██╔════╝██╔══██╗██║╚══██╔══╝
#! ██║░░██║██║░░██║  ██╔██╗██║██║░░██║░░░██║░░░  █████╗░░██║░░██║██║░░░██║░░░
#! ██║░░██║██║░░██║  ██║╚████║██║░░██║░░░██║░░░  ██╔══╝░░██║░░██║██║░░░██║░░░
#! ██████╔╝╚█████╔╝  ██║░╚███║╚█████╔╝░░░██║░░░  ███████╗██████╔╝██║░░░██║░░░
#! ╚═════╝░░╚════╝░  ╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░  ╚══════╝╚═════╝░╚═╝░░░╚═╝░░░


# Sources vital global environment variables and configurations // Users are encouraged to use ./user.zsh for customization
# shellcheck disable=SC1091
if ! . "$ZDOTDIR/conf.d/abix/env.zsh"; then
    echo "Error: Could not source $ZDOTDIR/conf.d/abix/env.zsh"
    return 1
fi

if [[ $- == *i* ]] && [ -f "$ZDOTDIR/conf.d/abix/terminal.zsh" ]; then
    . "$ZDOTDIR/conf.d/abix/terminal.zsh" || echo "Error: Could not source $ZDOTDIR/conf.d/abix/terminal.zsh"
fi
