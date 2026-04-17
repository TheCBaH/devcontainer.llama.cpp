#!/bin/sh
set -eu
#set -x

build_type="${1:?build_type required}"
shift
bin_dir="llama.cpp/build.$build_type/bin"

bench_args="-p 1000 -n 50 -d 0,1000,2000,3000,4000,5000"
case "${1:-}" in
    --fast) bench_args="-p 512 -n 10"; shift ;;
esac

models_dir="${LLAMA_CACHE:-${HOME}/.cache/huggingface/hub}"

for model_dir in $(du -s "$models_dir"/models--* | sort -n | awk '{print $2}'); do
    [ -d "$model_dir" ] || continue

    base="$(basename "$model_dir")"
    hf_id="$(echo "$base" | sed 's/^models--//; s/--/\//')"

    if [ $# -gt 0 ]; then
        match=0
        for filter in "$@"; do
            case "$hf_id" in *"$filter"*) match=1; break ;; esac
        done
        [ $match -eq 1 ] || continue
    fi

    gguf="$(find "$model_dir" -name "*.gguf" ! -name "mmproj*" | head -1)"
    [ -n "$gguf" ] || continue
    pattern="$(basename "$gguf" .gguf)"

    "$bin_dir/llama-bench" -hf "$hf_id:$pattern" $bench_args
done
