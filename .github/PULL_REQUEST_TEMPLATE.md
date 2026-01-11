## 📋 変更内容 (Description)

<!-- このPRで何を変更したか、簡潔に説明してください -->

## 🎯 変更の目的 (Motivation and Context)

<!-- なぜこの変更が必要なのか説明してください -->
<!-- 関連する Issue がある場合はリンクしてください (例: Fixes #123) -->

Fixes #(issue番号)

## 📝 変更の種類 (Type of Change)

<!-- 該当するものにチェックを入れてください -->

- [ ] 🐛 バグ修正 (Bug fix - non-breaking change which fixes an issue)
- [ ] ✨ 新機能 (New feature - non-breaking change which adds functionality)
- [ ] 💥 破壊的変更 (Breaking change - fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 ドキュメント更新 (Documentation update)
- [ ] 🎨 コードスタイル改善 (Code style/refactoring - no functional changes)
- [ ] ⚡️ パフォーマンス改善 (Performance improvement)
- [ ] ✅ テスト追加/改善 (Test addition/improvement)
- [ ] 🔧 設定変更 (Configuration change)

## ✅ チェックリスト (Checklist)

<!-- 該当するものにチェックを入れてください -->

- [ ] コードは [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) に準拠している
- [ ] `make lint` (ShellCheck) を実行してエラーがない
- [ ] `make format` (shfmt) でコードをフォーマットした
- [ ] `make test` (bats-core) を実行してすべてのテストが通過した
- [ ] 新機能の場合、適切なテストを追加した
- [ ] 破壊的変更の場合、README.md を更新した
- [ ] コミットメッセージは [Conventional Commits](https://www.conventionalcommits.org/) に従っている

## 🧪 テスト方法 (How Has This Been Tested?)

<!-- どのようにテストしたか説明してください -->

テスト環境:
- OS: (例: Ubuntu 22.04, Raspberry Pi OS Bookworm)
- Bash バージョン: (例: 5.1.16)
- 実行コマンド:

```bash
# テストに使用したコマンドを記載
make test
sudo adguardhome-280blocker-filter-update -v
```

## 📸 スクリーンショット/ログ (Screenshots/Logs)

<!-- 該当する場合、実行結果やログを貼り付けてください -->

```
# ここにログを貼り付け
```

## 🔗 関連情報 (Related Issues/PRs)

<!-- 関連する Issue や PR があればリンクしてください -->

- Related to #
- Depends on #

## 📄 追加情報 (Additional Notes)

<!-- その他、レビュアーが知っておくべき情報があれば記載してください -->
