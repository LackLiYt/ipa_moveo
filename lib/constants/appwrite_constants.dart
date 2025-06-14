class AppwriteConstants {
  static const String databaseId = '6717aac9002fc50506d7'; 
  static const String projectId =  '6717a8f8000e772c5899';
  static const String endPoint = 'https://cloud.appwrite.io/v1';
  
  static const String usersCollectionId = '6793ffd70014bf79247d';
  static const String postCollectionId = '679f890c0025ddf0c58b';
  static const String postTestCollectionId = '67faa053003587684a33';
  static const String leaderboardCollectionId = '681b5a350024b878fecd';

  // Chat Collections
  static const String chatsCollectionId = '6830bb6c002c797591fa';
  static const String messagesCollectionId = 'messages';

  // Friends Collection
  static const String friendsCollectionId = '6830bb580031098c87e2';

  static const String commentsCollectionId = '682adaf50018719725d6';
  static const String likesCollectionId = '682cabc00000a92b509f';  

  static const String imagesBucketId = '6796730c003d58e79e62';
  static String imageUrl(String imageId) => '$endPoint/storage/buckets/$imagesBucketId/files/$imageId/view?project=$projectId';
}