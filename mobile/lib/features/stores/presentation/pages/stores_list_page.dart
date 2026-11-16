import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../bloc/stores_bloc.dart';
import '../widgets/store_card.dart';
import '../widgets/store_map_widgets.dart';

/// Plain list of stores with a map shortcut in the glass top bar.
class StoresListPage extends StatelessWidget {
  const StoresListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoresBloc, StoresState>(
      builder: (context, state) {
        final List<Widget> slivers;
        if (state is StoresError) {
          slivers = [
            SliverToBoxAdapter(
              child: StoresStateMessage(
                icon: Icons.cloud_off_rounded,
                color: AppColors.error,
                title: 'Не удалось загрузить',
                message: state.message,
                action: GlassButton(
                  label: 'Повторить',
                  icon: Icons.refresh_rounded,
                  onTap: () =>
                      context.read<StoresBloc>().add(const LoadStores()),
                ),
              ),
            ),
          ];
        } else if (state is StoresLoaded) {
          slivers = state.stores.isEmpty
              ? const [
                  SliverToBoxAdapter(
                    child: StoresStateMessage(
                      icon: Icons.storefront_outlined,
                      title: 'Нет магазинов',
                    ),
                  ),
                ]
              : [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.builder(
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
                  ),
                ];
        } else {
          slivers = const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
          ];
        }

        return GlassPage(
          title: 'Магазины',
          actions: [
            GlassIconButton(
              icon: Icons.map_outlined,
              tooltip: 'Карта',
              onTap: () => context.push('/stores-map'),
            ),
          ],
          onRefresh: () async =>
              context.read<StoresBloc>().add(const LoadStores()),
          slivers: slivers,
        );
      },
    );
  }
}
