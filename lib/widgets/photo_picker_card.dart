import 'package:flutter/material.dart';
import 'dart:io';

class PhotoPickerCard extends StatelessWidget {
  final File? photo;
  final VoidCallback onPickImage;
  
  const PhotoPickerCard({
    required this.photo,
    required this.onPickImage,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: photo != null ? Color(0xFF4FC3F7) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: photo != null
            ? _buildPhotoPreview()
            : _buildPlaceholder(),
      ),
    );
  }
  
  Widget _buildPhotoPreview() {
    return Stack(
      children: [
        // Фото
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.file(
            photo!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        
        // Затемнение сверху для текста
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
                Colors.transparent,
              ],
            ),
          ),
        ),
        
        // Текст "Изменить"
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, size: 16, color: Color(0xFF4FC3F7)),
                SizedBox(width: 5),
                Text(
                  'Изменить',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4FC3F7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF4FC3F7).withOpacity(0.1),
            border: Border.all(
              color: Color(0xFF4FC3F7).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.add_a_photo,
            size: 40,
            color: Color(0xFF4FC3F7),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Добавить фото',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Нажмите, чтобы выбрать фото\nиз галереи или сделать снимок',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}