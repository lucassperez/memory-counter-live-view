FROM elixir:1.17.3 AS base

WORKDIR /app

RUN apt update
RUN apt install -y inotify-tools
COPY mix.exs mix.lock /app
RUN mix deps.get
COPY . /app

EXPOSE 4000

RUN cat <<EOF >> /etc/bash.bashrc
alias ls='ls --color=auto -F --group-directories-first'
alias ll='ls -l -h'
alias la='ls -a'
alias lla='ls -l -h -a'
alias lal='ls -l -h -a'
PS1='${debian_chroot:+($debian_chroot)}\u@\h:\e[35m\w\e[0;1m \\$\e[0m '
EOF

CMD ["mix", "phx.server"]
