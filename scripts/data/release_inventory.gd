class_name ReleaseInventory
extends RefCounted


static func inspect(inventory: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var entries := {}
	if int(inventory.get("version", 0)) != 1:
		errors.append("Release content inventory version must be 1.")
	var project_license: Variant = inventory.get("project_license", null)
	if not project_license is Dictionary or String(project_license.get("status", "")) != "approved":
		errors.append("Project license decision is not approved in the release content inventory.")
	elif String(project_license.get("license", "")).strip_edges().is_empty() or String(project_license.get("evidence", "")).strip_edges().is_empty():
		errors.append("Approved project license requires license and evidence fields.")
	var entries_value: Variant = inventory.get("entries", null)
	if not entries_value is Array:
		errors.append("Release content inventory entries must be an array.")
		return {"errors": errors, "entries": entries}
	for index in entries_value.size():
		var entry_value: Variant = entries_value[index]
		if not entry_value is Dictionary:
			errors.append("Release content inventory entry %d must be an object." % index)
			continue
		var entry: Dictionary = entry_value
		var path := String(entry.get("path", ""))
		if path.is_empty() or path.is_absolute_path() or path.contains(".."):
			errors.append("Release content inventory entry %d has an invalid relative path." % index)
			continue
		var resource_path := "res://%s" % path
		if entries.has(resource_path):
			errors.append("Release content inventory contains duplicate path: %s" % path)
			continue
		entries[resource_path] = entry
	return {"errors": errors, "entries": entries}


static func required_entry_errors(entries: Dictionary, resource_path: String, expected_kind: String) -> Array[String]:
	var errors: Array[String] = []
	if not entries.has(resource_path):
		errors.append("Release file is not inventoried: %s" % resource_path)
		return errors
	var entry: Dictionary = entries[resource_path]
	if String(entry.get("kind", "")) != expected_kind:
		errors.append("Release inventory kind for %s must be '%s'." % [resource_path, expected_kind])
	if not bool(entry.get("include_in_release", false)):
		errors.append("Required release file is not marked for inclusion: %s" % resource_path)
	if not bool(entry.get("cleared", false)):
		errors.append("Redistribution clearance is pending for: %s" % resource_path)
	for field in ["attribution", "license", "evidence", "package_marker"]:
		if String(entry.get(field, "")).strip_edges().is_empty():
			errors.append("Release inventory entry for %s requires non-empty %s." % [resource_path, field])
	return errors
