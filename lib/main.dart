import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const appTitle = 'Flutter Forms';

    return MaterialApp(
        title: appTitle,
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.purple,
        ),
        home: const FormWidget());
  }
}

class FormWidget extends StatefulWidget {
  const FormWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FormWidgetState();
  }
}

class _FormWidgetState extends State<FormWidget> {
  final String apiKey =
      const String.fromEnvironment("TMDB_API_KEY", defaultValue: "");
  final String _appTitle = 'Form title';

  DateTime? date;

  DateTime selectedDate = DateTime.now();
  final TextEditingController _date = TextEditingController();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  List<Genre>? genres;
  List<String>? movies;

  Genre? selectedGenre;
  String? selectedMovie;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var gestureDetector = GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: _date,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(
            hintText: 'Date of birth',
            prefixIcon: Icon(Icons.dialpad, color: Colors.purple),
          ),
        ),
      ),
    );

    var genreDd = FutureBuilder<DropdownButton<Genre>>(
        future: _generateGenresDropdownButton(),
        builder: (BuildContext context,
            AsyncSnapshot<DropdownButton<Genre>> snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(1),
              child: snapshot.data,
            );
          } else if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(1),
              child: Text('Une erreur est survenue'),
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(1),
              child: Text('En attente du résultat'),
            );
          }
        });

    var moviesDropdown = DropdownButton<String>(
      value: selectedMovie,
      items: movies?.map<DropdownMenuItem<String>>((movie) {
        return DropdownMenuItem<String>(value: movie, child: Text(movie));
      }).toList(),
      onChanged: (String? element) {
        setState(() {
          selectedMovie = element;
        });
      },
    );

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Title(
              title: 'Form title',
              color: Colors.purple,
              child: Text(_appTitle),
            ),
            const TextField(),
            gestureDetector,
            genreDd,
            moviesDropdown,
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1998),
        lastDate: DateTime(2100));

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = picked;
      initializeDateFormatting();
      Intl.defaultLocale = 'fr';
      final formatter = DateFormat('dd/MM/yyyy');
      _date.value = TextEditingValue(text: formatter.format(picked));
    });
  }

  Future<void> _loadGenresAsync() async {
    http.Response response = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/genre/movie/list?api_key=$apiKey'));

    if (response.statusCode != 200) {
      return;
    }

    genres = <Genre>[];

    var result = jsonDecode(response.body);

    for (var element in result['genres']) {
      genres?.add(Genre.fromJson(element));
    }
  }

  Future<List<String>?> _loadMoviesFromGenreAsync(int? genreId) async {
    if (genreId == null) return null;

    http.Response response = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&include_adult=false&include_video=false&page=1&with_genres=$genreId'));

    if (response.statusCode != 200) return null;

    Discover discover = Discover.fromJson(jsonDecode(response.body));

    return discover.results.map((e) {
      return e.title;
    }).toList();
  }

  Future<DropdownButton<Genre>> _generateGenresDropdownButton() async {
    await _loadGenresAsync();

    selectedGenre ??= genres?.first;

    movies = await _loadMoviesFromGenreAsync(selectedGenre?.id);

    selectedMovie ??= movies?.first;

    return DropdownButton<Genre>(
      value: selectedGenre,
      items: genres?.map<DropdownMenuItem<Genre>>((genre) {
        return DropdownMenuItem<Genre>(
          value: genre,
          child: Text(genre.name),
        );
      }).toList(),
      onChanged: (Genre? newValue) async {
        movies = await _loadMoviesFromGenreAsync(newValue?.id);

        setState(() {
          selectedGenre = newValue;

          if (movies != null) {
            selectedMovie = movies?.first;
          }
        });
      },
    );
  }
}

class Genre {
  const Genre({required this.id, required this.name});

  final int id;
  final String name;

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['id'], name: json['name']);
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(other) {
    return other is Genre && other.id == id && other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode + name.hashCode;
  }
}

class Discover {
  const Discover({required this.page, required this.results});

  final int page;
  final List<Movie> results;

  factory Discover.fromJson(Map<String, dynamic> json) {
    List<Movie> movies = <Movie>[];
    int p = json['page'];

    for (var element in json['results']) {
      movies.add(Movie.fromJson(element));
    }

    return Discover(page: p, results: movies);
  }
}

class Movie {
  const Movie({required this.id, required this.title, required this.genreIds});

  final int id;
  final String title;
  final List<int> genreIds;

  factory Movie.fromJson(Map<String, dynamic> json) {
    List<int> g = <int>[];

    for (var element in json['genre_ids']) {
      g.add(element);
    }

    return Movie(id: json['id'], title: json['original_title'], genreIds: g);
  }

  @override
  String toString() {
    return title;
  }

  @override
  bool operator ==(other) {
    return other is Movie && other.id == id && other.title == title;
  }

  @override
  int get hashCode {
    return id.hashCode + title.hashCode + genreIds.hashCode;
  }
}
