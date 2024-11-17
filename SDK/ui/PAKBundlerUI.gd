extends Window

const WadEntryPrefab = preload("res://ui/WADEntry.tscn");

var loadedPAKPath : String;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    connect("close_requested", Callable(self, "closeRequested"));
    var app = get_node("/root/App");
    get_node("Layout/TopContainer/SourcePAKButton").connect("pressed", Callable(app, "openFileBrowser").bind(FileDialog.FILE_MODE_OPEN_FILE, ["*.pak"], "file_selected", Callable(self, "PAKSelected")));
    get_node("Layout/Container/Container/Layout/Level/Button").connect("pressed", Callable(app, "openFileBrowser").bind(FileDialog.FILE_MODE_OPEN_FILE, ["*.bsp"], "file_selected", Callable(self, "levelSelected")));
    get_node("Layout/Container/Container/Layout/WADs/Button").connect("pressed", Callable(app, "openFileBrowser").bind(FileDialog.FILE_MODE_OPEN_FILES, ["*.wad"], "files_selected", Callable(self, "WADsSelected")));
    get_node("Layout/Container/Container/Layout/Preview/Button").connect("pressed", Callable(app, "openFileBrowser").bind(FileDialog.FILE_MODE_OPEN_FILE, ["*.bmp", "*.png", "*.jpg", "*.jpeg"], "file_selected", Callable(self, "previewSelected")));
    get_node("Layout/Container/Container/Layout/Sky/Button").connect("pressed", Callable(app, "openFileBrowser").bind(FileDialog.FILE_MODE_OPEN_FILE, ["*.bmp", "*.png", "*.jpg", "*.jpeg"], "file_selected", Callable(self, "skySelected")));
    get_node("Layout/BottomContainer/Layout/OutputFolder/Button").connect("pressed", Callable(app, "openFileBrowser").bind(FileDialog.FILE_MODE_OPEN_DIR, [], "dir_selected", Callable(self, "outputSelected")));
    get_node("Layout/BottomContainer/Layout/GenerateButton").connect("pressed", Callable(self, "validateAndGenerate"));

# File browser callbacks

func PAKSelected(pakPath : String):
    loadedPAKPath = pakPath;
    var reader = ZIPReader.new();
    if reader.open(pakPath) != OK:
        printStatus("PAK %s cannot be opened." % pakPath, Color.RED);
        return; #Error loading
    var metaData = reader.read_file("meta.json");
    if !metaData:
        printStatus("PAK has missing meta.json.", Color.RED);
        return;
    metaData = JSON.parse_string(metaData.get_string_from_utf8());
    get_node("Layout/Container/Container/Layout/Level/LineEdit").set_text("$PAK:%s" % metaData.level);
    get_node("Layout/Container/Container/Layout/Name/LineEdit").set_text(metaData.name);
    get_node("Layout/Container/Container/Layout/Author/LineEdit").set_text(metaData.author);
    get_node("Layout/Container/Container/Layout/Version/SpinBox").set_value(metaData.map_version);
    var gmNodes = get_node("Layout/Container/Container/Layout/GameModes").get_children();
    for i in range(0, metaData.gamemodes.size()):
        gmNodes[i].get_node("CheckBox").button_pressed = true;
    get_node("Layout/Container/Container/Layout/DescriptionEdit").set_text(metaData.description.en);
    WADsSelected(metaData.wads, true);
    get_node("Layout/Container/Container/Layout/License/LineEdit").set_text(metaData.license);
    var preview = "" if metaData.preview.is_empty() else "$PAK:%s" % metaData.preview;
    get_node("Layout/Container/Container/Layout/Preview/LineEdit").set_text(preview);
    var sky = "" if metaData.sky.is_empty() else "$PAK:%s" % metaData.sky;
    get_node("Layout/Container/Container/Layout/Sky/LineEdit").set_text(sky);
    get_node("Layout/BottomContainer/Layout/OutputFolder/LineEdit").set_text(pakPath.get_base_dir());
    printStatus("PAK loaded successfully.", Color.GREEN);

func levelSelected(levelPath : String):
    get_node("Layout/Container/Container/Layout/Level/LineEdit").set_text(levelPath);
    get_node("Layout/Container/Container/Layout/Name/LineEdit").set_text(levelPath.get_file().split(".")[0]);

func WADsSelected(WADsPath : Array, embedded : bool):
    var container = get_node("Layout/Container/Container/Layout/WADsList/Layout");
    for child in container.get_children():
        child.queue_free();
    for wad in WADsPath:
        var entry = WadEntryPrefab.instantiate();
        if embedded:
            wad = "$PAK:"+wad;
        entry.get_node("Label").set_text(wad);
        entry.get_node("RemoveButton").connect("pressed", Callable(entry, "queue_free"));
        container.add_child(entry);

func previewSelected(previewPath : String):
    get_node("Layout/Container/Container/Layout/Preview/LineEdit").set_text(previewPath);

func skySelected(skyPath : String):
    get_node("Layout/Container/Container/Layout/Sky/LineEdit").set_text(skyPath);

func outputSelected(outputPath : String):
    get_node("Layout/BottomContainer/Layout/OutputFolder/LineEdit").set_text(outputPath);

# Validation & Generation

func validateAndGenerate():
    var levelPath = get_node("Layout/Container/Container/Layout/Level/LineEdit").get_text();
    if levelPath.is_empty():
        printStatus("Level BSP is not set.", Color.RED);
        return; #Mandatory field
    elif PAKBundler.pathIsEmbedded(levelPath) && !PAKBundler.checkPAKFileExists(loadedPAKPath, levelPath):
            return; #file not in PAK
    elif !PAKBundler.pathIsEmbedded(levelPath) && !FileAccess.file_exists(levelPath):
            printStatus("Level %s cannot be found" % levelPath, Color.RED);
            return; #file not on disk
    var levelName = get_node("Layout/Container/Container/Layout/Name/LineEdit").get_text();
    if levelName.is_empty():
        printStatus("Level has no valid name.", Color.RED);
        return; #Mandatory field
    var author = get_node("Layout/Container/Container/Layout/Author/LineEdit").get_text();
    var mapVersion = get_node("Layout/Container/Container/Layout/Version/SpinBox").get_value();
    var gmNodes = get_node("Layout/Container/Container/Layout/GameModes").get_children();
    var gameModes = [];
    for i in range(0, gmNodes.size()):
        if gmNodes[i].get_node("CheckBox").button_pressed:
            gameModes.push_back(i);
    if gameModes.size() < 1:
        printStatus("Level has no valid gamemode.", Color.RED);
        return; #Not playable
    var description = get_node("Layout/Container/Container/Layout/DescriptionEdit").get_text();
    for wad in getSelectedWADs():
        if PAKBundler.pathIsEmbedded(wad) && !PAKBundler.checkPAKFileExists(loadedPAKPath, wad):
            printStatus("WAD %s is not in source PAK" % wad, Color.RED);
            return; #Wad missing in PAK
        elif !PAKBundler.pathIsEmbedded(wad) && !FileAccess.file_exists(wad):
            printStatus("WAD %s cannot be opened." % wad, Color.RED);
            return; #Wad does not exist
    var license = get_node("Layout/Container/Container/Layout/License/LineEdit").get_text();
    var previewPath = get_node("Layout/Container/Container/Layout/Preview/LineEdit").get_text();
    if !previewPath.is_empty():
        if PAKBundler.pathIsEmbedded(previewPath) && !PAKBundler.checkPAKFileExists(loadedPAKPath, previewPath):
                printStatus("Preview %s is not in source PAK" % previewPath, Color.RED);
                return; #file not in PAK
        elif !PAKBundler.pathIsEmbedded(previewPath) && !FileAccess.file_exists(previewPath):
                printStatus("Preview %s cannot be found" % previewPath, Color.RED);
                return; #file not on disk
    var skyPath = get_node("Layout/Container/Container/Layout/Sky/LineEdit").get_text();
    if !skyPath.is_empty():
        if PAKBundler.pathIsEmbedded(skyPath) && !PAKBundler.checkPAKFileExists(loadedPAKPath, skyPath):
                printStatus("Sky %s is not in source PAK" % skyPath, Color.RED);
                return; #file not in PAK
        elif !PAKBundler.pathIsEmbedded(skyPath) && !FileAccess.file_exists(skyPath):
                printStatus("Sky %s cannot be found" % skyPath, Color.RED);
                return; #file not on disk
    var outputPath = get_node("Layout/BottomContainer/Layout/OutputFolder/LineEdit").get_text();
    if outputPath.is_empty():
        printStatus("Output path is not set.", Color.RED);
        return; #Mandatory field
    if outputPath[-1] == "/" || outputPath[-1] == "\\":
        outputPath.erase_at(-1);
    var res = PAKBundler.bundle(outputPath, levelName, author, mapVersion, gameModes, description, license, levelPath, getSelectedWADs(), previewPath, skyPath);
    if res != null:
        printStatus("PAK Failed generating: %s" % outputPath, Color.RED);
    else:
        printStatus("PAK successfully generated at %s" % outputPath, Color.GREEN);

# Utils

func closeRequested():
    visible = false;

func printStatus(msg : String, color : Color):
    var statusLabel = get_node("Layout/BottomContainer/Layout/StatusLabel");
    statusLabel.add_theme_color_override("font_color", color);
    statusLabel.set_text(msg);

func getSelectedWADs():
    var container = get_node("Layout/Container/Container/Layout/WADsList/Layout");
    var wads = [];
    for wadEntry in container.get_children():
        wads.push_back(wadEntry.get_node("Label").get_text());
    return wads;
