import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:kind_clock/models/feedback_model.dart';
import 'package:kind_clock/models/notification_model.dart';
import 'package:kind_clock/models/request_model.dart';
import 'dart:io';

import 'package:kind_clock/models/user_model.dart';

class FirebaseStorageService extends GetxController {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _collection = FirebaseFirestore.instance;

  Future<String> uploadFile(File file, String path) async {
    try {
      TaskSnapshot snapshot = await _storage.ref().child(path).putFile(file);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      throw Exception('Error deleting file: $e');
    }
  }

  Future<String> getFileUrl(String path) async {
    try {
      String downloadUrl = await _storage.ref().child(path).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error getting file URL: $e');
    }
  }

  Future<void> createUserCollection(UserModel user) async {
    try {
      await _collection.collection('users').doc(user.userId).set(user.toJson());
    } catch (e) {
      throw Exception('Error creating user collection: $e');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _collection
          .collection('users')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        log('User ID: ${userDoc.id}');

        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;
        log("The user in getUser: ${userData.toString()}");

        if (userData != null) {
          UserModel user = UserModel.fromJson(userData);

          // Save the user to local storage
          log("User is fetched: ${user.userId}");
          return user;
        } else {
          log('User data is null');
          return null;
        }
      } else {
        log('No user found with the provided User ID');
        return null;
      }
    } catch (e) {
      log('Error fetching user: $e');
      return null;
    }
  }

  Future<void> updateUser(Map<String, dynamic> user, String userId) async {
    try {
      await _collection.collection('users').doc(userId).update(user);
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _collection.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  Future<void> saveRequestToStorage(RequestModel request) async {
    try {
      await _collection
          .collection('requests')
          .doc(request.requestId)
          .set(request.toJson());
    } catch (e) {
      throw Exception('Error saving request to storage: $e');
    }
  }

  Future<void> saveNotification(NotificationModel notification) async {
    try {
      log("Saving notification to Firestore: ${notification.toJson()}");

      await _collection
          .collection('notifications')
          .doc(notification.notificationId)
          .set(notification.toJson());
    } catch (e) {
      throw Exception('Error saving notification to storage: $e');
    }
  }

  Future<List<RequestModel>> fetchRequests() async {
    try {
      QuerySnapshot querySnapshot =
          await _collection.collection('requests').orderBy('timestamp', descending: true).get();

      List<RequestModel> requests = querySnapshot.docs
          .map((doc) =>
              RequestModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      log('$requests');
      return requests;
    } catch (e) {
      throw Exception('Error fetching requests: $e');
    }
  }

  // Get single request
  Future<RequestModel?> getRequest(String requestId) async {
    try {
      QuerySnapshot querySnapshot = await _collection
          .collection('requests')
          .where('requestId', isEqualTo: requestId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot requestDoc = querySnapshot.docs.first;
        log('Request ID: ${requestDoc.id}');

        Map<String, dynamic>? requestData =
            requestDoc.data() as Map<String, dynamic>?;
        log("The request in getRequest: ${requestData.toString()}");

        if (requestData != null) {
          RequestModel request = RequestModel.fromJson(requestData);

          // Save the user to local storage
          log("Request is fetched: ${request.requestId}");
          return request;
        } else {
          log('Request data is null');
          return null;
        }
      } else {
        log('No request found with the provided request ID');
        return null;
      }
    } catch (e) {
      log('Error fetching request: $e');
      return null;
    }
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      QuerySnapshot querySnapshot =
          await _collection.collection('notifications').orderBy('timestamp', descending: true).get();

      List<NotificationModel> notifications = querySnapshot.docs
          .map((doc) =>
              NotificationModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return notifications;
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<void> updateRequest(
      String requestId, Map<String, dynamic> updatedFields) async {
    try {
      log(updatedFields.toString());
      await _collection
          .collection("requests")
          .doc(requestId)
          .update(updatedFields);
    } catch (e) {
      log('Error updating request: $e');
      throw Exception('Error updating request: $e');
    }
  }

  Future<void> updateNotification(NotificationModel notification) async {
    log("First firebase: ${notification.toJson().toString()}");
    var notify = NotificationModel(
        notificationId: notification.notificationId,
        status: RequestStatus.accepted.toString().split('.').last,
        body: notification.body,
        isUserWaiting: false,
        userId: notification.userId,
        timestamp: DateTime.now());
    log("Changed firebase: ${notify.toJson().toString()}");
    try {
      await _collection
          .collection("notifications")
          .doc(notification.notificationId)
          .update(notify.toJson());
    } catch (e) {
      log('Error updating notification: $e');
      throw Exception('Error updating notification: $e');
    }
  }

  Future<List<FeedbackModel>> getFeedbackForUser(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .get(); // Get all requests, since feedback is nested inside

      List<FeedbackModel> feedbackList = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        if (data['feedbackList'] != null) {
          final feedbackRawList = data['feedbackList'] as List<dynamic>;

          for (var feedbackJson in feedbackRawList) {
            try {
              final feedback = FeedbackModel.fromJson(
                Map<String, dynamic>.from(feedbackJson),
              );

              // Check if this feedback was received by the target user
              if (feedback.feedbackId == userId) {
                feedbackList.add(feedback);
              }
            } catch (e) {
              log("Failed to parse feedback: $e");
            }
          }
        }
      }

      feedbackList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return feedbackList;
    } catch (e) {
      log("Error fetching feedback: $e");
      rethrow;
    }
  }

  Future<List<RequestModel>> searchRequestsByLocation(String location) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('requests')
        .where('location', isEqualTo: location.toLowerCase())
        .get();

    return querySnapshot.docs
        .map((doc) => RequestModel.fromJson(doc.data()))
        .toList();
  }

}
