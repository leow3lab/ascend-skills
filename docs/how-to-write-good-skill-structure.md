# Skill 目录结构示例
 
以下是典型的 skill 目录结构：
 
```
skill-name/
├── SKILL.md                  # 使用文档（必填，包含 YAML frontmatter）
├── scripts/                  # 脚本（可选）
│   └── example-script.py
├── references/               # 参考资料（可选）
│   ├── API-reference.md
│   ├── config-example.yaml
│   └── README.md
└── assets/                  # 静态资源（可选）
    ├── message-templates.txt
    └── icons/
```
 
## 目录说明
 
### SKILL.md
- **作用**：主要使用文档，提供快速开始、配置说明、注意事项等
- **内容结构**：简介 → 功能列表 → 使用方法 → 配置说明 → 注意事项 → 常见问题
- **必填字段**：以 `---` 包裹的 YAML frontmatter，包含 `name` 和 `description`
 
### scripts/
- **作用**：存放可执行脚本
- **适用场景**：
  - 独立工具脚本（如发送消息、数据采集）
  - 自动化任务脚本
  - 批处理脚本
- **命名规范**：使用小写字母和连字符，如 `send-welink.py`
 
### references/
- **作用**：存放参考文档、配置示例、API 文档等
- **适用场景**：
  - API 详细文档（`API-reference.md`）
  - 配置文件示例（`config-example.yaml`）
  - 开发指南、调试说明
- **命名规范**：使用描述性名称，必要时加 `example` 或 `template` 后缀
 
### assets/
- **作用**：存放静态资源文件
- **适用场景**：
  - 消息模板（`message-templates.txt`）
  - 图标、图片
  - 配置数据文件
  - SQL 查询模板
- **命名规范**：使用描述性名称，如 `message-templates.txt`
 
## 最小化结构
 
最精简的 skill 只需要一个文件：
 
```
minimal-skill/
└── SKILL.md             # 文档（必填，包含 YAML frontmatter）
```
 
适用于纯文档型 skill（如说明文档、使用指南）。
 
## 复杂结构示例
 
对于功能完整的 skill，可能包含丰富的资源：
 
```
complex-skill/
├── SKILL.md
├── scripts/
│   ├── main.py
│   ├── helper.py
│   └── deploy.sh
├── references/
│   ├── API-reference.md
│   ├── architecture.md
│   ├── config-example.yaml
│   └── troubleshooting.md
└── assets/
    ├── templates/
    │   └── email-template.html
    ├── data/
    │   └── sample-data.json
    └── icons/
        └── logo.png
```
 
## 创建建议
 
1. **先创建最小结构** - 先用 `SKILL.md` 跑通
2. **按需添加资源** - 根据需要逐步添加 scripts/references/assets
3. **验证格式** - 使用 `validate-skill.py` 检查硬编码和格式问题
4. **保持目录清晰** - 资源文件分类存放，便于维护