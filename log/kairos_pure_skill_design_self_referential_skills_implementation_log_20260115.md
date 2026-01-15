# Kairos Pure Skills DSL 実装ログ

**Date**: 2026-01-15
**Status**: Completed

## 概要

Kairos Pure Skills Design に基づき、SUSHI MCP Server に自己言及・自己改変可能なスキルシステムを実装した。

---

## 実装の経緯

### Phase 1: DSL/AST 基盤 (2026-01-15 AM)

**背景**: `skills.md` (Markdown) の限界を克服し、実行可能・検証可能なスキル定義へ移行する必要があった。

**実装内容**:

1. **skills_dsl.rb** - Ruby DSL によるスキル定義
   - `Skill` Struct (id, title, use_when, requires, guarantees, depends_on, content, behavior)
   - `SkillBuilder` DSL クラス
   - `SkillsDsl.load` による動的ロード

2. **skills_ast.rb** - Ruby AST 解析
   - `RubyVM::AbstractSyntaxTree` による構造解析
   - スキルノードの抽出
   - 基本的なバリデーション

3. **dsl_skills_provider.rb** - スキル提供インターフェース
   - list_skills, get_skill, search_skills
   - AST 検証機能

4. **MCP Tools**:
   - `skills_dsl_list` - DSL スキル一覧
   - `skills_dsl_get` - DSL スキル詳細取得
   - `skills_dsl_validate` - 構文検証
   - `skills_ast_inspect` - AST 構造表示
   - `skills_ast_diff` - 差分検出（プレースホルダー）

5. **skills/sushi.rb** - 初期 DSL ファイル作成

---

### Phase 2: Self-Evolution System (2026-01-15 PM)

**背景**: LLM が自身の行動を振り返り（自己言及）、必要に応じてスキルを改善（自己改変）する機能が必要だった。

**設計原則**: Minimum-Nomic
- ルールは進化可能
- ただし進化を統治するルールは厳格に制限
- 暴走を防ぐ安全機構を組み込む

**実装内容**:

1. **action_log.rb** - 行動履歴記録（自己言及）
   - JSONL 形式でログ保存
   - アクション、スキルID、詳細を記録
   - 履歴参照・クリア機能

2. **skills_config.rb** - 設定管理（ON/OFF 制御）
   - `evolution_enabled` - 自己改変の有効/無効
   - `require_human_approval` - 人間承認の要否
   - `immutable_skills` - 変更不可スキル指定
   - `max_evolutions_per_session` - セッション当たりの進化回数制限

3. **version_manager.rb** - バージョン管理（ロールバック）
   - スナップショット作成
   - バージョン一覧
   - ロールバック実行
   - diff 機能

4. **safe_evolver.rb** - 安全な自己改変
   - 提案 (propose) と適用 (apply) の分離
   - サンドボックス検証
   - 人間承認フロー
   - 不変スキル保護

5. **MCP Tools**:
   - `skills_action_log` - 行動履歴参照
   - `skills_config` - 設定管理
   - `skills_rollback` - ロールバック
   - `skills_evolve` - 変更提案・適用

---

### Phase 3: Pure Skills DSL Extension (2026-01-15 PM)

**背景**: Pure Skill Design 仕様に完全準拠するため、DSL を拡張する必要があった。

**設計原則**:
- P1: スキルはデフォルトで純粋（副作用なし）
- P2: 副作用は名前付きコンテキストでスコープ化
- P3: 自己参照は構造的（魔法ではない）
- P4: 進化は制約される（Minimum-Nomic）

**実装内容**:

1. **skills_dsl.rb 拡張**
   - `Skill` Struct に追加: version, inputs, effects, evolution_rules, created_at
   - `can_evolve?`, `history` メソッド追加
   - `SkillBuilder` に version, inputs, guarantees（ブロック形式）, effect, evolve 追加

2. **skill_contexts.rb** (新規)
   - `GuaranteesContext` - 宣言的な保証条件収集
   - `EffectContext` - 名前付き副作用コンテキスト
   - `EvolveContext` - 進化ルール管理

3. **kairos.rb** (新規)
   - `Kairos` モジュール - グローバル自己参照
   - `skills`, `skill(id)`, `reload!`, `history`, `config`, `evolution_enabled?`
   - `SkillHistory` クラス - スキル履歴アクセス

4. **safe_evolver.rb 拡張**
   - `evolve` DSL ルールとの統合
   - `Kairos` モジュール経由でのスキル取得
   - フィールド単位の進化許可/拒否チェック

5. **skills/sushi.rb 更新**
   - 新 DSL 構文への移行
   - `core_safety`, `self_inspection`, `action_history` スキル追加

---

## 最終ファイル構成

```
lib/sushi_mcp/
├── skills_dsl.rb          # DSL コア（拡張済み）
├── skill_contexts.rb      # コンテキストクラス群
├── kairos.rb              # 自己参照モジュール
├── dsl_skills_provider.rb # スキル提供インターフェース
├── skills_ast.rb          # AST 解析
├── action_log.rb          # 行動履歴
├── skills_config.rb       # 設定管理
├── version_manager.rb     # バージョン管理
├── safe_evolver.rb        # 安全な進化
└── tools/
    ├── skills_dsl_list.rb
    ├── skills_dsl_get.rb
    ├── skills_dsl_validate.rb
    ├── skills_ast_inspect.rb
    ├── skills_ast_diff.rb
    ├── skills_action_log.rb
    ├── skills_config_tool.rb
    ├── skills_rollback.rb
    └── skills_evolve.rb

skills/
├── sushi.md               # 既存 Markdown スキル（互換性維持）
├── sushi.rb               # 新 DSL スキル
├── config.yml             # 設定ファイル
├── action_log.jsonl       # 行動ログ（生成）
└── versions/              # スナップショット格納
```

---

## 検証結果

### 1. DSL ロードテスト

```bash
$ ruby -e "
require_relative 'lib/sushi_mcp/skills_dsl'
require_relative 'lib/sushi_mcp/skill_contexts'
dsl = SushiMcp::SkillsDsl.new
dsl.skills.each { |s| puts \"#{s.id}: v#{s.version}\" }
"
# Output:
# core_safety: v1.0
# self_inspection: v1.0
# arch_010: v1.0
# arch_020: v1.0
# action_history: v1.0
```

### 2. Kairos 自己参照テスト

```bash
$ ruby -e "
require_relative 'lib/sushi_mcp/kairos'
skills = SushiMcp::Kairos.skills
puts \"Total skills: #{skills.count}\"
safety = SushiMcp::Kairos.skill(:core_safety)
puts \"core_safety can_evolve?(:behavior): #{safety.can_evolve?(:behavior)}\"
"
# Output:
# Total skills: 5
# core_safety can_evolve?(:behavior): false
```

### 3. 進化提案テスト

```bash
$ ruby -e "
require_relative 'lib/sushi_mcp/safe_evolver'
result = SushiMcp::SafeEvolver.evolution_status(:core_safety)
puts result.to_json
"
# Output:
# {"skill_id":"core_safety","config_allows":false,"skill_rules":{"allowed":[],"denied":["guarantees","behavior"]}}
```

### 4. MCP ツール一覧

```bash
$ ruby -e "
require_relative 'lib/sushi_mcp/tool_registry'
registry = SushiMcp::ToolRegistry.new
puts registry.list_tools.map{|t| t[:name]}.sort
"
# Output includes: skills_dsl_list, skills_dsl_get, skills_evolve, skills_config, ...
```

---

## 運用ガイドライン

### evolution_enabled の運用

| 状態 | 用途 |
|------|------|
| **false (デフォルト)** | 通常運用。スキルは安定した仕様として機能 |
| **true** | 明示的な「進化セッション」時のみ有効化 |

**true にするタイミング**:

1. **スキル改善セッション** - 人間が明示的に許可した時
2. **監督下での実験** - 変更の影響を確認できる状態
3. **定期メンテナンス** - スケジュールされた改善作業

**運用フロー**:

```
1. evolution_enabled: true に設定
2. LLM がスキル改善を提案 (skills_evolve propose)
3. 人間が確認・承認
4. 変更を適用 (skills_evolve apply approved:true)
5. 検証後、evolution_enabled: false に戻す
```

---

## 今後の拡張案

1. **条件付き自動有効化** - 特定条件下で限定的に進化を許可
2. **時間制限付き有効化** - 一定時間後に自動で OFF
3. **承認待ちキュー** - 提案を溜めておき、後でまとめて承認
4. **semantic diff** - AST レベルでの意味的差分検出
5. **PoC 連携** - Proof of Contribution/Cooperation/Coevolution との統合

---

## 関連ドキュメント

- [設計思想 (Pure Skill Design)](log/kairos_pure_skill_design_self_referential_skills_idea_20260115.md)
- [DSL/AST 設計提案](log/kairos_skills_dsl_ast_design_proposal_20260115.md)
- [Self-Evolution 実装プラン](log/kairos_self_evolution_implementation_plan_20260115.md)
- [Pure Skills 実装プラン](log/kairos_pure_skill_design_self_referential_skills_implementation_plan_20260115.md)

---

**Implemented by**: AI Coding Agent (Cursor / Claude)
**Date**: 2026-01-15
