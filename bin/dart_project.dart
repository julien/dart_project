// library dart_project;

import 'dart:io';

Directory projectDir;
String projectPath;
String projectName;


String TEMPLATE_DART_CMD = '''
import 'dart:io';

void main() { }
''';

String TEMPLATE_DART_WEB = '''
import 'dart:html';

void main() { }
''';

String TEMPLATE_HTML = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>${projectName}</title>
    <link rel="stylesheet" href="${projectName}.css">
  </head>
  <body>
    <h1>${projectName}</h1>
    <script type="application/dart" src="${projectName}.dart"></script>
    <script src="https://dart.googlecode.com/svn/branches/bleeding_edge/dart/client/dart.js"></script>
  </body>
</html>
''';

String TEMPLATE_CSS = '''
body {
  background-color: #F8F8F8;
  font-family: 'Open Sans', sans-serif;
  font-size: 14px;
  font-weight: normal;
  line-height: 1.2em;
  margin: 15px;
}

p {
  color: #333;
}

#container {
  width: 100%;
  height: 400px;
  position: relative;
  border: 1px solid #ccc;
  background-color: #fff;
}

#text {
  font-size: 24pt;
  text-align: center;
  margin-top: 140px;
}
''';

String TEMPLATE_PUBSPEC = '''
name: ${projectName}

dependencies:
#  js: any
#  unittest: any

''';

void abort([String message = 'bye bye!', int statusCode = 1]) {
  print('\x1b[32m$message\x1b[0m');
  exit(statusCode);
}

Future<bool> prompt(String message) {
  print('$message[y/n]');

  Completer completer = new Completer();

  StringInputStream stream = new StringInputStream(stdin);
  stream.onLine = () {
    String answer = stream.readLine().toLowerCase().trim();
    if (answer == 'y') {
      completer.complete(true);
    } else {
      completer.complete(false);
    }
  };
  return completer.future;
}

Future<dynamic> createFile(String name, String contents) {
  Completer completer = new Completer();
  File file = new File(name);

  Future<File> createFile = file.create();
  createFile.then((File value) {
    if (value != null) {
      // this fails ... why?
      // Future<File> writeFile = file.writeAsString(contents, Encoding.UTF_8, FileMode.WRITE);
      Future<File> writeFile = file.writeAsString(contents, FileMode.WRITE);
      writeFile.then((File value) {
        if (value != null) {
          completer.complete(value);
        } else {
          completer.complete(false);
        }
      });
    } else {
      completer.complete(false);
    }
  });
  return completer.future;
}

Future<dynamic> createDirectory(String path) {
  Completer completer = new Completer();
  Directory dir = new Directory(path);
  dir.create().then((Directory dir) {
    if (dir != null) {
      completer.complete(dir);
    } else {
      completer.complete(false);
    }
  });
  return completer.future;
}

void createProject(String projectPath) {
   print('\x1b[32mcreating project "$projectName"\t${projectPath}\x1b[0m');

   createDirectory(projectPath).then((dynamic value) {
     if (value is Directory) {
       Future<bool> fileFuture = createFile('${projectPath}/pubspec.yaml', TEMPLATE_PUBSPEC);

       Future<bool> webFuture = prompt('\x1b[36mgenerate content for a base web app?\x1b[0m');
       webFuture.then((bool value) {
         if (value) {
           createDirectory('${projectPath}/web').then((Directory dir) {
             if (dir != null) {
               Future<bool> dartFile = createFile('${projectPath}/web/${projectName}.dart', TEMPLATE_DART_WEB);
               dartFile.then((value) {
                 if (value is File) {
                   Future<bool> htmlFile = createFile('${projectPath}/web/${projectName}.html', TEMPLATE_HTML);
                   htmlFile.then((value) {
                     if (value is File) {
                       Future<bool> cssFile  = createFile('${projectPath}/web/${projectName}.css', TEMPLATE_CSS);
                       cssFile.then((value) {
                         abort('project created\tbye bye!');
                       });
                     }
                   });
                 }
               });
             }
           });
         } else {
          createDirectory('${projectPath}/bin').then((Directory dir) {
            if (dir != null) {
              Future<bool> dartFile = createFile('${projectPath}/bin/${projectName}.dart', TEMPLATE_DART_CMD);
              dartFile.then((value) {
                abort('project created\t${projectName}');
              });
            }
          });
         }
       });

     }
   });

}

void initialize(Directory dir, String name) {
  print('\x1b[32minitializing project:\t"${name}"\x1b[0m');
  print('\x1b[32mproject path:\t${projectPath}\x1b[0m');

  bool found;
  File existing;
  Future<bool> future;


  DirectoryLister lister = dir.list(recursive:true);

  lister.onError = (e) => print(e);
  lister.onDir  = (String dir) {
    if (projectPath == dir) {
      existing = new File(dir);
      found = true;
    }
  };
  lister.onFile = (String file) {
    if (projectPath == file) {
      existing = new File(file);
      found = true;
    }
  };
  lister.onDone = (bool completed) {
    if (completed && found) {
      future = prompt('\x1b[31m${projectPath} already exists, do you want to overwrite it?\x1b[0m');
      future.then((value) { !value ? abort() : createProject(projectPath); });
    } else {
      createProject(projectPath);
    }
  };
}


void main() {
  Options options = new Options();
  List<String> arguments = options.arguments;
  if (arguments.length > 0) {
    projectDir = new Directory.current();
    projectName = arguments[0];
    projectPath = new Path('${projectDir.path}/$projectName').toNativePath();
    initialize(projectDir, projectName);
  } else {
    abort('\x1b[32musage: dart_project.dart PROJECT_NAME\x1b[0m');
  }
}
