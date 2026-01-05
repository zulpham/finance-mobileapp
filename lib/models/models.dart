class Category {
  final int? id;
  final String name;
  final bool isIncome;

  Category({this.id, required this.name, required this.isIncome});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id_kategori'],
      name: map['nama_kategori'],
      isIncome: map['is_pemasukan'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_kategori': id,
      'nama_kategori': name,
      'is_pemasukan': isIncome ? 1 : 0,
    };
  }
}

class TransactionModel {
  final int? id;
  final String name;
  final DateTime date;
  final int amount;
  final String description;
  final bool isIncome;
  final int categoryId;
  final String? categoryName;

  TransactionModel({
    this.id,
    required this.name,
    required this.date,
    required this.amount,
    required this.description,
    required this.isIncome,
    required this.categoryId,
    this.categoryName,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id_transaksi'],
      name: map['nama'],
      date: DateTime.parse(map['tanggal']),
      amount: map['nominal'],
      description: map['keterangan'] ?? '',
      isIncome: map['is_pemasukan'] == 1,
      categoryId: map['id_kategori'],
      categoryName: map['nama_kategori'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_transaksi': id,
      'nama': name,
      'tanggal': date.toIso8601String().split('T').first,
      'nominal': amount,
      'keterangan': description,
      'is_pemasukan': isIncome ? 1 : 0,
      'id_kategori': categoryId,
    };
  }
}

// UPDATE: userId diganti menjadi String untuk mendukung 'user001'
class SavingsModel {
  final String userId;
  final int balance;

  SavingsModel({required this.userId, required this.balance});

  factory SavingsModel.fromMap(Map<String, dynamic> map) {
    return SavingsModel(
      userId: map['user_id'],
      balance: map['tabungan'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'tabungan': balance,
    };
  }
}