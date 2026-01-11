FROM ubuntu:24.04

# コンテナであることをSystemdに伝える環境変数
ENV container docker

# 1. 必要なパッケージ + systemd のインストール
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    make \
    git \
    curl \
    sudo \
    shellcheck \
    bats \
    && rm -rf /var/lib/apt/lists/*

# 2. shfmt のインストール
# 3. SystemdをDockerで動かすための不要サービス削除（公式推奨の呪文）
RUN curl -sS https://webinstall.dev/shfmt | bash \
    && cd /lib/systemd/system/sysinit.target.wants/ \
    && rm -f $(ls | grep -v systemd-tmpfiles-setup) \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/*

# 作業ディレクトリ
WORKDIR /app

# 停止シグナルの設定
STOPSIGNAL SIGRTMIN+3

# 【重要】エントリーポイントを Systemd (init) に設定
CMD ["/sbin/init"]