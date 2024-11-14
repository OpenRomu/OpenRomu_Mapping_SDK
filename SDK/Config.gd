extends Resource
class_name Config

const SavePath = "user://Config.res"

@export var version : String;
@export var mapEditorPath : String;

func init(version_ : String = ProjectSettings.get_setting("application/config/version"),
          mapEditorPath_ : String = ""):
    version = version_;
    mapEditorPath = mapEditorPath_;

func saveToDisk() -> void:
    version = ProjectSettings.get_setting("application/config/version");
    ResourceSaver.save(self, SavePath);

static func loadFromDisk() -> Config:
    var loadedConfig = null;
    if FileAccess.file_exists(SavePath):
        loadedConfig = ResourceLoader.load(SavePath) as Config;
    if loadedConfig && loadedConfig.version && loadedConfig.version == ProjectSettings.get_setting("application/config/version"):
        return loadedConfig;
    return Config.new();
