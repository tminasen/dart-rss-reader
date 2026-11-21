import 'dart:convert';

import 'package:server/server.dart';
import 'package:server/src/repository/article_repository.dart';
import 'package:server/src/repository/in_memory_article_repository.dart';
import 'package:server/src/repository/in_memory_subscription_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'repository/fixtures.dart';

void noopLogger(String message, bool isError) {}

/// id '1'(11/1) '2'(11/2) '3'(11/3) はフィード '1'、'4'(11/9) はフィード '2'。
/// '2' だけ既読。新しい順は ['4', '3', '2', '1']。
Future<InMemoryArticleRepository> seeded() async {
  final repo = InMemoryArticleRepository();
  await repo.addAll('1', [rss(1), rss(2), rss(3)]);
  await repo.addAll('2', [atomArticle]);
  await repo.setRead('2', isRead: true);
  return repo;
}

Handler handlerWith(ArticleRepository repo) => buildHandler(
  subscriptionRepository: InMemorySubscriptionRepository(),
  articleRepository: repo,
  logger: noopLogger,
);

Request get(String q) =>
    Request('GET', Uri.parse('http://localhost/articles$q'));

Request patch(String id, String body) =>
    Request('PATCH', Uri.parse('http://localhost/articles/$id'), body: body);

Future<Map<String, Object?>> decode(Response response) async =>
    jsonDecode(await response.readAsString()) as Map<String, Object?>;

List<Object?> ids(Map<String, Object?> json) =>
    (json['items'] as List).map((e) => (e as Map)['id']).toList();

void main() {
  group('GET /articles', () {
    test('should return 200 and application/json when requested', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: GET /articles を処理する
      final response = await handler(get(''));

      // Then: 200 と JSON の content-type になる
      expect(response.statusCode, equals(200));
      expect(response.mimeType, equals('application/json'));
    });

    test(
      'should return all articles newest first with default paging when no parameters',
      () async {
        // Given: 記事が登録されたリポジトリ
        final handler = handlerWith(await seeded());

        // When: パラメータなしで GET /articles を処理する
        final json = await decode(await handler(get('')));

        // Then: 全件が新しい順で、既定の limit / offset が返る
        expect(ids(json), equals(['4', '3', '2', '1']));
        expect(json['limit'], equals(20));
        expect(json['offset'], equals(0));
      },
    );

    test('should represent an article in nested form when listed', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: feedId=1&limit=1 で GET /articles を処理する
      final json = await decode(await handler(get('?feedId=1&limit=1')));

      // Then: 先頭は入れ子の形の rss(3) になる
      expect(json['items'], [
        {'id': '3', 'feedId': '1', 'isRead': false, 'article': rss(3).toJson()},
      ]);
    });

    test('should return empty items when no articles exist', () async {
      // Given: 空のリポジトリ
      final handler = handlerWith(InMemoryArticleRepository());

      // When: GET /articles を処理する
      final response = await handler(get(''));

      // Then: 200 で空の items と既定のページ情報が返る
      expect(response.statusCode, equals(200));
      expect(await decode(response), {'items': [], 'limit': 20, 'offset': 0});
    });

    test('should filter by feedId when feedId is given', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: feedId=1 で GET /articles を処理する
      final json = await decode(await handler(get('?feedId=1')));

      // Then: フィード 1 の記事だけが新しい順で返る
      expect(ids(json), equals(['3', '2', '1']));
    });

    test('should return only unread when unread=true', () async {
      // Given: 記事が登録されたリポジトリ（'2' は既読）
      final handler = handlerWith(await seeded());

      // When: unread=true で GET /articles を処理する
      final json = await decode(await handler(get('?unread=true')));

      // Then: 未読だけが返る
      expect(ids(json), equals(['4', '3', '1']));
    });

    test('should filter by feedId and unread when both are given', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: feedId=1&unread=true で GET /articles を処理する
      final json = await decode(await handler(get('?feedId=1&unread=true')));

      // Then: フィード 1 の未読だけが返る
      expect(ids(json), equals(['3', '1']));
    });

    test('should not filter when unread=false', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: unread=false で GET /articles を処理する
      final json = await decode(await handler(get('?unread=false')));

      // Then: 既読を含む全件が返る
      expect(ids(json), equals(['4', '3', '2', '1']));
    });

    test('should return empty items when feedId does not exist', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: 存在しない feedId で GET /articles を処理する
      final response = await handler(get('?feedId=999'));

      // Then: 200 で空の items が返る
      expect(response.statusCode, equals(200));
      expect(ids(await decode(response)), equals([]));
    });

    test(
      'should keep order and only drop read articles when unread=true for any feedId',
      () async {
        // Given: 記事が登録されたリポジトリ
        final handler = handlerWith(await seeded());

        for (final feedQuery in ['', '&feedId=1', '&feedId=2', '&feedId=999']) {
          // When: unread の有無で同じ feedId の一覧を取得する
          final all = await decode(
            await handler(get('?unread=false$feedQuery')),
          );
          final unread = await decode(
            await handler(get('?unread=true$feedQuery')),
          );

          // Then: 未読の一覧は、全件のうち isRead == false のものを順序を保って並べたもの
          final expected = (all['items'] as List)
              .where((e) => (e as Map)['isRead'] == false)
              .toList();
          expect(
            unread['items'],
            equals(expected),
            reason: 'feedQuery=$feedQuery',
          );
        }
      },
    );

    test('should slice a page when limit and offset are given', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: limit=2&offset=1 で GET /articles を処理する
      final json = await decode(await handler(get('?limit=2&offset=1')));

      // Then: 新しい順の [1,3) が返り、limit / offset も返る
      expect(ids(json), equals(['3', '2']));
      expect(json['limit'], equals(2));
      expect(json['offset'], equals(1));
    });

    test('should return only one article when limit=1', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: limit=1 で GET /articles を処理する
      final json = await decode(await handler(get('?limit=1')));

      // Then: 最新の1件だけが返る
      expect(ids(json), equals(['4']));
      expect(json['limit'], equals(1));
    });

    test('should accept limit=100 when limit is at upper bound', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: limit=100 で GET /articles を処理する
      final json = await decode(await handler(get('?limit=100')));

      // Then: 全件が返り、limit は 100
      expect(ids(json), equals(['4', '3', '2', '1']));
      expect(json['limit'], equals(100));
    });

    test('should return from the head when offset=0 is explicit', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: limit=2&offset=0 で GET /articles を処理する
      final json = await decode(await handler(get('?limit=2&offset=0')));

      // Then: 先頭の2件が返り、offset は 0
      expect(ids(json), equals(['4', '3']));
      expect(json['offset'], equals(0));
    });

    test('should limit to 20 items when limit is omitted', () async {
      // Given: 25 件の記事が登録されたリポジトリ
      final repo = InMemoryArticleRepository();
      await repo.addAll('1', [for (var n = 1; n <= 25; n++) rss(n)]);
      final handler = handlerWith(repo);

      // When: パラメータなしで GET /articles を処理する
      final json = await decode(await handler(get('')));

      // Then: 新しい順に 20 件（'25'〜'6'）が返る
      expect(ids(json), equals([for (var n = 25; n >= 6; n--) '$n']));
      expect(json['limit'], equals(20));
    });

    test('should return the last article when offset points to it', () async {
      // Given: 記事が登録されたリポジトリ（4件）
      final handler = handlerWith(await seeded());

      // When: offset=3 で GET /articles を処理する
      final json = await decode(await handler(get('?offset=3')));

      // Then: 最後の1件が返り、既定の limit と指定した offset が返る
      expect(ids(json), equals(['1']));
      expect(json['limit'], equals(20));
      expect(json['offset'], equals(3));
    });

    test('should return empty items when offset equals the count', () async {
      // Given: 記事が登録されたリポジトリ（4件）
      final handler = handlerWith(await seeded());

      // When: offset=4 で GET /articles を処理する
      final response = await handler(get('?offset=4'));

      // Then: 200 で空の items が返り、offset は 4
      expect(response.statusCode, equals(200));
      final json = await decode(response);
      expect(ids(json), equals([]));
      expect(json['offset'], equals(4));
    });

    test(
      'should match skip and take of all articles when paging for any limit and offset',
      () async {
        // Given: 記事が登録されたリポジトリ
        final handler = handlerWith(await seeded());
        final all = ids(await decode(await handler(get('?limit=100'))));

        for (final limit in [1, 2, 3, 4, 5, 20, 100]) {
          for (final offset in [0, 1, 2, 3, 4, 5]) {
            // When: limit と offset を指定して GET /articles を処理する
            final json = await decode(
              await handler(get('?limit=$limit&offset=$offset')),
            );

            // Then: 全件の新しい順を skip(offset).take(limit) したものと一致する
            expect(
              ids(json),
              equals(all.skip(offset).take(limit).toList()),
              reason: 'limit=$limit offset=$offset',
            );
          }
        }
      },
    );

    test('should return 400 when limit=0', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: limit=0 で GET /articles を処理する
      final response = await handler(get('?limit=0'));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });

    test('should return 400 when limit=101', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: limit=101 で GET /articles を処理する
      final response = await handler(get('?limit=101'));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });

    test('should return 400 when limit is not an integer', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: limit=abc で GET /articles を処理する
      final response = await handler(get('?limit=abc'));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });

    test('should return JSON error body when request is invalid', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: limit=0 で GET /articles を処理する
      final response = await handler(get('?limit=0'));

      // Then: application/json で error が文字列の本文になる
      expect(response.mimeType, equals('application/json'));
      expect((await decode(response))['error'], isA<String>());
    });

    test('should return 400 when offset is negative', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: offset=-1 で GET /articles を処理する
      final response = await handler(get('?offset=-1'));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });

    test('should return 400 when offset is not an integer', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: offset=abc で GET /articles を処理する
      final response = await handler(get('?offset=abc'));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });

    test('should return 400 when unread is neither true nor false', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: unread=yes で GET /articles を処理する
      final response = await handler(get('?unread=yes'));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });
  });

  group('PATCH /articles/{id}', () {
    test('should mark as read and return the updated article', () async {
      // Given: 記事が登録されたリポジトリ（'1' は未読）
      final handler = handlerWith(await seeded());

      // When: PATCH /articles/1 に {"isRead":true} を送る
      final response = await handler(patch('1', '{"isRead":true}'));

      // Then: 200・application/json で更新後の記事が返る
      expect(response.statusCode, equals(200));
      expect(response.mimeType, equals('application/json'));
      expect(await decode(response), {
        'id': '1',
        'feedId': '1',
        'isRead': true,
        'article': rss(1).toJson(),
      });
    });

    test('should persist read state when marked as read', () async {
      // Given: 記事が登録されたリポジトリ（'1' は未読）
      final repo = await seeded();
      final handler = handlerWith(repo);

      // When: PATCH /articles/1 に {"isRead":true} を送る
      await handler(patch('1', '{"isRead":true}'));

      // Then: リポジトリ上で既読になっている
      expect((await repo.findById('1'))!.isRead, isTrue);
    });

    test('should mark as unread when isRead is false', () async {
      // Given: 記事が登録されたリポジトリ（'2' は既読）
      final repo = await seeded();
      final handler = handlerWith(repo);

      // When: PATCH /articles/2 に {"isRead":false} を送る
      final response = await handler(patch('2', '{"isRead":false}'));

      // Then: 200 で isRead が false になり、リポジトリにも反映される
      expect(response.statusCode, equals(200));
      expect((await decode(response))['isRead'], isFalse);
      expect((await repo.findById('2'))!.isRead, isFalse);
    });

    test('should succeed when the same value is given', () async {
      // Given: 記事が登録されたリポジトリ（'1' は未読）
      final handler = handlerWith(await seeded());

      // When: PATCH /articles/1 に {"isRead":false} を送る
      final response = await handler(patch('1', '{"isRead":false}'));

      // Then: 200 で isRead は false のまま
      expect(response.statusCode, equals(200));
      expect((await decode(response))['isRead'], isFalse);
    });

    test('should return 404 when the article does not exist', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: 存在しない id 999 に PATCH する
      final response = await handler(patch('999', '{"isRead":true}'));

      // Then: 404 になる
      expect(response.statusCode, equals(404));
    });

    test('should return JSON error body when the article is missing', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: 存在しない id 999 に PATCH する
      final response = await handler(patch('999', '{"isRead":true}'));

      // Then: application/json で error が文字列の本文になる
      expect(response.mimeType, equals('application/json'));
      expect((await decode(response))['error'], isA<String>());
    });

    test('should return 400 when body is not JSON', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: PATCH /articles/1 に JSON でないボディを送る
      final response = await handler(patch('1', 'abc'));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });

    test('should return 400 when body is empty', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: PATCH /articles/1 に 空のボディを送る
      final response = await handler(patch('1', ''));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });

    test('should return 400 when isRead is missing', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: PATCH /articles/1 に isRead がないボディを送る
      final response = await handler(patch('1', '{}'));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });

    test('should return 400 when isRead is not a boolean', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: PATCH /articles/1 に 真偽値でない isReadを送る
      final response = await handler(patch('1', '{"isRead":"true"}'));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });

    test('should return 400 when body is not a JSON object', () async {
      // Given: 記事が登録されたリポジトリ
      final handler = handlerWith(await seeded());

      // When: PATCH /articles/1 に オブジェクトでないボディを送る
      final response = await handler(patch('1', '[true]'));

      // Then: 400 になる
      expect(response.statusCode, equals(400));
    });

    test('should keep read state when body is invalid', () async {
      // Given: 記事が登録されたリポジトリ（'1' は未読）
      final repo = await seeded();
      final handler = handlerWith(repo);

      // When: PATCH /articles/1 に真偽値でない isRead を送る
      await handler(patch('1', '{"isRead":"true"}'));

      // Then: '1' は未読のまま
      expect((await repo.findById('1'))!.isRead, isFalse);
    });
  });
}
