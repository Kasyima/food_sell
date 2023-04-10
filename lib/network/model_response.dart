/*
* It's a good practice to create a generic response class that will hold either
  a successful response or an error.
* The classes make it easier to deal with the responses that the server returns 
*/

abstract class Result<T> {}

class Success<T> extends Result<T> {
  final T value;

  Success(this.value);
}

class Error<T> extends Result<T> {
  final Exception exception;

  Error(this.exception);
}
