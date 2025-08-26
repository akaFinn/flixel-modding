package flixel.system.fileSystem;

import haxe.io.Bytes;

class RamFileSystem implements IFileSystem
{
	var files:Map<String, Bytes>;
	var folders:Map<String, Bool>;

	public function new()
	{
		files = new Map<String, Bytes>();
		folders = new Map<String, Bool>();
	}

	public function createFile(path:String, name:String, data:Dynamic):Void
	{
		if (this.exists(path + (StringTools.endsWith(path, "/") ? "" : "/") + name))
			files.remove(path + (StringTools.endsWith(path, "/") ? "" : "/") + name);

		files.set(path + (StringTools.endsWith(path, "/") ? "" : "/") + name, data);
	}

	public function renameFile(path:String, name:String):Void
	{
		if (this.isFile(path))
		{
			files.set(path.substr(0, path.lastIndexOf("/")) + "/" + name, files.get(path));
			files.remove(path);
		}
	}

	public function deleteFile(path:String):Void
	{
		files.remove(path);
	}

	public function isFile(path:String):Bool
	{
		return files.exists(path);
	}

	public function getFileContent(path:String):String
	{
		return files.get(path).toString();
	}

	public function getFileBytes(path:String):Bytes
	{
		return files.get(path);
	}

	public function setFileContent(path:String, content:String):Void
	{
		files.set(path, Bytes.ofString(content));
	}

	public function setFileBytes(path:String, bytes:Bytes):Void
	{
		files.set(path, bytes);
	}

	public function readFolder(path:String):Array<String>
	{
		var result:Array<String> = [];

		for (folder in folders.keys())
		{
			if (StringTools.startsWith(folder, path) && !result.contains(folder))
			{
				result.push(folder);
			}
		}

		for (file in files.keys())
		{
			if (StringTools.startsWith(file, path) && !result.contains(file))
			{
				result.push(file);
			}
		}

		return result;
	}

	public function createFolder(path:String, name:String):Void
	{
		if (this.exists(path + (StringTools.endsWith(path, "/") ? "" : "/") + name))
			folders.remove(path + (StringTools.endsWith(path, "/") ? "" : "/") + name);

		@:privateAccess
		folders.set(path + (StringTools.endsWith(path, "/") ? "" : "/") + name, StringTools.startsWith(path, FlxModding.modsDirectory));
	}

	public function renameFolder(path:String, name:String):Void
	{
		if (this.isFolder(path))
		{
			folders.set(path.substr(0, path.lastIndexOf("/")) + "/" + name, folders.get(path));
			folders.remove(path);
		}
	}

	public function deleteFolder(path:String):Void
	{
		folders.remove(path);
	}

	public function isFolder(path:String):Bool
	{
		return folders.exists(path);
	}

	public function exists(path:String):Bool
	{
		if (this.isFolder(path))
			return folders.exists(path);
		else
			return files.exists(path);
	}
}
