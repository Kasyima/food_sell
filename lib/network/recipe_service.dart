import 'dart:developer';
import 'package:chopper/chopper.dart';

import 'model_converter.dart';
import 'model_response.dart';
import 'recipe_model.dart';

part 'recipe_service.chopper.dart';

const String apiKey = 'b37ada2fa78fb7df0192d266b9df7de9';
const String apiId = 'c4dbbc12';
const String apiUrl = 'https://api.edamam.com';

//! Setting up the Chopper client
@ChopperApi()
abstract class RecipeService extends ChopperService {
  @Get(path: 'search')
  Future<Response<Result<APIRecipeQuery>>> queryRecipes(
    @Query('q') String query,
    @Query('from') int from,
    @Query('to') int to,
  );
  // Add create()
  //! Wiring up interceptors & converters

  static RecipeService create() {
    final client = ChopperClient(
      baseUrl: Uri.parse(apiUrl),
      interceptors: [_addQuery, HttpLoggingInterceptor()],
      /*
      * Pass in 2 interceptors.
      * _addQuery() - adds ur key and ID to the query.
      * HttpLoggingInterceptor - logs all calls -- handy while you're developing
      * to see traffic between the app and the server.
      */
      converter: ModelConverter(),
      errorConverter: const JsonConverter(), // decode any errors
      services: [
        _$RecipeService(),
      ],
    );
    return _$RecipeService(client);
  }
}

// Add _addQuery()
//! Automatically including your ID and key
/*
* Instead of adding the app_id and app_key fields manually to each query,
* you can use an interceptor to add them to each call.
 */
Request _addQuery(Request req) {
  final params = Map<String, dynamic>.from(req.parameters);
  // * Creates a Map, which contains key-value pairs from the existing Request
  // * parameters.

  params['app_id'] = apiId;
  params['app_key'] = apiKey;

  return req.copyWith(parameters: params);
}
