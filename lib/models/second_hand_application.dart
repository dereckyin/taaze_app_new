/// 產品等級
enum ProductRank {
  a('全新'),
  b('近全新'),
  c('良好'),
  d('普通'),
  e('差強人意');

  final String value;
  const ProductRank(this.value);

  static ProductRank fromString(String value) {
    return ProductRank.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => ProductRank.c,
    );
  }
}

/// 產品標記
enum ProductMark {
  new_('new'),
  used('used'),
  damaged('damaged');

  final String value;
  const ProductMark(this.value);

  static ProductMark fromString(String value) {
    return ProductMark.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ProductMark.used,
    );
  }
}

/// 配送方式
enum DeliveryType {
  home('home'),
  store('store'),
  post('post');

  final String value;
  const DeliveryType(this.value);

  static DeliveryType fromString(String value) {
    return DeliveryType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => DeliveryType.home,
    );
  }
}

/// 二手書申請單項目
class SecondHandBookApplicationItem {
  final String? id;
  final String? custId;
  final String? prodId;
  final String orgProdId;
  final ProductRank prodRank;
  final ProductMark prodMark;
  final double salePrice;
  final String? otherMark;

  SecondHandBookApplicationItem({
    this.id,
    this.custId,
    this.prodId,
    required this.orgProdId,
    required this.prodRank,
    required this.prodMark,
    required this.salePrice,
    this.otherMark,
  });

  factory SecondHandBookApplicationItem.fromJson(Map<String, dynamic> json) {
    return SecondHandBookApplicationItem(
      id: json['id']?.toString(),
      custId: json['cust_id']?.toString(),
      orgProdId: json['org_prod_id']?.toString() ?? '',
      prodId: json['prod_id']?.toString(),
      prodRank: ProductRank.fromString(json['prod_rank']?.toString() ?? 'C'),
      prodMark: ProductMark.fromString(json['prod_mark']?.toString() ?? 'used'),
      salePrice: (json['sale_price'] ?? 0.0).toDouble(),
      otherMark: json['other_mark']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (custId != null) 'cust_id': custId,
      'org_prod_id': orgProdId,
      'prod_rank': prodRank.value,
      'prod_mark': prodMark.value,
      'sale_price': salePrice,
      if (otherMark != null) 'other_mark': otherMark,
    };
  }
}

/// 二手書申請單
class SecondHandBookApplication {
  final String? id;
  final String? custId;
  final String? custName;
  final String? custMobile;
  final String? cityId;
  final String? townId;
  final String? zip;
  final String? address;
  final DeliveryType deliveryType;
  final String? telDay;
  final String? telNight;
  final String? sprodAskNo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SecondHandBookApplication({
    this.id,
    this.custId,
    this.custName,
    this.custMobile,
    this.cityId,
    this.townId,
    this.zip,
    this.address,
    required this.deliveryType,
    this.telDay,
    this.telNight,
    this.sprodAskNo,
    this.createdAt,
    this.updatedAt,
  });

  factory SecondHandBookApplication.fromJson(Map<String, dynamic> json) {
    return SecondHandBookApplication(
      id: json['id']?.toString(),
      custId: json['cust_id']?.toString(),
      custName: json['cust_name']?.toString(),
      custMobile: json['cust_mobile']?.toString(),
      cityId: json['city_id']?.toString(),
      townId: json['town_id']?.toString(),
      zip: json['zip']?.toString(),
      address: json['address']?.toString(),
      deliveryType: DeliveryType.fromString(
        json['delivery_type']?.toString() ?? 'home',
      ),
      telDay: json['tel_day']?.toString(),
      telNight: json['tel_night']?.toString(),
      sprodAskNo: json['sprod_ask_no']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (custId != null) 'cust_id': custId,
      if (custName != null) 'cust_name': custName,
      if (custMobile != null) 'cust_mobile': custMobile,
      if (cityId != null) 'city_id': cityId,
      if (townId != null) 'town_id': townId,
      if (zip != null) 'zip': zip,
      if (address != null) 'address': address,
      'delivery_type': deliveryType.value,
      if (telDay != null) 'tel_day': telDay,
      if (telNight != null) 'tel_night': telNight,
      if (sprodAskNo != null) 'sprod_ask_no': sprodAskNo,
    };
  }
}

/// 分頁響應
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 10,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}
