#!/usr/bin/env bash
#
# install.sh — WSL (Ubuntu/Debian 系) 用 dotfiles セットアップスクリプト
#
# 使い方:
#   ./install.sh               # apt upgrade + パッケージインストール + リンク作成
#   ./install.sh --no-upgrade  # apt upgrade をスキップ(update とインストールは行う)
#   ./install.sh --link-only   # シンボリックリンク作成のみ(sudo 不要)
#
# 何度実行しても安全(冪等)です。既存の設定ファイルは
# ~/.dotfiles_backup/<日時>/ に退避してからリンクを張ります。

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
LINK_ONLY=false
DO_UPGRADE=true

for arg in "$@"; do
    case "$arg" in
        --link-only)  LINK_ONLY=true ;;
        --no-upgrade) DO_UPGRADE=false ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; exit 1 ;;
    esac
done

info()  { printf '\e[32m[INFO]\e[0m %s\n' "$1"; }
warn()  { printf '\e[33m[WARN]\e[0m %s\n' "$1"; }

# ----------------------------------------------------------------------
# 1. パッケージインストール
# ----------------------------------------------------------------------
install_packages() {
    if ! command -v apt-get >/dev/null 2>&1; then
        warn "apt-get が見つかりません。パッケージインストールをスキップします。"
        return
    fi

    info "apt パッケージを更新・インストールします(sudo が必要です)..."
    sudo apt-get update -qq

    if [ "$DO_UPGRADE" = true ]; then
        info "既存パッケージをアップグレードします(--no-upgrade でスキップ可)..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
            || warn "apt upgrade に失敗しました(続行します)"
    fi

    # 基本ツール + モダン CLI ツール
    # 1つずつインストールする(一括だと存在しないパッケージが1つあるだけで全滅するため)
    local pkgs=(ca-certificates gnupg build-essential curl wget git unzip bash-completion
                ripgrep fzf fd-find bat jq tree htop wslu dnsutils whois)
    local failed=()
    local pkg
    for pkg in "${pkgs[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            continue  # インストール済み
        fi
        sudo apt-get install -y -qq "$pkg" >/dev/null 2>&1 || failed+=("$pkg")
    done
    if [ ${#failed[@]} -gt 0 ]; then
        warn "インストールできなかったパッケージ: ${failed[*]}(続行します)"
    fi

    # eza(モダンな ls。apt に無い場合は公式リポジトリから)
    if ! command -v eza >/dev/null 2>&1; then
        if ! sudo apt-get install -y -qq eza 2>/dev/null; then
            info "eza を公式リポジトリからインストールします..."
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
                | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
                | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
            sudo apt-get update -qq && sudo apt-get install -y -qq eza \
                || warn "eza のインストールに失敗しました(続行します)"
        fi
    fi

    # Neovim(apt 版は古いことが多いので、最新安定版を GitHub Releases から)
    if ! command -v nvim >/dev/null 2>&1; then
        info "Neovim (最新安定版) をインストールします..."
        local arch tarball
        arch="$(uname -m)"
        case "$arch" in
            x86_64)  tarball="nvim-linux-x86_64.tar.gz" ;;
            aarch64) tarball="nvim-linux-arm64.tar.gz" ;;
            *)       warn "未対応アーキテクチャ ($arch)。apt 版 neovim を入れます。"
                     sudo apt-get install -y -qq neovim; return ;;
        esac
        curl -fsSL -o "/tmp/$tarball" \
            "https://github.com/neovim/neovim/releases/latest/download/$tarball" \
            && sudo rm -rf /opt/nvim \
            && sudo tar -C /opt -xzf "/tmp/$tarball" \
            && sudo mv /opt/nvim-linux-* /opt/nvim \
            && sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim \
            && rm -f "/tmp/$tarball" \
            || { warn "GitHub からの取得に失敗。apt 版 neovim を入れます。"; sudo apt-get install -y -qq neovim; }
    fi

    # 日本語ロケールの生成(.bashrc の LANG=ja_JP.UTF-8 用)
    if ! locale -a 2>/dev/null | grep -qi '^ja_JP\.utf-\?8$'; then
        info "日本語ロケール (ja_JP.UTF-8) を生成します..."
        sudo locale-gen ja_JP.UTF-8 >/dev/null 2>&1 \
            && info "ja_JP.UTF-8 を生成しました" \
            || warn "ロケール生成に失敗しました(続行します)"
    fi

    # GitHub CLI (gh)
    if ! command -v gh >/dev/null 2>&1; then
        info "GitHub CLI をインストールします..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update -qq && sudo apt-get install -y -qq gh \
            || warn "gh のインストールに失敗しました(続行します)"
    fi

    # starship(プロンプトカスタマイズ)
    if ! command -v starship >/dev/null 2>&1; then
        info "starship をインストールします..."
        curl -fsSL https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1 \
            || warn "starship のインストールに失敗しました(続行します)"
    fi

    # win32yank(WSL で Neovim のクリップボード連携に使用)
    if grep -qi microsoft /proc/version 2>/dev/null && ! command -v win32yank.exe >/dev/null 2>&1; then
        info "win32yank をインストールします(Neovim のクリップボード連携用)..."
        mkdir -p "$HOME/.local/bin"
        curl -fsSL -o /tmp/win32yank.zip \
            "https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip" \
            && unzip -o -q /tmp/win32yank.zip -d /tmp/win32yank \
            && install -m 755 /tmp/win32yank/win32yank.exe "$HOME/.local/bin/win32yank.exe" \
            && rm -rf /tmp/win32yank /tmp/win32yank.zip \
            || warn "win32yank のインストールに失敗しました(続行します)"
    fi

    info "パッケージインストール完了"
}

# ----------------------------------------------------------------------
# 2. Node.js LTS(nvm 経由)
# ----------------------------------------------------------------------
install_node() {
    export NVM_DIR="$HOME/.nvm"

    if [ ! -d "$NVM_DIR" ]; then
        info "nvm をインストールします..."
        # 最新の nvm を取得(バージョンは GitHub API から解決、失敗時は固定版)
        local nvm_ver
        nvm_ver="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null \
            | grep -oP '"tag_name":\s*"\K[^"]+' || echo 'v0.40.3')"
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_ver/install.sh" | PROFILE=/dev/null bash \
            || { warn "nvm のインストールに失敗しました(Node のセットアップをスキップ)"; return; }
    fi

    # このスクリプト内で nvm を読み込む
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    if command -v nvm >/dev/null 2>&1; then
        info "Node.js LTS をインストールします..."
        nvm install --lts >/dev/null
        nvm alias default 'lts/*' >/dev/null
        info "Node $(node --version) / npm $(npm --version) をインストールしました"

        # corepack を有効化(pnpm / yarn を使えるように)
        corepack enable 2>/dev/null && info "corepack を有効化しました (pnpm / yarn が使えます)" \
            || warn "corepack の有効化に失敗しました(続行します)"
    fi
}

# ----------------------------------------------------------------------
# 3. Docker Engine(WSL ネイティブ)
# ----------------------------------------------------------------------
install_docker() {
    # Docker Desktop の WSL 連携などで既に docker が使える場合はスキップ
    if command -v docker >/dev/null 2>&1; then
        info "docker は既に利用可能です($(docker --version 2>/dev/null || echo 'version 不明'))。スキップします。"
        return
    fi

    info "Docker Engine をインストールします..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    if ! sudo apt-get update -qq || ! sudo apt-get install -y -qq \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        warn "Docker のインストールに失敗しました(続行します)"
        return
    fi

    # sudo なしで docker を使えるように
    sudo usermod -aG docker "$USER"
    info "ユーザー $USER を docker グループに追加しました(反映には WSL の再起動が必要です)"

    # systemd が有効なら自動起動を設定
    if [ -d /run/systemd/system ]; then
        sudo systemctl enable --now docker >/dev/null 2>&1 \
            && info "docker サービスを有効化しました" \
            || warn "docker サービスの起動に失敗しました"
    else
        warn "systemd が無効のようです。/etc/wsl.conf に以下を追記して 'wsl --shutdown' 後に再起動してください:"
        printf '    [boot]\n    systemd=true\n'
    fi
}

# ----------------------------------------------------------------------
# 4. Claude Code
# ----------------------------------------------------------------------
install_claude_code() {
    if command -v claude >/dev/null 2>&1; then
        info "Claude Code は既にインストール済みです($(claude --version 2>/dev/null || echo 'version 不明'))。スキップします。"
        return
    fi

    info "Claude Code をインストールします..."
    if curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1; then
        info "Claude Code をインストールしました ($HOME/.local/bin/claude)"
        info "初回は 'claude' を実行してログインしてください。"
    else
        warn "Claude Code のインストールに失敗しました(続行します)"
    fi
}

# ----------------------------------------------------------------------
# 5. git ユーザー設定(~/.gitconfig.local)
# ----------------------------------------------------------------------
setup_git_user() {
    local conf="$HOME/.gitconfig.local"
    local name email
    name="$(git config --file "$conf" user.name 2>/dev/null || true)"
    email="$(git config --file "$conf" user.email 2>/dev/null || true)"

    if [ -n "$name" ] && [ -n "$email" ]; then
        info "git ユーザー設定済み: $name <$email> (~/.gitconfig.local)"
        return
    fi

    # 非対話実行時(CI やパイプ経由)は案内だけ出して続行
    if [ ! -t 0 ]; then
        warn "~/.gitconfig.local に git のユーザー情報がありません。後で設定してください:"
        printf '    git config --file ~/.gitconfig.local user.name "Your Name"\n'
        printf '    git config --file ~/.gitconfig.local user.email "you@example.com"\n'
        return
    fi

    info "git のユーザー情報を設定します(~/.gitconfig.local に保存。空 Enter でスキップ)"
    local input
    read -rp "  user.name : " input
    if [ -n "$input" ]; then
        git config --file "$conf" user.name "$input"
        name="$input"
    fi
    read -rp "  user.email: " input
    if [ -n "$input" ]; then
        git config --file "$conf" user.email "$input"
        email="$input"
    fi

    if [ -n "$name" ] && [ -n "$email" ]; then
        info "設定しました: $name <$email>"
    else
        warn "未設定の項目があります。後で上記コマンドか再実行で設定できます。"
    fi
}

# ----------------------------------------------------------------------
# 6. シンボリックリンク作成
# ----------------------------------------------------------------------
link_file() {
    local src="$1" dest="$2"

    # 既に正しいリンクが張られていれば何もしない
    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
        info "OK: $dest (リンク済み)"
        return
    fi

    # 既存ファイル/リンクは $HOME からの相対パス構造を保ってバックアップへ退避
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        local rel="${dest#"$HOME"/}"
        if [ "$rel" = "$dest" ]; then
            rel="${dest#/}"
        fi
        local backup_target="$BACKUP_DIR/$rel"
        mkdir -p "$(dirname "$backup_target")"
        mv "$dest" "$backup_target"
        warn "退避: $dest -> $backup_target"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    info "リンク作成: $dest -> $src"
}

create_links() {
    info "シンボリックリンクを作成します..."

    # bash
    link_file "$DOTFILES_DIR/bash/.bashrc"        "$HOME/.bashrc"
    link_file "$DOTFILES_DIR/bash/.bash_aliases"  "$HOME/.bash_aliases"

    # git
    link_file "$DOTFILES_DIR/git/.gitconfig"        "$HOME/.gitconfig"
    link_file "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

    # nvim
    link_file "$DOTFILES_DIR/nvim/.config/nvim" "$HOME/.config/nvim"

    # starship
    link_file "$DOTFILES_DIR/starship/.config/starship.toml" "$HOME/.config/starship.toml"

    # AI Agents (共通グローバルルール AGENTS.md -> Gemini / Claude 両方へリンク)
    link_file "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.gemini/GEMINI.md"
    link_file "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"

    # ~/.agents/skills/* の共通スキルを Gemini / Claude 両方の skills ディレクトリへリンク
    if [ -d "$HOME/.agents/skills" ]; then
        mkdir -p "$HOME/.gemini/config/skills" "$HOME/.claude/skills"
        local skill_dir skill_name
        for skill_dir in "$HOME/.agents/skills"/*; do
            # シンボリックリンク(別名エイリアス等)や SKILL.md が無いものはスキップ
            [ -d "$skill_dir" ] && [ ! -L "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || continue
            skill_name="$(basename "$skill_dir")"
            link_file "$skill_dir" "$HOME/.gemini/config/skills/$skill_name"
            link_file "$skill_dir" "$HOME/.claude/skills/$skill_name"
        done
    fi

    info "リンク作成完了"
}

# ----------------------------------------------------------------------
# 7. Gemini (Antigravity CLI) permissions 設定の同期
# ----------------------------------------------------------------------
setup_gemini_settings() {
    local perm_file="$DOTFILES_DIR/gemini/permissions.json"
    local local_perm_file="$HOME/.gemini/permissions.local.json"
    local target="$HOME/.gemini/antigravity-cli/settings.json"

    if [ ! -f "$perm_file" ]; then
        return
    fi
    if ! command -v jq >/dev/null 2>&1; then
        warn "jq が見つからないため、Gemini settings.json の更新をスキップします。"
        return
    fi

    local existing_json='{}'
    if [ -s "$target" ]; then
        existing_json="$(cat "$target")"
    fi

    local local_perms='{}'
    if [ -s "$local_perm_file" ]; then
        local_perms="$(cat "$local_perm_file")"
    fi

    # permissions 以外の既存設定(モデル設定等)は保持しつつ、
    # permissions.{allow,deny,ask} は dotfiles 側(+ ~/.gemini/permissions.local.json)で同期上書きする
    local merged
    merged="$(jq -n \
        --argjson existing "$existing_json" \
        --slurpfile dotfiles "$perm_file" \
        --argjson local_cfg "$local_perms" '
        $dotfiles[0] as $df |
        ($local_cfg.permissions // $local_cfg) as $lp |
        ($existing * {
            "$schema": $df."$schema",
            "permissions": {
                "allow": ((($df.permissions.allow // []) + ($lp.allow // [])) | unique),
                "deny":  ((($df.permissions.deny  // []) + ($lp.deny  // [])) | unique),
                "ask":   ((($df.permissions.ask   // []) + ($lp.ask   // [])) | unique)
            }
        })
    ')"

    mkdir -p "$(dirname "$target")"
    if [ ! -f "$target" ]; then
        printf '%s\n' "$merged" > "$target"
        chmod 600 "$target"
        info "Gemini 設定を作成しました: $target"
        return
    fi

    if [ "$merged" = "$existing_json" ]; then
        info "OK: $target (permissions 同期済み)"
        return
    fi

    local backup_target="$BACKUP_DIR/.gemini/antigravity-cli/settings.json"
    mkdir -p "$(dirname "$backup_target")"
    cp -p "$target" "$backup_target"
    printf '%s\n' "$merged" > "$target"
    chmod 600 "$target"
    info "Gemini permissions を同期しました: $target"
}

# ----------------------------------------------------------------------
# main
# ----------------------------------------------------------------------
main() {
    info "dotfiles ディレクトリ: $DOTFILES_DIR"

    if [ "$LINK_ONLY" = false ]; then
        install_packages
        install_node
        install_docker
        install_claude_code
    else
        info "--link-only: パッケージインストールをスキップします"
    fi

    create_links
    setup_gemini_settings

    # git のユーザー情報はリポジトリに含めないため、~/.gitconfig.local に書く
    setup_git_user

    echo
    info "セットアップ完了! 'source ~/.bashrc' するか、新しいシェルを開いてください。"
    info "Neovim を初回起動するとプラグインが自動インストールされます。"
    if [ -d "$BACKUP_DIR" ]; then
        info "既存の設定は $BACKUP_DIR に退避しました。"
    fi
}

main
