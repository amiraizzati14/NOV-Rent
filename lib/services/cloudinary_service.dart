import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'novrent123';
  static const String uploadPreset = 'identitas_user';

  static Future<String> uploadImage({
    required XFile file,
    String folder = 'verifications',
  }) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary Cloud Name atau Upload Preset belum diisi. '
        'Silakan atur di lib/services/cloudinary_service.dart',
      );
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name.isNotEmpty ? file.name : 'upload.jpg',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = jsonResponse['secure_url'] as String?;
      if (secureUrl != null && secureUrl.isNotEmpty) {
        return secureUrl;
      }
      throw Exception('Format respons Cloudinary tidak sesuai.');
    } else {
      String errorMessage =
          'Gagal mengunggah foto ke Cloudinary (${response.statusCode})';
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        if (errorData['error']?['message'] != null) {
          errorMessage = errorData['error']['message'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
