import 'dart:io';
import 'package:path/path.dart' as Path;

int main(List<String> arguments){
  String output = "./";
  
  int pathArgIndex = arguments.indexOf("-o");
  if(pathArgIndex != -1 && pathArgIndex + 1  < arguments.length)
    output = arguments[pathArgIndex + 1];

  Directory current = Directory.current;
  String outputPath = Path.normalize(Path.join(Directory.current.path, output));
  Directory outputDirectory = Directory(outputPath);
  print("Output Directory: $outputPath");
  if(!outputDirectory.existsSync())
    outputDirectory.createSync(recursive: true);

  current.list(recursive: true).forEach((FileSystemEntity f){
    if(!f.path.endsWith(".dart"))return;
    String fileName = Path.basenameWithoutExtension(f.path);
    Process.run("dart2native", ["./$fileName.dart", "-o", Path.join(outputPath, fileName + ".exe")], runInShell: true).then((onValue){
      if(onValue.exitCode != 0)
        print("Failed Build of $fileName.dart: \n${onValue.stderr}");
      else
        print("Output: ${onValue.stdout}");
    });
  });
  return 1;
}