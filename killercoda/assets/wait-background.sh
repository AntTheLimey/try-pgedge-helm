#!/bin/bash
# Waits for the background installer to finish.
# Killercoda copies this to /usr/local/bin with +x via index.json assets.

spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
i=0
while [ ! -f /tmp/.background-done ]; do
  printf "\r  ${spinner[$i]} Installing components..."
  i=$(( (i + 1) % ${#spinner[@]} ))
  sleep 0.3
done
printf "\r  ✓ All components installed.         \n"
