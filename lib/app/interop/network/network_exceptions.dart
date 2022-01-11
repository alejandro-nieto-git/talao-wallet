
import 'dart:io';
import 'dart:js';
import 'package:dio/dio.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:talao/app/shared/error_handler/error_hadler.dart';

part 'network_exceptions.freezed.dart';

@freezed
abstract class NetworkExceptions
    with ErrorHandler
    implements _$NetworkExceptions {
  const factory NetworkExceptions.badRequest() = BadRequest;
  const factory NetworkExceptions.conflict() = Conflict;
  const factory NetworkExceptions.created() = Created;
  const factory NetworkExceptions.defaultError(String error) = DefaultError;
  const factory NetworkExceptions.formatException() = NetworkFormatException;
  const factory NetworkExceptions.gatewayTimeout() = GatewayTimeout;
  const factory NetworkExceptions.internalServerError() = InternalServerError;
  const factory NetworkExceptions.methodNotAllowed() = MethodNotAllowed;
  const factory NetworkExceptions.noInternetConnection() = NoInternetConnection;
  const factory NetworkExceptions.notAcceptable() = NotAcceptable;
  const factory NetworkExceptions.notFound(String reason) = NotFound;
  const factory NetworkExceptions.notImplemented() = NotImplemented;
  const factory NetworkExceptions.ok() = Ok;
  const factory NetworkExceptions.requestCancelled() = RequestCancelled;
  const factory NetworkExceptions.requestTimeout() = RequestTimeout;
  const factory NetworkExceptions.sendTimeout() = SendTimeout;
  const factory NetworkExceptions.serviceUnavailable() = ServiceUnavailable;
  const factory NetworkExceptions.tooManyRequests() = TooManyRequests;
  const factory NetworkExceptions.unableToProcess() = UnableToProcess;
  const factory NetworkExceptions.unauthenticated() = Unauthenticated;
  const factory NetworkExceptions.unauthorizedRequest() = UnauthorizedRequest;
  const factory NetworkExceptions.unexpectedError() = UnexpectedError;
  static NetworkExceptions handleResponse(int? statusCode) {
    
    switch (statusCode) {
      case 200:
        return NetworkExceptions.ok();
      case 201:
        return NetworkExceptions.created();
      case 400:
        return NetworkExceptions.badRequest();

      case 401:
        return NetworkExceptions.unauthenticated();
      case 403:
        return NetworkExceptions.unauthorizedRequest();
      case 404:
        return NetworkExceptions.notFound('Not found');
      case 408:
        return NetworkExceptions.requestTimeout();
      case 409:
        return NetworkExceptions.conflict();
      case 429:
        return NetworkExceptions.tooManyRequests();
      case 500:
        return NetworkExceptions.internalServerError();
      case 501:
        return NetworkExceptions.notImplemented();
      case 503:
        return NetworkExceptions.serviceUnavailable();
      case 504:
        return NetworkExceptions.gatewayTimeout();
      default:
        var responseCode = statusCode;
        return NetworkExceptions.defaultError(
          'Received invalid status code: $responseCode',
        );
    }
  }

  static NetworkExceptions getDioException(error) {
    if (error is Exception) {
      try {
        NetworkExceptions networkExceptions;
        if (error is DioError) {
          switch (error.type) {
            case DioErrorType.cancel:
              networkExceptions = NetworkExceptions.requestCancelled();
              break;
            case DioErrorType.connectTimeout:
              networkExceptions = NetworkExceptions.requestTimeout();
              break;
            case DioErrorType.other:
              networkExceptions = NetworkExceptions.noInternetConnection();
              break;
            case DioErrorType.receiveTimeout:
              networkExceptions = NetworkExceptions.sendTimeout();
              break;
            case DioErrorType.response:
              networkExceptions =
                  NetworkExceptions.handleResponse(error.response?.statusCode);
              break;
            case DioErrorType.sendTimeout:
              networkExceptions = NetworkExceptions.sendTimeout();
              break;
          }
        } else if (error is SocketException) {
          networkExceptions = NetworkExceptions.noInternetConnection();
        } else {
          networkExceptions = NetworkExceptions.unexpectedError();
        }
        return networkExceptions;
      } on FormatException catch (_) {
        return NetworkExceptions.formatException();
      } catch (_) {
        return NetworkExceptions.unexpectedError();
      }
    } else {
      if (error.toString().contains('is not a subtype of')) {
        return NetworkExceptions.unableToProcess();
      } else {
        return NetworkExceptions.unexpectedError();
      }
    }
  }

  static String getErrorMessage(
      BuildContext context, NetworkExceptions networkExceptions) {
    final localizations = AppLocalizations.of(context)!;

    var errorMessage = '';
    networkExceptions.when(
        notImplemented: () {
          errorMessage = 'Not Implemented';
        },
        requestCancelled: () {
          errorMessage = 'Request Cancelled';
        },
        internalServerError: () {
          errorMessage = 'Internal Server Error';
        },
        notFound: (String reason) {
          errorMessage = reason;
        },
        serviceUnavailable: () {
          errorMessage = 'Service unavailable';
        },
        methodNotAllowed: () {
          errorMessage = 'Method Allowed';
        },
        badRequest: () {
          errorMessage = 'Bad request';
        },
        unauthorizedRequest: () {
          errorMessage = 'Unauthorized request';
        },
        unexpectedError: () {
          errorMessage = 'Unexpected error occurred';
        },
        requestTimeout: () {
          errorMessage = 'Connection request timeout';
        },
        noInternetConnection: () {
          errorMessage = 'No internet connection';
        },
        conflict: () {
          errorMessage = 'Error due to a conflict';
        },
        sendTimeout: () {
          errorMessage = 'Send timeout in connection with API server';
        },
        unableToProcess: () {
          errorMessage = 'Unable to process the data';
        },
        defaultError: (String error) {
          errorMessage = error;
        },
        formatException: () {
          errorMessage = 'Unexpected error occurred';
        },
        notAcceptable: () {
          errorMessage = 'Not acceptable';
        },
        created: () {},
        gatewayTimeout: () {},
        ok: () {},
        tooManyRequests: () {},
        unauthenticated: () {});
    return errorMessage;
  }

  static void displayError(
      BuildContext context, ErrorHandler error, Color errorColor) {
    if (error is NetworkExceptions) {
      var errorMessage = getErrorMessage(context, error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: errorColor,
        content: Text(errorMessage),
      ));
    }
  }
}
