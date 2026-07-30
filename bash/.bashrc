# ~/.bashrc — WSL 用 bash 設定
# 対話シェルでない場合は何もしない
case $- in
    *i*) ;;
    *) return ;;
esac

# ----------------------------------------------------------------------
# 履歴
# ----------------------------------------------------------------------
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups   # 重複と先頭スペース付きコマンドを記録しない
HISTTIMEFORMAT='%F %T '
shopt -s histappend                # 履歴を上書きせず追記
shopt -s cmdhist                   # 複数行コマンドを1エントリで保存

# ----------------------------------------------------------------------
# シェルオプション
# ----------------------------------------------------------------------
shopt -s checkwinsize              # ウィンドウサイズ変更を反映
shopt -s globstar 2>/dev/null      # ** による再帰グロブ
shopt -s autocd 2>/dev/null        # ディレクトリ名だけで cd
shopt -s cdspell 2>/dev/null       # cd のタイポを軽く補正

# ----------------------------------------------------------------------
# プロンプト
# starship があればそちらを使用(設定は ~/.config/starship.toml)。
# なければ git ブランチ表示付きのシンプルな PS1 にフォールバック。
# ----------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    __git_branch() {
        git symbolic-ref --short HEAD 2>/dev/null | sed 's/.*/ (&)/'
    }
    # 緑: user@host / 青: カレントディレクトリ / 黄: git ブランチ
    PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[33m\]$(__git_branch)\[\e[0m\]\$ '
fi

# ----------------------------------------------------------------------
# 環境変数
# ----------------------------------------------------------------------
export EDITOR=nvim
export VISUAL=nvim
# 日本語ロケールが生成済みなら使う。なければ C.UTF-8 にフォールバック
if locale -a 2>/dev/null | grep -qi '^ja_JP\.utf-\?8$'; then
    export LANG=ja_JP.UTF-8
else
    export LANG=C.UTF-8
fi
export LESS='-R -F -X'
export PATH="$HOME/.local/bin:$PATH"

# ----------------------------------------------------------------------
# 補完
# ----------------------------------------------------------------------
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# ----------------------------------------------------------------------
# fzf(インストールされていれば有効化)
# ----------------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash 2>/dev/null)" || {
        [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
        [ -f /usr/share/doc/fzf/examples/completion.bash ] && . /usr/share/doc/fzf/examples/completion.bash
    }
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    command -v rg >/dev/null 2>&1 && export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
fi

# ----------------------------------------------------------------------
# nvm (Node.js バージョン管理)
# ----------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# ----------------------------------------------------------------------
# WSL 固有設定
# ----------------------------------------------------------------------
if grep -qi microsoft /proc/version 2>/dev/null; then
    # Windows のエクスプローラーでカレントディレクトリを開く
    alias open='explorer.exe .'
    # クリップボード連携 (echo foo | clip)
    alias clip='clip.exe'
    # Windows 側ブラウザで URL を開く
    export BROWSER='wslview'
fi

# ----------------------------------------------------------------------
# エイリアス(別ファイル)
# ----------------------------------------------------------------------
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# ----------------------------------------------------------------------
# ローカル専用設定(git 管理外。マシン固有の設定はここに書く)
# ----------------------------------------------------------------------
[ -f ~/.bashrc.local ] && . ~/.bashrc.local
