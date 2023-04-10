import 'dart:math';
import 'dart:convert';
import '../../network/recipe_model.dart';
import '../../network/recipe_service.dart';
import '../recipe_card.dart';
import 'recipe_details.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_dropdown.dart';
import '../colors.dart';
import 'package:chopper/chopper.dart';
import '../../network/model_response.dart';
import 'dart:collection';

class RecipeList extends StatefulWidget {
  const RecipeList({Key? key}) : super(key: key);

  @override
  State createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  //! Add key
  static const String prefSearchKey = 'previousSearches';
  // All preferences need to use a unique key or they'll be overwritten
  late TextEditingController searchTextController;
  final ScrollController _scrollController = ScrollController();
  List<APIHits> currentSearchList = [];
  int currentCount = 0;
  int currentStartPosition = 0;
  int currentEndPosition = 20;
  int pageCount = 20;
  bool hasMore = false;
  bool loading = false;
  bool inErrorState = false;
  //! Add searches array
  // This clears the way for you to save the user's previous searches and keep
  // track of the current search.

  List<String> previousSearches = <String>[];
  // Add _currentRecipes1

  @override
  void initState() {
    super.initState();
    // Call loadRecipes()

    //! Call getPreviousSearches
    getPreviousSearches();
    searchTextController = TextEditingController(text: '');
    _scrollController.addListener(() {
      final triggerFetchMoreSize =
          0.7 * _scrollController.position.maxScrollExtent;

      if (_scrollController.position.pixels > triggerFetchMoreSize) {
        if (hasMore &&
            currentEndPosition < currentCount &&
            !loading &&
            !inErrorState) {
          setState(() {
            loading = true;
            currentStartPosition = currentEndPosition;
            currentEndPosition =
                min(currentStartPosition + pageCount, currentCount);
          });
        }
      }
    });
    // Add loadRecipes
  }

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  //! Saving previous searches
  // SharedPreferences.getInstance() returns  Future<SharedPreferences>,
  // which you use to retrieve an instance of the SharedPreferences class.
  void savePreviousSearches() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(prefSearchKey, previousSearches);
  }

  //! getPreviousSearches
  void getPreviousSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(prefSearchKey)) {
      final searches = prefs.getStringList(prefSearchKey);

      if (searches != null) {
        previousSearches = searches;
      } else {
        previousSearches = <String>[];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildSearchCard(),
            _buildRecipeLoader(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            // Replace
            IconButton(
              onPressed: () {
                startSearch(
                  searchTextController.text,
                );
                final currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus) {
                  currentFocus.unfocus();
                }
              },
              icon: const Icon(
                Icons.search,
              ),
            ),
            const SizedBox(
              width: 6.0,
            ),
            // *** Start Replace
            Expanded(
                child: TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search',
              ),
              autofocus: false,
              textInputAction: TextInputAction.done, // Closes the keyboard when
              // user presses the Done button.
              onSubmitted: (value) {
                startSearch(
                  searchTextController.text,
                );
              },
              controller: searchTextController,
            )),
            // Build a list of custom dropdown menus to display previoussearches
            PopupMenuButton(
              icon: const Icon(
                Icons.arrow_drop_down,
                color: lightGrey,
              ),
              onSelected: (String value) {
                searchTextController.text = value;
                startSearch(
                  searchTextController.text,
                );
              },
              itemBuilder: (context) {
                return previousSearches
                    .map<CustomDropdownMenuItem<String>>((String value) {
                  return CustomDropdownMenuItem<String>(
                    value: value,
                    text: value,
                    callback: () {
                      setState(() {
                        previousSearches.remove(value);
                        savePreviousSearches();
                        Navigator.pop(context);
                      });
                    },
                  );
                }).toList();
              },
            ),
          ],
        ),
      ),
    );
  }

  //! Adding the search functionality
  void startSearch(String value) {
    setState(() {
      currentSearchList.clear();
      currentCount = 0;
      currentEndPosition = pageCount;
      currentStartPosition = 0;
      hasMore = true;
      value = value.trim();

      if (!previousSearches.contains(value)) {
        previousSearches.add(value);
        savePreviousSearches();
      }
    });
  }

  // TODO: Replace method

  // _buildRecipeCard
  Widget _buildRecipeCard(
      BuildContext topLevelContext, List<APIHits> hits, int index) {
    final recipe = hits[index].recipe;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          topLevelContext,
          MaterialPageRoute(builder: (context) {
            return const RecipeDetails();
          }),
        );
      },
      child: recipeCard(recipe),
    );
  }

  Widget _buildRecipeList(BuildContext recipeListContext, List<APIHits> hits) {
    final size = MediaQuery.of(context).size;
    const itemHeight = 310;
    final itemWidth = size.width / 2;
    return Flexible(
      child: GridView.builder(
        controller: _scrollController,
        itemCount: hits.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: (itemWidth / itemHeight),
        ),
        itemBuilder: (context, index) {
          return _buildRecipeCard(
            recipeListContext,
            hits,
            index,
          );
        },
      ),
    );
  }

  Widget _buildRecipeLoader(BuildContext context) {
    if (searchTextController.text.length < 3) {
      return Container();
    }
    return FutureBuilder<Response<Result<APIRecipeQuery>>>(
      // * The future creates a new instance of RecipeService and calls its
      // * method, queryRecipes, to perform the query.
      future: RecipeService.create().queryRecipes(
        searchTextController.text.trim(),
        currentStartPosition,
        currentEndPosition,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
                textScaleFactor: 1.3,
              ),
            );
          }
          loading = false;

          //!
          if (false == snapshot.data?.isSuccessful) {
            var errorMessage = 'Problems getting data';
            // * Check for an error map and extract the message to show
            if (snapshot.data?.error != null &&
                snapshot.data?.error is LinkedHashMap) {
              final map = snapshot.data?.error as LinkedHashMap;
              errorMessage = map['message'];
            }
            return Center(
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18.0,
                ),
              ),
            );
          }
          final result = snapshot.data?.body;
          if (result == null || result is Error) {
            // Hit an error
            inErrorState = true;
            return _buildRecipeList(
              context,
              currentSearchList,
            );
          }
          final query = (result as Success).value;

          //!

          inErrorState = false;
          if (query != null) {
            currentCount = query.count;
            hasMore = query.more;
            currentSearchList.addAll(
              query.hits,
            );
            if (query.to < currentEndPosition) {
              currentEndPosition = query.to;
            }
          }
          return _buildRecipeList(
            context,
            currentSearchList,
          );
        }
        // Handle not done connection
        else {
          if (currentCount == 0) {
            // Show a loading indicator while waiting for the recipes.
            return const Center(
              heightFactor: 10,
              child: CircularProgressIndicator(),
            );
          } else {
            return _buildRecipeList(
              context,
              currentSearchList,
            );
          }
        }
      },
    );
  }
}
