# dotfiles

WSL (Ubuntu/Debian 系) 用の dotfiles。シンボリックリンク方式で管理します。

## 構成

```
dotfiles/
├── install.sh              # セットアップスクリプト(冪等)
├── agents/
│   └── AGENTS.md           # AI エージェント共通グローバルルール(GEMINI.md / CLAUDE.md へリンク)
├── bash/
│   ├── .bashrc             # bash 本体設定(履歴・プロンプト・fzf・WSL 連携)
│   └── .bash_aliases       # エイリアス(eza / bat / git ショートカット等)
├── gemini/
│   └── permissions.json    # Gemini (Antigravity CLI) の allow / deny / ask 権限定義
├── git/
│   ├── .gitconfig          # git 設定(エイリアス・WSL 向け autocrlf 等。user は ~/.gitconfig.local へ)
│   └── .gitignore_global   # 全リポジトリ共通 ignore
├── nvim/
│   └── .config/nvim/
│       ├── init.lua        # Neovim 設定(lazy.nvim + 基本プラグイン)
│       └── lazy-lock.json  # プラグインのバージョン固定(lockfile)
└── starship/
    └── .config/
        └── starship.toml   # starship プロンプト設定
```

## Windows 側の準備

WSL 内のセットアップとは別に、Windows 側で以下をやっておくと快適です。

### Nerd Font のインストール(推奨)

starship のアイコン・eza の `--icons`・nvim の lualine はNerd Font 前提です。
PowerShell で:

```powershell
winget install --id DEVCOM.JetBrainsMonoNerdFont
```

インストール後、フォントを設定します。

- **Windows Terminal**: 設定 → プロファイル (Ubuntu) → 外観 → フォントフェイス → `JetBrainsMono Nerd Font`
- **VS Code**: `settings.json` に `"terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"`

フォントが無くてもプロンプト等は動作します(アイコンが「□」に化けるだけ)。

### VS Code は WSL モードで使う

VS Code に **WSL 拡張機能**(Microsoft 製「WSL」)を入れ、WSL 内のリポジトリは
WSL のターミナルから `code .` で開きます(ウィンドウ左下に「WSL: Ubuntu」と出ていれば OK)。

Windows 側から直接開くと git / SSH が **Windows 側のもの**で動くため、
SSH 鍵が WSL 内にしか無い場合 `git push` が Permission denied になります。

### SSH 鍵は WSL 側で作る

GitHub 用の SSH 鍵は WSL 内で作成・登録します(Windows 側との二重管理を避けるため)。

```bash
ssh-keygen -t ed25519 -C "you@example.com"
cat ~/.ssh/id_ed25519.pub   # これを GitHub → Settings → SSH keys に登録
```

## セットアップ

```bash
git clone <このリポジトリのURL> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` は以下を行います。

1. apt パッケージのインストール — git, curl, build-essential, ripgrep, fzf, fd-find, bat, jq, tree, htop, bash-completion, wslu, dnsutils (dig/nslookup/host), whois, eza
2. GitHub CLI (`gh`)・**starship**(プロンプト)のインストール
3. Neovim 最新安定版のインストール(GitHub Releases から /opt/nvim へ)
4. win32yank のインストール(WSL ↔ Windows クリップボード連携)
5. **Node.js LTS** のインストール(nvm 経由。corepack 有効化で pnpm / yarn も利用可)
6. **Docker Engine** のインストール(WSL ネイティブ。docker compose / buildx プラグイン付き)
7. **Claude Code** のインストール(公式インストーラ。`~/.local/bin/claude`。初回は `claude` 実行でログイン)
8. シンボリックリンクの作成(既存ファイルは `~/.dotfiles_backup/<日時>/` に退避)
   - `agents/AGENTS.md` を `~/.gemini/GEMINI.md` と `~/.claude/CLAUDE.md` の両方にリンク
   - `~/.agents/skills/*` の共通スキルを `~/.gemini/config/skills/` と `~/.claude/skills/` の両方にリンク
9. **Gemini (`agy`) の権限設定マージ**(`gemini/permissions.json` を `jq` で `~/.gemini/antigravity-cli/settings.json` に安全にマージ)

### Docker についての注意

- Docker Desktop を既に使っている場合、`docker` コマンドが見えていれば Engine のインストールは自動でスキップされます。
- `sudo` なしで docker を使うにはインストール後に一度 WSL を再起動してください(`wsl --shutdown`)。
- systemd が無効な場合はスクリプトが案内を表示します(`/etc/wsl.conf` に `[boot] systemd=true` を追記)。

### Node.js について

- `nvm install 22` などで別バージョンも追加できます。デフォルトは LTS に設定されます。
- プロジェクトに `.nvmrc` があれば `nvm use` で切り替えられます。

なお、実行の最初に `apt update` + `apt upgrade` で既存パッケージも最新化します。

オプション:

```bash
./install.sh --no-upgrade  # apt upgrade をスキップ(インストールとリンクは行う)
./install.sh --link-only   # リンクだけ張り直す(sudo 不要)
```

何度実行しても安全です(冪等)。

## マシン固有の設定

git 管理したくない設定は以下のファイルに書きます(存在すれば自動で読み込まれます)。

- `~/.bashrc.local` — マシン固有のシェル設定
- `~/.gitconfig.local` — マシン固有の git 設定

**git の名前・メールアドレス**はリポジトリにコミットしないよう、
`.gitconfig` ではなく `~/.gitconfig.local` に保存します。
未設定の場合は `install.sh` 実行時に対話で入力を求められます(空 Enter でスキップ可)。
後から設定・変更する場合は:

```bash
git config --file ~/.gitconfig.local user.name "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

## Neovim

初回起動時に lazy.nvim とプラグインが自動インストールされます。
`lazy-lock.json` をコミットしているので、`:Lazy restore` で
このリポジトリと同じプラグインバージョンに揃えられます
(プラグイン更新後は変化した `lazy-lock.json` をコミットしてください)。

主なキーマップ(Leader = Space):

- `Space ff` ファイル検索 / `Space fg` 全文検索(Telescope)
- `gcc` コメントトグル
- `Ctrl-h/j/k/l` ウィンドウ移動
