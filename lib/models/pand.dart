enum Category { poet, thinker, leader, writer, artist, book }

const Map<Category, String> persionCtg = {
  Category.thinker: 'اندیشمند',
  Category.leader: 'رهبر',
  Category.poet: 'شاعر ',
  Category.writer: 'نویسنده',
  Category.artist: 'هنرمند',
  Category.book: 'یک کتاب',
};

class Pand {
  int? id;
  final String title;
  final String sentence;
  final String teller;
  final Category category;
  bool isFavorite;

  Pand({
    this.id,
    required this.title,
    required this.sentence,
    required this.category,
    required this.teller,
    this.isFavorite = false,
  });

  //map -> Pand
  factory Pand.fromMap(Map<String, dynamic> map) {
    return Pand(
      id: map['id'] as int,
      title: map['title'] as String,
      sentence: map['sentence'] as String,
      category: Category.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => Category.leader,
      ),
      teller: map['teller'] as String,
      isFavorite: map['isFavorite'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sentence': sentence,
      'category': category.name,
      'teller': teller,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  Map<String, dynamic> toMapForSupabase() {
    return {
      'title': title,
      'sentence': sentence,
      'category': category.name,
      'teller': teller,
    };
  }
}
