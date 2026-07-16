#!/usr/bin/env bash
set -euo pipefail

action="${1:-status}"
mode="${2:-desktop}"
audio="${3:-none}"
monitor="${4:-AUTO}"
delay="${5:-0}"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ayame-shell"
videos_dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
state_file="$state_dir/recording.state"
log_file="$state_dir/recording.log"
mkdir -p "$state_dir" "$videos_dir"

read_state() {
    [[ -f "$state_file" ]] || return 1
    IFS='|' read -r recorder_pid output started < "$state_file"
    [[ "$recorder_pid" =~ ^[0-9]+$ ]] || return 1
}

is_recording() {
    read_state && kill -0 "$recorder_pid" 2>/dev/null
}

stop_recording() {
    if ! is_recording; then
        rm -f "$state_file"
        echo "No recording is active"
        return 0
    fi
    kill -INT "$recorder_pid" 2>/dev/null || true
    for _ in {1..50}; do
        kill -0 "$recorder_pid" 2>/dev/null || break
        sleep 0.1
    done
    rm -f "$state_file"
    notify-send -a "Ayame Recorder" -i video-x-generic \
        "Recording saved" "$output" 2>/dev/null || true
    printf '%s\n' "$output"
}

case "$action" in
    status)
        if is_recording; then
            printf 'recording|%s|%s\n' "$output" "$started"
        else
            rm -f "$state_file"
            echo "idle||"
        fi
        ;;
    stop)
        stop_recording
        ;;
    toggle)
        if is_recording; then
            stop_recording
            exit 0
        fi
        action=start
        ;&
    start)
        command -v wf-recorder >/dev/null 2>&1 || {
            echo "wf-recorder is not installed" >&2
            exit 1
        }
        if is_recording; then
            echo "A recording is already active" >&2
            exit 1
        fi
        output="$videos_dir/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
        [[ "$delay" =~ ^[0-9]+$ ]] || delay=0
        if ((delay > 0)); then
            sleep "$delay"
        fi
        args=(-f "$output" -r 60 -c libx264 -p preset=veryfast -p crf=20 -y)
        case "$mode" in
            desktop) ;;
            monitor)
                if [[ -z "$monitor" || "$monitor" == AUTO ]]; then
                    monitor=$(hyprctl monitors 2>/dev/null | awk '
                        /^Monitor / { current=$2 }
                        /^[[:space:]]*focused: yes/ { print current; exit }
                    ')
                fi
                [[ -n "$monitor" ]] || { echo "No monitor was detected" >&2; exit 2; }
                args+=(-o "$monitor")
                ;;
            area)
                geometry=$(slurp -d -b '#00000099' -c '#ff6b81ff' -s '#ff6b8144' -w 3) || exit 0
                [[ -n "$geometry" ]] || exit 0
                args+=(-g "$geometry")
                ;;
            *) echo "Unknown recording mode: $mode" >&2; exit 2 ;;
        esac
        case "$audio" in
            none) ;;
            microphone) args+=(-a) ;;
            system)
                sink=$(pactl get-default-sink 2>/dev/null || true)
                [[ -n "$sink" ]] && args+=("--audio=${sink}.monitor") || args+=(-a)
                ;;
            *) echo "Unknown audio mode: $audio" >&2; exit 2 ;;
        esac
        setsid wf-recorder "${args[@]}" >"$log_file" 2>&1 &
        recorder_pid=$!
        started=$(date +%s)
        printf '%s|%s|%s\n' "$recorder_pid" "$output" "$started" > "$state_file"
        sleep 0.4
        if ! kill -0 "$recorder_pid" 2>/dev/null; then
            rm -f "$state_file"
            tail -n 3 "$log_file" >&2
            exit 1
        fi
        notify-send -a "Ayame Recorder" -i media-record \
            "Recording started" "Click the red top-bar pill to stop" 2>/dev/null || true
        printf '%s\n' "$output"
        ;;
    *) echo "Usage: $0 {start|stop|toggle|status} [desktop|monitor|area] [none|system|microphone] [monitor]" >&2; exit 2 ;;
esac
