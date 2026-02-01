import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

abstract class ProductsRemoteDatasource {
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? search,
    String? sortBy,
    bool? isNew,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  });
  Future<ProductModel> getProductById(String id);
}

class ProductsRemoteDatasourceImpl implements ProductsRemoteDatasource {
  final ApiClient _apiClient;

  ProductsRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.get(ApiEndpoints.categories);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? search,
    String? sortBy,
    bool? isNew,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (isNew != null) queryParams['isNew'] = isNew;
    if (minPrice != null) queryParams['minPrice'] = minPrice;
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice;

    final response = await _apiClient.get(
      ApiEndpoints.products,
      queryParameters: queryParams,
    );
    final data = response.data;
    final List<dynamic> list;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data')) {
        list = data['data'] as List<dynamic>;
      } else if (data.containsKey('items')) {
        list = data['items'] as List<dynamic>;
      } else {
        list = [];
      }
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.products}/$id');
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }
}
