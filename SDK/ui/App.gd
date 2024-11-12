extends Control

const ConfigFilePath = "user://Config.res"

var config : Config;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    DisplayServer.window_set_min_size(Vector2(400, 400));
    DisplayServer.window_set_title("OpenRomu SDK v%s" % ProjectSettings.get_setting("application/config/version"));
    get_viewport().gui_embed_subwindows = false;
    config = Config.loadFromDisk();
    get_node("Container/Layout/Tree/MarginContainer/Layout/MapEditor").connect("pressed", Callable(self, "openMapEditor"));
    get_node("Container/Layout/Tree/MarginContainer/Layout/ConfigureMapEditor").connect("pressed", Callable(self, "openConfigureMapEditor"));
    get_node("Container/Layout/Tree/MarginContainer/Layout/BundleMap").connect("pressed", Callable(self, "openPAKBundler"));
    get_node("Container/Layout/Tree/MarginContainer/Layout/OpenFiles").connect("pressed", Callable(self, "openFileExplorer").bind("OpenRomu"));
    get_node("Container/Layout/Tree/MarginContainer/Layout/Website").connect("pressed", Callable(self, "openWebsite").bind("https://openromu.fr"));
    get_node("Container/Layout/Tree/MarginContainer/Layout/XHLTGithub").connect("pressed", Callable(self, "openWebsite").bind("https://github.com/seedee/SDHLT"));
    # Game version
    get_node("Container/Layout/Bottom/GameVersion/VersionDropdown").select(0);
    # ConfigureMapEditorDialog
    setMapEditorDialogPath(config.mapEditorPath);
    var mapEditorDialog = get_node("ConfigureMapEditorDialog");
    mapEditorDialog.connect("confirmed", Callable(self, "setMapEditorPath"));
    var browseButton = mapEditorDialog.get_node("Container/Container/Layout/Layout/BrowseButton");
    browseButton.connect("pressed", Callable(self, "browseMapEditor"));
    # ConfigureMapEditorDialog
    var browseEditorDialog = get_node("BrowseMapEditorDialog");
    browseEditorDialog.connect("file_selected", Callable(self, "setMapEditorDialogPath"));

func openMapEditor():
    if config.mapEditorPath.is_empty():
        openConfigureMapEditor();
        return;
    OS.create_process(config.mapEditorPath, []);

func openConfigureMapEditor():
    var mapEditorDialog = get_node("ConfigureMapEditorDialog");
    mapEditorDialog.visible = true;

func setMapEditorPath():
    var mapEditorDialog = get_node("ConfigureMapEditorDialog");
    var pathInput = mapEditorDialog.get_node("Container/Container/Layout/Layout/PathInput");
    config.mapEditorPath = pathInput.text;
    config.saveToDisk();

func setMapEditorDialogPath(path):
    var mapEditorDialog = get_node("ConfigureMapEditorDialog");
    var pathInput = mapEditorDialog.get_node("Container/Container/Layout/Layout/PathInput");
    pathInput.set_text(path);

func browseMapEditor():
    get_node("BrowseMapEditorDialog").visible = true;

func openWebsite(websiteUrl : String):
    OS.shell_open(websiteUrl);

func openFileExplorer(path : String):
    OS.shell_show_in_file_manager(path, true);

func openPAKBundler():
    get_node("PakBundlerUI/BundlerWindow").visible = true;
