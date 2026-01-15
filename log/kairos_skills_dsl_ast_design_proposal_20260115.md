# Kairos Skills DSL / AST 化 設計案（背景含む）

## 0. 本文書の目的

本書は、従来の `skills.md`（Markdown ベースの能力定義）を、**Ruby DSL / Ruby AST ベースの実行可能・進化可能なスキル定義（以下 skills.rb）へ移行するための設計思想および実装指針**を整理し、

- Cursor などの AI コーディングエージェント
- MCP（Model Context Protocol）Server
- Kairos（記憶するエージェントフレームワーク）

に共有可能な形で提示することを目的とする。

本設計は特定の LLM（例：Claude）に依存しない。AI コーディングエージェント（Claude / Cursor / Antigravity 等） / Antigravity など、**複数の AI コーディングエージェントが同一のスキル定義を参照・解釈できること**を前提とする。

また、本設計では **MCP Server が Ruby により実装されていること**を前提とし、Ruby のメタプログラミング能力（DSL / AST / 自己言及）を積極的に活用する。

本設計は単なる実装技術ではなく、**AI の能力を「プロンプト」から「存在条件」へ昇格させる試み**である。

---

## 1. 背景：skills.md の限界

### 1.1 skills.md の役割

従来の skills.md は以下を担ってきた。

- AI が「何ができるか」を理解するための宣言文書
- Claude / LLM に対する system / project context
- 人間が可読な能力仕様

### 1.2 構造的な限界

skills.md は本質的に **説明書（declarative text）** であり、以下の制約を持つ。

- 実行不能（評価・検証対象にならない）
- 動的に変化できない
- 自己言及・自己更新ができない
- バージョン差分が意味論的に扱えない

結果として、skills.md は

> 「AI が能力を *持っているように振る舞う*」

ための補助資料に留まる。

---

## 2. 前提概念の整理（初読者向け）

### 2.1 Kairos とは何か

**Kairos** は、本設計におけるエージェントフレームワークのコードネームである。

Kairos は次の性質を持つことを想定している。

- AI が提案した行動・判断・ルールを
- **人間と機械の双方が理解可能な中間表現（Ruby DSL / AST）として記憶する**
- 記憶された構造を再利用・再評価・再定義できる

すなわち Kairos は、

> 「その場限りの推論」ではなく、
> **時間の中で自己を再記述していく AI システム**

を目指す設計思想である。

### 2.2 Minimum-Nomic とは何か

**Minimum-Nomic** は、本設計におけるルール進化の安全原則である。

- Nomic：ルールを変更できるゲーム
- Minimum-Nomic：
  - ルール変更は可能
  - ただし「最小限の変更制約」を常に維持する

本設計では、

- スキル（ルール）をコードとして定義しつつ
- スキル自身が無制限に自己改変して暴走することを防ぐ

ための **安全設計原理**として Minimum-Nomic を採用する。

これは「完全固定ルール」でも「無制限自己改変」でもない、
**進化可能だがゲーム化されにくい中間状態**を目指す考え方である。

---

## 3. 問題設定：スキルをどこに定義すべきか

本設計の根本的な問いは次である。

> **AI の能力とは、プロンプトなのか？ ツールなのか？ それとも構造なのか？**

Kairos では、能力を以下のように再定義する。

- 能力 = 説明文 ❌
- 能力 = 外部 script ❌
- 能力 = **意味・条件・振る舞いを持つ構造（Structure）** ⭕

このため、skills.md を **Ruby DSL / AST** として再構築する。

---

## 3. 提案：skills.rb（Ruby DSL）の導入

### 3.1 基本コンセプト

- スキルを Ruby DSL として定義する
- DSL は Ruby AST として保存・評価可能
- AI は DSL / AST を「読む・説明する・提案する」存在になる

### 3.2 最小 DSL イメージ

```ruby
skill :pipeline_generation do
  requires :genomics_context
  guarantees :reproducibility

  behavior do |ctx|
    generate_pipeline(ctx)
  end
end
```

ここでスキルは：

- 名前
- 前提条件（requires）
- 保証条件（guarantees）
- 振る舞い（behavior）

を持つ **存在定義** である。

---

## 4. Ruby AST を採用する理由

### 4.1 AST は「意味を持つ履歴」

Ruby DSL は次のように AST 化できる。

```ruby
RubyVM::AbstractSyntaxTree.parse(code)
```

AST を採用することで：

- スキル定義の差分が取得可能
- スキル進化の履歴が保存可能
- PoC（Proof of Contribution / Cooperation / Coevolution）の根拠になる

### 4.2 スキルは「評価対象」になる

- 実行可否
- 制約違反
- 危険性
- 冗長性

を AST レベルで検査可能。

---

## 5. MCP Server との関係

### 5.1 全体アーキテクチャ

```text
Human
  ↓ edits
skills.rb (DSL)
  ↓ parse
Ruby AST
  ↓ filter / project
MCP Server
  ↓ context-specific skill projection
AI コーディングエージェント（Claude / Cursor / Antigravity 等）
```

### 5.2 Claude の役割

Claude は：

- skills.rb / AST を直接実行しない
- AST の **意味を解釈・説明・提案** する
- 修正案を生成する

Claude = 思考器官
Ruby / MCP = 記憶・法・統治

---

## 6. script 参照型 skills との違い

### 6.1 script 参照型

- skills.md が外部 script を「使える」と宣言
- script はブラックボックス
- AI はツール操作者

### 6.2 skills.rb 型

- script を DSL の behavior に内包可能
- script は意味構造の一部
- AI は構造の一部

> **script = 行為**
> **skills.rb = 存在条件**

---

## 7. 自己言及・Minimum-Nomic への拡張

skills.rb は自分自身を参照できる。

```ruby
skill :self_inspection do
  behavior do
    Kairos.skills.ast.each do |s|
      evaluate(s)
    end
  end
end
```

これにより：

- ルールがルールを記述する
- スキルが再定義可能になる
- Minimum-Nomic（ゲーム不能な自己更新系）が成立する

---

## 8. 失われるものと対策

### 8.1 失われるもの

- 非エンジニア向け可読性
- 即席プロンプトの気軽さ

### 8.2 対策

- DSL → Markdown 生成
- DSL → Human-readable spec 生成

```ruby
describe_skills(format: :markdown)
```

---

## 9. 本設計の位置づけ

本設計は：

- Kairos の中核
- GenomicsChain の PoC 思想
- Evolvable / CARE / TRUST の実装基盤

である。

> **AI の能力を、言語モデルの外に定義する**

これは単なる実装ではなく、
**AI を「進化する存在」として扱うための憲法設計**である。

---

## 10. 次フェーズ（実装ロードマップ案）

1. skills DSL 最小コア（10–20行）
2. AST 保存・diff 機構
3. MCP Server での skill projection
4. Claude による DSL 修正提案ループ
5. PoC / PoC² / PoC³ との接続

---

（本書は Cursor / LLM への入力文書として利用可能）

