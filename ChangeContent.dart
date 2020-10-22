import 'dart:convert';
import 'dart:io';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

class FileWrapper{
	File file;
	String content;
	String relativePath;
	bool containsKey;
	bool matches;

	FileWrapper(this.file){
		relativePath = path.relative(file.path);
	}

	bool Matches(Glob pattern){
		matches = pattern.matches(relativePath);
		return matches;
	}

	Future<bool> Contains(String key) async {
		content = await file.readAsString();
		containsKey = content.contains(key);
		return containsKey;
	}

	void Replace(String key, String value){
		if(content == null)
			print("File not Loaded yet");
		content = content.replaceFirst(key, value);
	}

	Future<bool> Save() async {
    try{
		  await file.writeAsString(content, flush: true);
		  return true;
    }catch(err){
      return false;
    }
	}
}

void main(List<String> args) async {
	var appDataDir = "";

	if (Platform.operatingSystem == 'windows') {
		appDataDir = Directory(Platform.environment['APPDATA']).parent.path;
	}else{
		print("Non Windows Operating systems are not supported");
		return;
	}

	File lastSave = new File(path.join(appDataDir, "local", "CEbbinghaus", "DartTools", "Rename.lst"));
	if(! await lastSave.exists())
		await lastSave.create(recursive: true);

	bool override = false;

	if(args.length < 3){
		if(args.length == 1 && args[0] == "restore"){
			var lines = await lastSave.readAsLines();
			if(lines.length < 4){
				print("Invalid Save file. Cannot Restore");
				return;
			}
			var path = lines.removeAt(0);
			if(path != Directory.current.path){
				print("Cannot restore. Save file is from a different Directory");
				return;
			}
			override = true;
			var pattern = lines.removeAt(0);
			args = lines.reversed.toList();
			args.insert(0, pattern);
		}else{
			print("Script requires 3 Arguments");
			return;
		}
	}

	if(args[1] == args[2]){
		print("Cannnot replace a value with itself");
		return;
	}

	final Glob pattern = new Glob(args[0]);
	Directory dir = Directory.current;
	List<FileWrapper> files = dir.listSync(recursive: true).where((v) => v is File).map((f) => new FileWrapper(f)).where((fw) => fw.Matches(pattern)).toList();

	print("Found ${files.length} Matching Files");

	print("Replacing \"${args[1]}\" with \"${args[2]}\"");

	if(files.length == 0)return;

	bool done = override;
	if(!done)
		stdout.write("Continue? (yes|no):");
	while(!done){
		var line = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
		if(line == "no" || line == "n")return;
		if(line == "yes" || line == "y"){
			done = true;
			continue;
		}
		stdout.write("Invalid Input: ");
	}

	lastSave.writeAsString("${Directory.current.path}\n${args[0]}\n${args[1]}\n${args[2]}");

	List<Future<bool>> saved = new List();
	for(var file in files){
		if(await file.Contains(args[1])){
			file.Replace(args[1], args[2]);
			saved.add(file.Save());
			print("Replaced ${file.relativePath}");
		}else{
			print("Couldn't find Key in ${file.relativePath}");
		}
	}

	var finished = await Future.wait(saved);
	for(var fin in finished){
		if(fin == false){
			print("Failed to save a File");
		}
	}
	if(finished.reduce((a, b) => a == b ? a : null) != null);
		print("\n\nCompleted without Error");
}