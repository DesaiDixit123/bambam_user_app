// lib/data/models/about_us_model.dart
import 'package:equatable/equatable.dart';

class AboutUsModel extends Equatable {
  final String title;
  final String description;
  final String imageUrl;

  const AboutUsModel({required this.title, required this.description, required this.imageUrl});

  factory AboutUsModel.empty() => const AboutUsModel(title: '', description: '', imageUrl: '');

  factory AboutUsModel.fromJson(Map<String, dynamic> json) {
    return AboutUsModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'image_url': imageUrl,
      };

  @override
  List<Object?> get props => [title, description, imageUrl];
}
