class_name Util

static func get_locale(language: String) -> String:
    # This should be handled differently in the future, once more translations are added.
    match language:
        "English (US)":
            return "en_US"
        _:
            return "automatic"
