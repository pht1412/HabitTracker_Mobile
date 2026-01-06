import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // 🔥 CẤU HÌNH CLOUDINARY (Bạn cần thay đổi thông tin của mình vào đây)
  // 1. Tạo tài khoản Cloudinary miễn phí: https://cloudinary.com/
  // 2. Vào Settings -> Upload -> Add upload preset -> Chọn "Unsigned" -> Lưu lại tên preset

  final String cloudName = "dapsvdkmt"; // Ví dụ: dxx51...
  final String uploadPreset = "primeshop_preset"; // Ví dụ: my_app_preset

  Future<String?> uploadImage(File imageFile) async {
    try {
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      var request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = uploadPreset;

      // Gắn file ảnh vào request
      var pic = await http.MultipartFile.fromPath("file", imageFile.path);
      request.files.add(pic);

      // Gửi đi
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonMap = jsonDecode(responseString);

        // Trả về đường dẫn ảnh an toàn (HTTPS)
        return jsonMap['secure_url'];
      } else {
        print("Upload Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Lỗi Cloudinary: $e");
      return null;
    }
  }
}