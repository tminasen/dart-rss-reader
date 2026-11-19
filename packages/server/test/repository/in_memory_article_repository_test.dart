import 'package:server/src/repository/in_memory_article_repository.dart';

import 'article_repository_contract.dart';

void main() {
  articleRepositoryContract(() async => InMemoryArticleRepository());
}
