import 'package:dio/dio.dart';

class MasterDataApi {
  MasterDataApi(this._dio);

  final Dio _dio;

  Future<Response> getMasterData() {
    return _dio.get(
      '',
      queryParameters: {
        'action': 'getMasterData',
      },
    );
  }
}
