import 'package:vietnam_provinces/vietnam_provinces.dart' as vp;

class ProvinceModel {
  final String code;
  final String name;
  const ProvinceModel({required this.code, required this.name});
}

class DistrictModel {
  final String code;
  final String name;
  final String provinceCode;
  const DistrictModel({
    required this.code,
    required this.name,
    required this.provinceCode,
  });
}

class WardModel {
  final String code;
  final String name;
  const WardModel({required this.code, required this.name});
}

class VietnamAddressService {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await vp.VietnamProvinces.initialize();
    _initialized = true;
  }

  Future<List<ProvinceModel>> getProvinces() async {
    await ensureInitialized();
    return vp.VietnamProvinces.getProvinces()
        .map((p) => ProvinceModel(code: p.code.toString(), name: p.name))
        .toList();
  }

  Future<List<DistrictModel>> getDistricts(String provinceCode) async {
    await ensureInitialized();
    return vp.VietnamProvinces.getDistricts(
      provinceCode: int.parse(provinceCode),
    )
        .map((d) => DistrictModel(
              code: d.code.toString(),
              name: d.name,
              provinceCode: provinceCode,
            ))
        .toList();
  }

  Future<List<WardModel>> getWards(
      String provinceCode, String districtCode) async {
    await ensureInitialized();
    return vp.VietnamProvinces.getWards(
      provinceCode: int.parse(provinceCode),
      districtCode: int.parse(districtCode),
    ).map((w) => WardModel(code: w.code.toString(), name: w.name)).toList();
  }
}
