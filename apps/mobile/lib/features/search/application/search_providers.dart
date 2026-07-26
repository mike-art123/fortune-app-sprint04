import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/shared_providers.dart';
import '../data/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(apiClientProvider));
});
