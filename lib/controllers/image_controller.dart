import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kind_clock/services/firebase_storage.dart';

class ImageController extends GetxController {
  // final store = Get.find<FirebaseStorageService>(); // REMOVED: Migrating to Django
  Rx<File?> pickedImage = Rx<File?>(null);
  final isLoading = false.obs;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      pickedImage.value = File(image.path);
    }
  }

  Future<String> uploadImage(String userId, File image) async {
    isLoading.value = true;
    // String downloadUrl = await store.uploadFile(image, "profile/$userId"); // REMOVED: Firebase dependency
    isLoading.value = false;
    return "https://placeholder-image-url.com"; // TODO: Implement Django file upload
  }
}



