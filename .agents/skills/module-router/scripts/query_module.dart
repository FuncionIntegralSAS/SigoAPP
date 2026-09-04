import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    printUsage();
    return;
  }

  final query = args[0].toLowerCase().trim();
  final isJson = args.contains('--json');

  // Determinar la raíz del proyecto
  final currentDir = Directory.current.path;
  final mapFile = File('$currentDir/.context/SigoAPP_Mapa_Modulos.md');

  if (!mapFile.existsSync()) {
    stderr.writeln('Error: No se encontró .context/SigoAPP_Mapa_Modulos.md en $currentDir');
    exit(1);
  }

  final content = mapFile.readAsStringSync();
  final lines = content.split('\n');

  final matchedSections = <ModuleSection>[];
  ModuleSection? currentSection;
  bool readingTable = false;

  final headingRegex = RegExp(r'^##\s+(?:(\d+(?:\.\d+)?)\s+)?(.*)$');
  final subHeadingRegex = RegExp(r'^###\s+(?:(\d+(?:\.\d+)?)\s+)?(.*)$');
  final tableRowRegex = RegExp(r'^\|\s*([^|]+)\s*\|\s*`?([^`|]+)`?\s*\|\s*`?([^`|]+)`?\s*\|$');
  final permissionRegex = RegExp(r'\*\*Permiso(?:\(s\))?:\*\*\s*(.+)', caseSensitive: false);
  final functionalDocRegex = RegExp(r'\*\*Documentación Funcional:\*\*\s*\[?`?([^`\]\)]+)`?\]?\(?([^)\s]*)\)?', caseSensitive: false);

  String? currentDoc;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    // Comprobar si hay link a documento funcional
    final docMatch = functionalDocRegex.firstMatch(line);
    if (docMatch != null) {
      currentDoc = docMatch.group(1);
    }

    // Comprobar encabezados nivel 2 o 3
    final h2 = headingRegex.firstMatch(line);
    final h3 = subHeadingRegex.firstMatch(line);
    final match = h2 ?? h3;

    if (match != null) {
      if (currentSection != null && currentSection.files.isNotEmpty) {
        matchedSections.add(currentSection);
      }
      final title = match.group(2)?.trim() ?? '';
      currentSection = ModuleSection(title: title, functionalDoc: currentDoc);
      readingTable = false;
      continue;
    }

    if (currentSection != null) {
      // Buscar permisos
      final permMatch = permissionRegex.firstMatch(line);
      if (permMatch != null) {
        currentSection.permissions.add(permMatch.group(1)!.trim());
      }

      // Detectar inicio de tabla
      if (line.startsWith('| Capa') || line.startsWith('|Capa')) {
        readingTable = true;
        continue;
      }
      if (line.startsWith('|---') || line.startsWith('| ---')) {
        continue;
      }

      if (readingTable) {
        if (!line.startsWith('|')) {
          readingTable = false;
          continue;
        }

        final rowMatch = tableRowRegex.firstMatch(line);
        if (rowMatch != null) {
          final capa = rowMatch.group(1)!.replaceAll('*', '').trim();
          final nombre = rowMatch.group(2)!.trim();
          final ruta = rowMatch.group(3)!.trim();

          if (ruta.startsWith('lib/') || ruta.endsWith('.dart')) {
            currentSection.files.add(FileInfo(
              layer: capa,
              name: nombre,
              relativePath: ruta,
            ));
          }
        }
      }
    }
  }

  if (currentSection != null && currentSection.files.isNotEmpty) {
    matchedSections.add(currentSection);
  }

  // Filtrar según query
  final filtered = matchedSections.where((sec) {
    final matchTitle = sec.title.toLowerCase().contains(query);
    final matchPerm = sec.permissions.any((p) => p.toLowerCase().contains(query));
    final matchFile = sec.files.any((f) =>
        f.name.toLowerCase().contains(query) ||
        f.relativePath.toLowerCase().contains(query) ||
        f.layer.toLowerCase().contains(query));
    return matchTitle || matchPerm || matchFile;
  }).toList();

  if (filtered.isEmpty) {
    print('No se encontraron módulos coincidentes con: "$query".');
    print('\nMódulos disponibles:');
    for (final s in matchedSections) {
      print('- ${s.title} ${s.permissions.isNotEmpty ? "(${s.permissions.join(', ')})" : ""}');
    }
    return;
  }

  // Enriquecer archivos con datos del sistema de archivos local
  for (final sec in filtered) {
    for (final f in sec.files) {
      final fileOnDisk = File('$currentDir/${f.relativePath}');
      f.exists = fileOnDisk.existsSync();
      if (f.exists) {
        try {
          f.totalLines = fileOnDisk.readAsLinesSync().length;
        } catch (_) {
          f.totalLines = 0;
        }
      }

      // Buscar si existe archivo de prueba correspondiente
      final testPath = f.relativePath.replaceFirst('lib/', 'test/').replaceFirst('.dart', '_test.dart');
      final testFile = File('$currentDir/$testPath');
      f.hasTest = testFile.existsSync();
      f.testPath = f.hasTest ? testPath : null;
    }
  }

  if (isJson) {
    printJsonOutput(filtered);
  } else {
    printMarkdownOutput(filtered, currentDir);
  }
}

void printMarkdownOutput(List<ModuleSection> sections, String currentDir) {
  for (final sec in sections) {
    print('### Módulo: ${sec.title}');
    if (sec.permissions.isNotEmpty) {
      print('**Permisos:** ${sec.permissions.join(', ')}');
    }
    if (sec.functionalDoc != null) {
      print('**Documentación Funcional:** `.context/${sec.functionalDoc}`');
    }
    print('');
    print('| Capa | Archivo | Ruta Relativa | Líneas | Test Unitario |');
    print('|---|---|---|:---:|:---:|');
    for (final f in sec.files) {
      final existMark = f.exists ? '' : ' *(no encontrado)*';
      final testMark = f.hasTest ? '`test` ✓' : '—';
      print('| ${f.layer} | `${f.name}`$existMark | `${f.relativePath}` | ${f.totalLines} | $testMark |');
    }
    print('');
  }
}

void printJsonOutput(List<ModuleSection> sections) {
  print('[\n' +
      sections.map((s) {
        final filesJson = s.files.map((f) => '''
      {
        "layer": "${f.layer}",
        "name": "${f.name}",
        "path": "${f.relativePath}",
        "exists": ${f.exists},
        "lines": ${f.totalLines},
        "hasTest": ${f.hasTest},
        "testPath": ${f.testPath != null ? '"${f.testPath}"' : 'null'}
      }''').join(',\n');

        return '''  {
    "title": "${s.title}",
    "permissions": ${s.permissions.map((p) => '"$p"').toList()},
    "functionalDoc": ${s.functionalDoc != null ? '"${s.functionalDoc}"' : 'null'},
    "files": [\n$filesJson\n    ]
  }''';
      }).join(',\n') +
      '\n]');
}

void printUsage() {
  print('''
Uso: dart run .agents/skills/module-router/scripts/query_module.dart <termino_busqueda> [--json]

Parámetros:
  <termino_busqueda>  Nombre del módulo (ej. inventario, auth, conteo),
                      código de permiso (ej. avac, aein, agst) o nombre de archivo.
  --json              (Opcional) Retorna los resultados en formato JSON estructurado.

Ejemplos:
  dart run .agents/skills/module-router/scripts/query_module.dart inventario
  dart run .agents/skills/module-router/scripts/query_module.dart aein
  dart run .agents/skills/module-router/scripts/query_module.dart auth --json
''');
}

class ModuleSection {
  final String title;
  final String? functionalDoc;
  final List<String> permissions = [];
  final List<FileInfo> files = [];

  ModuleSection({required this.title, this.functionalDoc});
}

class FileInfo {
  final String layer;
  final String name;
  final String relativePath;
  bool exists = false;
  int totalLines = 0;
  bool hasTest = false;
  String? testPath;

  FileInfo({
    required this.layer,
    required this.name,
    required this.relativePath,
  });
}
