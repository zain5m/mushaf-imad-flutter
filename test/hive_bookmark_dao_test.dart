import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:imad_flutter/imad_flutter.dart';

void main() {
  late HiveBookmarkDao dao;

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
  });

  setUp(() async {
    dao = HiveBookmarkDao();
    await dao.deleteAll();
  });

  tearDown(() async {
    await dao.deleteAll();
  });

  Bookmark createBookmark({
    String id = '1',
    int chapter = 2,
    int verse = 255,
    int page = 42,
    int createdAt = 1000,
    String note = '',
    List<String> tags = const [],
  }) {
    return Bookmark(
      id: id,
      chapterNumber: chapter,
      verseNumber: verse,
      pageNumber: page,
      createdAt: createdAt,
      note: note,
      tags: tags,
    );
  }

  group('HiveBookmarkDao', () {
    test('insert and getById returns the same bookmark', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      final result = await dao.getById('1');

      expect(result, isNotNull);
      expect(result!.id, '1');
      expect(result.chapterNumber, 2);
      expect(result.verseNumber, 255);
    });

    test('getAll returns bookmarks sorted by createdAt descending', () async {
      final b1 = createBookmark(id: '1', createdAt: 1000);
      final b2 = createBookmark(id: '2', createdAt: 2000);

      await dao.insert(b1);
      await dao.insert(b2);

      final results = await dao.getAll();

      expect(results.length, 2);
      expect(results.first.id, '2');
      expect(results.last.id, '1');
    });

    test('watchAll emits updates when bookmark inserted', () async {
      final stream = dao.watchAll();

      final events = <List<Bookmark>>[];

      final sub = stream.listen(events.add);

      final bookmark = createBookmark();

      await dao.insert(bookmark);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.isNotEmpty, true);
      expect(events.last.length, 1);

      await sub.cancel();
    });

    test('getByChapter returns correct bookmark', () async {
      final b1 = createBookmark(id: '1', chapter: 2);
      final b2 = createBookmark(id: '2', chapter: 2);
      final b3 = createBookmark(id: '3', chapter: 3);

      await dao.insert(b1);
      await dao.insert(b2);
      await dao.insert(b3);

      final result = await dao.getByChapter(2);

      expect(result, isNotNull);
      expect(result.length, 2);
    });

    test('getByVerse returns correct bookmark', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      final result = await dao.getByVerse(2, 255);

      expect(result, isNotNull);
      expect(result!.id, '1');
    });

    test('existsByVerse returns true when bookmark exists', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      final exists = await dao.existsByVerse(2, 255);

      expect(exists, true);
    });

    test('updateNote updates the bookmark note', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      await dao.updateNote('1', 'important verse');

      final result = await dao.getById('1');

      expect(result!.note, 'important verse');
    });

    test('updateTags updates bookmark tags', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      await dao.updateTags('1', ['tafseer', 'memorization']);

      final result = await dao.getById('1');

      expect(result!.tags.length, 2);
      expect(result.tags.contains('tafseer'), true);
    });

    test('delete removes bookmark', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      await dao.delete('1');

      final result = await dao.getById('1');

      expect(result, isNull);
    });

    test('deleteByVerse removes matching bookmark', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      await dao.deleteByVerse(2, 255);

      final result = await dao.getById('1');

      expect(result, isNull);
    });

    test('deleteAll removes all bookmarks', () async {
      final b1 = createBookmark(id: '1');
      final b2 = createBookmark(id: '2');

      await dao.insert(b1);
      await dao.insert(b2);

      await dao.deleteAll();

      final results = await dao.getAll();

      expect(results.isEmpty, true);
    });

    test('search finds bookmark by note', () async {
      final bookmark = createBookmark(note: 'important verse');

      await dao.insert(bookmark);

      final results = await dao.search('important');

      expect(results.length, 1);
      expect(results.first.note, 'important verse');
    });

    test('search finds bookmark by tag', () async {
      final bookmark = createBookmark(tags: ['tafseer']);

      await dao.insert(bookmark);

      final results = await dao.search('tafseer');

      expect(results.length, 1);
      expect(results.first.tags.contains('tafseer'), true);
    });

    test('search finds bookmark by verse reference', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      final results = await dao.search('2:255');

      expect(results.length, 1);
      expect(results.first.verseReference, '2:255');
    });
  });
}
