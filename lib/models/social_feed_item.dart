class SocialFeedItem {
  final String custId;
  final String? nickName;
  final String prodId;
  final String? prodName;
  final String? readProgress;
  final String status;
  final String crtTime;

  SocialFeedItem({
    required this.custId,
    this.nickName,
    required this.prodId,
    this.prodName,
    this.readProgress,
    required this.status,
    required this.crtTime,
  });

  factory SocialFeedItem.fromJson(Map<String, dynamic> json) {
    return SocialFeedItem(
      custId: json['cust_id']?.toString() ?? json['CUST_ID']?.toString() ?? '',
      nickName: json['nick_name']?.toString() ?? json['NICK_NAME']?.toString(),
      prodId: json['prod_id']?.toString() ?? json['PROD_ID']?.toString() ?? '',
      prodName: json['prod_name']?.toString() ?? json['PROD_NAME']?.toString(),
      readProgress:
          json['read_progress']?.toString() ?? json['READ_PROGRESS']?.toString(),
      status: json['status']?.toString() ?? json['STATUS']?.toString() ?? '',
      crtTime: json['crt_time']?.toString() ?? json['CRT_TIME']?.toString() ?? '',
    );
  }

  bool get isReading => status == 'Y' || status == 'F';
  bool get isCollection => status == 'Y';
}
