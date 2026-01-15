#!/bin/bash
# Blueprint Lock Library
# 跨平台鎖定機制（使用 mkdir atomic + PID tracking）

LOCK_DIR=".blueprint/.lock"
LOCK_STALE_THRESHOLD=60  # 秒

# 檢查是否為 stale lock
# 參數：$1 = lock 目錄路徑
# 返回：0 是 stale，1 不是 stale
is_stale_lock() {
    local lock_dir="$1"

    # 檢查 PID 檔案
    if [ ! -f "$lock_dir/pid" ]; then
        return 0
    fi

    local lock_pid=$(cat "$lock_dir/pid" 2>/dev/null)

    # 檢查 process 是否存在
    if ! kill -0 "$lock_pid" 2>/dev/null; then
        return 0
    fi

    # 檢查 timestamp（超過閾值視為異常）
    if [ -f "$lock_dir/timestamp" ]; then
        local lock_time=$(cat "$lock_dir/timestamp" 2>/dev/null)
        local current_time=$(date +%s)
        local age=$((current_time - lock_time))
        if [ $age -gt $LOCK_STALE_THRESHOLD ]; then
            return 0
        fi
    fi

    return 1
}

# 清理 stale lock
# 參數：$1 = lock 目錄路徑
# 返回：0 成功，1 失敗
cleanup_stale_lock() {
    local lock_dir="$1"
    rm -rf "$lock_dir" 2>/dev/null
    return $?
}

# 釋放鎖定
# 參數：無
# 返回：0 成功，1 失敗
release_lock() {
    local lock_dir="$LOCK_DIR"

    # 驗證是否為當前 process 持有
    if [ -f "$lock_dir/pid" ]; then
        local lock_pid=$(cat "$lock_dir/pid" 2>/dev/null)
        if [ "$lock_pid" = "$$" ]; then
            rm -rf "$lock_dir"
            trap - EXIT INT TERM
            return 0
        fi
    fi

    return 1
}

# 取得鎖定
# 參數：$1 = timeout（秒，預設 5）
# 返回：0 成功，1 失敗
acquire_lock() {
    local timeout="${1:-5}"
    local lock_dir="$LOCK_DIR"
    local start_time=$(date +%s)

    # 清理舊版 .lock 檔案（向後相容）
    if [ -f ".blueprint/.lock" ] && [ ! -d ".blueprint/.lock" ]; then
        rm -f ".blueprint/.lock" 2>/dev/null
    fi

    while true; do
        if mkdir "$lock_dir" 2>/dev/null; then
            # 成功建立鎖定目錄
            echo $$ > "$lock_dir/pid"
            date +%s > "$lock_dir/timestamp"
            trap 'release_lock' EXIT INT TERM
            return 0
        fi

        # 檢查是否為 stale lock
        if is_stale_lock "$lock_dir"; then
            cleanup_stale_lock "$lock_dir"
            continue
        fi

        # 檢查 timeout
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        if [ $elapsed -ge $timeout ]; then
            return 1
        fi

        sleep 0.1
    done
}
