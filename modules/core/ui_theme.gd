class_name UITheme
extends RefCounted
## 黑白扁平化 UI 主题
## 所有面板和按钮使用统一的样式，无装饰色彩

# === 面板样式 ===

static func apply_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.06, 0.95)
	style.border_color = Color(0.7, 0.7, 0.7, 0.4)
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)


# === 主按钮（白色填充） ===

static func style_btn_primary(btn: Button) -> void:
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.9, 0.9, 0.9, 1.0)
	cs.corner_radius_top_left = 4
	cs.corner_radius_top_right = 4
	cs.corner_radius_bottom_left = 4
	cs.corner_radius_bottom_right = 4
	cs.content_margin_top = 8
	cs.content_margin_bottom = 8
	cs.content_margin_left = 16
	cs.content_margin_right = 16
	btn.add_theme_stylebox_override("normal", cs)

	var cs_h := StyleBoxFlat.new()
	cs_h.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	cs_h.corner_radius_top_left = 4
	cs_h.corner_radius_top_right = 4
	cs_h.corner_radius_bottom_left = 4
	cs_h.corner_radius_bottom_right = 4
	cs_h.content_margin_top = 8
	cs_h.content_margin_bottom = 8
	cs_h.content_margin_left = 16
	cs_h.content_margin_right = 16
	btn.add_theme_stylebox_override("hover", cs_h)

	var cs_p := StyleBoxFlat.new()
	cs_p.bg_color = Color(0.65, 0.65, 0.65, 1.0)
	cs_p.corner_radius_top_left = 4
	cs_p.corner_radius_top_right = 4
	cs_p.corner_radius_bottom_left = 4
	cs_p.corner_radius_bottom_right = 4
	cs_p.content_margin_top = 8
	cs_p.content_margin_bottom = 8
	cs_p.content_margin_left = 16
	cs_p.content_margin_right = 16
	btn.add_theme_stylebox_override("pressed", cs_p)

	btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.2, 0.2, 0.2, 1.0))


# === 次要按钮（白色边框，透明底） ===

static func style_btn_secondary(btn: Button) -> void:
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	cs.border_color = Color(0.5, 0.5, 0.5, 0.6)
	cs.border_width_bottom = 1
	cs.border_width_top = 1
	cs.border_width_left = 1
	cs.border_width_right = 1
	cs.corner_radius_top_left = 4
	cs.corner_radius_top_right = 4
	cs.corner_radius_bottom_left = 4
	cs.corner_radius_bottom_right = 4
	cs.content_margin_top = 8
	cs.content_margin_bottom = 8
	cs.content_margin_left = 16
	cs.content_margin_right = 16
	btn.add_theme_stylebox_override("normal", cs)

	var cs_h := StyleBoxFlat.new()
	cs_h.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	cs_h.border_color = Color(0.8, 0.8, 0.8, 0.8)
	cs_h.border_width_bottom = 1
	cs_h.border_width_top = 1
	cs_h.border_width_left = 1
	cs_h.border_width_right = 1
	cs_h.corner_radius_top_left = 4
	cs_h.corner_radius_top_right = 4
	cs_h.corner_radius_bottom_left = 4
	cs_h.corner_radius_bottom_right = 4
	cs_h.content_margin_top = 8
	cs_h.content_margin_bottom = 8
	cs_h.content_margin_left = 16
	cs_h.content_margin_right = 16
	btn.add_theme_stylebox_override("hover", cs_h)

	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))


# === 关闭按钮（右上角X） ===

static func style_btn_close(btn: Button) -> void:
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	cs.corner_radius_top_left = 3
	cs.corner_radius_top_right = 3
	cs.corner_radius_bottom_left = 3
	cs.corner_radius_bottom_right = 3
	cs.content_margin_top = 2
	cs.content_margin_bottom = 2
	cs.content_margin_left = 6
	cs.content_margin_right = 6
	btn.add_theme_stylebox_override("normal", cs)

	var cs_h := StyleBoxFlat.new()
	cs_h.bg_color = Color(0.25, 0.25, 0.25, 0.8)
	cs_h.corner_radius_top_left = 3
	cs_h.corner_radius_top_right = 3
	cs_h.corner_radius_bottom_left = 3
	cs_h.corner_radius_bottom_right = 3
	cs_h.content_margin_top = 2
	cs_h.content_margin_bottom = 2
	cs_h.content_margin_left = 6
	cs_h.content_margin_right = 6
	btn.add_theme_stylebox_override("hover", cs_h)

	btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))

static func style_list_item(btn: Button) -> void:
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.12, 0.12, 0.12, 0.9)
	cs.border_color = Color(0.4, 0.4, 0.4, 0.5)
	cs.border_width_bottom = 1
	cs.border_width_top = 1
	cs.border_width_left = 1
	cs.border_width_right = 1
	cs.corner_radius_top_left = 4
	cs.corner_radius_top_right = 4
	cs.corner_radius_bottom_left = 4
	cs.corner_radius_bottom_right = 4
	cs.content_margin_top = 6
	cs.content_margin_bottom = 6
	cs.content_margin_left = 12
	cs.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", cs)

	var cs_h := StyleBoxFlat.new()
	cs_h.bg_color = Color(0.2, 0.2, 0.2, 0.95)
	cs_h.border_color = Color(0.7, 0.7, 0.7, 0.8)
	cs_h.border_width_bottom = 1
	cs_h.border_width_top = 1
	cs_h.border_width_left = 1
	cs_h.border_width_right = 1
	cs_h.corner_radius_top_left = 4
	cs_h.corner_radius_top_right = 4
	cs_h.corner_radius_bottom_left = 4
	cs_h.corner_radius_bottom_right = 4
	cs_h.content_margin_top = 6
	cs_h.content_margin_bottom = 6
	cs_h.content_margin_left = 12
	cs_h.content_margin_right = 12
	btn.add_theme_stylebox_override("hover", cs_h)

	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
