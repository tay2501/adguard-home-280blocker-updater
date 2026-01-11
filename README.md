# AdGuard Home 280blocker Updater

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-brightgreen)](https://www.shellcheck.net/)
[![Google Shell Style](https://img.shields.io/badge/Style-Google-blue)](https://google.github.io/styleguide/shellguide.html)

AdGuard Home用の280blockerフィルタリストを自動更新するシェルスクリプト。
月次更新される280blockerのドメインフィルタを自動的にダウンロードし、AdGuard Homeに適用します。

## ✨ Features

- ✅ **FHS (Filesystem Hierarchy Standard) 準拠**: `/var/opt` にデータを配置
- ✅ **UNIX Philosophy**: "Silence is Golden" - 成功時は静か、失敗時のみエラー出力
- ✅ **Raspberry Pi最適化**: SDカード寿命保護（tmpfsの活用）、ARM最適化
- ✅ **Google Shell Style Guide 準拠**: モダンなBashプラクティス
- ✅ **Bash Strict Mode**: `set -euo pipefail` による堅牢なエラーハンドリング
- ✅ **変更検知**: 差分がない場合は書き込みをスキップ（I/O削減）
- ✅ **リトライロジック**: 不安定なネットワーク環境に対応
- ✅ **完全なテストカバレッジ**: bats-core による自動テスト
- ✅ **CI/CD対応**: GitHub Actions統合

## 📋 Requirements

### 必須

- **Bash** 4.0+ (macOS: 3.2+互換)
- **curl**: HTTPSダウンロード用
- **GNU coreutils**: date, mktemp, install, cmp, stat

### 開発環境（オプション）

- **ShellCheck**: 静的解析ツール
- **shfmt**: シェルスクリプトフォーマッター
- **bats-core**: テストフレームワーク

## 📝 Naming Convention

このプロジェクトは **UNIX/Linux命名規約** に準拠しています:

### ファイル拡張子

- **開発中のソースファイル**: `bin/update_280.sh` (`.sh` 拡張子あり)
- **インストール後の実行ファイル**: `/usr/local/bin/adguard-280blocker-update` (拡張子なし)

[Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) によると:

> "If the executable will be added directly to the user's PATH, then **prefer to use no extension**. It is not necessary to know what language a program is written in when executing it."

### コマンド名の構成

コマンド名 `adguard-280blocker-update` は以下のUNIXベストプラクティスに従っています:

1. **ハイフン区切り**: UNIX伝統（例: `apt-get`, `docker-compose`, `git-log`）
2. **説明的**: 何をするかが即座に理解可能（[Rule of Clarity](https://cscie2x.dce.harvard.edu/hw/ch01s06.html): "clarity is better than cleverness"）
3. **ドメイン明示**: `adguard` + `280blocker` + `update` で文脈が完全に明確

参考: [UNIX Command Naming Standards](https://knowledge.businesscompassllc.com/unix-shell-script-naming-and-coding-standards-and-best-practices/)

## 🚀 Installation

### クイックインストール

```bash
# リポジトリのクローン
git clone https://github.com/yourusername/adguard-home-280blocker-updater.git
cd adguard-home-280blocker-updater

# スクリプトを /usr/local/bin にインストール
sudo make install-script

# フィルタ保存ディレクトリの作成（AdGuard Home用）
sudo mkdir -p /var/opt/adguardhome/filters
```

### cron設定（自動更新）

```bash
# 毎日午前3時に自動実行
sudo make setup-cron

# 手動でcrontabに追加する場合
echo "0 3 * * * /usr/local/bin/adguard-280blocker-update" | sudo crontab -
```

### AdGuard Home設定

1. AdGuard Homeの管理画面にログイン
2. **フィルタ** → **DNS遮断リスト** → **カスタムフィルタを追加**
3. 以下を設定:
   - **名前**: 280blocker Domain List
   - **URL**: `file:///var/opt/adguardhome/filters/280blocker_domain.txt`
4. 保存後、フィルタリストを更新

## 📖 Usage

### 基本的な使用方法

```bash
# 静かに実行（cron向け）
/usr/local/bin/adguard-280blocker-update

# 詳細モード（進捗を表示）
/usr/local/bin/adguard-280blocker-update -v

# Makefile経由で実行
make run         # 詳細モード
make run-quiet   # 静かに実行
```

### オプション

- `-v`: Verbose mode - 進捗状況を標準出力に表示

### 終了コード

- `0`: 成功（フィルタ更新完了 or 変更なし）
- `1`: 失敗（ダウンロードエラー、ネットワーク障害など）

## 🛠️ Development

### 開発環境のセットアップ

```bash
# 依存関係のインストール（Debian/Ubuntu/Raspberry Pi OS）
make install

# または手動でインストール
sudo apt-get update
sudo apt-get install -y shellcheck shfmt bats
```

### 利用可能なMakeタスク

```bash
make help          # ヘルプを表示
make lint          # ShellCheck静的解析
make format        # shfmtで自動フォーマット
make format-check  # フォーマットチェック（CIで使用）
make test          # bats-coreテストを実行
make test-verbose  # テストを詳細モードで実行
make ci            # 完全なCIパイプライン実行
make clean         # 一時ファイルのクリーンアップ
```

### テストの実行

```bash
# 全テスト実行
make test

# 特定のテストファイルのみ
bats test/update_280.bats

# bats-core v1.13.0の新機能
bats --abort test/           # fail-fast: 最初の失敗で停止
bats --verbose-run test/     # 詳細出力
```

### コードスタイル

- **Google Shell Style Guide** に準拠
- インデント: **スペース2つ**
- ShellCheckの全チェックを有効化
- すべてのスクリプトは `#!/bin/bash` で開始
- 厳格モード: `set -euo pipefail`

## 📁 Project Structure

```
adguard-home-280blocker-updater/
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions CI/CD
├── bin/
│   └── update_280.sh           # メインスクリプト
├── lib/                        # 共通ライブラリ（今後の拡張用）
├── test/
│   ├── setup_suite.bash        # テストスイート設定
│   └── update_280.bats         # bats-core テスト
├── .editorconfig               # エディタ設定
├── .gitignore                  # Git除外設定
├── .shellcheckrc               # ShellCheck設定
├── LICENSE                     # MITライセンス
├── Makefile                    # タスクランナー
└── README.md                   # このファイル
```

## 🔧 Configuration

### 環境変数（オプション）

スクリプト内の定数をカスタマイズする場合は、以下の環境変数を設定できます:

```bash
# データディレクトリのカスタマイズ
export DATA_DIR="/custom/path/to/filters"

# スクリプト実行
DATA_DIR="/custom/path" /usr/local/bin/adguard-280blocker-update -v
```

### デフォルト設定

- **データディレクトリ**: `/var/opt/adguardhome/filters`
- **ファイル名**: `280blocker_domain.txt`
- **接続タイムアウト**: 10秒
- **最大リトライ**: 3回
- **リトライ間隔**: 5秒

## 🔍 Troubleshooting

### よくある問題と解決方法

#### 1. ダウンロード失敗

```bash
[ERROR] Failed to download filter list. Neither 202601 nor 202512 were available.
```

**原因**: ネットワーク接続の問題、または280blocker.netのメンテナンス
**解決策**:
- インターネット接続を確認
- `curl -I https://280blocker.net` でサイトの疎通確認
- しばらく待ってから再実行

#### 2. 権限エラー

```bash
install: cannot create regular file '/var/opt/adguardhome/filters/280blocker_domain.txt': Permission denied
```

**原因**: 書き込み権限がない
**解決策**:
```bash
sudo mkdir -p /var/opt/adguardhome/filters
sudo chown $(whoami):$(whoami) /var/opt/adguardhome/filters
```

#### 3. ShellCheck警告

```bash
make lint
```

を実行してコードの品質を確認してください。

## 🤝 Contributing

プルリクエストを歓迎します！以下の手順に従ってください:

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

### コントリビューションガイドライン

- Google Shell Style Guideに準拠すること
- `make lint` と `make test` が成功すること
- 新機能には対応するテストを追加すること
- コミットメッセージは明確に記述すること

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [280blocker](https://280blocker.net/) - フィルタリストの提供元
- [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) - DNS広告ブロッカー
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck](https://www.shellcheck.net/)
- [bats-core](https://github.com/bats-core/bats-core)

## 📚 References

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck GitHub Repository](https://github.com/koalaman/shellcheck)
- [bats-core Documentation](https://bats-core.readthedocs.io/)
- [Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)

## 📮 Support

問題が発生した場合は、[GitHub Issues](https://github.com/yourusername/adguard-home-280blocker-updater/issues) で報告してください。

---

**Made with ❤️ for Raspberry Pi & AdGuard Home users**
