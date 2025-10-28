![](images/misc/todo.png?raw=true)

# [1.6.0] *BETA* - (October 27, 2025)

Core improvements, extended file system support, and scripting rework for next-gen modding targets.

---

### Planned Additions
- [ ] Add mod support for JS / HTML5 build targets  
- [x] Implement functional ZIP support for compressed modpacks  
- [ ] Introduce file systems with a ZIP variant  
- [ ] Rework scripting for scripted classes and scriptables (similar to Polymod but with deeper integration)  
- [x] Add support for appending and merging strings across all formats  

---

### Planned Changes
- [ ] Refactor `FlxScriptUtil` to improve execution flow between scripts and scriptables  
- [x] Optimize `FlxModding.reload` to streamline modpack loading between zipped and unpacked formats  
- [ ] Update internal handling of modpacks for JS/HTML5 targets to match sys-level file systems
- [ ] Make Flash build targets not crash on runtime due to non flash target variables

---

### Planned Removals
- [x] Remove legacy or redundant scripting wrappers used before rework  
- [x] Deprecate temporary file handling functions in favor of the new ZIP-based system  

---

### Notes
This list represents features currently being designed or implemented for the next major update.  
Sections can be updated or reused per version to reflect roadmap progress.
