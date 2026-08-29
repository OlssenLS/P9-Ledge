// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(categoriesRepository)
final categoriesRepositoryProvider = CategoriesRepositoryProvider._();

final class CategoriesRepositoryProvider
    extends
        $FunctionalProvider<
          CategoriesRepository,
          CategoriesRepository,
          CategoriesRepository
        >
    with $Provider<CategoriesRepository> {
  CategoriesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoriesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoriesRepository create(Ref ref) {
    return categoriesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoriesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoriesRepository>(value),
    );
  }
}

String _$categoriesRepositoryHash() =>
    r'aca8a79a8adf0985ca7775bf39cf8b2e4a103526';

@ProviderFor(watchCategories)
final watchCategoriesProvider = WatchCategoriesProvider._();

final class WatchCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategoryEntity>>,
          List<CategoryEntity>,
          Stream<List<CategoryEntity>>
        >
    with
        $FutureModifier<List<CategoryEntity>>,
        $StreamProvider<List<CategoryEntity>> {
  WatchCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchCategoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<CategoryEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CategoryEntity>> create(Ref ref) {
    return watchCategories(ref);
  }
}

String _$watchCategoriesHash() => r'7e540a800376a5d6414cca162ce8352654f168ae';
