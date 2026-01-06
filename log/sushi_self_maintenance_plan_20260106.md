# SUSHI Self-Maintenance MCP Server（Ruby / STDIO）設計案

> **目的（PoC）**：SUSHI App の開発支援を、Cursor / Claude Code などの MCP クライアントから呼び出せる **同一node・同一LAN内限定**の MCP server として提供する。
> **方針**：一般公開しない・production には入れない（test server用 repo のみ）・まずは **read-only** を中心に安全運用。

---

## 0. 前提・スコープ

### 前提

* 利用範囲：同一 node 上での限定利用（外部公開なし）
* SUSHI の **test server 用 repository** に MCP server を含める（production repo は別扱い）
* MCP transport：**STDIO**
* Ruby 実装（Python 依存を避け、Kairos/Chronos の思想と実装を統一）

### 初期スコープ（Phase 0〜1）

* **SUSHI App 開発支援**（検索・閲覧・構造理解）
* 安全性重視：書き込み・破壊的コマンド・デプロイ操作は行わない

---

## 1. 目標（Done定義）

### MVP（最低限）

* MCP server が STDIO で起動し、クライアントから接続できる
* `tools/list` で tool 一覧が返る
* `tools/call` で tool が動作し、テキスト結果を返す

### MVP Tool（最初に価値が出るセット）

1. `search_repo(query, path?, max_results?)`：ripgrep 検索
2. `read_file(path, max_bytes?)`：安全な範囲のファイル読み取り
3. `list_tree(path?, depth?)`：ディレクトリ構造の要約
4. `find_files(glob, path?)`：ファイル探索（例：`**/*controller*`）

> これで「どこに何がある？ → 検索 → 読む → 構造理解」が完結する。

---

## 2. ディレクトリ構成（SUSHI repo に含める）

推奨：repo ルートに `mcp/` を作り、SUSHI本体と明確に分離。

```
SUSHI/
  mcp/
    sushi_mcp_server.rb         # エントリ（STDIO）
    tool_registry.rb            # tool の自動登録・ディスパッチ
    safety.rb                   # SAFE_ROOT / blocklist 等
    tools/
      search_repo.rb
      read_file.rb
      list_tree.rb
      find_files.rb
      ...                       # 将来追加
    skills/
      sushi_dev_support.rb      # 開発支援 tool セット定義
      sushi_arch_support.rb     # アーキ支援 tool セット定義（将来）
    README.md                   # セットアップ・使い方
  app/
  lib/
  ...
```

---

## 3. MCP server アーキテクチャ

### 3.1 Transport（STDIO）

* MCP クライアントがプロセス起動し、stdin/stdout で JSON メッセージ交換
* Ruby は `STDIN.gets` のループで 1行JSON を受け取り処理

### 3.2 メッセージ処理（JSON-RPC風）

* `method` に応じて分岐

  * `initialize` / `mcp/initialize`
  * `tools/list` / `mcp/tools/list`
  * `tools/call` / `mcp/tools/call`

### 3.3 Tool Registry

* `mcp/tools/*.rb` を自動ロード
* tool はクラス or モジュール単位（単機能）
* `skills/*` は「toolセットの組み合わせ」を管理（用途別）

> **狙い**：tool を追加しても server 本体をほぼ触らず拡張できる。

---

## 4. 安全設計（最重要）

### 4.1 SAFE_ROOT 固定

* MCP server の起動ディレクトリ（SUSHI repo root）を `SAFE_ROOT` として固定
* `read_file` などは `SAFE_ROOT` 外のパスを拒否

### 4.2 ブロックリスト（機密ファイル保護）

* 以下は read を明示的に拒否（test repo でも混入しうる）

  * `.env`, `.env.*`
  * `config/master.key`
  * `credentials*.yml.enc`
  * `id_rsa`, `*.pem`, `*.key`
  * `*.sqlite3`（必要なら別対応）

### 4.3 出力制限

* `search_repo`：最大 N 行
* `read_file`：最大 N bytes
* `list_tree`：最大 depth

### 4.4 実行系 tool の扱い

* Phase 1 は **read-only**
* `run_command` は原則禁止
* 将来入れる場合は **allowlist 固定コマンドのみ**（例：`bundle exec rspec`）

---

## 5. Tool / Skill 設計指針

### 5.1 Tool（単機能・責務明確）

* 例：`SearchRepoTool`, `ReadFileTool` など
* 入力は JSON Schema で明示
* 出力は `content: [{type: "text", text: "..."}]` を基本に統一

### 5.2 Skill Pack（用途別に tool を束ねる）

#### Skill: SUSHI Dev Support（最初に作る）

* search_repo
* read_file
* list_tree
* find_files

#### Skill: SUSHI Architecture Support（将来拡張）

* summarize_structure（構造の要約）
* list_entrypoints（入口の列挙）
* trace_request_flow（簡易フロー推定）
* locate_feature（機能の所在探索）

#### Skill: SUSHI Feature Extension Support（将来）

* propose_patch（diff 提案のみ）
* generate_commit_message（補助）

> **ポイント**：Skill は「増えても迷子にならない」ための整理軸。

---

## 6. 運用フロー（Cursor / Claude Code から）

### 6.1 起動

* MCP client 側で stdio server として登録
* command 例：

  * `ruby /abs/path/to/SUSHI/mcp/sushi_mcp_server.rb`
* working directory：SUSHI repo root

### 6.2 使い方（想定）

1. AIが `tools/list` で tool を認識
2. `search_repo` で該当箇所を検索
3. `read_file` で詳細確認
4. `list_tree` で関連ディレクトリを把握
5. 変更案は AI が提示（PoCではパッチ適用は人間）

---

## 7. 開発ロードマップ（Phaseごとに停止して運用テスト）

> 方針：**全部を一括で作らず**、各Phaseの終わりで必ず「運用テスト」を行い、そこで得た知見を次Phaseに反映する。
> 目的：MCPがコンテキストを浪費しやすい問題を、**出力制限・Skills Retrieval・分割運用**で制御しながら、確実に価値が出るところまで段階的に育てる。

---

### Phase 0：Hello, World MCP（最小運用テスト）

**ゴール**：Cursor / Claude Code から「接続できる」ことだけを確認する。

* STDIO server のメッセージループを実装
* `initialize` を返せる
* `tools/list` が固定で1つ返る（例：`hello_world`）
* `tools/call(hello_world)` が固定メッセージを返す

**運用テスト項目**

* MCPクライアントから server を stdio として起動できるか
* `tools/list` が認識され、呼び出しができるか
* 返答がUIに表示されるか（テキストでOK）
* ログ（stderr）で異常が出ていないか

> Phase 0 では repo の安全性や tool の本体はまだ作らない。まず「つながる」ことが最重要。

---

### Phase 1：Dev Support MVP（read-only、最小で効く）

**ゴール**：SUSHI 開発支援として「検索→読む」が成立し、日常で使える。

* `search_repo(query, path?, max_results?)`
* `read_file(path, max_bytes?)`
* 安全設計の導入

  * SAFE_ROOT 固定（SUSHI repo root）
  * blocklist（.env / key類等）
  * 出力制限（lines/bytes）

**運用テスト項目**

* 実際のSUSHI開発タスクで1回使ってみる
* `search_repo` の返却量が適切か（多すぎないか）
* `read_file` の max_bytes が運用上十分か
* blocklist に誤検出/漏れがないか

---

### Phase 2：Structure Support（構造理解を高速化）

**ゴール**：アーキテクチャ理解の「入口」をAIが案内できる。

* `list_tree(path?, depth?)`
* `find_files(glob, path?)`
* `summarize_structure(path?, depth?)`（ディレクトリ要約：短く）

**運用テスト項目**

* 新規開発/改修の前に「構造把握」用途で使う
* treeが大きいrepoでもトークン浪費しないか（depth制御）

---

### Phase 3：Skills（.md）導入 + Retrieval（token節約の本丸）

**ゴール**：Skillsを“全文貼り”せず、必要箇所だけ取り出して使える。

#### 3.1 Skillsのドキュメント設計（atom化）

* `skills/` に短い断片として分割保存（例：arch/flows.md, dev/how_to_add_feature.md など）
* 見出しに固定IDを付与（例：`## [ARCH-010] Job Execution Flow`）

#### 3.2 AI用圧縮版（二層化）

* `skills_ai/` を作り、要点のみのbullet版（500–800 tokens目安）
* 原則：まず `skills_ai` を参照 → 足りなければ `skills` をピンポイント抽出

#### 3.3 Skills Retrieval tool（全文読ませない）

* `skills_list()`：利用可能なSkills一覧（短く）
* `skills_search(query, max_sections=3)`：該当セクション抽出（上限あり）
* `skills_get(section_id)`：ID指定でセクション取得
* `skills_summarize(topic)`：関連セクションを箇条書き要約

**運用テスト項目**

* アーキテクチャ質問（例：入口、データフロー）で Skills Retrieval を使う
* `read_file` で全文を返してしまう事故が起きないか
* Retrieval出力の上限が適切か（短すぎ/長すぎ）

---

### Phase 4：Architecture Support（推論補助 + ガイド化）

**ゴール**：feature拡張や設計判断を“迷わず進められる”支援へ。

* `list_entrypoints()`：入口候補を提示
* `locate_feature(feature_name)`：機能名→候補ファイル
* `trace_request_flow(endpoint)`：簡易フロー（推論ベース）

**運用テスト項目**

* 実際のfeature追加前に「どこを触るか」を絞れるか
* 推論の誤りを Skills 側にフィードバックして改善できるか

---

### Phase 5：提案型メンテ（書き込みはしない／人間が適用）

**ゴール**：AIがパッチを提案し、人間がapplyする運用で安全に加速。

* `propose_patch(file, diff)`：diff生成のみ
* `generate_commit_message()`

**運用テスト項目**

* 提案パッチがレビュー可能な品質か
* 変更手順が Skills に反映されているか

---

### Phase 6：限定実行（allowlist）※必要になったら

**ゴール**：安全な範囲でテスト・診断の実行を自動化。

* `run_tests()`：固定コマンドのみ
* `lint()`：固定コマンドのみ

**運用テスト項目**

* allowlist が十分に安全か
* 実行ログがトークン浪費しないよう要約されるか

---

## 8. 期待できる効果

* SUSHI の保守・改修で最も重い「理解コスト」を AI が吸収
* repo 内の構造理解・影響範囲の見積りが高速化
* Skills を Retrieval することで **トークン浪費を抑えつつ**品質を上げられる
* 将来的にセルフメンテ（自己更新可能なMCP）へ接続できる土台

---

## 9. 次に決めること（Phase 0開始前チェック）

1. `mcp/` を SUSHI repo に追加し、git管理に含めるか（test repoのみ）
2. Phase 0 で検証する MCP クライアント（Cursor / Claude Code）
3. server 起動コマンドと working directory の固定
4. Phase 0 のログ保存方法（stderr → file など）

