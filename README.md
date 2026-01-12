<a href='https://ko-fi.com/Z8Z31J3LMW' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
<a href="https://www.buymeacoffee.com/tay2501" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 36px !important;width: 130px !important;" ></a>

# AdGuard Home 280blocker Updater

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-brightgreen)](https://www.shellcheck.net/)

AdGuard Home用の280blockerフィルタリストを自動更新するシェルスクリプト。
月次更新される280blockerのドメインフィルタを自動的にダウンロードし、AdGuard Homeに適用します。

## ✨ Features

- ✅ **自動更新**: 月次更新される280blockerフィルタを自動ダウンロード
- ✅ **差分検知**: 変更がない場合はファイル書き込みをスキップ（I/O削減）
- ✅ **エラーハンドリング**: ネットワーク障害時の自動リトライ機能
- ✅ **Raspberry Pi最適化**: SDカード寿命保護（tmpfsの活用）
- ✅ **Cron対応**: 静かに動作し、エラー時のみ通知
- ✅ **FHS準拠**: `/var/opt` にデータを配置（Linuxファイルシステム標準）

## 📋 Requirements

### 必須コンポーネント

- **Bash** 4.0以上
- **curl**: HTTPSダウンロード用
- **sudo権限**: インストールとcron設定に必要

### ネットワーク要件

- **外向きHTTPS通信**: `280blocker.net` (TCP/443)
- ファイアウォール設定が必要な環境では、`280blocker.net` へのHTTPSアクセスを許可してください
- プロキシ環境では、`curl` が環境変数 `https_proxy` を参照します

## 🚀 Installation

### Quick Install (Recommended)

```bash
# リポジトリのクローン
git clone https://github.com/tay2501/adguard-home-280blocker-updater.git
cd adguard-home-280blocker-updater

# /usr/local/bin にスクリプトをインストール + cron設定
sudo make install-cron

# または systemd timer を使用する場合（推奨: モダンなLinux）
sudo make install-systemd
```

### Step by Step Installation

#### 1. リポジトリのクローン

```bash
git clone https://github.com/yourusername/adguard-home-280blocker-updater.git
cd adguard-home-280blocker-updater
```

#### 2. スクリプトのインストール

```bash
# GNU標準: /usr/local/bin にインストール + cron設定
sudo make install

# システムディレクトリ(/usr/bin)にインストールする場合
sudo make PREFIX=/usr install

# systemd timer を使用する場合（cronの代替）
sudo make install-systemd
```

**インストール先:**
- デフォルト: `/usr/local/bin/adguardhome-280blocker-filter-updaterr`
- Cron設定: `/etc/cron.d/adguardhome-280blocker-filter-updaterr`
- Systemd設定: `/etc/systemd/system/adguardhome-280blocker-filter-updaterr.{service,timer}`

#### 3. フィルタ保存ディレクトリの作成

```bash
sudo mkdir -p /var/opt/adguardhome/filters
```

#### 4. インストール状態の確認

```bash
# インストール状態を確認
make status

# cron設定を確認
make check-cron

# systemd timer設定を確認（systemd使用時）
make check-systemd
```

## 🐳 Docker Development Environment

開発・テスト環境として Docker を使用できます。Windows などの非 Linux 環境でも、systemd や cron の動作確認が可能です。

### Docker Compose での起動

```bash
# テスト用 Linux 環境を起動
docker compose up -d

# コンテナ内でシェルを起動
docker compose exec lab bash

# コンテナ内で各種コマンドを実行
docker compose exec lab make lint
docker compose exec lab make test
docker compose exec lab make install-systemd

# 環境の停止と削除
docker compose down
```

### Docker を使用した CI/CD

```bash
# Docker 経由で完全な CI パイプラインを実行
docker compose run --rm lab make ci

# 個別のテストやチェック
docker compose run --rm lab make lint
docker compose run --rm lab make test
docker compose run --rm lab make format-check
```

### Dockerfile について

プロジェクトには開発・テスト用の Dockerfile が含まれています：
- ベースイメージ: Ubuntu 24.04 LTS
- systemd 統合: systemd が動作するため、実環境に近いテストが可能
- 開発ツール: ShellCheck, bats-core, shfmt などがプリインストール済み

**注意**: このDockerfileは開発・テスト専用です。本番環境では直接ホストにインストールしてください。

## 📖 Usage

### 基本的な使用方法

```bash
# 静かに実行（cron向け）
adguardhome-280blocker-filter-updater

# 詳細モード（進捗を表示）
adguardhome-280blocker-filter-updater -v
```

### オプション

- `-v`: Verbose mode - 進捗状況を標準出力に表示

### 終了コード

- `0`: 成功（フィルタ更新完了 または 変更なし）
- `1`: 失敗（ダウンロードエラー、ネットワーク障害など）

## ⚙️ AdGuard Home設定

スクリプトのインストールが完了したら、AdGuard Homeにフィルタを登録します:

1. AdGuard Homeを停止

```Bash
sudo systemctl stop AdGuardHome
```

2. 設定ファイルを編集

  ```/opt/AdGuardHome/AdGuardHome.yaml
  filtering:
    # ...
    safe_fs_patterns:
      - /opt/AdGuardHome/userfilters/*    # 初期設定
      - /var/opt/adguardhome/filters/*    # ★追加箇所
  ```

3. AdGuard Homeを再起動
   
  ```Bash
  sudo systemctl restart AdGuardHome
  ```

4. AdGuard Homeの管理画面にログイン
5. **フィルタ** → **DNS遮断リスト** → **カスタムフィルタを追加**
6. 以下を設定:
    - **名前**: `280blocker Domain List`
    - **URL**: `/var/opt/adguardhome/filters/280blocker_domain_ag.txt`
7. 保存後、フィルタリストを更新

### 初回実行

AdGuard Home設定前に、一度手動でスクリプトを実行してフィルタファイルを作成します:

1. 手動実行

```bash
sudo systemctl start adguardhome-280blocker-filter-updater.service
```

2. 結果確認

```bash
# 実行ログを見る
journalctl -u adguardhome-280blocker-filter-updater.service -n 20 --no-pager

# ファイルが生成されたか確認
ls -l /var/opt/adguardhome/filters/
```

## 🔍 Troubleshooting

### よくある問題と解決方法

#### 1. ダウンロード失敗

```
[ERROR] Failed to download filter list.
```

**原因**: ネットワーク接続の問題、または280blocker.netのメンテナンス

**解決策**:
- インターネット接続を確認
- `curl -I https://280blocker.net` でサイトの疎通確認
- しばらく待ってから再実行

#### 2. 権限エラー

```
install: cannot create regular file: Permission denied
```

**原因**: 書き込み権限がない

**解決策**:
```bash
# ディレクトリを作成して権限を設定
sudo mkdir -p /var/opt/adguardhome/filters
sudo chown $(whoami):$(whoami) /var/opt/adguardhome/filters

# または常にsudoで実行
sudo adguardhome-280blocker-filter-updater -v
```

#### 3. cron実行時のエラー確認

cronジョブが正常に動作しているか確認:

```bash
# cron設定を確認
make check-cron

# cronログを確認（Debian/Ubuntu）
sudo grep adguardhome-280blocker-filter-updater /var/log/syslog

# cron設定ファイルを確認
cat /etc/cron.d/adguardhome-280blocker-updater
```

**systemd timer使用時:**
```bash
# タイマー状態を確認
make check-systemd

# ログを確認
sudo journalctl -u adguardhome-280blocker-updater.service

# 次回実行時刻を確認
systemctl list-timers adguardhome-280blocker-updater.timer
```

#### 4. スクリプトが見つからない

```
command not found: adguardhome-280blocker-filter-updater
```

**原因**: スクリプトが正しくインストールされていない

**解決策**:
```bash
# インストール状態を確認
make status

# 詳細確認
which adguardhome-280blocker-filter-updater
ls -la /usr/local/bin/adguardhome-280blocker-filter-updater

# 再インストール
cd /path/to/adguard-home-280blocker-updater
sudo make install
```

## 🗑️ Uninstallation

### 完全アンインストール（推奨）

```bash
# スクリプト、cron、systemd設定を全て削除
sudo make uninstall

# データディレクトリの削除（オプション）
sudo rm -rf /var/opt/adguardhome/filters
```

### 詳細なアンインストール手順

```bash
# 1. インストール状態を確認
make status

# 2. 完全アンインストール実行
# - /usr/local/bin/adguardhome-280blocker-filter-updater を削除
# - /etc/cron.d/adguardhome-280blocker-updater を削除
# - systemd設定を削除（存在する場合）
sudo make uninstall

# 3. フィルタデータの削除（必要に応じて）
sudo rm -rf /var/opt/adguardhome/filters
```

**Note:** `/etc/cron.d/`方式を採用しているため、他のcronジョブに影響を与えることなく安全にアンインストールできます。

## 🛠️ Advanced Usage

### Makefile Targets

プロジェクトはGNU標準に準拠したMakefileを提供しています:

```bash
# ヘルプを表示（全ターゲットのリスト）
make help

# GNU標準ターゲット
make all              # スクリプトの存在確認（デフォルト）
make install          # スクリプトとcron設定をインストール
make install-systemd  # systemd timer方式でインストール
make uninstall        # 完全アンインストール
make check            # テスト実行（make testのエイリアス）
make test             # bats-coreテストを実行
make clean            # 一時ファイルを削除
make distclean        # 全生成ファイルを削除

# 開発者向けターゲット
make bootstrap        # 開発依存関係をインストール
make lint             # ShellCheck静的解析
make format           # shfmtで自動フォーマット
make format-check     # フォーマットチェック
make ci               # 完全なCIパイプライン実行

# ランタイム・ステータス確認
make run              # スクリプトを詳細モードで実行
make run-quiet        # スクリプトを静かに実行
make status           # インストール状態を確認
make check-cron       # cron設定を確認
make check-systemd    # systemd timer状態を確認
```

### PREFIX/DESTDIRサポート（パッケージング）

パッケージ作成やカスタムインストール先に対応:

```bash
# /usr/binにインストール（システムパッケージ向け）
sudo make PREFIX=/usr install

# ステージングディレクトリへインストール（DEB/RPM作成）
make DESTDIR=/tmp/staging PREFIX=/usr install

# ホームディレクトリへインストール（sudoなし）
make PREFIX=$HOME/.local install
```

### systemd timer vs cron

#### cron方式（デフォルト）
```bash
sudo make install
```
- **利点**: シンプル、ポータブル、古いシステムで動作
- **用途**: 常時稼働サーバー、シンプルなスケジュール

#### systemd timer方式（推奨）
```bash
sudo make install-systemd
```
- **利点**:
  - システムダウン時の実行保証（`Persistent=true`）
  - ジョブ重複防止
  - `journalctl`による統合ログ管理
  - 依存関係制御
- **用途**: モダンなLinux、信頼性重視

## 📚 Documentation

- **[README.md](README.md)** - このファイル（ユーザー向けガイド）
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - 開発者向けガイド
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - デプロイメント詳細ガイド
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - アーキテクチャとデザイン決定
- **[CHANGELOG.md](CHANGELOG.md)** - 変更履歴

## 🤝 Contributing

バグ報告や機能リクエストは [GitHub Issues](https://github.com/yourusername/adguard-home-280blocker-updater/issues) でお願いします。

プルリクエストを歓迎します！開発に参加する場合は、[CONTRIBUTING.md](CONTRIBUTING.md) をご覧ください。

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [280blocker](https://280blocker.net/) - フィルタリストの提供元
- [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) - DNS広告ブロッカー
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

---

**Made with ❤️ for Raspberry Pi & AdGuard Home users**
