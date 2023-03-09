#! /usr/bin/env sh

eval "fnm env --shell=bash --use-on-cd"

if test -f ".nvmrc"; then
  echo "setting node env"
  fnm use
fi
