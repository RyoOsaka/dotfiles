# dotfiles

WSL (Ubuntu/Debian 系) 用の dotfiles。シンボリックリンク方式で管理します。

## 構成

```
dotfiles/
├── install.sh              # セットアップスクリプト(冪等)
├── bash/
│   ├── .bashrc             # bash 本体設定(履歴・プロンプト・fzf・WSL 連携)
│   └── .bash_aliases       # エイリアス(eza / bat / git ショートカット等)
├── git/
│   ├── .gitconfig          # git 設定(エイリアス・WSL 向け autocrlf 等)
│   └── .gitignore_global   # 全リポジトリ共通 ignore
├── nvim/
│   └── .config/nvim/
│       └── init.lua        # Neovim 設定(lazy.nvim + 基本プラグイン)
└── starship/
    └── .config/
        └── starship.toml   # starship プロンプト設定
```

## セットアップ

```bash
git clone <このリポジトリのURL> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` は以下を行います。

1. apt パッケージのインストール — git, curl, build-essential, ripgrep, fzf, fd-find, bat, jq, tree, htop, bash-completion, wslu, eza
2. GitHub CLI (`gh`)・**starship**(プロンプト)のインストール
3. Neovim 最新安定版のインストール(GitHub Releases から /opt/nvim へ)
4. win32yank のインストール(WSL ↔ Windows クリップボード連携)
5. **Node.js LTS** のインストール(nvm 経由。corepack 有効化で pnpm / yarn も利用可)
6. **Docker Engine** のインストール(WSL ネイティブ。docker compose / buildx プラグイン付き)
7. シンボリックリンクの作成(既存ファイルは `~/.dotfiles_backup/<日時>/` に退避)

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
- `~/.gitconfig.local` — マシン固有の git 設定(仕事用メールアドレスなど)

## Neovim

初回起動時に lazy.nvim とプラグインが自動インストールされます。
主なキーマップ(Leader = Space):

- `Space ff` ファイル検索 / `Space fg` 全文検索(Telescope)
- `gcc` コメントトグル
- `Ctrl-h/j/k/l` ウィンドウ移動

## GitHub での管理を始めるには

```bash
cd ~/dotfiles
git init
git add -A
git commit -m "Initial dotfiles"
gh repo create dotfiles --private --source=. --push   # gh CLI がある場合
```
