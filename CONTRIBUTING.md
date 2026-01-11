# Contributing to AdGuard Home 280blocker Updater

このプロジェクトへのコントリビューションを歓迎します！
このドキュメントでは、開発環境のセットアップからコードのコントリビューション方法までを説明します。

## 📋 Table of Contents

- [Development Environment](#development-environment)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Code Style](#code-style)
- [Testing](#testing)
- [CI/CD](#cicd)
- [Pull Request Process](#pull-request-process)

---

## 🛠️ Development Environment

### 必要なツール

開発には以下のツールが必要です:

- **Bash** 4.0+ (macOS: 3.2+互換)
- **GNU Make**: タスクランナー
- **ShellCheck**: 静的解析ツール
- **shfmt**: シェルスクリプトフォーマッター
- **bats-core**: テストフレームワーク (v1.13.0+)
- **Git**: バージョン管理

### セットアップ

```bash
# リポジトリのクローン
git clone https://github.com/yourusername/adguard-home-280blocker-updater.git
cd adguard-home-280blocker-updater

# 開発依存関係のインストール（Debian/Ubuntu/Raspberry Pi OS）
make bootstrap

# 手動インストールの場合
sudo apt-get update
sudo apt-get install -y shellcheck bats

# shfmt（Debian/Ubuntuの場合）
sudo apt-get install -y shfmt

# shfmt（その他のシステム）
wget -qO /usr/local/bin/shfmt https://github.com/mvdan/sh/releases/latest/download/shfmt_v3.8.0_linux_amd64
chmod +x /usr/local/bin/shfmt
```

**Note:** `make install`は本番環境へのインストールコマンドです。開発依存関係のインストールには`make bootstrap`を使用してください。

### Docker開発環境（推奨）

Windows や macOS など、Linux以外の環境で開発する場合は Docker を使用できます：

```bash
# テスト用 Linux 環境を起動
docker compose up -d

# コンテナ内でシェルを起動
docker compose exec lab bash

# コンテナ内で開発作業を実行
docker compose exec lab make lint
docker compose exec lab make test
docker compose exec lab make format

# systemd の動作確認（実環境に近いテスト）
docker compose exec lab make install-systemd
docker compose exec lab systemctl status adguardhome-280blocker-filter-updater.timer

# 環境の停止と削除
docker compose down
```

**Docker 環境の特徴:**
- Ubuntu 24.04 LTS ベース
- systemd 統合済み（実環境に近いテストが可能）
- 開発ツール（ShellCheck, bats-core, shfmt）プリインストール済み
- Windows でも systemd や cron の動作確認が可能

---

## 📁 Project Structure

```
adguard-home-280blocker-updater/
├── .github/
│   ├── ISSUE_TEMPLATE/         # Issueテンプレート
│   ├── workflows/
│   │   └── ci.yml              # GitHub Actions CI/CD
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── dependabot.yml          # Dependabot設定
├── bin/
│   └── adguardhome-280blocker-filter-updater.sh  # メインスクリプト
├── config/                     # 設定ファイル（NEW）
│   ├── cron.d/
│   │   └── adguardhome-280blocker-updater       # cron設定
│   └── systemd/
│       ├── adguardhome-280blocker-updater.service
│       └── adguardhome-280blocker-updater.timer
├── lib/                        # 共通ライブラリ（今後の拡張用）
├── test/
│   ├── setup_suite.bash        # テストスイート設定
│   └── test_*.bats             # bats-core テスト
├── docs/                       # ドキュメント
│   ├── ARCHITECTURE.md         # アーキテクチャ設計
│   └── DEPLOYMENT.md           # デプロイメントガイド
├── .editorconfig               # エディタ設定
├── .gitignore                  # Git除外設定
├── .shellcheckrc               # ShellCheck設定
├── CHANGELOG.md                # 変更履歴
├── compose.yaml                # Docker Compose設定（開発用）
├── CONTRIBUTING.md             # このファイル（開発者向け）
├── Dockerfile                  # Docker開発環境（systemd統合）
├── LICENSE                     # MITライセンス
├── Makefile                    # GNU標準準拠タスクランナー
└── README.md                   # 利用者向けドキュメント
```

### ディレクトリの役割

- **bin/**: 実行可能スクリプト（`.sh` 拡張子あり）
- **config/**: システム設定ファイル（cron, systemd）
  - `cron.d/`: `/etc/cron.d/`へデプロイされるcron設定
  - `systemd/`: `/etc/systemd/system/`へデプロイされるユニットファイル
- **lib/**: 共有ライブラリファイル（`.sh` 拡張子必須、実行不可）
- **test/**: テストファイル（`.bats` 拡張子）
- **.github/**: GitHub固有の設定（CI/CD, Issue/PRテンプレート）

---

## 🔄 Development Workflow

### 利用可能なMakeタスク

Makefileは[GNU Coding Standards](https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html)に準拠しています。

#### GNU標準ターゲット
```bash
make all           # デフォルトターゲット（スクリプトの存在確認）
make install       # 本番環境へインストール（スクリプト + cron設定）
make install-systemd  # systemd timer方式でインストール
make uninstall     # 完全アンインストール
make check         # テスト実行（testのエイリアス）
make test          # bats-coreテストを実行
make clean         # 一時ファイルのクリーンアップ
make distclean     # 全生成ファイルを削除
```

#### 開発者向けターゲット
```bash
make bootstrap     # 開発依存関係のインストール（shellcheck, shfmt, bats）
make lint          # ShellCheck静的解析
make format        # shfmtで自動フォーマット
make format-check  # フォーマットチェック（CIで使用）
make test-verbose  # テストを詳細モードで実行
make ci            # 完全なCIパイプライン実行（lint + format-check + test）
```

#### ランタイム・ステータス確認
```bash
make run           # スクリプトを詳細モードで実行
make run-quiet     # スクリプトを静かに実行
make status        # インストール状態を確認
make check-cron    # cron設定を確認
make check-systemd # systemd timer状態を確認
```

#### 変数のカスタマイズ
```bash
make PREFIX=/usr install              # /usr/binにインストール
make DESTDIR=/tmp/staging install     # ステージング（パッケージング）
```

### 開発サイクル

1. **機能ブランチの作成**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **コードの実装**
   - Google Shell Style Guideに従ってコードを記述
   - コメントは英語で統一

3. **フォーマットとリント**
   ```bash
   make format  # 自動フォーマット
   make lint    # 静的解析でエラーチェック
   ```

4. **テストの追加と実行**
   ```bash
   # 新機能には対応するテストを追加
   vim test/update_280.bats

   # テスト実行
   make test
   ```

5. **CIパイプライン確認**
   ```bash
   make ci  # lint + format-check + test を一括実行
   ```

6. **コミット**
   ```bash
   git add .
   git commit -m "feat: Add new feature"
   ```

7. **プッシュとプルリクエスト**
   ```bash
   git push origin feature/your-feature-name
   # GitHubでプルリクエストを作成
   ```

---

## 🎨 Code Style

### Google Shell Style Guide準拠

このプロジェクトは [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) に準拠しています。

#### 重要なルール

1. **Shebang**: 全スクリプトは `#!/bin/bash` で開始
2. **Strict Mode**: `set -euo pipefail` を設定
3. **インデント**: スペース2つ（タブ禁止）
4. **変数クォート**: 常に `"$VAR"` でクォート
5. **関数**: `function` キーワードは使用しない（`func_name() { ... }` 形式）
6. **条件式**: `[[ ... ]]` を使用（`[ ... ]` より優先）
7. **コマンド置換**: `$(command)` を使用（バッククォート禁止）
8. **local変数**: 関数内では必ず `local` を使用

#### コメント規約

- **英語で記述**: コメントは必ず英語
- **shdoc形式**: 関数にはshdocアノテーションを付与

```bash
# @description Downloads the filter list from 280blocker.net
# @arg $1 string Target date in YYYYMM format
# @return 0 on success, 1 on failure
download_list() {
    local target_date="$1"
    # ... implementation ...
}
```

#### 命名規約

- **変数**: `lowercase_with_underscores` または `UPPERCASE_CONSTANTS`
- **関数**: `lowercase_with_underscores`
- **ファイル（ソース）**: `script_name.sh` (拡張子あり)
- **ファイル（インストール後）**: `script-name` (拡張子なし、ハイフン区切り)

詳細は [UNIX Naming Convention](https://knowledge.businesscompassllc.com/unix-shell-script-naming-and-coding-standards-and-best-practices/) を参照。

---

## 🧪 Testing

### bats-core テストフレームワーク

このプロジェクトは [bats-core v1.13.0+](https://github.com/bats-core/bats-core) を使用しています。

#### テストファイルの場所

- `test/setup_suite.bash`: テストスイートの共通セットアップ
- `test/update_280.bats`: メインスクリプトのテスト

#### テストの実行

```bash
# 全テスト実行
make test

# 特定のテストファイルのみ
bats test/update_280.bats

# v1.13.0の新機能: fail-fast（最初の失敗で停止）
bats --abort test/

# v1.13.0の新機能: 詳細出力
bats --verbose-run test/

# 特定のテストパターンを除外
bats --negative-filter "INTEGRATION" test/
```

#### テストの書き方

```bash
@test "Description of what this test validates" {
    # Setup (if needed beyond global setup)
    local test_var="value"

    # Execute
    run your_command arg1 arg2

    # Assert
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected pattern" ]]
    [ ${#lines[@]} -gt 0 ]
}
```

#### テストのベストプラクティス

1. **明確な説明**: テスト名は何を検証するか明確に記述
2. **独立性**: 各テストは他のテストに依存しない
3. **skip活用**: ネットワークや外部依存が必要なテストは `skip` を使用
4. **cleanup**: `teardown` で確実にリソースを解放

---

## 🤖 CI/CD

### GitHub Actions

プッシュおよびプルリクエスト時に自動的に以下が実行されます:

1. **ShellCheck**: 静的解析
2. **Format Check**: コードフォーマットの検証
3. **bats-core Tests**: 自動テスト実行（Ubuntu 20.04, 22.04）

#### ワークフローファイル

`.github/workflows/ci.yml`

#### ローカルでCIを再現

```bash
make ci
```

これにより、GitHubで実行されるのと同じチェックが実行されます。

---

## 🔀 Pull Request Process

### プルリクエストの作成

1. **フォーク**: このリポジトリをフォーク
2. **ブランチ作成**: `git checkout -b feature/amazing-feature`
3. **実装とテスト**: コードを実装し、テストを追加
4. **フォーマット**: `make format` で自動フォーマット
5. **CI確認**: `make ci` で全チェックをパス
6. **コミット**: 明確なコミットメッセージで変更をコミット
7. **プッシュ**: `git push origin feature/amazing-feature`
8. **PR作成**: GitHubでプルリクエストを作成

### コミットメッセージ

[Conventional Commits](https://www.conventionalcommits.org/) に従ってください:

```
<type>: <description>

[optional body]

[optional footer]
```

**Type例:**
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `style`: コードフォーマット（ロジック変更なし）
- `refactor`: リファクタリング
- `test`: テストの追加・修正
- `chore`: ビルドプロセスやツールの変更

**例:**
```
feat: Add retry logic for network failures

Implement exponential backoff for curl download failures.
Retry up to 3 times with 5 second delay between attempts.

Closes #42
```

### プルリクエストのチェックリスト

- [ ] `make lint` が成功する
- [ ] `make format-check` が成功する
- [ ] `make test` が成功する
- [ ] 新機能には対応するテストを追加した
- [ ] ドキュメント（README.mdまたはCONTRIBUTING.md）を更新した
- [ ] コミットメッセージがConventional Commitsに従っている
- [ ] 破壊的変更がある場合は `BREAKING CHANGE:` を明記した

---

## 📚 References

### 公式ドキュメント

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [GNU Coding Standards - Makefile Conventions](https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html)
- [GNU Standard Targets](https://www.gnu.org/prep/standards/html_node/Standard-Targets.html)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [bats-core Documentation](https://bats-core.readthedocs.io/)
- [UNIX Naming Standards](https://knowledge.businesscompassllc.com/unix-shell-script-naming-and-coding-standards-and-best-practices/)

### システム統合

- [cron.d Best Practices](https://www.tenable.com/audits/items/Tenable_Best_Practices_Cisco_Firepower_Management_Center_OS.audit:e60ebdfb030ed8bfb25007969128ed58)
- [systemd timers vs cron](https://opensource.com/article/20/7/systemd-timers)
- [DESTDIR Best Practices](https://www.gnu.org/prep/standards/html_node/DESTDIR.html)

### 学習リソース

- [ShellCheck Solutions](https://www.hackerone.com/blog/shell-script-pitfalls-and-shellcheck-solutions)
- [Testing Bash with BATS](https://www.hackerone.com/blog/testing-bash-scripts-bats-practical-guide)
- [UNIX Philosophy](https://cscie2x.dce.harvard.edu/hw/ch01s06.html)
- [Makefile Best Practices](https://danyspin97.org/blog/makefiles-best-practices/)

---

## 💬 Questions?

質問や提案がある場合は、[GitHub Issues](https://github.com/yourusername/adguard-home-280blocker-updater/issues) で気軽にお尋ねください。

---

**Thank you for contributing! 🎉**
