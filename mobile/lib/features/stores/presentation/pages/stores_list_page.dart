import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../bloc/stores_bloc.dart';
import '../widgets/store_card.dart';

class StoresListPage extends StatelessWidget {
  const StoresListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Магазины',
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Карта',
            onPressed: () => context.push('/stores-map'),
          ),
        ],
      ),
      body: GradientBackground(
        child: BlocBuilder<StoresBloc, StoresState>(
          builder: (context, state) {
            if (state is StoresLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is StoresError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<StoresBloc>().add(const LoadStores()),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }
            if (state is StoresLoaded) {
              if (state.stores.isEmpty) {
                return Center(
                  child: Text(
                    'Нет магазинов',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context.read<StoresBloc>().add(const LoadStores());
                },
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    16,
                    32,
                  ),
                  itemCount: state.stores.length,
                  itemBuilder: (context, index) {
                    final store = state.stores[index];
                    return StoreCard(
                      store: store,
                      onTap: () => context.push(
                        '/stores/${store.id}',
                        extra: store,
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
