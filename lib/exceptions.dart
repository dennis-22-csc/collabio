// Custom exception for fetch projects error
class FetchProjectsException implements Exception {
  final String message;

  FetchProjectsException(this.message);
}

// Custom exception for fetch messages error
class FetchMessagesException implements Exception {
  final String message;

  FetchMessagesException(this.message);
}

// Custom exception for delete messages error
class DeleteMessagesException implements Exception {
  final String message;

  DeleteMessagesException(this.message);
}

// Custom exception for socket error
class SocketException implements Exception {
  final String message;

  SocketException(this.message);
}

// Custom exception for network data transfer
class SendDataException implements Exception {
  final String message;

  SendDataException(this.message);
}

class LocalInsertException implements Exception {
  final String message;

  LocalInsertException(this.message);
}

class FetchUserException implements Exception {
  final String message;

  FetchUserException(this.message);
}