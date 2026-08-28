import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MovieDashboard());
}

class MovieDashboard extends StatelessWidget {
  const MovieDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5FA),
      ),
      home: const HomeScreen(),
    );
  }
}

// ================= MODEL =================

class Movie {
  String id;
  String title;
  String genre;
  int year;
  double rating;
  bool favorite;
  bool watched;

  Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.rating,
    this.favorite = false,
    this.watched = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'genre': genre,
    'year': year,
    'rating': rating,
    'favorite': favorite,
    'watched': watched,
  };

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      genre: json['genre'],
      year: json['year'],
      rating: (json['rating'] as num).toDouble(),
      favorite: json['favorite'] ?? false,
      watched: json['watched'] ?? false,
    );
  }
}

// ================= STORAGE =================

class MovieStorage {
  static const key = 'movie_dashboard_data';

  static Future<List<Movie>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);

    if (data == null) return [];

    return (jsonDecode(data) as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  static Future<void> save(List<Movie> movies) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      key,
      jsonEncode(movies.map((e) => e.toJson()).toList()),
    );
  }
}

// ================= HOME =================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selected = 0;
  List<Movie> movies = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMovies();
  }

  Future<void> loadMovies() async {
    movies = await MovieStorage.load();

    if (movies.isEmpty) {
      movies = [
        Movie(
          id: '1',
          title: 'Interstellar',
          genre: 'Sci-Fi',
          year: 2014,
          rating: 8.7,
          favorite: true,
          watched: true,
        ),
        Movie(
          id: '2',
          title: 'Inception',
          genre: 'Thriller',
          year: 2010,
          rating: 8.8,
          watched: true,
        ),
        Movie(
          id: '3',
          title: 'The Dark Knight',
          genre: 'Action',
          year: 2008,
          rating: 9.0,
          favorite: true,
          watched: true,
        ),
        Movie(
          id: '4',
          title: 'La La Land',
          genre: 'Romance',
          year: 2016,
          rating: 8.0,
        ),
      ];

      await MovieStorage.save(movies);
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> save() async {
    await MovieStorage.save(movies);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pages = [
      DashboardPage(movies: movies),
      MoviesPage(
        movies: movies,
        onChanged: save,
      ),
      FavoritesPage(
        movies: movies,
        onChanged: save,
      ),
      WatchlistPage(
        movies: movies,
        onChanged: save,
      ),
      ReportsPage(movies: movies),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selected == 0
              ? 'Movie Dashboard'
              : selected == 1
              ? 'All Movies'
              : selected == 2
              ? 'Favorites'
              : selected == 3
              ? 'Watchlist'
              : 'Reports',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: CircleAvatar(
              radius: 19,
              child: Icon(Icons.person),
            ),
          ),
        ],
      ),
      body: pages[selected],
      floatingActionButton: selected == 1
          ? FloatingActionButton.extended(
        onPressed: () => showMovieDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Movie'),
      )
          : null,
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: selected,
        onDestinationSelected: (index) {
          setState(() => selected = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Movies',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Future<void> showMovieDialog([Movie? movie]) async {
    final title = TextEditingController(
      text: movie?.title ?? '',
    );
    final genre = TextEditingController(
      text: movie?.genre ?? '',
    );
    final year = TextEditingController(
      text: movie?.year.toString() ?? '',
    );
    final rating = TextEditingController(
      text: movie?.rating.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            movie == null ? 'Add Movie' : 'Edit Movie',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Movie Title',
                  ),
                ),
                TextField(
                  controller: genre,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                  ),
                ),
                TextField(
                  controller: year,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Release Year',
                  ),
                ),
                TextField(
                  controller: rating,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Rating (0-10)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) return;

                final newRating =
                    double.tryParse(rating.text) ?? 0;

                if (movie == null) {
                  movies.add(
                    Movie(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      title: title.text.trim(),
                      genre: genre.text.trim(),
                      year: int.tryParse(year.text) ?? 2026,
                      rating:
                      newRating.clamp(0, 10).toDouble(),
                    ),
                  );
                } else {
                  movie.title = title.text.trim();
                  movie.genre = genre.text.trim();
                  movie.year =
                      int.tryParse(year.text) ?? movie.year;
                  movie.rating =
                      newRating.clamp(0, 10).toDouble();
                }

                await save();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

// ================= DASHBOARD =================

class DashboardPage extends StatelessWidget {
  final List<Movie> movies;

  const DashboardPage({
    super.key,
    required this.movies,
  });

  @override
  Widget build(BuildContext context) {
    final watched =
        movies.where((m) => m.watched).length;

    final favorites =
        movies.where((m) => m.favorite).length;

    final avg = movies.isEmpty
        ? 0.0
        : movies.fold<double>(
      0,
          (sum, movie) => sum + movie.rating,
    ) /
        movies.length;

    final genres = movies
        .map((m) => m.genre)
        .where((g) => g.isNotEmpty)
        .toSet()
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Welcome back! 🎬',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Manage your movie collection easily.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // RESPONSIVE STAT CARDS
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final columns = width < 360
                ? 1
                : width < 600
                ? 2
                : 4;

            final cardWidth =
                (width - ((columns - 1) * 12)) / columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Total Movies',
                    value: '${movies.length}',
                    icon: Icons.movie,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Watched',
                    value: '$watched',
                    icon: Icons.visibility,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Favorites',
                    value: '$favorites',
                    icon: Icons.favorite,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Avg Rating',
                    value: avg.toStringAsFixed(1),
                    icon: Icons.star,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 25),

        const Text(
          'Movie Statistics',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              ProgressRow(
                title: 'Watched',
                value: movies.isEmpty
                    ? 0
                    : watched / movies.length,
                count: watched,
              ),
              const SizedBox(height: 18),
              ProgressRow(
                title: 'Favorites',
                value: movies.isEmpty
                    ? 0
                    : favorites / movies.length,
                count: favorites,
              ),
              const SizedBox(height: 18),
              ProgressRow(
                title: 'Genres',
                value: genres > 10 ? 1 : genres / 10,
                count: genres,
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        const Text(
          'Top Rated Movies',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        ...([...movies]
          ..sort(
                (a, b) => b.rating.compareTo(a.rating),
          ))
            .take(3)
            .map(
              (movie) => MovieTile(movie: movie),
        ),
      ],
    );
  }
}

// ================= STAT CARD =================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 19,
            child: Icon(
              icon,
              size: 20,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= PROGRESS =================

class ProgressRow extends StatelessWidget {
  final String title;
  final double value;
  final int count;

  const ProgressRow({
    super.key,
    required this.title,
    required this.value,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}

// ================= MOVIES =================

class MoviesPage extends StatefulWidget {
  final List<Movie> movies;
  final VoidCallback onChanged;

  const MoviesPage({
    super.key,
    required this.movies,
    required this.onChanged,
  });

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  String search = '';
  String genre = 'All';

  @override
  Widget build(BuildContext context) {
    final genres = [
      'All',
      ...widget.movies.map((m) => m.genre).toSet(),
    ];

    final filtered = widget.movies.where((movie) {
      final matchSearch = movie.title
          .toLowerCase()
          .contains(search.toLowerCase());

      final matchGenre =
          genre == 'All' || movie.genre == genre;

      return matchSearch && matchGenre;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            15,
            16,
            8,
          ),
          child: TextField(
            onChanged: (value) {
              setState(() => search = value);
            },
            decoration: InputDecoration(
              hintText: 'Search movies...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            itemCount: genres.length,
            itemBuilder: (context, index) {
              final g = genres[index];

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    g,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: genre == g,
                  onSelected: (_) {
                    setState(() => genre = g);
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 4),

        Expanded(
          child: filtered.isEmpty
              ? const Center(
            child: Text('No movies found'),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              90,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final movie = filtered[index];

              return MovieCard(
                movie: movie,
                onFavorite: () async {
                  movie.favorite = !movie.favorite;
                  await MovieStorage.save(
                    widget.movies,
                  );
                  setState(() {});
                  widget.onChanged();
                },
                onWatched: () async {
                  movie.watched = !movie.watched;
                  await MovieStorage.save(
                    widget.movies,
                  );
                  setState(() {});
                  widget.onChanged();
                },
                onEdit: () {
                  editMovie(context, movie);
                },
                onDelete: () async {
                  widget.movies.removeWhere(
                        (m) => m.id == movie.id,
                  );

                  await MovieStorage.save(
                    widget.movies,
                  );

                  setState(() {});
                  widget.onChanged();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> editMovie(
      BuildContext context,
      Movie movie,
      ) async {
    final title =
    TextEditingController(text: movie.title);
    final genre =
    TextEditingController(text: movie.genre);
    final year =
    TextEditingController(text: movie.year.toString());
    final rating =
    TextEditingController(text: movie.rating.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Movie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Movie Title',
                  ),
                ),
                TextField(
                  controller: genre,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                  ),
                ),
                TextField(
                  controller: year,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                  ),
                ),
                TextField(
                  controller: rating,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Rating',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                movie.title = title.text.trim();
                movie.genre = genre.text.trim();
                movie.year =
                    int.tryParse(year.text) ?? movie.year;
                movie.rating =
                    (double.tryParse(rating.text) ??
                        movie.rating)
                        .clamp(0, 10)
                        .toDouble();

                await MovieStorage.save(widget.movies);
                widget.onChanged();
                setState(() {});

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

// ================= MOVIE CARD =================

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onFavorite;
  final VoidCallback onWatched;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MovieCard({
    super.key,
    required this.movie,
    required this.onFavorite,
    required this.onWatched,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
              ),
              child: const Icon(
                Icons.movie,
                size: 28,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.genre} • ${movie.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        movie.rating.toStringAsFixed(1),
                      ),
                      const SizedBox(width: 8),
                      if (movie.watched)
                        const Icon(
                          Icons.visibility,
                          size: 16,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 22,
              onSelected: (value) {
                if (value == 'favorite') {
                  onFavorite();
                } else if (value == 'watched') {
                  onWatched();
                } else if (value == 'edit') {
                  onEdit();
                } else {
                  onDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'favorite',
                  child: Text(
                    movie.favorite
                        ? 'Remove Favorite'
                        : 'Add Favorite',
                  ),
                ),
                PopupMenuItem(
                  value: 'watched',
                  child: Text(
                    movie.watched
                        ? 'Mark Unwatched'
                        : 'Mark Watched',
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================= MOVIE TILE =================

class MovieTile extends StatelessWidget {
  final Movie movie;

  const MovieTile({
    super.key,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        leading: CircleAvatar(
          child: Text(
            movie.title.isEmpty
                ? '?'
                : movie.title[0].toUpperCase(),
          ),
        ),
        title: Text(
          movie.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${movie.genre} • ${movie.year}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '⭐ ${movie.rating.toStringAsFixed(1)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ================= FAVORITES =================

class FavoritesPage extends StatelessWidget {
  final List<Movie> movies;
  final VoidCallback onChanged;

  const FavoritesPage({
    super.key,
    required this.movies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final favorites =
    movies.where((m) => m.favorite).toList();

    if (favorites.isEmpty) {
      return const Center(
        child: Text('No favorite movies yet'),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        90,
      ),
      children: favorites
          .map(
            (movie) => MovieCard(
          movie: movie,
          onFavorite: () async {
            movie.favorite = false;
            await MovieStorage.save(movies);
            onChanged();
          },
          onWatched: () async {
            movie.watched = !movie.watched;
            await MovieStorage.save(movies);
            onChanged();
          },
          onEdit: () {},
          onDelete: () async {
            movies.remove(movie);
            await MovieStorage.save(movies);
            onChanged();
          },
        ),
      )
          .toList(),
    );
  }
}

// ================= WATCHLIST =================

class WatchlistPage extends StatelessWidget {
  final List<Movie> movies;
  final VoidCallback onChanged;

  const WatchlistPage({
    super.key,
    required this.movies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final watchlist =
    movies.where((m) => !m.watched).toList();

    if (watchlist.isEmpty) {
      return const Center(
        child: Text('Your watchlist is empty'),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        90,
      ),
      children: watchlist
          .map(
            (movie) => MovieCard(
          movie: movie,
          onFavorite: () async {
            movie.favorite = !movie.favorite;
            await MovieStorage.save(movies);
            onChanged();
          },
          onWatched: () async {
            movie.watched = true;
            await MovieStorage.save(movies);
            onChanged();
          },
          onEdit: () {},
          onDelete: () async {
            movies.remove(movie);
            await MovieStorage.save(movies);
            onChanged();
          },
        ),
      )
          .toList(),
    );
  }
}

// ================= REPORTS =================

class ReportsPage extends StatelessWidget {
  final List<Movie> movies;

  const ReportsPage({
    super.key,
    required this.movies,
  });

  @override
  Widget build(BuildContext context) {
    final watched =
        movies.where((m) => m.watched).length;

    final unwatched = movies.length - watched;

    final favorites =
        movies.where((m) => m.favorite).length;

    final avg = movies.isEmpty
        ? 0.0
        : movies.fold<double>(
      0,
          (sum, movie) => sum + movie.rating,
    ) /
        movies.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        90,
      ),
      children: [
        const Text(
          'Movie Reports',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        ReportCard(
          title: 'Total Movies',
          value: '${movies.length}',
          icon: Icons.movie,
        ),
        ReportCard(
          title: 'Watched Movies',
          value: '$watched',
          icon: Icons.visibility,
        ),
        ReportCard(
          title: 'Unwatched Movies',
          value: '$unwatched',
          icon: Icons.bookmark,
        ),
        ReportCard(
          title: 'Favorite Movies',
          value: '$favorites',
          icon: Icons.favorite,
        ),
        ReportCard(
          title: 'Average Rating',
          value: avg.toStringAsFixed(1),
          icon: Icons.star,
        ),
      ],
    );
  }
}

// ================= REPORT CARD =================

class ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const ReportCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        leading: CircleAvatar(
          radius: 20,
          child: Icon(icon),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}