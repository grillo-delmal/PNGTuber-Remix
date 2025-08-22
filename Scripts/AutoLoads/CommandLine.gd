extends Node

func _ready():
    for argument in OS.get_cmdline_user_args():
        if argument.contains("="):
            var key_value = argument.split("=");
            if key_value[0].trim_prefix("--") == "save-data-path":
                print("Custom save data path provided: ", key_value[1]);
                Settings.save_location = key_value[1];
