import 'dart:developer';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/models/request_model.dart';

class RequestDetailsController extends GetxController {
  // Access to the main RequestController for data operations
  late final RequestController _requestController;

  // Observable variables for additional UI state
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = "".obs;

  @override
  void onInit() {
    super.onInit();
    _requestController = Get.find<RequestController>();
  }

  /// Refresh request details by reloading from API
  /// ✅ FIXED: Now properly integrates with RequestController.loadRequestDetails()
  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = "";
      
      // Get current request ID from RequestController
      final currentRequest = _requestController.currentRequestDetails.value;
      if (currentRequest != null) {
        log('🔄 RequestDetailsController: Refreshing data for request ${currentRequest.requestId}');
        
        // Use RequestController's loadRequestDetails for consistency
        await _requestController.loadRequestDetails(currentRequest.requestId);
        
        log('✅ RequestDetailsController: Successfully refreshed request details');
      } else {
        log('⚠️  RequestDetailsController: No current request to refresh');
        throw Exception('No current request available to refresh');
      }
    } catch (e) {
      log('💥 RequestDetailsController: Error refreshing data - $e');
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current request from RequestController
  /// ✅ NEW: Provides reactive access to current request
  RequestModel? get currentRequest => _requestController.currentRequestDetails.value;

  /// Check if data is currently loading
  /// ✅ NEW: Combines loading states from both controllers
  bool get isDataLoading => _requestController.isLoadingRequestDetails.value || isLoading.value;

  /// Format date time to string
  String formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  /// Clear any error state
  void clearError() {
    hasError.value = false;
    errorMessage.value = "";
  }

  @override
  void onClose() {
    // Clean up resources if needed
    super.onClose();
  }
}



