extends RefCounted
## Strict parsing for the flags a tool script reads after `--`. An unknown flag or a value of the wrong
## kind stops the run, because silently ignored flags once let four route runs repeat seed 0 unnoticed.

## Maps each accepted flag to its default: a bool default marks a bare switch such as
## `--simulation-clock`, and any other default a `--name=value` flag of that type. Returns the defaults
## overridden by the command line, or null after asking the tree to quit with status 2.
static func parse(tree: SceneTree, defaults: Dictionary) -> Variant:
	var values := defaults.duplicate()
	for arg in OS.get_cmdline_user_args():
		var name := arg.get_slice("=", 0)
		var value := arg.substr(name.length() + 1)
		var default: Variant = defaults.get(name)
		if default == null or (default is bool) == arg.contains("=") \
				or (default is int and not value.is_valid_int()) or (default is float and not value.is_valid_float()):
			var forms := PackedStringArray()
			for flag: String in defaults:
				forms.append(flag if defaults[flag] is bool else "%s=<%s>" % [flag, type_string(typeof(defaults[flag]))])
			push_error("Unknown or malformed flag %s; this script accepts %s" % [arg, ", ".join(forms)])
			tree.quit(2)
			return null
		values[name] = true if default is bool else type_convert(value, typeof(default))
	return values
