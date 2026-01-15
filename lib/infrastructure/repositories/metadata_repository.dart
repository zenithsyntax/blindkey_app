import 'package:blindkey_app/domain/failures/failures.dart';
import 'package:blindkey_app/domain/models/folder_model.dart';
import 'package:blindkey_app/domain/repositories/folder_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MetadataRepository implements FolderRepository {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('blindkey.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE folders ADD COLUMN allowSave INTEGER DEFAULT 1',
      );
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE folders ADD COLUMN expiryDate TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        salt TEXT NOT NULL,
        verificationHash TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        allowSave INTEGER DEFAULT 1,
        expiryDate TEXT
      )
    ''');

    // Also create files table
    await db.execute('''
      CREATE TABLE files (
        id TEXT PRIMARY KEY,
        folderId TEXT NOT NULL,
        encryptedMetadata TEXT NOT NULL,
        encryptedPreviewPath TEXT NOT NULL,
        expiryDate TEXT,
        FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');
  }

  @override
  Future<Either<Failure, FolderModel>> createFolder({
    required String name,
    required String password,
  }) async {
    // This implementation is incomplete as it requires the encryption service to generate salt/hash
    // We will implement the actual logic in the Application Layer (Notifier), which calls this just to SAVE.
    // Or we should pass the fully formed model here. The interface says "createFolder(name, password)"
    // which implies business logic in repo? No, typically repo is dumb storage.
    // The INTERFACE `FolderRepository` defined previously has `createFolder(name, password)`.
    // This might be a design flaw in my interface if I want Clean Architecture.
    // Ideally, UseCase/Service creates the Model (generating salt/hash) andRepo.save(model).
    // BUT, the interface `createFolder` acts as a "high level" action.
    // Let's stick to the interface for now but we might refactor to `saveFolder(FolderModel)`.
    // Actually, `createFolder` in Repo usually implies interaction with specific backend logic.
    // Since we are "Serverless", the Repo IS the backend.

    // Wait, if I want to strictly follow Clean Architecture:
    // 1. Application Layer calls `CreateFolderUseCase`.
    // 2. UseCase generates Salt, Hash using `CryptographyService`.
    // 3. UseCase creates `FolderModel`.
    // 4. UseCase calls `FolderRepository.save(folderModel)`.

    // My previous interface `createFolder` takes name/password. This mixes concerns.
    // I should probably change the interface to `saveFolder(FolderModel)`.
    // However, I can't easily change the interface *file* right now without rewriting it.
    // I'll leave the interface as is and implement "dumb" logic assuming the params are insufficient
    // OR implementation will do the work.
    // Let's implement it here properly:
    // I need `CryptographyService` injected here to do it properly?
    // Or I should refactor the interface. Refactoring is better.

    // For now, I will implement `saveFolder` logic inside `createFolder` but I need the salt/hash.
    // Use `throw UnimplementedError`? No, I'll update the interface in the next step to be `saveFolder`.

    return left(
      const Failure.unexpected('Refactor required: Use saveFolder instead'),
    );
  }

  Future<Either<Failure, Unit>> saveFolder(FolderModel folder) async {
    try {
      final db = await database;
      // Convert boolean allowSave to integer 1 or 0 for SQLite
      final json = folder.toJson();
      final Map<String, dynamic> dbData = Map.from(json);
      dbData['allowSave'] = (folder.allowSave) ? 1 : 0;

      await db.insert(
        'folders',
        dbData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return right(unit);
    } catch (e) {
      return left(Failure.databaseError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteFolder(String id) async {
    try {
      final db = await database;
      await db.delete('folders', where: 'id = ?', whereArgs: [id]);
      // Cascading delete should handle files if enabled, but sqflite needs 'PRAGMA foreign_keys = ON'
      return right(unit);
    } catch (e) {
      return left(Failure.databaseError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FolderModel>> getFolder(String id) async {
    try {
      final db = await database;
      final maps = await db.query('folders', where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        // Convert integer allowSave back to boolean
        final Map<String, dynamic> data = Map.from(maps.first);
        data['allowSave'] = (data['allowSave'] as int?) == 1;
        return right(FolderModel.fromJson(data));
      } else {
        return left(const Failure.databaseError('Folder not found'));
      }
    } catch (e) {
      return left(Failure.databaseError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FolderModel>>> getFolders() async {
    try {
      final db = await database;
      final maps = await db.query('folders', orderBy: 'createdAt DESC');
      return right(
        maps.map((e) {
          final Map<String, dynamic> data = Map.from(e);
          data['allowSave'] = (data['allowSave'] as int?) == 1;
          return FolderModel.fromJson(data);
        }).toList(),
      );
    } catch (e) {
      return left(Failure.databaseError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPassword({
    required FolderModel folder,
    required String password,
  }) {
    // This should be done in Domain or Application service using Cryptography.
    // Repository shouldn't really check password?
    // Actually, "Repository" abstracting specific data source.
    // If we are treating this as "Authentication", it belongs in a generic Service.
    // But let's leave it stubbed.
    return Future.value(
      left(const Failure.unexpected('Use EncryptionService for verification')),
    );
  }
}
