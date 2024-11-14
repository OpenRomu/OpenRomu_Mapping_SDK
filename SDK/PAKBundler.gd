extends Node
class_name PAKBundler

static func bundle(outputPath : String, levelName : String, author : String, mapVersion : int, gameModes : Array, description : String, license : String, levelPath : String, wadsPath : Array, previewPath : String, skyPath : String, loadedPAKPath : String = ""):
    var packer = ZIPPacker.new();
    var pakOutput = outputPath+("\\" if OS.has_feature("windows") else "/")+levelName.replace(" ", "_").to_lower()+".pak";
    if packer.open(pakOutput) != OK:
        return "Error creating PAK.";
    # write BSP
    var rLevelPath = levelPath.get_file() if !pathIsEmbedded(levelPath) else getEmbeddedRealPath(levelPath);
    packer.start_file(rLevelPath);
    if pathIsEmbedded(levelPath):
        packer.write_file(getPAKFile(loadedPAKPath, rLevelPath));
    else:
        packer.write_file(FileAccess.get_file_as_bytes(levelPath));
    packer.close_file();
    # write WADs
    var rWadPaths = [];
    for wad in wadsPath:
        rWadPaths.push_back(wad.get_file() if !pathIsEmbedded(wad) else getEmbeddedRealPath(wad));
        if !pathIsEmbedded(wad):
            packer.start_file(wad.get_file());
            packer.write_file(FileAccess.get_file_as_bytes(wad));
            packer.close_file();
    # write Preview
    var rPreviewPath = "";
    if !previewPath.is_empty():
        rPreviewPath = previewPath.get_file() if !pathIsEmbedded(previewPath) else getEmbeddedRealPath(previewPath);
        packer.start_file(rPreviewPath);
        if pathIsEmbedded(previewPath):
            packer.write_file(getPAKFile(loadedPAKPath, rPreviewPath));
        else:
            packer.write_file(FileAccess.get_file_as_bytes(previewPath));
        packer.close_file();
    # write Sky
    var rSkyPath = "";
    if !skyPath.is_empty():
        rSkyPath = skyPath.get_file() if !pathIsEmbedded(skyPath) else getEmbeddedRealPath(skyPath);
        packer.start_file(rSkyPath);
        if pathIsEmbedded(skyPath):
            packer.write_file(getPAKFile(loadedPAKPath, rSkyPath));
        else:
            packer.write_file(FileAccess.get_file_as_bytes(skyPath));
        packer.close_file();
    # write meta
    var metaData = {
        "meta_version": 1,
        "name": levelName,
        "author": author,
        "map_version": mapVersion,
        "date_created:": Time.get_datetime_string_from_system(true, true),
        "license" : license,
        "preview": rPreviewPath,
    
        "openrs_version_support" : 1,
        "hidden": false,
        "gamemodes": gameModes,
    
        "description": {
            "en": description,
            "fr": description
        },
        
        "wads": rWadPaths,
        "level": rLevelPath,
        "sky": rSkyPath
    };
    packer.start_file("meta.json");
    packer.write_file(JSON.stringify(metaData).to_utf8_buffer());
    packer.close_file();
    packer.close();
    return null;

static func pathIsEmbedded(path : String) -> bool:
    return path.begins_with("$PAK:");

static func getEmbeddedRealPath(path : String) -> String:
    return path.replace("$PAK:", "");

static func checkPAKFileExists(pakPath : String, filePath : String) -> bool:
    if pakPath.is_empty():
        return false; #No loaded PAK
    var reader = ZIPReader.new();
    if reader.open(pakPath) != OK:
        return false; #Error loading
    var res = true;
    var rFile = getEmbeddedRealPath(filePath);
    res = reader.file_exists(rFile);
    reader.close();
    return res;

static func getPAKFile(pakPath : String, filePath : String):
    var rFile = getEmbeddedRealPath(filePath);
    if pakPath.is_empty():
        return null; #No loaded PAK
    var reader = ZIPReader.new();
    if reader.open(pakPath) != OK:
        return null; #Error loading
    var file = reader.read_file(rFile);
    reader.close();
    if !file:
        return null; #Embedded file %s cannot be found
    return file;
    
