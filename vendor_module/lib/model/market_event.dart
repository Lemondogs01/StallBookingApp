import 'package:mfu_market/utils.dart';

class MarketEvent {
  final int id;
  final String name;
  final String venue;
  final String area;
  final DateTime date;
  final String hours;
  final String tagline;
  final List<String> categories;
  final String visitors;
  final String about;

  const MarketEvent({
    required this.id,
    required this.name,
    required this.venue,
    required this.area,
    required this.date,
    required this.hours,
    required this.tagline,
    required this.categories,
    required this.visitors,
    required this.about,
  });
}

/// Demo markets (mock data). Both share the same stall inventory, one per date.
List<MarketEvent> buildMarketEvents() {
  final first = nextSaturday();
  return [
    MarketEvent(
      id: 1,
      name: 'MFU night market (inside uni.)',
      venue: 'MFU university',
      area: 'MFU, Chiang rai',
      date: first,
      hours: '10am–4pm',
      tagline: 'CRAFT, DESIGN & GOOD FOOD',
      categories: const ['Craft & design', 'Food'],
      visitors: '2,000+',
      about: 'Join a curated mix of local makers, artists and food producers '
          'in a lively campus courtyard. A welcoming setting where '
          'neighbours meet to discover something original.',
    ),
    MarketEvent(
      id: 2,
      name: 'MFU night market (outside uni.)',
      venue: 'MFU front gate',
      area: 'Tha Sud, Chiang rai',
      date: addDays(first, 7),
      hours: '5pm–10pm',
      tagline: 'STREET FOOD & GOODS',
      categories: const ['Food'],
      visitors: '1,200+',
      about: 'An evening street market just outside the university gate. '
          'Great foot traffic from students and locals heading home.',
    ),
  ];
}
