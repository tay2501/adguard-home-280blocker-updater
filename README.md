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

- **Bash** 4.0以上
- **curl**: HTTPSダウンロード用
- **sudo権限**: インストールとcron設定に必要

## 🚀 Installation

### 1. リポジトリのクローン

```bash
git clone https://github.com/yourusername/adguard-home-280blocker-updater.git
cd adguard-home-280blocker-updater
```

### 2. スクリプトのインストール

```bash
# /usr/local/bin にインストール（拡張子なし）
sudo make install-script

# または手動でコピー
sudo install -m 755 bin/update_280.sh /usr/local/bin/adguard-280blocker-update
```

### 3. フィルタ保存ディレクトリの作成

```bash
sudo mkdir -p /var/opt/adguardhome/filters
```

### 4. cron設定（自動更新）

```bash
# 毎日午前3時に自動実行
sudo make setup-cron

# または手動でcrontabに追加
echo "0 3 * * * /usr/local/bin/adguard-280blocker-update" | sudo crontab -
```

## 📖 Usage

### 基本的な使用方法

```bash
# 静かに実行（cron向け）
adguard-280blocker-update

# 詳細モード（進捗を表示）
adguard-280blocker-update -v
```

### オプション

- `-v`: Verbose mode - 進捗状況を標準出力に表示

### 終了コード

- `0`: 成功（フィルタ更新完了 または 変更なし）
- `1`: 失敗（ダウンロードエラー、ネットワーク障害など）

## ⚙️ AdGuard Home設定

スクリプトのインストールが完了したら、AdGuard Homeにフィルタを登録します:

1. AdGuard Homeの管理画面にログイン
2. **フィルタ** → **DNS遮断リスト** → **カスタムフィルタを追加**
3. 以下を設定:
   - **名前**: `280blocker Domain List`
   - **URL**: `file:///var/opt/adguardhome/filters/280blocker_domain.txt`
4. 保存後、フィルタリストを更新

### 初回実行

AdGuard Home設定前に、一度手動でスクリプトを実行してフィルタファイルを作成します:

```bash
sudo adguard-280blocker-update -v
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
sudo adguard-280blocker-update -v
```

#### 3. cron実行時のエラー確認

cronジョブが正常に動作しているか確認:

```bash
# cronログを確認（Debian/Ubuntu）
sudo grep adguard-280blocker-update /var/log/syslog

# crontabを確認
sudo crontab -l
```

#### 4. スクリプトが見つからない

```
command not found: adguard-280blocker-update
```

**原因**: スクリプトが正しくインストールされていない

**解決策**:
```bash
# インストール状態を確認
which adguard-280blocker-update
ls -la /usr/local/bin/adguard-280blocker-update

# 再インストール
cd /path/to/adguard-home-280blocker-updater
sudo make install-script
```

## 🗑️ Uninstallation

```bash
# スクリプトのアンインストール
sudo make uninstall-script

# cron設定の削除
sudo crontab -l | grep -v adguard-280blocker-update | sudo crontab -

# データディレクトリの削除（オプション）
sudo rm -rf /var/opt/adguardhome/filters
```

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
