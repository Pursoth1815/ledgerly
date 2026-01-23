import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/core/errors/app_exception.dart';
import 'package:ledgerly/features/master_data/master_data.dart';
import 'package:ledgerly/shared/widgets/app_error_view.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterDataAsync = ref.watch(masterDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledgerly'),
      ),
      body: masterDataAsync.when(
        data: (masterData) {
          return ListView.builder(
            itemCount: masterData.categories.length,
            itemBuilder: (_, index) {
              Category item = masterData.categories[index];
              return ListTile(
                title: Text(item.name),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) {
          if (error is AppException) {
            return AppErrorView(message: error.message);
          }
          return const AppErrorView(message: 'Something went wrong');
        },
      ),
    );
  }
}
