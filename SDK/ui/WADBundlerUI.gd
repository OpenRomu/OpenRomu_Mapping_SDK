extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var app = get_node("/root/App");
    connect("close_requested", Callable(self, "closeRequested"));
    get_node("Container/Container/Layout/SourceFolder/Button").connect("pressed", Callable(app, "openFileBrowser").bind(FileDialog.FILE_MODE_OPEN_DIR, [], "dir_selected", Callable(self, "sourceFolderSelected")));
    get_node("Container/Container/Layout/OutputWAD/Button").connect("pressed", Callable(app, "openFileBrowser").bind(FileDialog.FILE_MODE_SAVE_FILE, ["*.wad"], "file_selected", Callable(self, "outputWADSelected")));
    var bundleButton = get_node("Container/Container/Layout/BundleButton");
    bundleButton.connect("pressed", Callable(self, "preBundle"));

func sourceFolderSelected(path):
    get_node("Container/Container/Layout/SourceFolder/LineEdit").set_text(path);

func outputWADSelected(path):
    get_node("Container/Container/Layout/OutputWAD/LineEdit").set_text(path);

func preBundle():
    clearStatus();
    var sourceFolderInput = get_node("Container/Container/Layout/SourceFolder/LineEdit").get_text();
    if sourceFolderInput.is_empty():
        printStatus("No source folder selected", Color.INDIAN_RED);
        return;
    var outputWADInput = get_node("Container/Container/Layout/OutputWAD/LineEdit").get_text();
    if outputWADInput.is_empty():
        printStatus("Ouput WAD is not set", Color.INDIAN_RED);
        return;
    var recursive = get_node("Container/Container/Layout/Recursive/CheckBox").button_pressed;
    bundle(sourceFolderInput, outputWADInput, recursive);

func bundle(sourceFolderInput : String, outputWADInput : String, recursive : bool):
    var args = ["bundle", sourceFolderInput, outputWADInput];
    if recursive:
        args.push_back("--recursive");
    var stdout = [];
    var res = OS.execute("utils/wad3-cli", args, stdout);
    if res != OK:
        stdout.push_back("failed to run wad3-cli");
    for line in stdout:
        printStatus(line + "\n", Color.WHITE);
    
# Utils

func clearStatus():
    var statusLabel = get_node("Container/Container/Layout/ScrollContainer/StatusLabel");
    statusLabel.text = "";

func printStatus(msg : String, color : Color):
    var statusLabel = get_node("Container/Container/Layout/ScrollContainer/StatusLabel");
    statusLabel.text += "[color="+color.to_html()+"]"+msg+"[/color]";

func closeRequested():
    visible = false;
