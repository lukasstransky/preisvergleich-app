import 'package:integration_test/integration_test.dart';
import 'search_test.dart' as search_tests;
import 'shopping_list_test.dart' as shopping_list_tests;
import 'shopping_list_management_test.dart' as shopping_list_management_tests;
import 'favorites_test.dart' as favorites_tests;
import 'price_alerts_test.dart' as price_alerts_tests;
import 'navigation_test.dart' as navigation_tests;
import 'filter_combinations_test.dart' as filter_combinations_tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  search_tests.main();
  shopping_list_tests.main();
  shopping_list_management_tests.main();
  favorites_tests.main();
  price_alerts_tests.main();
  navigation_tests.main();
  filter_combinations_tests.main();
}
