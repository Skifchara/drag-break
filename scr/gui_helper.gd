class_name GUIHelper

## GUIHelper — утилита для создания UI-элементов из Basic_GUI_Bundle.
## Константы путей + простые static-функции для иконок/рядов звёзд.
## Кнопки создаются в .tscn через PremadeButtons (icon) — без StyleBoxTexture.

const BASE: String = "res://Basic_GUI_Bundle/"

# --- Premade text buttons ---
const BTN_RESUME: String = BASE + "ButtonsText/PremadeButtons_Resume.png"
const BTN_REPLAY: String = BASE + "ButtonsText/PremadeButtons_Replay.png"
const BTN_EXIT: String = BASE + "ButtonsText/PremadeButtons_ExitRed.png"
const BTN_MENU: String = BASE + "ButtonsText/PremadeButtons_Menu.png"
const BTN_SELECT: String = BASE + "ButtonsText/PremadeButtons_Select.png"
const BTN_YES: String = BASE + "ButtonsText/PremadeButtons_YesGreen.png"
const BTN_NO: String = BASE + "ButtonsText/PremadeButtons_No.png"
const BTN_CHECK: String = BASE + "ButtonsText/PremadeButtons_Check.png"
const BTN_OPTIONS: String = BASE + "ButtonsText/PremadeButtons_Options.png"
const BTN_SHOP: String = BASE + "ButtonsText/PremadeButtons_Shop.png"

# --- Button backgrounds (for custom text overlay) ---
const BTN_LG_BLUE_SQUARE: String = BASE + "ButtonsText/ButtonText_Large_Blue_Square.png"
const BTN_LG_GREEN_SQUARE: String = BASE + "ButtonsText/ButtonText_Large_Green_Square.png"
const BTN_LG_ROUND: String = BASE + "ButtonsText/ButtonText_Large_Round.png"
const BTN_LG_BLUE_ROUND: String = BASE + "ButtonsText/ButtonText_Large_Blue_Round.png"
const BTN_LG_GREEN_ROUND: String = BASE + "ButtonsText/ButtonText_Large_Green_Round.png"
const BTN_LG_ORANGE_ROUND: String = BASE + "ButtonsText/ButtonText_Large_Orange_Round.png"

# --- Icon backgrounds ---
const ICON_LG_BG_ROUNDED: String = BASE + "ButtonsIcons/IconButton_Large_Background_Rounded.png"
const ICON_SM_BG_ROUNDED: String = BASE + "ButtonsIcons/IconButton_Small_Background_Rounded.png"

# --- Stars / Hearts ---
const STAR_FULL: String = BASE + "Icons/Icon_Large_Star.png"
const STAR_GREY: String = BASE + "Icons/Icon_Large_StarGrey.png"
const STAR_OUTLINE: String = BASE + "Icons/Icon_Large_Star_WhiteOutline.png"
const HEART_FULL: String = BASE + "Icons/Icon_Large_HeartFull.png"
const HEART_EMPTY: String = BASE + "Icons/Icon_Large_HeartEmpty.png"

# --- Banners / Boxes ---
const BANNER_BLUE: String = BASE + "BoxesBanners/Banner_Blue.png"
const BANNER_GREEN: String = BASE + "BoxesBanners/Banner_Green.png"
const BANNER_ORANGE: String = BASE + "BoxesBanners/Banner_Orange.png"
const BANNER_RED: String = BASE + "BoxesBanners/Banner_Red.png"
const BANNER_GREY: String = BASE + "BoxesBanners/Banner_Grey.png"
const BOX_BLUE_ROUNDED: String = BASE + "BoxesBanners/Box_Blue_Rounded.png"
const BOX_ORANGE_ROUNDED: String = BASE + "BoxesBanners/Box_Orange_Rounded.png"
const BOX_BLANK_ROUNDED: String = BASE + "BoxesBanners/Box_Blank_Rounded.png"

# --- Lock icon ---
const ICON_LOCK: String = BASE + "Icons/Icon_Small_Lock.png"
const ICON_PAUSE: String = BASE + "Icons/Icon_Small_Blank_Pause.png"
const ICON_RETURN: String = BASE + "Icons/Icon_Small_Blank_Return.png"


## Создать иконку — TextureRect
static func make_icon(texture_path: String, size: Vector2 = Vector2(32, 32)) -> TextureRect:
	var rect := TextureRect.new()
	var tex: Texture2D = load(texture_path)
	if tex:
		rect.texture = tex
	rect.custom_minimum_size = size
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return rect


## Создать HBoxContainer со звёздами (серия иконок)
static func make_stars_row(count: int, total: int = 3, star_size: Vector2 = Vector2(48, 48)) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for i in range(total):
		var path: String = STAR_FULL if i < count else STAR_GREY
		var icon := make_icon(path, star_size)
		row.add_child(icon)
	return row


## Создать кнопку-уровень — flat кнопка с текстом + цвет фона.
## Для заблокированных — замок + серый.
static func make_level_cell(level_num: int, unlocked: bool, completed: bool, stars: int, cell_size: Vector2 = Vector2(100, 100)) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = cell_size

	if not unlocked:
		btn.text = ""
		btn.disabled = true
		btn.icon = load(ICON_LOCK)
		btn.icon_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
	elif completed and stars > 0:
		btn.text = "%d\n%s" % [level_num, "★".repeat(stars)]
		btn.flat = false
		# Оранжевый — пройденный
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.85, 0.55, 0.15, 0.9)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 4
		style.content_margin_right = 4
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		btn.text = str(level_num)
		btn.flat = false
		# Синий — доступный
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.45, 0.75, 0.9)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 4
		style.content_margin_right = 4
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", style)
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.25, 0.55, 0.85, 0.95)
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		hover.content_margin_left = 4
		hover.content_margin_right = 4
		hover.content_margin_top = 4
		hover.content_margin_bottom = 4
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", Color.WHITE)

	btn.focus_mode = Control.FOCUS_ALL
	return btn
