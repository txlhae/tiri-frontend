import 'dart:developer';
import 'package:get/get.dart';
import 'package:kind_clock/models/request_model.dart';
import 'package:kind_clock/services/firebase_storage.dart';

class RequestDetailsController extends GetxController {
  final FirebaseStorageService storageService =
      Get.find<FirebaseStorageService>();

  // Observable variables
  final isLoading = true.obs;
  final requestModel = Rx<RequestModel?>(null);
  final posterUsername = "".obs;
  final posterUserId = "".obs;
  final referrerUsername = "".obs;

  // Load request details
  Future<void> loadRequestDetails(RequestModel initialRequest) async {
    isLoading.value = true;

    try {
      // Load the latest request data
      await _loadRequest(initialRequest.requestId);

      // Load user information
      await _loadUserInfo(initialRequest.userId);

      isLoading.value = false;
    } catch (e) {
      log('Error loading request details: $e');
      isLoading.value = false;
    }
  }

  // Load request data
  Future<void> _loadRequest(String requestId) async {
    try {
      final result = await storageService.getRequest(requestId);
      if (result != null) {
        requestModel.value = result;
      }
    } catch (e) {
      log('Error fetching request: $e');
    }
  }

  // Load user information
  Future<void> _loadUserInfo(String userId) async {
    try {
      final userModel = await storageService.getUser(userId);
      if (userModel != null) {
        posterUsername.value = userModel.username;
        posterUserId.value = userModel.userId;

        // Load referrer information if available
        if (userModel.referralUserId != null &&
            userModel.referralUserId!.isNotEmpty) {
          final referrerModel =
              await storageService.getUser(userModel.referralUserId!);
          if (referrerModel != null) {
            referrerUsername.value = referrerModel.username;
          }
        }
      }
    } catch (e) {
      log('Error fetching user info: $e');
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    if (requestModel.value != null) {
      await loadRequestDetails(requestModel.value!);
    }
  }

  // Format date time to string
  String formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  void onClose() {
    // Clean up resources if needed
    super.onClose();
  }
}
