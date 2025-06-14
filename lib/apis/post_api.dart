import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:moveo/constants/appwrite_constants.dart';
import 'package:moveo/core/core.dart';
import 'package:moveo/core/providers.dart';
//import 'package:moveo/models/post_model_desired.dart';
import 'package:moveo/models/post_model.dart';

final postAPIProvider = Provider((ref) {
  return PostAPI(db: ref.watch(appwriteDatabaseProvider), realtime: ref.watch(appwriteRealtimeProvider)
  );
});

abstract class IPostAPI {
  FutureEither<Document> sharePost(Post post);
  FutureEither<Document> sharePostData(Map<String, dynamic> data);
  Future<List<Document>> getPosts();
  Future<List<Document>> getPostsByUserId(String userId);
  Stream<RealtimeMessage> getLatestPosts();
  Stream<RealtimeMessage> getLatestPostsByUserId(String userId);
  Future<void> toggleLike(String postId, String userId);
  Future<bool> hasUserLikedPost(String postId, String userId);
}

class PostAPI implements IPostAPI {
  final Databases _db;
  final Realtime _realtime;
  PostAPI({required Databases db, required Realtime realtime}) : _db = db, _realtime = realtime;
  @override
  FutureEither<Document> sharePost(Post post) async {
    try {
        final document = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.postCollectionId,
        documentId: ID.unique(),
        data: post.toMap(),
      );
      return right(document);
    } on AppwriteException catch (e,st) {
      return left(Failure(e.message??'Some unexpected bullshit occured', st)
      );
    } catch (e, st) {
      return left(Failure(e.toString(), st)
      );
    }  
  }

  @override
  FutureEither<Document> sharePostData(Map<String, dynamic> data) async {
    try {
      final document = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.postCollectionId,
        documentId: ID.unique(),
        data: data,
      );
      return right(document);
    } on AppwriteException catch (e, st) {
      return left(Failure(e.message ?? 'Error creating post', st));
    } catch (e, st) {
      return left(Failure(e.toString(), st));
    }
  }

  @override
  Future<List<Document>> getPosts() async {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.postCollectionId,
        queries: [
          Query.orderDesc('createdAt'),
        ],
      );
      return documents.documents;
  }

  @override
  Future<List<Document>> getPostsByUserId(String userId) async {
    final documents = await _db.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.postCollectionId,
      queries: [
        Query.equal('uid', userId),
      ],
    );
    return documents.documents;
  }
  
  @override
  Stream<RealtimeMessage> getLatestPosts() {
    return _realtime.subscribe(['databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.postCollectionId}.documents']).stream;
  }

  @override
  Stream<RealtimeMessage> getLatestPostsByUserId(String userId) {
     return _realtime.subscribe(['databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.postCollectionId}.documents']).stream.where((event) => event.events.contains('databases.*.collections.*.documents.*.create') && (event.payload)['uid'] == userId);
  }

  @override
  Future<void> toggleLike(String postId, String userId) async {
    // Check if like exists
    final existingLikes = await _db.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.likesCollectionId,
      queries: [
        Query.equal('postId', postId),
        Query.equal('uid', userId),
      ],
    );

    if (existingLikes.documents.isEmpty) {
      // Add like
      await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.likesCollectionId,
        documentId: ID.unique(),
        data: {
          'postId': postId,
          'uid': userId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Get current likes count
      final post = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.postCollectionId,
        documentId: postId,
      );
      
      // Increment likes count
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.postCollectionId,
        documentId: postId,
        data: {
          'likesCount': (post.data['likesCount'] ?? 0) + 1,
        },
      );
    } else {
      // Remove like
      await _db.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.likesCollectionId,
        documentId: existingLikes.documents.first.$id,
      );
      
      // Get current likes count
      final post = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.postCollectionId,
        documentId: postId,
      );
      
      // Decrement likes count
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.postCollectionId,
        documentId: postId,
        data: {
          'likesCount': (post.data['likesCount'] ?? 0) - 1,
        },
      );
    }
  }

  @override
  Future<bool> hasUserLikedPost(String postId, String userId) async {
    final response = await _db.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.likesCollectionId,
      queries: [
        Query.equal('postId', postId),
        Query.equal('uid', userId),
      ],
    );
    return response.documents.isNotEmpty;
  }
}