#!/bin/bash

sci home

# swipe left
sleep 0.5s
sci swipe 100 1000 700 1000 300

# swipe left
sleep 0.5s
sci swipe 100 1000 700 1000 300

# swipe left
sleep 0.5s
sci swipe 100 1000 700 1000 300

#swipe right
sleep 0.5s
sci swipe 700 900 100 900 300

# Open Panther browser (top left app)
sleep 1s
sci tap 279 396

# Tap omnibox
sleep 4s
sci tap 215 120

# Delete url
sleep 1s
sci keyboard SCI_SPECIAL_BACKSPACE

# Write url
sleep 0.7s
sci keyboard 'https://foro.elhacker.net/'

# Press Go Button
sleep 0.2
sci tap 672 119

sleep 5s
# Press cancel tapatalk button
sci tap 219 854

# Scroll down
sleep 1s
sci swipe 390 1300 390 800 300

sleep 0.2s
# Click Mas Estadisticas
sci tap 80 1449

# Click Panther Menu Icon
sleep 0.1s
sci tap 53 113

# Scroll Menu down
sleep 0.3s
sci swipe 150 450 150 50 300

# Press Exit to close Panther
sleep 4s
sci tap 141 522

# Press Termux icon
sleep 0.8s
sci tap 98 1434




