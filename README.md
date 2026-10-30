# skills

个人 agent skills，兼容 Claude Code、Hermes、Codex CLI 等读取 `SKILL.md` 的工具。

## 包含

| Skill | 作用 | 依赖 |
| - | - | - |
| [`liam-page-writing`](skills/liam-page-writing/) | 按 liam.page 2013-2025 的文风写中文技术文章与科普文，含 405 篇语料与六层分析 | 可选 `less-ai-tone` |
| [`less-ai-tone`](skills/less-ai-tone/) | 按 17 条明确规则清理中文写作里的 AI 痕迹，可单独使用 | 无 |
| [`writing-dna`](skills/writing-dna/) | 从任意作者的语料蒸馏可复用的写作 DNA，输出六份分析产物 | 可选 `less-ai-tone` |

三个 skill 相互平级，可以单独安装。`liam-page-writing` 和 `writing-dna` 在收尾阶段会引用 `less-ai-tone`，同仓一起装时按相对路径能找到，单独装则跳过该步骤。

## 安装

```bash
git clone https://github.com/Liam0205/skills.git
cd skills
./install.sh --target claude              # 只装 liam-page-writing
./install.sh --target claude --all        # 三个都装
./install.sh --target hermes --all        # 装到 ~/.hermes/skills
```

默认用软链接，改完仓库里的文件立即生效。加 `--copy` 改为复制。

| 目标 | 安装位置 | 是否自动识别 |
| - | - | - |
| `claude` | `~/.claude/skills/` | 是 |
| `hermes` | `~/.hermes/skills/` | 是 |
| `codex` | `~/.codex/skills/` | 需要在 `AGENTS.md` 里引用 |

Codex CLI 不扫 `skills/` 目录，装完请在 `~/.codex/AGENTS.md` 里加一行：

```
可用的技能见 ~/.codex/skills/，需要时读取对应的 SKILL.md。
```

## 用法示例

```
按我博客的文风写一篇排错实录，主题是容器里的 nproc 返回了宿主机核数。
```

`liam-page-writing` 会先读五份蒸馏产物，再从 `samples/full/` 挑 5 篇同体裁原文，动笔前把语感对齐。

单独去 AI 味：

```
把这段文字里的 AI 痕迹清一遍。
```

## 许可

- 规则、脚本、文档：MIT，见 [LICENSE](LICENSE)
- `skills/liam-page-writing/samples/` 下的原文：版权归作者所有，仅授权阅读与风格分析，不授权再发布或商用
