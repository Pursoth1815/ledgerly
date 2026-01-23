import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/config/di/di_providers.dart';
import 'package:ledgerly/features/master_data/repository/master_data_repository.dart';
import '../models/master_data_model.dart';


final masterDataRepositoryProvider =
    Provider<MasterDataRepository>((ref) {
  return MasterDataRepository(ref.read(masterDataApiProvider));
});

final masterDataProvider = FutureProvider<MasterData>((ref) {
  return ref.read(masterDataRepositoryProvider).fetchMasterData();
});
