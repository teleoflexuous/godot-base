# Scene Node Guide

## General Rules

- Put permanent layout in scenes.
- Put transient binding and event forwarding in node-local scripts.
- Use exported properties for designer-tunable values.
- Use signals for ownership boundaries instead of polling another node's private state.
- Do not add a global singleton when a scene-owned node can express the behavior.

## 2D Starting Points

| Need | Preferred Nodes |
|---|---|
| Root gameplay surface | `Node2D` |
| Camera | `Camera2D` |
| Static collision | `StaticBody2D` + `CollisionShape2D` |
| Moving actor | `CharacterBody2D` or scene-local `Node2D` depending on physics needs |
| UI overlay | `CanvasLayer` + `Control` scenes |

## 3D Starting Points

| Need | Preferred Nodes |
|---|---|
| Root gameplay surface | `Node3D` |
| Camera | `Camera3D`, optionally under a pivot `Node3D` |
| Sun/global light | `DirectionalLight3D` |
| Environment | `WorldEnvironment` with a shared `Environment` resource |
| Static level collision | `StaticBody3D` + `CollisionShape3D` |
| Moving actor | `CharacterBody3D` when physics movement is needed |

## UI Starting Points

| Need | Preferred Nodes |
|---|---|
| Screens and panels | `Control`, `PanelContainer`, `MarginContainer` |
| Rows/columns | `HBoxContainer`, `VBoxContainer`, `GridContainer` |
| Modal-like flow | Built-in `Control` scenes first; consider ProperUI modal/drawer when behavior grows |
| Tooltips | Built-in tooltip first; consider `properUI_tooltip` for rich chained content |

## Script Boundary

- Attach scripts to the scene root when the script owns the whole scene contract.
- Attach scripts to child nodes only when the child has reusable behavior.
- Move code to `scripts/` only after two or more scenes share it.
- Move code to `addons/` only when it has an addon-local contract, docs, and tests.
