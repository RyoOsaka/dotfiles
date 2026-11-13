# Global Rules (AGENTS.md / GEMINI.md / CLAUDE.md)

## Language Preference
- ユーザーとの会話、質問への回答、説明、およびアーティファクト（ドキュメント等）の作成は、特に指定がない限り常に**日本語**で行ってください。

## Safety & Data Protection (Google Workspace / Backlog)
- **削除操作の完全禁止**: Google Workspace (`gws` CLI) および Backlog MCP において、既存のファイル・ドキュメント・予定・メール・課題・コメント等を削除する操作（`delete`, `trash`, `remove`, `clear` 等）は**いかなる場合も絶対に実行しないでください**。
- **書き込み・更新時の事前確認**: 新規作成・追記・ステータス更新などの変更系操作を行う場合は、必ず事前に `--dry-run`（対応している場合）や変更内容のプレビューを提示し、ユーザーの明示的な許可を得てから実行してください。
