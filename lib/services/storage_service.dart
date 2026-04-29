// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/foundation.dart';
// import 'dart:typed_data';
//
// class StorageService {
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//
//   Future<String> uploadFile({
//     File? file,
//     Uint8List? webFile,
//     required String path,
// }) async {
//     final ref = _storage.ref().child(path);
//
//     UploadTask uploadTask;
//
//     if (kIsWeb) {
//       if (webFile == null) throw Exception("Web file is null");
//       uploadTask = ref.putData(webFile);
//     } else {
//       if (file == null) throw Exception("Mobile file is null");
//       uploadTask = ref.putFile(file);
//     }
//     final snapshot = await uploadTask;
//     return await snapshot.ref.getDownloadURL();
//
//   }
//
//
// }