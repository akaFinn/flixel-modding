![](images/misc/todo.png?raw=true)

# [1.6.0] *BETA* - (November 3, 2025)

Core improvements, extended file system support, and scripting rework for next-gen modding targets.

---

### Planned Additions
- [ ] Add mod support for JS / HTML5 build targets  
- [x] Implement functional ZIP support for compressed modpacks  
- [ ] Introduce file systems with a ZIP variant  
- [x] Rework scripting for scripted classes and scriptables (similar to Polymod also not really)  
- [x] Add support for appending and merging strings across all formats  

---

### Planned Changes
- [x] Refactor `FlxScriptUtil` to improve execution flow between scripts and scriptables  
- [x] Optimize `FlxModding.reload` to streamline modpack loading between zipped and unpacked formats  
- [ ] Update internal handling of modpacks for JS/HTML5 targets to match sys-level file systems
- [ ] Merge all file systems into one class instead of seperate classes

---

### Planned Removals
- [x] Remove legacy or redundant scripting wrappers used before rework  
- [x] Deprecate temporary file handling functions in favor of the new ZIP-based system
- [x] Deprecate asset system found in `FlxModding` due to it being stupid

---

### Notes
This list represents features currently being designed or implemented for the next major update.  
Sections can be updated or reused per version to reflect roadmap progress.
