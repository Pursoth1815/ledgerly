import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/network/dio/dio_client.dart';
import '../../core/network/api/master_data_api.dart';

/// Dio provider
final dioProvider = Provider<Dio>((ref) {
  return DioClient.create();
});

final masterDataApiProvider = Provider<MasterDataApi>((ref) {
  return MasterDataApi(ref.read(dioProvider));
});
