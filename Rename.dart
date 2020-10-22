import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

String ProcessName(File file, RegExp pattern, String result){
	String fileName = file.name();
	var output = pattern.firstMatch(fileName);
	if(output == null)return null;
	for(int i = 0; i < output.groupCount + 1; ++i){
		result = result.replaceAll("\$$i", output.group(i));
	}
	return result;
}

Future<dynamic> RenameFile(File file, String newName){
	var filePath = path.dirname(file.path);
	return file.rename(path.join(filePath, newName));
}

void main(List<String> args) async {

	if(args.length < 2){
		print("Script requires 2 Arguments");
		return;
	}

	var rgx = new RegExp(args[0]);
	var result = args[1];
	var key = (int index) => result.replaceAll("{{N}}", index.toString());


	Directory dir = Directory.current;
	List<File> files = dir.listSync(recursive: true).where((v) => v is File).map((v) => v as File).where((v) => rgx.hasMatch(v.name())).toList();
	files.sort((a, b) => a.name().compareTo(b.name()));


	if(files.length == 0){
		print("Couldn't find any Files");
		return;
	}else
		print("Found ${files.length} Files");



	print("\"${files[0].name()}\" will be renamed to \"${ProcessName(files[0], rgx, key(0))}\"");

	bool done = false;
	if(!done)
		stdout.write("Continue? (yes|no):");
	while(!done){
		var line = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
		if(line == "no" || line == "n")return;
		if(line == "yes" || line == "y"){
			done = true;
			continue;
		}
		stdout.write("Invalid Input $line. Try Again: ");
	}

	print("Renaming...\n");
	sleep(Duration(milliseconds: 250));


	List<Future<dynamic>> processed = new List();
	for(int i = 0; i < files.length; ++i){
		var newName = ProcessName(files[i], rgx, key(i));
		if(newName == null)continue;
		processed.add(RenameFile(files[i], newName));
		print("Replacing ${files[i].name()} with $newName");
	}

	await Future.wait(processed);
	print("\nCompleted");
}



extension Overloads on File{
	String name(){
		return path.basename(this.path);
	}
}