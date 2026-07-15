import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  throw UnimplementedError('ApiService must be overridden in ProviderScope');
});
