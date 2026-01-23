// master_data_repository.dart
import 'package:ledgerly/core/errors/error_handler.dart';
import 'package:ledgerly/core/network/api/master_data_api.dart';
import 'package:ledgerly/core/utils/logger.dart';
import 'package:ledgerly/features/master_data/models/master_data_model.dart';

class MasterDataRepository {
  final MasterDataApi api;

  MasterDataRepository(this.api);

  Future<MasterData> fetchMasterData() async {
    AppLogger.d('Fetching master data', tag: 'MASTER_DATA');

    try {
      final response = await api.getMasterData();
      return MasterData.fromJson(response.data);
    } catch (error, st) {
      AppLogger.e(
        'Failed to fetch master data',
        tag: 'MASTER_DATA',
        stackTrace: st,
      );

      throw ErrorHandler.handle(error);
    }
  }
}
