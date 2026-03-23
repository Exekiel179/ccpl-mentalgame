# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Godot 4.6** game project targeting **Mobile** rendering (D3D12 on Windows), with a 1280×720 viewport. The project is in early development — no game scenes or scripts exist yet beyond the MCP tooling.

本项目的主要目的是开发一个可玩的2D的游戏，强化玩家的认知重构能力，借此锻炼玩家的心理健康技能。游戏分为 两个实现的层面，1是局外的心理健康知识的介绍，比如为什么认知重构是有效的，2是局内的对战模式，类似纸镜奇缘，需要玩家利用键盘或者鼠标快速给一些句子，诸如“我完蛋了”进行分类，划分是事实还是想法，可以加更多的干扰项，如果在倒计时结束前没有正确回答，或者做出错误回答就掉心理健康值，如果值没有了，游戏失败  这是第一关，模仿纸镜奇缘的小游戏。需要调用env中的gemini的key 生成合适的游戏场景立绘。游戏可以基于一些背景知识，比如学业压力，家庭矛盾，社交压力等。

## Development Setup

**Two processes must both be running to work with this project via Claude Code:**

1. **Godot Editor** — open `F:\Projects\game_new` as the project in Godot 4.6
2. **MCP Bridge** — runs automatically via `.mcp.json` using `start_godot_mcp.bat`, which launches `npx -y godot-mcp-server` on `ws://127.0.0.1:6505`

The Godot editor toolbar shows "MCP: Connected" (green) when the bridge is active. If it shows red/disconnected, restart the MCP server via the bat file.

## MCP Bridge Architecture

The `addons/godot_mcp/` plugin acts as a WebSocket client inside the Godot editor:

- `plugin.gd` — EditorPlugin entry point; manages connection lifecycle and routes tool requests
- `mcp_client.gd` — WebSocket client that connects to the external MCP server process
- `tool_executor.gd` — Dispatches incoming tool calls to the appropriate tool module
- `tools/` — Individual tool modules: `scene_tools.gd`, `script_tools.gd`, `file_tools.gd`, `asset_tools.gd`, `project_tools.gd`, `visualizer_tools.gd`

Claude Code sends MCP tool calls → `godot-mcp-server` (Node.js process) → WebSocket → Godot editor plugin → executes in editor context.

## Key Project Settings

- Main scene: `res://main.tscn` (not yet created)
- Renderer: Mobile (`rendering/renderer/rendering_method = "mobile"`)
- Platform target: Windows with D3D12

## GDScript Conventions

- Use Godot 4 syntax (no Godot 3 compatibility shims)
- Prefer typed GDScript (`var x: int`, `func foo() -> void`)
- Use `@export` for inspector-visible properties
- Signal connections use `.connect()` (not the old `connect()` with string method names)
