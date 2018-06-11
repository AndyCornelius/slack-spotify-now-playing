#!/bin/bash

APIKEY="you-api-key-here"
trap onexit INT

function getExistingStatus() {
    if [ ! -f status_text.txt ] || [ test `find "status_test.txt" -mmin +5` ]; then
        CURRENTPROFILE=$(curl -s "https://slack.com/api/users.profile.get?token="$APIKEY)
        STATUSEMOJI=$(php -r '$result = json_decode($argv[1], true); echo $result["profile"][$argv[2]];' "$CURRENTPROFILE" status_emoji)

        if [[ $STATUSEMOJI != "" && $STATUSEMOJI != ":headphones:" ]]; then
            echo $STATUSEMOJI > status_emoji.txt

            echo $(php -r '$result = json_decode($argv[1], true); echo $result["profile"][$argv[2]];' "$CURRENTPROFILE" status_text) > status_text.txt
        fi
    fi
}

function updateSlackStatus() {
    URLEMOJI=$(php -r 'echo rawurlencode($argv[1]);' "$2")
    URLTEXT=$(php -r 'echo rawurlencode($argv[1]);' "$1")

    curl -s -d "payload=$json" "https://slack.com/api/users.profile.set?token="$APIKEY"&profile=%7B%22status_text%22%3A%22"$URLTEXT"%22%2C%22status_emoji%22%3A%22"$URLEMOJI"%22%7D" > /dev/null
}

function reset() {
    if [ -f status_emoji.txt ]; then
        EMOJI=$(cat status_emoji.txt)
    else
        EMOJI=""
    fi

    if [ -f status_text.txt ]; then
        TEXT=$(cat status_text.txt)
    else
        TEXT=""
    fi

    updateSlackStatus "$TEXT" "$EMOJI"
}

function onexit() {
    reset

    rm -f status_*.txt
}

function runMainLogic() {
    if [[ $(osascript -e 'tell application "System Events" to get name of every process') = *"Slack"* ]]; then
        getExistingStatus

        if [[ $(osascript -e 'tell application "System Events" to get name of every process') = *"Spotify"* ]]; then
            STATE=$(osascript -e 'tell application "Spotify" to player state')

            if [[ "$STATE" != "playing" ]]; then
                reset
            else
                SONG=$(osascript -e 'tell application "Spotify" to artist of current track & " - " & name of current track')

                updateSlackStatus "$SONG" ":headphones:"
            fi
        else
            reset
        fi
    else
        rm -f status_*.txt
    fi
}

runMainLogic

sleep 30

runMainLogic
