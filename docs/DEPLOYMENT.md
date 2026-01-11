# Deployment Guide

本ドキュメントでは、AdGuard Home 280blocker Updaterの様々なデプロイメント方法について詳細に説明します。

## Table of Contents

- [Standard Installation](#standard-installation)
- [System-wide Installation](#system-wide-installation)
- [Systemd Timer Deployment](#systemd-timer-deployment)
- [Package Creation (DEB/RPM)](#package-creation-debrpm)
- [Docker Deployment](#docker-deployment)
- [Troubleshooting](#troubleshooting)

---

## Standard Installation

最も一般的なインストール方法で、`/usr/local/bin`にスクリプトを配置し、cronで自動実行を設定します。

### Prerequisites

- Bash 4.0+
- curl
- sudo権限

### Installation Steps

```bash
# 1. リポジトリのクローン
git clone https://github.com/yourusername/adguard-home-280blocker-updater.git
cd adguard-home-280blocker-updater

# 2. インストール実行
sudo make install
```

**何が行われるか:**
- スクリプトを`/usr/local/bin/adguardhome-280blocker-filter-updater`にインストール
- cron設定を`/etc/cron.d/adguardhome-280blocker-updater`に配置（644 root:root）
- フィルタ保存ディレクトリ`/var/opt/adguardhome/filters`を作成

### Verification

```bash
# インストール状態を確認
make status

# cron設定を確認
make check-cron

# 手動実行テスト
sudo adguardhome-280blocker-filter-updater -v
```

---

## System-wide Installation

システムパッケージとして`/usr/bin`にインストールする方法です。

### When to Use

- システム標準パッケージとして配布する場合
- FHS（Filesystem Hierarchy Standard）完全準拠が必要な場合
- パッケージマネージャ（apt, yum）経由で管理する場合

### Installation

```bash
sudo make PREFIX=/usr install
```

**インストール先:**
- `/usr/bin/adguardhome-280blocker-filter-updater`
- `/etc/cron.d/adguardhome-280blocker-updater`

### Uninstallation

```bash
sudo make PREFIX=/usr uninstall
```

---

## Systemd Timer Deployment

cronの代わりにsystemd timerを使用する方法です。モダンなLinuxディストリビューションで推奨されます。

### Advantages

1. **Persistent Execution**: システムダウン時に実行できなかったジョブを起動時に実行
2. **No Overlap**: 前回のジョブが終了していない場合、新しいジョブは待機
3. **Unified Logging**: `journalctl`で統合ログ管理
4. **Dependency Management**: 他のサービスとの依存関係を定義可能

### Installation

```bash
sudo make install-systemd
```

**配置されるファイル:**
- `/etc/systemd/system/adguardhome-280blocker-updater.service`
- `/etc/systemd/system/adguardhome-280blocker-updater.timer`

### Management

```bash
# タイマー状態を確認
make check-systemd
systemctl status adguardhome-280blocker-updater.timer

# 次回実行時刻を確認
systemctl list-timers adguardhome-280blocker-updater.timer

# ログを確認
sudo journalctl -u adguardhome-280blocker-updater.service

# 手動実行
sudo systemctl start adguardhome-280blocker-updater.service

# タイマーを停止
sudo systemctl stop adguardhome-280blocker-updater.timer
sudo systemctl disable adguardhome-280blocker-updater.timer

# タイマーを再起動
sudo systemctl restart adguardhome-280blocker-updater.timer
```

### Configuration Customization

実行時刻を変更する場合:

```bash
# タイマーファイルを編集
sudo vim /etc/systemd/system/adguardhome-280blocker-updater.timer

# OnCalendar行を変更（例: 毎日午前4時）
OnCalendar=*-*-* 04:00:00

# systemd設定を再読み込み
sudo systemctl daemon-reload
sudo systemctl restart adguardhome-280blocker-updater.timer
```

---

## Package Creation (DEB/RPM)

DEBやRPMパッケージを作成する方法です。

### Prerequisites

- `dpkg-deb` (Debian/Ubuntu)
- `rpmbuild` (RedHat/CentOS)

### DEB Package Creation

```bash
# 1. ステージングディレクトリへインストール
export PKG_NAME=adguardhome-280blocker-updater
export VERSION=1.0.0
export STAGING=/tmp/$PKG_NAME-$VERSION

make DESTDIR=$STAGING PREFIX=/usr install

# 2. DEBIAN制御ファイルを作成
mkdir -p $STAGING/DEBIAN
cat > $STAGING/DEBIAN/control <<EOF
Package: $PKG_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: bash (>= 4.0), curl, cron | systemd
Maintainer: Your Name <your.email@example.com>
Description: AdGuard Home 280blocker filter updater
 Automatically updates 280blocker filter lists for AdGuard Home.
 Includes both cron and systemd timer support.
EOF

# 3. パッケージをビルド
dpkg-deb --build $STAGING
mv /tmp/$PKG_NAME-$VERSION.deb .

# 4. インストールテスト
sudo dpkg -i $PKG_NAME-$VERSION.deb
```

### RPM Package Creation

```bash
# 1. rpmbuild環境を準備
rpmdev-setuptree

# 2. ステージングディレクトリへインストール
export PKG_NAME=adguardhome-280blocker-updater
export VERSION=1.0.0
export STAGING=$HOME/rpmbuild/BUILDROOT/$PKG_NAME-$VERSION-1.x86_64

make DESTDIR=$STAGING PREFIX=/usr install

# 3. SPECファイルを作成
cat > $HOME/rpmbuild/SPECS/$PKG_NAME.spec <<EOF
Name:           $PKG_NAME
Version:        $VERSION
Release:        1%{?dist}
Summary:        AdGuard Home 280blocker filter updater

License:        MIT
URL:            https://github.com/yourusername/$PKG_NAME
Source0:        %{name}-%{version}.tar.gz

Requires:       bash >= 4.0, curl

%description
Automatically updates 280blocker filter lists for AdGuard Home.

%install
# Files already installed by make DESTDIR

%files
%{_bindir}/adguardhome-280blocker-filter-updater
/etc/cron.d/adguardhome-280blocker-updater

%changelog
* $(date +'%a %b %d %Y') Your Name <your.email@example.com> - $VERSION-1
- Initial package
EOF

# 4. RPMをビルド
rpmbuild -bb $HOME/rpmbuild/SPECS/$PKG_NAME.spec

# 5. インストールテスト
sudo rpm -ivh $HOME/rpmbuild/RPMS/x86_64/$PKG_NAME-$VERSION-1.x86_64.rpm
```

---

## Docker Deployment

Dockerコンテナ内で実行する方法（開発・テスト用）。

### Dockerfile Example

```dockerfile
FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y bash curl cron && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy application
COPY bin/adguardhome-280blocker-filter-updater.sh /usr/local/bin/adguardhome-280blocker-filter-updater
COPY config/cron.d/adguardhome-280blocker-updater /etc/cron.d/adguardhome-280blocker-updater

# Set permissions
RUN chmod 755 /usr/local/bin/adguardhome-280blocker-filter-updater && \
    chmod 644 /etc/cron.d/adguardhome-280blocker-updater

# Create filter directory
RUN mkdir -p /var/opt/adguardhome/filters

# Start cron
CMD ["cron", "-f"]
```

### Build and Run

```bash
# Build image
docker build -t adguardhome-280blocker-updater .

# Run container
docker run -d \
  --name updater \
  -v /path/to/filters:/var/opt/adguardhome/filters \
  adguardhome-280blocker-updater

# Check logs
docker logs updater

# Manual execution
docker exec updater /usr/local/bin/adguardhome-280blocker-filter-updater -v
```

---

## Troubleshooting

### Common Issues

#### 1. Permission Denied

**Symptom:**
```
install: cannot create regular file: Permission denied
```

**Solution:**
```bash
# Use sudo for installation
sudo make install

# Or ensure filter directory exists with correct permissions
sudo mkdir -p /var/opt/adguardhome/filters
sudo chown $USER:$USER /var/opt/adguardhome/filters
```

#### 2. Cron Not Running

**Check cron service:**
```bash
# Debian/Ubuntu
sudo systemctl status cron

# RedHat/CentOS
sudo systemctl status crond

# Restart if needed
sudo systemctl restart cron
```

**Verify cron file permissions:**
```bash
ls -l /etc/cron.d/adguardhome-280blocker-updater
# Should be: -rw-r--r-- 1 root root
```

#### 3. Systemd Timer Not Starting

**Check timer status:**
```bash
sudo systemctl status adguardhome-280blocker-updater.timer
```

**Common fixes:**
```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable and start timer
sudo systemctl enable adguardhome-280blocker-updater.timer
sudo systemctl start adguardhome-280blocker-updater.timer

# Check for errors
sudo journalctl -xe -u adguardhome-280blocker-updater.timer
```

#### 4. Script Not Found After Installation

**Verify PATH:**
```bash
echo $PATH
# Should include /usr/local/bin or /usr/bin

# Test directly
/usr/local/bin/adguardhome-280blocker-filter-updater -v
```

**Check installation:**
```bash
make status
which adguardhome-280blocker-filter-updater
```

---

## Best Practices

1. **Use systemd timers on modern systems** for better reliability and logging
2. **Always test manually** before relying on scheduled execution
3. **Monitor logs regularly** to catch issues early
4. **Use staging environments** for testing package deployments
5. **Document customizations** if you modify schedules or paths

---

## References

- [GNU Makefile Conventions](https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html)
- [systemd.timer Documentation](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
- [Debian Package Guidelines](https://www.debian.org/doc/manuals/maint-guide/)
- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/)
