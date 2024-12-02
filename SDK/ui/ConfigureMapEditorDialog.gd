extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var app = get_node("/root/App");
    var browseButton = get_node("Container/Container/Layout/Layout/BrowseButton");
    browseButton.connect("pressed", Callable(app, "openFileBrowser").bind(FileDialog.FileMode.FILE_MODE_OPEN_FILE, [], "file_selected", Callable(self, "setMapEditorDialogPath")));
    get_node("Container/Container/Layout/Buttons/CancelButton").connect("pressed", Callable(self, "hide"));
    get_node("Container/Container/Layout/Buttons/ApplyButton").connect("pressed", Callable(self, "apply"));

func setMapEditorDialogPath(path):
    var pathInput = get_node("Container/Container/Layout/Layout/PathInput");
    pathInput.set_text(path);

func apply():
    var pathInput = get_node("Container/Container/Layout/Layout/PathInput");
    var app = get_node("/root/App");
    app.config.mapEditorPath = pathInput.text;
    hide();
