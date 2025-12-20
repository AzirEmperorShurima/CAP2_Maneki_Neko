class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiTimeoutException extends ApiException {
  ApiTimeoutException([super.message = 'Connection timed out. Please try again.']);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Unauthorized. Please login again.']);
}

class ForbiddenException extends ApiException {
  ForbiddenException([super.message = 'Access denied.']);
}

class NotFoundException extends ApiException {
  NotFoundException([super.message = 'Resource not found.']);
}

class BadRequestException extends ApiException {
  BadRequestException([super.message = 'Bad request']);
}

class ServerException extends ApiException {
  ServerException([super.message = 'Server error. Please try again later.']);
}

class NoInternetConnectionException extends ApiException {
  NoInternetConnectionException([super.message = 'No internet connection.']);
}


