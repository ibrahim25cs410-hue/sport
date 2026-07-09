import '../models/stadium.dart';
import '../utils/paged_response.dart';
import '../core/paging/paged_list_state.dart';
import 'api_service.dart';

class StadiumService {
  StadiumService(this._api);

  final ApiService _api;

  Future<List<Stadium>> listStadiums({int page = 1, int limit = defaultPageSize}) async {
    final res = await _api.dio.get('/stadiums', queryParameters: {'page': page, 'limit': limit});
    return unwrapPagedList(res.data, Stadium.fromJson);
  }

  Future<List<Stadium>> listMyStadiums({int page = 1, int limit = defaultPageSize}) async {
    final res = await _api.dio.get('/stadiums/mine', queryParameters: {'page': page, 'limit': limit});
    return unwrapPagedList(res.data, Stadium.fromJson);
  }

  Future<Stadium> getStadium(int id) async {
    final res = await _api.dio.get('/stadiums/$id');
    return Stadium.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Stadium> createStadium({
    required String name,
    String address = '',
    String phone = '',
    int pricePerHour = 0,
    String? image,
    String description = '',
  }) async {
    final res = await _api.dio.post('/stadiums', data: {
      'name': name,
      'address': address,
      'phone': phone,
      'pricePerHour': pricePerHour,
      if (image != null) 'image': image,
      'description': description,
    });
    return Stadium.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Stadium> updateStadium(
    int id, {
    String? name,
    String? address,
    String? phone,
    int? pricePerHour,
    String? image,
    String? description,
  }) async {
    final res = await _api.dio.put('/stadiums/$id', data: {
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (pricePerHour != null) 'pricePerHour': pricePerHour,
      if (image != null) 'image': image,
      if (description != null) 'description': description,
    });
    return Stadium.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteStadium(int id) async {
    await _api.dio.delete('/stadiums/$id');
  }
}
