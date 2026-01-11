# プロジェクト憲法 (Project Constitution) - Shell/Bash Edition

## 🛠 技術スタック & 環境 (Immutable)

- **言語**: Bash (Version 4.0+ 推奨, macOS互換が必要な場合は 3.2+)
- **スタイルガイド**: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) 準拠
- **管理/実行**: Makefile (タスクランナーとして使用)
- **品質 (Lint)**: [ShellCheck](https://github.com/koalaman/shellcheck) (Static Analysis)
- **フォーマット**: [shfmt](https://github.com/mvdan/sh) (Indent: 2 spaces, Google Style)
- **テスト**: [bats-core](https://github.com/bats-core/bats-core) (TAP-compliant testing)
- **ドキュメント**: [shdoc](https://github.com/reconquest/shdoc) (Markdown generator via annotations)

## エージェント行動指針 (The Agentic Loop)

AIは以下の「思考と行動のループ」を厳守し、単発の回答ではなく「解決」を目指すこと。

1. **探索 (Explore & Context)**:
    - いきなり修正せず、まず関連ファイル（特に `Makefile`, `lib/`, `bin/`）を読み込む。
    - **重要**: `man` コマンドや `help` ビルトイン、`context7` / `serena` を自律的に使用し、オプションや挙動を裏取りする。曖昧な記憶で書かない。
    - シェル特有の「落とし穴（Pitfalls）」を事前に考慮する（例: 空白を含むパス、未定義変数、パイプのエラーハンドリング）。

2. **計画 (Plan & Consensus)**:
    - ユーザーに「日本語」で簡潔な実装計画を提示する。
    - 破壊的変更（例: 互換性のないオプション変更）がある場合は、ユーザーの合意を得る。
    - 複雑なロジックは、関数化や別ファイルへの切り出しを提案する。

3. **実行 (Act)**:
    - **TDD原則**: 可能な限り「失敗する Bats テスト」を先に書き、それをパスさせる形で実装する。
    - **KISS/SRP**: 単一責任の原則を守り、関数は小さく保つ。
    - **Google Style**: インデントはスペース2つ。`local` 変数を徹底する。

4. **検証 (Verify)**:
    - 実装後は必ず `make test` (bats) と `make lint` (shellcheck) を実行し、エラーがないことを確認してから完了報告をする。

## 鉄の掟 (Strict Rules)

- **Safety First (The Boilerplate)**:
    - すべてのスクリプト（エントリーポイント）の冒頭に必ず `set -euo pipefail` を記述する。
    - 変数は必ずダブルクォートで囲む (`"$VAR"`)。ただし、意図的な単語分割が必要な場合を除く（その場合はコメントで明記）。

- **Latest information & Standards**:
    - 古いバッドノウハウ（例: `expr` やバッククォート `` `cmd` ``）は禁止。
    - モダンな構文（例: `[[ ... ]]`, `$(( ... ))`, `$(cmd)`）を使用する。
    - 外部コマンドより、可能な限り Bash ビルトイン機能を使用しパフォーマンスを優先する。

- **No Hallucinations**:
    - 存在しないフラグやオプションを捏造しない。必ず `man` や公式ドキュメントで確認する。

- **Clean Code**:
    - コメントは **英語 (English)** で統一。
    - 関数には `shdoc` 形式のアノテーション（`# @description`, `# @arg`）を付与する。
    - デバッグ用 `echo` や `set -x` は作業完了時に必ず削除する。

- **Token Economy**:
    - 必要のないファイル（特に巨大なログやバイナリ）をコンテキストに読み込まない。
    - 会話が長引いた場合は `/compact` を提案する。

## コマンドエイリアス (Slash Commands Guidelines)

ユーザーが以下の意図を示した場合、AIは対応する `make` コマンドまたは直接コマンドを優先する。

- **アプリ起動**: `make run` (または `./main.sh`)
- **テスト**: `make test` (実体: `bats test/`)
    - 特定のテストのみ: `bats test/test_file.bats`
- **静的解析**: `make lint` (実体: `shellcheck -x ./**/*.sh`)
- **フォーマット**: `make format` (実体: `shfmt -l -w -i 2 .`)
- **依存追加**: シェルにパッケージマネージャはないため、ユーザーに `brew install`, `apt-get install` などを提案するか、`lib/` へのサブモジュール追加を提案する。

## 重要制約

- **ハードコード絶対禁止**: パス、トークン、環境依存の値は環境変数または引数から受け取ること。
- **Eval禁止**: セキュリティリスクの高い `eval` は原則使用禁止。必要な場合は代替案を徹底的に模索すること。

## コマンドエイリアス (Slash Commands Guidelines)

ユーザーが以下の意図を示した場合、AIは対応するコマンドライン操作を優先する。
**注意: ホストはWindowsだが、プロジェクトはLinux用であるため、実行は全てDocker経由で行うこと。**

### Systemd統合テスト (Docker Compose)

- **ラボ起動**: `docker compose up -d`
- **Systemdインストール**: `docker compose exec lab make install-systemd`
- **Cronインストール**: `docker compose exec lab make install-cron`
- **アンインストール**: `docker compose exec lab make uninstall`
- **ラボ破棄**: `docker compose down`
- 