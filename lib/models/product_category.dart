import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String prodCatId;
  final String name;
  final int level;
  final List<ProductCategory>? children;

  ProductCategory({
    required this.id,
    required this.prodCatId,
    required this.name,
    required this.level,
    this.children,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id']?.toString() ?? '',
      prodCatId: json['prod_cat_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      level: json['level'] is int ? json['level'] : (json['level'] is String ? int.tryParse(json['level']) ?? 1 : 1),
      children: json['children'] != null
          ? (json['children'] as List)
              .map((child) => ProductCategory.fromJson(child as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prod_cat_id': prodCatId,
      'name': name,
      'level': level,
      'children': children?.map((child) => child.toJson()).toList(),
    };
  }

  ProductCategory copyWith({
    String? id,
    String? prodCatId,
    String? name,
    int? level,
    List<ProductCategory>? children,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      prodCatId: prodCatId ?? this.prodCatId,
      name: name ?? this.name,
      level: level ?? this.level,
      children: children ?? this.children,
    );
  }

  /// Get the icon for a category by name
  static IconData getIcon(String categoryName) {
    switch (categoryName) {
      case '旅遊':
        return FontAwesomeIcons.plane;
      case '哲學宗教':
        return FontAwesomeIcons.star;
      case '語言':
        return FontAwesomeIcons.language;
      case '漫畫／輕小說':
        return FontAwesomeIcons.bookOpen;
      case '藝術':
        return FontAwesomeIcons.palette;
      case '建築設計':
        return FontAwesomeIcons.building;
      case '少兒親子':
        return FontAwesomeIcons.child;
      case '生活風格':
        return FontAwesomeIcons.house;
      case '華文文學':
        return FontAwesomeIcons.book;
      case '世界文學':
        return FontAwesomeIcons.globe;
      case '類型文學':
        return FontAwesomeIcons.bookOpen;
      case '歷史地理':
        return FontAwesomeIcons.map;
      case '社會科學':
        return FontAwesomeIcons.users;
      case '商業':
        return FontAwesomeIcons.briefcase;
      case '電腦':
        return FontAwesomeIcons.laptop;
      case '醫學保健':
        return FontAwesomeIcons.heart;
      case '政府考用':
        return FontAwesomeIcons.file;
      case '教育':
        return FontAwesomeIcons.graduationCap;
      case '科學':
        return FontAwesomeIcons.flask;
      case '心理勵志':
        return FontAwesomeIcons.lightbulb;
      case '傳記':
        return FontAwesomeIcons.user;
      case '程式設計':
        return FontAwesomeIcons.code;
      case '設計':
        return FontAwesomeIcons.palette;
      case '人工智慧':
        return FontAwesomeIcons.robot;
      case '資料庫':
        return FontAwesomeIcons.database;
      case '網路安全':
        return FontAwesomeIcons.shield;
      case '雲端運算':
        return FontAwesomeIcons.cloud;
      case '區塊鏈':
        return FontAwesomeIcons.link;
      default:
        return FontAwesomeIcons.book;
    }
  }
}