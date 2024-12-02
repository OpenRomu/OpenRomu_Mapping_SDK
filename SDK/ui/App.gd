extends Control

const ConfigFilePath = "user://Config.res"

var config : Config;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    DisplayServer.window_set_min_size(Vector2(400, 400));
    DisplayServer.window_set_title("OpenRomu SDK v%s" % ProjectSettings.get_setting("application/config/version"));
    get_viewport().gui_embed_subwindows = false;
    config = Config.loadFromDisk();
    get_node("Container/Layout/MenuBar/File").connect("index_pressed", Callable(self, "filePressed"));
    get_node("Container/Layout/MenuBar/?").connect("index_pressed", Callable(self, "questionPressed"));
    get_node("Container/Layout/Panel/MarginContainer/Layout/MapEditor").connect("pressed", Callable(self, "openMapEditor"));
    get_node("Container/Layout/Panel/MarginContainer/Layout/BundleMap").connect("pressed", Callable(self, "openPAKBundler"));
    get_node("Container/Layout/Panel/MarginContainer/Layout/BundleWAD").connect("pressed", Callable(self, "openWADBundler"));
    get_node("Container/Layout/Panel/MarginContainer/Layout/OpenFiles").connect("pressed", Callable(self, "openFileExplorer").bind("OpenRomu"));
    get_node("Container/Layout/Panel/MarginContainer/Layout/Website").connect("pressed", Callable(self, "openWebsite").bind("https://openromu.fr"));
    get_node("Container/Layout/Panel/MarginContainer/Layout/XHLTGithub").connect("pressed", Callable(self, "openWebsite").bind("https://github.com/seedee/SDHLT"));
    # Game version
    get_node("Container/Layout/Bottom/GameVersion/VersionDropdown").select(0);
    
func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        config.saveToDisk();
        get_tree().quit();
        
func filePressed(index):
    if index == 0:
        openConfigureMapEditor(false);

func questionPressed(index):
    if index == 0:
        get_node("AboutDialog").visible = true;
    

func openMapEditor():
    if config.mapEditorPath.is_empty():
        openConfigureMapEditor(true);
        return;
    OS.create_process(config.mapEditorPath, []);

func openConfigureMapEditor(openEditorAfter : bool = false):
    var mapEditorDialog = get_node("ConfigureMapEditorDialog");
    # ConfigureMapEditorDialog
    mapEditorDialog.setMapEditorDialogPath(config.mapEditorPath);
    mapEditorDialog.visible = true;
    if openEditorAfter:
        openMapEditor();

func openWebsite(websiteUrl : String):
    OS.shell_open(websiteUrl);

func openFileExplorer(path : String):
    if OS.has_feature("linux"):
        OS.execute("xdg-open", ["."], []);
    else:
        OS.shell_show_in_file_manager(path, true);

func openPAKBundler():
    get_node("PakBundlerUI/BundlerWindow").visible = true;

func openWADBundler():
    get_node("WADBundlerUI/BundlerWindow").visible = true;

# Utils

func openFileBrowser(fileMode : FileDialog.FileMode, filters : Array, signalName : String, callback : Callable):
    var fileDialog = get_node("FileDialog");
    fileDialog.set_current_file("");
    fileDialog.file_mode = fileMode;
    fileDialog.filters = filters;
    # Disconnect signals because it could be linked to another
    for dict in fileDialog[signalName].get_connections():
        fileDialog[signalName].disconnect(dict.callable);
    # Connect
    fileDialog.connect(signalName, callback);
    fileDialog.visible = true;
