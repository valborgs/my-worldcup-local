import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../dto/worldcup_dao.dart';
import '../models/worldcup_item_model.dart';
import '../models/worldcup_model.dart';

class WorldCupPackageException implements Exception {
  final String message;

  const WorldCupPackageException(this.message);

  @override
  String toString() => message;
}

class ImportedWorldCup {
  final int idx;
  final String title;

  const ImportedWorldCup({required this.idx, required this.title});
}

/// 월드컵 메타데이터와 이미지를 하나의 `.myworldcup`(ZIP) 파일로
/// 내보내거나, 공유받은 파일을 앱 저장공간으로 가져온다.
class WorldCupPackageService {
  static const String fileExtension = 'myworldcup';
  static const String mimeType = 'application/vnd.org.comon.my-worldcup+zip';

  static const String _format = 'my-worldcup';
  static const int _formatVersion = 1;
  static const String _manifestName = 'manifest.json';
  static const int _maxPackageBytes = 512 * 1024 * 1024;
  static const int _maxManifestBytes = 1024 * 1024;
  static const int _maxImageBytes = 64 * 1024 * 1024;
  static const int _maxTotalImageBytes = 512 * 1024 * 1024;
  static const int _maxItemCount = 512;

  final WorldCupDao _dao;
  final Future<Directory> Function() _temporaryDirectoryProvider;
  final Future<Directory> Function() _documentsDirectoryProvider;

  WorldCupPackageService({
    WorldCupDao? dao,
    Future<Directory> Function()? temporaryDirectoryProvider,
    Future<Directory> Function()? documentsDirectoryProvider,
  })  : _dao = dao ?? WorldCupDao(),
        _temporaryDirectoryProvider =
            temporaryDirectoryProvider ?? getTemporaryDirectory,
        _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  Future<void> shareWorldCup(
    WorldCupModel model, {
    Rect? sharePositionOrigin,
  }) async {
    final packageFile = await createPackage(model);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(packageFile.path, mimeType: mimeType)],
        title: '${model.title} 월드컵 공유',
        subject: '${model.title} 월드컵',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  Future<File> createPackage(WorldCupModel model) async {
    final items = await _dao.getWorldCupItemList(model.idx);
    if (items.length < 4) {
      throw const WorldCupPackageException(
        '공유할 월드컵 항목이 부족합니다.',
      );
    }
    if (items.length > _maxItemCount) {
      throw const WorldCupPackageException(
        '항목이 너무 많아 공유할 수 없습니다.',
      );
    }

    final imageEntries = <String>[];
    for (var index = 0; index < items.length; index++) {
      final extension = _safeImageExtension(items[index].imagePath);
      imageEntries.add('images/${index.toString().padLeft(4, '0')}$extension');
    }

    var titleImageIndex =
        items.indexWhere((item) => item.imagePath == model.titleImageSrc);
    if (titleImageIndex < 0) titleImageIndex = 0;

    final manifest = <String, Object>{
      'format': _format,
      'version': _formatVersion,
      'title': model.title,
      'info': model.info,
      'createdAt': model.date.toIso8601String(),
      'maxRound': items.length,
      'titleImageIndex': titleImageIndex,
      'items': [
        for (var index = 0; index < items.length; index++)
          <String, String>{
            'image': imageEntries[index],
            'info': items[index].imageInfo,
          },
      ],
    };

    final tempDirectory = await _temporaryDirectoryProvider();
    final shareDirectory = Directory(
      path.join(tempDirectory.path, 'worldcup_shares'),
    );
    await shareDirectory.create(recursive: true);
    await _deleteExpiredPackages(shareDirectory);

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final packageFile = File(
      path.join(
        shareDirectory.path,
        '${_safeFileName(model.title)}_$timestamp.$fileExtension',
      ),
    );

    final encoder = ZipFileEncoder();
    var encoderCreated = false;
    try {
      encoder.create(packageFile.path);
      encoderCreated = true;
      encoder.addArchiveFile(
        ArchiveFile.string(_manifestName, jsonEncode(manifest)),
      );

      var totalImageBytes = 0;
      for (var index = 0; index < items.length; index++) {
        final sourcePath = items[index].imagePath;
        final archivePath = imageEntries[index];
        if (sourcePath.startsWith('assets/')) {
          final asset = await rootBundle.load(sourcePath);
          if (asset.lengthInBytes > _maxImageBytes) {
            throw WorldCupPackageException(
              '이미지 파일이 너무 큽니다: ${items[index].imageInfo}',
            );
          }
          totalImageBytes += asset.lengthInBytes;
          encoder.addArchiveFile(
            ArchiveFile.typedData(
                archivePath,
                asset.buffer.asUint8List(
                  asset.offsetInBytes,
                  asset.lengthInBytes,
                )),
          );
        } else {
          final imageFile = File(sourcePath);
          if (!await imageFile.exists()) {
            throw WorldCupPackageException(
              '이미지 파일을 찾을 수 없습니다: ${items[index].imageInfo}',
            );
          }
          final imageBytes = await imageFile.length();
          if (imageBytes > _maxImageBytes) {
            throw WorldCupPackageException(
              '이미지 파일이 너무 큽니다: ${items[index].imageInfo}',
            );
          }
          totalImageBytes += imageBytes;
          await encoder.addFile(imageFile, archivePath);
        }
        if (totalImageBytes > _maxTotalImageBytes) {
          throw const WorldCupPackageException(
            '이미지 리소스의 크기가 너무 큽니다.',
          );
        }
      }

      await encoder.close();
      encoderCreated = false;
      return packageFile;
    } catch (error) {
      if (encoderCreated) {
        try {
          await encoder.close();
        } catch (_) {
          // 원본 패키지 생성 오류를 유지한다.
        }
      }
      if (await packageFile.exists()) await packageFile.delete();
      if (error is WorldCupPackageException) rethrow;
      throw const WorldCupPackageException(
        '월드컵 공유 파일을 만들지 못했습니다.',
      );
    }
  }

  Future<ImportedWorldCup> importPackage(String packagePath) async {
    final packageFile = File(packagePath);
    if (!await packageFile.exists()) {
      throw const WorldCupPackageException('공유 파일을 찾을 수 없습니다.');
    }
    if (await packageFile.length() > _maxPackageBytes) {
      throw const WorldCupPackageException('공유 파일이 너무 큽니다.');
    }

    InputFileStream? input;
    late final Archive archive;
    try {
      input = InputFileStream(packageFile.path);
      archive = ZipDecoder().decodeStream(input, verify: true);
    } catch (_) {
      input?.closeSync();
      throw const WorldCupPackageException(
        '올바른 월드컵 공유 파일이 아닙니다.',
      );
    }

    Directory? importDirectory;
    var databaseCommitted = false;
    try {
      final entries = <String, ArchiveFile>{};
      for (final entry in archive) {
        if (!entry.isFile) continue;
        if (entries.containsKey(entry.name)) {
          throw const WorldCupPackageException(
            '중복된 리소스가 있는 공유 파일입니다.',
          );
        }
        entries[entry.name] = entry;
      }

      final manifestEntry = entries[_manifestName];
      if (manifestEntry == null || manifestEntry.size > _maxManifestBytes) {
        throw const WorldCupPackageException(
          '월드컵 정보가 없거나 손상되었습니다.',
        );
      }
      final manifestBytes = manifestEntry.readBytes();
      if (manifestBytes == null || manifestBytes.length > _maxManifestBytes) {
        throw const WorldCupPackageException(
          '월드컵 정보를 읽을 수 없습니다.',
        );
      }
      final manifest = _PackageManifest.fromJson(
        jsonDecode(utf8.decode(manifestBytes)),
      );

      var totalImageBytes = 0;
      for (final item in manifest.items) {
        if (!_isSafeImageEntry(item.image)) {
          throw const WorldCupPackageException(
            '안전하지 않은 리소스 경로가 포함되었습니다.',
          );
        }
        final imageEntry = entries[item.image];
        if (imageEntry == null ||
            imageEntry.size <= 0 ||
            imageEntry.size > _maxImageBytes) {
          throw const WorldCupPackageException(
            '이미지 리소스가 없거나 손상되었습니다.',
          );
        }
        totalImageBytes += imageEntry.size;
        if (totalImageBytes > _maxTotalImageBytes) {
          throw const WorldCupPackageException(
            '이미지 리소스의 크기가 너무 큽니다.',
          );
        }
      }

      final documentsDirectory = await _documentsDirectoryProvider();
      final importRoot = Directory(
        path.join(documentsDirectory.path, 'imported_worldcups'),
      );
      await importRoot.create(recursive: true);
      importDirectory = Directory(
        path.join(
          importRoot.path,
          DateTime.now().microsecondsSinceEpoch.toString(),
        ),
      );
      await importDirectory.create();

      final importedImagePaths = <String>[];
      for (var index = 0; index < manifest.items.length; index++) {
        final item = manifest.items[index];
        final imageEntry = entries[item.image]!;
        final bytes = imageEntry.readBytes();
        if (bytes == null || bytes.isEmpty || bytes.length > _maxImageBytes) {
          throw const WorldCupPackageException(
            '이미지 리소스를 읽을 수 없습니다.',
          );
        }
        final extension = _safeImageExtension(item.image);
        final outputFile = File(
          path.join(
            importDirectory.path,
            '${index.toString().padLeft(4, '0')}$extension',
          ),
        );
        await outputFile.writeAsBytes(bytes, flush: true);
        importedImagePaths.add(outputFile.path);
        imageEntry.clear();
      }

      final worldCup = WorldCupModel(
        0,
        manifest.title,
        manifest.info,
        manifest.createdAt,
        importedImagePaths[manifest.titleImageIndex],
        manifest.items.length,
      );
      final items = <WorldCupItemModel>[
        for (var index = 0; index < manifest.items.length; index++)
          WorldCupItemModel(
            0,
            importedImagePaths[index],
            manifest.items[index].info,
            0,
          ),
      ];
      final idx = await _dao.addWorldCupWithItems(worldCup, items);
      databaseCommitted = true;
      return ImportedWorldCup(idx: idx, title: manifest.title);
    } on WorldCupPackageException {
      rethrow;
    } catch (_) {
      throw const WorldCupPackageException(
        '월드컵 공유 파일을 가져오지 못했습니다.',
      );
    } finally {
      input.closeSync();
      archive.clearSync();
      if (!databaseCommitted &&
          importDirectory != null &&
          await importDirectory.exists()) {
        await importDirectory.delete(recursive: true);
      }
    }
  }

  static String _safeImageExtension(String sourcePath) {
    final extension = path.extension(sourcePath).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,10}$').hasMatch(extension)
        ? extension
        : '.img';
  }

  static String _safeFileName(String title) {
    final sanitized =
        title.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_').trim();
    if (sanitized.isEmpty) return 'worldcup';
    return sanitized.length <= 40 ? sanitized : sanitized.substring(0, 40);
  }

  static bool _isSafeImageEntry(String entryName) {
    if (entryName.contains('\\') || !entryName.startsWith('images/')) {
      return false;
    }
    if (path.posix.isAbsolute(entryName) ||
        path.posix.normalize(entryName) != entryName) {
      return false;
    }
    return path.posix.basename(entryName).isNotEmpty;
  }

  static Future<void> _deleteExpiredPackages(Directory directory) async {
    final expiration = DateTime.now().subtract(const Duration(days: 1));
    await for (final entity in directory.list()) {
      if (entity is! File || path.extension(entity.path) != '.$fileExtension') {
        continue;
      }
      final stat = await entity.stat();
      if (stat.modified.isBefore(expiration)) await entity.delete();
    }
  }
}

class _PackageManifest {
  final String title;
  final String info;
  final DateTime createdAt;
  final int titleImageIndex;
  final List<_PackageItem> items;

  const _PackageManifest({
    required this.title,
    required this.info,
    required this.createdAt,
    required this.titleImageIndex,
    required this.items,
  });

  factory _PackageManifest.fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['format'] != WorldCupPackageService._format ||
        json['version'] != WorldCupPackageService._formatVersion) {
      throw const WorldCupPackageException(
        '지원하지 않는 월드컵 공유 파일입니다.',
      );
    }

    final title = json['title'];
    final info = json['info'];
    final createdAt = json['createdAt'];
    final titleImageIndex = json['titleImageIndex'];
    final rawItems = json['items'];
    if (title is! String ||
        title.isEmpty ||
        title.length > 200 ||
        info is! String ||
        info.length > 5000 ||
        createdAt is! String ||
        titleImageIndex is! int ||
        rawItems is! List ||
        rawItems.length < 4 ||
        rawItems.length > WorldCupPackageService._maxItemCount) {
      throw const WorldCupPackageException(
        '월드컵 정보가 손상되었습니다.',
      );
    }

    final parsedDate = DateTime.tryParse(createdAt);
    if (parsedDate == null ||
        titleImageIndex < 0 ||
        titleImageIndex >= rawItems.length) {
      throw const WorldCupPackageException(
        '월드컵 정보가 손상되었습니다.',
      );
    }

    final items = <_PackageItem>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map<String, dynamic> ||
          rawItem['image'] is! String ||
          (rawItem['image'] as String).length > 200 ||
          rawItem['info'] is! String ||
          (rawItem['info'] as String).length > 2000) {
        throw const WorldCupPackageException(
          '월드컵 항목 정보가 손상되었습니다.',
        );
      }
      items.add(
        _PackageItem(
          image: rawItem['image'] as String,
          info: rawItem['info'] as String,
        ),
      );
    }

    return _PackageManifest(
      title: title,
      info: info,
      createdAt: parsedDate,
      titleImageIndex: titleImageIndex,
      items: items,
    );
  }
}

class _PackageItem {
  final String image;
  final String info;

  const _PackageItem({required this.image, required this.info});
}
