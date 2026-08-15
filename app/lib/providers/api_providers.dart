import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

final apiClientProvider = FutureProvider<ApiClient>((ref) => ApiClient.create());

Future<ApiClient> requireApiClient() => ApiClient.create();
