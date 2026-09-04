import 'dart:io';

void main(List<String> args) {
  final currentDir = Directory.current.path;
  final mapFile = File('$currentDir/.context/SigoAPP_Mapa_Modulos.md');

  if (!mapFile.existsSync()) {
    stderr.writeln('Error: No se encontró .context/SigoAPP_Mapa_Modulos.md');
    exit(1);
  }

  final mapContent = mapFile.readAsStringSync();

  // 1. Obtener archivos modificados o creados recientemente vía Git
  var gitResult = Process.runSync('git', ['status', '--porcelain'], workingDirectory: currentDir);
  var output = gitResult.stdout.toString().trim();
  var files = <String>[];

  if (output.isNotEmpty) {
    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.length > 3) {
        final filePath = trimmed.substring(3).trim();
        if (filePath.startsWith('lib/') && filePath.endsWith('.dart')) {
          files.add(filePath);
        }
      }
    }
  }

  // Si git status está limpio, revisar el último commit
  if (files.isEmpty) {
    gitResult = Process.runSync('git', ['diff', '--name-only', 'HEAD~1'], workingDirectory: currentDir);
    output = gitResult.stdout.toString().trim();
    if (output.isNotEmpty) {
      for (final line in output.split('\n')) {
        final filePath = line.trim();
        if (filePath.startsWith('lib/') && filePath.endsWith('.dart')) {
          files.add(filePath);
        }
      }
    }
  }

  print('=== Auditoría de Sincronización de Contexto (SigoAPP) ===\n');

  if (files.isEmpty) {
    print('No se detectaron archivos de código Dart modificados recientemente en lib/.');
    print('El repositorio está limpio o sin cambios pendientes de sincronización.');
    return;
  }

  print('Archivos evaluados en lib/ (${files.length}):');
  for (final f in files) {
    print('  - $f');
  }
  print('');

  final affectedDocs = <String>{};
  final unmappedFiles = <String>[];

  for (final file in files) {
    final fileName = file.split('/').last;

    // Verificar si está en Mapa de Módulos
    if (!mapContent.contains(fileName)) {
      unmappedFiles.add(file);
    }

    // Clasificar impacto según ruta
    if (file.contains('/screens/')) {
      affectedDocs.add('.context/SigoAPP_Mapa_Modulos.md');
      affectedDocs.add('.context/SigoAPP_Arquitectura.md');
    } else if (file.contains('/providers/') || file.contains('/repositories/')) {
      affectedDocs.add('.context/SigoAPP_Mapa_Modulos.md');
      affectedDocs.add('.context/SigoAPP_Arquitectura.md');
    } else if (file.contains('/utils/')) {
      affectedDocs.add('.context/utils_documentation.md');
      affectedDocs.add('.context/SigoAPP_Mapa_Modulos.md');
    } else if (file.contains('/models/')) {
      affectedDocs.add('.context/SigoAPP_Mapa_Modulos.md');
    }
  }

  if (unmappedFiles.isNotEmpty) {
    print('⚠️ Archivos NO referenciados en .context/SigoAPP_Mapa_Modulos.md:');
    for (final uf in unmappedFiles) {
      print('  [!] $uf');
    }
    print('');
  } else {
    print('✓ Todos los archivos modificados ya están referenciados en SigoAPP_Mapa_Modulos.md.\n');
  }

  print('📋 Documentos de .context/ que requieren validación/actualización:');
  for (final doc in affectedDocs) {
    print('  - $doc');
  }
  print('\nRecuerda solicitar la aprobación del usuario antes de aplicar cambios a estos documentos.');
}
